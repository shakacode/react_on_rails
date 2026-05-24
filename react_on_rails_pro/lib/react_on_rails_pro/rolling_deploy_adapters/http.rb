# frozen_string_literal: true

require "fileutils"
require "json"
require "net/http"
require "openssl"
require "uri"

require "react_on_rails_pro/error"
require "react_on_rails_pro/rolling_deploy/tarball"

module ReactOnRailsPro
  module RollingDeployAdapters
    # Built-in HTTP rolling-deploy adapter. Pairs with
    # ReactOnRailsPro::RollingDeploy::BundlesController on the running Rails
    # server: the controller exposes the current deployment's bundles and the
    # adapter (running in the next deployment's build CI) fetches them.
    #
    # The promise is "zero-infra default": no S3 bucket, no IAM, no extra gem.
    # The currently-deployed Rails server already has the bundles + companion
    # assets sitting on disk; this adapter pulls them via authenticated HTTP.
    #
    # Configuration (see docs/pro/rolling-deploy-http-adapter.md):
    #
    #   ReactOnRailsPro.configure do |config|
    #     config.rolling_deploy_adapter      = ReactOnRailsPro::RollingDeployAdapters::Http
    #     config.rolling_deploy_token        = ENV.fetch("ROLLING_DEPLOY_TOKEN")
    #     config.rolling_deploy_previous_url = ENV["ROLLING_DEPLOY_PREVIOUS_URL"]
    #   end
    #
    # Error contract matches the rolling_deploy_adapter protocol: every
    # exception is caught and reported as a warning so a failed seed degrades
    # to the runtime 410-retry fallback rather than failing the build.
    class Http
      # Per-request HTTP timeouts. The outer Timeout.timeout in
      # RollingDeployCacheStager bounds the total wall-clock budget (10s for
      # discovery, 30s for fetch); these inner timeouts let a hung server fail
      # before the outer wrapper interrupts mid-write, which is more reliable
      # than relying on the thread-level Timeout.timeout that may interrupt
      # at a random execution point.
      DEFAULT_OPEN_TIMEOUT_SECONDS = 5
      DEFAULT_READ_TIMEOUT_SECONDS = 25

      # Maximum uncompressed payload accepted from /bundles/:hash. Mirrors the
      # tarball helper default so a misbehaving or malicious server cannot
      # exhaust disk via a zip-bomb-style response.
      DEFAULT_MAX_SIZE = ReactOnRailsPro::RollingDeploy::Tarball::DEFAULT_MAX_SIZE

      LOG_PREFIX = "[ReactOnRailsPro::RollingDeployAdapters::Http]"

      BUNDLE_ENTRY_NAME = "bundle.js"

      class << self
        def previous_bundle_hashes
          base = configured_previous_url
          return [] if base.nil?

          response = http_get(URI("#{base}/manifest"))
          return warn_and_return("manifest returned HTTP #{response.code}", []) unless response.is_a?(Net::HTTPSuccess)

          parsed = JSON.parse(response.body)
          Array(parsed["hashes"]).map(&:to_s).reject(&:empty?)
        rescue StandardError => e
          warn_and_return("previous_bundle_hashes failed: #{e.class}: #{e.message}", [])
        end

        def fetch(bundle_hash)
          base = configured_previous_url
          return nil if base.nil?
          return nil if hash_invalid?(bundle_hash)

          dir = bundle_dir(bundle_hash)
          FileUtils.mkdir_p(dir)
          tarball_body = download_bundle_tarball(base, bundle_hash)
          return cleanup_and_return(dir, nil) if tarball_body.nil?

          extract_payload(tarball_body, dir, bundle_hash)
        rescue StandardError => e
          cleanup_and_return(dir, nil) if defined?(dir) && dir
          warn_and_return("fetch(#{bundle_hash.inspect}) failed: #{e.class}: #{e.message}", nil)
        end

        # Intentional no-op. The running Rails server IS the artifact store —
        # bundle + companion assets are already on local disk where the
        # mountable BundlesController will serve them on the next deploy's
        # build CI. Documented in docs/pro/rolling-deploy-http-adapter.md.
        def upload(_bundle_hash, bundle:, assets:)
          # See class doc above.
        end

        private

        def configured_previous_url
          url = ReactOnRailsPro.configuration.rolling_deploy_previous_url.to_s.strip
          return nil if url.empty?

          url.chomp("/")
        end

        def configured_token
          ReactOnRailsPro.configuration.rolling_deploy_token.to_s
        end

        # Reject the same hash shapes that RollingDeployCacheStager would
        # reject downstream so we don't issue a wasted HTTP request, and so a
        # path-like hash never reaches the URL builder. Mirrors
        # RollingDeployCacheStager::SAFE_HASH_PATTERN.
        def hash_invalid?(bundle_hash)
          str = bundle_hash.to_s
          return true if str.empty?

          unsafe = !str.match?(/\A(?!\.)[A-Za-z0-9_.-]+\z/)
          return false unless unsafe

          warn "#{LOG_PREFIX} fetch(#{bundle_hash.inspect}) rejected: hash contains unsafe characters."
          true
        end

        def bundle_dir(bundle_hash)
          Rails.root.join("tmp/rolling-deploy", bundle_hash.to_s)
        end

        def download_bundle_tarball(base, bundle_hash)
          response = http_get(URI("#{base}/bundles/#{bundle_hash}"))
          unless response.is_a?(Net::HTTPSuccess)
            warn "#{LOG_PREFIX} bundles/#{bundle_hash} returned HTTP #{response.code}; skipping this hash."
            return nil
          end
          response.body
        end

        def extract_payload(tarball_body, dir, bundle_hash)
          ReactOnRailsPro::RollingDeploy::Tarball.extract(tarball_body, dir, max_size: DEFAULT_MAX_SIZE)
          bundle_path = File.join(dir, BUNDLE_ENTRY_NAME)
          unless File.file?(bundle_path)
            return cleanup_and_return(
              dir,
              warn_and_return("fetch(#{bundle_hash.inspect}) tarball did not contain #{BUNDLE_ENTRY_NAME}", nil)
            )
          end

          assets = extracted_assets(dir)
          { bundle: bundle_path, assets: assets }
        end

        def extracted_assets(dir)
          Dir.children(dir).sort.filter_map do |entry_name|
            next if entry_name == BUNDLE_ENTRY_NAME

            path = File.join(dir, entry_name)
            path if File.file?(path)
          end
        end

        def cleanup_and_return(dir, value)
          FileUtils.rm_rf(dir) if dir
          value
        end

        def warn_and_return(message, value)
          warn "#{LOG_PREFIX} #{message}"
          value
        end

        # Single-shot HTTP GET with bearer-token auth. We don't reuse
        # connections: the adapter is called at most a handful of times per
        # build (one /manifest plus one /bundles per previous hash), and
        # connection pooling would force us to manage lifecycle / cleanup
        # across threads.
        def http_get(uri)
          request = Net::HTTP::Get.new(uri.request_uri)
          token = configured_token
          request["Authorization"] = "Bearer #{token}" unless token.empty?
          request["Accept-Encoding"] = "identity" # tarball is already gzipped; don't double-compress

          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == "https")
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER if http.use_ssl?
          http.open_timeout = DEFAULT_OPEN_TIMEOUT_SECONDS
          http.read_timeout = DEFAULT_READ_TIMEOUT_SECONDS
          http.request(request)
        end
      end
    end
  end
end

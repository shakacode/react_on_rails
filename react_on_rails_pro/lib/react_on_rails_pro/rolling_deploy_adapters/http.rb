# frozen_string_literal: true

require "fileutils"
require "json"
require "net/http"
require "openssl"
require "tempfile"
require "uri"

require "react_on_rails_pro/error"
require "react_on_rails_pro/rolling_deploy/safe_hash_pattern"
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
    # Configuration (see docs/pro/rolling-deploy-adapters.md):
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
    # rubocop:disable Metrics/ClassLength
    class Http
      # Per-request HTTP timeouts. The outer Timeout.timeout in
      # RollingDeployCacheStager bounds the total wall-clock budget (10s for
      # discovery, 30s for fetch); these inner timeouts let a hung server fail
      # before the outer wrapper interrupts mid-write, which is more reliable
      # than relying on the thread-level Timeout.timeout that may interrupt
      # at a random execution point.
      DEFAULT_OPEN_TIMEOUT_SECONDS = 5
      DEFAULT_READ_TIMEOUT_SECONDS = 25
      # Manifest discovery is wrapped in a 10s outer budget by RollingDeployCacheStager.
      MANIFEST_READ_TIMEOUT_SECONDS = 4

      # Maximum uncompressed payload accepted from /bundles/:hash. Mirrors the
      # tarball helper default so a misbehaving or malicious server cannot
      # exhaust disk via a zip-bomb-style response.
      DEFAULT_MAX_SIZE = ReactOnRailsPro::RollingDeploy::Tarball::DEFAULT_MAX_SIZE

      # Maximum compressed bytes accepted from /bundles/:hash before extract
      # enforces DEFAULT_MAX_SIZE on the uncompressed tarball contents.
      # Set near 1/4 of DEFAULT_MAX_SIZE: JS bundles typically decompress 3-5x,
      # so a 50 MB wire payload that decompresses beyond 200 MB is anomalous.
      COMPRESSED_BODY_CAP = 50 * 1024 * 1024

      LOG_PREFIX = "[ReactOnRailsPro::RollingDeployAdapters::Http]"

      # Wire-format constant: must stay in sync with
      # `ReactOnRailsPro::RollingDeploy::BundlesController::BUNDLE_ENTRY_NAME`.
      # The controller serves the bundle file under this entry name; if the
      # two ever diverge the client will fail to locate the bundle after
      # extracting the tarball.
      BUNDLE_ENTRY_NAME = "bundle.js"

      class << self
        def previous_bundle_hashes
          base = configured_previous_url
          return [] if base.nil?

          if token_missing?
            return warn_and_return("rolling_deploy_token is not configured; skipping manifest fetch",
                                   [])
          end

          response = http_get(
            URI("#{base}/manifest"),
            read_timeout: MANIFEST_READ_TIMEOUT_SECONDS
          )
          return warn_and_return("manifest returned HTTP #{response.code}", []) unless response.is_a?(Net::HTTPSuccess)

          parsed = JSON.parse(response.body)
          # Filter manifest hashes through SAFE_HASH_PATTERN before returning
          # so server-supplied strings never appear verbatim in downstream
          # warning logs. Each hash is re-validated inside `fetch`, so this is
          # defense-in-depth — nothing unsafe could reach the filesystem layer
          # — but it keeps log lines from a misbehaving or compromised server
          # from echoing arbitrary content.
          Array(parsed["hashes"])
            .map(&:to_s)
            .reject(&:empty?)
            .grep(ReactOnRailsPro::RollingDeploy::SAFE_HASH_PATTERN)
        rescue StandardError => e
          warn_and_return("previous_bundle_hashes failed: #{e.class}: #{e.message}", [])
        end

        def fetch(bundle_hash)
          base = configured_previous_url
          return nil if base.nil?
          return nil if hash_invalid?(bundle_hash)

          if token_missing?
            return warn_and_return("rolling_deploy_token is not configured; skipping fetch(#{bundle_hash.inspect})",
                                   nil)
          end

          dir = bundle_dir(bundle_hash)
          FileUtils.mkdir_p(dir)

          result = download_bundle_tarball(base, bundle_hash) do |tarball|
            extract_payload(tarball, dir, bundle_hash)
          end
          return cleanup_and_return(dir, nil) if result.nil?

          result
        rescue StandardError => e
          cleanup_and_return(dir, nil) if dir
          warn_and_return("fetch(#{bundle_hash.inspect}) failed: #{e.class}: #{e.message}", nil)
        end

        # Intentional no-op. The running Rails server IS the artifact store —
        # bundle + companion assets are already on local disk where the
        # mountable BundlesController will serve them on the next deploy's
        # build CI. Documented in docs/pro/rolling-deploy-adapters.md.
        def upload(_bundle_hash, bundle:, assets:)
          # See class doc above.
        end

        private

        def configured_previous_url
          url = ReactOnRailsPro.configuration.rolling_deploy_previous_url.to_s.strip
          return nil if url.empty?

          uri = URI.parse(url.chomp("/"))
          unless %w[http https].include?(uri.scheme)
            Rails.logger.warn(
              "#{LOG_PREFIX} rolling_deploy_previous_url has unsupported scheme " \
              "#{uri.scheme.inspect}; expected http or https. Skipping discovery."
            )
            return nil
          end
          uri.to_s
        rescue URI::InvalidURIError => e
          Rails.logger.warn(
            "#{LOG_PREFIX} rolling_deploy_previous_url is not a valid URI: #{e.message}. " \
            "Skipping discovery."
          )
          nil
        end

        def configured_token
          ReactOnRailsPro.configuration.rolling_deploy_token.to_s
        end

        def token_missing?
          configured_token.empty?
        end

        # Reject the same hash shapes that RollingDeployCacheStager would
        # reject downstream so we don't issue a wasted HTTP request, and so a
        # path-like hash never reaches the URL builder.
        def hash_invalid?(bundle_hash)
          str = bundle_hash.to_s
          return true if str.empty?

          unsafe = !str.match?(ReactOnRailsPro::RollingDeploy::SAFE_HASH_PATTERN)
          return false unless unsafe

          Rails.logger.warn("#{LOG_PREFIX} fetch(#{bundle_hash.inspect}) rejected: hash contains unsafe characters.")
          true
        end

        def bundle_dir(bundle_hash)
          Rails.root.join("tmp/rolling-deploy", bundle_hash.to_s)
        end

        def download_bundle_tarball(base, bundle_hash)
          Tempfile.create(["rolling-deploy-download-", ".tar.gz"]) do |tmp|
            tmp.binmode
            response = http_stream(URI("#{base}/bundles/#{bundle_hash}")) do |streaming_response|
              unless streaming_response.is_a?(Net::HTTPSuccess)
                Rails.logger.warn(
                  "#{LOG_PREFIX} bundles/#{bundle_hash} returned HTTP #{streaming_response.code}; skipping this hash."
                )
                # Drain the error body (capped) so Net::HTTP can finish the
                # response cleanly. If the body itself exceeds the cap,
                # `drain_response_body` raises and `fetch`'s rescue logs a second
                # "fetch(...) failed" warning alongside the "skipping this hash"
                # line above. Both lines are expected for an oversized error
                # body — the pair signals "non-2xx, and the body was too large
                # to drain," not a separate failure.
                drain_response_body(streaming_response)
                next
              end

              stream_response_body(streaming_response, tmp)
            end
            # Non-local return: exits `download_bundle_tarball`; Tempfile.create's
            # ensure block still unlinks `tmp` before the method returns.
            return nil unless response.is_a?(Net::HTTPSuccess)

            tmp.flush
            tmp.rewind
            yield tmp
          end
        end

        def stream_response_body(response, io)
          each_capped_body_chunk(response, context: "bundle body") { |chunk| io.write(chunk) }
        end

        # Reads and discards a non-success body solely to enforce the
        # compressed-byte cap. No block is passed, so `each_capped_body_chunk`
        # counts bytes without writing them anywhere.
        def drain_response_body(response)
          each_capped_body_chunk(response, context: "non-success response body")
        end

        def each_capped_body_chunk(response, context:)
          bytes = 0
          response.read_body do |chunk|
            bytes += chunk.bytesize
            # Strictly greater-than (`>`, not `>=`): exactly COMPRESSED_BODY_CAP
            # bytes are allowed through, so the cap is an exclusive ceiling. The
            # raise fires before `yield chunk`, so the offending chunk is counted
            # but never written/drained — the Tempfile never sees more than
            # COMPRESSED_BODY_CAP bytes.
            if bytes > COMPRESSED_BODY_CAP
              raise ReactOnRailsPro::Error,
                    "#{context} exceeded compressed body cap " \
                    "(#{compressed_body_cap_label}); aborting download"
            end
            yield chunk if block_given?
          end
        end

        # Dynamic (not a constant) so specs that `stub_const` the cap to a small
        # value still see the stubbed value reflected in the warning message.
        def compressed_body_cap_label
          megabyte_bytes = 1024 * 1024
          megabytes = COMPRESSED_BODY_CAP / megabyte_bytes
          return "#{megabytes} MB" if megabytes.positive? && megabytes * megabyte_bytes == COMPRESSED_BODY_CAP

          "#{COMPRESSED_BODY_CAP} bytes"
        end

        def extract_payload(tarball_source, dir, bundle_hash)
          ReactOnRailsPro::RollingDeploy::Tarball.extract(tarball_source, dir, max_size: DEFAULT_MAX_SIZE)
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
          Rails.logger.warn("#{LOG_PREFIX} #{message}")
          value
        end

        # Single-shot HTTP GET with bearer-token auth. We don't reuse
        # connections: the adapter is called at most a handful of times per
        # build (one /manifest plus one /bundles per previous hash), and
        # connection pooling would force us to manage lifecycle / cleanup
        # across threads.
        def http_get(uri, read_timeout: DEFAULT_READ_TIMEOUT_SECONDS)
          http_for(uri, read_timeout: read_timeout).request(build_request(uri))
        end

        def http_stream(uri, read_timeout: DEFAULT_READ_TIMEOUT_SECONDS, &block)
          http_for(uri, read_timeout: read_timeout).request(build_request(uri), &block)
        end

        def build_request(uri)
          request = Net::HTTP::Get.new(uri.request_uri)
          token = configured_token
          request["Authorization"] = "Bearer #{token}" unless token.empty?
          request["Accept-Encoding"] = "identity" # tarball is already gzipped; don't double-compress
          request
        end

        def http_for(uri, read_timeout:)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = (uri.scheme == "https")
          warn_plain_http_token(uri) unless http.use_ssl?
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER if http.use_ssl?
          http.open_timeout = DEFAULT_OPEN_TIMEOUT_SECONDS
          http.read_timeout = read_timeout
          http
        end

        # Plain-HTTP guardrail. The full HTTPS-only guard lands in PR 2; until
        # then a single-line warning here protects misconfigured deployments
        # by surfacing the cleartext-token risk in build CI logs.
        #
        # Loopback hosts are intentionally exempt so developers running a
        # local Rails server for `rolling_deploy_previous_url` during
        # development don't see noise on every build CI rehearsal — the
        # token never leaves the host in that case.
        LOOPBACK_HOST_PATTERN = /\A(localhost|127(?:\.\d{1,3}){3}|::1|\[::1\])\z/
        private_constant :LOOPBACK_HOST_PATTERN

        def warn_plain_http_token(uri)
          return if uri.host.to_s.match?(LOOPBACK_HOST_PATTERN)

          Rails.logger.warn(
            "#{LOG_PREFIX} #{uri.scheme}://#{uri.host} is not HTTPS — " \
            "the Bearer token will be transmitted in cleartext. Use HTTPS in production."
          )
        end
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end

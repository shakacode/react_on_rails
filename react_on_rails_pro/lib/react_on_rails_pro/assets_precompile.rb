# frozen_string_literal: true

require "timeout"

module ReactOnRailsPro
  class AssetsPrecompile # rubocop:disable Metrics/ClassLength
    include Singleton

    UPLOAD_TIMEOUT_SECONDS = 120

    def remote_bundle_cache_adapter
      unless ReactOnRailsPro.configuration.remote_bundle_cache_adapter.is_a?(Module)
        raise ReactOnRailsPro::Error, "config.remote_bundle_cache_adapter must have a module assigned"
      end

      ReactOnRailsPro.configuration.remote_bundle_cache_adapter
    end

    def zipped_bundles_filename
      "precompile-cache.#{bundles_cache_key}.production.gz"
    end

    def zipped_bundles_filepath
      @zipped_bundles_filepath ||=
        begin
          FileUtils.mkdir_p(Rails.root.join("tmp", "bundle_cache"))
          Rails.root.join("tmp", "bundle_cache", zipped_bundles_filename)
        end
    end

    def bundles_cache_key
      @bundles_cache_key ||=
        begin
          ReactOnRailsPro::Utils.rorp_puts "Calculating digest of bundle dependencies."
          starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          cache_dependencies = [Shakapacker.config.source_path.join("**", "*")]
                               .union(ReactOnRailsPro.configuration.dependency_globs)
          # Note, digest_of_globs removes excluded globs
          digest = ReactOnRailsPro::Utils.digest_of_globs(cache_dependencies)
          # Include the NODE_ENV in the digest
          env_cache_keys = [
            ReactOnRailsPro::VERSION,
            ENV.fetch("RAILS_ENV", nil),
            ENV.fetch("NODE_ENV", nil)
          ]

          if remote_bundle_cache_adapter.respond_to?(:cache_keys)
            env_cache_keys += remote_bundle_cache_adapter.cache_keys
          end
          env_cache_keys.compact.each { |value| digest.update(value) }

          result = digest.hexdigest
          ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          elapsed = (ending - starting).round(2)
          ReactOnRailsPro::Utils.rorp_puts "Completed calculating digest of bundle dependencies in #{elapsed} seconds."
          result
        end
    end

    def build_bundles
      remote_bundle_cache_adapter.build
    rescue RuntimeError
      ReactOnRailsPro::Utils.rorp_puts "The custom config.remote_bundle_cache_adapter 'build' method raised an error:"
      raise
    end

    def self.call
      instance.build_or_fetch_bundles
      return unless ReactOnRailsPro.configuration.node_renderer?

      # Symlink is the same-filesystem default (local dev, CI, Heroku-style same-dyno
      # deploys, bundle-caching restores). Docker image builds that run assets:precompile
      # should set ASSETS_PRECOMPILE_RENDERER_CACHE_MODE=copy to bake the cache into the
      # immutable artifact, or invoke `rake react_on_rails_pro:pre_seed_renderer_cache`
      # directly (which defaults to copy mode).
      ReactOnRailsPro::PreSeedRendererCache.call(mode: pre_seed_renderer_cache_mode)

      publish_current_bundle_if_configured
    end

    # Best-effort publication of the just-built bundles + assets to the configured
    # rolling_deploy_adapter so that the *next* deploy can fetch these hashes as
    # "previous" bundles. Runs only in production-like environments. Errors are
    # warned per-hash, not raised, because a failed upload degrades the next
    # deploy's rolling-deploy seeding — not this deploy's correctness.
    #
    # Protocol: each hash is one bundle's cache entry — when RSC is enabled,
    # upload is called once for the server bundle (under server_bundle_hash)
    # and once for the RSC bundle (under rsc_bundle_hash).
    def self.publish_current_bundle_if_configured
      adapter = ReactOnRailsPro.configuration.rolling_deploy_adapter
      return if adapter.nil?
      # NodeRendererPool.server_bundle_hash is only available under the NodeRenderer
      # renderer mode. With ExecJS, skip publication rather than crash.
      return unless ReactOnRailsPro.configuration.node_renderer?
      return if Rails.env.development? || Rails.env.test?

      publish_bundles(adapter)
    rescue StandardError => e
      # Outer rescue catches anything raised by the setup-side calls below
      # (collect_assets, server_bundle_hash, rsc_bundle_js_file_path). Per the
      # rolling-deploy contract, a failed upload must degrade the next deploy's
      # seeding — not fail *this* deploy's assets:precompile.
      warn "[ReactOnRailsPro] rolling_deploy_adapter publication failed: #{e.class}: #{e.message}. " \
           "Next deploy's rolling-deploy seeding may degrade; precompile continuing."
    end

    def self.publish_bundles(adapter)
      pool = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool
      # Companion manifests are generated for the deploy as a whole, so server
      # and RSC hashes from the same build intentionally share this asset set.
      assets = filter_existing_assets(ReactOnRailsPro::RendererCacheHelpers.collect_assets.map(&:to_s))

      server_bundle = ReactOnRails::Utils.server_bundle_js_file_path
      publish_bundle(adapter, pool.server_bundle_hash, server_bundle, assets, "server") if File.exist?(server_bundle)

      return unless ReactOnRailsPro.configuration.enable_rsc_support

      rsc_bundle = ReactOnRailsPro::Utils.rsc_bundle_js_file_path
      publish_bundle(adapter, pool.rsc_bundle_hash, rsc_bundle, assets, "RSC") if File.exist?(rsc_bundle)
    end

    # Some collected companion assets may be absent or point at non-file paths.
    # Typical adapters iterate the list and `cp`/open each entry, so forwarding
    # an invalid path would raise and abort the whole hash upload, leaving the
    # next deploy unable to fetch this hash (→ cold 410 retries). Drop invalid
    # entries with a warning so publication still covers the existing assets.
    def self.filter_existing_assets(assets)
      existing, invalid = assets.partition { |path| File.file?(path) }
      return existing if invalid.empty?

      missing, non_files = invalid.partition { |path| !File.exist?(path) }
      warn_skipped_invalid_assets(existing, missing, non_files)
      warn_if_unavailable_required_rsc_assets(invalid)
      existing
    end

    # Combine missing-vs-non-file reasons into a single warning so operators see
    # one entry per skipped batch instead of two near-identical lines. The
    # reason breakdown (missing vs non-file) still appears so adapter authors
    # can tell a deleted asset apart from one that resolved to e.g. a directory.
    def self.warn_skipped_invalid_assets(existing, missing, non_files)
      reasons = []
      reasons << "missing: #{missing.inspect}" unless missing.empty?
      reasons << "not a file: #{non_files.inspect}" unless non_files.empty?
      warn "[ReactOnRailsPro] Skipping invalid assets for rolling_deploy_adapter upload " \
           "(some may be required for RSC) — #{reasons.join('; ')}. " \
           "Continuing with #{existing.length} existing asset(s)."
    end

    def self.warn_if_unavailable_required_rsc_assets(unavailable_assets)
      missing_required = required_rsc_asset_basenames & unavailable_assets.map { |path| File.basename(path) }
      return if missing_required.empty?

      warn "[ReactOnRailsPro] WARNING: unavailable assets include required RSC companion file(s) " \
           "#{missing_required.inspect}. The partial entry will be rejected on every subsequent rolling " \
           "deploy that tries to seed this bundle hash for RSC (falling back to 410-retry) until a " \
           "complete precompile with all required RSC companion files overwrites this hash."
    end

    def self.required_rsc_asset_basenames
      return [] unless ReactOnRailsPro.configuration.enable_rsc_support

      rsc_manifest_paths = ReactOnRailsPro::RendererCacheHelpers.rsc_manifest_paths
      required_asset_paths = ReactOnRailsPro::RendererCacheHelpers.required_rsc_asset_paths(rsc_manifest_paths)
      required_asset_paths.map { |path| File.basename(path) }
    end

    def self.publish_bundle(adapter, hash, bundle, assets, bundle_label)
      if hash.to_s.empty?
        warn "[ReactOnRailsPro] Skipping rolling_deploy_adapter publication for #{bundle_label} bundle " \
             "#{bundle.inspect} because its bundle hash is blank."
        return
      end

      upload_bundle(adapter, hash, bundle, assets)
    end

    def self.upload_bundle(adapter, hash, bundle, assets)
      Timeout.timeout(UPLOAD_TIMEOUT_SECONDS) do
        adapter.upload(hash, bundle: bundle, assets: assets)
      end
      puts "[ReactOnRailsPro] Published bundle hash #{hash} via rolling_deploy_adapter"
    rescue Timeout::Error
      warn "[ReactOnRailsPro] rolling_deploy_adapter#upload for #{hash} timed out after " \
           "#{UPLOAD_TIMEOUT_SECONDS}s. Next deploy's rolling-deploy seeding for this hash may degrade."
    rescue StandardError => e
      warn "[ReactOnRailsPro] rolling_deploy_adapter#upload for #{hash} raised #{e.class}: " \
           "#{e.message}. Next deploy's rolling-deploy seeding for this hash may degrade."
    end

    def self.pre_seed_renderer_cache_mode
      raw = ENV.fetch("ASSETS_PRECOMPILE_RENDERER_CACHE_MODE", "symlink").to_s.downcase
      mode = raw.to_sym
      return mode if ReactOnRailsPro::PreSeedRendererCache::VALID_MODES.include?(mode)

      valid = ReactOnRailsPro::PreSeedRendererCache::VALID_MODES.map(&:to_s).join(", ")
      raise ReactOnRailsPro::Error,
            "ASSETS_PRECOMPILE_RENDERER_CACHE_MODE must be one of: #{valid} (got #{raw.inspect})"
    end
    private_class_method :pre_seed_renderer_cache_mode

    def build_or_fetch_bundles
      if disable_precompile_cache?
        build_bundles
        return
      end

      begin
        bundles_fetched = fetch_and_unzip_cached_bundles
      rescue RuntimeError => e
        ReactOnRailsPro::Utils.rorp_puts "An error occurred while attempting to fetch cached bundles."
        ReactOnRailsPro::Utils.rorp_puts "This will be evaluated as a bundle cache miss."
        ReactOnRailsPro::Utils.rorp_puts e.message
        puts e.backtrace.join('\n')
        bundles_fetched = false
      end

      return if bundles_fetched

      build_bundles

      begin
        cache_bundles
      rescue RuntimeError => e
        ReactOnRailsPro::Utils.rorp_puts "An error occurred while attempting to cache the built bundles."
        ReactOnRailsPro::Utils.rorp_puts e.message
        puts e.backtrace.join('\n')
      end
    end

    def disable_precompile_cache?
      ENV["DISABLE_PRECOMPILE_CACHE"] == "true"
    end

    def fetch_bundles
      ReactOnRailsPro::Utils.rorp_puts "Checking for a cached bundle: #{zipped_bundles_filename}"
      begin
        fetch_result = remote_bundle_cache_adapter.fetch(zipped_bundles_filename)
      rescue RuntimeError
        message = "An error was raised by the custom config.remote_bundle_cache_adapter 'fetch' " \
                  "method when called with { zipped_bundles_filename: #{zipped_bundles_filename} }"
        ReactOnRailsPro::Utils.rorp_puts message
        raise
      end

      if fetch_result
        ReactOnRailsPro::Utils.rorp_puts "Remote bundle cache detected. Bundles will be restored to local cache."
        File.binwrite(zipped_bundles_filepath, fetch_result)
        true
      else
        ReactOnRailsPro::Utils.rorp_puts "Remote bundle cache not found."
        false
      end
    end

    def fetch_and_unzip_cached_bundles
      if File.exist?(zipped_bundles_filepath)
        ReactOnRailsPro::Utils.rorp_puts "Found a local cache of bundles: #{zipped_bundles_filepath}"
        result = true
      else
        result = fetch_bundles
      end

      if File.exist?(zipped_bundles_filepath)
        ReactOnRailsPro::Utils.rorp_puts "gunzipping bundle cache: #{zipped_bundles_filepath}"
        public_output_path = Shakapacker.config.public_output_path
        FileUtils.mkdir_p(public_output_path)
        Dir.chdir(public_output_path) do
          Rake.sh "tar -xzf #{zipped_bundles_filepath}"
        end

        ReactOnRailsPro::Utils.rorp_puts "gunzipped bundle cache: #{zipped_bundles_filepath} to #{public_output_path}"

        extract_extra_files_from_cache_dir
      end
      result
    end

    def extra_files_path
      Rails.root.join(Shakapacker.config.public_output_path, "extra_files")
    end

    def copy_extra_files_to_cache_dir
      return unless remote_bundle_cache_adapter.respond_to?(:extra_files_to_cache)

      FileUtils.mkdir_p(extra_files_path)
      copied_extra_files_paths = []

      remote_bundle_cache_adapter.extra_files_to_cache.each do |file_path|
        if file_path.file?
          copy_file_to_extra_files_cache_dir(file_path)
          copied_extra_files_paths.push(file_path.relative_path_from(Rails.root).to_s)
        else
          ReactOnRailsPro::Utils.rorp_puts "Extra file: #{file_path}, doesn't exist. Skipping"
        end
      end

      ReactOnRailsPro::Utils.rorp_puts "Copied extra files: #{copied_extra_files_paths.join(', ')} " \
                                       "to extra_files cache dir"
    end

    def copy_file_to_extra_files_cache_dir(source_path)
      destination_file_path = convert_to_destination(source_path)
      FileUtils.cp(source_path, destination_file_path)
    end

    def convert_to_destination(source)
      new_file_name = source.relative_path_from(Rails.root).each_filename.to_a.join("---")
      extra_files_path.join(new_file_name)
    end

    def extract_extra_files_from_cache_dir
      return unless File.exist?(extra_files_path)

      extracted_extra_files_paths = []
      Dir.each_child(extra_files_path) do |file_name|
        file_path_parts = file_name.split("---")
        source_file_path = extra_files_path.join(file_name)
        destination_file_path = Rails.root.join(*file_path_parts)
        FileUtils.mv(source_file_path, destination_file_path)
        extracted_extra_files_paths.push(destination_file_path.relative_path_from(Rails.root).to_s)
      end

      ReactOnRailsPro::Utils.rorp_puts "Extracted extra files: #{extracted_extra_files_paths.join(', ')} " \
                                       "from extra_files cache dir"
      remove_extra_files_cache_dir
    end

    def cache_bundles
      begin
        copy_extra_files_to_cache_dir
        public_output_path = Shakapacker.config.public_output_path
        ReactOnRailsPro::Utils.rorp_puts "Gzipping built bundles to #{zipped_bundles_filepath} with " \
                                         "files in #{public_output_path}"
        Dir.chdir(public_output_path) do
          Rake.sh "tar -czf #{zipped_bundles_filepath} --auto-compress -C " \
                  "#{Shakapacker.config.public_output_path} ."
        end
      rescue StandardError => e
        ReactOnRailsPro::Utils.rorp_puts "An error occurred while attempting to zip the built bundles."
        ReactOnRailsPro::Utils.rorp_puts e.message
        puts e.backtrace.join('\n')
      ensure
        remove_extra_files_cache_dir
      end

      ReactOnRailsPro::Utils.rorp_puts "Bundles will be uploaded to remote bundle cache as #{zipped_bundles_filename}"

      begin
        remote_bundle_cache_adapter.upload(zipped_bundles_filepath)
      rescue RuntimeError
        message = "An error was raised by the custom config.remote_bundle_cache_adapter 'upload' " \
                  "method when called with zipped_bundles_filepath: #{zipped_bundles_filepath}"
        ReactOnRailsPro::Utils.rorp_puts message
        raise
      end
    end

    def remove_extra_files_cache_dir
      FileUtils.rm_f(extra_files_path)
    end
  end
end

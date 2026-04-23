# frozen_string_literal: true

require "fileutils"
require "react_on_rails_pro/renderer_cache_helpers"
require "securerandom"
require "timeout"

module ReactOnRailsPro
  # Seeds previous deploy bundle hashes into the Node Renderer cache so that
  # during a rolling deploy, new renderer instances can serve requests for
  # bundles referenced by draining Rails instances without hitting the 410
  # retry path.
  #
  # Discovery:
  #   * ENV["PREVIOUS_BUNDLE_HASHES"] (comma-separated) — overrides adapter discovery.
  #   * ReactOnRailsPro.configuration.rolling_deploy_adapter#previous_bundle_hashes — the default.
  #
  # Retrieval:
  #   * rolling_deploy_adapter#fetch(hash) must return a Hash with keys
  #     :bundle (String path to the bundle file) and :assets (Array<String>
  #     of companion asset file paths). Returns nil if the bundle is
  #     unavailable.
  #
  # Protocol model: each hash is one bundle's cache entry. Adapters
  # advertise separate hashes for server and RSC bundles; the stager
  # stages each hash at <cache>/<hash>/<hash>.js independently.
  #
  # Missing previous bundles degrade gracefully (warn + continue) because
  # the runtime 410-retry path is still a valid fallback — a failed
  # rolling-deploy seed is less catastrophic than a failed *current*
  # bundle seed.
  module RollingDeployCacheStager # rubocop:disable Metrics/ModuleLength
    DISCOVERY_TIMEOUT_SECONDS = 10
    FETCH_TIMEOUT_SECONDS = 30
    STALE_TEMP_DIR_TTL_SECONDS = 3600
    TEMPORARY_DIRECTORY_PATTERN = /\.(?:staging|previous)-\d+-[0-9a-f]+\z/

    def self.call(cache_dir:, current_hashes:, mode:)
      adapter = ReactOnRailsPro.configuration.rolling_deploy_adapter
      return handle_missing_adapter unless adapter

      sweep_stale_temporary_directories(cache_dir)
      hashes = resolve_previous_hashes(adapter, current_hashes)
      if hashes.empty?
        puts "[ReactOnRailsPro] No previous bundle hashes to seed for rolling deploy."
        return
      end

      puts "[ReactOnRailsPro] Seeding previous bundle hashes for rolling deploy: #{hashes.inspect}"
      hashes.each { |hash| seed_previous_hash(adapter, hash, cache_dir, mode) }
    end

    def self.handle_missing_adapter
      env_override = ENV["PREVIOUS_BUNDLE_HASHES"].to_s.strip
      return if env_override.empty?

      # PREVIOUS_BUNDLE_HASHES overrides *discovery*; the adapter is still required
      # to fetch the actual bundle files. Refuse to proceed rather than raise a raw
      # NoMethodError on the nil adapter.
      warn "[ReactOnRailsPro] PREVIOUS_BUNDLE_HASHES=#{env_override.inspect} is set but no " \
           "rolling_deploy_adapter is configured. Rolling-deploy seeding requires both. " \
           "Set config.rolling_deploy_adapter to enable. Skipping previous-hash seeding."
    end
    private_class_method :handle_missing_adapter

    # Bundle hashes are used as directory names under the renderer cache path
    # (<cache>/<hash>/<hash>.js). Reject path separators and also "." / ".."
    # so staging and cleanup can never escape the cache root.
    SAFE_HASH_PATTERN = /\A(?!\.{1,2}\z)[A-Za-z0-9_.-]+\z/

    def self.resolve_previous_hashes(adapter, current_hashes)
      explicit = ENV["PREVIOUS_BUNDLE_HASHES"].to_s.split(",").map(&:strip).reject(&:empty?)
      hashes = if explicit.any?
                 sanitize_hashes(explicit, source_label: "PREVIOUS_BUNDLE_HASHES")
               else
                 sanitize_hashes(
                   fetch_hashes_from_adapter(adapter),
                   source_label: "rolling_deploy_adapter#previous_bundle_hashes"
                 )
               end
      # Deduplicate within the previous-hash list first so a duplicate entry can't
      # fail later and trigger `seed_previous_hash`'s rollback on a directory an
      # earlier successful stage already populated. Then subtract current-build
      # hashes so we don't re-fetch what we just staged.
      hashes.uniq - Array(current_hashes).map(&:to_s)
    end
    private_class_method :resolve_previous_hashes

    def self.fetch_hashes_from_adapter(adapter)
      Timeout.timeout(DISCOVERY_TIMEOUT_SECONDS) { Array(adapter.previous_bundle_hashes) }
    rescue Timeout::Error
      warn "[ReactOnRailsPro] rolling_deploy_adapter#previous_bundle_hashes timed out after " \
           "#{DISCOVERY_TIMEOUT_SECONDS}s. Skipping previous-hash seeding."
      []
    rescue StandardError => e
      warn "[ReactOnRailsPro] rolling_deploy_adapter#previous_bundle_hashes raised #{e.class}: " \
           "#{e.message}. Skipping previous-hash seeding."
      []
    end
    private_class_method :fetch_hashes_from_adapter

    def self.seed_previous_hash(adapter, hash, cache_dir, mode)
      staging_dir = nil
      payload = fetch_payload(adapter, hash)
      return if payload.nil?

      bundle_dir = bundle_directory(cache_dir, hash)
      staging_dir = temporary_bundle_directory(bundle_dir)
      stage_previous_file(
        payload[:bundle],
        File.join(staging_dir, "#{hash}.js"),
        bundle_dir,
        mode,
        "Seeded previous bundle file"
      )

      Array(payload[:assets]).each do |asset_path|
        stage_previous_file(
          asset_path,
          File.join(staging_dir, File.basename(asset_path)),
          bundle_dir,
          mode,
          "Seeded previous asset"
        )
      end

      replace_bundle_directory(staging_dir, bundle_dir)
      staging_dir = nil
    rescue StandardError => e
      # Remove only files created by this attempt. If the hash directory was
      # already valid from an earlier seed on a persistent cache volume, keep it
      # available rather than evicting it because this refresh failed.
      FileUtils.rm_rf(staging_dir) if staging_dir
      warn "[ReactOnRailsPro] Failed to seed previous bundle hash #{hash}: #{e.class}: #{e.message}. " \
           "Rolled back this attempt's partially-staged files. Runtime 410-retry remains the fallback."
    end
    private_class_method :seed_previous_hash

    def self.fetch_payload(adapter, hash)
      payload = Timeout.timeout(FETCH_TIMEOUT_SECONDS) { adapter.fetch(hash) }
      if payload.nil?
        warn "[ReactOnRailsPro] rolling_deploy_adapter#fetch(#{hash.inspect}) returned nil. " \
             "Runtime 410-retry path remains available as fallback."
        return nil
      end

      asset_paths = Array(payload[:assets]).map(&:to_s)
      return nil unless valid_bundle_payload?(payload, hash)
      return nil unless valid_required_rsc_payload?(asset_paths, hash)
      return nil unless valid_asset_payload?(asset_paths, hash)

      warn_if_missing_loadable_stats(asset_paths, hash)
      payload
    rescue Timeout::Error
      warn "[ReactOnRailsPro] rolling_deploy_adapter#fetch(#{hash.inspect}) timed out after " \
           "#{FETCH_TIMEOUT_SECONDS}s. Skipping this hash."
      nil
    rescue StandardError => e
      # Keep adapter-fetch attribution here instead of letting the outer rescue
      # in `seed_previous_hash` rewrite the message as a generic staging failure —
      # `bundle_dir` is still nil at this point, so nothing has been staged.
      warn "[ReactOnRailsPro] rolling_deploy_adapter#fetch(#{hash.inspect}) raised #{e.class}: " \
           "#{e.message}. Skipping this hash."
      nil
    end
    private_class_method :fetch_payload

    def self.valid_bundle_payload?(payload, hash)
      return true if payload[:bundle] && File.file?(payload[:bundle])

      warn "[ReactOnRailsPro] rolling_deploy_adapter#fetch(#{hash.inspect}) returned payload without " \
           "a valid :bundle file path. Skipping this hash."
      false
    end
    private_class_method :valid_bundle_payload?

    def self.valid_asset_payload?(asset_paths, hash)
      missing_assets = asset_paths.reject { |asset_path| File.exist?(asset_path) }
      return true if missing_assets.empty?

      missing_required = required_rsc_asset_basenames & missing_assets.map { |path| File.basename(path) }
      if missing_required.any?
        warn "[ReactOnRailsPro] rolling_deploy_adapter#fetch(#{hash.inspect}) returned missing required RSC " \
             "asset path(s): #{missing_required.inspect}. Skipping this hash."
      else
        warn "[ReactOnRailsPro] rolling_deploy_adapter#fetch(#{hash.inspect}) returned missing asset " \
             "path(s): #{missing_assets.inspect}. Skipping this hash."
      end
      false
    end
    private_class_method :valid_asset_payload?

    def self.valid_required_rsc_payload?(asset_paths, hash)
      missing = required_rsc_asset_basenames - asset_paths.map { |path| File.basename(path) }
      return true if missing.empty?

      warn "[ReactOnRailsPro] rolling_deploy_adapter#fetch(#{hash.inspect}) is missing required RSC " \
           "companion asset(s): #{missing.inspect}. Skipping this hash."
      false
    end
    private_class_method :valid_required_rsc_payload?

    def self.warn_if_missing_loadable_stats(asset_paths, hash)
      return if asset_paths.map { |path| File.basename(path) }.include?("loadable-stats.json")

      warn "[ReactOnRailsPro] rolling_deploy_adapter#fetch(#{hash.inspect}) is missing loadable-stats.json. " \
           "Client hydration may break for requests served by this previous bundle hash."
    end
    private_class_method :warn_if_missing_loadable_stats

    def self.required_rsc_asset_basenames
      return [] unless ReactOnRailsPro.configuration.enable_rsc_support

      RendererCacheHelpers.required_rsc_asset_paths.map { |path| File.basename(path) }
    end
    private_class_method :required_rsc_asset_basenames

    def self.stage_previous_file(src, dest, bundle_dir, mode, log_prefix)
      stage_mode = cache_local_source?(src, bundle_dir) ? :copy : mode
      stage_file(src, dest, stage_mode, log_prefix)
    end
    private_class_method :stage_previous_file

    # In symlink mode, a payload source inside the same target bundle dir would
    # become self-referential after the staging dir is promoted into place.
    # Copy those cache-local files instead; external payload sources still use
    # the caller-requested mode.
    def self.cache_local_source?(src, bundle_dir)
      return false unless File.directory?(bundle_dir)

      bundle_dir_realpath = File.realpath(bundle_dir)
      source_realpath = File.realpath(src)
      source_realpath.start_with?("#{bundle_dir_realpath}#{File::SEPARATOR}")
    rescue Errno::ENOENT
      false
    end
    private_class_method :cache_local_source?

    def self.stage_file(src, dest, mode, log_prefix)
      RendererCacheHelpers.stage_file(src, dest, mode, log_prefix: log_prefix)
    end
    private_class_method :stage_file

    def self.sweep_stale_temporary_directories(cache_dir)
      return unless Dir.exist?(cache_dir)

      Dir.children(cache_dir).each do |entry|
        next unless entry.match?(TEMPORARY_DIRECTORY_PATTERN)

        remove_stale_temporary_directory(File.join(cache_dir, entry))
      end
    end
    private_class_method :sweep_stale_temporary_directories

    def self.remove_stale_temporary_directory(path)
      stat = File.lstat(path)
      return unless stat.directory?
      return unless stat.mtime < Time.now - STALE_TEMP_DIR_TTL_SECONDS

      FileUtils.rm_rf(path)
      warn "[ReactOnRailsPro] Removed stale rolling-deploy temp directory #{path}."
    rescue StandardError => e
      warn "[ReactOnRailsPro] Could not remove stale rolling-deploy temp directory #{path}: " \
           "#{e.class}: #{e.message}."
    end
    private_class_method :remove_stale_temporary_directory

    def self.temporary_bundle_directory(bundle_dir)
      "#{bundle_dir}.staging-#{Process.pid}-#{SecureRandom.hex(6)}"
    end
    private_class_method :temporary_bundle_directory

    def self.sanitize_hashes(hash_values, source_label:)
      hashes = Array(hash_values).map { |value| value.to_s.strip }.reject(&:empty?)
      invalid = hashes.grep_v(SAFE_HASH_PATTERN)
      if invalid.any?
        warn "[ReactOnRailsPro] #{source_label} returned invalid hash values (rejected): #{invalid.inspect}. " \
             "Hashes must match /#{SAFE_HASH_PATTERN.source}/ to stay within the renderer cache directory."
      end
      hashes - invalid
    end
    private_class_method :sanitize_hashes

    def self.bundle_directory(cache_dir, hash)
      # File.realpath requires the cache root to exist before path normalization.
      FileUtils.mkdir_p(cache_dir)
      normalized_cache_dir = File.realpath(cache_dir)
      normalized_candidate = File.expand_path(File.join(normalized_cache_dir, hash))

      # Require the candidate to be a *subdirectory* of the cache root, not the
      # cache root itself. `sanitize_hashes` already rejects `""` / `.` / `..`,
      # so the equality case is unreachable today; enforcing `start_with?` only
      # keeps staging safe even if sanitization ever regressed (a bundle landing
      # directly at `<cache>/<hash>.js` instead of `<cache>/<hash>/<hash>.js`
      # would break the renderer's lookup layout silently).
      return normalized_candidate if normalized_candidate.start_with?("#{normalized_cache_dir}/")

      raise ReactOnRailsPro::Error,
            "Refusing to stage rolling-deploy bundle hash #{hash.inspect} outside renderer cache dir " \
            "#{normalized_cache_dir.inspect}."
    end
    private_class_method :bundle_directory

    def self.replace_bundle_directory(staging_dir, bundle_dir)
      backup_dir = nil
      if File.exist?(bundle_dir)
        backup_dir = "#{bundle_dir}.previous-#{Process.pid}-#{SecureRandom.hex(6)}"
        FileUtils.mv(bundle_dir, backup_dir)
      end

      FileUtils.mv(staging_dir, bundle_dir)
      remove_previous_bundle_backup(backup_dir)
    rescue StandardError
      restore_previous_bundle_directory(backup_dir, bundle_dir)
      raise
    end
    private_class_method :replace_bundle_directory

    def self.remove_previous_bundle_backup(backup_dir)
      return unless backup_dir

      FileUtils.rm_rf(backup_dir)
    rescue StandardError => e
      warn "[ReactOnRailsPro] Could not remove stale rolling-deploy backup directory #{backup_dir}: " \
           "#{e.class}: #{e.message}. It will be swept on a later run."
    end
    private_class_method :remove_previous_bundle_backup

    def self.restore_previous_bundle_directory(backup_dir, bundle_dir)
      return unless backup_dir

      FileUtils.rm_rf(bundle_dir)
      FileUtils.mv(backup_dir, bundle_dir) if File.exist?(backup_dir) && !File.exist?(bundle_dir)
    end
    private_class_method :restore_previous_bundle_directory
  end
end

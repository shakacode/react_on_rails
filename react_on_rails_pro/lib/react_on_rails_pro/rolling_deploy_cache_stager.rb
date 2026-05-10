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
    # Duplicated in react_on_rails/lib/react_on_rails/doctor.rb as a hardcoded
    # fallback when the Pro gem isn't loaded. The cross-package equality is
    # asserted in spec/dummy/spec/rolling_deploy_cache_stager_spec.rb so a
    # change here fails that spec instead of silently drifting past the doctor
    # probe.
    DISCOVERY_TIMEOUT_SECONDS = 10
    # Per-hash fetch budget during pre-seeding. Large cross-region stores may
    # need adapters to keep fetches comfortably under this limit.
    FETCH_TIMEOUT_SECONDS = 30
    STALE_TEMP_DIR_TTL_SECONDS = 3600
    # Match temp dirs created by `temporary_bundle_directory` (and the analogous
    # `.previous-` backup suffix in `replace_bundle_directory`). The 8-hex
    # random suffix defeats false positives where a real bundle hash happens
    # to end with `.staging-<digits>-<short hex>`. PID is `\d+` rather than
    # `\d{4,}` because container deployments (Docker, Kubernetes) commonly run
    # the seeding process as PID 1; a stricter floor would silently leave
    # PID-1 staging dirs in the cache to accumulate forever.
    TEMPORARY_DIRECTORY_PATTERN = /\.(?:staging|previous)-\d+-[0-9a-f]{8,}\z/

    def self.call(cache_dir:, current_hashes:, mode:)
      adapter = ReactOnRailsPro.configuration.rolling_deploy_adapter
      return handle_missing_adapter unless adapter

      sweep_stale_temporary_directories(cache_dir)
      hashes = resolve_previous_hashes(adapter, current_hashes)
      if hashes.empty?
        puts "[ReactOnRailsPro] No previous bundle hashes to seed for rolling deploy."
        return
      end

      # Create the cache root once we know we have at least one hash to stage.
      # bundle_directory then resolves real paths against an existing dir without
      # needing to mutate the filesystem itself.
      FileUtils.mkdir_p(cache_dir)
      puts "[ReactOnRailsPro] Seeding previous bundle hashes for rolling deploy: #{hashes.inspect}"
      hashes.each { |hash| seed_previous_hash(adapter, hash, cache_dir, mode) }
    end

    def self.handle_missing_adapter
      env_override = ENV["PREVIOUS_BUNDLE_HASHES"].to_s.strip
      return nil if env_override.empty?

      # PREVIOUS_BUNDLE_HASHES overrides *discovery*; the adapter is still required
      # to fetch the actual bundle files. Refuse to proceed rather than raise a raw
      # NoMethodError on the nil adapter.
      warn "[ReactOnRailsPro] PREVIOUS_BUNDLE_HASHES=#{env_override.inspect} is set but no " \
           "rolling_deploy_adapter is configured. Rolling-deploy seeding requires both. " \
           "Set config.rolling_deploy_adapter to enable. Skipping previous-hash seeding."
      nil
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
      # Create the staging dir explicitly so a permission error here surfaces with a
      # clear "Failed to seed previous bundle hash" attribution rather than as a
      # downstream copy/symlink failure inside `stage_previous_file`.
      FileUtils.mkdir_p(staging_dir)
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
      puts "[ReactOnRailsPro] Seeded previous bundle hash #{hash} at #{bundle_dir}."
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

      # Attribute PackerUtils / RendererCacheHelpers failures to the loadable-stats
      # lookup rather than letting the outer adapter#fetch rescue blame the adapter
      # for an internal framework error (manifest absent, malformed, etc.).
      begin
        warn_if_missing_loadable_stats(asset_paths, hash)
      rescue StandardError => e
        warn "[ReactOnRailsPro] Could not check loadable-stats.json for #{hash.inspect}: " \
             "#{e.class}: #{e.message}. Continuing with the seeded payload."
      end
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
      # Stricter than upload-side filtering: a partial payload in the store means
      # every subsequent seed for this hash would produce a broken hydration
      # chain, so reject the whole hash rather than staging an incomplete set.
      invalid_assets = asset_paths.reject { |asset_path| File.file?(asset_path) }
      return true if invalid_assets.empty?

      missing_assets, non_file_assets = invalid_assets.partition { |asset_path| !File.exist?(asset_path) }
      warn_missing_asset_payload(hash, missing_assets)
      warn_non_file_asset_payload(hash, non_file_assets)
      false
    end
    private_class_method :valid_asset_payload?

    def self.warn_missing_asset_payload(hash, missing_assets)
      return if missing_assets.empty?

      missing_required = required_rsc_asset_basenames & missing_assets.map { |path| File.basename(path) }
      if missing_required.any?
        warn "[ReactOnRailsPro] rolling_deploy_adapter#fetch(#{hash.inspect}) returned missing required RSC " \
             "asset path(s): #{missing_required.inspect}. Skipping this hash."
      else
        warn "[ReactOnRailsPro] rolling_deploy_adapter#fetch(#{hash.inspect}) returned non-required asset " \
             "path(s) that do not exist: #{missing_assets.inspect}. Adapter contract requires only " \
             "existing file paths. Skipping this hash to avoid staging an incomplete bundle directory."
      end
    end
    private_class_method :warn_missing_asset_payload

    def self.warn_non_file_asset_payload(hash, non_file_assets)
      return if non_file_assets.empty?

      non_file_required = required_rsc_asset_basenames & non_file_assets.map { |path| File.basename(path) }
      if non_file_required.any?
        warn "[ReactOnRailsPro] rolling_deploy_adapter#fetch(#{hash.inspect}) returned non-file required RSC " \
             "asset path(s): #{non_file_required.inspect}. Skipping this hash."
      else
        warn "[ReactOnRailsPro] rolling_deploy_adapter#fetch(#{hash.inspect}) returned non-required asset " \
             "path(s) that are not files: #{non_file_assets.inspect}. Adapter contract requires only " \
             "existing file paths. Skipping this hash to avoid staging an incomplete bundle directory."
      end
    end
    private_class_method :warn_non_file_asset_payload

    # Only checks that the required RSC basenames *appear* in the payload's asset
    # list. Existence and file-ness of those paths on disk are validated downstream
    # by `valid_asset_payload?`, which attributes any missing required RSC files
    # via `warn_missing_asset_payload`. Splitting the two passes lets each warning
    # attribute the failure mode (contract gap vs. dangling path) accurately.
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
      # Skip the warning for builds that legitimately don't produce loadable-stats.json
      # (single-chunk apps without code-splitting). The local build's collect_assets
      # only attaches the file when it exists, so the previous-hash payload absence is
      # consistent — warning would just be noise on every rolling deploy.
      return unless ReactOnRailsPro::RendererCacheHelpers.loadable_stats_asset_path

      warn "[ReactOnRailsPro] WARNING: rolling_deploy_adapter#fetch(#{hash.inspect}) is missing loadable-stats.json. " \
           "Client hydration may break for requests served by this previous bundle hash."
    end
    private_class_method :warn_if_missing_loadable_stats

    def self.required_rsc_asset_basenames
      RendererCacheHelpers.required_rsc_asset_basenames
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

    # No-ops when `cache_dir` does not exist yet. On Docker-style deploys (cache
    # rebuilt from an immutable image layer each release) that's the desired
    # behavior. On persistent-volume deploys where the cache survives across
    # releases but `cache_dir` was wiped between runs, orphaned `.staging-*` /
    # `.previous-*` dirs from a prior run would re-appear when the volume is
    # remounted under a fresh, empty `cache_dir` — they'll be swept on the next
    # successful seeding pass once `cache_dir` is recreated, not this one.
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

    # Even after SAFE_HASH_PATTERN, a hash like `release.staging-1-abcdef12345678`
    # is allowed by the character class but also matches TEMPORARY_DIRECTORY_PATTERN
    # — staging that hash would create a directory the next sweep silently evicts.
    # Webpack content hashes are pure hex and won't collide, but the protocol is
    # open to user-supplied adapters whose hashes could embed dots (OCI tags,
    # human-readable release names, etc.). Reject both buckets in one pass so the
    # warning lists every offending hash for the operator at the source.
    def self.sanitize_hashes(hash_values, source_label:)
      hashes = Array(hash_values).map { |value| value.to_s.strip }.reject(&:empty?)
      invalid = (hashes.grep_v(SAFE_HASH_PATTERN) + hashes.grep(TEMPORARY_DIRECTORY_PATTERN)).uniq
      if invalid.any?
        warn "[ReactOnRailsPro] #{source_label} returned invalid hash values (rejected): #{invalid.inspect}. " \
             "Hashes must match /#{SAFE_HASH_PATTERN.source}/ and not look like renderer-cache staging " \
             "directories to stay within the renderer cache directory."
      end
      hashes - invalid
    end
    private_class_method :sanitize_hashes

    def self.bundle_directory(cache_dir, hash)
      # File.realpath requires the cache root to exist; the caller in `call` is
      # responsible for `FileUtils.mkdir_p(cache_dir)` once at least one hash is
      # known to need staging. Keeping the mkdir here would make every call to
      # this pure-looking helper mutate the filesystem.
      normalized_cache_dir = File.realpath(cache_dir)
      normalized_candidate = File.expand_path(File.join(normalized_cache_dir, hash))

      # Require the candidate to be a *subdirectory* of the cache root, not the
      # cache root itself. `sanitize_hashes` already rejects `""` / `.` / `..`,
      # so the equality case is unreachable today; enforcing `start_with?` only
      # keeps staging safe even if sanitization ever regressed (a bundle landing
      # directly at `<cache>/<hash>.js` instead of `<cache>/<hash>/<hash>.js`
      # would break the renderer's lookup layout silently).
      return normalized_candidate if normalized_candidate.start_with?("#{normalized_cache_dir}#{File::SEPARATOR}")

      raise ReactOnRailsPro::Error,
            "Refusing to stage rolling-deploy bundle hash #{hash.inspect} outside renderer cache dir " \
            "#{normalized_cache_dir.inspect}."
    end
    private_class_method :bundle_directory

    # There is a brief window between the two `mv` calls below where `bundle_dir`
    # does not exist on disk. A renderer lookup for this hash during that window
    # would miss the cache and fall back to the runtime 410-retry path — a single
    # cold-start, not a correctness regression. On Linux/same-filesystem deploys
    # `File.rename` is atomic at the kernel level, so the window is sub-millisecond.
    # On cross-filesystem or NFS mounts, `FileUtils.mv` falls back to copy+delete
    # and the window can widen to seconds. The trade-off is intentional: this
    # design favors full-replacement atomicity (no half-staged dir ever observed)
    # over zero-downtime swap, since the 410-retry fallback bounds the worst case.
    def self.replace_bundle_directory(staging_dir, bundle_dir)
      backup_dir = nil
      if File.exist?(bundle_dir)
        backup_dir = "#{bundle_dir}.previous-#{Process.pid}-#{SecureRandom.hex(6)}"
        FileUtils.mv(bundle_dir, backup_dir)
      end

      # Guard against a concurrent writer recreating bundle_dir between the
      # backup move and this promotion. Without this check FileUtils.mv would
      # nest staging_dir *inside* the racing dir (yielding `<hash>/<staging-dir>/<hash>.js`),
      # and renderer lookups would miss the cache. The rescue below restores
      # the backup so the previous good copy remains servable.
      if File.exist?(bundle_dir)
        raise ReactOnRailsPro::Error,
              "Concurrent writer recreated #{bundle_dir} between backup and promote; aborting promotion"
      end

      FileUtils.mv(staging_dir, bundle_dir)
      nested_staging_dir = File.join(bundle_dir, File.basename(staging_dir))
      if File.directory?(nested_staging_dir)
        FileUtils.rm_rf(nested_staging_dir)
        raise ReactOnRailsPro::Error,
              "Concurrent writer recreated #{bundle_dir} before promotion completed; aborting promotion"
      end
      puts "[ReactOnRailsPro] Staged previous bundle hash into #{bundle_dir}"
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
      return unless backup_dir && File.exist?(backup_dir)

      if File.exist?(bundle_dir)
        warn "[ReactOnRailsPro] Cannot restore previous rolling-deploy bundle directory because #{bundle_dir} " \
             "already exists. Leaving that concurrent writer's directory intact; #{backup_dir} will be swept later."
        return
      end

      # If a concurrent writer recreates bundle_dir between the check above and the mv below,
      # the rescue catches the resulting error and leaves that writer's directory intact.
      FileUtils.mv(backup_dir, bundle_dir)
    rescue StandardError => e
      warn "[ReactOnRailsPro] Could not restore previous rolling-deploy bundle directory #{backup_dir} " \
           "to #{bundle_dir}: #{e.class}: #{e.message}. Runtime 410-retry remains the fallback."
    end
    private_class_method :restore_previous_bundle_directory
  end
end

# frozen_string_literal: true

require "fileutils"
require "pathname"
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
  module RollingDeployCacheStager
    DISCOVERY_TIMEOUT_SECONDS = 10
    FETCH_TIMEOUT_SECONDS = 30

    def self.call(cache_dir:, current_hashes:, mode:)
      adapter = ReactOnRailsPro.configuration.rolling_deploy_adapter
      return handle_missing_adapter unless adapter

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
    SAFE_HASH_PATTERN = /\A(?!\.{1,2}\z)[A-Za-z0-9_\-.]+\z/

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
      bundle_dir = nil
      payload = fetch_payload(adapter, hash)
      return if payload.nil?

      bundle_dir = bundle_directory(cache_dir, hash)
      stage_file(payload[:bundle], File.join(bundle_dir, "#{hash}.js"), mode)

      Array(payload[:assets]).each do |asset_path|
        stage_file(asset_path, File.join(bundle_dir, File.basename(asset_path)), mode)
      end
    rescue StandardError => e
      # Roll back the entire hash directory. Leaving the bundle file in place
      # without its companion assets would cause the renderer to find the bundle
      # (skipping its 410 path) and emit HTML referencing chunks from a manifest
      # that never got staged — producing hydration failures instead of the clean
      # 410-retry fallback that we rely on for degradation.
      FileUtils.rm_rf(bundle_dir) if bundle_dir
      warn "[ReactOnRailsPro] Failed to seed previous bundle hash #{hash}: #{e.class}: #{e.message}. " \
           "Rolled back partially-staged files. Runtime 410-retry remains the fallback."
    end
    private_class_method :seed_previous_hash

    def self.fetch_payload(adapter, hash)
      payload = Timeout.timeout(FETCH_TIMEOUT_SECONDS) { adapter.fetch(hash) }
      if payload.nil?
        warn "[ReactOnRailsPro] rolling_deploy_adapter#fetch(#{hash.inspect}) returned nil. " \
             "Runtime 410-retry path remains available as fallback."
        return nil
      end

      unless payload[:bundle] && File.exist?(payload[:bundle])
        warn "[ReactOnRailsPro] rolling_deploy_adapter#fetch(#{hash.inspect}) returned payload without " \
             "a valid :bundle path. Skipping this hash."
        return nil
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

    def self.stage_file(src, dest, mode)
      FileUtils.mkdir_p(File.dirname(dest))
      FileUtils.rm_f(dest)

      if mode == :copy
        FileUtils.cp(src, dest)
        puts "[ReactOnRailsPro] Seeded (copy) previous bundle file: #{dest}"
      else
        make_relative_symlink(src, dest)
      end
    end
    private_class_method :stage_file

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
      candidate = File.join(cache_dir, hash)
      normalized_cache_dir = File.expand_path(cache_dir)
      normalized_candidate = File.expand_path(candidate)

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

    # Mirrors PreSeedRendererCache.make_relative_symlink so previous-hash
    # symlinks have identical properties (relative path, realpath-canonicalized)
    # to current-hash symlinks.
    def self.make_relative_symlink(source, destination)
      destination_dir = Pathname.new(destination).dirname
      source_path = Pathname.new(source).realpath
      relative_source_path = source_path.relative_path_from(destination_dir.realpath)
      File.symlink(relative_source_path, destination)
      puts "[ReactOnRailsPro] Seeded (symlink) previous bundle file: #{relative_source_path} -> #{destination}"
    rescue Errno::ENOENT => e
      raise ReactOnRailsPro::Error,
            "Could not resolve real path for symlink source #{source} (#{e.message}). " \
            "The file may have been removed or be a dangling symlink."
    end
    private_class_method :make_relative_symlink
  end
end

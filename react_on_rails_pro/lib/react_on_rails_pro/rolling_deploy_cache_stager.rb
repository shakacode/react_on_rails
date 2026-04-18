# frozen_string_literal: true

require "fileutils"

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
  #     :server_bundle (String path), :rsc_bundle (String path or nil),
  #     and :assets (Array<String>). Returns nil if the bundle is unavailable.
  #
  # Missing previous bundles degrade gracefully (warn + continue) because the
  # runtime 410-retry path is still a valid fallback — a failed rolling-deploy
  # seed is less catastrophic than a failed *current* bundle seed.
  module RollingDeployCacheStager
    module_function

    def call(cache_dir:, current_hashes:, mode:)
      adapter = ReactOnRailsPro.configuration.rolling_deploy_adapter
      return if adapter.nil? && ENV["PREVIOUS_BUNDLE_HASHES"].to_s.empty?

      hashes = resolve_previous_hashes(adapter, current_hashes)
      if hashes.empty?
        puts "[ReactOnRailsPro] No previous bundle hashes to seed for rolling deploy."
        return
      end

      puts "[ReactOnRailsPro] Seeding previous bundle hashes for rolling deploy: #{hashes.inspect}"
      hashes.each { |hash| seed_previous_hash(adapter, hash, cache_dir, mode) }
    end

    def resolve_previous_hashes(adapter, current_hashes)
      explicit = ENV["PREVIOUS_BUNDLE_HASHES"].to_s.split(",").map(&:strip).reject(&:empty?)
      hashes = explicit.any? ? explicit : fetch_hashes_from_adapter(adapter)
      # Deduplicate against the hashes we just staged so we don't re-fetch the current build.
      hashes - Array(current_hashes).map(&:to_s)
    end
    private_class_method :resolve_previous_hashes

    def fetch_hashes_from_adapter(adapter)
      return [] if adapter.nil?

      Array(adapter.previous_bundle_hashes)
    rescue StandardError => e
      warn "[ReactOnRailsPro] rolling_deploy_adapter#previous_bundle_hashes raised #{e.class}: #{e.message}. " \
           "Skipping previous-hash seeding."
      []
    end
    private_class_method :fetch_hashes_from_adapter

    def seed_previous_hash(adapter, hash, cache_dir, mode)
      payload = fetch_payload(adapter, hash)
      return if payload.nil?

      bundle_dir = File.join(cache_dir, hash)
      stage_file(payload[:server_bundle], File.join(bundle_dir, "#{hash}.js"), mode)

      if payload[:rsc_bundle]
        # The RSC bundle has its own hash subdirectory at runtime; but for rolling
        # deploys the adapter returns the RSC bundle associated with this hash so we
        # drop it next to the server bundle. Adapters that key RSC separately should
        # emit the RSC hash via previous_bundle_hashes.
        stage_file(payload[:rsc_bundle], File.join(bundle_dir, File.basename(payload[:rsc_bundle])), mode)
      end

      Array(payload[:assets]).each do |asset_path|
        stage_file(asset_path, File.join(bundle_dir, File.basename(asset_path)), mode)
      end
    rescue StandardError => e
      warn "[ReactOnRailsPro] Failed to seed previous bundle hash #{hash}: #{e.class}: #{e.message}. " \
           "Runtime 410-retry path remains available as fallback."
    end
    private_class_method :seed_previous_hash

    def fetch_payload(adapter, hash)
      payload = adapter.fetch(hash)
      if payload.nil?
        warn "[ReactOnRailsPro] rolling_deploy_adapter#fetch(#{hash.inspect}) returned nil. " \
             "Runtime 410-retry path remains available as fallback."
        return nil
      end

      unless payload[:server_bundle] && File.exist?(payload[:server_bundle])
        warn "[ReactOnRailsPro] rolling_deploy_adapter#fetch(#{hash.inspect}) returned payload without " \
             "a valid :server_bundle path. Skipping this hash."
        return nil
      end

      payload
    end
    private_class_method :fetch_payload

    def stage_file(src, dest, mode)
      FileUtils.mkdir_p(File.dirname(dest))
      FileUtils.rm_f(dest)

      if mode == :copy
        FileUtils.cp(src, dest)
        puts "[ReactOnRailsPro] Seeded (copy) previous bundle file: #{dest}"
      else
        File.symlink(File.expand_path(src), dest)
        puts "[ReactOnRailsPro] Seeded (symlink) previous bundle file: #{dest}"
      end
    end
    private_class_method :stage_file
  end
end

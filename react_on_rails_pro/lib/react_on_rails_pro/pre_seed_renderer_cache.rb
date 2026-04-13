# frozen_string_literal: true

require "fileutils"

module ReactOnRailsPro
  # Pre-seeds the Node Renderer bundle cache by copying compiled server bundles
  # into the renderer's expected directory structure. Designed for Docker builds
  # where the bundle can be baked into the image, eliminating the 410→retry
  # cold-start latency on first SSR request after deployment.
  #
  # Unlike PrepareNodeRenderBundles (which creates symlinks for local/CI use),
  # this class copies files and uses the subdirectory structure the renderer
  # expects: <cache>/<bundleHash>/<bundleHash>.js
  class PreSeedRendererCache
    def self.call
      cache_dir = resolve_cache_dir
      pool = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool

      # Pre-seed server bundle
      server_bundle_path = ReactOnRails::Utils.server_bundle_js_file_path
      validate_bundle_exists!(server_bundle_path)
      server_bundle_hash = pool.server_bundle_hash
      seed_bundle(server_bundle_path, server_bundle_hash, cache_dir)

      # Collect assets to copy
      assets = collect_assets

      # Copy assets into the server bundle directory
      copy_assets(assets, File.join(cache_dir, server_bundle_hash.to_s))

      # Pre-seed RSC bundle if enabled
      return unless ReactOnRailsPro.configuration.enable_rsc_support

      rsc_bundle_path = ReactOnRailsPro::Utils.rsc_bundle_js_file_path
      validate_bundle_exists!(rsc_bundle_path)
      rsc_bundle_hash = pool.rsc_bundle_hash
      seed_bundle(rsc_bundle_path, rsc_bundle_hash, cache_dir)
      copy_assets(assets, File.join(cache_dir, rsc_bundle_hash.to_s))
    end

    def self.resolve_cache_dir
      if ENV["RENDERER_SERVER_BUNDLE_CACHE_PATH"].present?
        ENV["RENDERER_SERVER_BUNDLE_CACHE_PATH"]
      elsif ENV["RENDERER_BUNDLE_PATH"].present?
        warn "[ReactOnRailsPro] RENDERER_BUNDLE_PATH is deprecated. " \
             "Use RENDERER_SERVER_BUNDLE_CACHE_PATH instead."
        ENV["RENDERER_BUNDLE_PATH"]
      else
        Rails.root.join(".node-renderer-bundles").to_s
      end
    end
    private_class_method :resolve_cache_dir

    def self.validate_bundle_exists!(path)
      return if File.exist?(path)

      raise ReactOnRailsPro::Error, "Bundle not found at #{path}. " \
                                    "Please build your bundles before pre-seeding the renderer cache."
    end
    private_class_method :validate_bundle_exists!

    def self.seed_bundle(src_path, bundle_hash, cache_dir)
      bundle_dir = File.join(cache_dir, bundle_hash.to_s)
      dest_file = File.join(bundle_dir, "#{bundle_hash}.js")
      FileUtils.mkdir_p(bundle_dir)
      FileUtils.cp(src_path, dest_file)
      puts "[ReactOnRailsPro] Pre-seeded renderer cache: #{dest_file}"
    end
    private_class_method :seed_bundle

    def self.collect_assets
      assets = Array(ReactOnRailsPro.configuration.assets_to_copy).dup

      if ReactOnRailsPro.configuration.enable_rsc_support
        assets << ReactOnRailsPro::Utils.react_client_manifest_file_path
        assets << ReactOnRailsPro::Utils.react_server_client_manifest_file_path
      end

      assets.compact
    end
    private_class_method :collect_assets

    def self.copy_assets(assets, bundle_dir)
      assets.each do |asset_path|
        unless File.exist?(asset_path.to_s)
          warn "[ReactOnRailsPro] Asset not found #{asset_path}"
          next
        end

        dest = File.join(bundle_dir, File.basename(asset_path.to_s))
        FileUtils.cp(asset_path.to_s, dest)
        puts "[ReactOnRailsPro] Copied asset: #{dest}"
      end
    end
    private_class_method :copy_assets
  end
end

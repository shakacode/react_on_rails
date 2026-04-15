# frozen_string_literal: true

require "fileutils"
require "set"

module ReactOnRailsPro
  # Pre-seeds the Node Renderer bundle cache by copying compiled server bundles
  # into the renderer's expected directory structure. Designed for Docker builds
  # where the bundle can be baked into the image, eliminating the 410→retry
  # cold-start latency on first SSR request after deployment.
  #
  # Unlike PrepareNodeRenderBundles (which stages the same cache layout via
  # symlinks for same-filesystem workflows), this class copies files so the
  # cache can be baked into an image or other immutable artifact.
  class PreSeedRendererCache
    def self.call
      cache_dir = resolve_cache_dir
      puts "[ReactOnRailsPro] Pre-seeding renderer cache in: #{cache_dir}"
      pool = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool

      # Pre-seed server bundle
      server_bundle_path = ReactOnRails::Utils.server_bundle_js_file_path
      validate_bundle_exists!(server_bundle_path)
      server_bundle_hash = pool.server_bundle_hash
      seed_bundle(server_bundle_path, server_bundle_hash, cache_dir)

      # Collect assets to copy
      assets = collect_assets

      # Copy assets (including RSC manifests) into the server bundle directory.
      # The Node Renderer serves manifests from whichever bundle dir it loaded,
      # so both server and RSC dirs need the manifests present.
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
      ReactOnRailsPro::Utils.resolve_renderer_cache_dir
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

      assets.compact_blank
    end
    private_class_method :collect_assets

    # RSC manifests are required when RSC is enabled — a missing manifest would cause
    # the renderer to fail at runtime with a hard-to-diagnose error. User-configured
    # assets_to_copy are optional and only produce a warning.
    def self.copy_assets(assets, bundle_dir)
      rsc_required = Set.new
      if ReactOnRailsPro.configuration.enable_rsc_support
        rsc_required << File.basename(ReactOnRailsPro::Utils.react_client_manifest_file_path.to_s)
        rsc_required << File.basename(ReactOnRailsPro::Utils.react_server_client_manifest_file_path.to_s)
      end

      assets.each do |asset_path|
        basename = File.basename(asset_path.to_s)
        unless File.exist?(asset_path.to_s)
          if rsc_required.include?(basename)
            raise ReactOnRailsPro::Error, "Required RSC asset not found: #{asset_path}. " \
                                          "Build your bundles before pre-seeding the renderer cache."
          end
          warn "[ReactOnRailsPro] Asset not found #{asset_path}"
          next
        end

        dest = File.join(bundle_dir, basename)
        FileUtils.cp(asset_path.to_s, dest)
        puts "[ReactOnRailsPro] Copied asset: #{dest}"
      end
    end
    private_class_method :copy_assets
  end
end

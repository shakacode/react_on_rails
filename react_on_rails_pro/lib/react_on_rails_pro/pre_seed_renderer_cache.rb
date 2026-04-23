# frozen_string_literal: true

require "react_on_rails_pro/renderer_cache_helpers"

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
      cache_dir = ReactOnRailsPro::Utils.resolve_renderer_cache_dir
      puts "[ReactOnRailsPro] Pre-seeding renderer cache in: #{cache_dir}"
      pool = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool

      assets = RendererCacheHelpers.collect_assets
      rsc_required_paths = RendererCacheHelpers.required_rsc_asset_paths

      RendererCacheHelpers.bundle_sources(pool, "pre-seeding").each do |src_bundle_path, bundle_hash|
        seed_bundle(src_bundle_path, bundle_hash, cache_dir)
        # The Node Renderer serves manifests from whichever bundle dir it loaded,
        # so both server and RSC dirs need the manifests present.
        copy_assets(assets, File.join(cache_dir, bundle_hash.to_s), rsc_required_paths)
      end
    end

    def self.seed_bundle(src_path, bundle_hash, cache_dir)
      bundle_dir = File.join(cache_dir, bundle_hash.to_s)
      dest_file = File.join(bundle_dir, "#{bundle_hash}.js")
      RendererCacheHelpers.copy_file_atomically(src_path, dest_file, log_prefix: "Pre-seeded renderer cache")
    end
    private_class_method :seed_bundle

    # RSC manifests are required when RSC is enabled — a missing manifest would
    # cause the renderer to fail at runtime with a hard-to-diagnose error.
    # User-configured assets_to_copy are optional and only produce a warning.
    def self.copy_assets(assets, bundle_dir, rsc_required_paths)
      RendererCacheHelpers.each_stageable_asset(assets, rsc_required_paths, "pre-seeding") do |expanded|
        dest = File.join(bundle_dir, File.basename(expanded))
        RendererCacheHelpers.copy_file_atomically(expanded, dest, log_prefix: "Copied asset")
      end
    end
    private_class_method :copy_assets
  end
end

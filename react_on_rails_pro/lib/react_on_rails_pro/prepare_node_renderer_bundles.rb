# frozen_string_literal: true

require "fileutils"
require "pathname"
require "react_on_rails_pro/renderer_cache_helpers"

module ReactOnRailsPro
  # Pre-stages the Node Renderer cache via symlinks for same-filesystem workflows
  # such as local development, Heroku-style same-dyno deploys, and bundle-caching
  # restores. The staged layout matches the renderer's runtime cache contract:
  # <cache>/<bundleHash>/<bundleHash>.js
  class PrepareNodeRenderBundles
    def self.make_relative_symlink(source, destination)
      destination_dir = Pathname.new(destination).dirname
      FileUtils.mkdir_p(destination_dir)
      FileUtils.rm_f(destination)

      # Canonicalize both sides so paths like /var -> /private/var do not
      # produce broken relative symlinks when the cache dir comes from tmpdir.
      source_path = Pathname.new(source).realpath
      relative_source_path = source_path.relative_path_from(destination_dir.realpath)
      File.symlink(relative_source_path, destination)
      puts "[ReactOnRailsPro] Symlinked #{relative_source_path} to #{destination}"
    end
    private_class_method :make_relative_symlink

    def self.resolve_dest_path
      ReactOnRailsPro::Utils.resolve_renderer_cache_dir
    end
    private_class_method :resolve_dest_path

    def self.call
      cache_dir = resolve_dest_path
      pool = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool
      puts "[ReactOnRailsPro] Pre-staging renderer cache via symlinks at: #{cache_dir}"

      assets = RendererCacheHelpers.collect_assets
      rsc_required_paths = RendererCacheHelpers.required_rsc_asset_paths

      RendererCacheHelpers.bundle_sources(pool, "pre-staging").each do |src_bundle_path, bundle_hash|
        bundle_dir = File.join(cache_dir, bundle_hash.to_s)
        bundle_dest_path = File.join(bundle_dir, "#{bundle_hash}.js")
        make_relative_symlink(src_bundle_path, bundle_dest_path)
        symlink_assets(assets, bundle_dir, rsc_required_paths)
      end
    end

    # Required assets are matched by expanded path rather than basename so a
    # same-named unrelated entry in assets_to_copy cannot trigger a false-
    # positive "required" error. Expand against Rails.root to match how
    # RendererCacheHelpers.required_rsc_asset_paths builds its Set.
    def self.symlink_assets(assets, bundle_dir, rsc_required_paths)
      assets.each do |asset_path|
        expanded = File.expand_path(asset_path.to_s, Rails.root)
        unless File.exist?(expanded)
          if rsc_required_paths.include?(expanded)
            raise ReactOnRailsPro::Error, "Required RSC asset not found: #{asset_path}. " \
                                          "Build your bundles before pre-staging the renderer cache."
          end
          warn "[ReactOnRailsPro] Asset not found #{asset_path}"
          next
        end

        destination_full_path = File.join(bundle_dir, File.basename(expanded))
        make_relative_symlink(expanded, destination_full_path)
      end
    end
    private_class_method :symlink_assets
  end
end

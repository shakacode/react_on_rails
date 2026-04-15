# frozen_string_literal: true

require "pathname"
require "set"

module ReactOnRailsPro
  # Pre-stages the Node Renderer cache via symlinks for same-filesystem workflows
  # such as local development, Heroku-style same-dyno deploys, and bundle-caching
  # restores. The staged layout matches the renderer's runtime cache contract:
  # <cache>/<bundleHash>/<bundleHash>.js
  class PrepareNodeRenderBundles
    extend FileUtils

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

    def self.resolve_dest_path
      ReactOnRailsPro::Utils.resolve_renderer_cache_dir
    end
    private_class_method :resolve_dest_path

    def self.call
      cache_dir = resolve_dest_path
      pool = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool
      puts "[ReactOnRailsPro] Pre-staging renderer cache via symlinks at: #{cache_dir}"

      bundle_sources.each do |src_bundle_path, bundle_hash_method|
        validate_bundle_exists!(src_bundle_path)
        bundle_hash = pool.public_send(bundle_hash_method)
        bundle_dir = File.join(cache_dir, bundle_hash.to_s)
        bundle_dest_path = File.join(bundle_dir, "#{bundle_hash}.js")
        make_relative_symlink(src_bundle_path, bundle_dest_path)
        symlink_assets(collect_assets, bundle_dir)
      end
    end

    def self.bundle_sources
      sources = [[ReactOnRails::Utils.server_bundle_js_file_path, :server_bundle_hash]]

      return sources unless ReactOnRailsPro.configuration.enable_rsc_support

      sources << [ReactOnRailsPro::Utils.rsc_bundle_js_file_path, :rsc_bundle_hash]
      sources
    end
    private_class_method :bundle_sources

    def self.collect_assets
      assets = Array(ReactOnRailsPro.configuration.assets_to_copy).dup

      if ReactOnRailsPro.configuration.enable_rsc_support
        assets << ReactOnRailsPro::Utils.react_client_manifest_file_path
        assets << ReactOnRailsPro::Utils.react_server_client_manifest_file_path
      end

      assets.compact
    end
    private_class_method :collect_assets

    def self.required_rsc_assets
      return Set.new unless ReactOnRailsPro.configuration.enable_rsc_support

      Set.new(
        [
          File.basename(ReactOnRailsPro::Utils.react_client_manifest_file_path.to_s),
          File.basename(ReactOnRailsPro::Utils.react_server_client_manifest_file_path.to_s)
        ]
      )
    end
    private_class_method :required_rsc_assets

    def self.symlink_assets(assets, bundle_dir)
      assets.each do |asset_path|
        basename = File.basename(asset_path.to_s)
        unless File.exist?(asset_path.to_s)
          if required_rsc_assets.include?(basename)
            raise ReactOnRailsPro::Error, "Required RSC asset not found: #{asset_path}. " \
                                          "Build your bundles before pre-staging the renderer cache."
          end
          warn "Asset not found #{asset_path}"
          next
        end

        destination_full_path = File.join(bundle_dir, basename)
        make_relative_symlink(asset_path.to_s, destination_full_path)
      end
    end
    private_class_method :symlink_assets

    def self.validate_bundle_exists!(path)
      return if File.exist?(path)

      raise ReactOnRailsPro::Error, "Bundle not found at #{path}. " \
                                    "Please build your bundles before pre-staging the renderer cache."
    end
    private_class_method :validate_bundle_exists!
  end
end

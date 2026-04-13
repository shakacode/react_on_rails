# frozen_string_literal: true

require "pathname"

module ReactOnRailsPro
  class PrepareNodeRenderBundles
    extend FileUtils

    def self.make_relative_symlink(source, destination)
      FileUtils.rm_f(destination)
      relative_source_path = Pathname.new(source).relative_path_from(Pathname.new(destination).dirname)
      File.symlink(relative_source_path, destination)
      puts "[ReactOnRailsPro] Symlinked #{relative_source_path} to #{destination}"
    end

    def self.resolve_dest_path
      if ENV["RENDERER_BUNDLE_PATH"].present?
        warn "[ReactOnRailsPro] RENDERER_BUNDLE_PATH is deprecated. " \
             "Use RENDERER_SERVER_BUNDLE_CACHE_PATH instead."
      end
      ENV["RENDERER_SERVER_BUNDLE_CACHE_PATH"].presence ||
        ENV["RENDERER_BUNDLE_PATH"].presence ||
        Rails.root.join(".node-renderer-bundles").to_s
    end
    private_class_method :resolve_dest_path

    def self.call
      # TODO: temporarily hardcoding tmp/bundles directory. renderer and rails should read from a Yaml file
      src_bundle_path = ReactOnRails::Utils.server_bundle_js_file_path
      renderer_bundle_file_name = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool.renderer_bundle_file_name
      dest_path = resolve_dest_path
      bundle_dest_path = File.join(dest_path, renderer_bundle_file_name.to_s).to_s
      puts "[ReactOnRailsPro] Symlinking assets to local node-renderer, path #{dest_path}"
      mkdir_p(dest_path)

      make_relative_symlink(src_bundle_path, bundle_dest_path)

      return unless ReactOnRailsPro.configuration.assets_to_copy.present?

      ReactOnRailsPro.configuration.assets_to_copy.each do |asset_path|
        unless File.exist?(asset_path)
          warn "Asset not found #{asset_path}"
          next
        end

        destination_full_path = File.join(dest_path, asset_path.basename.to_s)
        make_relative_symlink(asset_path, destination_full_path)
      end
    end
  end
end

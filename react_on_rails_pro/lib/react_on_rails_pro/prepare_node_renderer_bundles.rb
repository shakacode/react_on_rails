# frozen_string_literal: true

require "pathname"

module ReactOnRailsPro
  class PrepareNodeRenderBundles
    extend FileUtils

    # rubocop:disable Metrics/AbcSize
    def self.call
      # TODO: temporarily hardcoding tmp/bundles directory. renderer and rails should read from a Yaml file
      src_bundle_path = ReactOnRails::Utils.server_bundle_js_file_path
      renderer_bundle_file_name = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool.renderer_bundle_file_name
      dest_path = ENV["RENDERER_BUNDLE_PATH"].presence || Rails.root.join(".node-renderer-bundles").to_s
      bundle_dest_path = File.join(dest_path, renderer_bundle_file_name.to_s).to_s
      puts "[ReactOnRailsPro] Symlinking assets to local node-renderer, path #{dest_path}"
      mkdir_p(dest_path)

      File.delete(bundle_dest_path) if File.exist?(bundle_dest_path)
      relative_source_path = Pathname.new(src_bundle_path).relative_path_from(Pathname.new(bundle_dest_path).dirname)
      symlink(relative_source_path, bundle_dest_path)
      puts "[ReactOnRailsPro] Symlinked #{relative_source_path} to #{bundle_dest_path}"

      return unless ReactOnRailsPro.configuration.assets_to_copy.present?

      ReactOnRailsPro.configuration.assets_to_copy.each do |asset_path|
        raise ReactOnRails::Error, "Asset not found #{asset_path}" unless File.exist?(asset_path)

        destination_full_path = File.join(dest_path, asset_path.basename.to_s)
        File.delete(destination_full_path) if File.exist?(destination_full_path)
        symlink(asset_path, destination_full_path)
        puts "[ReactOnRailsPro] Symlinked #{asset_path} to #{destination_full_path}"
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end

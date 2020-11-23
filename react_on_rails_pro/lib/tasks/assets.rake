# frozen_string_literal: true

require "active_support"

namespace :react_on_rails_pro do
  desc "Copy assets to local vm-renderer"
  task pre_stage_bundle_for_vm_renderer: :environment do
    # TODO: temporarily hardcoding tmp/bundles directory. renderer and rails should read from a Yaml file
    src_bundle_path = ReactOnRails::Utils.server_bundle_js_file_path
    renderer_bundle_file_name = ReactOnRailsPro::ServerRenderingPool::VmRenderingPool.renderer_bundle_file_name
    dest_path = ENV["RENDERER_BUNDLE_PATH"].presence || Rails.root.join("tmp", "bundles").to_s
    bundle_dest_path = File.join(dest_path, renderer_bundle_file_name.to_s).to_s
    puts "[ReactOnRailsPro] Copying assets to local vm-renderer, path #{dest_path}"
    puts "[ReactOnRailsPro] Bundle file is copied to #{bundle_dest_path}"
    mkdir_p(dest_path)
    cp src_bundle_path, bundle_dest_path

    if ReactOnRailsPro.configuration.assets_to_copy.present?
      ReactOnRailsPro.configuration.assets_to_copy.each do |asset_path|
        raise ReactOnRails::Error, "Asset not found #{asset_path}" unless File.exist?(asset_path)

        cp asset_path, dest_path
      end
    end
  end

  desc "Copy assets to remote vm-renderer"
  task copy_assets_to_remote_vm_renderer: :environment do
    puts "[ReactOnRailsPro] Copying assets to remote vm-renderer #{ReactOnRailsPro.configuration.renderer_url}"
    ReactOnRailsPro::Request.upload_assets
  end
end

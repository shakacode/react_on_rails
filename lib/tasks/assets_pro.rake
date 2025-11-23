# frozen_string_literal: true

require "active_support"

namespace :react_on_rails_pro do
  desc "Copy assets to local node-renderer"
  task pre_stage_bundle_for_node_renderer: :environment do
    ReactOnRailsPro::PrepareNodeRenderBundles.call
  end

  desc "Copy assets to remote node-renderer"
  task copy_assets_to_remote_vm_renderer: :environment do
    puts "[ReactOnRailsPro] Copying assets to remote node-renderer #{ReactOnRailsPro.configuration.renderer_url}"
    ReactOnRailsPro::Request.upload_assets
  end
end

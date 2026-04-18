# frozen_string_literal: true

require "active_support"

namespace :react_on_rails_pro do
  desc "Stage the Node Renderer bundle cache. MODE=copy (default; Docker/image builds) " \
       "or MODE=symlink (dev/CI/same-filesystem deploys)."
  task pre_seed_renderer_cache: :environment do
    mode = (ENV["MODE"] || "copy").to_sym
    ReactOnRailsPro::PreSeedRendererCache.call(mode: mode)
  end

  # Deprecated alias. Delegates to pre_seed_renderer_cache with MODE=symlink so
  # existing Procfile/Dockerfile/deploy-script entries keep working during the
  # deprecation cycle.
  desc "DEPRECATED: use 'pre_seed_renderer_cache MODE=symlink' instead."
  task pre_stage_bundle_for_node_renderer: :environment do
    warn "[ReactOnRailsPro] The 'react_on_rails_pro:pre_stage_bundle_for_node_renderer' rake task " \
         "is deprecated. Use 'rake react_on_rails_pro:pre_seed_renderer_cache MODE=symlink' instead."
    ReactOnRailsPro::PreSeedRendererCache.call(mode: :symlink)
  end

  desc "Copy assets to remote node-renderer"
  task copy_assets_to_remote_vm_renderer: :environment do
    puts "[ReactOnRailsPro] Copying assets to remote node-renderer #{ReactOnRailsPro.configuration.renderer_url}"
    ReactOnRailsPro::Request.upload_assets
  end
end

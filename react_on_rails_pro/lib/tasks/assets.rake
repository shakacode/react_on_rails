# frozen_string_literal: true

require "active_support"

namespace :react_on_rails_pro do
  desc "Stage the Node Renderer bundle cache. MODE=copy (default; Docker/image builds) " \
       "or MODE=symlink (dev/CI/same-filesystem deploys)."
  task pre_seed_renderer_cache: :environment do
    raw_mode = ENV["MODE"].to_s.downcase
    raw_mode = "copy" if raw_mode.empty?
    valid_modes = ReactOnRailsPro::PreSeedRendererCache::VALID_MODES.map(&:to_s)
    unless valid_modes.include?(raw_mode)
      abort "[ReactOnRailsPro] Unknown MODE=#{ENV.fetch('MODE', nil).inspect}. " \
            "Expected one of: #{valid_modes.join(', ')}"
    end
    ReactOnRailsPro::PreSeedRendererCache.call(mode: raw_mode.to_sym)
  end

  # Deprecated alias. Delegates to pre_seed_renderer_cache with MODE=symlink so
  # existing Procfile/Dockerfile/deploy-script entries keep working during the
  # deprecation cycle.
  #
  # The warning below fires on every task invocation (it is not guarded by the
  # once-per-process mutex in PrepareNodeRenderBundles). Rake tasks are invoked
  # once per deploy, so repeated output is not a concern here.
  desc "DEPRECATED: use 'pre_seed_renderer_cache' (MODE=copy for Docker, MODE=symlink for same-filesystem)."
  task pre_stage_bundle_for_node_renderer: :environment do
    warn "[ReactOnRailsPro] The 'react_on_rails_pro:pre_stage_bundle_for_node_renderer' rake task is deprecated. " \
         "Migrate to 'rake react_on_rails_pro:pre_seed_renderer_cache' — use MODE=copy (default) for Docker/image " \
         "builds, or MODE=symlink for same-filesystem deploys (this shim preserves the old symlink behavior). " \
         "Run 'rake react_on_rails:doctor' for a per-file migration suggestion based on where the task is referenced."
    ReactOnRailsPro::PreSeedRendererCache.call(mode: :symlink)
  end

  desc "Copy assets to remote node-renderer"
  task copy_assets_to_remote_vm_renderer: :environment do
    puts "[ReactOnRailsPro] Copying assets to remote node-renderer #{ReactOnRailsPro.configuration.renderer_url}"
    ReactOnRailsPro::Request.upload_assets
  end
end

# frozen_string_literal: true

require "set"

module ReactOnRailsPro
  # Shared helpers for staging the Node Renderer bundle cache. Used by both
  # PreSeedRendererCache (copies files for Docker images) and
  # PrepareNodeRenderBundles (symlinks for same-filesystem workflows).
  module RendererCacheHelpers
    module_function

    def collect_assets
      assets = Array(ReactOnRailsPro.configuration.assets_to_copy).dup

      if ReactOnRailsPro.configuration.enable_rsc_support
        assets << ReactOnRailsPro::Utils.react_client_manifest_file_path
        assets << ReactOnRailsPro::Utils.react_server_client_manifest_file_path
      end

      assets.compact_blank
    end

    def required_rsc_asset_paths
      return Set.new unless ReactOnRailsPro.configuration.enable_rsc_support

      Set.new(
        [
          File.expand_path(ReactOnRailsPro::Utils.react_client_manifest_file_path.to_s),
          File.expand_path(ReactOnRailsPro::Utils.react_server_client_manifest_file_path.to_s)
        ]
      )
    end

    def validate_bundle_exists!(path, action_description)
      return if File.exist?(path)

      raise ReactOnRailsPro::Error,
            "Bundle not found at #{path}. " \
            "Please build your bundles before #{action_description} the renderer cache."
    end

    # Resolves bundle sources as [path, hash] pairs so callers can iterate
    # without needing to re-call pool methods. `pool` must respond to
    # `server_bundle_hash` and (when RSC is enabled) `rsc_bundle_hash`.
    def bundle_sources(pool)
      sources = [[ReactOnRails::Utils.server_bundle_js_file_path, pool.server_bundle_hash]]

      return sources unless ReactOnRailsPro.configuration.enable_rsc_support

      sources << [ReactOnRailsPro::Utils.rsc_bundle_js_file_path, pool.rsc_bundle_hash]
      sources
    end
  end
end

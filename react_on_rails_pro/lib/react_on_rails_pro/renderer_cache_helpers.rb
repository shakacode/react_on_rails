# frozen_string_literal: true

require "set"

module ReactOnRailsPro
  # Shared helpers for staging the Node Renderer bundle cache. Used by both
  # PreSeedRendererCache (copies files for Docker images) and
  # PrepareNodeRenderBundles (symlinks for same-filesystem workflows).
  module RendererCacheHelpers
    module_function

    def collect_assets
      config = ReactOnRailsPro.configuration
      assets = Array(config.assets_to_copy).dup

      if config.enable_rsc_support
        assets << ReactOnRailsPro::Utils.react_client_manifest_file_path
        assets << ReactOnRailsPro::Utils.react_server_client_manifest_file_path
      end

      assets.compact_blank
    end

    # Must expand against Rails.root so that callers who expand per-asset paths
    # against the same base produce Set-comparable strings. Without an explicit
    # base, File.expand_path uses Dir.pwd, which differs in Docker RUN steps
    # and would make the Set lookup miss.
    def required_rsc_asset_paths
      return Set.new unless ReactOnRailsPro.configuration.enable_rsc_support

      Set.new(
        [
          File.expand_path(ReactOnRailsPro::Utils.react_client_manifest_file_path.to_s, Rails.root),
          File.expand_path(ReactOnRailsPro::Utils.react_server_client_manifest_file_path.to_s, Rails.root)
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
    #
    # Validates each bundle path exists *before* computing its hash, because
    # `pool.server_bundle_hash` eventually calls `Digest::MD5.file` / `File.mtime`
    # on the bundle path, which raises raw `Errno::ENOENT` if the file is
    # missing — bypassing the friendly `ReactOnRailsPro::Error` message.
    def bundle_sources(pool, action_description)
      server_bundle_path = ReactOnRails::Utils.server_bundle_js_file_path
      validate_bundle_exists!(server_bundle_path, action_description)
      sources = [[server_bundle_path, pool.server_bundle_hash]]

      return sources unless ReactOnRailsPro.configuration.enable_rsc_support

      rsc_bundle_path = ReactOnRailsPro::Utils.rsc_bundle_js_file_path
      validate_bundle_exists!(rsc_bundle_path, action_description)
      sources << [rsc_bundle_path, pool.rsc_bundle_hash]
      sources
    end
  end
end

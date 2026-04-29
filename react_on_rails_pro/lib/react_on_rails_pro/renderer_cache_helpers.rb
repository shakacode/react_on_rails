# frozen_string_literal: true

require "fileutils"
require "securerandom"
require "set"

module ReactOnRailsPro
  # Shared helpers for staging the Node Renderer bundle cache. Used by both
  # PreSeedRendererCache (copies files for Docker images) and
  # PrepareNodeRenderBundles (symlinks for same-filesystem workflows).
  module RendererCacheHelpers
    module_function

    def collect_assets
      config = ReactOnRailsPro.configuration
      # assets_to_copy may include nil entries (user-configured, optional);
      # those are silently dropped by `.compact`. RSC manifests, by contrast,
      # are required, so resolve them separately and fail loudly if either
      # resolves to nil rather than letting `.compact` swallow the gap.
      assets = Array(config.assets_to_copy).dup.compact

      if config.enable_rsc_support
        rsc_manifests = [
          ReactOnRailsPro::Utils.react_client_manifest_file_path,
          ReactOnRailsPro::Utils.react_server_client_manifest_file_path
        ]
        if rsc_manifests.any?(&:nil?)
          raise ReactOnRailsPro::Error,
                "RSC manifest path resolved to nil. " \
                "Check react_client_manifest_file and react_server_client_manifest_file configuration."
        end
        assets.concat(rsc_manifests)
      end

      assets.uniq(&:to_s)
    end

    # Required assets are matched by expanded path rather than basename so a
    # same-named unrelated entry in assets_to_copy cannot trigger a false-
    # positive "required" error. Expand against Rails.root to match how
    # required_rsc_asset_paths builds its Set.
    def each_stageable_asset(assets, rsc_required_paths, action_description)
      assets.each do |asset_path|
        expanded = File.expand_path(asset_path.to_s, Rails.root)
        unless File.file?(expanded)
          if rsc_required_paths.include?(expanded)
            raise ReactOnRailsPro::Error, "Required RSC asset not found or not a file: #{asset_path}. " \
                                          "Build your bundles before #{action_description} the renderer cache."
          end
          warn "[ReactOnRailsPro] Asset not found #{asset_label(asset_path)} (missing or not a file)"
          next
        end

        yield expanded
      end
    end

    def copy_file_atomically(src, dest, log_prefix:)
      FileUtils.mkdir_p(File.dirname(dest))
      tmp_file = "#{dest}.tmp-#{Process.pid}-#{SecureRandom.hex(6)}"
      FileUtils.cp(src, tmp_file)
      File.rename(tmp_file, dest)
      puts "[ReactOnRailsPro] #{log_prefix}: #{dest}"
    ensure
      FileUtils.rm_f(tmp_file) if tmp_file
    end

    def asset_label(asset_path)
      asset_path.to_s.empty? ? "<blank>" : asset_path
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

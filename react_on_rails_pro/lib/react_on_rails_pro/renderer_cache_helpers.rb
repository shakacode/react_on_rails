# frozen_string_literal: true

require "fileutils"
require "securerandom"
require "set"

require "react_on_rails_pro/error"

module ReactOnRailsPro
  # Shared helpers for staging the Node Renderer bundle cache. Used by both
  # PreSeedRendererCache (copies files for Docker images) and
  # PrepareNodeRenderBundles (symlinks for same-filesystem workflows).
  module RendererCacheHelpers
    module_function

    def collect_assets_with_required_paths
      config = ReactOnRailsPro.configuration
      # assets_to_copy may include nil entries (user-configured, optional);
      # those are silently dropped by `.compact`. RSC manifests, by contrast,
      # are required, so resolve them separately and fail loudly if either
      # resolves to nil rather than letting `.compact` swallow the gap.
      assets = Array(config.assets_to_copy).compact
      rsc_manifests = []

      if config.enable_rsc_support
        rsc_manifests = rsc_manifest_paths
        assets.concat(rsc_manifests)
      end

      unique = assets.uniq(&:to_s)
      warn_on_duplicate_basenames(unique)
      [unique, required_rsc_asset_paths(rsc_manifests)]
    end

    def rsc_manifest_paths
      manifests = {
        react_client_manifest_file_path: ReactOnRailsPro::Utils.react_client_manifest_file_path,
        react_server_client_manifest_file_path: ReactOnRailsPro::Utils.react_server_client_manifest_file_path
      }
      nil_manifest_names = manifests.select { |_name, path| path.nil? }.keys
      unless nil_manifest_names.empty?
        raise ReactOnRailsPro::Error,
              "RSC manifest path resolved to nil for #{nil_manifest_names.join(', ')}. " \
              "Check react_client_manifest_file and react_server_client_manifest_file configuration."
      end

      manifests.values
    end

    # `stage_assets` writes each asset into `bundle_dir` using only its basename,
    # so two distinct assets with the same basename (e.g. `/path/a/manifest.json`
    # and `/path/b/manifest.json`) silently overwrite one another. Uniq-by-path
    # cannot detect this; warn so the user notices the misconfiguration.
    def warn_on_duplicate_basenames(assets)
      basenames = assets.reject { |a| http_url?(a) }.map { |a| File.basename(a.to_s) }
      duplicates = basenames.tally.select { |_, count| count > 1 }.keys
      return if duplicates.empty?

      warn "[ReactOnRailsPro] Duplicate asset basenames in assets_to_copy / RSC manifests: " \
           "#{duplicates.join(', ')}. Only the last entry per basename will be staged."
    end

    # Required assets are matched by expanded path rather than basename so a
    # same-named unrelated entry in assets_to_copy cannot trigger a false-
    # positive "required" error. Expand against Rails.root to match how
    # required_rsc_asset_paths builds its Set.
    #
    # URL-backed assets (returned by `asset_uri_from_packer` while the dev
    # server is running) cannot be staged into the local cache; skip them with
    # a warning so the renderer falls back to fetching them at request time
    # rather than aborting the entire pre-seed.
    def each_stageable_asset(assets, rsc_required_paths, action_description)
      assets.each do |asset_path|
        if http_url?(asset_path)
          warn "[ReactOnRailsPro] Skipping URL-backed asset #{asset_path} while " \
               "#{action_description} the renderer cache; the dev server is serving " \
               "this asset, so the renderer will fetch it on first request."
          next
        end

        expanded =
          begin
            File.expand_path(asset_path.to_s, Rails.root)
          rescue ArgumentError => e
            warn "[ReactOnRailsPro] Asset not found #{asset_label(asset_path)} (invalid path: #{e.message})"
            next
          end

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
      puts "[ReactOnRailsPro] #{log_prefix}: #{src} -> #{dest}"
    ensure
      # `tmp_file` is nil if FileUtils.mkdir_p raises before the assignment executes.
      # On success, File.rename has already moved the temp file, so rm_f is a no-op.
      # On failure after assignment, rm_f cleans up the orphaned temp file.
      FileUtils.rm_f(tmp_file) if tmp_file
    end

    def asset_label(asset_path)
      asset_path.to_s.empty? ? "<blank>" : asset_path
    end

    # Mirrors `Request#http_url?`: detects dev-server-served assets returned
    # by `ReactOnRails::PackerUtils.asset_uri_from_packer` so the staging
    # path can skip them instead of treating them as filesystem paths.
    def http_url?(path)
      path.to_s.match?(%r{\Ahttps?://})
    end

    # Must expand against Rails.root so that callers who expand per-asset paths
    # against the same base produce Set-comparable strings. Without an explicit
    # base, File.expand_path uses Dir.pwd, which differs in Docker RUN steps
    # and would make the Set lookup miss.
    #
    # URL-backed manifests (dev server) cannot be staged; exclude them so
    # `each_stageable_asset` does not see them as "required" and raise.
    def required_rsc_asset_paths(manifests)
      return Set.new unless ReactOnRailsPro.configuration.enable_rsc_support

      Set.new(
        manifests
          .reject { |path| http_url?(path) }
          .map { |path| File.expand_path(path.to_s, Rails.root) }
      )
    end

    def validate_bundle_exists!(path, action_description)
      return if File.file?(path)

      raise ReactOnRailsPro::Error,
            "Bundle not found or not a file at #{path}. " \
            "Please build your bundles before #{action_description} the renderer cache."
    end

    # Defense-in-depth against future regressions in the hash-computation path:
    # `calc_bundle_hash` always returns a non-empty string today, but a blank
    # value here would cause `File.join(cache_dir, "")` to resolve to `cache_dir`
    # itself and stage the bundle as `<cache_dir>/.js` — a hidden file the
    # renderer never reads. Fail loudly instead of silently mis-staging.
    #
    # We also reject non-String, non-nil types (e.g. Pathname, Symbol) so a
    # future pool that returns one fails loudly rather than silently producing
    # surprising `File.join` results downstream.
    def validate_bundle_hash!(hash, path)
      unless hash.nil? || hash.is_a?(String)
        raise ReactOnRailsPro::Error,
              "Bundle hash for #{path} must be a String or nil, got #{hash.class}."
      end
      return unless hash.to_s.strip.empty?

      raise ReactOnRailsPro::Error,
            "Bundle hash for #{path} is nil or blank; cannot stage renderer cache."
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
      server_hash = pool.server_bundle_hash
      validate_bundle_hash!(server_hash, server_bundle_path)
      sources = [[server_bundle_path, server_hash]]

      return sources unless ReactOnRailsPro.configuration.enable_rsc_support

      rsc_bundle_path = ReactOnRailsPro::Utils.rsc_bundle_js_file_path
      validate_bundle_exists!(rsc_bundle_path, action_description)
      rsc_hash = pool.rsc_bundle_hash
      validate_bundle_hash!(rsc_hash, rsc_bundle_path)
      sources << [rsc_bundle_path, rsc_hash]
      sources
    end
  end
end

# frozen_string_literal: true

require "active_support/security_utils"

require "react_on_rails_pro/rolling_deploy/safe_hash_pattern"
require "react_on_rails_pro/rolling_deploy/tarball"

module ReactOnRailsPro
  module RollingDeploy
    # Server side of the built-in HTTP rolling-deploy adapter. Exposes the
    # current deployment's bundle hashes (`GET /manifest`) and serves a
    # gzipped tarball per hash (`GET /bundles/:hash`). The
    # ReactOnRailsPro::RollingDeployAdapters::Http adapter on the next
    # deploy's build CI consumes both endpoints.
    #
    # Auto-mounted by the engine when `config.rolling_deploy_adapter` is the
    # Http adapter (or a subclass). Users who need a custom mount path or want
    # to layer their own auth middleware can mount manually:
    #
    #   # config/routes.rb
    #   ReactOnRailsPro::RollingDeploy::BundlesController.draw_routes(
    #     self,
    #     path: "/internal/rolling-deploy"
    #   )
    #
    # Callers that need to mount the controller more than once (for example,
    # the engine auto-mount plus a user-controlled secondary path) must pass
    # a distinct `as_prefix:` per call so Rails' named-route registry
    # doesn't raise `ArgumentError: Invalid route name, already in use`.
    #
    # Security:
    #   * Bearer-token auth via `Authorization: Bearer <token>`, constant-time
    #     compare (ActiveSupport::SecurityUtils.secure_compare). 401 returned
    #     uniformly for missing / malformed / wrong token so callers can't
    #     distinguish failure modes.
    #   * `:hash` URL param is matched against an allowlist of the current
    #     deployment's actual bundle hashes — anything else returns 404. The
    #     hash never touches the filesystem layer.
    #   * Responses include `Cache-Control: no-store` so a misconfigured
    #     intermediary doesn't cache the bundle behind the auth check.
    #   * Inherits from `ActionController::API` rather than `Base`, which
    #     omits cookie/session/view machinery and the CSRF middleware
    #     entirely. CSRF only protects against ambient-credential abuse
    #     (e.g. session cookies a browser auto-attaches); a Bearer-token
    #     API has no ambient credential, so there's nothing for CSRF to
    #     protect. Using API avoids `protect_from_forgery with: :null_session`,
    #     which CodeQL (correctly) flags as weakened CSRF on a Base controller.
    class BundlesController < ActionController::API
      before_action :authenticate_rolling_deploy_request
      before_action :set_no_store_headers

      DEFAULT_ROUTE_PREFIX = "react_on_rails_pro_rolling_deploy"

      class << self
        # Helper for users who want to mount manually under a custom path. The
        # auto-mount path uses these same route definitions via the engine
        # initializer (see ReactOnRailsPro::Engine).
        #
        # `as_prefix:` controls the generated named-route helpers
        # (`<prefix>_manifest`, `<prefix>_bundle`). Callers that mount the
        # controller more than once (e.g. auto-mount plus a secondary user
        # mount) must pass distinct prefixes so the Rails route registry
        # doesn't raise on duplicate names.
        def draw_routes(mapper, path:, as_prefix: DEFAULT_ROUTE_PREFIX)
          mapper.get("#{path}/manifest",
                     to: "react_on_rails_pro/rolling_deploy/bundles#manifest",
                     as: :"#{as_prefix}_manifest")
          mapper.get("#{path}/bundles/:hash",
                     to: "react_on_rails_pro/rolling_deploy/bundles#show",
                     constraints: { hash: SAFE_HASH_PATTERN },
                     as: :"#{as_prefix}_bundle")
        end
      end

      # Defense-in-depth: even if the route constraint somehow let a
      # path-traversal value through, the controller still rejects it
      # before any disk lookup because the hash must be in the
      # (regex-validated) current-hash set.
      SAFE_HASH_PATTERN = ReactOnRailsPro::RollingDeploy::SAFE_HASH_PATTERN

      # Tarball entry name reserved for the server bundle. Companion assets
      # whose basename collides with this are skipped to keep the receiver
      # from extracting the wrong bytes into the bundle slot.
      BUNDLE_ENTRY_NAME = "bundle.js"

      PROTOCOL_VERSION = 1

      def manifest
        sources = safe_current_bundle_sources
        render json: {
          hashes: sources.map { |_, hash| hash },
          rsc_enabled: ReactOnRailsPro.configuration.enable_rsc_support,
          generated_at: Time.now.utc.iso8601,
          protocol_version: PROTOCOL_VERSION
        }
      end

      def show
        hash = params[:hash].to_s
        # Defense in depth — route constraint should already enforce this,
        # but we also reject any value that slipped past it before any
        # filesystem operation looks at it.
        return head(:not_found) unless SAFE_HASH_PATTERN.match?(hash)

        sources = safe_current_bundle_sources
        match = sources.find { |_, h| h == hash }
        return head(:not_found) unless match

        bundle_path, _matched_hash = match
        serve_bundle_tarball(bundle_path)
      end

      private

      def authenticate_rolling_deploy_request
        configured = ReactOnRailsPro.configuration.rolling_deploy_token.to_s
        # If the controller is reached without a configured token, refuse
        # unconditionally. This is defense-in-depth — the engine should not
        # mount the controller in that state — but it makes the no-token
        # mode a hard fail rather than an open endpoint.
        return head(:unauthorized) if configured.empty?

        provided = extract_bearer_token(request.headers["Authorization"])
        return head(:unauthorized) if provided.empty?

        # secure_compare requires equal-length strings. Tokens are configured
        # with a fixed minimum length, so this rejects malformed input before
        # comparing same-length token bytes.
        match = provided.bytesize == configured.bytesize &&
                ActiveSupport::SecurityUtils.secure_compare(provided, configured)
        head(:unauthorized) unless match
      end

      def extract_bearer_token(header)
        return "" if header.blank?
        return "" unless header.start_with?("Bearer ", "bearer ")

        header[7..].to_s.strip
      end

      def set_no_store_headers
        response.headers["Cache-Control"] = "no-store"
      end

      # Wraps bundle_sources to absorb the "bundle file not present yet" case
      # so the manifest endpoint can still 200 with an empty hashes list during
      # the brief window after Rails boots but before assets:precompile has
      # produced the bundle on this dyno. Returns `[]` rather than raising so
      # the build-CI side sees "this server has nothing to seed" instead of a
      # 500 that would otherwise show up as a noisy deploy alert.
      def safe_current_bundle_sources
        return [] unless ReactOnRailsPro.configuration.node_renderer?

        pool = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool
        ReactOnRailsPro::RendererCacheHelpers.bundle_sources(pool, "serving rolling-deploy tarball")
      rescue StandardError => e
        Rails.logger.warn(
          "[ReactOnRailsPro::RollingDeploy::BundlesController] " \
          "bundle source discovery failed: #{e.class}: #{e.message}. " \
          "Returning empty manifest — verify bundles have been precompiled."
        )
        []
      end

      def serve_bundle_tarball(bundle_path)
        entries = tarball_entries(bundle_path)

        ReactOnRailsPro::RollingDeploy::Tarball.compose_to_tempfile(entries) do |io|
          # We've already buffered the tarball to a Tempfile inside
          # compose_to_tempfile; send_data reads the contents once. For very
          # large bundles a streaming send via ActionController::Live would
          # save memory; that's deferred to a follow-up PR — the current
          # default ceiling (200 MB) fits comfortably in memory on every
          # Rails app instance we'd expect to deploy.
          send_data io.read,
                    type: "application/gzip",
                    disposition: "inline",
                    filename: "#{params[:hash]}.tar.gz"
        end
      end

      # Pairs the bundle file (renamed to `bundle.js` on the wire) with the
      # current build's companion assets. Each tarball carries the full
      # companion set so the receiver can stage a complete cache entry without
      # a second round-trip — matching the rolling_deploy_adapter contract
      # that `fetch(hash)` returns bundle + assets together.
      #
      # Companions are skipped (with a warning) when they would shadow the
      # bundle entry, collide with another companion's basename, or carry a
      # name that the tarball helper would reject during compose. This
      # matches the publish-side behavior in AssetsPrecompile where missing
      # or unsafe assets degrade rather than fail the build.
      def tarball_entries(bundle_path)
        entries = { BUNDLE_ENTRY_NAME => bundle_path }
        companion_assets.each do |asset_path|
          name = File.basename(asset_path)
          next if skip_companion?(name, asset_path, entries)

          entries[name] = asset_path
        end
        entries
      end

      def skip_companion?(name, asset_path, entries)
        if name == BUNDLE_ENTRY_NAME
          warn_companion_skipped(
            "companion #{asset_path.inspect} basename collides with bundle entry #{BUNDLE_ENTRY_NAME.inspect}"
          )
          return true
        end
        unless ReactOnRailsPro::RollingDeploy::Tarball::ENTRY_NAME_PATTERN.match?(name)
          warn_companion_skipped(
            "companion #{asset_path.inspect} basename #{name.inspect} is not a safe tarball entry name"
          )
          return true
        end
        if entries.key?(name)
          warn_companion_skipped(
            "duplicate companion basename #{name.inspect}; " \
            "keeping #{entries[name].inspect}, dropping #{asset_path.inspect}"
          )
          return true
        end
        false
      end

      def warn_companion_skipped(message)
        Rails.logger.warn("[ReactOnRailsPro::RollingDeploy::BundlesController] #{message}.")
      end

      def companion_assets
        rails_root = File.expand_path(Rails.root.to_s)
        rails_root_realpath = File.realpath(rails_root)

        # `collect_assets` returns the live build's loadable-stats + RSC
        # manifests; missing assets are silently dropped to match the
        # publish-side behavior in AssetsPrecompile.
        ReactOnRailsPro::RendererCacheHelpers.collect_assets
                                             .map(&:to_s)
                                             .reject { |p| ReactOnRailsPro::RendererCacheHelpers.http_url?(p) }
                                             .filter_map do |path|
                                               safe_companion_asset_path(path, rails_root, rails_root_realpath)
                                             end
      rescue StandardError => e
        Rails.logger.warn(
          "[ReactOnRailsPro::RollingDeploy::BundlesController] " \
          "companion asset discovery failed: #{e.class}: #{e.message}. " \
          "Serving bundle without companion assets — RSC clients may fall back to runtime 410-retry."
        )
        []
      end

      def safe_companion_asset_path(path, rails_root, rails_root_realpath)
        expanded = File.expand_path(path, rails_root)
        return nil unless path_within_root?(expanded, rails_root)
        return nil unless File.file?(expanded)

        realpath = File.realpath(expanded)
        return nil unless path_within_root?(realpath, rails_root_realpath)

        expanded
      end

      def path_within_root?(path, root)
        path == root || path.start_with?("#{root}#{File::SEPARATOR}")
      end
    end
  end
end

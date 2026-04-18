# frozen_string_literal: true

require "fileutils"
require "pathname"
require "react_on_rails_pro/renderer_cache_helpers"
require "react_on_rails_pro/renderer_cache_path"
require "react_on_rails_pro/rolling_deploy_cache_stager"

module ReactOnRailsPro
  # Stages the Node Renderer bundle cache in the renderer's expected directory
  # structure (`<cache>/<bundleHash>/<bundleHash>.js`), including any configured
  # assets_to_copy and, when RSC support is enabled, the RSC bundle and manifests.
  #
  # Supports two modes:
  #
  # * `:copy` (default) - copies bundle and assets. Designed for Docker image
  #   builds where the cache must be baked into an immutable artifact.
  # * `:symlink` - creates relative symlinks. For same-filesystem workflows
  #   (local dev, CI, Heroku-style same-dyno deploys, bundle-caching restores).
  #
  # Both modes produce the same on-disk cache layout, matching the renderer's
  # runtime contract. The 410->retry cold-start round-trip on first SSR request
  # is eliminated when the pre-seeded bundle is present at renderer startup.
  class PreSeedRendererCache
    VALID_MODES = %i[copy symlink].freeze

    # `mode:` is required (no default) because the two modes have fundamentally
    # different semantics — `:copy` bakes immutable artifacts for Docker/image
    # builds; `:symlink` links live files on a shared filesystem. Forcing callers
    # to be explicit prevents the footgun where an implicit default would mismatch
    # the deploy context (e.g., copy-mode raises about RENDERER_SERVER_BUNDLE_CACHE_PATH
    # in a dev shell). The rake task and AssetsPrecompile auto-invocation both pass
    # `mode:` explicitly with their own context-appropriate defaults.
    def self.call(mode:)
      unless VALID_MODES.include?(mode)
        raise ArgumentError, "mode must be one of #{VALID_MODES.inspect}, got #{mode.inspect}"
      end

      cache_dir = resolve_cache_dir(mode)
      puts "[ReactOnRailsPro] Staging renderer cache (mode: #{mode}) in: #{cache_dir}"
      pool = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool

      assets, rsc_required_paths = RendererCacheHelpers.collect_assets_with_required_paths

      current_hashes = []
      # Block-level `rescue` (Ruby 2.5+): equivalent to wrapping the block body in
      # begin/rescue/end. RuboCop's Style/RedundantBegin enforces this form, so
      # callers reading the loop should treat the rescue clause below as the
      # iteration body's exception handler — not the surrounding method's.
      RendererCacheHelpers.bundle_sources(pool, action_description(mode)).each do |src_bundle_path, bundle_hash|
        bundle_dir = File.join(cache_dir, bundle_hash.to_s)
        stage_bundle(src_bundle_path, bundle_dir, bundle_hash, mode)
        # The Node Renderer serves manifests from whichever bundle dir it loaded,
        # so both server and RSC dirs need the manifests present.
        stage_assets(assets, bundle_dir, rsc_required_paths, mode)
        current_hashes << bundle_hash.to_s
      rescue StandardError => e
        # Fail-fast: re-raise on the first bundle failure so the deploy sees a non-zero exit and
        # aborts before downstream steps assume the cache is complete. Earlier bundles that
        # already staged successfully (e.g. server bundle when RSC fails) remain on disk for
        # diagnosis or for a re-run, but the renderer should not be expected to start from a
        # partially-staged cache — operators must rebuild the cache or roll back.
        warn "[ReactOnRailsPro] Renderer cache staging failed for bundle #{bundle_hash}; " \
             "cache may be partially staged: #{e.message}"
        raise
      end

      # Optionally seed previous deploys' bundle hashes for rolling-deploy safety.
      # No-op when neither config.rolling_deploy_adapter nor PREVIOUS_BUNDLE_HASHES is set.
      RollingDeployCacheStager.call(cache_dir: cache_dir, current_hashes: current_hashes, mode: mode)
    end

    # Validates the cache-dir env var (raises in production-like copy mode when
    # unset) before resolving. See enforce_cache_dir_env_var! for the rationale.
    def self.resolve_cache_dir(mode)
      enforce_cache_dir_env_var!(mode)
      ReactOnRailsPro::RendererCachePath.resolve
    end
    private_class_method :resolve_cache_dir

    # In copy mode (Docker image builds), silent fallback to Rails.root/.node-renderer-bundles
    # is a footgun: the renderer process may run from a different cwd and resolve its default
    # cache directory to a different path (e.g., /tmp/react-on-rails-pro-node-renderer-bundles),
    # causing pre-seeded bundles to land somewhere the renderer never reads. Require an
    # explicit env var in non-dev/test environments.
    def self.enforce_cache_dir_env_var!(mode)
      return unless mode == :copy
      return if Rails.env.development? || Rails.env.test?

      # Only development and test are exempt; custom environments (ci, staging,
      # review, etc.) must set the env var explicitly because their default cache
      # path can differ from the Node renderer's default, causing silent
      # mis-staging.
      # RENDERER_BUNDLE_PATH remains accepted for compatibility, but new deploys
      # should migrate to RENDERER_SERVER_BUNDLE_CACHE_PATH. Whitespace-only
      # values intentionally pass this guard so RendererCachePath can raise the
      # specific validation error instead of the missing-env guidance.
      return if !ENV.fetch("RENDERER_SERVER_BUNDLE_CACHE_PATH", "").empty? ||
                !ENV.fetch("RENDERER_BUNDLE_PATH", "").empty?

      raise ReactOnRailsPro::Error, <<~MSG.strip
        Pre-seeding the renderer cache in copy mode (#{Rails.env}) requires an explicit
        cache directory. Set RENDERER_SERVER_BUNDLE_CACHE_PATH in your environment, e.g.
        in your Dockerfile:

          ENV RENDERER_SERVER_BUNDLE_CACHE_PATH=/app/.node-renderer-bundles

        The Node Renderer's default cache directory resolution differs between the Ruby
        and standalone Node environments, so relying on the default in production-like
        deploys can cause pre-seeded bundles to land in a path the renderer never reads.

        If you don't need an immutable artifact (e.g. in CI or same-filesystem deploys),
        use mode: :symlink instead:

          rake react_on_rails_pro:pre_seed_renderer_cache MODE=symlink
      MSG
    end
    private_class_method :enforce_cache_dir_env_var!

    def self.action_description(mode)
      mode == :copy ? "pre-seeding" : "pre-staging"
    end
    private_class_method :action_description

    def self.stage_bundle(src_path, bundle_dir, bundle_hash, mode)
      dest_file = File.join(bundle_dir, "#{bundle_hash}.js")
      log_prefix = mode == :copy ? "Pre-seeded renderer cache" : "Pre-staged renderer cache"
      stage_file(src_path, dest_file, mode, log_prefix)
    end
    private_class_method :stage_bundle

    def self.stage_file(src, dest, mode, log_prefix)
      if mode == :copy
        RendererCacheHelpers.copy_file_atomically(src, dest, log_prefix: log_prefix)
      else
        make_relative_symlink(src, dest, log_prefix)
      end
    end
    private_class_method :stage_file

    # RSC manifests are required when RSC is enabled; user-configured
    # assets_to_copy are optional and only produce a warning.
    def self.stage_assets(assets, bundle_dir, rsc_required_paths, mode)
      action_desc = action_description(mode)
      RendererCacheHelpers.each_stageable_asset(assets, rsc_required_paths, action_desc) do |expanded|
        dest = File.join(bundle_dir, File.basename(expanded))
        log_prefix = mode == :copy ? "Copied asset" : "Symlinked asset"
        stage_file(expanded, dest, mode, log_prefix)
      end
    end
    private_class_method :stage_assets

    # Creates a temporary symlink alongside `destination` and renames it into
    # place atomically. POSIX rename replaces an existing symlink without a
    # delete-first gap, so concurrent renderer reads never see a missing bundle.
    def self.make_relative_symlink(source, destination, log_prefix)
      destination_dir = Pathname.new(destination).dirname

      # Canonicalize both sides so paths like /var -> /private/var do not
      # produce broken relative symlinks when the cache dir comes from tmpdir.
      # Pathname#realpath raises Errno::ENOENT on a dangling symlink or a
      # path that vanished between File.exist? and here (e.g. webpack output
      # rotating mid-stage). Wrap each realpath call separately so the error
      # message correctly names the side that failed.
      source_path =
        begin
          Pathname.new(source).realpath
        rescue Errno::ENOENT
          raise ReactOnRailsPro::Error,
                "Cannot resolve real path for symlink source #{source} - " \
                "it does not exist or is a dangling symlink. " \
                "Rebuild your bundles before staging the renderer cache."
        end
      FileUtils.mkdir_p(destination_dir)
      destination_dir_real =
        begin
          destination_dir.realpath
        rescue Errno::ENOENT
          raise ReactOnRailsPro::Error,
                "Cannot resolve real path for symlink destination dir #{destination_dir} - " \
                "it may have been removed after mkdir_p (race with an external cleanup)."
        end
      relative_source_path = source_path.relative_path_from(destination_dir_real)
      tmp = "#{destination}.tmp-#{Process.pid}-#{SecureRandom.hex(6)}"
      File.symlink(relative_source_path, tmp)
      File.rename(tmp, destination)
      puts "[ReactOnRailsPro] #{log_prefix}: #{relative_source_path} -> #{destination}"
    ensure
      # Ruby pre-initializes `tmp` to nil at parse time, so the local exists even if
      # an exception fires before the assignment runs — the `if tmp` guard turns that
      # case into a no-op. On success the file has been renamed away; on a failure
      # after assignment it removes the temp symlink.
      FileUtils.rm_f(tmp) if tmp
    end
    private_class_method :make_relative_symlink
  end
end

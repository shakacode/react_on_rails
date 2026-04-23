# frozen_string_literal: true

require "fileutils"
require "pathname"
require "react_on_rails_pro/renderer_cache_helpers"

module ReactOnRailsPro
  # Stages the Node Renderer bundle cache in the renderer's expected directory
  # structure (`<cache>/<bundleHash>/<bundleHash>.js`), including any configured
  # assets_to_copy and, when RSC support is enabled, the RSC bundle and manifests.
  #
  # Supports two modes:
  #
  # * `:copy` (default) — copies bundle and assets. Designed for Docker image
  #   builds where the cache must be baked into an immutable artifact.
  # * `:symlink` — creates relative symlinks. For same-filesystem workflows
  #   (local dev, CI, Heroku-style same-dyno deploys, bundle-caching restores).
  #
  # Both modes produce the same on-disk cache layout, matching the renderer's
  # runtime contract. The 410→retry cold-start round-trip on first SSR request
  # is eliminated when the pre-seeded bundle is present at renderer startup.
  class PreSeedRendererCache
    VALID_MODES = %i[copy symlink].freeze

    def self.call(mode: :copy)
      unless VALID_MODES.include?(mode)
        raise ArgumentError, "mode must be one of #{VALID_MODES.inspect}, got #{mode.inspect}"
      end

      cache_dir = resolve_cache_dir(mode)
      puts "[ReactOnRailsPro] Staging renderer cache (mode: #{mode}) in: #{cache_dir}"
      pool = ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool

      assets = RendererCacheHelpers.collect_assets
      rsc_required_paths = RendererCacheHelpers.required_rsc_asset_paths

      RendererCacheHelpers.bundle_sources(pool, action_description(mode)).each do |src_bundle_path, bundle_hash|
        bundle_dir = File.join(cache_dir, bundle_hash.to_s)
        stage_bundle(src_bundle_path, bundle_dir, bundle_hash, mode)
        # The Node Renderer serves manifests from whichever bundle dir it loaded,
        # so both server and RSC dirs need the manifests present.
        stage_assets(assets, bundle_dir, rsc_required_paths, mode)
      end
    end

    def self.resolve_cache_dir(mode)
      enforce_cache_dir_env_var!(mode)
      ReactOnRailsPro::Utils.resolve_renderer_cache_dir
    end
    private_class_method :resolve_cache_dir

    # In copy mode (Docker image builds), silent fallback to Rails.root/.node-renderer-bundles
    # is a footgun: the renderer process may run from a different cwd and resolve its default
    # cache directory to a different path (e.g., /tmp/react-on-rails-pro-node-renderer-bundles),
    # causing pre-seeded bundles to land somewhere the renderer never reads. Require an
    # explicit env var in non-dev/test environments.
    def self.enforce_cache_dir_env_var!(mode)
      return unless mode == :copy
      # Use a plain-Ruby check (no ActiveSupport .present?) so whitespace-only
      # values are treated as "not set" and the guard remains portable.
      return unless ENV.fetch("RENDERER_SERVER_BUNDLE_CACHE_PATH", "").strip.empty? &&
                    ENV.fetch("RENDERER_BUNDLE_PATH", "").strip.empty?
      return if Rails.env.development? || Rails.env.test?

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
      stage_file(src_path, dest_file, mode, "Pre-seeded renderer cache")
    end
    private_class_method :stage_bundle

    # Shared mode dispatch. In :copy mode ensures the destination directory
    # exists; make_relative_symlink handles its own mkdir_p in :symlink mode.
    def self.stage_file(src, dest, mode, copy_log_prefix)
      if mode == :copy
        FileUtils.mkdir_p(File.dirname(dest))
        FileUtils.cp(src, dest)
        puts "[ReactOnRailsPro] #{copy_log_prefix}: #{dest}"
      else
        make_relative_symlink(src, dest)
      end
    end
    private_class_method :stage_file

    # RSC manifests are required when RSC is enabled — a missing manifest would cause
    # the renderer to fail at runtime with a hard-to-diagnose error. User-configured
    # assets_to_copy are optional and only produce a warning. Required assets are
    # matched by expanded path rather than basename so a same-named unrelated entry
    # in assets_to_copy cannot trigger a false-positive "required" error. Expand
    # against Rails.root to match how RendererCacheHelpers.required_rsc_asset_paths
    # builds its Set.
    def self.stage_assets(assets, bundle_dir, rsc_required_paths, mode)
      assets.each do |asset_path|
        expanded = File.expand_path(asset_path.to_s, Rails.root)
        unless File.exist?(expanded)
          if rsc_required_paths.include?(expanded)
            raise ReactOnRailsPro::Error, "Required RSC asset not found: #{asset_path}. " \
                                          "Build your bundles before #{action_description(mode)} the renderer cache."
          end
          warn "[ReactOnRailsPro] Asset not found #{asset_path}"
          next
        end

        dest = File.join(bundle_dir, File.basename(expanded))
        stage_file(expanded, dest, mode, "Copied asset")
      end
    end
    private_class_method :stage_assets

    # Replaces `destination` with a relative symlink to `source`. Not atomic:
    # if the process is killed between `rm_f` and `File.symlink` the destination
    # is briefly absent. In practice the renderer's 410→refetch retry at
    # request time recovers from a missing bundle, so the brief gap is benign.
    def self.make_relative_symlink(source, destination)
      destination_dir = Pathname.new(destination).dirname
      FileUtils.mkdir_p(destination_dir)
      FileUtils.rm_f(destination)

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
                "Cannot resolve real path for symlink source #{source} — " \
                "it does not exist or is a dangling symlink. " \
                "Rebuild your bundles before staging the renderer cache."
        end
      destination_dir_real =
        begin
          destination_dir.realpath
        rescue Errno::ENOENT
          raise ReactOnRailsPro::Error,
                "Cannot resolve real path for symlink destination dir #{destination_dir} — " \
                "it may have been removed after mkdir_p (race with an external cleanup)."
        end
      relative_source_path = source_path.relative_path_from(destination_dir_real)
      # File.symlink raises Errno::EEXIST if the destination reappears between
      # the rm_f above and this call (e.g. two Puma workers racing through
      # AssetsPrecompile.call at boot). Treat a concurrent winner as success:
      # both processes compute the same relative source, so the existing link
      # is already correct for us.
      begin
        File.symlink(relative_source_path, destination)
        puts "[ReactOnRailsPro] Symlinked #{relative_source_path} to #{destination}"
      rescue Errno::EEXIST
        puts "[ReactOnRailsPro] Symlink already present at #{destination} " \
             "(concurrent creator won the race); leaving existing link."
      end
    end
    private_class_method :make_relative_symlink
  end
end

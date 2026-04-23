# frozen_string_literal: true

require "react_on_rails_pro/pre_seed_renderer_cache"

module ReactOnRailsPro
  # DEPRECATED: use `ReactOnRailsPro::PreSeedRendererCache.call(mode: :symlink)` directly.
  # Retained as a thin shim so existing callers (custom rake tasks, Procfile entries,
  # deploy scripts) keep working during the deprecation cycle. Emits a warning once
  # per process on first call.
  class PrepareNodeRenderBundles
    # Mutex guards the check-then-set on @deprecation_warned so concurrent callers
    # (e.g. multiple Puma workers invoking the shim at boot) still see exactly one
    # warning per process.
    @deprecation_mutex = Mutex.new
    @deprecation_warned = false

    # The deprecated rake task emits its own warning and calls PreSeedRendererCache
    # directly; it does not set this one-time guard. See assets.rake for that path.
    def self.call
      emit_deprecation_warning!
      PreSeedRendererCache.call(mode: :symlink)
    end

    def self.emit_deprecation_warning!
      @deprecation_mutex.synchronize do
        return if @deprecation_warned

        warn "[ReactOnRailsPro] ReactOnRailsPro::PrepareNodeRenderBundles is deprecated. " \
             "Use ReactOnRailsPro::PreSeedRendererCache.call(mode: :symlink) instead. " \
             "The rake task equivalent is 'rake react_on_rails_pro:pre_seed_renderer_cache MODE=symlink'."
        @deprecation_warned = true
      end
    end
    private_class_method :emit_deprecation_warning!

    # :nodoc: Test helper — resets the one-time deprecation-warning guard so
    # specs can exercise the warning path without leaking state between examples.
    # Private so it can only be invoked from specs via `send`; prevents accidental
    # reset from production code.
    def self.reset_deprecation_warned!
      @deprecation_mutex.synchronize { @deprecation_warned = false }
    end
    private_class_method :reset_deprecation_warned!
  end
end

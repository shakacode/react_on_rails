# frozen_string_literal: true

require "react_on_rails_pro/pre_seed_renderer_cache"

module ReactOnRailsPro
  # DEPRECATED: use `ReactOnRailsPro::PreSeedRendererCache.call(mode: :symlink)` directly.
  # Retained as a thin shim so existing callers (custom rake tasks, Procfile entries,
  # deploy scripts) keep working during the deprecation cycle. Emits a warning once
  # per process on first call.
  class PrepareNodeRenderBundles
    def self.call
      emit_deprecation_warning!
      PreSeedRendererCache.call(mode: :symlink)
    end

    def self.emit_deprecation_warning!
      return if @deprecation_warned

      warn "[ReactOnRailsPro] ReactOnRailsPro::PrepareNodeRenderBundles is deprecated. " \
           "Use ReactOnRailsPro::PreSeedRendererCache.call(mode: :symlink) instead. " \
           "The rake task equivalent is 'rake react_on_rails_pro:pre_seed_renderer_cache MODE=symlink'."
      @deprecation_warned = true
    end
    private_class_method :emit_deprecation_warning!

    # :nodoc: Test helper — resets the one-time deprecation-warning guard so
    # specs can exercise the warning path without leaking state between examples.
    def self.reset_deprecation_warned!
      @deprecation_warned = nil
    end
  end
end

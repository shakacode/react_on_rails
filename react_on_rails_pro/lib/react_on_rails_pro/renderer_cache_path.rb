# frozen_string_literal: true

require "react_on_rails_pro/error"

module ReactOnRailsPro
  # Resolves the Node Renderer server-bundle cache directory from environment
  # variables, preserving the same precedence and warning behavior as the Node
  # renderer configuration.
  class RendererCachePath
    PREFERRED_ENV_VAR = "RENDERER_SERVER_BUNDLE_CACHE_PATH"
    LEGACY_ENV_VAR = "RENDERER_BUNDLE_PATH"
    DEFAULT_CACHE_DIR = ".node-renderer-bundles"
    LEGACY_ENV_VAR_DEPRECATION_MUTEX = Mutex.new

    private_constant :PREFERRED_ENV_VAR,
                     :LEGACY_ENV_VAR,
                     :DEFAULT_CACHE_DIR,
                     :LEGACY_ENV_VAR_DEPRECATION_MUTEX

    @legacy_env_var_deprecation_warned = false

    class << self
      def resolve
        preferred = env_value(PREFERRED_ENV_VAR)
        return preferred if preferred

        legacy = env_value(LEGACY_ENV_VAR)
        return Rails.root.join(DEFAULT_CACHE_DIR).to_s unless legacy

        warn_legacy_env_var_once
        legacy
      end

      private

      # Surrounding whitespace is preserved verbatim because the Node renderer
      # reads these env vars raw, but it is almost always a misconfigured CI
      # secret — warn so operators notice.
      #
      # The two whitespace guards are intentionally asymmetric:
      #   * Whitespace-only ("  ") raises because there is no valid
      #     interpretation, so a misconfigured deploy should fail fast instead
      #     of silently falling back.
      #   * Surrounding whitespace ("  /app/bundles  ") only warns because the
      #     trimmed path could conceivably be intentional. Preserve it and let
      #     the operator decide.
      def env_value(name)
        value = ENV.fetch(name, "")
        raise ReactOnRailsPro::Error, "#{name} is whitespace-only; set or unset it." if value.match?(/\A\s+\z/)

        if value != value.strip
          warn "[ReactOnRailsPro] #{name} has surrounding whitespace " \
               "and will be used verbatim: #{value.inspect}"
        end
        value.empty? ? nil : value
      end

      def warn_legacy_env_var_once
        LEGACY_ENV_VAR_DEPRECATION_MUTEX.synchronize do
          unless @legacy_env_var_deprecation_warned
            warn "[ReactOnRailsPro] #{LEGACY_ENV_VAR} is deprecated. Use #{PREFERRED_ENV_VAR} instead."
            @legacy_env_var_deprecation_warned = true
          end
        end
      end

      # :nodoc: Test helper for resetting the one-time deprecation-warning guard.
      def reset_deprecation_warned!
        LEGACY_ENV_VAR_DEPRECATION_MUTEX.synchronize { @legacy_env_var_deprecation_warned = false }
      end
    end
  end
end

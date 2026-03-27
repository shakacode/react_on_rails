# frozen_string_literal: true

require "react_on_rails/utils"

module ReactOnRails
  module ReactComponent
    # rubocop:disable Metrics/ClassLength
    class RenderOptions
      include Utils::Required

      attr_accessor :request_digest

      PRERENDER_OVERRIDE_ENV_KEY = "REACT_ON_RAILS_PRERENDER_OVERRIDE"
      PRERENDER_OVERRIDE_VALUES = { "true" => true, "false" => false }.freeze
      PRERENDER_OVERRIDE_CACHE_MUTEX = Mutex.new
      class << self
        def prerender_env_override
          PRERENDER_OVERRIDE_CACHE_MUTEX.synchronize do
            raw_value = ENV.fetch(PRERENDER_OVERRIDE_ENV_KEY, nil)
            cached_override = @prerender_env_override_cache
            return cached_override[:value] if cached_override && cached_override[:raw_value] == raw_value

            parsed_value = parse_prerender_env_override(raw_value)
            @prerender_env_override_cache = { raw_value: raw_value, value: parsed_value }
            parsed_value
          end
        end

        def reset_prerender_env_override_cache!
          PRERENDER_OVERRIDE_CACHE_MUTEX.synchronize do
            @prerender_env_override_cache = nil
          end
        end

        private

        def parse_prerender_env_override(raw_value)
          return nil if raw_value.nil?

          normalized_value = raw_value.strip.downcase
          return PRERENDER_OVERRIDE_VALUES[normalized_value] if PRERENDER_OVERRIDE_VALUES.key?(normalized_value)

          Rails.logger.warn(
            "[REACT ON RAILS] Ignoring #{PRERENDER_OVERRIDE_ENV_KEY}=#{raw_value.inspect}. " \
            "Expected 'true' or 'false'."
          )
          # Cache invalid values too so we warn once per unique raw env value.
          nil
        end
      end

      NO_PROPS = {}.freeze

      # TODO: remove the required for named params
      def initialize(react_component_name: required("react_component_name"), options: required("options"))
        @react_component_name = react_component_name.camelize
        @options = options
      end

      attr_reader :react_component_name

      def throw_js_errors
        options.fetch(:throw_js_errors, false)
      end

      def props
        options.fetch(:props) { NO_PROPS }
      end

      def client_props
        props_extension = ReactOnRails.configuration.rendering_props_extension
        if props_extension.present?
          if props_extension.respond_to?(:adjust_props_for_client_side_hydration)
            return props_extension.adjust_props_for_client_side_hydration(react_component_name,
                                                                          props.clone)
          end

          raise ReactOnRails::Error, "ReactOnRails: your rendering_props_extension module is missing the " \
                                     "required adjust_props_for_client_side_hydration method & can not be used"
        end
        props
      end

      def random_dom_id
        retrieve_configuration_value_for(:random_dom_id)
      end

      def dom_id
        @dom_id ||= options.fetch(:id) do
          if random_dom_id
            generate_unique_dom_id
          else
            base_dom_id
          end
        end
      end

      def random_dom_id?
        return false if options[:id]

        return false unless random_dom_id

        true
      end

      def html_options
        options[:html_options].to_h
      end

      def prerender
        env_override = prerender_env_override
        return env_override unless env_override.nil?

        retrieve_configuration_value_for(:prerender)
      end

      def auto_load_bundle
        retrieve_configuration_value_for(:auto_load_bundle)
      end

      def trace
        retrieve_configuration_value_for(:trace)
      end

      def replay_console
        retrieve_configuration_value_for(:replay_console)
      end

      def raise_on_prerender_error
        retrieve_configuration_value_for(:raise_on_prerender_error)
      end

      def raise_non_shell_server_rendering_errors
        retrieve_react_on_rails_pro_config_value_for(:raise_non_shell_server_rendering_errors)
      end

      def logging_on_server
        retrieve_configuration_value_for(:logging_on_server)
      end

      def immediate_hydration
        ReactOnRails::Utils.normalize_immediate_hydration(
          options[:immediate_hydration],
          react_component_name,
          "Component"
        )
      end

      def to_s
        "{ react_component_name = #{react_component_name}, options = #{options}, request_digest = #{request_digest}"
      end

      def internal_option(key)
        options[key]
      end

      def set_option(key, value)
        options[key] = value
      end

      def render_mode
        # Determines the React rendering strategy:
        # - :sync: Synchronous SSR using renderToString (blocking and rendering in one shot)
        # - :html_streaming: Progressive SSR using renderToPipeableStream (non-blocking and rendering incrementally)
        # - :rsc_payload_streaming: Server Components serialized in React flight format
        #   (non-blocking and rendering incrementally).
        options.fetch(:render_mode, :sync)
      end

      def streaming?
        # Returns true if the component should be rendered incrementally
        %i[html_streaming rsc_payload_streaming].include?(render_mode)
      end

      def rsc_payload_streaming?
        # Returns true if the component should be rendered as a React Server Component
        render_mode == :rsc_payload_streaming
      end

      def html_streaming?
        # Returns true if the component should be rendered incrementally
        render_mode == :html_streaming
      end

      def store_dependencies
        options[:store_dependencies]
      end

      def self.generate_request_id
        SecureRandom.uuid
      end

      private

      attr_reader :options

      def base_dom_id
        "#{react_component_name}-react-component"
      end

      def generate_unique_dom_id
        "#{base_dom_id}-#{SecureRandom.uuid}"
      end

      def retrieve_configuration_value_for(key)
        options.fetch(key) do
          ReactOnRails.configuration.public_send(key)
        end
      end

      def retrieve_react_on_rails_pro_config_value_for(key)
        options.fetch(key) do
          return nil unless ReactOnRails::Utils.react_on_rails_pro?

          ReactOnRailsPro.configuration.public_send(key)
        end
      end

      def prerender_env_override
        self.class.prerender_env_override
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end

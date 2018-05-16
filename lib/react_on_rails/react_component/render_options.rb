# frozen_string_literal: true

require "react_on_rails/utils"

module ReactOnRails
  module ReactComponent
    class RenderOptions
      include Utils::Required

      attr_accessor :request_digest

      NO_PROPS = {}.freeze

      def initialize(react_component_name: required("react_component_name"), options: required("options"))
        @react_component_name = react_component_name.camelize
        @options = options
      end

      attr_reader :react_component_name

      def props
        options.fetch(:props) { NO_PROPS }
      end

      def dom_id
        @dom_id ||= options.fetch(:id) { generate_unique_dom_id }
      end

      def html_options
        options[:html_options].to_h
      end

      def prerender
        retrieve_key(:prerender)
      end

      def trace
        retrieve_key(:trace)
      end

      def replay_console
        retrieve_key(:replay_console)
      end

      def raise_on_prerender_error
        retrieve_key(:raise_on_prerender_error)
      end

      def logging_on_server
        retrieve_key(:logging_on_server)
      end

      def to_s
        "{ react_component_name = #{react_component_name}, options = #{options}, request_digest = #{request_digest}"
      end

      private

      attr_reader :options

      def generate_unique_dom_id
        "#{react_component_name}-react-component-#{SecureRandom.uuid}"
      end

      def retrieve_key(key)
        options.fetch(key) do
          ReactOnRails.configuration.public_send(key)
        end
      end
    end
  end
end

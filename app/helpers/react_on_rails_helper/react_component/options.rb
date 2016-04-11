module ReactOnRailsHelper
  module ReactComponent
    class Options
      include ERB::Util

      HIDDEN = "display:none".freeze

      attr_reader :name,
                  :props,
                  :prerender,
                  :trace,
                  :replay_console,
                  :raise_on_prerender_error,
                  :html_options,
                  :dom_id,
                  :style

      def initialize(name, index, options)
        @options = options
        @name = name.camelize
        @props = options[:props] || {}
        @html_options = options[:html_options].to_h
        @dom_id = options.fetch(:id) { "#{name}-react-component-#{index}" }

        build_configurable_options
      end

      def data
        {
          component_name: name,
          props: props,
          trace: trace,
          dom_id: dom_id
        }
      end

      def props_string
        props.is_a?(String) ? props : props.to_json
      end

      def props_sanitized
        props.is_a?(String) ? json_escape(props) : props.to_json
      end

      private

      attr_reader :options

      def build_configurable_options
        @prerender = retrieve_key(:prerender)
        @trace = retrieve_key(:trace)
        @replay_console = retrieve_key(:replay_console)
        @raise_on_prerender_error = retrieve_key(:raise_on_prerender_error)
        @style = build_style
      end

      def retrieve_key(key)
        options.fetch(key) do
          ReactOnRails.configuration.public_send(key)
        end
      end

      def build_style
        return nil if ReactOnRails.configuration.skip_display_none
        HIDDEN
      end
    end
  end
end

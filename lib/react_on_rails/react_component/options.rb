module ReactOnRails
  module ReactComponent
    class Options
      NO_PROPS = {}.freeze
      HIDDEN = "display:none".freeze

      attr_reader :index

      def initialize(name:, index:, options:)
        @name = name
        @index = index
        @options = options
      end

      def props
        options.fetch(:props) { NO_PROPS }
      end

      def name
        @name.camelize
      end

      def dom_id
        options.fetch(:id) { default_dom_id }
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

      def data
        {
          component_name: name,
          props: props,
          trace: trace,
          dom_id: dom_id
        }
      end

      def style
        return nil if ReactOnRails.configuration.skip_display_none
        HIDDEN
      end

      private

      attr_reader :options

      def default_dom_id
        "#{@name}-react-component-#{@index}"
      end

      def retrieve_key(key)
        options.fetch(key) do
          ReactOnRails.configuration.public_send(key)
        end
      end
    end
  end
end

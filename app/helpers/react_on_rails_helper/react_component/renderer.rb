module ReactOnRailsHelper
  module ReactComponent
    class Renderer
      include ActionView::Helpers::TagHelper

      def initialize(options)
        @options = options
      end

      def call
        build_html_safe(server_rendered_react_component_html)
      end

      private

      attr_reader :options

      def build_html_safe(html)
        <<-HTML.html_safe
#{component_specification_tag}
        #{rendered_output(html)}
        #{console_replay_script(html)}
        HTML
      end

      def component_specification_tag
        content_tag(:div,
                    "",
                    class: "js-react-on-rails-component",
                    style: options.style,
                    data: options.data)
      end

      def rendered_output(result)
        html = result["html"].html_safe
        content_tag_options = options.html_options
        content_tag_options[:id] = options.dom_id

        content_tag(:div, html, content_tag_options)
      end

      def console_replay_script(html)
        return "" unless options.replay_console

        html["consoleReplayScript"]
      end

      # Returns Array [0]: html, [1]: script to console log
      def server_rendered_react_component_html
        return { "html" => "", "consoleReplayScript" => "" } unless options.prerender

        ReactOnRails::ServerRenderingPool.reset_pool_if_server_bundle_was_modified

        result = ReactOnRails::ServerRenderingPool.server_render_js_with_console_logging(wrapper_js)
        check_server_rendered_valid!(result)
        result
      rescue ExecJS::ProgramError => err
        # rubocop:disable Style/RaiseArgs
        raise ReactOnRails::PrerenderError.new(component_name: options.name,
                                               props: options.props_sanitized,
                                               err: err,
                                               js_code: wrapper_js)
        # rubocop:enable Style/RaiseArgs
      end

      def initialize_redux_stores
        return "" unless @registered_stores.present? || @registered_stores_defer_render.present?
        declarations = "var reduxProps, store, storeGenerator;\n"

        all_stores = (@registered_stores || []) + (@registered_stores_defer_render || [])

        all_stores.each_with_object(declarations) do |redux_store_data, memo|
          store_name = redux_store_data[:store_name]
          props = props_string(redux_store_data[:props])
          memo << <<-JS
reduxProps = #{props};
storeGenerator = ReactOnRails.getStoreGenerator('#{store_name}');
store = storeGenerator(reduxProps, railsContext);
ReactOnRails.setStore('#{store_name}', store);
          JS
        end
      end

      def wrapper_js
        <<-JS
(function() {
  var railsContext = #{rails_context(server_side: true).to_json};
#{initialize_redux_stores}
  var props = #{options.props_string};
  return ReactOnRails.serverRenderReactComponent({
    name: '#{options.name}',
    domNodeId: '#{options.dom_id}',
    props: props,
    trace: #{options.trace},
    railsContext: railsContext
  });
})()
        JS
      end

      def check_server_rendered_valid!(result)
        return unless result["hasErrors"] && raise_on_prerender_error

        # rubocop:disable Style/RaiseArgs
        raise ReactOnRails::PrerenderError.new(component_name: options.name,
                                               props: options.props_sanitized,
                                               err: nil,
                                               js_code: wrapper_js,
                                               console_messages: result["consoleReplayScript"])
        # rubocop:enable Style/RaiseArgs
      end
    end
  end
end

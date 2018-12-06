# frozen_string_literal: true

module ReactOnRails
  module ServerRenderingJsCode
    class << self
      def js_code_renderer
        @js_code_renderer ||= if ReactOnRails::Utils.react_on_rails_pro?
                                ReactOnRailsPro::ServerRenderingJsCode
                              else
                                self
                              end
      end

      def server_rendering_component_js_code(
        props_string: nil,
        rails_context: nil,
        redux_stores: nil,
        react_component_name: nil,
        render_options: nil
      )
        js_code_renderer.render(props_string, rails_context, redux_stores, react_component_name, render_options)
      end

      def render(props_string, rails_context, redux_stores, react_component_name, render_options)
        <<-JS
        (function() {
          var railsContext = #{rails_context};
        #{redux_stores}
          var props = #{props_string};
          return ReactOnRails.serverRenderReactComponent({
            name: '#{react_component_name}',
            domNodeId: '#{render_options.dom_id}',
            props: props,
            trace: #{render_options.trace},
            railsContext: railsContext
          });
        })()
        JS
      end
    end
  end
end

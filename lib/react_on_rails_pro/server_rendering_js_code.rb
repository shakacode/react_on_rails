# frozen_string_literal: true

module ReactOnRailsPro
  module ServerRenderingJsCode
    class << self
      def ssr_pre_hook_js
        ReactOnRailsPro.configuration.ssr_pre_hook_js || ""
      end

      def render(props_string, rails_context, redux_stores, react_component_name, render_options)
        <<-JS
        (function() {
          var railsContext = #{rails_context};
        #{ssr_pre_hook_js}
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

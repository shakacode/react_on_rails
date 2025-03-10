# frozen_string_literal: true

module ReactOnRailsPro
  module ServerRenderingJsCode
    class << self
      def ssr_pre_hook_js
        ReactOnRailsPro.configuration.ssr_pre_hook_js || ""
      end

      def render(props_string, rails_context, redux_stores, react_component_name, render_options)
        render_function_name = if render_options.rsc_payload_streaming?
                                 "serverRenderRSCReactComponent"
                               elsif render_options.html_streaming?
                                 "streamServerRenderedReactComponent"
                               else
                                 "serverRenderReactComponent"
                               end
        rsc_props_if_rsc_request = if render_options.rsc_payload_streaming?
                                     manifest_file = ReactOnRails.configuration.react_client_manifest_file
                                     "reactClientManifestFileName: '#{manifest_file}',"
                                   else
                                     ""
                                   end
        <<-JS
        (function() {
          var railsContext = #{rails_context};
        #{ssr_pre_hook_js}
        #{redux_stores}
          var props = #{props_string};
          return ReactOnRails.#{render_function_name}({
            name: '#{react_component_name}',
            domNodeId: '#{render_options.dom_id}',
            props: props,
            trace: #{render_options.trace},
            railsContext: railsContext,
            throwJsErrors: #{ReactOnRailsPro.configuration.throw_js_errors},
            renderingReturnsPromises: #{ReactOnRailsPro.configuration.rendering_returns_promises},
            #{rsc_props_if_rsc_request}
          });
        })()
        JS
      end
    end
  end
end

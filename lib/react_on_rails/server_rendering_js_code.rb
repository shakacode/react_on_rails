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

        config_server_bundle_js = ReactOnRails.configuration.server_bundle_js_file

        if render_options.prerender == true && config_server_bundle_js.blank?
          msg = <<~MSG
            The `prerender` option to allow Server Side Rendering is marked as true but the ReactOnRails configuration
            for `server_bundle_js_file` is nil or not present in `config/initializers/react_on_rails.rb`.
            Set `config.server_bundle_js_file` to your javascript bundle to allow server side rendering.
            Read more at https://www.shakacode.com/react-on-rails/docs/guides/react-server-rendering/
          MSG
          raise ReactOnRails::Error, msg
        end

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

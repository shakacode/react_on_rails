module ReactRailsServerRendering
  class ReactRenderer

    # "this" does not need a closure as it refers to the "this" defined by the
    # calling the calling context which is the "this" in the execJs environment.
    def js_render_react_component
      <<-JS.strip_heredoc
      function renderReactComponent(componentClass, props) {
        return this.React.renderToString(
         componentClass(props)
        );
      }
      JS
    end

    def initialize
      js_code = "#{bundle_js_code};\n#{js_render_react_component}"
      @context = ExecJS.compile(js_code)
    end

    def render(js_code)
      js_code_wrapper = <<-JS.strip_heredoc
      (function () {
        var result = #{js_code}
        return result;
      })()
      JS

      @context.eval(js_code_wrapper)
    end

    private

    def bundle_js_code
      # Calling to_s to get contents of sprockets.

      # TODO: Make this file name configurable
      Rails.application.assets['generated/server.js'].to_s
    end
  end
end

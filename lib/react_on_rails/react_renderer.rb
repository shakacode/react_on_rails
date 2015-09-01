module ReactOnRails
  class ReactRenderer

    # "this" does not need a closure as it refers to the "this" defined by the
    # calling the calling context which is the "this" in the execJs environment.
    def render_js_react_component
      <<-JS.strip_heredoc
      function renderReactComponent(componentClass, props) {
        return this.React.renderToString(
         componentClass(props)
        );
      }
      JS
    end

    def initialize
      js_code = "#{bundle_js_code};\n#{render_js_react_component}"
      @context = ExecJS.compile(js_code)
    end

    # Returns a html_safe string of HTML for direct insertion on the page by evaluating a js_code.
    # Note, js_code does not have to be based on React.
    def render_js(js_code)
      js_code_wrapper = <<-JS.strip_heredoc
      (function () {
        return #{js_code}
      })()
      JS

      # This is the html from the JavaScript. Whatever calls this will probably call 'html_safe'
      # on the string.
      @context.eval(js_code_wrapper)
    end

    private

    def bundle_js_code
      js_file = Rails.root.join(ReactOnRails.configuration.bundle_js_file)
      File.read(js_file)
    end
  end
end

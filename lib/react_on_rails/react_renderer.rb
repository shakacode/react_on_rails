module ReactOnRails
  class ReactRenderer

    # Returns a React element, unwrapping it if the component is a generator function
    def render_js_react_element(react_component, props)
      <<-JS
        #{react_component}.generator ?
          #{react_component}(#{props}) :
          this.React.createElement(#{react_component}, #{props})
      JS
    end

    def initialize
      js_code = "#{bundle_js_code};"
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

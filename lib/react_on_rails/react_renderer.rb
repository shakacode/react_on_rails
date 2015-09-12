module ReactOnRails
  class ReactRenderer

    # Returns the JavaScript code to generate a React element.
    # The parameter react_component_name can be a React component or a generator function
    # that returns a React component. To be invoked as a function, react_component_name
    # must have the property "generator" set to true and be a function that
    # takes one parameter, props, that is used to construct the React component.
    def self.render_js_react_element(react_component_name, props_name)
      <<-JS.strip_heredoc
        #{react_component_name}.generator ?
          #{react_component_name}(#{props_name}) :
          this.React.createElement(#{react_component_name}, #{props_name})
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

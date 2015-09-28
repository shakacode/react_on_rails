require "react_on_rails/react_renderer"

# NOTE:
# For any heredoc JS:
# 1. The white spacing in this file matters!
# 2. Keep all #{some_var} fully to the left so that all indentation is done evenly in that var

module ReactOnRailsHelper
  # react_component_name: can be a React component, created using a ES6 class, or
  #   React.createClass, or a
  #     `generator function` that returns a React component
  #       using ES6
  #          let MyReactComponentApp = (props) => <MyReactComponent {...props}/>;
  #       or using ES5
  #          var MyReactComponentApp = function(props) { return <YourReactComponent {...props}/>; }
  #    Exposing the react_component_name is necessary to both a plain ReactComponent as well as
  #      a generator:
  #    For client rendering, expose the react_component_name on window:
  #      window.MyReactComponentApp = MyReactComponentApp;
  #    For server rendering, export the react_component_name on global:
  #      global.MyReactComponentApp = MyReactComponentApp;
  #    See spec/dummy/client/app/startup/serverGlobals.jsx and
  #      spec/dummy/client/app/startup/ClientApp.jsx for examples of this
  # props: Ruby Hash which contains the properties to pass to the react object
  #
  #  options:
  #    generator_function: <true/false> default is false, set to true if you want to use a
  #                        generator function rather than a React Component.
  #    prerender: <true/false> set to false when debugging!
  #    trace: <true/false> set to true to print additional debugging information in the browser
  #           default is true for development, off otherwise
  #    replay_console: <true/false> Default is true. False will disable echoing server rendering
  #                    logs to browser. While this can make troubleshooting server rendering difficult,
  #                    so long as you have the default configuration of logging_on_server set to
  #                    true, you'll still see the errors on the server.
  #  Any other options are passed to the content tag, including the id.
  def react_component(component_name, props = {}, options = {})
    # Create the JavaScript and HTML to allow either client or server rendering of the
    # react_component.
    #
    # Create the JavaScript setup of the global to initialize the client rendering
    # (re-hydrate the data). This enables react rendered on the client to see that the
    # server has already rendered the HTML.
    # We use this react_component_index in case we have the same component multiple times on the page.
    react_component_index = next_react_component_index
    react_component_name = component_name.camelize # Not sure if we should be doing this (JG)
    if options[:id].nil?
      dom_id = "#{component_name}-react-component-#{react_component_index}"
    else
      dom_id = options[:id]
    end

    # Setup the page_loaded_js, which is the same regardless of prerendering or not!
    # The reason is that React is smart about not doing extra work if the server rendering did its job.
    data_variable_name = "__#{component_name.camelize(:lower)}Data#{react_component_index}__"
    turbolinks_loaded = Object.const_defined?(:Turbolinks)
    # NOTE: props might include closing script tag that might cause XSS
    props_string = props.is_a?(String) ? props : props.to_json
    page_loaded_js = <<-JS
(function() {
  window.#{data_variable_name} = #{props_string};
  ReactOnRails.clientRenderReactComponent({
    componentName: '#{react_component_name}',
    domId: '#{dom_id}',
    propsVarName: '#{data_variable_name}',
    props: window.#{data_variable_name},
    trace: #{trace(options)},
    generatorFunction: #{generator_function(options)},
    expectTurboLinks: #{turbolinks_loaded}
  });
})();
    JS

    data_from_server_script_tag = javascript_tag(page_loaded_js)

    # Create the HTML rendering part
    server_rendered_html, console_script =
      server_rendered_react_component_html(options, props_string, react_component_name,
                                           data_variable_name, dom_id)

    content_tag_options = options.except(:generator_function, :prerender, :trace,
                                         :replay_console, :id, :react_component_name,
                                         :server_side)
    content_tag_options[:id] = dom_id

    rendered_output = content_tag(:div,
                                  server_rendered_html.html_safe,
                                  content_tag_options)

    # IMPORTANT: Ensure that we mark string as html_safe to avoid escaping.
    <<-HTML.html_safe
#{data_from_server_script_tag}
#{rendered_output}
#{replay_console(options) ? console_script : ""}
    HTML
  end

  def next_react_component_index
    @react_component_index ||= -1
    @react_component_index += 1
  end

  # Returns Array [0]: html, [1]: script to console log
  # NOTE, these are NOT html_safe!
  def server_rendered_react_component_html(options, props_string, react_component_name, data_variable, dom_id)
    return ["", ""]

    if prerender(options)
      render_js_expression = <<-JS
(function(React) {
        #{debug_js(react_component_name, data_variable, dom_id, trace(options))}
        var reactElement = #{render_js_react_element(react_component_name, props_string, generator_function(options))}
        return React.renderToString(reactElement);
      })(this.React);
      JS
      # create the server generated html of the react component with props
      options[:react_component_name] = react_component_name
      options[:server_side] = true
      render_js_internal(render_js_expression, options)
    else
      ["",""]
    end
  rescue ExecJS::ProgramError => err
    raise ReactOnRails::ServerRenderingPool::PrerenderError.new(react_component_name, props_string, err)
  end

  # Takes javascript code and returns the output from it. This is called by react_component, which
  # sets up the JS code for rendering a react component.
  # This method could be used by itself to render the output of any javascript that returns a
  # string of proper HTML.
  def render_js(js_expression, options = {})
    wrapper_js = <<-JS
(function() {
  var htmlResult = '';
  var consoleReplay = '';

  try {
    htmlResult =
      (function() {
        return #{js_expression};
      })();
  } catch(e) {
    htmlResult = handleError(e, null, jsCode);
  }

  consoleReplay = ReactOnRails.buildConsoleReplay();
  return JSON.stringify([htmlResult, consoleReplay]);
})()
    JS

    result_json = ReactOnRails::ServerRenderingPool.eval_js(wrapper_js)
    result = JSON.parse(result_json)
    "#{result[0]}\n#{result[1]}".html_safe
  end

  private
  # Takes javascript code and returns the output from it. This is called by react_component, which
  # sets up the JS code for rendering a react component.
  # This method could be used by itself to render the output of any javascript that returns a
  # string of proper HTML.
  # Returns Array [0]: html, [1]: script to console log
  def render_js_internal(js_expression, options = {})
    # TODO: This should be changed so that we don't create a new context every time
    # Example of doing this here: https://github.com/reactjs/react-rails/tree/master/lib/react/rails
    ReactOnRails::ReactRenderer.render_js(js_expression,
                                          options)
  end


  def trace(options)
    options.fetch(:trace) { ReactOnRails.configuration.trace }
  end

  def generator_function(options)
    options.fetch(:generator_function) { ReactOnRails.configuration.generator_function }
  end

  def prerender(options)
    options.fetch(:prerender) { ReactOnRails.configuration.prerender }
  end

  def replay_console(options)
    options.fetch(:replay_console) { ReactOnRails.configuration.replay_console }
  end
end

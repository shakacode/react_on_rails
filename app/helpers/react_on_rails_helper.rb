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
  # props: Ruby Hash or JSON string which contains the properties to pass to the react object
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
    turbolinks_loaded = Object.const_defined?(:Turbolinks)

    component_specification_tag =
      content_tag(:div,
                  "",
                  class: "react-component",
                  data: {
                    component_name: react_component_name,
                    props: props,
                    trace: trace(options),
                    generator_function: generator_function(options),
                    expect_turbolinks: turbolinks_loaded,
                    dom_id: dom_id
                  })

    # Create the HTML rendering part
    server_rendered_html, console_script =
      server_rendered_react_component_html(options, props, react_component_name, dom_id)

    content_tag_options = options.except(:generator_function, :prerender, :trace,
                                         :replay_console, :id, :react_component_name,
                                         :server_side)
    content_tag_options[:id] = dom_id

    rendered_output = content_tag(:div,
                                  server_rendered_html.html_safe,
                                  content_tag_options)

    # IMPORTANT: Ensure that we mark string as html_safe to avoid escaping.
    <<-HTML.html_safe
#{component_specification_tag}
#{rendered_output}
#{replay_console(options) ? console_script : ''}
    HTML
  end

  def sanitized_props_string(props)
    props.is_a?(String) ? json_escape(props) : props.to_json
  end

  # Helper method to take javascript expression and returns the output from evaluating it.
  # If you have more than one line that needs to be executed, wrap it in an IIFE.
  # JS exceptions are caught and console messages are handled properly.
  def server_render_js(js_expression, options = {})
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
    htmlResult = ReactOnRails.handleError({e: e, componentName: null,
      jsCode: '#{escape_javascript(js_expression)}', serverSide: true});
  }

  consoleReplay = ReactOnRails.buildConsoleReplay();
  return JSON.stringify([htmlResult, consoleReplay]);
})()
    JS

    result = ReactOnRails::ServerRenderingPool.server_render_js_with_console_logging(wrapper_js)

    # IMPORTANT: To ensure that Rails doesn't auto-escape HTML tags, use the 'raw' method.
    raw("#{result[0]}#{replay_console(options) ? result[1] : ''}")
  end

  private

  def next_react_component_index
    @react_component_index ||= -1
    @react_component_index += 1
  end

  # Returns Array [0]: html, [1]: script to console log
  # NOTE, these are NOT html_safe!
  def server_rendered_react_component_html(options, props, react_component_name, dom_id)
    return ["", ""] unless prerender(options)

    # Make sure that we use up-to-date server-bundle
    ReactOnRails::ServerRenderingPool.reset_pool_if_server_bundle_was_modified

    # Since this code is not inserted on a web page, we don't need to escape.
    props_string = props.is_a?(String) ? props : props.to_json

    wrapper_js = <<-JS
(function() {
  var props = #{props_string};
  return ReactOnRails.serverRenderReactComponent({
    componentName: '#{react_component_name}',
    domId: '#{dom_id}',
    props: props,
    trace: #{trace(options)},
    generatorFunction: #{generator_function(options)}
  });
})()
    JS

    ReactOnRails::ServerRenderingPool.server_render_js_with_console_logging(wrapper_js)
  rescue ExecJS::ProgramError => err
    raise ReactOnRails::ServerRenderingPool::PrerenderError.new(
      react_component_name,
      sanitized_props_string(props), # Sanitize as this might be browser logged
      err
    )
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

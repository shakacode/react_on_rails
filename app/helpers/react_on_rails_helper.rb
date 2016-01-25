# NOTE:
# For any heredoc JS:
# 1. The white spacing in this file matters!
# 2. Keep all #{some_var} fully to the left so that all indentation is done evenly in that var
require "react_on_rails/prerender_error"

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
  #    See README.md for how to "register" your react components.
  #    See spec/dummy/client/app/startup/serverRegistration.jsx and
  #      spec/dummy/client/app/startup/ClientRegistration.jsx for examples of this
  # props: Ruby Hash or JSON string which contains the properties to pass to the react object
  #
  #  options:
  #    prerender: <true/false> set to false when debugging!
  #    trace: <true/false> set to true to print additional debugging information in the browser
  #           default is true for development, off otherwise
  #    replay_console: <true/false> Default is true. False will disable echoing server rendering
  #                    logs to browser. While this can make troubleshooting server rendering difficult,
  #                    so long as you have the default configuration of logging_on_server set to
  #                    true, you'll still see the errors on the server.
  #    raise_on_prerender_error: <true/false> Default to false. True will raise exception on server
  #       if the JS code throws
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
    dom_id = if options[:id].nil?
               "#{component_name}-react-component-#{react_component_index}"
             else
               options[:id]
             end

    # Setup the page_loaded_js, which is the same regardless of prerendering or not!
    # The reason is that React is smart about not doing extra work if the server rendering did its job.
    turbolinks_loaded = Object.const_defined?(:Turbolinks)

    data = { component_name: react_component_name,
             props: props,
             trace: trace(options),
             expect_turbolinks: turbolinks_loaded,
             dom_id: dom_id
    }

    component_specification_tag =
      content_tag(:div,
                  "",
                  class: "js-react-on-rails-component",
                  style: ReactOnRails.configuration.skip_display_none ? nil : "display:none",
                  data: data)

    # Create the HTML rendering part
    result = server_rendered_react_component_html(options, props, react_component_name, dom_id)

    server_rendered_html = result["html"]
    console_script = result["consoleReplayScript"]

    content_tag_options = options.except(:generator_function, :prerender, :trace,
                                         :replay_console, :id, :react_component_name,
                                         :server_side, :raise_on_prerender_error)
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
  var consoleReplayScript = '';
  var hasErrors = false;

  try {
    htmlResult =
      (function() {
        return #{js_expression};
      })();
  } catch(e) {
    htmlResult = ReactOnRails.handleError({e: e, name: null,
      jsCode: '#{escape_javascript(js_expression)}', serverSide: true});
    hasErrors = true;
  }

  consoleReplayScript = ReactOnRails.buildConsoleReplay();

  return JSON.stringify({
      html: htmlResult,
      consoleReplayScript: consoleReplayScript,
      hasErrors: hasErrors
  });

})()
    JS

    result = ReactOnRails::ServerRenderingPool.server_render_js_with_console_logging(wrapper_js)

    # IMPORTANT: To ensure that Rails doesn't auto-escape HTML tags, use the 'raw' method.
    html = result["html"]
    console_log_script = result["consoleLogScript"]
    raw("#{html}#{replay_console(options) ? console_log_script : ''}")
  rescue ExecJS::ProgramError => err
    # rubocop:disable Style/RaiseArgs
    raise ReactOnRails::PrerenderError.new(component_name: "N/A (server_render_js called)",
                                           err: err,
                                           js_code: wrapper_js)
    # rubocop:enable Style/RaiseArgs
  end

  private

  def next_react_component_index
    @react_component_index ||= -1
    @react_component_index += 1
  end

  # Returns Array [0]: html, [1]: script to console log
  # NOTE, these are NOT html_safe!
  def server_rendered_react_component_html(options, props, react_component_name, dom_id)
    return { "html" => "", "consoleReplayScript" => "" } unless prerender(options)

    # On server `location` option is added (`location = request.fullpath`)
    # React Router needs this to match the current route

    # Make sure that we use up-to-date server-bundle
    ReactOnRails::ServerRenderingPool.reset_pool_if_server_bundle_was_modified

    # Since this code is not inserted on a web page, we don't need to escape.
    props_string = props.is_a?(String) ? props : props.to_json

    wrapper_js = <<-JS
(function() {
  var props = #{props_string};
  return ReactOnRails.serverRenderReactComponent({
    name: '#{react_component_name}',
    domNodeId: '#{dom_id}',
    props: props,
    trace: #{trace(options)},
    location: '#{request.fullpath}'
  });
})()
    JS

    result = ReactOnRails::ServerRenderingPool.server_render_js_with_console_logging(wrapper_js)

    if result["hasErrors"] && raise_on_prerender_error(options)
      # We caught this exception on our backtrace handler
      # rubocop:disable Style/RaiseArgs
      fail ReactOnRails::PrerenderError.new(component_name: react_component_name,
                                            # Sanitize as this might be browser logged
                                            props: sanitized_props_string(props),
                                            err: nil,
                                            js_code: wrapper_js,
                                            console_messages: result["consoleReplayScript"])
      # rubocop:enable Style/RaiseArgs
    end
    result
  rescue ExecJS::ProgramError => err
    # This error came from execJs
    # rubocop:disable Style/RaiseArgs
    raise ReactOnRails::PrerenderError.new(component_name: react_component_name,
                                           # Sanitize as this might be browser logged
                                           props: sanitized_props_string(props),
                                           err: err,
                                           js_code: wrapper_js)
    # rubocop:enable Style/RaiseArgs
  end

  def raise_on_prerender_error(options)
    options.fetch(:raise_on_prerender_error) { ReactOnRails.configuration.raise_on_prerender_error }
  end

  def trace(options)
    options.fetch(:trace) { ReactOnRails.configuration.trace }
  end

  def prerender(options)
    options.fetch(:prerender) { ReactOnRails.configuration.prerender }
  end

  def replay_console(options)
    options.fetch(:replay_console) { ReactOnRails.configuration.replay_console }
  end
end

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
  #                    logs, which can make troubleshooting server rendering difficult.
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
    dom_id = "#{component_name}-react-component-#{react_component_index}"

    # Setup the page_loaded_js, which is the same regardless of prerendering or not!
    # The reason is that React is smart about not doing extra work if the server rendering did its job.
    data_variable_name = "__#{component_name.camelize(:lower)}Data#{react_component_index}__"
    turbolinks_loaded = Object.const_defined?(:Turbolinks)
    install_render_events = turbolinks_loaded ? turbolinks_bootstrap(dom_id) : non_turbolinks_bootstrap
    page_loaded_js = <<-JS
(function() {
  window.#{data_variable_name} = #{props.to_json};
#{define_render_if_dom_node_present(react_component_name, data_variable_name, dom_id,
                                    trace(options), generator_function(options))}
#{install_render_events}
})();
    JS

    data_from_server_script_tag = javascript_tag(page_loaded_js)

    # Create the HTML rendering part
    server_rendered_html =
      server_rendered_react_component_html(options, props, react_component_name)

    rendered_output = content_tag(:div,
                                  server_rendered_html,
                                  id: dom_id)

    # IMPORTANT: Ensure that we mark string as html_safe to avoid escaping.
    <<-HTML.html_safe
#{data_from_server_script_tag}
#{rendered_output}
    HTML
  end

  def next_react_component_index
    @react_component_index ||= -1
    @react_component_index += 1
  end

  def server_rendered_react_component_html(options, props, react_component_name)
    if prerender(options)
      render_js_expression = <<-JS
(function(React) {
        var reactElement = #{render_js_react_element(react_component_name, props.to_json, generator_function(options))}
        return React.renderToString(reactElement);
      })(this.React);
      JS
      # create the server generated html of the react component with props
      options[:react_component_name] = react_component_name
      options[:prerender] = true
      render_js(render_js_expression, options)
    else
      ''
    end
  end

  # Takes javascript code and returns the output from it. This is called by react_component, which
  # sets up the JS code for rendering a react component.
  # This method could be used by itself to render the output of any javascript that returns a
  # string of proper HTML.
  def render_js(js_expression, options = {})
    # TODO: This should be changed so that we don't create a new context every time
    # Example of doing this here: https://github.com/reactjs/react-rails/tree/master/lib/react/rails
    ReactOnRails::ReactRenderer.new(options).render_js(js_expression,
                                                       options).html_safe
  end

  private

  def trace(options)
    options.fetch(:trace) { ReactOnRails.configuration.trace }
  end

  def generator_function(options)
    options.fetch(:generator_function) { ReactOnRails.configuration.generator_function }
  end

  def prerender(options)
    options.fetch(:prerender) { ReactOnRails.configuration.prerender }
  end

  def debug_js(react_component_name, data_variable, dom_id, trace)
    if trace
      "console.log(\"CLIENT SIDE RENDERED #{react_component_name} with data_variable"\
      " #{data_variable} to dom node with id: #{dom_id}\");"
    else
      ""
    end
  end

  # react_component_name: See app/helpers/react_on_rails_helper.rb:5
  # props_string: is either the variable name used to hold the props (client side) or the
  #   stringified hash of props from the Ruby server side. In terms of the view helper, one is
  #   simply passing in the Ruby Hash of props.
  #
  # Returns the JavaScript code to generate a React element.
  def render_js_react_element(react_component_name, props_string, generator_function)
    # "this" is defined by the calling context which is "global" in the execJs
    # environment or window in the client side context.
    js_create_element = if generator_function
                          "#{react_component_name}(props)"
                        else
                          "React.createElement(#{react_component_name}, props)"
                        end

    <<-JS
(function(React) {
          var props = #{props_string};
          return #{js_create_element};
        })(this.React);
    JS
  end

  def define_render_if_dom_node_present(react_component_name, data_variable, dom_id, trace, generator_function)
    inner_js_code = <<-JS_CODE
      var domNode = document.getElementById('#{dom_id}');
      if (domNode) {
        #{debug_js(react_component_name, data_variable, dom_id, trace)}
        var reactElement = #{render_js_react_element(react_component_name, data_variable, generator_function)}
        React.render(reactElement, domNode);
      }
JS_CODE

    <<-JS
  var renderIfDomNodePresent = function() {
#{ReactOnRails::ReactRenderer.wrap_code_with_exception_handler(inner_js_code, react_component_name, false)}
  }
    JS
  end

  def non_turbolinks_bootstrap
    <<-JS
    document.addEventListener("DOMContentLoaded", function(event) {
      console.log("DOMContentLoaded event fired");
      renderIfDomNodePresent();
    });
    JS
  end

  def turbolinks_bootstrap(dom_id)
    <<-JS
  var turbolinksInstalled = typeof(Turbolinks) !== 'undefined';
  if (!turbolinksInstalled) {
    console.warn("WARNING: NO TurboLinks detected in JS, but it's in your Gemfile");
#{non_turbolinks_bootstrap}
  } else {
    function onPageChange(event) {
      var removePageChangeListener = function() {
        document.removeEventListener("page:change", onPageChange);
        document.removeEventListener("page:before-unload", removePageChangeListener);
        var domNode = document.getElementById('#{dom_id}');
        React.unmountComponentAtNode(domNode);
      };
      document.addEventListener("page:before-unload", removePageChangeListener);

      renderIfDomNodePresent();
    }
    document.addEventListener("page:change", onPageChange);
  }
    JS
  end
end

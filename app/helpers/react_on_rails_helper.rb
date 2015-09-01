require 'react_on_rails/react_renderer'

module ReactOnRailsHelper

  # component_name: React component name
  # props: Ruby Hash which contains the properties to pass to the react object
  #
  # Naming Conventions:
  # Suppose your component is named "App" (can be anything)
  # 1. Inside app/startup/ServerApp.jsx, setup the component for server rendering. This is used by
  #    the global exports in step 2
  # 2. Component_name is changed to CamelizedUpper for the exposed component,
  #    so we have App as the exposed global (see app/startup/serverGlobals.jsx)
  # 3. Inside app/startup/ClientApp.jsx, you want to export a function that generates
  #    your component, and when you generate the component, you must use this naming convention
  #    to get the data.
  #    App(__appData__)
  #    That way it gets the data you pass from the Rails helper.
  #
  #  options:
  #    prerender: <true/false> defaults to true
  #    trace: <true/false> defaults to false, set to true to print additional info
  def react_component(component_name, props = {}, options = {})
    # Create the JavaScript setup of the global to initialize the client rendering
    # (re-hydrate the data). This enables react rendered on the client to see that the
    # server has already rendered the HTML.
    @react_component_index ||= 0
    prerender = options.fetch(:prerender) { ReactOnRails.configuration.prerender }
    trace = options.fetch(:trace, false)

    dataVariable = "__#{component_name.camelize(:lower)}Data#{@react_component_index}__"
    reactComponent = component_name.camelize
    domId = "#{component_name}-react-component-#{@react_component_index}"
    @react_component_index += 1

    turbolinks_loaded = Object.const_defined?(:Turbolinks)
    install_render_events = turbolinks_loaded ? turbolinks_bootstrap(domId) : non_turbolinks_bootstrap

    page_loaded_js = <<-JS
      (function() {
        window.#{dataVariable} = #{props.to_json};
        #{define_render_if_dom_node_present(reactComponent, dataVariable, domId, trace)}
        #{install_render_events}
      })();
    JS

    data_from_server_script_tag = javascript_tag(page_loaded_js)

    # Create the HTML rendering part
    if prerender
      render_js_expression = <<-JS
          renderReactComponent(this.#{reactComponent}, #{props.to_json})
      JS
      server_rendered_react_component_html = render_js(render_js_expression)
    else
      server_rendered_react_component_html = ""
    end

    rendered_output = content_tag(:div,
                                  server_rendered_react_component_html,
                                  id: domId)

    <<-HTML.strip_heredoc.html_safe
      #{data_from_server_script_tag}
      #{rendered_output}
    HTML
  end

  # Takes javascript code and returns the output from it. This is called by react_component, which
  # sets up the JS code for rendering a react component.
  # This method could be used by itself to render the output of any javascript that returns a
  # string of proper HTML.
  def render_js(js_expression)
    ReactOnRails::ReactRenderer.new.render_js(js_expression).html_safe
  end

  private

  def debug_js(react_component, data_variable, dom_id, trace)
    if trace
      <<-JS.strip_heredoc
        console.log("CLIENT SIDE RENDERED #{react_component} with dataVariable #{data_variable} to dom node with id: #{dom_id}");
      JS
    else
      ""
    end
  end

  def define_render_if_dom_node_present(react_component, data_variable, dom_id, trace)
    <<-JS.strip_heredoc
      var renderIfDomNodePresent = function() {
        var domNode = document.getElementById('#{dom_id}');
        if (domNode) {
          #{debug_js(react_component, data_variable, dom_id, trace)}
          var reactComponent = #{react_component}(#{data_variable});
          React.render(reactComponent, domNode);
        }
      }
    JS
  end

  def non_turbolinks_bootstrap
    <<-JS.strip_heredoc
      document.addEventListener("DOMContentLoaded", function(event) {
        console.log("DOMContentLoaded event fired");
        renderIfDomNodePresent();
      });
    JS
  end

  def turbolinks_bootstrap(dom_id)
    <<-JS.strip_heredoc
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

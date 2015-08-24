require 'react_rails_server_rendering/react_renderer'

module ReactRailsServerRenderingHelper

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
  def react_component(component_name, props = {})
    # Setup the custom secret sauce to prepare the react rendering

    # Create the JavaScript setup of the global to initialize the client rendering
    # (re-hydrate the data). This enables react rendered on the client to see that the
    # server has already rendered the HTML.

    # TODO: Bootstrap the react component on the server, checking if page loaded or document loaded

    dataVariable = "__#{component_name.camelize(:lower)}Data__"
    reactComponent = component_name.camelize
    @react_component_index ||= 0

    # TODO: What if you want to render the same component multiple times on the same page?
    domId = "#{component_name}-react-component-#{@react_component_index}"
    @react_component_index += 1
    turbolinks_loaded = Object.const_defined?(:Turbolinks)
    install_render_events = turbolinks_loaded ? turbolinks_bootstrap(domId) : non_turbolinks_bootstrap

    page_loaded_js = <<-JS
      window.#{dataVariable} = #{props.to_json};
      #{define_render_if_dom_node_present(reactComponent, dataVariable, domId)}
      #{install_render_events}
    JS

    data_from_server_script_tag = javascript_tag(page_loaded_js)

    # Create the HTML rendering part
    render_js_expression = <<-JS
        renderReactComponent(this.#{reactComponent}, #{props.to_json})
    JS
    server_rendered_react_component_html = render_js(render_js_expression)
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
    ReactRailsServerRendering::ReactRenderer.new.render_js(js_expression).html_safe
  end

  private

  def define_render_if_dom_node_present(reactComponent, dataVariable, domId)
    <<-JS.strip_heredoc
      var renderIfDomNodePresent = function() {
        var domNode = document.getElementById('#{domId}');
        if (domNode) {
          console.log("ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ");
          console.log("DID CLIENT SIDE RENDER");
          console.log("ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ");
          var reactComponent = #{reactComponent}(#{dataVariable});
          React.render(reactComponent, domNode);
        }
      }
    JS
  end

  def non_turbolinks_bootstrap
    <<-JS.strip_heredoc
      document.addEventListener("DOMContentLoaded", function(event) {
        console.log("YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY");
        console.log("DOMContentLoaded event fired");
        console.log("YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY");
        renderIfDomNodePresent();
      });
    JS
  end

  def turbolinks_bootstrap(domId)
    <<-JS.strip_heredoc
      var turbolinksInstalled = typeof(Turbolinks) !== 'undefined';
      console.log("YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY");
      console.log("Configuring for turbolinks.");
      console.log("YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY");
      if (!turbolinksInstalled) {
        console.log("WARNING: NO TurboLinks detected in JS, but it's in your Gemfile");
        #{non_turbolinks_bootstrap}
      } else {
        function onPageChange(event) {
          console.log("YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY");
          console.log("page:change event fired");
          console.log("YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY");
          var removePageChangeListener = function() {
            document.removeEventListener("page:change", onPageChange);
            document.removeEventListener("page:before-unload", removePageChangeListener);
            var domNode = document.getElementById('#{domId}');
            React.unmountComponentAtNode(domNode);
            console.log("YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY");
            console.log("removed both event listeners and component at dom node");
            console.log("YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY");
          };
          document.addEventListener("page:before-unload", removePageChangeListener);

          document.addEventListener("page:after-remove", function() {
            console.log("page:after-remove called")
          });

          renderIfDomNodePresent();
        }
        console.log("YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY");
        console.log("Add turbolinks handler page:change handler");
        console.log("YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY");
        document.addEventListener("page:change", onPageChange);
      }
    JS
  end
end

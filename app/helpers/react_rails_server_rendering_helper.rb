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
    page_loaded_js = <<-JS
        window.__#{component_name.camelize(:lower)}Data__ = #{props.to_json};
        // Here is where were put the bootstrapping code for the client
    JS
    data_from_server_script_tag = javascript_tag(page_loaded_js)

    # Create the HTML rendering part
    render_js_expression = <<-JS
        renderReactComponent(this.#{component_name.camelize}, #{props.to_json})
    JS
    server_rendered_react_component_html = render_js(render_js_expression)
    rendered_output = content_tag(:div,
                                  server_rendered_react_component_html,
                                  id: component_name.camelize(:lower))

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
end

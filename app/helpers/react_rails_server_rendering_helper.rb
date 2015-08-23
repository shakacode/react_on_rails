require 'react_rails_server_rendering/react_renderer'

module ReactRailsServerRenderingHelper

  # component_name: React component name
  # props: Hash which contains the properties to pass to the react object
  # js_code: Optional javascript code to execute before calling renderReactComponent
  def react_component(component_name, props = {}, js_code = nil)
    js_expression = <<-JS
        // TODO: Pass in arbitrary javascript as well????
        #{js_code}
        // TODO: Need to pass in some extra prop for redux???
        renderReactComponent(this.#{component_name}, #{props.to_json})
    JS

    js_render(js_expression)
  end

  # TODO: Should we remove these
  def js_context_debug
    js_render("'this is<br>' + JSON.stringify(this)")
  end

  def js_render(js_expression)
    ReactRailsServerRendering::ReactRenderer.new.render(js_expression).html_safe
  end
end

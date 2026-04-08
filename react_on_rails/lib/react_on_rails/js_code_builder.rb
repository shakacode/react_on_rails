# frozen_string_literal: true

module ReactOnRails
  # Structured builder that produces JavaScript code for server-side rendering.
  # Replaces the heredoc-based ServerRenderingJsCode with composable, overridable sections.
  #
  # Pro inherits and overrides only the sections it needs (RSC manifest, pre-hooks,
  # dynamic render function name).
  class JsCodeBuilder
    # Build the complete JS code for a render request.
    # @param render_request [ReactOnRails::RenderRequest]
    # @return [String] JavaScript IIFE ready for execution
    def build(render_request)
      sections = []
      sections << rails_context_section(render_request)
      sections << store_initialization_section(render_request)
      sections << props_section(render_request)
      sections << render_call_section(render_request)
      wrap_in_iife(sections.compact.join("\n"))
    end

    protected

    def rails_context_section(render_request)
      "  var railsContext = #{render_request.rails_context};"
    end

    def store_initialization_section(render_request)
      render_request.store_initializations
    end

    def props_section(render_request)
      "  var props = #{render_request.props_string};"
    end

    def render_call_section(render_request)
      <<~JS
        return ReactOnRails.serverRenderReactComponent({
          name: #{render_request.component_name.to_json},
          domNodeId: #{render_request.dom_id.to_json},
          props: props,
          trace: #{render_request.render_options.trace},
          railsContext: railsContext
        });
      JS
    end

    def wrap_in_iife(body)
      "(function() {\n#{body}\n})()\n"
    end
  end
end

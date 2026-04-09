# frozen_string_literal: true

module ReactOnRails
  # Structured builder for generating JavaScript code used in server-side rendering.
  # Replaces the heredoc-based JS code generation in ServerRenderingJsCode with
  # overridable section methods that Pro can extend.
  #
  # Part of the strategy pattern refactoring (see issue #2905).
  # Currently additive — not yet wired into the main rendering path.
  class JsCodeBuilder
    # Build the complete JS code for a render request.
    # @param render_request [RenderRequest] The render request to build JS for
    # @return [String] JavaScript code to evaluate for SSR
    def build(render_request)
      body = build_sections(render_request).compact.join("\n")
      wrap_in_iife(body, render_request)
    end

    protected

    # Returns an array of JS code sections. Override in subclasses to add/reorder sections.
    def build_sections(render_request)
      [
        rails_context_section(render_request),
        store_initialization_section(render_request),
        props_section(render_request),
        render_call_section(render_request)
      ]
    end

    def rails_context_section(render_request)
      "var railsContext = #{render_request.rails_context_json};"
    end

    def store_initialization_section(render_request)
      render_request.store_initializations
    end

    def props_section(render_request)
      "var props = #{render_request.props_string};"
    end

    def render_call_section(render_request)
      <<~JS.chomp
        return ReactOnRails.serverRenderReactComponent({
          name: #{render_request.component_name.to_json},
          domNodeId: #{render_request.dom_id.to_json},
          props: props,
          trace: #{render_request.render_options.trace},
          railsContext: railsContext
        });
      JS
    end

    def wrap_in_iife(body, _render_request)
      "(function() {\n#{body}\n})()"
    end
  end
end

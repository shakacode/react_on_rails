# frozen_string_literal: true

module ReactOnRails
  # Structured data object that encapsulates everything needed for a server render,
  # replacing the ad-hoc pattern of passing js_code strings and render_options separately
  # through the delegation chain.
  class RenderRequest
    attr_reader :component_name, :props_string, :rails_context,
                :store_initializations, :render_options

    # @param component_name [String] The registered React component name
    # @param props_string [String] JSON-encoded props (with unicode escapes applied)
    # @param rails_context [String] JSON-encoded rails context
    # @param store_initializations [String] JavaScript code for Redux store setup
    # @param render_options [ReactOnRails::ReactComponent::RenderOptions] Render configuration
    def initialize(component_name:, props_string:, rails_context:,
                   store_initializations:, render_options:)
      @component_name = component_name
      @props_string = props_string
      @rails_context = rails_context
      @store_initializations = store_initializations
      @render_options = render_options
    end

    def dom_id
      render_options.dom_id
    end

    def streaming?
      render_options.streaming?
    end

    def trace?
      render_options.trace
    end

    # Serialize to JS code via configured builder
    def to_js
      ReactOnRails.js_code_builder.build(self)
    end
  end
end

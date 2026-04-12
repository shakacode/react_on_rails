# frozen_string_literal: true

module ReactOnRails
  # Structured data object encapsulating everything needed for a server render.
  # Replaces the ad-hoc parameter passing of js_code strings and render_options
  # through the delegation chain.
  #
  # Part of the strategy pattern refactoring (see issue #2905).
  # Currently additive — not yet wired into the main rendering path.
  class RenderRequest
    attr_reader :component_name, :props, :rails_context, :store_initializations,
                :render_options

    # @param component_name [String] React component name
    # @param props [Hash, String] Component props (Hash or JSON string)
    # @param rails_context [Hash] Rails context data for the render
    # @param store_initializations [String] JavaScript code for Redux store initialization
    # @param render_options [ReactOnRails::ReactComponent::RenderOptions] Render configuration
    def initialize(component_name:, props:, rails_context:, store_initializations:, render_options:)
      @component_name = component_name
      @props = props
      @rails_context = rails_context
      @store_initializations = store_initializations
      @render_options = render_options
    end

    # Serialize to JS code via configured builder.
    # Raises if server_bundle_js_file is not configured when prerender is true.
    def to_js
      validate_server_bundle_configured!
      ReactOnRails.js_code_builder.build(self)
    end

    # Returns props as a JSON string, with unicode line/paragraph separators escaped
    # for safe embedding in JavaScript.
    def props_string
      json = props.is_a?(String) ? props : props.to_json
      json.gsub("\u2028", '\u2028').gsub("\u2029", '\u2029')
    end

    def rails_context_json
      raise ArgumentError, "rails_context must be a Hash, got #{rails_context.class}" unless rails_context.is_a?(Hash)

      rails_context.to_json.gsub("\u2028", '\u2028').gsub("\u2029", '\u2029')
    end

    def dom_id
      render_options.dom_id
    end

    def streaming?
      render_options.streaming?
    end

    def rsc_payload_streaming?
      render_options.rsc_payload_streaming?
    end

    private

    def validate_server_bundle_configured!
      config_server_bundle_js = ReactOnRails.configuration.server_bundle_js_file
      return unless render_options.prerender == true && config_server_bundle_js.blank?

      msg = <<~MSG
        The `prerender` option to allow Server Side Rendering is marked as true but the ReactOnRails configuration
        for `server_bundle_js_file` is nil or not present in `config/initializers/react_on_rails.rb`.
        Set `config.server_bundle_js_file` to your javascript bundle to allow server side rendering.
        Read more at https://reactonrails.com/docs/core-concepts/react-server-rendering/
      MSG
      raise ReactOnRails::Error, msg
    end
  end
end

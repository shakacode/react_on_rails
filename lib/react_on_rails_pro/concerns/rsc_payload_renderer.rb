# frozen_string_literal: true

module ReactOnRailsPro
  module RSCPayloadRenderer
    extend ActiveSupport::Concern

    included do
      include ReactOnRails::Controller
      include ReactOnRailsPro::Stream
    end

    def rsc_payload
      @rsc_payload_component_name = rsc_payload_component_name
      @rsc_payload_component_props = rsc_payload_component_props

      stream_view_containing_react_components(
        template: custom_rsc_payload_template,
        layout: false
      )
    end

    private

    def rsc_payload_component_props
      return {} if params[:props].blank?

      JSON.parse(params[:props])
    end

    def rsc_payload_component_name
      params[:component_name]
    end

    def custom_rsc_payload_template
      "react_on_rails_pro/rsc_payload"
    end
  end
end

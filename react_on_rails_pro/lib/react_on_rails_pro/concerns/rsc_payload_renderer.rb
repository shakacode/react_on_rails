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
        layout: false,
        # Render as text so Rails does not inject HTML view annotation comments
        # into the NDJSON stream. Custom template overrides must resolve to a
        # text or format-neutral template, not `.html.erb`.
        formats: [:text],
        content_type: "application/x-ndjson"
      )
    rescue ActionView::MissingTemplate => e
      raise e.exception(
        "#{e.message}\n\n" \
        "[React on Rails Pro] RSC payload templates are now rendered with format :text. " \
        "If you override `custom_rsc_payload_template`, make sure the override resolves to " \
        "a text or format-neutral template (for example `rsc_payload.text.erb`) instead of " \
        "only `.html.erb`. See react_on_rails_pro/docs/updating.md for upgrade notes."
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

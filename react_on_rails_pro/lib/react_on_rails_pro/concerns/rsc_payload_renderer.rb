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
        "[React on Rails Pro] RSC payload templates are now rendered with format :text. " \
        "If you override `custom_rsc_payload_template`, make sure the override resolves to " \
        "a text or format-neutral template (for example `rsc_payload.text.erb`) instead of " \
        "only `.html.erb`. See\n" \
        "https://github.com/shakacode/react_on_rails/blob/master/docs/pro/updating.md " \
        "for upgrade notes.\n\n" \
        "Original error: #{e.message}"
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

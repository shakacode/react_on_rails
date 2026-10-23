# frozen_string_literal: true

module ReactOnRails
  # Controller concern that applies HTTP status codes and redirect headers
  # from server-rendered React components.
  #
  # When a render function (e.g. TanStack Router) returns `httpResponse` metadata
  # in its server render result, the view helper stores it in `request.env`.
  # This concern reads it in an `after_action` callback and sets `response.status`
  # and `response.headers["Location"]` accordingly.
  #
  # Applies to non-streaming responses only. For streaming SSR
  # (`stream_view_containing_react_components`), headers are committed at the
  # first byte, so this concern has no effect.
  #
  # The `location` value is trusted from the JS renderer (same trust boundary
  # as any server-side rendered content). Applications using custom render
  # functions should validate redirect targets in their component code.
  #
  # Usage:
  #   class MyController < ApplicationController
  #     include ReactOnRails::SsrStatusHandler
  #   end
  #
  # The first `httpResponse` from any `react_component` call on the page wins.
  # Subsequent httpResponse values are ignored.
  module SsrStatusHandler
    extend ActiveSupport::Concern

    SSR_HTTP_RESPONSE_ENV_KEY = "react_on_rails.ssr_http_response"

    included do
      after_action :apply_ssr_http_response
    end

    private

    def apply_ssr_http_response
      http_response = request.env[SSR_HTTP_RESPONSE_ENV_KEY]
      return unless http_response.is_a?(Hash)

      status = http_response["status"]
      location = http_response["location"]

      response.status = status if status.is_a?(Integer) && status.between?(200, 599)

      # Set Location header for redirects. Reject values containing CR/LF/null
      # to prevent header injection.
      return unless location.is_a?(String) && location.present? && !location.match?(/[\r\n\0]/)

      response.headers["Location"] = location
    end
  end
end

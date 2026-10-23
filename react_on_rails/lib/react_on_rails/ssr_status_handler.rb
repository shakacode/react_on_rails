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
  # (`stream_view_containing_react_components`), headers are already committed
  # at the first byte, so this concern detects that and skips silently.
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
    # Per-component key: holds the httpResponse from the most recently rendered component.
    # Used by the Pro caching layer to cache each component's own metadata, not the
    # request-wide "first wins" value. Overwritten on every render.
    SSR_HTTP_RESPONSE_CURRENT_ENV_KEY = "react_on_rails.ssr_http_response_current"

    # Control characters (ASCII 0x00-0x1F, 0x7F) and literal backslash.
    # These are rejected in Location header values to prevent:
    # - HTTP response splitting (CR/LF)
    # - Null-byte injection
    # - Proxy misinterpretation of other control characters
    # - Literal \n / \r sequences that some parsers expand
    UNSAFE_HEADER_VALUE_PATTERN = /[\x00-\x1f\x7f\\]/

    included do
      after_action :apply_ssr_http_response
    end

    private

    def apply_ssr_http_response
      http_response = request.env[SSR_HTTP_RESPONSE_ENV_KEY]
      return unless http_response.is_a?(Hash)

      # Do not modify the response after headers have been sent (streaming SSR).
      return if response.committed?

      status = http_response["status"]
      location = http_response["location"]

      # Validate the complete metadata before changing anything on the response.
      # If any field is invalid, the entire httpResponse is rejected — no partial
      # application of status without a valid location or vice versa.
      valid_status = status.is_a?(Integer) && status.between?(200, 599)
      return unless valid_status

      valid_location = location.nil? || (location.is_a?(String) && location.present? &&
                                         !location.match?(UNSAFE_HEADER_VALUE_PATTERN))

      # Reject the entire httpResponse if the location is present but invalid.
      unless valid_location
        Rails.logger.warn do
          "[ReactOnRails] Rejected httpResponse: invalid Location value. " \
            "status=#{status} location=#{location.inspect.truncate(200)}"
        end
        return
      end

      response.status = status
      response.headers["Location"] = location if location
    end
  end
end

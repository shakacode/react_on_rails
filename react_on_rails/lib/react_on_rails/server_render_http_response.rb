# frozen_string_literal: true

module ReactOnRails
  # Applies the optional "httpResponse" value of a server-render result to the Rails response.
  #
  # A JavaScript render function can return it next to the HTML, for example:
  #   { renderedHtml: ..., httpResponse: { status: 404 } }
  #   { renderedHtml: "", httpResponse: { status: 307, location: "/login" } }
  #
  # This module sets the status code and, for a redirect, the Location header.
  module ServerRenderHttpResponse
    REDIRECT_STATUSES = [301, 302, 303, 307, 308].freeze
    ERROR_STATUSES = (400..599)

    # A path on this site. It starts with exactly one "/". The next character is not "/" or "\",
    # because browsers read "//host" and "/\host" as another website. Only visible ASCII characters
    # are allowed, so the value cannot add a line to the response headers.
    LOCAL_PATH = %r{\A/(?![/\\])[\x21-\x7E]*\z}

    class << self
      # Changes `response` and returns true when the value is applied.
      # Returns false and changes nothing when:
      #   - the value is absent, malformed or not allowed (see .normalize),
      #   - there is no response object, or the response was already sent (streaming),
      #   - the controller already chose a status other than 200,
      #   - the redirect points at the URL of the current request (it would loop). The fragment
      #     (`#...`) is ignored for this check: browsers never send it, so `/about` redirecting to
      #     `/about#team` would loop too.
      def apply(http_response, response:, current_path:, component_name:)
        normalized = normalize(http_response, component_name:)
        return false unless normalized && response
        return false if response.committed? || response.status != 200

        location = normalized[:location]
        if location && location.split("#", 2).first == current_path
          log(:warn, component_name, "the redirect points at the current URL", http_response)
          return false
        end

        response.location = location if location
        response.status = normalized[:status]
        true
      end

      # Returns { status: Integer, location: String or nil } when the value can be used.
      # Returns nil when the value is absent, malformed or not allowed.
      def normalize(http_response, component_name:)
        return nil if http_response.nil?

        unless http_response.is_a?(Hash) && http_response["status"].is_a?(Integer)
          log(:warn, component_name, "expected a Hash with an Integer \"status\"", http_response)
          return nil
        end

        if http_response["location"].nil?
          normalize_status_only(http_response, component_name)
        else
          normalize_redirect(http_response, component_name)
        end
      end

      private

      def normalize_status_only(http_response, component_name)
        status = http_response["status"]
        return { status:, location: nil } if ERROR_STATUSES.cover?(status)

        # 200 means "normal page". Anything else without a location is not supported.
        unless status == 200
          log(:warn, component_name, "a status without \"location\" must be between 400 and 599", http_response)
        end
        nil
      end

      def normalize_redirect(http_response, component_name)
        status = http_response["status"]
        location = http_response["location"]

        unless REDIRECT_STATUSES.include?(status)
          log(:warn, component_name, "a redirect status must be one of #{REDIRECT_STATUSES.join(', ')}", http_response)
          return nil
        end

        unless location.is_a?(String) && LOCAL_PATH.match?(location)
          # Not an error: for example a redirect to another website. The browser-side router
          # still follows it after the page loads.
          log(:debug, component_name, "\"location\" is not a path on this site", http_response)
          return nil
        end

        { status:, location: }
      end

      def log(level, component_name, reason, http_response)
        return unless defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger

        Rails.logger.public_send(
          level,
          "[react_on_rails] Ignored httpResponse from component #{component_name.inspect}: #{reason}. " \
          "Received: #{http_response.inspect}"
        )
      end
    end
  end
end

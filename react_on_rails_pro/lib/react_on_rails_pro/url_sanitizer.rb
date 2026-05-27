# frozen_string_literal: true

require "uri"

module ReactOnRailsPro
  # Redacts password components from URLs before they're logged or surfaced in
  # error messages. The Node renderer's password can be embedded in renderer_url
  # (e.g. https://:password@host:3800), and we must not let that value leak into
  # info logs, error reporters, or exception messages.
  module UrlSanitizer
    REDACTED_PLACEHOLDER = "__REDACTED__"
    # Matches the password segment of a userinfo (`user:password@`) inside an
    # otherwise-unparseable URL. Used as a fallback when URI.parse raises.
    # The password class allows spaces and most chars so we redact aggressively
    # — false negatives leak secrets, false positives only over-mask logs.
    USERINFO_PASSWORD_REGEX = %r{(://[^:/?#\s]*:)([^@/?#]+)(@)}

    module_function

    # Returns the URL with the password component redacted.
    # Returns the URL unchanged if it has no password. Falls back to a regex
    # redaction when the URL is unparseable so callers can still log the value
    # for diagnostics without leaking the secret.
    #
    # @param url [String, nil]
    # @return [String, nil]
    def redact_password(url)
      return url if url.nil? || url.empty?

      uri = URI.parse(url)
      return url if uri.password.nil? || uri.password.empty?

      uri.password = REDACTED_PLACEHOLDER
      uri.to_s
    rescue URI::InvalidURIError
      url.gsub(USERINFO_PASSWORD_REGEX, "\\1#{REDACTED_PLACEHOLDER}\\3")
    end
  end
end

# frozen_string_literal: true

require "uri"

module ReactOnRails
  # Redacts password components from URLs (or strings that embed URLs) before
  # they're logged or surfaced in error messages. Used by:
  #   * the Pro gem's request/HTTPX connection setup
  #   * `bin/dev` env-var warnings in `ReactOnRails::Dev::ServerManager`
  #   * any place a URL-shaped string might appear in an exception's `#message`
  module UrlSanitizer
    REDACTED_PLACEHOLDER = "__REDACTED__"

    # Matches `scheme://[user]:password@…` even when the user or password
    # contains a raw `@` (which RFC 3986 says should be percent-encoded but
    # in practice often isn't — e.g. when an email address is used as the
    # username). Captures through the LAST `@` before the host portion via
    # a greedy `.*` + lookahead. The `m` flag lets `.` cross newlines so we
    # don't leak passwords with embedded control characters.
    USERINFO_PASSWORD_REGEX = %r{(://[^:/?#\s]*:)(.*)@(?=[^@]*(?:[/?#\s]|\z))}m

    module_function

    # Returns the input with any embedded `user:password@` userinfo redacted.
    #
    # Primary path: `URI.parse` + `password=` for well-formed URLs.
    # Fallback path: regex substitution that runs on the input string as-is,
    # so this can also redact URLs embedded inside larger strings (e.g.
    # `URI::InvalidURIError#message`, which includes the original URL).
    #
    # @param input [String, nil]
    # @return [String, nil] the input with the password component redacted
    def redact_password(input)
      return input if input.nil? || input.empty?

      # If the entire input is a parseable URL, trust URI's structural view:
      # either redact via the URI API or — when there's no password to redact —
      # return the input unchanged. Skipping the regex for clean parseable URLs
      # avoids false positives on URLs whose query/fragment contains an '@'
      # (e.g. https://host/path?email=a@b would otherwise be corrupted into
      # https://host:__REDACTED__@b).
      uri = URI.parse(input)
      if uri.password && !uri.password.empty?
        uri.password = REDACTED_PLACEHOLDER
        return uri.to_s
      end
      input
    rescue URI::InvalidURIError
      # URL is either malformed OR embedded inside a larger string (e.g.
      # `URI::InvalidURIError#message`, "Setting up Node Renderer connection
      # to <url>", HTTPX error messages). Fall back to a regex that can
      # locate a `userinfo@host` pattern inside arbitrary surrounding text.
      apply_regex_redaction(input)
    end

    def apply_regex_redaction(input)
      input.gsub(USERINFO_PASSWORD_REGEX, "\\1#{REDACTED_PLACEHOLDER}@")
    end
  end
end

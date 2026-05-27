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

      # If the entire input is a parseable URL with a password, use the URI
      # API for an exact, structure-aware replacement.
      uri = URI.parse(input)
      if uri.password && !uri.password.empty?
        uri.password = REDACTED_PLACEHOLDER
        return uri.to_s
      end
      # No password in a parseable URL → still run the regex on the input in
      # case the parser tolerated a malformed userinfo segment that contains
      # a literal password we ought to mask.
      apply_regex_redaction(input)
    rescue URI::InvalidURIError
      apply_regex_redaction(input)
    end

    def apply_regex_redaction(input)
      input.gsub(USERINFO_PASSWORD_REGEX, "\\1#{REDACTED_PLACEHOLDER}@")
    end
  end
end

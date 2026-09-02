# frozen_string_literal: true

require "uri"

module ReactOnRails
  # Removes URL userinfo from configured values and diagnostic prose before either is displayed.
  module DiagnosticUrlRedactor
    HTTP_URL_SCHEME_PATTERN = %r{https?://}i
    NETWORK_URL_START_PATTERN = %r{
      (?:[a-z]|%[0-9a-f]{2})
      (?:[a-z0-9+.-]|%[0-9a-f]{2})*
      (?::|%3a)
      (?:/|%2f){2}
    }ix
    ENCODED_USERINFO_DELIMITER_PATTERN = /@|%40/i
    ENCODED_AUTHORITY_END_PATTERN = %r{/|%2f|\?|%3f|\#|%23}i
    HTTP_URL_TOKEN_PATTERN = /#{HTTP_URL_SCHEME_PATTERN}(?:(?!#{HTTP_URL_SCHEME_PATTERN})[^\s"'])+/

    CONFIGURED_URL_NOT_PROVIDED = Object.new.freeze
    private_constant :CONFIGURED_URL_NOT_PROVIDED

    class << self
      # Sanitizes a configured URL when called with one argument. When sanitizing exception text,
      # pass the originating URL so both its raw and inspected spellings are replaced safely.
      def sanitize(text, configured_url: CONFIGURED_URL_NOT_PROVIDED)
        return sanitized_configured_url(text) if configured_url.equal?(CONFIGURED_URL_NOT_PROVIDED)

        sanitized_error_message(text, configured_url)
      end

      private

      # One configured value is not free-form prose: multiple schemes or line breaks after its
      # first scheme make the URL suffix structurally ambiguous, so that suffix fails closed
      # through its final @. Any non-URL prefix is preserved for useful error context.
      def sanitized_configured_url(url)
        return url if url.nil? || url.empty?

        url = valid_diagnostic_text(url)

        # Treat whitespace around a scheme delimiter as a malformed HTTP(S) URL rather than a
        # local path. URL classification may reject that spelling, but diagnostics must still
        # fail closed if the value contains credential-like userinfo.
        scheme_pattern = %r{https?\s*:\s*//}i
        scheme = url.match(scheme_pattern)
        return sanitized_authority_relative_url(url) unless scheme

        prefix = url[...scheme.begin(0)]
        configured_url = url[scheme.begin(0)..]
        sanitized_url = if configured_url.match?(/[\r\n]/) || configured_url.scan(scheme_pattern).length > 1
                          strip_malformed_url_userinfo(configured_url)
                        else
                          sanitized_valid_network_url(configured_url) || strip_malformed_url_userinfo(configured_url)
                        end

        "#{prefix}#{sanitized_url}"
      end

      def sanitized_authority_relative_url(url)
        authority_start = url.index("//")
        return url unless authority_start

        prefix = url[...authority_start]
        authority_relative_url = url[authority_start..]
        sanitized_url = sanitized_valid_network_url(authority_relative_url) ||
                        strip_malformed_url_userinfo(authority_relative_url)
        "#{prefix}#{sanitized_url}"
      end

      def sanitized_error_message(message, raw_url)
        message = valid_diagnostic_text(message)
        return strip_userinfo(message) if raw_url.nil? || raw_url.empty?

        raw_url = valid_diagnostic_text(raw_url)
        sanitized_url = sanitized_configured_url(raw_url)

        # URI::InvalidURIError embeds String#inspect, while other errors may embed the raw value.
        message = message.gsub(raw_url.inspect) { sanitized_url.inspect }
                         .gsub(raw_url) { sanitized_url }
        strip_userinfo(message)
      end

      # Protects successfully parsed bare HTTP(S) tokens by assembling the result from spans,
      # without collision-prone placeholder text. A candidate remains unprotected when any @
      # follows it before the next scheme: punctuation, prose, and line breaks are not structural
      # proof that the @ is unrelated to malformed userinfo. When an unresolved region precedes
      # a credential-bearing candidate, that region is discarded and the candidate is sanitized
      # independently rather than allowing one fallback match to consume through another scheme.
      # Ambiguous text may be over-redacted for safety.
      def strip_userinfo(text)
        text = valid_diagnostic_text(text)
        sanitized = text.dup.clear
        unprotected_start = 0

        text.to_enum(:scan, HTTP_URL_TOKEN_PATTERN).each do
          match = Regexp.last_match
          protected_url = sanitized_valid_network_url(match[0])
          next unless protected_url
          next if userinfo_delimiter_before_next_scheme?(text, match)

          unprotected = text[unprotected_start...match.begin(0)]
          sanitized << sanitized_unprotected_prefix(unprotected, match[0], protected_url)
          sanitized << protected_url
          unprotected_start = match.end(0)
        end

        sanitized << strip_unprotected_userinfo(text[unprotected_start..])
      end

      def userinfo_delimiter_before_next_scheme?(text, match)
        continuation = text[match.end(0)..]
        boundary = continuation.match(HTTP_URL_SCHEME_PATTERN)
        continuation = continuation[...boundary.begin(0)] if boundary
        continuation.match?(ENCODED_USERINFO_DELIMITER_PATTERN)
      end

      def sanitized_unprotected_prefix(text, raw_url, sanitized_url)
        unresolved_scheme = text.match(HTTP_URL_SCHEME_PATTERN)
        return strip_unprotected_userinfo(text) if raw_url == sanitized_url || unresolved_scheme.nil?

        text[...unresolved_scheme.begin(0)]
      end

      # URI handles valid network URLs structurally, so an @ in the path is never mistaken for
      # userinfo. A missing host means an authority-shaped value was parsed as a path instead;
      # returning nil keeps that ambiguous token unprotected for the fail-closed pass.
      def sanitized_valid_network_url(url)
        sanitized_url = sanitized_single_network_url(url)&.dup
        return nil unless sanitized_url

        sanitized_nested_network_urls(sanitized_url)
      end

      def sanitized_nested_network_urls(sanitized_url)
        # A valid outer URL can carry another credential URL in its path or query. Partition the
        # input into disjoint scheme spans and assemble their replacements from left to right,
        # keeping the work bounded by the input size even when a diagnostic has many URL starts.
        # The first scheme belongs to the outer URL and was handled structurally above.
        nested_scheme_starts = sanitized_url.to_enum(:scan, NETWORK_URL_START_PATTERN)
                                            .map { Regexp.last_match.begin(0) }
        nested_scheme_starts.shift if nested_scheme_starts.first&.zero?
        return sanitized_url if nested_scheme_starts.empty?

        sanitized = sanitized_url.dup.clear
        unprocessed_start = 0

        nested_scheme_starts.each_with_index do |start, index|
          token_end = nested_scheme_starts.fetch(index + 1, sanitized_url.length)
          nested_url = sanitized_url[start...token_end]
          replacement = strip_encoded_network_url_userinfo(nested_url) ||
                        sanitized_single_network_url(nested_url) ||
                        nested_url
          sanitized << sanitized_url[unprocessed_start...start]
          sanitized << replacement
          unprocessed_start = token_end
        end

        sanitized << sanitized_url[unprocessed_start..]
      end

      # Percent encoding can hide the structural delimiters of a nested URL from URI.parse.
      # Inspect only the encoded-or-literal scheme, authority terminator, and @ delimiter, then
      # remove the original encoded span without decoding or rewriting unrelated output.
      def strip_encoded_network_url_userinfo(url)
        network_url = url.match(NETWORK_URL_START_PATTERN)
        return nil unless network_url&.begin(0)&.zero?

        authority_start = network_url.end(0)
        authority_end_match = url.match(ENCODED_AUTHORITY_END_PATTERN, authority_start)
        authority_end = authority_end_match&.begin(0) || url.length
        authority = url[authority_start...authority_end]
        _userinfo, delimiter, host = authority.rpartition(ENCODED_USERINFO_DELIMITER_PATTERN)
        return nil if delimiter.empty?

        "#{url[...authority_start]}#{host}#{url[authority_end..]}"
      end

      def sanitized_single_network_url(url)
        uri = URI.parse(url)
        return nil if uri.host.nil?
        return url if uri.userinfo.nil?

        # URI rejects a password without a user, so clear password first.
        uri.password = nil
        uri.user = nil
        uri.to_s
      rescue URI::Error, ArgumentError
        nil
      end

      def valid_diagnostic_text(text)
        text = text.to_s
        text.valid_encoding? ? text : text.scrub
      end

      def strip_unprotected_userinfo(text)
        # A protected HTTP token can end before a malformed nested credential delimiter.
        # Reuse the bounded structural scan for the remaining prose span before applying the
        # broader fail-closed patterns below.
        text = sanitized_nested_network_urls(text.dup)

        # A credential-bearing network-path reference can appear in an exception message even
        # when it is not the configured bundle URL. Require a non-whitespace token immediately
        # after // so ordinary prose such as "// contact dev@example" remains untouched.
        authority_start_pattern = %r{//(?=\S)}
        authority_token_pattern = /#{authority_start_pattern}[^\s"']+/
        text = text.gsub(authority_token_pattern) do |url|
          sanitized_valid_network_url(url) || strip_malformed_url_userinfo(url)
        end

        # Malformed userinfo can cross prose delimiters before its @. Keep scanning until the
        # next URL-like start and fail closed through the last @ in that bounded span.
        malformed_authority_pattern = /
          #{authority_start_pattern}
          (?:(?!#{HTTP_URL_SCHEME_PATTERN}|#{authority_start_pattern}).)*[\s"']
          (?:(?!#{HTTP_URL_SCHEME_PATTERN}|#{authority_start_pattern}).)*@
        /mx
        text = text.gsub(malformed_authority_pattern) { |span| strip_malformed_url_userinfo(span) }

        scheme_pattern = %r{https?\s*:\s*//}i
        text.gsub(/#{scheme_pattern}(?:(?!#{scheme_pattern}).)*@/m) { |span| strip_malformed_url_userinfo(span) }
      end

      # For malformed URLs or unprotected scheme-delimited spans, remove through the last @. The
      # retained suffix is best-effort context; ambiguous malformed diagnostics may lose text.
      def strip_malformed_url_userinfo(url)
        scheme = url.match(%r{\A[a-z][a-z0-9+.-]*\s*:\s*//}i)
        authority_prefix_end = scheme&.end(0) || (2 if url.start_with?("//"))
        userinfo_delimiter = url.rindex("@")
        return url unless authority_prefix_end && userinfo_delimiter

        "#{url[...authority_prefix_end]}#{url[(userinfo_delimiter + 1)..]}"
      end
    end
  end
end

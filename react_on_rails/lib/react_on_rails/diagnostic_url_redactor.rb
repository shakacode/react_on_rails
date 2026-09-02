# frozen_string_literal: true

require "uri"
require_relative "diagnostic_url_redactor/authority_relative_rewriter"

module ReactOnRails
  # Removes URL userinfo from configured values and diagnostic prose before either is displayed.
  module DiagnosticUrlRedactor
    HTTP_URL_SCHEME_PATTERN = %r{https?://}i
    ENCODED_USERINFO_DELIMITER_PATTERN = /@|%40/i
    ENCODED_AUTHORITY_END_PATTERN = %r{/|%2f|\?|%3f|\#|%23}i
    HTTP_URL_TOKEN_PATTERN = /#{HTTP_URL_SCHEME_PATTERN}(?:(?!#{HTTP_URL_SCHEME_PATTERN})[^\s"'])+/
    FLEXIBLE_HTTP_URL_SCHEME_PATTERN = %r{https?\s*:\s*//}i

    CONFIGURED_URL_NOT_PROVIDED = Object.new.freeze
    private_constant :AuthorityRelativeRewriter, :CONFIGURED_URL_NOT_PROVIDED

    # Rewrites disjoint regex-delimited spans with byte offsets so multibyte prefixes do not
    # force Ruby to rescan the string for every match.
    module ByteSpanRewriter
      module_function

      def rewrite(text, pattern, skip_initial: false)
        binary_text = text.b
        match = first_match(binary_text, pattern, skip_initial)
        return text unless match

        rewritten = text.dup.clear
        unprocessed_start = 0
        while match
          next_match = binary_text.match(pattern, match.end(0))
          span_end = next_match&.begin(0) || text.bytesize
          rewritten << text.byteslice(unprocessed_start, match.begin(0) - unprocessed_start)
          rewritten << yield(text.byteslice(match.begin(0), span_end - match.begin(0)))
          unprocessed_start = span_end
          match = next_match
        end
        rewritten << text.byteslice(unprocessed_start, text.bytesize - unprocessed_start)
      end

      def rewrite_at_offsets(text, offsets)
        return text if offsets.empty?

        rewritten = text.dup.clear
        unprocessed_start = 0
        offsets.each_with_index do |offset, index|
          span_end = offsets[index + 1] || text.bytesize
          rewritten << text.byteslice(unprocessed_start, offset - unprocessed_start)
          rewritten << yield(text.byteslice(offset, span_end - offset))
          unprocessed_start = span_end
        end
        rewritten << text.byteslice(unprocessed_start, text.bytesize - unprocessed_start)
      end

      def first_match(binary_text, pattern, skip_initial)
        match = binary_text.match(pattern)
        return match unless skip_initial && match&.begin(0)&.zero?

        binary_text.match(pattern, match.end(0))
      end
      private_class_method :first_match
    end
    private_constant :ByteSpanRewriter

    # Finds non-overlapping extended URL scheme starts without retrying a greedy
    # pattern at every byte.
    module NetworkUrlStartScanner
      module_function

      def spans(text)
        spans = []
        each_span(text, greedy: true) { |scheme_start, match_end| spans << [scheme_start, match_end] }
        spans
      end

      def first_span(text)
        first = nil
        each_span(text, greedy: false, stop_after_first: true) do |scheme_start, match_end|
          first = [scheme_start, match_end]
        end
        first
      end

      def authority_starts(text)
        starts = []
        each_span(text, greedy: false) { |_scheme_start, match_end| starts << match_end }
        starts
      end

      def each_span(text, greedy:, stop_after_first: false)
        binary_text = text.b
        search_offset = 0

        while (scheme_start = next_scheme_start(binary_text, search_offset))
          match_end, run_end = match_end_and_run_end(binary_text, scheme_start, greedy:)
          if match_end
            yield scheme_start, match_end
            break if stop_after_first

            search_offset = match_end
          else
            search_offset = run_end + 1
          end
        end
      end

      def next_scheme_start(text, offset)
        while offset < text.bytesize
          return offset if ascii_letter_byte?(text.getbyte(offset)) || percent_encoded_byte_at?(text, offset)

          offset += 1
        end

        nil
      end

      # The former regex used a greedy scheme continuation, so an encoded colon
      # is a separator only when it is the rightmost usable one in the run.
      def match_end_and_run_end(text, scheme_start, greedy: true)
        offset = scheme_start
        match_end = nil

        while (token_length = scheme_continuation_token_length(text, offset))
          encoded_separator_end = encoded_separator_end(text, offset, scheme_start)
          return [encoded_separator_end, offset] if encoded_separator_end && !greedy

          match_end = encoded_separator_end if encoded_separator_end
          offset += token_length
        end

        literal_separator_end = network_separator_end(text, offset) if text.getbyte(offset) == 58
        match_end = literal_separator_end if literal_separator_end
        [match_end, offset]
      end

      def encoded_separator_end(text, offset, scheme_start)
        return nil if offset == scheme_start
        return nil unless percent_encoded_colon_at?(text, offset)

        network_separator_end(text, offset)
      end

      def network_separator_end(text, offset)
        separator_length = text.getbyte(offset) == 58 ? 1 : 3
        slash_end = slash_token_end(text, offset + separator_length)
        return nil unless slash_end

        slash_token_end(text, slash_end)
      end

      def slash_token_end(text, offset)
        return offset + 1 if text.getbyte(offset) == 47
        return offset + 3 if percent_encoded_slash_at?(text, offset)

        nil
      end

      def scheme_continuation_token_length(text, offset)
        return 3 if percent_encoded_byte_at?(text, offset)

        byte = text.getbyte(offset)
        return 1 if ascii_letter_byte?(byte) || digit_byte?(byte) || [43, 45, 46].include?(byte)

        nil
      end

      def percent_encoded_colon_at?(text, offset)
        text.getbyte(offset) == 37 && text.getbyte(offset + 1) == 51 &&
          case_insensitive_byte_match?(text.getbyte(offset + 2), 97)
      end

      def percent_encoded_slash_at?(text, offset)
        text.getbyte(offset) == 37 && text.getbyte(offset + 1) == 50 &&
          case_insensitive_byte_match?(text.getbyte(offset + 2), 102)
      end

      def case_insensitive_byte_match?(byte, lowercase_byte)
        byte == lowercase_byte || byte == lowercase_byte - 32
      end

      def digit_byte?(byte)
        byte && (48..57).cover?(byte)
      end

      def percent_encoded_byte_at?(text, offset)
        text.getbyte(offset) == 37 && hex_byte?(text.getbyte(offset + 1)) && hex_byte?(text.getbyte(offset + 2))
      end

      def hex_byte?(byte)
        digit_byte?(byte) || (byte && ((65..70).cover?(byte) || (97..102).cover?(byte)))
      end

      def ascii_letter_byte?(byte)
        byte && ((65..90).cover?(byte) || (97..122).cover?(byte))
      end

      private_class_method :each_span, :next_scheme_start, :match_end_and_run_end, :encoded_separator_end,
                           :network_separator_end, :slash_token_end, :scheme_continuation_token_length,
                           :percent_encoded_colon_at?, :percent_encoded_slash_at?, :case_insensitive_byte_match?,
                           :digit_byte?, :percent_encoded_byte_at?, :hex_byte?, :ascii_letter_byte?
    end
    private_constant :NetworkUrlStartScanner

    # Removes userinfo from every encoded-or-literal authority without decoding
    # or rewriting unrelated path, query, and fragment text.
    module EncodedNetworkUrlRewriter
      module_function

      def rewrite(url, authority_start: nil)
        start_offset = authority_start || detected_authority_start(url)
        return nil unless start_offset

        removal_span = userinfo_removal_span(url, start_offset)
        return nil unless removal_span

        remove_byte_spans(url, [removal_span])
      end

      def rewrite_all(url)
        removal_spans = NetworkUrlStartScanner.authority_starts(url).filter_map do |authority_start|
          userinfo_removal_span(url, authority_start)
        end
        return nil if removal_spans.empty?

        remove_byte_spans(url, removal_spans)
      end

      def authority_end(url, authority_start)
        url.b.match(ENCODED_AUTHORITY_END_PATTERN, authority_start)&.begin(0) || url.bytesize
      end

      def detected_authority_start(url)
        network_url = NetworkUrlStartScanner.spans(url).first
        return network_url.last if network_url&.first&.zero?

        2 if url.start_with?("//")
      end

      def userinfo_removal_span(url, authority_start)
        end_offset = authority_end(url, authority_start)
        authority = url.byteslice(authority_start, end_offset - authority_start)
        _userinfo, delimiter, host = authority.rpartition(ENCODED_USERINFO_DELIMITER_PATTERN)
        return nil if delimiter.empty?

        [authority_start, end_offset - host.bytesize]
      end

      def remove_byte_spans(text, spans)
        rewritten = text.dup.clear
        unprocessed_start = 0

        spans.each do |start_offset, end_offset|
          if start_offset > unprocessed_start
            rewritten << text.byteslice(unprocessed_start, start_offset - unprocessed_start)
          end
          unprocessed_start = [unprocessed_start, end_offset].max
        end
        rewritten << text.byteslice(unprocessed_start, text.bytesize - unprocessed_start)
      end

      private_class_method :authority_end, :detected_authority_start, :userinfo_removal_span, :remove_byte_spans
    end
    private_constant :EncodedNetworkUrlRewriter

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
        scheme = url.match(FLEXIBLE_HTTP_URL_SCHEME_PATTERN)
        return sanitized_configured_url_without_http_scheme(url) unless scheme

        prefix = sanitized_configured_prefix(url[...scheme.begin(0)])
        configured_url = url[scheme.begin(0)..]
        sanitized_url = if configured_url.match?(/[\r\n]/) ||
                           configured_url.scan(FLEXIBLE_HTTP_URL_SCHEME_PATTERN).length > 1
                          strip_malformed_url_userinfo(configured_url)
                        else
                          sanitized_valid_network_url(configured_url) || strip_malformed_url_userinfo(configured_url)
                        end

        "#{prefix}#{sanitized_url}"
      end

      def sanitized_configured_url_without_http_scheme(url)
        network_start = NetworkUrlStartScanner.first_span(url)
        return sanitized_authority_relative_url(url) unless network_start

        start_offset, end_offset = network_start
        literal_authority_start = url.b.index("//")
        return sanitized_authority_relative_url(url) if literal_authority_start && literal_authority_start < end_offset

        prefix = sanitized_configured_prefix(url.byteslice(0, start_offset))
        configured_url = url.byteslice(start_offset, url.bytesize - start_offset)
        sanitized_url = EncodedNetworkUrlRewriter.rewrite_all(configured_url) || configured_url
        "#{prefix}#{sanitized_nested_network_urls(sanitized_url)}"
      end

      def sanitized_authority_relative_url(url)
        AuthorityRelativeRewriter.rewrite(url, delimiter_pattern: ENCODED_USERINFO_DELIMITER_PATTERN) do |span|
          sanitized_valid_network_url(span)
        end
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

      # A configured value with credential-like text before its first URL scheme is malformed,
      # not free-form prose. Fail closed through the prefix's final userinfo delimiter.
      def sanitized_configured_prefix(prefix)
        _userinfo, delimiter, suffix = prefix.rpartition(ENCODED_USERINFO_DELIMITER_PATTERN)
        delimiter.empty? ? prefix : suffix
      end

      # URI handles valid network URLs structurally, so an @ in the path is never mistaken for
      # userinfo. A missing host means an authority-shaped value was parsed as a path instead;
      # returning nil keeps that ambiguous token unprotected for the fail-closed pass.
      def sanitized_valid_network_url(url)
        sanitized_url = sanitized_single_network_url(url)&.dup
        if sanitized_url.nil? || sanitized_url == url
          # A bare outer // authority and an encoded nested scheme need independent passes.
          rewritten_url = EncodedNetworkUrlRewriter.rewrite(url) || url
          rewritten_url = EncodedNetworkUrlRewriter.rewrite_all(rewritten_url) || rewritten_url
          sanitized_url = rewritten_url unless rewritten_url == url
        end
        return nil unless sanitized_url

        sanitized_nested_network_urls(sanitized_url)
      end

      def sanitized_nested_network_urls(sanitized_url)
        # A valid outer URL can carry another credential URL in its path or query. Partition the
        # input into disjoint scheme spans and assemble their replacements from left to right,
        # keeping the work bounded by the input size even when a diagnostic has many URL starts.
        # The first scheme belongs to the outer URL and was handled structurally above.
        sanitized_network_url_spans(sanitized_url, skip_initial: true)
      end

      def sanitized_network_url_spans(text, skip_initial:)
        network_start_offsets = NetworkUrlStartScanner.spans(text).map(&:first)
        network_start_offsets.shift if skip_initial && network_start_offsets.first&.zero?

        ByteSpanRewriter.rewrite_at_offsets(text, network_start_offsets) do |nested_url|
          sanitized_nested_network_url(nested_url)
        end
      end

      def sanitized_nested_network_url(nested_url)
        return nested_url unless nested_url.match?(ENCODED_USERINFO_DELIMITER_PATTERN)

        EncodedNetworkUrlRewriter.rewrite_all(nested_url) ||
          EncodedNetworkUrlRewriter.rewrite(nested_url) ||
          sanitized_single_network_url(nested_url) ||
          nested_url
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

        strip_malformed_http_userinfo(text)
      end

      # Scan disjoint spans between flexible HTTP(S) schemes. Each bounded span reuses the
      # fail-closed last-@ rule, so each input character is scanned a constant number of times.
      def strip_malformed_http_userinfo(text)
        ByteSpanRewriter.rewrite(text, FLEXIBLE_HTTP_URL_SCHEME_PATTERN) do |span|
          strip_malformed_url_userinfo(span)
        end
      end

      # For malformed URLs or unprotected scheme-delimited spans, remove through the last @. The
      # retained suffix is best-effort context; ambiguous malformed diagnostics may lose text.
      def strip_malformed_url_userinfo(url)
        scheme = url.match(%r{\A[a-z][a-z0-9+.-]*\s*:\s*//}i)
        authority_prefix_end = scheme&.end(0) || (2 if url.start_with?("//"))
        _userinfo, delimiter, suffix = url.rpartition(ENCODED_USERINFO_DELIMITER_PATTERN)
        return url unless authority_prefix_end && !delimiter.empty?

        "#{url[...authority_prefix_end]}#{suffix}"
      end
    end
  end
end

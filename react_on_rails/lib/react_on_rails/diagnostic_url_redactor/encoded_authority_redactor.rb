# frozen_string_literal: true

module ReactOnRails
  module DiagnosticUrlRedactor
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

      private_class_method :detected_authority_start, :userinfo_removal_span, :remove_byte_spans
    end

    # Handles bare authorities whose slashes are percent-encoded. The literal marker scans
    # elsewhere in this file cannot see them, so without this pass an encoded spelling of a
    # credential would survive where its literal spelling is redacted.
    module EncodedAuthorityRedactor
      module_function

      # A configured value can begin its bare authority with encoded slashes. Reuse the encoded
      # authority rules so an encoded bare authority fails closed like an encoded HTTP authority.
      def sanitized_authority_relative_url(url)
        marker = url.b.match(ENCODED_AUTHORITY_MARKER_PATTERN)
        return nil unless marker

        authority_start = marker.end(0)
        EncodedNetworkUrlRewriter.rewrite(url, authority_start:) ||
          fail_closed_userinfo(url, authority_start)
      end

      # An encoded authority separator leaves the value structurally unparseable, so the first
      # encoded path/query/fragment token is only a trustworthy authority boundary when the
      # authority it delimits is a plausible host[:port]. Otherwise the value is malformed and
      # fails closed through its final userinfo delimiter, matching the literal malformed rule.
      def fail_closed_userinfo(url, authority_start)
        authority_end = EncodedNetworkUrlRewriter.authority_end(url, authority_start)
        authority = url.byteslice(authority_start, authority_end - authority_start)
        return nil if plausible_authority?(authority)

        tail = url.byteslice(authority_start, url.bytesize - authority_start)
        _userinfo, delimiter, suffix = tail.rpartition(ENCODED_USERINFO_DELIMITER_PATTERN)
        return nil if delimiter.empty?

        "#{url.byteslice(0, authority_start)}#{suffix}"
      end

      # Each token is anchored at its own marker and bounded by whitespace or a quote, so this
      # pass stays linear in the input size.
      def strip_userinfo(text)
        text.gsub(ENCODED_AUTHORITY_TOKEN_PATTERN) do |token|
          sanitized_authority_relative_url(token) || token
        end
      end

      def plausible_authority?(authority)
        !authority.sub(ENCODED_PORT_SUFFIX_PATTERN, "").match?(ENCODED_AUTHORITY_USERINFO_HINT_PATTERN)
      end

      private_class_method :plausible_authority?
    end
  end
end

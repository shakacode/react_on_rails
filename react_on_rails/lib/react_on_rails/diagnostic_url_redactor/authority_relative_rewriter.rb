# frozen_string_literal: true

module ReactOnRails
  module DiagnosticUrlRedactor
    # Rewrites authority-relative URLs with one monotone byte-offset pass. A structurally invalid
    # span stays pending because a later marker and userinfo delimiter may still belong to it.
    class AuthorityRelativeRewriter
      MARKER = "//"
      private_constant :MARKER

      def self.rewrite(text, delimiter_pattern:, &sanitizer)
        new(text, delimiter_pattern, sanitizer).rewrite
      end

      def initialize(text, delimiter_pattern, sanitizer)
        @text = text
        @binary_text = text.b
        @delimiter_pattern = delimiter_pattern
        @sanitizer = sanitizer
        @rewritten = text.dup.clear
        @output_cursor = 0
        @marker_start = @binary_text.index(MARKER)
        @pending_start = nil
        @pending_last_delimiter_end = nil
      end

      def rewrite
        return @text unless @marker_start

        rewrite_bounded_spans
        finish
      end

      private

      def rewrite_bounded_spans
        while (next_marker_start = @binary_text.index(MARKER, @marker_start + MARKER.bytesize))
          consume_bounded_span(next_marker_start)
          @marker_start = next_marker_start
        end
      end

      def consume_bounded_span(span_end)
        span = original_bytes(@marker_start, span_end)
        if @pending_start
          record_last_delimiter(span, @marker_start)
          return
        end

        sanitized_span = @sanitizer.call(span)
        if sanitized_span
          append_original(@output_cursor, @marker_start)
          @rewritten << sanitized_span
          @output_cursor = span_end
        else
          @pending_start = @marker_start
          record_last_delimiter(span, @marker_start)
        end
      end

      def finish
        final_span = original_bytes(@marker_start, @text.bytesize)
        return finish_pending(final_span) if @pending_start

        append_original(@output_cursor, @marker_start)
        @rewritten << (@sanitizer.call(final_span) || strip_ambiguous_userinfo(final_span))
      end

      def finish_pending(final_span)
        record_last_delimiter(final_span, @marker_start)
        append_original(@output_cursor, @pending_start)
        return @rewritten << original_bytes(@pending_start, @text.bytesize) unless @pending_last_delimiter_end

        @rewritten << original_bytes(@pending_start, @pending_start + MARKER.bytesize)
        @rewritten << original_bytes(@pending_last_delimiter_end, @text.bytesize)
      end

      def strip_ambiguous_userinfo(span)
        delimiter_end = last_delimiter_end(span)
        return span unless delimiter_end

        "#{MARKER}#{span.byteslice(delimiter_end, span.bytesize - delimiter_end)}"
      end

      def record_last_delimiter(span, absolute_start)
        delimiter_end = last_delimiter_end(span)
        @pending_last_delimiter_end = absolute_start + delimiter_end if delimiter_end
      end

      def last_delimiter_end(span)
        binary_span = span.b
        delimiter = binary_span.match(@delimiter_pattern)
        last_end = nil
        while delimiter
          last_end = delimiter.end(0)
          delimiter = binary_span.match(@delimiter_pattern, delimiter.end(0))
        end
        last_end
      end

      def append_original(start_offset, end_offset)
        @rewritten << original_bytes(start_offset, end_offset)
      end

      def original_bytes(start_offset, end_offset)
        @text.byteslice(start_offset, end_offset - start_offset)
      end
    end
  end
end

# frozen_string_literal: true

class PrMergeLedger
  module ClosingKeywordScanner
    module InlineCode
      private

      def closing_keyword_in_inline_code(line, line_index, markdown_state)
        normalized_line, inline_code_flags = inline_code_normalized_line(line, line_index, markdown_state)
        multiline_match = markdown_state.delete("inline_code_multiline_match")
        if multiline_match
          reset_inline_code_soft_wrap_state(markdown_state)
          return multiline_match
        end

        match = inline_code_closing_keyword_match(normalized_line, inline_code_flags)
        if markdown_state["inline_code_delimiter"]
          remember_inline_code_soft_wrap_line(normalized_line, inline_code_flags, markdown_state) unless match
          return match
        end

        match ||= soft_wrapped_inline_code_closing_keyword_match(normalized_line, inline_code_flags, markdown_state)
        remember_inline_code_soft_wrap_line(normalized_line, inline_code_flags, markdown_state)
        match
      end

      def inline_code_closing_keyword_match(normalized_line, inline_code_flags)
        index = 0

        loop do
          match = normalized_line.match(CLOSING_KEYWORD_PATTERN, index)
          return nil unless match

          return match[0] if inline_code_flags[match.begin(0)...match.end(0)].any?

          index = match.end(0)
        end
      end

      def soft_wrapped_inline_code_closing_keyword_match(normalized_line, inline_code_flags, markdown_state)
        previous_line = markdown_state["inline_code_previous_normalized_line"]
        previous_flags = markdown_state["inline_code_previous_flags"]
        return unless previous_line && previous_flags
        return if inline_code_soft_wrap_boundary?(normalized_line)

        combined_line = "#{previous_line}\n#{normalized_line}"
        combined_flags = previous_flags + [false] + inline_code_flags
        inline_code_closing_keyword_match(combined_line, combined_flags)
      end

      def remember_inline_code_soft_wrap_line(normalized_line, inline_code_flags, markdown_state)
        if inline_code_soft_wrap_boundary?(normalized_line)
          reset_inline_code_soft_wrap_state(markdown_state)
        else
          markdown_state["inline_code_previous_normalized_line"] = normalized_line
          markdown_state["inline_code_previous_flags"] = inline_code_flags
        end
      end

      def reset_inline_code_soft_wrap_state(markdown_state)
        markdown_state.delete("inline_code_previous_normalized_line")
        markdown_state.delete("inline_code_previous_flags")
      end

      def inline_code_soft_wrap_boundary?(line)
        line.strip.empty? || inline_code_block_boundary?(line)
      end

      def inline_code_normalized_line(line, line_index, markdown_state)
        normalized_line = +""
        inline_code_flags = []
        context = {
          line:,
          line_index:,
          markdown_state:,
          normalized_line:,
          inline_code_flags:
        }
        index = consume_open_inline_code(line, markdown_state, normalized_line, inline_code_flags)
        return [normalized_line, inline_code_flags] unless index

        loop do
          index = consume_next_inline_code_span(context, index)
          return [normalized_line, inline_code_flags] unless index
        end
      end

      def consume_next_inline_code_span(context, index)
        line = context.fetch(:line)
        opening_match = next_unescaped_backtick_run(line, index)
        unless opening_match
          append_inline_code_segment(context.fetch(:normalized_line), context.fetch(:inline_code_flags), line[index..],
                                     in_code: false)
          return nil
        end

        append_inline_code_segment(
          context.fetch(:normalized_line),
          context.fetch(:inline_code_flags),
          line[index...opening_match.begin(0)],
          in_code: false
        )

        closing_match = matching_closing_backtick_run(line, opening_match[0], opening_match.end(0))
        unless closing_match
          append_unmatched_or_multiline_inline_code(context, opening_match)
          return opening_match.end(0) unless context.fetch(:markdown_state).fetch("inline_code_delimiter")

          return nil
        end

        append_inline_code_segment(
          context.fetch(:normalized_line),
          context.fetch(:inline_code_flags),
          line[opening_match.end(0)...closing_match.begin(0)],
          in_code: true
        )
        closing_match.end(0)
      end
    end
  end
end

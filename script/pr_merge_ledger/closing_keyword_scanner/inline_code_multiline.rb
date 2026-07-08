# frozen_string_literal: true

class PrMergeLedger
  module ClosingKeywordScanner
    module InlineCodeMultiline
      private

      def append_unmatched_or_multiline_inline_code(context, opening_match)
        line = context.fetch(:line)
        markdown_state = context.fetch(:markdown_state)

        if inline_code_delimiter_closes_later?(
          markdown_state.fetch("body_lines"),
          context.fetch(:line_index),
          opening_match[0],
          markdown_state.fetch("current_blockquote_depth", 0)
        )
          code_segment = line[opening_match.end(0)..]
          append_inline_code_segment(context.fetch(:normalized_line), context.fetch(:inline_code_flags), code_segment,
                                     in_code: true)
          markdown_state["inline_code_multiline_content"] = code_segment.to_s.dup
          markdown_state["inline_code_multiline_reported"] = code_segment.to_s.match?(CLOSING_KEYWORD_PATTERN)
          markdown_state["inline_code_delimiter"] = opening_match[0]
        else
          append_inline_code_segment(
            context.fetch(:normalized_line),
            context.fetch(:inline_code_flags),
            line[opening_match.begin(0)..],
            in_code: false
          )
        end
      end

      def inline_code_delimiter_closes_later?(body_lines, line_index, delimiter, blockquote_depth)
        body_lines[(line_index + 1)..].to_a.each do |line|
          continuation_line = inline_code_continuation_line(line, blockquote_depth)
          return false unless continuation_line
          return false if continuation_line.strip.empty?
          return false if inline_code_block_boundary?(continuation_line)
          return true if matching_closing_backtick_run(continuation_line, delimiter, 0)
        end

        false
      end

      def inline_code_continuation_line(line, blockquote_depth)
        return line if blockquote_depth.zero?

        markdown_line = line
        blockquote_depth.times do
          marker_match = markdown_line.match(/\A {0,3}> ?/)
          return blockquote_lazy_continuation_line(line) unless marker_match

          markdown_line = markdown_line[marker_match.end(0)..] || ""
        end
        markdown_line
      end

      def blockquote_lazy_continuation_line(line)
        return nil if root_block_boundary_line?(line)
        return nil if line.match?(FENCED_CODE_BLOCK_PATTERN)

        line
      end

      def inline_code_block_boundary?(line)
        root_block_boundary_line?(line) || line.match?(FENCED_CODE_BLOCK_PATTERN)
      end

      def consume_open_inline_code(line, markdown_state, normalized_line, inline_code_flags)
        delimiter = markdown_state.fetch("inline_code_delimiter")
        return 0 unless delimiter

        closing_match = matching_closing_backtick_run(line, delimiter, 0)
        unless closing_match
          append_inline_code_segment(normalized_line, inline_code_flags, line, in_code: true)
          append_multiline_inline_code_content(markdown_state, line)
          return nil
        end

        code_segment = line[...closing_match.begin(0)]
        append_inline_code_segment(normalized_line, inline_code_flags, code_segment, in_code: true)
        append_multiline_inline_code_content(markdown_state, code_segment)
        markdown_state["inline_code_delimiter"] = nil
        markdown_state["inline_code_multiline_content"] = nil
        markdown_state["inline_code_multiline_reported"] = false
        closing_match.end(0)
      end

      def append_multiline_inline_code_content(markdown_state, code_segment)
        content = markdown_state["inline_code_multiline_content"]
        return unless content

        content << code_segment.to_s
        return if markdown_state.fetch("inline_code_multiline_reported")

        match = content.match(CLOSING_KEYWORD_PATTERN)
        return unless match

        markdown_state["inline_code_multiline_match"] = match[0]
        markdown_state["inline_code_multiline_reported"] = true
      end

      def append_inline_code_segment(normalized_line, inline_code_flags, segment, in_code:)
        return unless segment

        normalized_line << segment
        inline_code_flags.concat(Array.new(segment.length, in_code))
      end

      def next_unescaped_backtick_run(line, index)
        loop do
          match = line.match(/`+/, index)
          return nil unless match
          return match unless escaped_character?(line, match.begin(0))

          index = match.end(0)
        end
      end

      def matching_closing_backtick_run(line, delimiter, index)
        loop do
          match = line.match(/`+/, index)
          return nil unless match
          return match if match[0] == delimiter

          index = match.end(0)
        end
      end

      def escaped_character?(line, index)
        backslashes = 0
        cursor = index - 1
        while cursor >= 0 && line[cursor] == "\\"
          backslashes += 1
          cursor -= 1
        end

        backslashes.odd?
      end
    end
  end
end

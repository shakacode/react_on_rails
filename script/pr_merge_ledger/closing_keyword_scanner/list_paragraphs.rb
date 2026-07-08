# frozen_string_literal: true

class PrMergeLedger
  module ClosingKeywordScanner
    module ListParagraphs
      private

      def ordered_list_marker_continues_list_paragraph?(boundary_line, markdown_state)
        return false unless markdown_state&.fetch("list_paragraph_continuation_active", false)

        list_content_indent = markdown_state.fetch("list_content_indent", nil)
        return false unless list_content_indent

        match = boundary_line.match(ORDERED_LIST_ITEM_PATTERN)
        return false unless match && match[:start] != "1"

        marker_indent = column_after_prefix(match[:indent].each_char)
        marker_indent.between?(list_content_indent, list_content_indent + 3)
      end

      def next_list_paragraph_continuation_active(line, current_line_in_fenced_code, markdown_state)
        return false if list_paragraph_state_blocked?(line, current_line_in_fenced_code, markdown_state)
        return true if ordered_list_marker_continues_list_paragraph?(line.chomp, markdown_state)

        list_marker_starts_paragraph_continuation?(line, markdown_state) ||
          list_content_continues_paragraph?(line, markdown_state)
      end

      def list_paragraph_state_blocked?(line, current_line_in_fenced_code, markdown_state)
        current_line_in_fenced_code ||
          markdown_state.fetch("opening_fence") ||
          line.strip.empty? ||
          !markdown_state.fetch("list_content_indent") ||
          list_paragraph_line_code_block?(line, markdown_state)
      end

      def list_paragraph_line_code_block?(line, markdown_state)
        list_marker_indented_code_match(line, markdown_state) ||
          list_indented_code_continuation_line?(line, markdown_state) ||
          indented_code_block_line?(
            line,
            markdown_state.fetch("list_content_indent"),
            markdown_state.fetch("list_indented_code_allowed"),
            markdown_state.fetch("root_indented_code_allowed")
          )
      end

      def list_marker_starts_paragraph_continuation?(line, markdown_state)
        list_match = line.match(LIST_ITEM_WITH_PADDING_PATTERN)
        return false unless list_match

        list_content_indent = markdown_state.fetch("list_content_indent")
        marker_indent = column_after_prefix(list_match[:indent].each_char)
        content_column = column_after_prefix(line[...list_match.begin(:code)])
        return false unless list_marker_indent_allowed_for_line?(marker_indent, list_content_indent, content_column)

        !static_root_block_boundary_line?(list_match[:code].chomp)
      end

      def list_content_continues_paragraph?(line, markdown_state)
        list_content_indent = markdown_state.fetch("list_content_indent")
        return false unless leading_indentation_columns(line) >= list_content_indent

        !root_block_boundary_line?(line, markdown_state)
      end
    end
  end
end

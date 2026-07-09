# frozen_string_literal: true

class PrMergeLedger
  module ClosingKeywordScanner
    module ListBlocks
      private

      def list_marker_indented_code_match(line, markdown_state = nil)
        match = line.match(LIST_ITEM_WITH_PADDING_PATTERN)
        return unless match

        relative_content_column = column_after_prefix(line[...match.begin(:code)])
        marker_indent = column_after_prefix(match[:indent].each_char)
        list_content_indent = markdown_state&.fetch("list_content_indent", nil)
        return unless list_marker_indent_allowed_for_line?(marker_indent, list_content_indent, relative_content_column)

        markdown_start_column = markdown_state&.fetch("current_markdown_start_column", 0).to_i
        marker_end_column = column_after_prefix(line[...match.begin(:padding)], markdown_start_column)
        content_column = column_after_prefix(line[...match.begin(:code)], markdown_start_column)
        return match if content_column >= marker_end_column + 5

        same_line_nested_list_marker_indented_code_match(line, match, relative_content_column, markdown_start_column)
      end

      def list_blockquote_marker_match(line, markdown_state)
        match = line.match(LIST_BLOCKQUOTE_MARKER_PATTERN)
        if match
          marker_indent = column_after_prefix(match[:indent].each_char)
          list_content_indent = markdown_state.fetch("list_content_indent")
          if list_marker_indent_allowed?(marker_indent, list_content_indent)
            return ListBlockquoteMarkerMatch.new(match.end(0), blockquote_marker_depth(match[:blockquotes]))
          end
        end

        list_match = line.match(LIST_ITEM_WITH_PADDING_PATTERN)
        return unless list_match

        marker_indent = column_after_prefix(list_match[:indent].each_char)
        content_column = column_after_prefix(line[...list_match.begin(:code)])
        list_content_indent = markdown_state.fetch("list_content_indent")
        return unless list_marker_indent_allowed_for_line?(marker_indent, list_content_indent, content_column)

        same_line_nested_list_blockquote_marker_match(line, list_match, content_column)
      end

      def blockquote_marker_depth(markers)
        markers.count(">")
      end

      def list_marker_indent_allowed?(marker_indent, list_content_indent)
        return marker_indent <= 3 unless list_content_indent

        marker_indent <= 3 || marker_indent.between?(list_content_indent, list_content_indent + 3)
      end

      def list_marker_indent_allowed_for_line?(marker_indent, list_content_indent, content_column)
        list_marker_indent_allowed?(marker_indent, list_content_indent) || list_content_indent == content_column
      end

      def list_marker_indented_code_indent(line, markdown_state = nil)
        match = list_marker_indented_code_match(line, markdown_state)
        return unless match

        column_after_prefix(line[...match.begin(:code)])
      end

      def list_indented_code_continuation_line?(line, markdown_state)
        active_indent = markdown_state.fetch("list_indented_code_indent")
        return false unless active_indent
        return false unless markdown_state.fetch("list_indented_code_allowed")

        leading_indentation_columns(line) >= active_indent
      end

      def indented_code_block_line?(line, list_content_indent, list_indented_code_allowed, root_indented_code_allowed)
        return root_indented_code_allowed && line.match?(INDENTED_CODE_BLOCK_PATTERN) if list_content_indent.nil?

        list_indented_code_allowed && leading_indentation_columns(line) >= list_content_indent + 4
      end

      def next_list_indented_code_indent(line, markdown_state)
        active_indent = markdown_state.fetch("list_indented_code_indent")
        return active_indent if line.strip.empty?

        marker_indent = list_marker_indented_code_indent(line, markdown_state)
        return marker_indent if marker_indent
        return active_indent if active_indent && leading_indentation_columns(line) >= active_indent

        nil
      end

      def next_list_indented_code_allowed(line, in_fenced_code_block, list_content_indent, list_indented_code_allowed,
                                          markdown_state)
        if list_indented_code_always_allowed?(line, in_fenced_code_block, list_content_indent, markdown_state)
          return true
        end

        return true if list_indented_code_allowed && leading_indentation_columns(line) >= list_content_indent + 4

        false
      end

      def list_indented_code_always_allowed?(line, in_fenced_code_block, list_content_indent, markdown_state)
        list_content_indent.nil? ||
          line.strip.empty? ||
          in_fenced_code_block ||
          fenced_code_block_match(line, list_content_indent) ||
          list_marker_indented_code_match(line, markdown_state) ||
          empty_list_item_line?(line, markdown_state) ||
          list_item_block_boundary_line?(line, markdown_state)
      end

      def empty_list_item_line?(line, markdown_state)
        boundary_line = line.chomp
        return false if ordered_list_marker_continues_paragraph?(boundary_line, markdown_state)
        return false if ordered_list_marker_continues_list_paragraph?(boundary_line, markdown_state)

        match = empty_list_item_match(line)
        return false unless match

        list_marker_indent_allowed?(
          column_after_prefix(match[:indent].each_char),
          markdown_state.fetch("list_content_indent")
        )
      end

      def list_item_block_boundary_line?(line, markdown_state)
        return false if ordered_list_marker_continues_list_paragraph?(line.chomp, markdown_state)

        list_match = line.match(LIST_ITEM_WITH_PADDING_PATTERN)
        return false unless list_match

        list_content_indent = markdown_state.fetch("list_content_indent")
        marker_indent = column_after_prefix(list_match[:indent].each_char)
        return false unless list_marker_indent_allowed?(marker_indent, list_content_indent)

        list_item_content_block_boundary_line?(list_match[:code].chomp, markdown_state)
      end

      def next_root_indented_code_allowed(line, in_fenced_code_block, root_indented_code_allowed, markdown_state)
        stripped_line = line.strip
        return true if stripped_line.empty?
        return true if in_fenced_code_block || line.match?(FENCED_CODE_BLOCK_PATTERN)
        return true if root_indented_code_allowed && line.match?(INDENTED_CODE_BLOCK_PATTERN)
        return true if root_block_boundary_line?(line, markdown_state)

        false
      end

      def list_item_content_block_boundary_line?(line, markdown_state)
        static_root_block_boundary_line?(line) || link_reference_definition_line?(line, markdown_state)
      end
    end
  end
end

# frozen_string_literal: true

class PrMergeLedger
  module ClosingKeywordScanner
    module ListBlocks
      private

      def list_marker_indented_code_match(line, markdown_state = nil)
        match = line.match(LIST_ITEM_WITH_PADDING_PATTERN)
        return unless match

        marker_end_column = column_after_prefix(line[...match.begin(:padding)])
        content_column = column_after_prefix(line[...match.begin(:code)])
        marker_indent = column_after_prefix(match[:indent].each_char)
        list_content_indent = markdown_state&.fetch("list_content_indent", nil)
        return unless list_marker_indent_allowed_for_line?(marker_indent, list_content_indent, content_column)

        blockquote_depth = markdown_state&.fetch("current_blockquote_depth", 0).to_i
        tab_indented_code = blockquote_depth.positive? &&
                            match[:padding].include?("\t") &&
                            content_column >= marker_end_column + 3
        return match if tab_indented_code || content_column >= marker_end_column + 5

        same_line_nested_list_marker_indented_code_match(line, match, content_column)
      end

      def same_line_nested_list_marker_indented_code_match(line, outer_match, outer_content_column)
        nested_line_offset = outer_match.begin(:code)
        list_content_column = outer_content_column

        loop do
          nested_line = line[nested_line_offset..] || ""
          nested_match = nested_line.match(LIST_ITEM_WITH_PADDING_PATTERN)
          return unless nested_match

          marker_end_column = column_after_prefix(line[...nested_line_offset + nested_match.begin(:padding)])
          content_column = column_after_prefix(line[...nested_line_offset + nested_match.begin(:code)])
          marker_indent = column_after_prefix(line[...nested_line_offset + nested_match.begin(0)])
          return unless list_marker_indent_allowed?(marker_indent, list_content_column)

          if content_column >= marker_end_column + 5
            return ListMarkerIndentedCodeMatch.new(nested_match[:code], nested_line_offset + nested_match.begin(:code))
          end

          nested_line_offset += nested_match.begin(:code)
          list_content_column = content_column
        end
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

      def same_line_nested_list_blockquote_marker_match(line, outer_match, outer_content_column)
        nested_line_offset = outer_match.begin(:code)
        list_content_column = outer_content_column

        loop do
          nested_line = line[nested_line_offset..] || ""
          nested_match = nested_line.match(LIST_ITEM_WITH_PADDING_PATTERN)
          return unless nested_match

          content_column = column_after_prefix(line[...nested_line_offset + nested_match.begin(:code)])
          marker_indent = column_after_prefix(line[...nested_line_offset + nested_match.begin(0)])
          return unless list_marker_indent_allowed?(marker_indent, list_content_column)

          blockquote_line_offset = nested_line_offset + nested_match.begin(:code)
          blockquote_match = line[blockquote_line_offset..].to_s.match(/\A(?:> ?)+/)
          if blockquote_match
            return ListBlockquoteMarkerMatch.new(
              blockquote_line_offset + blockquote_match.end(0),
              blockquote_marker_depth(blockquote_match[0])
            )
          end

          nested_line_offset = blockquote_line_offset
          list_content_column = content_column
        end
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
          list_item_atx_heading_line?(line, markdown_state)
      end

      def list_item_atx_heading_line?(line, markdown_state)
        list_match = line.match(LIST_ITEM_WITH_PADDING_PATTERN)
        return false unless list_match

        list_content_indent = markdown_state.fetch("list_content_indent")
        marker_indent = column_after_prefix(list_match[:indent].each_char)
        return false unless list_marker_indent_allowed?(marker_indent, list_content_indent)

        list_match[:code].match?(/\A\#{1,6}(?:\s|\z)/)
      end

      def next_root_indented_code_allowed(line, in_fenced_code_block, root_indented_code_allowed, markdown_state)
        stripped_line = line.strip
        return true if stripped_line.empty?
        return true if in_fenced_code_block || line.match?(FENCED_CODE_BLOCK_PATTERN)
        return true if root_indented_code_allowed && line.match?(INDENTED_CODE_BLOCK_PATTERN)
        return true if root_block_boundary_line?(line, markdown_state)

        false
      end
    end
  end
end

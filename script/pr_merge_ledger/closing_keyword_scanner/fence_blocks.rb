# frozen_string_literal: true

class PrMergeLedger
  module ClosingKeywordScanner
    module FenceBlocks
      private

      def list_content_indent_for_line(line, markdown_state)
        current_indent = markdown_state.fetch("list_content_indent")
        return current_indent if line.strip.empty?
        return current_indent if ordered_list_marker_continues_paragraph?(line.chomp, markdown_state)
        return current_indent if ordered_list_marker_continues_list_paragraph?(line.chomp, markdown_state)

        marker_content_indent = list_marker_content_indent_for_line(line, current_indent)
        return marker_content_indent if marker_content_indent

        empty_marker_content_indent = empty_list_item_content_indent_for_line(line, current_indent)
        return empty_marker_content_indent if empty_marker_content_indent

        return current_indent if current_indent && leading_indentation_columns(line) >= current_indent

        nil
      end

      def list_marker_content_indent_for_line(line, current_indent)
        list_match = line.match(LIST_ITEM_PATTERN)
        return unless list_match

        marker_indent = column_after_prefix(list_match[:indent].each_char)
        column_after_prefix(list_match[0]) if list_marker_indent_allowed?(marker_indent, current_indent)
      end

      def empty_list_item_content_indent_for_line(line, current_indent)
        empty_list_match = empty_list_item_match(line)
        return unless empty_list_match

        marker_indent = column_after_prefix(empty_list_match[:indent].each_char)
        empty_list_item_content_indent(line, empty_list_match) if list_marker_indent_allowed?(
          marker_indent,
          current_indent
        )
      end

      def column_after_prefix(prefix, start_column = 0)
        characters = prefix.respond_to?(:each_char) ? prefix.each_char : prefix.each

        characters.reduce(start_column) do |column, character|
          character == "\t" ? column + (4 - (column % 4)) : column + 1
        end
      end

      def leading_indentation_columns(line)
        indentation = line.each_char.take_while { |character| INDENTATION_CHARACTERS.include?(character) }
        column_after_prefix(indentation)
      end

      def empty_list_item_match(line)
        line.match(EMPTY_LIST_ITEM_PATTERN)
      end

      def empty_list_item_content_indent(line, match)
        column_after_prefix(line[...match.end(:marker)].each_char) + 1
      end

      def next_opening_fence(line, opening_fence, list_content_indent, blockquote_depth)
        fence_match = fenced_code_block_match(line, list_content_indent)
        return opening_fence unless fence_match
        return nil if opening_fence && closing_fenced_code_block?(line, opening_fence)
        return opening_fence if opening_fence

        container_indent = if fence_match.respond_to?(:container_indent)
                             fence_match.container_indent
                           else
                             list_content_indent || 0
                           end

        {
          fence: fence_match[:fence],
          container_indent:,
          blockquote_depth:
        }
      end

      def closing_fenced_code_block?(line, opening_fence)
        fence = opening_fence.fetch(:fence)
        container_indent = opening_fence.fetch(:container_indent)
        fence_char = Regexp.escape(fence[0])
        indentation_match = line.match(/\A[ \t]*/)
        indentation_columns = column_after_prefix(indentation_match[0].each_char)
        return false unless indentation_columns.between?(container_indent, container_indent + 3)

        line[indentation_match.end(0)..].to_s.match?(/\A#{Regexp.escape(fence)}#{fence_char}*\s*\z/)
      end

      def fenced_code_block_match(line, list_content_indent)
        list_fence_match = list_fenced_code_block_match(line, list_content_indent)
        return list_fence_match if list_fence_match

        unless list_content_indent
          root_fence_match = line.match(FENCED_CODE_BLOCK_PATTERN)
          return root_fence_match if valid_fenced_code_block_opener?(line, root_fence_match)

          return nil
        end

        indented_fence_match = line.match(/\A[ \t]*(?<fence>`{3,}|~{3,})/)
        return unless indented_fence_match
        return unless valid_fenced_code_block_opener?(line, indented_fence_match)

        indentation_columns = column_after_prefix(line[...indented_fence_match.begin(:fence)].each_char)
        return unless indentation_columns.between?(list_content_indent, list_content_indent + 3)

        indented_fence_match
      end

      def list_fenced_code_block_match(line, list_content_indent)
        match = line.match(LIST_FENCED_CODE_BLOCK_PATTERN)
        if match && valid_fenced_code_block_opener?(line, match)
          marker_indent = column_after_prefix(match[:indent].each_char)
          content_column = column_after_prefix(line[...match.begin(:fence)].each_char)
          return match if list_marker_indent_allowed_for_line?(marker_indent, list_content_indent, content_column)
        end

        list_match = line.match(LIST_ITEM_WITH_PADDING_PATTERN)
        return unless list_match

        marker_indent = column_after_prefix(list_match[:indent].each_char)
        content_column = column_after_prefix(line[...list_match.begin(:code)].each_char)
        return unless list_marker_indent_allowed_for_line?(marker_indent, list_content_indent, content_column)

        same_line_nested_list_fenced_code_block_match(line, list_match, content_column)
      end

      def same_line_nested_list_fenced_code_block_match(line, outer_match, outer_content_column)
        each_same_line_nested_list_item(line, outer_match, outer_content_column) do |_match, fence_line_offset,
                                                                                     _marker_end_column,
                                                                                     content_column|
          fence_match = same_line_nested_list_fence_match(line, fence_line_offset, content_column)
          return fence_match if fence_match
        end
      end

      def same_line_nested_list_fence_match(line, fence_line_offset, content_column)
        fence_match = line.match(SAME_LINE_FENCED_CODE_BLOCK_PATTERN, fence_line_offset)
        return unless valid_fenced_code_block_opener?(line, fence_match)

        FencedCodeBlockMatch.new(
          fence_match[:fence],
          fence_match.begin(:fence),
          fence_match.end(:fence),
          content_column
        )
      end

      def valid_fenced_code_block_opener?(line, match)
        return false unless match

        fence = match[:fence]
        return true unless fence.start_with?("`")

        !line[match.end(:fence)..].to_s.include?("`")
      end
    end
  end
end

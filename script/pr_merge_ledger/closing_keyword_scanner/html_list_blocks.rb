# frozen_string_literal: true

class PrMergeLedger
  module ClosingKeywordScanner
    module HtmlListBlocks
      private

      def list_item_html_block_context_for_line(line, markdown_state)
        return unless markdown_state

        list_match = line.match(LIST_ITEM_WITH_PADDING_PATTERN)
        return unless list_match
        return if list_item_marker_continues_active_paragraph?(line, markdown_state)

        marker_indent = column_after_prefix(list_match[:indent].each_char)
        content_column = column_after_prefix(line[...list_match.begin(:code)].each_char)
        return unless list_marker_indent_allowed_for_line?(
          marker_indent,
          markdown_state.fetch("list_content_indent"),
          content_column
        )

        child_state = child_list_item_markdown_state(markdown_state)
        context = direct_html_block_context_for_list_item_line(list_match[:code], child_state)
        return context if context

        same_line_nested_list_item_html_block_context(line, list_match, content_column, child_state)
      end

      def same_line_nested_list_item_html_block_context(line, outer_match, outer_content_column, markdown_state)
        each_same_line_nested_list_item(line, outer_match, outer_content_column) do |item|
          next unless possible_html_block_context_start?(line, item.code_offset)

          context = direct_html_block_context_for_list_item_line(line[item.code_offset..], markdown_state)
          return context if context
        end
      end

      def list_html_block_context_for_line(line, markdown_state)
        list_item_html_block_context_for_line(line, markdown_state) ||
          list_indented_html_block_context_for_line(line, markdown_state)
      end

      def list_indented_html_block_context_for_line(line, markdown_state)
        return unless markdown_state

        content_indent = markdown_state.fetch("list_content_indent")
        return unless content_indent

        indentation_columns = leading_indentation_columns(line)
        return unless indentation_columns.between?(content_indent, content_indent + 3)

        html_block_context_for_line(
          line_without_indentation_columns(line, content_indent),
          markdown_state
        )
      end

      def direct_html_block_context_for_list_item_line(line, markdown_state)
        return unless possible_html_block_context_start?(line, 0)

        direct_html_block_context_for_line(line, markdown_state)
      end

      def possible_html_block_context_start?(line, offset)
        index = offset
        spaces = 0
        while spaces <= 3
          character = line[index]
          return character == "<" unless character == " "

          index += 1
          spaces += 1
        end

        false
      end
    end
  end
end

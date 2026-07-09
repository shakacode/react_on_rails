# frozen_string_literal: true

class PrMergeLedger
  module ClosingKeywordScanner
    module SameLineNestedListItems
      SameLineNestedListItem = Struct.new(
        :match,
        :code_offset,
        :marker_indent,
        :marker_end_column,
        :content_column,
        :absolute_marker_end_column,
        :absolute_content_column,
        keyword_init: true
      )
      SameLineNestedListState = Struct.new(
        :line_offset,
        :line_column,
        :absolute_line_column,
        :list_content_column,
        keyword_init: true
      )

      private

      def same_line_nested_list_marker_indented_code_match(line, outer_match, outer_content_column,
                                                           markdown_start_column = 0)
        each_same_line_nested_list_item(line, outer_match, outer_content_column, markdown_start_column) do |item|
          if item.absolute_content_column >= item.absolute_marker_end_column + 5
            return ListMarkerIndentedCodeMatch.new(item.match[:code], item.code_offset)
          end
        end
      end

      def same_line_nested_list_blockquote_marker_match(line, outer_match, outer_content_column)
        each_same_line_nested_list_item(line, outer_match, outer_content_column) do |item|
          blockquote_match = line.match(SAME_LINE_BLOCKQUOTE_MARKER_PATTERN, item.code_offset)
          if blockquote_match
            return ListBlockquoteMarkerMatch.new(
              blockquote_match.end(0),
              blockquote_marker_depth(blockquote_match[0])
            )
          end
        end
      end

      def same_line_nested_list_content_indent(line, outer_match, outer_content_column)
        deepest_content_column = nil
        each_same_line_nested_list_item(line, outer_match, outer_content_column) do |item|
          deepest_content_column = item.content_column
          nil
        end

        deepest_content_column
      end

      def each_same_line_nested_list_item(line, outer_match, outer_content_column, markdown_start_column = 0)
        state = SameLineNestedListState.new(
          line_offset: outer_match.begin(:code),
          line_column: outer_content_column,
          absolute_line_column: markdown_start_column + outer_content_column,
          list_content_column: outer_content_column
        )

        loop do
          item = next_same_line_nested_list_item(line, state)
          return unless item
          return unless list_marker_indent_allowed?(item.marker_indent, state.list_content_column)

          result = yield item
          return result if result

          state = next_same_line_nested_list_state(item)
        end
      end

      def next_same_line_nested_list_item(line, state)
        nested_match = line.match(SAME_LINE_LIST_ITEM_WITH_PADDING_PATTERN, state.line_offset)
        return unless nested_match

        SameLineNestedListItem.new(
          match: nested_match,
          code_offset: nested_match.begin(:code),
          marker_indent: same_line_nested_list_marker_indent(line, nested_match, state),
          marker_end_column: same_line_nested_list_marker_end_column(line, nested_match, state, state.line_column),
          content_column: same_line_nested_list_content_column(line, nested_match, state, state.line_column),
          absolute_marker_end_column: same_line_nested_list_marker_end_column(
            line,
            nested_match,
            state,
            state.absolute_line_column
          ),
          absolute_content_column: same_line_nested_list_content_column(
            line,
            nested_match,
            state,
            state.absolute_line_column
          )
        )
      end

      def same_line_nested_list_marker_indent(line, nested_match, state)
        column_after_prefix(
          line[state.line_offset...nested_match.begin(:marker)],
          state.line_column
        )
      end

      def same_line_nested_list_marker_end_column(line, nested_match, state, start_column)
        column_after_prefix(line[state.line_offset...nested_match.begin(:padding)], start_column)
      end

      def same_line_nested_list_content_column(line, nested_match, state, start_column)
        column_after_prefix(line[state.line_offset...nested_match.begin(:code)], start_column)
      end

      def next_same_line_nested_list_state(item)
        SameLineNestedListState.new(
          line_offset: item.code_offset,
          line_column: item.content_column,
          absolute_line_column: item.absolute_content_column,
          list_content_column: item.content_column
        )
      end
    end
  end
end

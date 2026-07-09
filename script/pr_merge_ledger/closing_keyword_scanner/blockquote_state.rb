# frozen_string_literal: true

class PrMergeLedger
  module ClosingKeywordScanner
    module BlockquoteState
      private

      def close_blockquote_fence_if_needed(markdown_state, blockquote_depth)
        opening_fence = markdown_state.fetch("opening_fence")
        return unless opening_fence
        return unless blockquote_depth < opening_fence.fetch(:blockquote_depth)

        markdown_state["opening_fence"] = nil
      end

      def close_outdented_list_fence_if_needed(markdown_state, line)
        opening_fence = markdown_state.fetch("opening_fence")
        return unless opening_fence

        container_indent = opening_fence.fetch(:container_indent)
        return if container_indent.zero?
        return if line.strip.empty?
        return if leading_indentation_columns(line) >= container_indent

        markdown_state["opening_fence"] = nil
      end

      def body_markdown_line_and_depth(line, markdown_state)
        opening_fence = markdown_state.fetch("opening_fence")
        return fenced_code_markdown_line_and_depth(line, opening_fence) if opening_fence

        markdown_line = line
        markdown_column = 0
        blockquote_depth = 0
        line_has_blockquote_marker = false
        line_has_list_blockquote_marker = false

        loop do
          marker_match = markdown_line.match(/\A {0,3}> ?/)
          break unless marker_match

          blockquote_depth += 1
          line_has_blockquote_marker = true
          markdown_column = column_after_prefix(markdown_line[...marker_match.end(0)], markdown_column)
          markdown_line = markdown_line[marker_match.end(0)..] || ""
        end

        list_blockquote_match = list_blockquote_marker_match(markdown_line, markdown_state)
        if list_blockquote_match
          blockquote_depth += list_blockquote_match.blockquote_depth
          line_has_blockquote_marker = true
          line_has_list_blockquote_marker = true
          markdown_column = column_after_prefix(markdown_line[...list_blockquote_match.end(0)], markdown_column)
          markdown_line = markdown_line[list_blockquote_match.end(0)..] || ""
        end

        normalized_blockquote_markdown_line_and_depth(
          line,
          markdown_line,
          blockquote_depth,
          {
            marker_found: line_has_blockquote_marker,
            list_blockquote_marker_found: line_has_list_blockquote_marker,
            marker_content_column: markdown_column,
            markdown_state:
          }
        )
      end

      def normalized_blockquote_markdown_line_and_depth(line, markdown_line, blockquote_depth, context)
        markdown_state = context.fetch(:markdown_state)
        if context.fetch(:marker_found)
          markdown_state["current_markdown_start_column"] = context.fetch(:marker_content_column)
          return [
            normalize_blockquote_content_indentation(
              markdown_line,
              blockquote_depth,
              context.fetch(:list_blockquote_marker_found),
              context.fetch(:marker_content_column)
            ),
            blockquote_depth
          ]
        end

        if markdown_state.fetch("blockquote_depth").positive? &&
           markdown_state.fetch("blockquote_lazy_continuation_allowed") &&
           blockquote_lazy_continuation_line(line, markdown_state)
          return [markdown_line, markdown_state.fetch("blockquote_depth")]
        end

        [markdown_line, blockquote_depth]
      end

      def blockquote_lazy_continuation_allowed_for_next_line?(line, current_line_in_fenced_code, blockquote_depth)
        return false unless blockquote_depth.positive?
        return false if current_line_in_fenced_code

        !line.strip.empty?
      end

      def normalize_blockquote_content_indentation(line, blockquote_depth, _list_blockquote_marker_found,
                                                   marker_content_column)
        return line unless blockquote_depth.positive?

        indentation = line.each_char.take_while { |character| INDENTATION_CHARACTERS.include?(character) }
        return line if indentation.empty?

        column = marker_content_column
        relative_indent = 0
        indentation.each do |character|
          next_column = character == "\t" ? column + (4 - (column % 4)) : column + 1
          relative_indent += next_column - column
          column = next_column
        end

        "#{' ' * relative_indent}#{line[indentation.length..]}"
      end

      def fenced_code_markdown_line_and_depth(line, opening_fence)
        markdown_line = line
        blockquote_depth = 0

        opening_fence.fetch(:blockquote_depth).times do
          marker_match = markdown_line.match(/\A {0,3}> ?/)
          break unless marker_match

          blockquote_depth += 1
          markdown_line = markdown_line[marker_match.end(0)..] || ""
        end

        [markdown_line, blockquote_depth + blockquote_depth_for_line(markdown_line)]
      end

      def blockquote_depth_for_line(line)
        blockquote_depth = 0
        markdown_line = line

        loop do
          marker_match = markdown_line.match(/\A {0,3}> ?/)
          return blockquote_depth unless marker_match

          blockquote_depth += 1
          markdown_line = markdown_line[marker_match.end(0)..] || ""
        end
      end

      def reset_markdown_state_for_blockquote_change(markdown_state, blockquote_depth)
        return if blockquote_depth == markdown_state.fetch("blockquote_depth")

        markdown_state["list_content_indent"] = nil
        markdown_state["list_indented_code_indent"] = nil
        markdown_state["list_indented_code_allowed"] = true
        markdown_state["root_indented_code_allowed"] = true
      end

      def effective_blockquote_depth(markdown_state, blockquote_depth)
        opening_fence = markdown_state.fetch("opening_fence")
        return opening_fence.fetch(:blockquote_depth) if opening_fence

        blockquote_depth
      end
    end
  end
end

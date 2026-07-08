# frozen_string_literal: true

class PrMergeLedger
  module ClosingKeywordScanner
    module CodeBlocks
      private

      def closing_keyword_in_code_block(line, in_fenced_code_block, markdown_state)
        fence_opener_closing_keyword = closing_keyword_in_fence_opener(line, markdown_state.fetch("fence_opener_match"))
        return fence_opener_closing_keyword if fence_opener_closing_keyword

        html_block_closing_keyword = closing_keyword_in_html_block(line, markdown_state)
        return html_block_closing_keyword if html_block_closing_keyword

        list_indented_code_match = closing_keyword_in_list_indented_code(line, markdown_state)
        return list_indented_code_match if list_indented_code_match
        return line.match(CLOSING_KEYWORD_PATTERN) if list_indented_code_continuation_line?(line, markdown_state)

        if in_fenced_code_block ||
           indented_code_block_line?(
             line,
             markdown_state.fetch("list_content_indent"),
             markdown_state.fetch("list_indented_code_allowed"),
             markdown_state.fetch("root_indented_code_allowed")
           )
          return line.match(CLOSING_KEYWORD_PATTERN)
        end

        nil
      end

      def closing_keyword_in_fence_opener(line, fence_opener_match)
        return unless fence_opener_match

        line[fence_opener_match.end(0)..]&.match(CLOSING_KEYWORD_PATTERN)
      end

      def closing_keyword_in_list_indented_code(line, markdown_state)
        list_marker_indented_code_match(line, markdown_state)&.[](:code)&.match(CLOSING_KEYWORD_PATTERN)
      end

      def closing_keyword_in_html_block(line, markdown_state)
        unless html_block_line?(line, markdown_state)
          reset_multiline_html_block_state(markdown_state)
          return
        end

        line.match(CLOSING_KEYWORD_PATTERN) || closing_keyword_in_multiline_html_block(line, markdown_state)
      end

      def closing_keyword_in_multiline_html_block(line, markdown_state)
        return if markdown_state.fetch("html_block_multiline_reported")

        content = markdown_state.fetch("html_block_multiline_content")
        content = if content
                    content << "\n"
                    content << line.to_s
                  else
                    line.to_s.dup
                  end
        markdown_state["html_block_multiline_content"] = content

        match = content.match(CLOSING_KEYWORD_PATTERN)
        return unless match

        markdown_state["html_block_multiline_reported"] = true
        match
      end

      def reset_multiline_html_block_state(markdown_state)
        markdown_state["html_block_multiline_content"] = nil
        markdown_state["html_block_multiline_reported"] = false
      end

      def closing_keyword_in_multiline_code_block(line, markdown_state)
        return if markdown_state.fetch("code_block_multiline_reported")

        content = markdown_state.fetch("code_block_multiline_content")
        content = if content
                    content << "\n"
                    content << line.to_s
                  else
                    line.to_s.dup
                  end
        markdown_state["code_block_multiline_content"] = content

        match = content.match(CLOSING_KEYWORD_PATTERN)
        return unless match

        markdown_state["code_block_multiline_reported"] = true
        match
      end

      def reset_multiline_code_block_state(markdown_state)
        markdown_state["code_block_multiline_content"] = nil
        markdown_state["code_block_multiline_reported"] = false
      end
    end
  end
end

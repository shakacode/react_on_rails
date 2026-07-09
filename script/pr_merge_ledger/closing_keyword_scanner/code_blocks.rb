# frozen_string_literal: true

class PrMergeLedger
  module ClosingKeywordScanner
    module CodeBlocks
      private

      def closing_keyword_in_code_block(line, in_fenced_code_block, markdown_state)
        fence_opener_closing_keyword = closing_keyword_in_fence_opener(line, markdown_state.fetch("fence_opener_match"))
        return fence_opener_closing_keyword if fence_opener_closing_keyword

        link_reference_closing_keyword = closing_keyword_in_link_reference(line, markdown_state)
        return link_reference_closing_keyword if link_reference_closing_keyword

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
        html_block = html_block_context_for_scan(line, markdown_state)
        unless html_block
          reset_multiline_html_block_state(markdown_state)
          return
        end

        reset_multiline_html_block_state(markdown_state) if new_html_block?(markdown_state, html_block)
        line.match(CLOSING_KEYWORD_PATTERN) || closing_keyword_in_multiline_html_block(line, markdown_state)
      end

      def html_block_context_for_scan(line, markdown_state)
        active_block = markdown_state.fetch("html_block")
        if active_block
          return nil if html_block_exited_container?(line, markdown_state, active_block)

          return active_block
        end

        html_block_context_for_line(line, markdown_state)
      end

      def new_html_block?(markdown_state, html_block)
        markdown_state.fetch("html_block").nil? && !html_block.nil?
      end

      def closing_keyword_in_multiline_html_block(line, markdown_state)
        return if markdown_state.fetch("html_block_multiline_reported")

        content, previous_length, candidate_start, appended_text = append_multiline_scan_content(
          markdown_state,
          "html_block_multiline_content",
          line,
          separator: "\n"
        )

        match = closing_keyword_in_updated_multiline_content(content, previous_length, candidate_start)
        update_multiline_closing_keyword_candidate_start(
          markdown_state,
          "html_block_multiline_content",
          content,
          candidate_start,
          appended_text
        )
        return unless match

        markdown_state["html_block_multiline_reported"] = true
        match
      end

      def reset_multiline_html_block_state(markdown_state)
        markdown_state["html_block_multiline_content"] = nil
        markdown_state["html_block_multiline_reported"] = false
        markdown_state["html_block_multiline_content_closing_keyword_candidate_start"] = nil
      end

      def closing_keyword_in_multiline_code_block(line, markdown_state)
        return if markdown_state.fetch("code_block_multiline_reported")

        content, previous_length, candidate_start, appended_text = append_multiline_scan_content(
          markdown_state,
          "code_block_multiline_content",
          line,
          separator: "\n"
        )

        match = closing_keyword_in_updated_multiline_content(content, previous_length, candidate_start)
        update_multiline_closing_keyword_candidate_start(
          markdown_state,
          "code_block_multiline_content",
          content,
          candidate_start,
          appended_text
        )
        return unless match

        markdown_state["code_block_multiline_reported"] = true
        match
      end

      def reset_multiline_code_block_state(markdown_state)
        markdown_state["code_block_multiline_content"] = nil
        markdown_state["code_block_multiline_reported"] = false
        markdown_state["code_block_multiline_content_closing_keyword_candidate_start"] = nil
      end

      def append_multiline_scan_content(markdown_state, state_key, segment, separator: nil)
        content = markdown_state.fetch(state_key)
        previous_length = content&.length || 0
        candidate_start = markdown_state.fetch(multiline_closing_keyword_candidate_state_key(state_key), nil)
        appended_text = content && separator ? "#{separator}#{segment}" : segment.to_s
        content = if content
                    content << appended_text
                  else
                    appended_text.dup
                  end
        markdown_state[state_key] = content

        [content, previous_length, candidate_start, appended_text]
      end

      def closing_keyword_in_updated_multiline_content(content, previous_length, candidate_start = nil)
        scan_start = [previous_length - CLOSING_KEYWORD_TAIL_OVERLAP_CHARACTERS, 0].max
        scan_start = [candidate_start, scan_start].compact.min

        content[scan_start..].to_s.match(CLOSING_KEYWORD_PATTERN)
      end

      def update_multiline_closing_keyword_candidate_start(markdown_state, state_key, content, previous_candidate_start,
                                                           appended_text)
        candidate_start =
          if previous_candidate_start && appended_text.match?(/\A\s*\z/)
            previous_candidate_start
          else
            closing_keyword_pending_candidate_start(content)
          end
        markdown_state[multiline_closing_keyword_candidate_state_key(state_key)] = candidate_start
      end

      def closing_keyword_pending_candidate_start(content)
        suffix_start = [content.length - CLOSING_KEYWORD_TAIL_OVERLAP_CHARACTERS, 0].max
        suffix = content[suffix_start..].to_s
        match = suffix.match(CLOSING_KEYWORD_PENDING_PATTERN)
        match && (suffix_start + match.begin(:keyword))
      end

      def multiline_closing_keyword_candidate_state_key(state_key)
        "#{state_key}_closing_keyword_candidate_start"
      end
    end
  end
end

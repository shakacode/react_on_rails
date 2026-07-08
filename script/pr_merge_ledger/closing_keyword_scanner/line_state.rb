# frozen_string_literal: true

class PrMergeLedger
  module ClosingKeywordScanner
    module LineState
      private

      def code_block_closing_keyword_match(line, current_line_in_fenced_code, code_block_line, markdown_state)
        block_match = closing_keyword_in_code_block(line, current_line_in_fenced_code, markdown_state)
        block_match ||= closing_keyword_in_multiline_code_block(line, markdown_state) if code_block_line
        reset_multiline_code_block_state(markdown_state) unless code_block_line
        block_match
      end

      def update_blockquote_lazy_continuation_state(markdown_state, line, current_line_in_fenced_code)
        markdown_state["blockquote_lazy_continuation_allowed"] = blockquote_lazy_continuation_allowed_for_next_line?(
          line,
          current_line_in_fenced_code,
          markdown_state.fetch("blockquote_depth")
        )
      end

      def update_body_markdown_state_before_scan(line, current_line_in_fenced_code, blockquote_depth, markdown_state)
        unless current_line_in_fenced_code
          markdown_state["list_content_indent"] =
            list_content_indent_for_line(line, markdown_state)
        end

        markdown_state["fence_opener_match"] =
          if markdown_state.fetch("opening_fence")
            nil
          else
            fenced_code_block_match(line, markdown_state.fetch("list_content_indent"))
          end
        markdown_state["opening_fence"] = next_opening_fence(
          line,
          markdown_state.fetch("opening_fence"),
          markdown_state.fetch("list_content_indent"),
          blockquote_depth
        )
      end

      def code_block_line_for_state?(line, current_line_in_fenced_code, markdown_state)
        current_line_in_fenced_code ||
          markdown_state.fetch("fence_opener_match") ||
          list_marker_indented_code_match(line, markdown_state) ||
          list_indented_code_continuation_line?(line, markdown_state) ||
          indented_code_block_line?(
            line,
            markdown_state.fetch("list_content_indent"),
            markdown_state.fetch("list_indented_code_allowed"),
            markdown_state.fetch("root_indented_code_allowed")
          )
      end

      def update_body_markdown_state_after_scan(line, current_line_in_fenced_code, markdown_state)
        markdown_state["list_indented_code_indent"] = next_list_indented_code_indent(line, markdown_state)
        markdown_state["list_indented_code_allowed"] = next_list_indented_code_allowed(
          line,
          current_line_in_fenced_code,
          markdown_state.fetch("list_content_indent"),
          markdown_state.fetch("list_indented_code_allowed"),
          markdown_state
        )
        markdown_state["root_indented_code_allowed"] = next_root_indented_code_allowed(
          line,
          current_line_in_fenced_code,
          markdown_state.fetch("root_indented_code_allowed"),
          markdown_state
        )
        markdown_state["setext_heading_candidate_active"] = next_setext_heading_candidate_active(
          line,
          current_line_in_fenced_code,
          markdown_state
        )
        markdown_state["gfm_table_block_active"] =
          next_gfm_table_block_active(line, current_line_in_fenced_code, markdown_state)
        markdown_state["gfm_table_header_candidate_cell_count"] =
          next_gfm_table_header_candidate_cell_count(line, current_line_in_fenced_code, markdown_state)
        markdown_state["gfm_table_header_candidate_active"] =
          !markdown_state.fetch("gfm_table_header_candidate_cell_count").nil?
        update_link_reference_title_state(markdown_state, line, current_line_in_fenced_code)
        markdown_state["list_paragraph_continuation_active"] = next_list_paragraph_continuation_active(
          line,
          current_line_in_fenced_code,
          markdown_state
        )
        markdown_state["paragraph_continuation_active"] = next_paragraph_continuation_active(
          line,
          current_line_in_fenced_code,
          markdown_state
        )
        markdown_state["html_block"] = next_html_block(line, markdown_state)
      end
    end
  end
end

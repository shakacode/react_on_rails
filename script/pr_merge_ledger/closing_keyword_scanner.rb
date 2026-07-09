# frozen_string_literal: true

require_relative "closing_keyword_scanner/block_boundaries"
require_relative "closing_keyword_scanner/blockquote_state"
require_relative "closing_keyword_scanner/constants"
require_relative "closing_keyword_scanner/code_blocks"
require_relative "closing_keyword_scanner/fence_blocks"
require_relative "closing_keyword_scanner/html_blocks"
require_relative "closing_keyword_scanner/inline_code"
require_relative "closing_keyword_scanner/inline_code_multiline"
require_relative "closing_keyword_scanner/line_state"
require_relative "closing_keyword_scanner/link_reference_blocks"
require_relative "closing_keyword_scanner/link_reference_parser"
require_relative "closing_keyword_scanner/list_blocks"
require_relative "closing_keyword_scanner/list_paragraphs"

class PrMergeLedger
  module ClosingKeywordScanner
    include BlockBoundaries
    include BlockquoteState
    include CodeBlocks
    include FenceBlocks
    include HtmlBlocks
    include InlineCode
    include InlineCodeMultiline
    include LineState
    include LinkReferenceBlocks
    include LinkReferenceParser
    include ListBlocks
    include ListParagraphs

    private

    def code_formatted_closing_keyword_violations(pull_request)
      return [] unless default_branch_pull_request?(pull_request)
      return [] if pull_request_body_line_too_long_for_closing_keyword_scan?(pull_request)

      body = pull_request.fetch(INTERNAL_PULL_REQUEST_BODY_KEY, "")
      body_lines = body.each_line.first(MAX_BODY_LINES)
      markdown_state = {
        "body_lines" => body_lines,
        "opening_fence" => nil,
        "inline_code_delimiter" => nil,
        "inline_code_failed_lookahead" => nil,
        "inline_code_multiline_content" => nil,
        "inline_code_multiline_reported" => false,
        "code_block_multiline_content" => nil,
        "code_block_multiline_reported" => false,
        "html_block" => nil,
        "html_block_multiline_content" => nil,
        "html_block_multiline_reported" => false,
        "blockquote_depth" => 0,
        "list_content_indent" => nil,
        "list_indented_code_indent" => nil,
        "list_indented_code_allowed" => true,
        "gfm_table_block_active" => false,
        "gfm_table_header_candidate_active" => false,
        "gfm_table_header_candidate_cell_count" => nil,
        "setext_heading_candidate_active" => false,
        "paragraph_continuation_active" => false,
        "list_paragraph_continuation_active" => false,
        "blockquote_lazy_continuation_allowed" => false,
        "link_reference_destination_allowed" => false,
        "link_reference_title_allowed" => false,
        "link_reference_title_delimiter" => nil,
        "link_reference_multiline_content" => nil,
        "link_reference_multiline_reported" => false,
        "root_indented_code_allowed" => true
      }

      body_lines.each_with_index.filter_map do |line, index|
        code_formatted_closing_keyword_violation(pull_request, line, index, markdown_state)
      end
    end

    def pull_request_body_truncated_for_closing_keyword_scan?(pull_request)
      return false unless default_branch_pull_request?(pull_request)

      pull_request.fetch(INTERNAL_PULL_REQUEST_BODY_KEY, "").each_line.count > MAX_BODY_LINES
    end

    def pull_request_body_line_too_long_for_closing_keyword_scan?(pull_request)
      return false unless default_branch_pull_request?(pull_request)

      pull_request.fetch(INTERNAL_PULL_REQUEST_BODY_KEY, "")
                  .each_line
                  .first(MAX_BODY_LINES)
                  .any? { |line| line.bytesize > MAX_BODY_LINE_BYTES }
    end

    def pull_request_body_exceeds_closing_keyword_scan_limit?(pull_request)
      pull_request_body_truncated_for_closing_keyword_scan?(pull_request) ||
        pull_request_body_line_too_long_for_closing_keyword_scan?(pull_request)
    end

    def default_branch_pull_request?(pull_request)
      pull_request["base_ref"] == DEFAULT_BRANCH
    end

    def code_formatted_closing_keyword_violation(pull_request, line, index, markdown_state)
      markdown_line, blockquote_depth = body_markdown_line_and_depth(line, markdown_state)
      close_blockquote_fence_if_needed(markdown_state, blockquote_depth)
      close_outdented_list_fence_if_needed(markdown_state, markdown_line)
      markdown_state["current_blockquote_depth"] = blockquote_depth
      current_line_in_fenced_code = !markdown_state.fetch("opening_fence").nil?
      reset_markdown_state_for_blockquote_change(markdown_state, blockquote_depth) unless current_line_in_fenced_code
      update_body_markdown_state_before_scan(
        markdown_line,
        current_line_in_fenced_code,
        blockquote_depth,
        markdown_state
      )

      code_block_line = code_block_line_for_state?(markdown_line, current_line_in_fenced_code, markdown_state)
      block_match = code_block_closing_keyword_match(
        markdown_line,
        current_line_in_fenced_code,
        code_block_line,
        markdown_state
      )
      inline_match =
        if code_block_line
          reset_inline_code_soft_wrap_state(markdown_state)
          nil
        else
          closing_keyword_in_inline_code(markdown_line, index, markdown_state)
        end
      match_text = inline_match || block_match&.[](0)
      update_body_markdown_state_after_scan(markdown_line, current_line_in_fenced_code, markdown_state)
      markdown_state["blockquote_depth"] = effective_blockquote_depth(markdown_state, blockquote_depth)
      update_blockquote_lazy_continuation_state(markdown_state, markdown_line, current_line_in_fenced_code)

      return unless match_text

      violation(
        pull_request,
        inline_match ? "backticked_closing_keyword" : "code_formatted_closing_keyword",
        "Code-formatted closing keyword does not auto-close linked issue: #{match_text}",
        pull_request["url"],
        "line" => index + 1
      )
    end
  end
end

# frozen_string_literal: true

require_relative "closing_keyword_scanner/block_boundaries"
require_relative "closing_keyword_scanner/blockquote_state"
require_relative "closing_keyword_scanner/code_blocks"
require_relative "closing_keyword_scanner/fence_blocks"
require_relative "closing_keyword_scanner/html_blocks"
require_relative "closing_keyword_scanner/inline_code"
require_relative "closing_keyword_scanner/inline_code_multiline"
require_relative "closing_keyword_scanner/line_state"
require_relative "closing_keyword_scanner/list_blocks"

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
    include ListBlocks

    # Parser constants stay beside the closeout scanner because they model Markdown state, not ledger state.
    CLOSING_KEYWORD_PATTERN = %r{
      \b(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?):?\s+
      (?:
        (?:[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)?\#\d+ |
        https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/(?:issues|pull)/\d+
      )
    }ix
    FENCED_CODE_BLOCK_PATTERN = /\A {0,3}(?<fence>`{3,}|~{3,})/
    INDENTED_CODE_BLOCK_PATTERN = /\A(?: {4}| {0,3}\t)/
    INDENTATION_CHARACTERS = [" ", "\t"].freeze
    LIST_ITEM_PATTERN = /\A(?<indent>[ \t]*)(?:[-+*]|\d{1,9}[.)])[ \t]+/
    EMPTY_LIST_ITEM_PATTERN = /\A(?<indent>[ \t]*)(?<marker>[-+*]|\d{1,9}[.)])[ \t]*(?:\n)?\z/
    LIST_FENCED_CODE_BLOCK_PATTERN = /\A(?<indent>[ \t]*)(?:[-+*]|\d{1,9}[.)])[ \t]+(?<fence>`{3,}|~{3,})/
    LIST_ITEM_WITH_PADDING_PATTERN = /\A(?<indent>[ \t]*)(?<marker>[-+*]|\d{1,9}[.)])(?<padding>[ \t]+)(?<code>.*)/
    LIST_BLOCKQUOTE_MARKER_PATTERN = /\A(?<indent>[ \t]*)(?:[-+*]|\d{1,9}[.)])[ \t]+(?<blockquotes>(?:> ?)+)/
    SAME_LINE_LIST_ITEM_WITH_PADDING_PATTERN =
      /\G(?<indent>[ \t]*)(?<marker>[-+*]|\d{1,9}[.)])(?<padding>[ \t]+)(?<code>.*)/
    SAME_LINE_BLOCKQUOTE_MARKER_PATTERN = /\G(?:> ?)+/
    SAME_LINE_FENCED_CODE_BLOCK_PATTERN = /\G {0,3}(?<fence>`{3,}|~{3,})/
    ORDERED_ROOT_LIST_ITEM_PATTERN = /\A {0,3}(?<start>\d{1,9})[.)][ \t]+/
    ROOT_BLOCK_BOUNDARY_PATTERN = /\A {0,3}(?:\#{1,6}(?:\s|\z)|>|[-+*][ \t]+|\d{1,9}[.)][ \t]+)/
    HTML_BLOCK_TAG_NAMES = %w[
      address article aside base basefont blockquote body caption center col colgroup dd details dialog dir div dl dt
      fieldset figcaption figure footer form frame frameset h1 h2 h3 h4 h5 h6 head header hr html iframe legend li
      link main menu menuitem nav noframes ol optgroup option p param pre script search section style summary table
      tbody
      td textarea tfoot th thead title tr track ul
    ].freeze
    HTML_RAW_TEXT_BLOCK_TAG_NAMES = %w[pre script style textarea].freeze
    HTML_BLOCK_TAG_PATTERN = Regexp.union(HTML_BLOCK_TAG_NAMES)
    HTML_BLOCK_BOUNDARY_PATTERN =
      %r{\A {0,3}(?:<!--|<\?|<![A-Z]|<!\[CDATA\[|</?(?:#{HTML_BLOCK_TAG_PATTERN})(?:[\s>/]|\z))}i
    HTML_COMMENT_OPEN_PATTERN = /\A {0,3}<!--/
    HTML_CDATA_OPEN_PATTERN = /\A {0,3}<!\[CDATA\[/
    HTML_DECLARATION_OPEN_PATTERN = /\A {0,3}<![A-Z]/
    HTML_PROCESSING_INSTRUCTION_OPEN_PATTERN = /\A {0,3}<\?/
    HTML_BLOCK_TAG_OPEN_PATTERN = %r{\A {0,3}<(?<tag>#{HTML_BLOCK_TAG_PATTERN})(?:[\s>/]|\z)}i
    HTML_TYPE_7_BLOCK_OPEN_PATTERN =
      %r{\A {0,3}</?[A-Za-z][A-Za-z0-9-]*(?:[ \t]+(?:[^<>"'\n]|"[^"\n]*"|'[^'\n]*')*)?>[ \t]*(?:\n)?\z}
    THEMATIC_BOUNDARY_PATTERN = /\A {0,3}(?:(?:-[ \t]*){3,}|(?:_[ \t]*){3,}|(?:\*[ \t]*){3,})\z/
    SETEXT_BOUNDARY_PATTERN = /\A {0,3}(?:=+|-+)[ \t]*\z/
    LINK_REFERENCE_DEFINITION_BOUNDARY_PATTERN = /\A {0,3}\[[^\]\n]+\]:[ \t]*\S/
    TABLE_SEPARATOR_CELL_PATTERN = /\A:?-+:?\z/

    # These lightweight structs mimic the MatchData subset used by scanner helpers.
    ListMarkerIndentedCodeMatch = Struct.new(:code, :code_begin) do
      def [](key)
        return code if key == :code

        nil
      end

      def begin(key)
        return code_begin if key == :code

        nil
      end
    end
    FencedCodeBlockMatch = Struct.new(:fence, :fence_begin, :fence_end, :container_indent) do
      def [](key)
        return fence if key == :fence

        nil
      end

      def begin(key = 0)
        return fence_begin if [0, :fence].include?(key)

        nil
      end

      def end(key = 0)
        return fence_end if [0, :fence].include?(key)

        nil
      end
    end
    ListBlockquoteMarkerMatch = Struct.new(:match_end, :blockquote_depth) do
      def end(key = 0)
        return match_end if key.eql?(0)

        nil
      end
    end

    private

    def code_formatted_closing_keyword_violations(pull_request)
      return [] unless default_branch_pull_request?(pull_request)

      body = pull_request.fetch(INTERNAL_PULL_REQUEST_BODY_KEY, "")
      body_lines = body.each_line.first(MAX_BODY_LINES)
      markdown_state = {
        "body_lines" => body_lines,
        "opening_fence" => nil,
        "inline_code_delimiter" => nil,
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
        "blockquote_lazy_continuation_allowed" => false,
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

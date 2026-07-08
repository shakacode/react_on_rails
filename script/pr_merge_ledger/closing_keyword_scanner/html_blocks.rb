# frozen_string_literal: true

class PrMergeLedger
  module ClosingKeywordScanner
    module HtmlBlocks
      private

      def next_html_block(line, markdown_state)
        active_block = markdown_state.fetch("html_block")
        if active_block
          return nil if html_block_closes_on_line?(line, active_block)

          return active_block
        end

        block = html_block_context_for_line(line, markdown_state)
        return nil unless block
        return nil if html_block_closes_on_line?(line, block)

        block
      end

      def html_block_context_for_line(line, markdown_state = nil)
        return { "type" => "comment" } if line.match?(HTML_COMMENT_OPEN_PATTERN)
        return { "type" => "cdata" } if line.match?(HTML_CDATA_OPEN_PATTERN)
        return { "type" => "declaration" } if line.match?(HTML_DECLARATION_OPEN_PATTERN)
        return { "type" => "processing_instruction" } if line.match?(HTML_PROCESSING_INSTRUCTION_OPEN_PATTERN)

        tag_match = line.match(HTML_BLOCK_TAG_OPEN_PATTERN)
        if tag_match
          tag_name = tag_match[:tag].downcase
          tag_type = HTML_RAW_TEXT_BLOCK_TAG_NAMES.include?(tag_name) ? "raw_tag" : "tag"
          return { "type" => tag_type, "tag" => tag_name }
        end

        return { "type" => "type7_tag" } if line.match?(HTML_TYPE_7_BLOCK_OPEN_PATTERN)

        list_item_html_block_context_for_line(line, markdown_state)
      end

      def list_item_html_block_context_for_line(line, markdown_state)
        return unless markdown_state

        list_match = line.match(LIST_ITEM_WITH_PADDING_PATTERN)
        return unless list_match

        marker_indent = column_after_prefix(list_match[:indent].each_char)
        content_column = column_after_prefix(line[...list_match.begin(:code)].each_char)
        return unless list_marker_indent_allowed_for_line?(
          marker_indent,
          markdown_state.fetch("list_content_indent"),
          content_column
        )

        html_block_context_for_line(list_match[:code])
      end

      def html_block_closes_on_line?(line, html_block)
        case html_block.fetch("type")
        when "comment"
          line.include?("-->")
        when "cdata"
          line.include?("]]>")
        when "declaration"
          line.include?(">")
        when "processing_instruction"
          line.include?("?>")
        when "raw_tag"
          line.match?(%r{</#{Regexp.escape(html_block.fetch('tag'))}\s*>}i)
        when "tag", "type7_tag"
          line.strip.empty?
        else
          false
        end
      end

      def html_block_line?(line, markdown_state)
        markdown_state.fetch("html_block") || html_block_context_for_line(line, markdown_state)
      end
    end
  end
end

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

        return { "type" => "type7_tag" } if html_type_7_block_open_line?(line)

        list_item_html_block_context_for_line(line, markdown_state)
      end

      def html_type_7_block_open_line?(line)
        markdown_line = line.chomp
        index = html_type_7_start_index(markdown_line)
        return false unless index

        index += 1
        closing_tag = markdown_line[index] == "/"
        index += 1 if closing_tag
        return false unless ascii_letter?(markdown_line[index])

        index += 1
        index += 1 while html_tag_name_character?(markdown_line[index])
        return closing_html_type_7_tag_close?(markdown_line, index) if closing_tag

        html_type_7_attributes_close?(markdown_line, index)
      end

      def html_type_7_start_index(markdown_line)
        index = 0
        index += 1 while markdown_line[index] == " "
        return nil if index > 3
        return nil unless markdown_line[index] == "<"

        index
      end

      def closing_html_type_7_tag_close?(markdown_line, index)
        markdown_line[index] == ">" && trailing_html_tag_close?(markdown_line, index)
      end

      def html_type_7_attributes_close?(markdown_line, index)
        loop do
          index += 1 while html_attribute_space?(markdown_line[index])
          return trailing_html_tag_close?(markdown_line, index) if markdown_line[index] == ">"
          return false unless html_type_7_attribute_content?(markdown_line[index])

          index = next_html_type_7_attribute_index(markdown_line, index)
          return false unless index
        end
      end

      def next_html_type_7_attribute_index(markdown_line, index)
        while index < markdown_line.length
          character = markdown_line[index]
          return index if html_attribute_delimiter?(character)
          return nil if html_attribute_invalid?(character)

          index = if html_attribute_quote?(character)
                    next_quoted_html_attribute_index(markdown_line, index, character)
                  else
                    index + 1
                  end
          return nil unless index
        end

        index
      end

      def next_quoted_html_attribute_index(markdown_line, index, quote)
        closing_index = markdown_line.index(quote, index + 1)
        closing_index && (closing_index + 1)
      end

      def trailing_html_tag_close?(markdown_line, index)
        markdown_line[(index + 1)..].to_s.match?(/\A[ \t]*\z/)
      end

      def html_type_7_attribute_content?(character)
        character && !html_attribute_delimiter?(character) && !html_attribute_invalid?(character)
      end

      def html_attribute_space?(character)
        HTML_ATTRIBUTE_SPACES.include?(character)
      end

      def html_attribute_delimiter?(character)
        html_attribute_space?(character) || character == ">"
      end

      def html_attribute_invalid?(character)
        HTML_ATTRIBUTE_INVALID_CHARACTERS.include?(character)
      end

      def html_attribute_quote?(character)
        HTML_ATTRIBUTE_QUOTES.include?(character)
      end

      def ascii_letter?(character)
        character&.match?(/[A-Za-z]/)
      end

      def html_tag_name_character?(character)
        character&.match?(/[A-Za-z0-9-]/)
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

        html_block_context_for_line(list_match[:code], markdown_state)
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

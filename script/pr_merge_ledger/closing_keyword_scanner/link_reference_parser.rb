# frozen_string_literal: true

class PrMergeLedger
  module ClosingKeywordScanner
    module LinkReferenceParser
      private

      def link_reference_content_line(line, markdown_state)
        list_item_link_reference_content_line(line, markdown_state) || line
      end

      def list_item_link_reference_content_line(line, markdown_state)
        return unless markdown_state

        content_indent = markdown_state.fetch("list_content_indent")
        content_line = line

        loop do
          list_match = content_line.match(LIST_ITEM_WITH_PADDING_PATTERN)
          return unless list_match

          marker_indent = column_after_prefix(list_match[:indent].each_char)
          content_column = column_after_prefix(content_line[...list_match.begin(:code)])
          return unless list_marker_indent_allowed_for_line?(marker_indent, content_indent, content_column)

          content_line = list_match[:code]
          return content_line if link_reference_definition_line?(content_line, markdown_state)

          content_indent = content_column
        end
      end

      def link_reference_definition_parts(line)
        match = line.match(LINK_REFERENCE_DEFINITION_PATTERN)
        return unless match

        link_reference_destination_parts(match[:tail])
      end

      def link_reference_destination_parts(line)
        stripped = line.to_s.sub(/\A {0,3}/, "").strip
        return { destination: nil, title: nil, complete_title: false } if stripped.empty?

        destination_and_title = link_reference_destination_and_title(stripped)
        return unless destination_and_title

        destination, title = destination_and_title
        return { destination:, title: nil, complete_title: false } if title.nil?

        title_parts = link_reference_title_parts_from_text(title)
        return unless title_parts

        {
          destination:,
          title:,
          complete_title: title_parts.fetch(:complete)
        }
      end

      def link_reference_destination_and_title(stripped)
        return stripped.split(/[ \t]+/, 2) unless stripped.start_with?("<")

        destination_end = stripped.index(">")
        return unless destination_end

        destination_text = stripped[1...destination_end]
        return if line_has_unescaped_delimiter?(destination_text, "<")

        destination = stripped[..destination_end]
        title = stripped[(destination_end + 1)..].to_s.strip
        [destination, title.empty? ? nil : title]
      end

      def link_reference_destination_complete_title?(line)
        link_reference_destination_parts(line)&.fetch(:complete_title)
      end

      def link_reference_title_parts(line)
        link_reference_title_parts_from_text(line.to_s.sub(/\A {0,3}/, ""))
      end

      def link_reference_title_parts_from_text(text)
        stripped_title = text.to_s.strip
        closing_delimiter = LINK_REFERENCE_TITLE_DELIMITERS[stripped_title[0]]
        return unless closing_delimiter

        closing_index = unescaped_delimiter_index(stripped_title[1..].to_s, closing_delimiter)
        return { delimiter: closing_delimiter, complete: false } if closing_index.nil?
        return unless stripped_title[(closing_index + 2)..].to_s.strip.empty?

        { delimiter: closing_delimiter, complete: true }
      end

      def line_has_unescaped_delimiter?(line, delimiter)
        !unescaped_delimiter_index(line, delimiter).nil?
      end

      def unescaped_delimiter_index(text, delimiter)
        search_start = 0
        loop do
          delimiter_index = text.index(delimiter, search_start)
          return unless delimiter_index
          return delimiter_index if even_backslash_run_before?(text, delimiter_index)

          search_start = delimiter_index + delimiter.length
        end
      end

      def even_backslash_run_before?(text, index)
        backslash_count = 0
        cursor = index - 1
        while cursor >= 0 && text[cursor] == "\\"
          backslash_count += 1
          cursor -= 1
        end

        backslash_count.even?
      end
    end
  end
end

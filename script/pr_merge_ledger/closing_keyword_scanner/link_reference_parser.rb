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
        return raw_link_reference_destination_and_title(stripped) unless stripped.start_with?("<")

        destination_end = unescaped_delimiter_index(stripped[1..].to_s, ">")
        return unless destination_end

        destination_end += 1
        destination_text = stripped[1...destination_end]
        return if line_has_unescaped_delimiter?(destination_text, "<")

        destination = stripped[..destination_end]
        title = stripped[(destination_end + 1)..].to_s.strip
        [destination, title.empty? ? nil : title]
      end

      def raw_link_reference_destination_and_title(stripped)
        destination, title = stripped.split(/[ \t]+/, 2)
        return unless raw_link_reference_destination?(destination)

        [destination, title]
      end

      def raw_link_reference_destination?(destination)
        parenthesis_depth = 0
        backslash_run_length = 0
        destination.to_s.each_char do |character|
          unescaped_character = backslash_run_length.even?

          if unescaped_character
            parenthesis_depth = next_raw_link_reference_parenthesis_depth(character, parenthesis_depth)
            return false if parenthesis_depth.nil?
          end

          backslash_run_length = character == "\\" ? backslash_run_length + 1 : 0
        end

        parenthesis_depth.zero?
      end

      def next_raw_link_reference_parenthesis_depth(character, parenthesis_depth)
        case character
        when "("
          parenthesis_depth + 1
        when ")"
          parenthesis_depth.positive? ? parenthesis_depth - 1 : nil
        when "<", ">"
          nil
        else
          parenthesis_depth
        end
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
        backslash_run_length = 0
        text.each_char.with_index do |character, index|
          return index if character == delimiter && backslash_run_length.even?

          backslash_run_length = character == "\\" ? backslash_run_length + 1 : 0
        end

        nil
      end
    end
  end
end

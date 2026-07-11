# frozen_string_literal: true

class PrMergeLedger
  module ClosingKeywordScanner
    module LinkReferenceParser
      private

      def link_reference_content_line(line, markdown_state)
        list_item_link_reference_content_line(line, markdown_state) ||
          list_indented_link_reference_content_line(line, markdown_state) ||
          line
      end

      def list_item_link_reference_content_line(line, markdown_state)
        return unless markdown_state

        content_indent = markdown_state.fetch("list_content_indent")
        content_line = line
        stripped_list_marker = false

        loop do
          list_match = content_line.match(LIST_ITEM_WITH_PADDING_PATTERN)
          return stripped_list_marker ? content_line : nil unless list_match

          marker_indent = column_after_prefix(list_match[:indent].each_char)
          content_column = column_after_prefix(content_line[...list_match.begin(:code)])
          return stripped_list_marker ? content_line : nil if list_item_marker_continues_active_paragraph?(
            content_line,
            markdown_state
          )
          return unless list_marker_indent_allowed_for_line?(marker_indent, content_indent, content_column)

          content_line = list_match[:code]
          stripped_list_marker = true
          return content_line if link_reference_definition_line?(content_line, markdown_state)

          content_indent = content_column
        end
      end

      def list_indented_link_reference_content_line(line, markdown_state)
        return unless markdown_state

        content_indent = markdown_state.fetch("list_content_indent")
        return unless content_indent
        return unless leading_indentation_columns(line) >= content_indent

        line_without_indentation_columns(line, content_indent)
      end

      def line_without_indentation_columns(line, columns)
        column = 0

        line.each_char.with_index do |character, index|
          break unless INDENTATION_CHARACTERS.include?(character)

          next_column = character == "\t" ? column + (4 - (column % 4)) : column + 1
          return "#{' ' * (next_column - columns)}#{line[(index + 1)..]}" if next_column > columns
          return line[(index + 1)..] if next_column == columns

          column = next_column
        end

        line
      end

      def link_reference_definition_parts(line)
        match = line.match(LINK_REFERENCE_DEFINITION_PATTERN)
        return unless match
        return unless valid_link_reference_label?(match[:label])

        link_reference_destination_parts(match[:tail])
      end

      def link_reference_definition_label_only_line?(line)
        match = line.to_s.match(LINK_REFERENCE_DEFINITION_LABEL_ONLY_PATTERN)
        match && valid_link_reference_label?(match[:label])
      end

      def valid_link_reference_label?(label)
        label && label.length <= MAX_LINK_REFERENCE_LABEL_CHARACTERS && label.match?(/\S/)
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

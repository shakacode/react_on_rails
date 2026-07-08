# frozen_string_literal: true

class PrMergeLedger
  module ClosingKeywordScanner
    module LinkReferenceBlocks
      private

      def closing_keyword_in_link_reference(line, markdown_state)
        return unless link_reference_hidden_line?(line, markdown_state)

        line.match(CLOSING_KEYWORD_PATTERN)
      end

      def link_reference_hidden_line?(line, markdown_state)
        markdown_state.fetch("link_reference_title_delimiter") ||
          link_reference_definition_boundary_line?(line, markdown_state) ||
          link_reference_destination_line?(line, markdown_state) ||
          link_reference_title_line?(line, markdown_state)
      end

      def link_reference_definition_boundary_line?(line, markdown_state)
        return false if link_reference_definition_interrupts_paragraph?(markdown_state)

        link_reference_definition_line?(line, markdown_state)
      end

      def next_link_reference_title_allowed(line, current_line_in_fenced_code, markdown_state)
        return false if current_line_in_fenced_code || markdown_state.fetch("opening_fence")
        return false if markdown_state.fetch("link_reference_title_delimiter")
        return false if next_link_reference_title_delimiter(line, current_line_in_fenced_code, markdown_state)

        if link_reference_definition_boundary_line?(line, markdown_state)
          return link_reference_definition_with_destination_line?(line) &&
                 !line.match?(LINK_REFERENCE_DEFINITION_WITH_TITLE_PATTERN)
        end

        link_reference_destination_line?(line, markdown_state) &&
          !line.match?(LINK_REFERENCE_DESTINATION_WITH_TITLE_PATTERN)
      end

      def update_link_reference_title_state(markdown_state, line, current_line_in_fenced_code)
        next_title_delimiter = next_link_reference_title_delimiter(
          line,
          current_line_in_fenced_code,
          markdown_state
        )
        next_destination_allowed = next_link_reference_destination_allowed(
          line,
          current_line_in_fenced_code,
          markdown_state
        )
        next_title_allowed = next_link_reference_title_allowed(
          line,
          current_line_in_fenced_code,
          markdown_state
        )

        markdown_state["link_reference_destination_allowed"] = next_destination_allowed
        markdown_state["link_reference_title_allowed"] = next_title_allowed
        markdown_state["link_reference_title_delimiter"] = next_title_delimiter
      end

      def next_link_reference_destination_allowed(line, current_line_in_fenced_code, markdown_state)
        return false if current_line_in_fenced_code || markdown_state.fetch("opening_fence")

        link_reference_definition_boundary_line?(line, markdown_state) &&
          line.match?(LINK_REFERENCE_DEFINITION_LABEL_ONLY_PATTERN)
      end

      def next_link_reference_title_delimiter(line, current_line_in_fenced_code, markdown_state)
        active_delimiter = markdown_state.fetch("link_reference_title_delimiter")
        return line.include?(active_delimiter) ? nil : active_delimiter if active_delimiter
        return nil if current_line_in_fenced_code || markdown_state.fetch("opening_fence")

        if link_reference_definition_boundary_line?(line, markdown_state)
          return unclosed_link_reference_title_delimiter(link_reference_definition_title_text(line))
        end

        if link_reference_destination_line?(line, markdown_state)
          return unclosed_link_reference_title_delimiter(link_reference_destination_title_text(line))
        end

        return unless markdown_state.fetch("link_reference_title_allowed")

        unclosed_link_reference_title_delimiter(line)
      end

      def link_reference_definition_line?(line, _markdown_state = nil)
        line.match?(LINK_REFERENCE_DEFINITION_BOUNDARY_PATTERN)
      end

      def link_reference_definition_with_destination_line?(line)
        line.match?(LINK_REFERENCE_DEFINITION_WITH_DESTINATION_PATTERN)
      end

      def link_reference_definition_interrupts_paragraph?(markdown_state)
        markdown_state&.fetch("paragraph_continuation_active", false) ||
          markdown_state&.fetch("list_paragraph_continuation_active", false)
      end

      def link_reference_destination_line?(line, markdown_state)
        markdown_state.fetch("link_reference_destination_allowed") &&
          line.match?(LINK_REFERENCE_DESTINATION_LINE_PATTERN)
      end

      def link_reference_title_line?(line, markdown_state)
        markdown_state.fetch("link_reference_title_allowed") &&
          line.match?(LINK_REFERENCE_TITLE_PATTERN)
      end

      def link_reference_definition_title_text(line)
        line.sub(/\A {0,3}\[[^\]\n]+\]:[ \t]*/, "")
      end

      def link_reference_destination_title_text(line)
        line.sub(/\A {0,3}/, "")
      end

      def unclosed_link_reference_title_delimiter(text)
        title_text = link_reference_title_text_after_destination(text)
        title_text ||= text
        stripped_title = title_text.to_s.strip
        closing_delimiter = LINK_REFERENCE_TITLE_DELIMITERS[stripped_title[0]]
        return unless closing_delimiter

        stripped_title[1..].to_s.include?(closing_delimiter) ? nil : closing_delimiter
      end

      def link_reference_title_text_after_destination(text)
        _destination, title_text = text.to_s.strip.split(/[ \t]+/, 2)
        title_text
      end
    end
  end
end

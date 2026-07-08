# frozen_string_literal: true

class PrMergeLedger
  module ClosingKeywordScanner
    module LinkReferenceBlocks
      private

      def closing_keyword_in_link_reference(line, markdown_state)
        return line.match(CLOSING_KEYWORD_PATTERN) if link_reference_definition_line?(line)
        return unless markdown_state.fetch("link_reference_title_allowed")
        return unless line.match?(LINK_REFERENCE_TITLE_PATTERN)

        line.match(CLOSING_KEYWORD_PATTERN)
      end

      def next_link_reference_title_allowed(line, current_line_in_fenced_code, markdown_state)
        return false if current_line_in_fenced_code || markdown_state.fetch("opening_fence")
        return false unless link_reference_definition_line?(line)

        !line.match?(LINK_REFERENCE_DEFINITION_WITH_TITLE_PATTERN)
      end

      def update_link_reference_title_state(markdown_state, line, current_line_in_fenced_code)
        markdown_state["link_reference_title_allowed"] = next_link_reference_title_allowed(
          line,
          current_line_in_fenced_code,
          markdown_state
        )
      end

      def link_reference_definition_line?(line)
        line.match?(LINK_REFERENCE_DEFINITION_BOUNDARY_PATTERN)
      end
    end
  end
end

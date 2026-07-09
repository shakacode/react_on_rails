# frozen_string_literal: true

class PrMergeLedger
  module ClosingKeywordScanner
    module LinkReferenceBlocks
      private

      def closing_keyword_in_link_reference(line, markdown_state)
        link_reference_line = link_reference_content_line(line, markdown_state)
        unless link_reference_hidden_line?(link_reference_line, markdown_state, source_line: line)
          reset_multiline_link_reference_state(markdown_state)
          return
        end

        if new_link_reference_hidden_block?(link_reference_line, markdown_state, source_line: line)
          reset_multiline_link_reference_state(markdown_state)
        end

        link_reference_line.match(CLOSING_KEYWORD_PATTERN) ||
          closing_keyword_in_multiline_link_reference(link_reference_line, markdown_state)
      end

      def new_link_reference_hidden_block?(line, markdown_state, source_line: line)
        markdown_state.fetch("link_reference_title_delimiter").nil? &&
          link_reference_definition_boundary_line?(line, markdown_state, source_line:)
      end

      def closing_keyword_in_multiline_link_reference(line, markdown_state)
        return if markdown_state.fetch("link_reference_multiline_reported")

        content, previous_length = append_multiline_scan_content(
          markdown_state,
          "link_reference_multiline_content",
          line,
          separator: "\n"
        )

        match = closing_keyword_in_updated_multiline_content(content, previous_length)
        return unless match

        markdown_state["link_reference_multiline_reported"] = true
        match
      end

      def reset_multiline_link_reference_state(markdown_state)
        markdown_state["link_reference_multiline_content"] = nil
        markdown_state["link_reference_multiline_reported"] = false
      end

      def link_reference_hidden_line?(line, markdown_state, source_line: line)
        active_title_delimiter = markdown_state.fetch("link_reference_title_delimiter")
        if active_title_delimiter
          return active_link_reference_title_hidden_line?(
            line,
            active_title_delimiter,
            markdown_state,
            source_line:
          )
        end

        link_reference_definition_boundary_line?(line, markdown_state, source_line:) ||
          link_reference_destination_line?(line, markdown_state) ||
          link_reference_title_line?(line, markdown_state)
      end

      def active_link_reference_title_hidden_line?(line, delimiter, markdown_state, source_line:)
        if active_link_reference_title_boundary_line?(source_line, markdown_state)
          markdown_state["link_reference_title_delimiter"] = nil
          return false
        end

        closing_index = unescaped_delimiter_index(line, delimiter)
        unless closing_index
          closes_later = active_link_reference_title_closes_later?(delimiter, markdown_state)
          markdown_state["link_reference_title_delimiter"] = nil unless closes_later
          return closes_later
        end

        line[(closing_index + delimiter.length)..].to_s.strip.empty?
      end

      def link_reference_definition_boundary_line?(line, markdown_state, source_line: line)
        list_item_content_line = list_item_link_reference_content_line(source_line, markdown_state)
        return link_reference_definition_line?(list_item_content_line, markdown_state) if list_item_content_line

        return false if link_reference_definition_interrupts_paragraph?(markdown_state)

        content_line = list_indented_link_reference_content_line(source_line, markdown_state) || line
        link_reference_definition_line?(content_line, markdown_state)
      end

      def next_link_reference_title_allowed(line, current_line_in_fenced_code, markdown_state)
        link_reference_line = link_reference_content_line(line, markdown_state)
        return false if current_line_in_fenced_code || markdown_state.fetch("opening_fence")
        return false if markdown_state.fetch("link_reference_title_delimiter")
        return false if next_link_reference_title_delimiter(
          link_reference_line,
          current_line_in_fenced_code,
          markdown_state
        )

        if link_reference_definition_boundary_line?(link_reference_line, markdown_state, source_line: line)
          return link_reference_definition_with_destination_line?(link_reference_line) &&
                 !link_reference_definition_complete_title?(link_reference_line)
        end

        link_reference_destination_line?(link_reference_line, markdown_state) &&
          !link_reference_destination_complete_title?(link_reference_line)
      end

      def update_link_reference_title_state(markdown_state, line, current_line_in_fenced_code)
        previous_title_delimiter = markdown_state.fetch("link_reference_title_delimiter")
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
        markdown_state["link_reference_title_lookahead"] = nil if previous_title_delimiter != next_title_delimiter
      end

      def next_link_reference_destination_allowed(line, current_line_in_fenced_code, markdown_state)
        link_reference_line = link_reference_content_line(line, markdown_state)
        return false if current_line_in_fenced_code || markdown_state.fetch("opening_fence")

        link_reference_definition_boundary_line?(link_reference_line, markdown_state, source_line: line) &&
          link_reference_definition_label_only_line?(link_reference_line)
      end

      def next_link_reference_title_delimiter(line, current_line_in_fenced_code, markdown_state)
        link_reference_line = link_reference_content_line(line, markdown_state)
        active_delimiter = markdown_state.fetch("link_reference_title_delimiter")
        return next_active_link_reference_title_delimiter(link_reference_line, active_delimiter) if active_delimiter
        return nil if current_line_in_fenced_code || markdown_state.fetch("opening_fence")

        if link_reference_definition_boundary_line?(link_reference_line, markdown_state, source_line: line)
          return unclosed_link_reference_title_delimiter(link_reference_definition_title_text(link_reference_line))
        end

        if link_reference_destination_line?(link_reference_line, markdown_state)
          return unclosed_link_reference_title_delimiter(link_reference_destination_title_text(link_reference_line))
        end

        return unless markdown_state.fetch("link_reference_title_allowed")

        unclosed_link_reference_title_delimiter(link_reference_line)
      end

      def next_active_link_reference_title_delimiter(link_reference_line, active_delimiter)
        return nil if link_reference_line.strip.empty?

        line_has_unescaped_delimiter?(link_reference_line, active_delimiter) ? nil : active_delimiter
      end

      def link_reference_definition_line?(line, _markdown_state = nil)
        !link_reference_definition_parts(line).nil?
      end

      def link_reference_definition_with_destination_line?(line)
        parts = link_reference_definition_parts(line)
        parts && !parts.fetch(:destination).nil?
      end

      def link_reference_definition_complete_title?(line)
        link_reference_definition_parts(line)&.fetch(:complete_title)
      end

      def link_reference_definition_interrupts_paragraph?(markdown_state)
        markdown_state&.fetch("paragraph_continuation_active", false) ||
          markdown_state&.fetch("list_paragraph_continuation_active", false)
      end

      def link_reference_destination_line?(line, markdown_state)
        markdown_state.fetch("link_reference_destination_allowed") &&
          line.match?(LINK_REFERENCE_DESTINATION_LINE_PATTERN) &&
          !link_reference_destination_parts(line).nil?
      end

      def link_reference_title_line?(line, markdown_state)
        markdown_state.fetch("link_reference_title_allowed") &&
          !link_reference_title_parts(line).nil?
      end

      def link_reference_definition_title_text(line)
        link_reference_definition_parts(line)&.fetch(:title)
      end

      def link_reference_destination_title_text(line)
        link_reference_destination_parts(line)&.fetch(:title)
      end

      def unclosed_link_reference_title_delimiter(text)
        title_parts = link_reference_title_parts_from_text(text)
        return unless title_parts && !title_parts.fetch(:complete)

        title_parts.fetch(:delimiter)
      end
    end
  end
end

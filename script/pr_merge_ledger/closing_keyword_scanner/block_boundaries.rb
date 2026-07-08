# frozen_string_literal: true

class PrMergeLedger
  module ClosingKeywordScanner
    module BlockBoundaries
      private

      def next_gfm_table_block_active(line, current_line_in_fenced_code, markdown_state)
        return false if current_line_in_fenced_code || markdown_state.fetch("opening_fence")

        return true if gfm_table_separator_matches_header_candidate?(line, markdown_state)
        return true if gfm_table_body_row_line?(line, markdown_state)

        false
      end

      def next_gfm_table_header_candidate_cell_count(line, current_line_in_fenced_code, markdown_state)
        return nil if current_line_in_fenced_code || markdown_state.fetch("opening_fence")

        boundary_line = line.chomp
        return nil if boundary_line.match?(INDENTED_CODE_BLOCK_PATTERN)
        return nil unless gfm_table_separator_cell_count(boundary_line).nil?
        return nil unless gfm_table_row_boundary_line?(boundary_line)

        gfm_table_cell_count(boundary_line)
      end

      def next_setext_heading_candidate_active(line, current_line_in_fenced_code, markdown_state)
        return false if current_line_in_fenced_code || markdown_state.fetch("opening_fence")
        return false if line.strip.empty?
        return false if line.match?(INDENTED_CODE_BLOCK_PATTERN)
        return false if root_block_boundary_line?(line, markdown_state)

        true
      end

      def root_block_boundary_line?(line, markdown_state = nil)
        boundary_line = line.chomp
        return false if ordered_list_marker_continues_paragraph?(boundary_line, markdown_state)

        static_root_block_boundary_line?(boundary_line) ||
          (markdown_state&.fetch("setext_heading_candidate_active", false) &&
            boundary_line.match?(SETEXT_BOUNDARY_PATTERN)) ||
          gfm_table_separator_matches_header_candidate?(line, markdown_state) ||
          gfm_table_body_row_line?(line, markdown_state)
      end

      def ordered_list_marker_continues_paragraph?(boundary_line, markdown_state)
        return false unless markdown_state&.fetch("paragraph_continuation_active", false)

        match = boundary_line.match(ORDERED_ROOT_LIST_MARKER_OR_EMPTY_PATTERN)
        match && match[:start] != "1"
      end

      def next_paragraph_continuation_active(line, current_line_in_fenced_code, markdown_state)
        return false if paragraph_continuation_blocked_line?(line, current_line_in_fenced_code, markdown_state)

        boundary_line = line.chomp
        return true if ordered_list_marker_continues_paragraph?(boundary_line, markdown_state)

        !root_block_boundary_line?(line, markdown_state)
      end

      def paragraph_continuation_blocked_line?(line, current_line_in_fenced_code, markdown_state)
        current_line_in_fenced_code ||
          markdown_state.fetch("opening_fence") ||
          line.strip.empty? ||
          html_block_line?(line, markdown_state) ||
          (line.match?(INDENTED_CODE_BLOCK_PATTERN) && markdown_state.fetch("root_indented_code_allowed"))
      end

      def static_root_block_boundary_line?(boundary_line)
        boundary_line.match?(ROOT_BLOCK_BOUNDARY_PATTERN) ||
          boundary_line.match?(HTML_BLOCK_BOUNDARY_PATTERN) ||
          html_type_7_block_open_line?(boundary_line) ||
          boundary_line.match?(THEMATIC_BOUNDARY_PATTERN) ||
          boundary_line.match?(LINK_REFERENCE_DEFINITION_BOUNDARY_PATTERN)
      end

      def gfm_table_separator_matches_header_candidate?(line, markdown_state)
        return false unless markdown_state&.fetch("gfm_table_header_candidate_active", false)

        header_cell_count = markdown_state.fetch("gfm_table_header_candidate_cell_count")
        separator_cell_count = gfm_table_separator_cell_count(line)
        !separator_cell_count.nil? && separator_cell_count == header_cell_count
      end

      def gfm_table_separator_cell_count(line)
        boundary_line = line.chomp
        cells = gfm_table_cells(boundary_line)
        return nil if cells.empty?
        return nil unless cells.all? { |cell| cell.strip.match?(TABLE_SEPARATOR_CELL_PATTERN) }

        cells.length
      end

      def gfm_table_cell_count(line)
        gfm_table_cells(line).length
      end

      def gfm_table_cells(line)
        row = line.sub(/\A {0,3}/, "")
        cells = split_gfm_table_row(row)
        cells.shift if row.start_with?("|")
        cells.pop if row.end_with?("|") && !escaped_character?(row, row.length - 1)
        cells
      end

      def split_gfm_table_row(row)
        cells = []
        cell = +""
        backslash_run_length = 0

        row.each_char do |character|
          if character == "|" && backslash_run_length.even?
            cells << cell
            cell = +""
          else
            cell << character
          end

          backslash_run_length = character == "\\" ? backslash_run_length + 1 : 0
        end

        cells << cell
      end

      def gfm_table_row_boundary_line?(line)
        row = line.sub(/\A {0,3}/, "")
        backslash_run_length = 0

        row.each_char.any? do |character|
          unescaped_pipe = character == "|" && backslash_run_length.even?
          backslash_run_length = character == "\\" ? backslash_run_length + 1 : 0
          unescaped_pipe
        end
      end

      def gfm_table_body_row_line?(line, markdown_state)
        return false unless markdown_state&.fetch("gfm_table_block_active", false)

        boundary_line = line.chomp
        return false if boundary_line.strip.empty?
        return false if boundary_line.match?(INDENTED_CODE_BLOCK_PATTERN)
        return true if gfm_table_row_boundary_line?(boundary_line)

        gfm_table_plain_body_row_line?(boundary_line)
      end

      def gfm_table_plain_body_row_line?(line)
        return false if line.match?(ROOT_BLOCK_BOUNDARY_PATTERN)
        return false if line.match?(THEMATIC_BOUNDARY_PATTERN)
        return false if line.match?(SETEXT_BOUNDARY_PATTERN)

        true
      end
    end
  end
end

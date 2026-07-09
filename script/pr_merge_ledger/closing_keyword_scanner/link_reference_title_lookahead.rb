# frozen_string_literal: true

class PrMergeLedger
  module ClosingKeywordScanner
    module LinkReferenceTitleLookahead
      private

      def active_link_reference_title_closes_later?(delimiter, markdown_state)
        body_lines = markdown_state.fetch("body_lines")
        line_index = markdown_state.fetch("line_index")
        table_header_candidate_cell_count = nil
        body_lines[(line_index + 1)..].to_a.each do |line|
          link_reference_line = active_link_reference_title_lookahead_line(line, markdown_state)
          return false if link_reference_line.strip.empty?
          return false if active_link_reference_title_boundary_line?(link_reference_line, markdown_state)
          if active_link_reference_title_table_separator_line?(
            link_reference_line,
            table_header_candidate_cell_count
          )
            return false
          end

          closing_index = unescaped_delimiter_index(link_reference_line, delimiter)
          return link_reference_line[(closing_index + delimiter.length)..].to_s.strip.empty? if closing_index

          table_header_candidate_cell_count = active_link_reference_title_table_cell_count(link_reference_line)
        end

        false
      end

      def active_link_reference_title_lookahead_line(line, markdown_state)
        lookahead_state = markdown_state.dup
        lookahead_state["current_markdown_start_column"] = 0
        markdown_line, blockquote_depth = body_markdown_line_and_depth(line, lookahead_state)
        current_blockquote_depth = markdown_state.fetch(
          "current_blockquote_depth",
          markdown_state.fetch("blockquote_depth")
        )
        return "" if blockquote_depth < current_blockquote_depth

        link_reference_content_line(markdown_line, lookahead_state)
      end

      def active_link_reference_title_boundary_line?(line, markdown_state)
        boundary_line = line.chomp
        return false if boundary_line.strip.empty?
        return true if boundary_line.match?(FENCED_CODE_BLOCK_PATTERN)

        static_root_block_boundary_line?(boundary_line) ||
          link_reference_definition_boundary_line?(boundary_line, markdown_state)
      end

      def active_link_reference_title_table_separator_line?(line, header_cell_count)
        return false unless header_cell_count

        gfm_table_separator_cell_count(line) == header_cell_count
      end

      def active_link_reference_title_table_cell_count(line)
        boundary_line = line.chomp
        return nil if boundary_line.strip.empty?
        return nil if boundary_line.match?(INDENTED_CODE_BLOCK_PATTERN)
        return nil unless gfm_table_separator_cell_count(boundary_line).nil?
        return nil unless gfm_table_row_boundary_line?(boundary_line)

        gfm_table_cell_count(boundary_line)
      end
    end
  end
end

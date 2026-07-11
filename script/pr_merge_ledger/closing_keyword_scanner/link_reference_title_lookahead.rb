# frozen_string_literal: true

class PrMergeLedger
  module ClosingKeywordScanner
    module LinkReferenceTitleLookahead
      private

      def active_link_reference_title_closes_later?(delimiter, markdown_state)
        cached_result = cached_active_link_reference_title_lookahead(delimiter, markdown_state)
        return cached_result unless cached_result.nil?

        result = active_link_reference_title_lookahead_result(delimiter, markdown_state)
        cache_active_link_reference_title_lookahead(
          markdown_state,
          delimiter,
          result.fetch(:through_line_index),
          result.fetch(:closes_later)
        )
        result.fetch(:closes_later)
      end

      def active_link_reference_title_lookahead_result(delimiter, markdown_state)
        body_lines = markdown_state.fetch("body_lines")
        line_index = markdown_state.fetch("line_index")
        table_header_candidate_cell_count = nil
        body_lines[(line_index + 1)..].to_a.each_with_index do |line, offset|
          lookahead_index = line_index + 1 + offset
          link_reference_line = active_link_reference_title_lookahead_line(line, markdown_state)
          if link_reference_line.strip.empty? ||
             active_link_reference_title_boundary_line?(link_reference_line, markdown_state)
            return { through_line_index: lookahead_index, closes_later: false }
          end

          if active_link_reference_title_table_separator_line?(
            link_reference_line,
            table_header_candidate_cell_count
          )
            return { through_line_index: lookahead_index, closes_later: false }
          end

          closing_index = unescaped_delimiter_index(link_reference_line, delimiter)
          if closing_index
            closes_later = link_reference_line[(closing_index + delimiter.length)..].to_s.strip.empty?
            return { through_line_index: lookahead_index, closes_later: }
          end

          table_header_candidate_cell_count = active_link_reference_title_table_cell_count(link_reference_line)
        end

        { through_line_index: body_lines.length, closes_later: false }
      end

      def cached_active_link_reference_title_lookahead(delimiter, markdown_state)
        cache = markdown_state.fetch("link_reference_title_lookahead")
        return unless cache

        line_index = markdown_state.fetch("line_index")
        return unless cache.fetch(:delimiter) == delimiter
        return unless cache.fetch(:blockquote_depth) == active_link_reference_title_blockquote_depth(markdown_state)
        return unless line_index < cache.fetch(:through_line_index)

        cache.fetch(:closes_later)
      end

      def cache_active_link_reference_title_lookahead(markdown_state, delimiter, through_line_index, closes_later)
        markdown_state["link_reference_title_lookahead"] = {
          delimiter:,
          blockquote_depth: active_link_reference_title_blockquote_depth(markdown_state),
          through_line_index:,
          closes_later:
        }
      end

      def active_link_reference_title_blockquote_depth(markdown_state)
        markdown_state.fetch(
          "current_blockquote_depth",
          markdown_state.fetch("blockquote_depth")
        )
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

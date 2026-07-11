# frozen_string_literal: true

class PrMergeLedger
  module ClosingKeywordScanner
    module HtmlBlockContainers
      private

      def html_block_exited_container?(line, markdown_state, html_block)
        return true if html_block_exited_blockquote_container?(markdown_state, html_block)

        list_content_indent = html_block["container_list_content_indent"]
        return false unless list_content_indent
        return false if line.strip.empty?

        leading_indentation_columns(line) < list_content_indent
      end

      def html_block_exited_blockquote_container?(markdown_state, html_block)
        container_blockquote_depth = html_block.fetch("container_blockquote_depth", 0)
        return false unless container_blockquote_depth.positive?
        return true if markdown_state.fetch("current_line_lazy_blockquote_continuation", false)

        current_blockquote_depth = markdown_state.fetch(
          "current_blockquote_depth",
          markdown_state.fetch("blockquote_depth")
        )
        current_blockquote_depth < container_blockquote_depth
      end

      def html_block_with_container(html_block, markdown_state)
        return html_block unless markdown_state

        html_block.merge(
          "container_blockquote_depth" => markdown_state.fetch(
            "current_blockquote_depth",
            markdown_state.fetch("blockquote_depth")
          ),
          "container_list_content_indent" => markdown_state.fetch("list_content_indent")
        )
      end
    end
  end
end

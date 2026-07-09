# frozen_string_literal: true

class PrMergeLedger
  module ClosingKeywordScanner
    # Parser constants model Markdown state, not ledger state.
    CLOSING_KEYWORD_PATTERN = %r{
      \b(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?):?\s+
      (?:
        (?:[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)?\#\d+ |
        https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/(?:issues|pull)/\d+
      )
    }ix
    MAX_BODY_LINE_BYTES = 100_000
    CLOSING_KEYWORD_PREFIX_OVERLAP_CHARACTERS = 512
    CLOSING_KEYWORD_TAIL_OVERLAP_CHARACTERS =
      MAX_BODY_LINE_BYTES + CLOSING_KEYWORD_PREFIX_OVERLAP_CHARACTERS
    FENCED_CODE_BLOCK_PATTERN = /\A {0,3}(?<fence>`{3,}|~{3,})/
    INDENTED_CODE_BLOCK_PATTERN = /\A(?: {4}| {0,3}\t)/
    INDENTATION_CHARACTERS = [" ", "\t"].freeze
    LIST_ITEM_PATTERN = /\A(?<indent>[ \t]*)(?:[-+*]|\d{1,9}[.)])[ \t]+/
    ORDERED_LIST_ITEM_PATTERN = /\A(?<indent>[ \t]*)(?<start>\d{1,9})[.)][ \t]+/
    ORDERED_LIST_MARKER_OR_EMPTY_PATTERN = /\A(?<indent>[ \t]*)(?<start>\d{1,9})[.)](?:[ \t]+|[ \t]*\z)/
    EMPTY_LIST_ITEM_PATTERN = /\A(?<indent>[ \t]*)(?<marker>[-+*]|\d{1,9}[.)])[ \t]*(?:\r?\n)?\z/
    LIST_FENCED_CODE_BLOCK_PATTERN = /\A(?<indent>[ \t]*)(?:[-+*]|\d{1,9}[.)])[ \t]+(?<fence>`{3,}|~{3,})/
    LIST_ITEM_WITH_PADDING_PATTERN = /\A(?<indent>[ \t]*)(?<marker>[-+*]|\d{1,9}[.)])(?<padding>[ \t]+)(?<code>.*)/
    LIST_BLOCKQUOTE_MARKER_PATTERN = /\A(?<indent>[ \t]*)(?:[-+*]|\d{1,9}[.)])[ \t]+(?<blockquotes>(?:> ?)+)/
    SAME_LINE_LIST_ITEM_WITH_PADDING_PATTERN =
      /\G(?<indent>[ \t]*)(?<marker>[-+*]|\d{1,9}[.)])(?<padding>[ \t]+)(?<code>.*)/
    SAME_LINE_BLOCKQUOTE_MARKER_PATTERN = /\G(?:> ?)+/
    SAME_LINE_FENCED_CODE_BLOCK_PATTERN = /\G {0,3}(?<fence>`{3,}|~{3,})/
    ORDERED_ROOT_LIST_ITEM_PATTERN = /\A {0,3}(?<start>\d{1,9})[.)][ \t]+/
    ORDERED_ROOT_LIST_MARKER_OR_EMPTY_PATTERN = /\A {0,3}(?<start>\d{1,9})[.)](?:[ \t]+|[ \t]*\z)/
    ROOT_BLOCK_BOUNDARY_PATTERN = /\A {0,3}(?:\#{1,6}(?:\s|\z)|>|[-+*][ \t]+|\d{1,9}[.)][ \t]+)/
    HTML_BLOCK_TAG_NAMES = %w[
      address article aside base basefont blockquote body caption center col colgroup dd details dialog dir div dl dt
      fieldset figcaption figure footer form frame frameset h1 h2 h3 h4 h5 h6 head header hr html iframe legend li
      link main menu menuitem nav noframes ol optgroup option p param pre script search section source style summary
      table tbody
      td textarea tfoot th thead title tr track ul
    ].freeze
    HTML_RAW_TEXT_BLOCK_TAG_NAMES = %w[pre script style].freeze
    HTML_BLOCK_TAG_PATTERN = Regexp.union(HTML_BLOCK_TAG_NAMES)
    HTML_BLOCK_BOUNDARY_PATTERN =
      %r{\A {0,3}(?:<!--|<\?|<![A-Z]|<!\[CDATA\[|</?(?:#{HTML_BLOCK_TAG_PATTERN})(?:[\s>/]|\z))}i
    HTML_COMMENT_OPEN_PATTERN = /\A {0,3}<!--/
    HTML_CDATA_OPEN_PATTERN = /\A {0,3}<!\[CDATA\[/
    HTML_DECLARATION_OPEN_PATTERN = /\A {0,3}<![A-Z]/
    HTML_PROCESSING_INSTRUCTION_OPEN_PATTERN = /\A {0,3}<\?/
    HTML_BLOCK_TAG_OPEN_PATTERN = %r{\A {0,3}<(?<tag>#{HTML_BLOCK_TAG_PATTERN})(?:[\s>/]|\z)}i
    HTML_ATTRIBUTE_SPACES = [" ", "\t"].freeze
    HTML_ATTRIBUTE_INVALID_CHARACTERS = ["<", "\n"].freeze
    HTML_ATTRIBUTE_QUOTES = ["\"", "'"].freeze
    HTML_UNQUOTED_ATTRIBUTE_VALUE_INVALID_CHARACTERS = ["\"", "'", "=", "<", ">", "`", "\n"].freeze
    THEMATIC_BOUNDARY_PATTERN = /\A {0,3}(?:(?:-[ \t]*){3,}|(?:_[ \t]*){3,}|(?:\*[ \t]*){3,})\z/
    SETEXT_BOUNDARY_PATTERN = /\A {0,3}(?:=+|-+)[ \t]*\z/
    LINK_REFERENCE_DEFINITION_PATTERN = /\A {0,3}\[[^\]\r\n]+\]:[ \t]*(?<tail>[^\r\n]*)(?:\r?\n)?\z/
    LINK_REFERENCE_DEFINITION_LABEL_ONLY_PATTERN = /\A {0,3}\[[^\]\r\n]+\]:[ \t]*(?:\r?\n)?\z/
    LINK_REFERENCE_DESTINATION_LINE_PATTERN = /\A {0,3}\S/
    LINK_REFERENCE_TITLE_DELIMITERS = { "\"" => "\"", "'" => "'", "(" => ")" }.freeze
    TABLE_SEPARATOR_CELL_PATTERN = /\A:?-+:?\z/

    # These lightweight structs mimic the MatchData subset used by scanner helpers.
    ListMarkerIndentedCodeMatch = Struct.new(:code, :code_begin) do
      def [](key)
        return code if key == :code

        nil
      end

      def begin(key)
        return code_begin if key == :code

        nil
      end
    end
    FencedCodeBlockMatch = Struct.new(:fence, :fence_begin, :fence_end, :container_indent) do
      def [](key)
        return fence if key == :fence

        nil
      end

      def begin(key = 0)
        return fence_begin if [0, :fence].include?(key)

        nil
      end

      def end(key = 0)
        return fence_end if [0, :fence].include?(key)

        nil
      end
    end
    ListBlockquoteMarkerMatch = Struct.new(:match_end, :blockquote_depth) do
      def end(key = 0)
        return match_end if key.eql?(0)

        nil
      end
    end
  end
end

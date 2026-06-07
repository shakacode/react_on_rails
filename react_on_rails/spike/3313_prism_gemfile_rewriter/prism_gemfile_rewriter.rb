# frozen_string_literal: true

require "prism"

module ReactOnRails
  module Spike
    # Prism-based prototype for the Pro migration Gemfile rewrite.
    # See spike/3313_prism_gemfile_rewriter/README.md and DECISION.md.
    #
    # Approach: parse with Prism, locate `gem` call nodes whose first argument is the
    # string literal `react_on_rails`, then apply location-based source edits.
    # Untouched bytes are preserved by construction.
    class PrismGemfileRewriter
      BASE_GEM_NAME = "react_on_rails"
      PRO_GEM_NAME = "react_on_rails_pro"
      NEWLINE_BYTE = "\n".ord
      SEMICOLON_BYTE = ";".ord
      COMMENT_BYTE = "#".ord
      BACKSLASH_BYTE = "\\".ord
      DOUBLE_QUOTE_BYTE = '"'.ord
      SINGLE_QUOTE_BYTE = "'".ord
      PERCENT_BYTE = "%".ord
      PERCENT_LITERAL_TYPE_BYTES = "qQwWiIxrs".bytes.freeze
      PERCENT_LITERAL_CLOSING_DELIMITERS = {
        "(".ord => ")".ord,
        "[".ord => "]".ord,
        "{".ord => "}".ord,
        "<".ord => ">".ord
      }.freeze
      SOURCE_OPTION_KEYS = %w[git github path].freeze

      Result = Struct.new(
        :content,
        :base_entries_removed,
        :parse_failed,
        :errors,
        keyword_init: true
      )

      def initialize(default_pro_version:)
        @default_pro_version = default_pro_version
      end

      def rewrite(source)
        parse_result = Prism.parse(source)
        if parse_result.failure?
          return Result.new(
            content: source,
            base_entries_removed: false,
            parse_failed: true,
            errors: parse_result.errors.map { |e| "#{e.location.start_line}: #{e.message}" }
          )
        end

        program = parse_result.value
        base_calls = []
        pro_calls = []
        parent_map = {}
        collect_gem_calls(program, base_calls, pro_calls, parent_map)

        if base_calls.empty?
          return Result.new(
            content: source,
            base_entries_removed: false,
            parse_failed: false,
            errors: []
          )
        end

        has_active_pro = pro_calls.any?
        preexisting_empty_ranges = has_active_pro ? empty_conditional_ranges(program) : []
        edits = base_calls.map do |call|
          if has_active_pro
            removal_edit(source, call, parent_map)
          else
            replacement_edit(source, call)
          end
        end

        new_source = apply_edits(source, edits)
        if has_active_pro
          new_source = collapse_dead_conditionals(
            new_source,
            adjust_ranges_after_edits(preexisting_empty_ranges, edits)
          )
        end

        Result.new(
          content: new_source,
          base_entries_removed: has_active_pro,
          parse_failed: false,
          errors: []
        )
      end

      private

      attr_reader :default_pro_version

      def collect_gem_calls(node, base_calls, pro_calls, parent_map)
        return unless node

        if gem_call?(node)
          name = gem_call_first_argument_name(node)
          case name
          when BASE_GEM_NAME then base_calls << node
          when PRO_GEM_NAME then pro_calls << node
          end
        end

        node.compact_child_nodes.each do |child|
          parent_map[child] = node
          collect_gem_calls(child, base_calls, pro_calls, parent_map)
        end
      end

      def gem_call?(node)
        node.is_a?(Prism::CallNode) && node.name == :gem && node.receiver.nil?
      end

      def gem_call_first_argument_name(node)
        first_arg = node.arguments&.arguments&.first
        return nil unless first_arg.is_a?(Prism::StringNode)

        first_arg.unescaped
      end

      def replacement_edit(source, call)
        first_arg = call.arguments.arguments.first
        quote = quote_char(source, first_arg)
        new_name_literal = "#{quote}#{PRO_GEM_NAME}#{quote}"

        if has_user_version_pin?(call)
          {
            start_offset: first_arg.location.start_offset,
            end_offset: first_arg.location.end_offset,
            replacement: new_name_literal
          }
        else
          # No user version pin: insert the default version as the second positional argument.
          # We splice it after the name literal so any kwargs (path:, git:, ...) remain in place.
          {
            start_offset: first_arg.location.start_offset,
            end_offset: first_arg.location.end_offset,
            replacement: "#{new_name_literal}, #{quote}#{default_pro_version}#{quote}"
          }
        end
      end

      def has_user_version_pin?(call)
        positional_args = call.arguments.arguments.drop(1).reject { |a| option_hash?(a) }
        positional_args.any? || source_option_present?(call)
      end

      def source_option_present?(call)
        option_hashes = call.arguments.arguments.select { |a| option_hash?(a) }
        option_hashes.any? do |option_hash|
          option_hash.elements.any? do |element|
            element.respond_to?(:key) &&
              element.key.is_a?(Prism::SymbolNode) &&
              SOURCE_OPTION_KEYS.include?(element.key.unescaped)
          end
        end
      end

      def option_hash?(node)
        node.is_a?(Prism::KeywordHashNode) || node.is_a?(Prism::HashNode)
      end

      def quote_char(source, string_node)
        quote = source.byteslice(string_node.location.start_offset, 1)
        return quote if quote == '"' || quote == "'"

        '"'
      end

      def removal_edit(source, call, parent_map)
        # Remove only this gem statement. If it is the only statement on a line,
        # remove the whole line; if it shares a line via semicolons, preserve the
        # neighboring statements.
        node = removable_statement_node(call, parent_map)

        # Inline single-line block conditionals (`if X then gem "ror_pro" else gem "ror" end`)
        # have no statement separators on the line, so the line-based fallback in
        # `statement_byte_range` would delete the whole conditional — including the
        # sibling Pro gem in the other branch. Remove only the call's own byte range;
        # the collapse pass below tidies the resulting empty branch.
        if node.equal?(call) && inline_conditional_with_sibling_branch?(call, parent_map)
          return {
            start_offset: call.location.start_offset,
            end_offset: call.location.end_offset,
            replacement: ""
          }
        end

        start_offset, end_offset = statement_byte_range(source, node)
        { start_offset:, end_offset:, replacement: "" }
      end

      def inline_conditional_with_sibling_branch?(call, parent_map)
        statements = parent_map[call]
        return false unless statements.is_a?(Prism::StatementsNode)

        conditional = parent_map[statements]
        # For the else-branch case the immediate parent is an ElseNode that
        # itself sits inside the surrounding IfNode/UnlessNode.
        conditional = parent_map[conditional] if conditional.is_a?(Prism::ElseNode)
        return false unless conditional.is_a?(Prism::IfNode) || conditional.is_a?(Prism::UnlessNode)
        return false unless conditional.respond_to?(:end_keyword_loc) && conditional.end_keyword_loc
        return false unless conditional.location.start_line == conditional.location.end_line

        sibling_branch_present?(conditional, statements)
      end

      def sibling_branch_present?(conditional, exclude_statements)
        then_branch = conditional.statements
        if then_branch && !then_branch.equal?(exclude_statements) && !branch_empty?(then_branch)
          return true
        end

        else_node = conditional_else_node(conditional)
        else_statements = else_node&.statements
        !else_statements.nil? &&
          !else_statements.equal?(exclude_statements) &&
          !branch_empty?(else_statements)
      end

      def removable_statement_node(call, parent_map)
        statements = parent_map[call]
        return call unless statements.is_a?(Prism::StatementsNode)
        return call unless statements.body.one?

        parent = parent_map[statements]
        return call unless parent.is_a?(Prism::IfNode) || parent.is_a?(Prism::UnlessNode)
        return call if parent.end_keyword_loc

        keyword_loc = conditional_keyword_loc(parent)
        return call unless keyword_loc && keyword_loc.start_offset > call.location.end_offset

        parent
      end

      def conditional_keyword_loc(node)
        if node.is_a?(Prism::IfNode)
          node.if_keyword_loc
        elsif node.is_a?(Prism::UnlessNode)
          node.keyword_loc
        end
      end

      def statement_byte_range(source, node)
        line_start = line_start_offset(source, node.location.start_offset)
        line_end = line_end_offset(source, node.location.end_offset)
        next_semicolon = next_semicolon_offset(
          source,
          line_start_offset(source, node.location.end_offset),
          line_end,
          node.location.end_offset
        )
        statement_end = next_semicolon || line_terminator_offset(source, line_end)

        previous_semicolon = previous_semicolon_offset(source, line_start, node.location.start_offset)
        if previous_semicolon
          [previous_semicolon, statement_end]
        elsif next_semicolon
          end_offset = next_semicolon + 1
          end_offset += 1 while end_offset < line_end && horizontal_space?(source.getbyte(end_offset))
          [line_start, end_offset]
        else
          [line_start, line_end]
        end
      end

      def previous_semicolon_offset(source, line_start, statement_start)
        statement_separator_offsets(source, line_start, statement_start).last
      end

      def next_semicolon_offset(source, line_start, line_end, statement_end)
        statement_separator_offsets(source, line_start, line_end).find { |offset| offset >= statement_end }
      end

      # NOTE: tracks string and percent-literal contexts but does not track
      # parenthesis depth. A semicolon inside an unquoted call argument
      # (e.g. `gem "ror" if func(a; b)`) would be misidentified as a
      # statement separator. Bundler's Gemfile DSL does not produce such
      # patterns in practice; revisit if the rewriter moves outside Gemfiles.
      def statement_separator_offsets(source, line_start, line_end)
        offsets = []
        quote_byte = nil
        scan = line_start

        while scan < line_end
          byte = source.getbyte(scan)
          break if byte == NEWLINE_BYTE || (!quote_byte && byte == COMMENT_BYTE)

          if quote_byte
            if byte == BACKSLASH_BYTE
              scan += 2
              next
            end

            quote_byte = nil if byte == quote_byte
          elsif byte == DOUBLE_QUOTE_BYTE || byte == SINGLE_QUOTE_BYTE
            quote_byte = byte
          elsif byte == PERCENT_BYTE
            percent_literal_end = percent_literal_end_offset(source, scan, line_end)
            if percent_literal_end
              scan = percent_literal_end
              next
            end
          elsif byte == SEMICOLON_BYTE
            offsets << scan
          end

          scan += 1
        end

        offsets
      end

      def percent_literal_end_offset(source, start_offset, line_end)
        delimiter_offset = start_offset + 1
        type_or_delimiter = source.getbyte(delimiter_offset)
        return nil unless type_or_delimiter

        delimiter_offset += 1 if PERCENT_LITERAL_TYPE_BYTES.include?(type_or_delimiter)
        delimiter = source.getbyte(delimiter_offset)
        return nil unless percent_literal_delimiter?(delimiter)

        closing_delimiter = PERCENT_LITERAL_CLOSING_DELIMITERS.fetch(delimiter, delimiter)
        nesting = PERCENT_LITERAL_CLOSING_DELIMITERS.key?(delimiter) ? 1 : nil
        scan = delimiter_offset + 1

        while scan < line_end
          byte = source.getbyte(scan)
          if byte == BACKSLASH_BYTE
            scan += 2
            next
          end

          if nesting
            nesting += 1 if byte == delimiter
            nesting -= 1 if byte == closing_delimiter
            return scan + 1 if nesting.zero?
          elsif byte == closing_delimiter
            return scan + 1
          end

          scan += 1
        end

        line_end
      end

      def percent_literal_delimiter?(byte)
        byte && !horizontal_space?(byte) && byte != NEWLINE_BYTE && !ascii_alphanumeric?(byte)
      end

      def ascii_alphanumeric?(byte)
        (byte >= "a".ord && byte <= "z".ord) ||
          (byte >= "A".ord && byte <= "Z".ord) ||
          (byte >= "0".ord && byte <= "9".ord)
      end

      def line_terminator_offset(source, line_end)
        newline_offset = line_end - 1
        newline_offset >= 0 && source.getbyte(newline_offset) == NEWLINE_BYTE ? newline_offset : line_end
      end

      def horizontal_space?(byte)
        byte == " ".ord || byte == "\t".ord
      end

      def apply_edits(source, edits)
        sorted = edits.sort_by { |e| -e[:start_offset] }
        sorted.reduce(source) do |acc, edit|
          splice_source(acc, edit[:start_offset], edit[:end_offset], edit[:replacement])
        end
      end

      def byte_slice(source, start_offset, end_offset)
        source.byteslice(start_offset, end_offset - start_offset) || ""
      end

      def splice_source(source, start_offset, end_offset, replacement)
        prefix = source.byteslice(0, start_offset) || ""
        suffix = source.byteslice(end_offset, source.bytesize - end_offset) || ""
        prefix + replacement + suffix
      end

      # After removing base gem statements, conditionals like
      #   if ENV["PRO"]
      #     gem "react_on_rails_pro", "16.0.0"
      #   else
      #     gem "react_on_rails", "16.0.0"
      #   end
      # become
      #   if ENV["PRO"]
      #     gem "react_on_rails_pro", "16.0.0"
      #   else
      #   end
      # which is valid but ugly. This pass collapses such conditionals.
      #
      # Policy:
      # - If the conditional has exactly one non-empty branch and that branch contains
      #   only `gem "react_on_rails_pro"`, the conditional is collapsed to that single
      #   gem declaration (the conditional's original purpose was to pick between gem
      #   variants; after migration there is only one variant, so the conditional has
      #   no remaining purpose).
      # - Otherwise, if a branch is empty, only that branch is removed.
      # Safety bound: each iteration removes one collapsible conditional, so the
      # editable-conditional count is monotonically decreasing. The explicit cap is
      # belt-and-suspenders insurance against any future change that could let
      # `find_collapse_edit` return a non-`nil` edit producing no net change.
      MAX_COLLAPSE_PASSES = 100

      def collapse_dead_conditionals(source, preexisting_empty_ranges)
        MAX_COLLAPSE_PASSES.times do
          parse_result = Prism.parse(source)
          break if parse_result.failure?

          edit = find_collapse_edit(
            source,
            parse_result.value,
            preexisting_empty_ranges
          )
          break unless edit
          # Defensive: a zero-length empty splice would be reapplied forever.
          # Real collapse edits always remove or replace at least one byte.
          break if edit[:start_offset] == edit[:end_offset] && edit[:replacement].empty?

          source = splice_source(source, edit[:start_offset], edit[:end_offset], edit[:replacement])
          preexisting_empty_ranges = adjust_ranges_after_edits(preexisting_empty_ranges, [edit])
        end
        source
      end

      def find_collapse_edit(
        source,
        node,
        preexisting_empty_ranges
      )
        return nil unless node

        if node.is_a?(Prism::IfNode) || node.is_a?(Prism::UnlessNode)
          edit = collapse_edit_for_conditional(
            source,
            node,
            preexisting_empty_ranges
          )
          return edit if edit
        end

        node.compact_child_nodes.each do |child|
          edit = find_collapse_edit(
            source,
            child,
            preexisting_empty_ranges
          )
          return edit if edit
        end

        nil
      end

      def collapse_edit_for_conditional(
        source,
        node,
        preexisting_empty_ranges
      )
        # Postfix modifiers and ternary-style conditionals have node.end_keyword_loc == nil.
        # Only block-form `if/unless ... end` is considered for collapse.
        return nil unless node.respond_to?(:end_keyword_loc) && node.end_keyword_loc
        return nil if preexisting_empty_ranges.include?([node.location.start_offset, node.location.end_offset])

        then_branch = node.statements
        else_node = conditional_else_node(node)
        has_else_node = !else_node.nil?
        else_statements = has_else_node ? else_node.statements : nil

        then_empty = branch_empty?(then_branch)
        else_empty = has_else_node && branch_empty?(else_statements)

        # NOTE: when `remove_empty_then_branch` is called the conditional cannot
        # be collapsed to a single Pro gem (otherwise `collapse_to_branch` would
        # have matched first). The stub returns `nil` for the spike, so the
        # empty-`then` conditional is left in the output. See the stub itself
        # for what production should do.
        if then_empty && has_else_node && !else_empty
          collapse_to_branch(source, node, else_statements) || remove_empty_then_branch(source, node)
        elsif has_else_node && else_empty && !then_empty
          collapse_to_branch(source, node, then_branch) || remove_empty_else_branch(source, node)
        end
      end

      def branch_empty?(statements_node)
        return true if statements_node.nil?
        return true unless statements_node.respond_to?(:body)

        statements_node.body.empty?
      end

      def empty_conditional_ranges(node)
        ranges = []
        collect_empty_conditional_ranges(node, ranges)
        ranges
      end

      def collect_empty_conditional_ranges(node, ranges)
        return unless node

        ranges << [node.location.start_offset, node.location.end_offset] if empty_conditional?(node)

        node.compact_child_nodes.each do |child|
          collect_empty_conditional_ranges(child, ranges)
        end
      end

      def empty_conditional?(node)
        return false unless node.is_a?(Prism::IfNode) || node.is_a?(Prism::UnlessNode)
        return false unless node.respond_to?(:end_keyword_loc) && node.end_keyword_loc

        then_branch = node.statements
        else_node = conditional_else_node(node)
        return false unless else_node

        else_statements = else_node.statements
        branch_empty?(then_branch) || branch_empty?(else_statements)
      end

      def adjust_ranges_after_edits(ranges, edits)
        sorted_edits = edits.sort_by { |edit| edit[:start_offset] }
        ranges.filter_map { |range| adjust_range_after_edits(range, sorted_edits) }
      end

      def adjust_range_after_edits(range, edits)
        original_start, original_end = range
        prefix_delta = 0
        inside_delta = 0

        edits.each do |edit|
          edit_start = edit[:start_offset]
          edit_end = edit[:end_offset]
          edit_delta = edit[:replacement].bytesize - (edit_end - edit_start)

          if edit_end <= original_start
            prefix_delta += edit_delta
          elsif edit_start >= original_end
            next
          elsif edit_start >= original_start && edit_end <= original_end
            inside_delta += edit_delta
          else
            return nil
          end
        end

        [original_start + prefix_delta, original_end + prefix_delta + inside_delta]
      end

      def collapse_to_branch(source, conditional, branch_statements)
        return nil unless single_pro_gem_call?(branch_statements)

        gem_call = branch_statements.body.first
        gem_text = byte_slice(source, gem_call.location.start_offset, gem_call.location.end_offset)
        # Preserve indentation of the original conditional.
        indent = leading_indentation(source, conditional.location.start_offset)
        collapse_replacement_edit(source, conditional, "#{indent}#{gem_text}\n", gem_text)
      end

      def collapse_replacement_edit(source, conditional, full_line_replacement, inline_replacement)
        line_start = line_start_offset(source, conditional.location.start_offset)
        line_end = line_end_offset(source, conditional.location.end_offset)
        next_semicolon = next_semicolon_offset(
          source,
          line_start_offset(source, conditional.location.end_offset),
          line_end,
          conditional.location.end_offset
        )
        previous_semicolon = previous_semicolon_offset(source, line_start, conditional.location.start_offset)

        if previous_semicolon || next_semicolon
          {
            start_offset: conditional.location.start_offset,
            end_offset: conditional.location.end_offset,
            replacement: inline_replacement
          }
        else
          {
            start_offset: line_start,
            end_offset: line_end,
            replacement: full_line_replacement
          }
        end
      end

      def single_pro_gem_call?(statements_node)
        return false if statements_node.nil?
        return false unless statements_node.body.size == 1

        call = statements_node.body.first
        gem_call?(call) && gem_call_first_argument_name(call) == PRO_GEM_NAME
      end

      def remove_empty_else_branch(source, node)
        # Find the `else` keyword location and remove from there to just before `end`.
        else_node = conditional_else_node(node)
        return nil unless else_node

        else_loc = else_node.else_keyword_loc
        end_loc = node.end_keyword_loc
        return nil unless else_loc && end_loc

        # Remove the entire `else ... ` (including the line) up to the `end` keyword.
        start_offset = line_start_offset(source, else_loc.start_offset)
        end_offset = line_start_offset(source, end_loc.start_offset)
        # Inline conditionals like `if X; pro; else; end` put `else` and `end`
        # on the same line, so both line-start lookups return the same offset.
        # A zero-length empty splice is a no-op; refuse it to avoid leaving the
        # collapse loop with nothing to do (the source is left unchanged).
        return nil if start_offset == end_offset

        {
          start_offset:,
          end_offset:,
          replacement: ""
        }
      end

      def remove_empty_then_branch(_source, _node)
        # `if X then (empty) else BODY end` → `unless X then BODY end`.
        # That is fiddly and uncommon; for the spike we leave this case alone.
        nil
      end

      def leading_indentation(source, offset)
        line_start = line_start_offset(source, offset)
        slice = byte_slice(source, line_start, offset)
        slice[/\A\s*/].to_s
      end

      def line_start_offset(source, offset)
        return 0 if offset.zero?

        idx = source.b.rindex("\n".b, offset - 1)
        idx ? idx + 1 : 0
      end

      def line_end_offset(source, offset)
        idx = source.b.index("\n".b, offset)
        idx ? idx + 1 : source.bytesize
      end

      def conditional_else_node(node)
        if node.is_a?(Prism::IfNode)
          node.subsequent if node.subsequent.is_a?(Prism::ElseNode)
        elsif node.is_a?(Prism::UnlessNode)
          node.else_clause
        end
      end
    end
  end
end

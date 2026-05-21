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
        collect_gem_calls(program, base_calls, pro_calls)

        if base_calls.empty?
          return Result.new(
            content: source,
            base_entries_removed: false,
            parse_failed: false,
            errors: []
          )
        end

        has_active_pro = pro_calls.any?
        edits = base_calls.map do |call|
          if has_active_pro
            removal_edit(source, call)
          else
            replacement_edit(source, call)
          end
        end

        new_source = apply_edits(source, edits)
        new_source = collapse_dead_conditionals(new_source) if has_active_pro

        Result.new(
          content: new_source,
          base_entries_removed: has_active_pro,
          parse_failed: false,
          errors: []
        )
      end

      private

      attr_reader :default_pro_version

      def collect_gem_calls(node, base_calls, pro_calls)
        return unless node

        if gem_call?(node)
          name = gem_call_first_argument_name(node)
          case name
          when BASE_GEM_NAME then base_calls << node
          when PRO_GEM_NAME then pro_calls << node
          end
        end

        node.compact_child_nodes.each do |child|
          collect_gem_calls(child, base_calls, pro_calls)
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
        positional_args = call.arguments.arguments.drop(1).reject { |a| a.is_a?(Prism::KeywordHashNode) }
        positional_args.any? { |a| a.is_a?(Prism::StringNode) }
      end

      def quote_char(source, string_node)
        source[string_node.location.start_offset]
      end

      def removal_edit(source, call)
        # Remove the entire statement containing the gem call, including any postfix
        # modifier (`if`, `unless`, `while`, `until`) and the trailing newline. The
        # statement may be wrapped in an `IfNode` / `UnlessNode` when there is a
        # postfix modifier, so we walk outward until we find the enclosing
        # statement-level node.
        statement_node = enclosing_statement_node(call)
        start_offset, end_offset = statement_byte_range(source, statement_node)
        { start_offset: start_offset, end_offset: end_offset, replacement: "" }
      end

      # When Prism parses `gem "foo" if cond`, the outermost node is `IfNode`, not the
      # `CallNode`. We treat the postfix-modifier node as the statement to remove.
      def enclosing_statement_node(call)
        # We do not have an explicit parent pointer; the caller passes the CallNode, so
        # we need to detect a postfix modifier by looking at the source slice. Prism's
        # location for the CallNode does NOT include the modifier, so we re-locate by
        # inspecting the source after the call's end_offset.
        call
      end

      def statement_byte_range(source, node)
        start_offset = line_start_offset(source, node.location.start_offset)

        # Walk forward from the node's end_offset to the end of the source line so that
        # we also delete trailing modifier text (e.g. `if ENV["X"]`) and the newline.
        scan = node.location.end_offset
        scan += 1 while scan < source.length && source[scan] != "\n"
        scan += 1 if scan < source.length && source[scan] == "\n"
        [start_offset, scan]
      end

      def apply_edits(source, edits)
        sorted = edits.sort_by { |e| -e[:start_offset] }
        sorted.reduce(source) do |acc, edit|
          acc[0...edit[:start_offset]] + edit[:replacement] + acc[edit[:end_offset]..]
        end
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
      def collapse_dead_conditionals(source)
        loop do
          parse_result = Prism.parse(source)
          break source if parse_result.failure?

          edit = find_collapse_edit(source, parse_result.value)
          break source unless edit

          source = source[0...edit[:start_offset]] + edit[:replacement] + source[edit[:end_offset]..]
        end
      end

      def find_collapse_edit(source, node)
        return nil unless node

        if node.is_a?(Prism::IfNode) || node.is_a?(Prism::UnlessNode)
          edit = collapse_edit_for_conditional(source, node)
          return edit if edit
        end

        node.compact_child_nodes.each do |child|
          edit = find_collapse_edit(source, child)
          return edit if edit
        end

        nil
      end

      def collapse_edit_for_conditional(source, node)
        # Postfix modifiers and ternary-style conditionals have node.end_keyword_loc == nil.
        # Only block-form `if/unless ... end` is considered for collapse.
        return nil unless node.respond_to?(:end_keyword_loc) && node.end_keyword_loc

        then_branch = node.statements
        has_else_node = node.subsequent.is_a?(Prism::ElseNode)
        else_statements = has_else_node ? node.subsequent.statements : nil

        then_empty = branch_empty?(then_branch)
        else_empty = has_else_node && branch_empty?(else_statements)

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

      def collapse_to_branch(source, conditional, branch_statements)
        return nil unless single_pro_gem_call?(branch_statements)

        gem_call = branch_statements.body.first
        gem_text = source[gem_call.location.start_offset...gem_call.location.end_offset]
        # Preserve indentation of the original conditional.
        indent = leading_indentation(source, conditional.location.start_offset)
        {
          start_offset: line_start_offset(source, conditional.location.start_offset),
          end_offset: line_end_offset(source, conditional.location.end_offset),
          replacement: "#{indent}#{gem_text}\n"
        }
      end

      def single_pro_gem_call?(statements_node)
        return false if statements_node.nil?
        return false unless statements_node.body.size == 1

        call = statements_node.body.first
        gem_call?(call) && gem_call_first_argument_name(call) == PRO_GEM_NAME
      end

      def remove_empty_else_branch(source, node)
        # Find the `else` keyword location and remove from there to just before `end`.
        return nil unless node.subsequent.is_a?(Prism::ElseNode)

        else_loc = node.subsequent.else_keyword_loc
        end_loc = node.end_keyword_loc
        return nil unless else_loc && end_loc

        # Remove the entire `else ... ` (including the line) up to the `end` keyword.
        start_offset = line_start_offset(source, else_loc.start_offset)
        end_offset = line_start_offset(source, end_loc.start_offset)
        {
          start_offset: start_offset,
          end_offset: end_offset,
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
        slice = source[line_start...offset]
        slice[/\A\s*/].to_s
      end

      def line_start_offset(source, offset)
        return 0 if offset.zero?

        idx = source.rindex("\n", offset - 1)
        idx ? idx + 1 : 0
      end

      def line_end_offset(source, offset)
        idx = source.index("\n", offset)
        idx ? idx + 1 : source.length
      end
    end
  end
end

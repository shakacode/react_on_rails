module SCSSLint
  # Checks for "reason" comments above linter-disabling comments.
  class Linter::DisableLinterReason < Linter
    include LinterRegistry

    def visit_comment(node)
      # No lint if the first line of the comment is not a command (because then
      # either this comment has no commands, or the first line serves as a the
      # reason for a command on a later line).
      return unless comment_lines(node).first.match(COMMAND_REGEX)

      # Maybe the previous node is the "reason" comment.
      prev = previous_node(node)

      if prev && prev.is_a?(Sass::Tree::CommentNode)
        # No lint if the last line of the previous comment is not a command.
        return unless comment_lines(prev).last.match(COMMAND_REGEX)
      end

      add_lint(node,
               'scss-lint:disable control comments should be preceded by a ' \
               'comment explaining why the linters need to be disabled.')
    end

  private

    COMMAND_REGEX = %r{
      (/|\*)\s* # Comment start marker
      scss-lint:
      (?<action>disable)\s+
      (?<linters>.*?)
      \s*(?:\*/|\n) # Comment end marker or end of line
    }x

    def comment_lines(node)
      node.value.join.split("\n")
    end
  end
end

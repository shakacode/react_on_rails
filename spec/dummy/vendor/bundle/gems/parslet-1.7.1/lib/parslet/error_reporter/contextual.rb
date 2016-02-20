module Parslet
  module ErrorReporter

    # A reporter that tries to improve on the deepest error reporter by
    # using heuristics to find the most relevant error and provide more
    # context.
    # The heuristic chooses the deepest error when parsing a sequence for which
    # no alternative parsed successfully.
    #
    # Given the following parser:
    #
    # root(:call)
    #
    # rule(:call, label: 'call') {
    #   identifier >> str('.') >> method
    # }
    #
    # rule(:method, label: 'method call') {
    #   identifier >> str('(') >> arguments.maybe >> str(')')
    # }
    #
    # rule(:identifier, label: 'identifier') {
    #   match['[:alnum:]'].repeat(1)
    # }
    #
    # rule(:arguments, label: 'method call arguments') {
    #   argument >> str(',') >> arguments | argument
    # }
    #
    # rule(:argument) {
    #    call | identifier
    # }
    #
    # and the following source:
    #
    #   foo.bar(a,goo.baz(),c,)
    #
    # The contextual reporter returns the following causes:
    #
    # 0: Failed to match sequence (identifier '.' method call) at line 1 char 5
    #    when parsing method call arguments.
    # 1: Failed to match sequence (identifier '(' method call arguments? ')') at
    #    line 1 char 22 when parsing method call arguments.
    # 2: Failed to match [[:alnum:]] at line 1 char 23 when parsing method call
    #    arguments.
    #
    # (where 2 is a child cause of 1 and 1 a child cause of 0)
    #
    # The last piece used by the reporter is the (newly introduced) ability
    # to attach a label to rules that describe a sequence in the grammar. The
    # labels are used in two places:
    #   - In the "to_s" of Atom::Base so that any error message uses labels to
    #     refer to atoms
    #   - In the cause error messages to give information about which expression
    #     failed to parse
    #
    class Contextual < Deepest

      def initialize
        @last_reset_pos = 0
        reset
      end

      # A sequence expression successfully parsed, reset all errors reported
      # for previous expressions in the sequence (an alternative matched)
      # Only reset errors if the position of the source that matched is higher
      # than the position of the source that was last successful (so we keep
      # errors that are the "deepest" but for which no alternative succeeded)
      #
      def succ(source)
        source_pos = source.pos.bytepos
        return if source_pos < @last_reset_pos
        @last_reset_pos = source_pos
        reset
      end

      # Reset deepest error and its position and sequence index
      #
      def reset
        @deepest_cause = nil
        @label_pos = -1
      end

      # Produces an error cause that combines the message at the current level
      # with the errors that happened at a level below (children).
      # Compute and set label used by Cause to produce error message.
      #
      # @param atom [Parslet::Atoms::Base] parslet that failed
      # @param source [Source] Source that we're using for this parse. (line
      #   number information...)
      # @param message [String, Array] Error message at this level.
      # @param children [Array] A list of errors from a deeper level (or nil).
      # @return [Cause] An error tree combining children with message.
      #
      def err(atom, source, message, children=nil)
        cause = super(atom, source, message, children)
        if (label = atom.respond_to?(:label) && atom.label)
          update_label(label, source.pos.bytepos)
          cause.set_label(@label)
        end
        cause
      end

      # Update error message label if given label is more relevant.
      # A label is more relevant if the position of the matched source is
      # bigger.
      #
      # @param label [String] label to apply if more relevant
      # @param bytepos [Integer] position in source code of matched source
      #
      def update_label(label, bytepos)
        if bytepos >= @label_pos
          @label_pos = bytepos
          @label = label
        end
      end

    end
  end
end

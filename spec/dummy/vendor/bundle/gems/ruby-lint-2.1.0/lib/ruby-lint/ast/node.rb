module RubyLint
  module AST
    ##
    # Extends the Node class provided by the `parser` Gem with various extra
    # methods.
    #
    class Node < ::Parser::AST::Node
      include ::RubyLint::VariablePredicates

      ##
      # @return [Numeric]
      #
      def line
        return location.expression.line if location
      end

      ##
      # @return [Numeric]
      #
      def column
        return location.expression.column + 1 if location
      end

      ##
      # @return [String]
      #
      def file
        return location.expression.source_buffer.name if location
      end

      ##
      # @return [String]
      #
      def name
        return const? ? children[-1].to_s : children[0].to_s
      end

      ##
      # Similar to `#inspect` but formats the value so that it fits on a single
      # line.
      #
      # @return [String]
      #
      def inspect_oneline
        return to_s.gsub(/\s*\n\s*/, ' ')
      end
    end # Node
  end # AST
end # RubyLint

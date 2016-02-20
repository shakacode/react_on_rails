module RubyLint
  module AST
    ##
    # Custom AST builder class used to provide some extra additions/changes to
    # the AST such as the use of a custom node class.
    #
    class Builder < ::Parser::Builders::Default
      ##
      # @see Parser::Builders::Default#n
      # @return [RubyLint::AST::Node]
      #
      def n(type, children, location)
        return Node.new(type, children, :location => location)
      end
    end # Builder
  end # AST
end # RubyLint

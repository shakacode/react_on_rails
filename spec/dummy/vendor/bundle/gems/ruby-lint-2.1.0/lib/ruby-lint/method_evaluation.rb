module RubyLint
  ##
  # Mixin that provides helper methods for handling method calls.
  #
  module MethodEvaluation
    ##
    # Given a `(block)` node this method returns the nested `(send)` node. If
    # the supplied node is not a block it is returned directly.
    #
    # This method is mostly useful for dealing with method calls that take a
    # block. In these cases the AST is in the form of `(block (send))` instead
    # of `(send (block))`.
    #
    # @param [RubyLint::AST::Node] node
    # @return [RubyLint::AST::Node]
    #
    def unpack_block(node)
      return node && node.block? ? node.children[0] : node
    end
  end # MethodEvaluation
end # RubyLint

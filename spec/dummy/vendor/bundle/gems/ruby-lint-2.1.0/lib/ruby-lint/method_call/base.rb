module RubyLint
  module MethodCall
    ##
    # Base class for the various method call handlers, takes care of some of
    # the common boilerplate code.
    #
    # @!attribute [r] node
    #  @return [RubyLint::AST::Node]
    #
    # @!attribute [r] vm
    #  @return [RubyLint::VirtualMachine]
    #
    class Base
      attr_reader :node, :vm

      ##
      # @param [RubyLint::AST::Node] node
      # @param [RubyLint::VirtualMachine] vm
      #
      def initialize(node, vm)
        @node = node
        @vm   = vm
      end

      ##
      # @param [Array] arguments
      # @param [RubyLint::Definition::RubyObject] context
      # @param [RubyLint::Definition::RubyObject] block
      #
      #:nocov:
      def evaluate(arguments, context, block = nil)
        raise NotImplementedError, '#evaluate must be implemented'
      end
      #:nocov:
    end # Base
  end # MethodCall
end # RubyLint

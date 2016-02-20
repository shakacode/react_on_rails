module RubyLint
  module DefinitionBuilder
    ##
    # Base definition builder that provides common methods for individual
    # builder classes.
    #
    # @!attribute [r] node
    #  @return [RubyLint::AST::Node]
    #
    # @!attribute [r] vm
    #  @return [RubyLint::VirtualMachine]
    #
    class Base
      attr_reader :vm, :node, :options

      ##
      # @param [RubyLint::AST::Node] node
      # @param [RubyLint::VirtualMachine] vm
      # @param [Hash] options
      #
      def initialize(node, vm, options = {})
        @node    = node
        @vm      = vm
        @options = options

        after_initialize if respond_to?(:after_initialize)
      end

      protected

      ##
      # Returns the name of a constant node as a String.
      #
      # @param [RubyLint::AST::Node] node
      # @return [String]
      #
      def constant_name(node)
        return node.children[1].to_s
      end
    end # Base
  end # DefinitionBuilder
end # RubyLint

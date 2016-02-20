module RubyLint
  module DefinitionBuilder
    ##
    # Definition builder used for building primitive Ruby types such as
    # integers and strings.
    #
    class Primitive < Base
      ##
      # @return [RubyLint::Definition::RubyObject]
      #
      def build
        parents = [definition_for_node(node)]
        opts    = {
          :type          => node.type,
          :value         => node.children[0],
          :instance_type => :instance,
          :parents       => parents
        }.merge(options)

        return Definition::RubyObject.new(opts)
      end

      ##
      # Returns a definition for a given node type.
      #
      # @param [RubyLint::AST::Node] node
      # @return [RubyLint::Definition::RubyObject]
      # @raise ArgumentError Raised when an invalid type was specified.
      #
      def definition_for_node(node)
        ruby_class = node.ruby_class

        raise(ArgumentError, "The type #{type} is invalid") unless ruby_class

        return vm.global_constant(ruby_class)
      end
    end # Primitive
  end # DefinitionBuilder
end # RubyLint

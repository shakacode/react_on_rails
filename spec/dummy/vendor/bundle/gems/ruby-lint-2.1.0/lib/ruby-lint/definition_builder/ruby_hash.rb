module RubyLint
  module DefinitionBuilder
    ##
    # Definition builder for building Ruby hashes.
    #
    class RubyHash < RubyArray
      ##
      # Builds the definition for the Hash and assigns the members.
      #
      # @return [RubyLint::Definition::RubyObject]
      #
      def build
        definition = create_container

        values.each do |pair|
          definition.add_definition(pair)
        end

        return definition
      end

      ##
      # @see RubyLint::DefinitionBuilder::RubyArray#parents
      #
      def parents
        return [vm.global_constant('Hash')]
      end

      ##
      # @return [Symbol]
      #
      def container_type
        return :hash
      end
    end # RubyHash
  end # DefinitionBuilder
end # RubyLint

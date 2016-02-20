module RubyLint
  module DefinitionBuilder
    ##
    # Definition builder for building Ruby arrays.
    #
    class RubyArray < Base
      ##
      # Builds the definition for the array and assigns the values as members.
      #
      # @return [RubyLint::Definition::RubyObject]
      #
      def build
        definition = create_container

        values.each_with_index do |value, index|
          member = create_member(index.to_s, value)

          definition.add_definition(member)
        end

        return definition
      end

      private

      ##
      # @return [Array]
      #
      def values
        return options[:values] || []
      end

      ##
      # @return [Array]
      #
      def parents
        return [vm.global_constant('Array')]
      end

      ##
      # Creates an empty data container for the members.
      #
      # @return [RubyLint::Definition::RubyObject]
      #
      def create_container
        return Definition::RubyObject.new(
          :type             => container_type,
          :instance_type    => :instance,
          :parents          => parents,
          :members_as_value => true
        )
      end

      ##
      # @return [Symbol]
      #
      def container_type
        return :array
      end

      ##
      # Creates a new array member definition.
      #
      # @param [String] name
      # @param [RubyLint::Definition::RubyObject] value
      # @return [RubyLint::Definition::RubyObject]
      #
      def create_member(name, value)
        return Definition::RubyObject.new(
          :type  => :member,
          :name  => name,
          :value => value
        )
      end
    end # RubyArray
  end # DefinitionBuilder
end # RubyLint

module RubyLint
  module DefinitionBuilder
    ##
    # Definition builder for building Ruby blocks.
    #
    class RubyBlock < Base
      ##
      # @return [RubyLint::Definition::RubyObject]
      #
      def build
        definition = new_definition([vm.current_scope])

        vm.current_scope.list(:lvar).each do |variable|
          definition.add_definition(variable)
        end

        return definition
      end

      ##
      # @param [Array] parents
      # @return [RubyLint::Definition::RubyObject]
      #
      def new_definition(parents)
        return Definition::RubyObject.new(
          :name           => 'block',
          :type           => :block,
          :parents        => parents,
          :instance_type  => vm.current_scope.instance_type,
          :update_parents => [:lvar, :ivar, :cvar, :gvar]
        )
      end
    end # RubyBlock
  end # DefinitionBuilder
end # RubyLint

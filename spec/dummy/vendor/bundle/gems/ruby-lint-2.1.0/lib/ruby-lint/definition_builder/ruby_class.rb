module RubyLint
  module DefinitionBuilder
    ##
    # Definition builder used for building Ruby classes.
    #
    class RubyClass < RubyModule
      ##
      # Called after creating a new instance of the class.
      #
      def after_initialize
        options[:parent] ||= vm.global_constant('Object')
      end

      ##
      # Builds the definition for a Ruby class.
      #
      # @see RubyLint::DefinitionBuilder::RubyModule#build
      #
      def build
        return new_definition([options[:parent], vm.current_scope])
      end
    end # RubyClass
  end # DefinitionBuilder
end # RubyLint

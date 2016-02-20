module RubyLint
  module DefinitionBuilder
    ##
    # Definition builder for building method definitions. Receivers should be
    # set from the outside (= the VM).
    #
    class RubyMethod < Base
      ##
      # Called after a new instance has been created.
      #
      def after_initialize
        @options[:type] ||= :instance_method
      end

      ##
      # Builds the definition for the method definition.
      #
      # @see #new_definition
      # @return [RubyLint::Definition::RubyMethod]
      #
      def build
        return new_definition([scope])
      end

      ##
      # Returns the scope to define the method in.
      #
      # @return [RubyLint::Definition::RubyObject]
      #
      def scope
        scope = vm.current_scope

        if has_receiver? and options[:receiver]
          scope = options[:receiver]
        end

        return scope
      end

      private

      ##
      # @return [String]
      #
      def method_name
        return node.children[name_index].to_s
      end

      ##
      # @param [Array] parents The parent definitions.
      # @return [RubyLint::Definition::RubyObject]
      #
      def new_definition(parents)
        type          = options[:type]
        instance_type = :instance

        # FIXME: setting the instance type of a method to a `class` is a bit of
        # a hack to ensure that class methods cause lookups inside them to be
        # performed on class level.
        if has_receiver? and options[:receiver].class?
          type          = :method
          instance_type = :class
        end

        return Definition::RubyMethod.new(
          :name          => method_name,
          :parents       => parents,
          :type          => type,
          :instance_type => instance_type,
          :visibility    => options[:visibility],
          :line          => node.line,
          :column        => node.column,
          :file          => node.file
        )
      end

      ##
      # @return [TrueClass|FalseClass]
      #
      def has_receiver?
        return node.type == :defs
      end

      ##
      # @return [Numeric]
      #
      def name_index
        return has_receiver? ? 1 : 0
      end
    end # RubyMethod
  end # DefinitionBuilder
end # RubyLint

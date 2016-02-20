module RubyLint
  module Analysis
    ##
    # Analysis class that checks for equality checks and adds warnings when
    # these always evaluate to false. An example of such a check is
    # `:hello == 'hello'`.
    #
    # This analysis class was added after a co-worker banged their head against
    # a wall after finding the following code:
    #
    #     if some_value.to_sym == "overall"
    #       # ...
    #     end
    #
    # This code would never evaluate to true. In the particular case this would
    # result in it never caching certain data.
    #
    class UselessEqualityChecks < Base
      register 'useless_equality_checks'

      ##
      # @param [RubyLint::AST::Node] node
      #
      def on_send(node)
        receiver, name, arg = *node

        return unless name == :==

        left_type  = node_type(receiver)
        right_type = node_type(arg)

        if skip_type?(left_type) or skip_type?(right_type)
          return
        end

        if left_type != right_type
          warning(
            "Comparing #{left_type} with #{right_type} evaluates to false",
            node
          )
        end
      end

      ##
      # Returns the type name for a given AST node.
      #
      # @param [RubyLint::AST::Node] node
      # @return [String]
      #
      def node_type(node)
        definition = vm.associations[node]
        type       = nil

        if definition
          type = definition_type(definition)
        end

        return type
      end

      ##
      # Returns the type name of the given definition.
      #
      # @param [RubyLint::Definition::RubyObject] object
      # @return [String]
      #
      def definition_type(object)
        name = nil

        # Built-in types such as Array.
        if object.ruby_class
          name = object.ruby_class

        # Variables
        elsif object.variable? and object.value
          name = definition_type(object.value)

        # Constants.
        elsif object.constant? and !object.name.empty?
          name = object.name
        end

        return name
      end

      ##
      # @param [String] type
      #
      def skip_type?(type)
        return !type || type == 'unknown'
      end
    end # UselessEqualityChecks
  end # Analysis
end # RubyLint

module RubyLint
  module MethodCall
    ##
    # The Alias class is used to evaluate the use of `alias` and
    # `alias_method`.
    #
    class Alias < Base
      ##
      # @see Base#evaluate
      #
      def evaluate(arguments, context, block = nil)
        if node.type == :alias and node.children[0].gvar?
          alias_gvar(arguments, context)
        else
          alias_sym(arguments, context)
        end
      end

      private

      ##
      # @see Base#evaluate
      #
      def alias_sym(arguments, context)
        method_type = context.method_call_type
        alias_name  = arguments[0].value.to_s
        source_name = arguments[1].value.to_s
        source      = context.lookup(method_type, source_name)

        context.add(method_type, alias_name, source) if source
      end

      ##
      # @see Base#evaluate
      #
      def alias_gvar(arguments, context)
        alias_name  = node.children[0].name
        source_name = node.children[1].name
        source      = context.lookup(:gvar, source_name)

        # Global variables should be added to the root scope.
        vm.definitions.add(:gvar, alias_name, source) if source
      end
    end # Alias
  end # MethodCall
end # RubyLint

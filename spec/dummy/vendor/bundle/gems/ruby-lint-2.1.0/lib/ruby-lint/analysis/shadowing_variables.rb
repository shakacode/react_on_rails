module RubyLint
  module Analysis
    ##
    # The ShadowingVariables class checks for the use of variables in a block
    # that shadow outer variables. "Shadowing" means that a variable is used
    # with the same name as a variable in the surrounding scope. A simple
    # example:
    #
    #     number = 10
    #
    #     [10, 20, 30].each do |number|
    #       puts number # `number` is being shadowed
    #     end
    #
    class ShadowingVariables < Base
      register 'shadowing_variables'

      ##
      # @param [RubyLint::AST::Node] node
      #
      def on_block(node)
        arguments = node.children[1].children

        arguments.each do |arg|
          validate_argument(arg)
        end

        super
      end

      private

      ##
      # @param [RubyLint::AST::Node] node
      #
      def validate_argument(node)
        if current_scope.has_definition?(:lvar, node.name)
          warning("shadowing outer local variable #{node.name}", node)
        end
      end
    end # ShadowingVariables
  end # Analysis
end # RubyLint

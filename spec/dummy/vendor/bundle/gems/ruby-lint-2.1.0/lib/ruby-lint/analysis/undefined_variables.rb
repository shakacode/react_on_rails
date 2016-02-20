module RubyLint
  module Analysis
    ##
    # The UndefinedVariables class checks for the use of undefined variables
    # (such as instance variables and constants). The order of definition and
    # use of a variable does not matter.
    #
    # This analysis class does *not* check for undefined local variables. Ruby
    # treats these as method calls and as result they are handled by
    # {RubyLint::Analysis::UndefinedMethods} instead.
    #
    class UndefinedVariables < Base
      register 'undefined_variables'

      ##
      # Hash containing the various variable types to add errors for whenever
      # they are used but not defined.
      #
      # @return [Hash]
      #
      VARIABLE_TYPES = {
        :gvar  => 'global variable',
        :ivar  => 'instance variable',
        :cvar  => 'class variable'
      }

      VARIABLE_TYPES.each do |type, label|
        define_method("on_#{type}") do |node|
          unless current_scope.has_definition?(type, node.name)
            error("undefined #{label} #{node.name}", node)
          end
        end
      end

      ##
      # Handles regular constants as well as constant paths.
      #
      # @param [RubyLint::AST::Node] node
      #
      def on_const(node)
        path     = ConstantPath.new(node)
        variable = path.resolve(current_scope)
        name     = path.to_s

        error("undefined constant #{name}", node) unless variable
      end
    end # UndefinedVariables
  end # Analysis
end # RubyLint

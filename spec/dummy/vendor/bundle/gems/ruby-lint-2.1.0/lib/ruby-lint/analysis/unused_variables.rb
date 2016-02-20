module RubyLint
  module Analysis
    ##
    # The UnusedVariables class checks for variables that are defined but never
    # used. Whenever it finds one of these variables it will add a
    # corresponding warning message.
    #
    class UnusedVariables < Base
      register 'unused_variables'

      ##
      # Hash containing the various variable types for which to add warnings
      # and human readable names for these types.
      #
      # @return [Hash]
      #
      VARIABLE_TYPES = {
        :lvasgn => 'local variable',
        :gvasgn => 'global variable',
        :cvasgn => 'class variable'
      }

      VARIABLE_TYPES.each do |type, label|
        define_method("on_#{type}") do |node|
          type     = VirtualMachine::ASSIGNMENT_TYPES[node.type]
          variable = current_scope.lookup(type, node.name)

          if add_warning?(variable)
            warning("unused #{label} #{variable.name}", node)
          end
        end
      end

      ##
      # @param [RubyLint::AST::Node] node
      #
      def on_ivasgn(node)
        name        = node.name
        variable    = current_scope.lookup(:ivar, name)
        method_type = current_scope.method_call_type
        getter      = current_scope.lookup(method_type, name[1..-1])

        if variable and !variable.used? and !getter
          warning("unused instance variable #{name}", node)
        end
      end

      ##
      # Handles regular constants as well as constant paths.
      #
      # @param [RubyLint::AST::Node] node
      #
      def on_casgn(node)
        path     = ConstantPath.new(node)
        variable = path.resolve(current_scope)
        name     = path.to_s

        if variable and !variable.used?
          warning("unused constant #{name}", node)
        end
      end

      VirtualMachine::ARGUMENT_TYPES.each do |name|
        define_method("on_#{name}") { |node| verify_argument(node) }
      end

      private

      ##
      # Adds warnings for unused method arguments.
      #
      # @param [RubyLint::AST::Node] node
      #
      def verify_argument(node)
        variable = current_scope.lookup(:lvar, node.name)

        if add_warning?(variable)
          warning("unused argument #{variable.name}", node)
        end
      end

      ##
      # @param [RubyLint::Definition::RubyObject] variable
      # @return [TrueClass|FalseClass]
      #
      def add_warning?(variable)
        return variable && !variable.used? && !ignore_variable?(variable.name)
      end

      ##
      # @param [String] name
      # @return [TrueClass|FalseClass]
      #
      def ignore_variable?(name)
        return name[0] == '_' || name.empty?
      end
    end # UnusedVariables
  end # Analysis
end # RubyLint

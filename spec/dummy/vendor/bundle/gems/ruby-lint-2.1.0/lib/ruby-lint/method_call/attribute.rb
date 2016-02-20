module RubyLint
  module MethodCall
    ##
    # The Attribute class is used for evaluating method calls to `attr`,
    # `attr_reader` and similar methods.
    #
    class Attribute < Base
      ##
      # @see Base#evaluate
      #
      def evaluate(arguments, context, block = nil)
        method = "evaluate_#{node.children[1]}"

        send(method, arguments, context)
      end

      private

      ##
      # Evaluates a call to `attr`. The `attr` method can be used in two
      # different ways (thank you Ruby for being consistent):
      #
      # 1. `attr [NAME], [TRUE|FALSE]`
      # 2. `attr [NAME], [NAME], etc
      #
      # @see #evaluate
      #
      def evaluate_attr(arguments, context)
        if arguments[1] and arguments[1].type == :true
          names = [arguments[0].value.to_s, arguments[0].value.to_s + '=']
        else
          names = arguments.map { |arg| arg.value.to_s }
        end

        names.each do |name|
          define_attribute(name, context)
        end
      end

      ##
      # Evaluates method calls to `attr_reader`.
      #
      # @see #evaluate
      #
      def evaluate_attr_reader(arguments, context)
        arguments.each do |arg|
          define_attribute(arg.value.to_s, context)
        end
      end

      ##
      # Evaluates method calls to `attr_writer`.
      #
      # @see #evaluate
      #
      def evaluate_attr_writer(arguments, context)
        arguments.each do |arg|
          define_attribute(arg.value.to_s, context, true)
        end
      end

      ##
      # Evaluates method calls to `attr_accessor`.
      #
      # @see #evaluate
      #
      def evaluate_attr_accessor(arguments, context)
        arguments.each do |arg|
          name = arg.value.to_s

          define_attribute(name, context)
          define_attribute(name, context, true)
        end
      end

      ##
      # @param [String] name
      # @param [RubyLint::Definition::RubyObject] context
      # @param [TrueClass|FalseClass] setter
      #
      def define_attribute(name, context, setter = false)
        ivar_name = '@' + name

        if setter
          name = name + '='
        end

        context.define_instance_method(name) do |method|
          method.define_argument('value') if setter
        end

        unless context.has_definition?(:ivar, ivar_name)
          ivar = Definition::RubyObject.new(
            :type             => :ivar,
            :name             => ivar_name,
            :reference_amount => 1
          )

          context.add_definition(ivar)
        end
      end
    end # Attribute
  end # MethodCall
end # RubyLint

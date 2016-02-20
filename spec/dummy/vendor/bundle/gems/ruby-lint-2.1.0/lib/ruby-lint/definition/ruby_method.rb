module RubyLint
  module Definition
    ##
    # The RubyMethod definition class is a definition class used for storing
    # information about Ruby methods (both class and instance methods).
    #
    # @see RubyLint::Definition::RubyObject
    #
    # @!attribute [r] visibility
    #  @return [Symbol] The method visibility such as `:public`.
    #
    # @!attribute [r] return_value
    #  @return [Mixed] The value that is returned by the method.
    #
    # @!attribute [r] calls
    #  @return [Array<RubyLint::MethodCallInfo>] The method calls made in the
    #   body of this method.
    #
    # @!attribute [r] callers
    #  @return [Array<RubyLint::MethodCallInfo>] The methods that called this
    #   method.
    #
    class RubyMethod < RubyObject
      attr_reader :calls, :callers, :return_value, :visibility

      ##
      # Called after a new instance of this class is created.
      #
      def after_initialize
        @calls   = []
        @callers = []
      end

      ##
      # @return [Array]
      #
      def arguments
        return list(:arg)
      end

      ##
      # @return [RubyLint::Definition::RubyObject]
      #
      def block_argument
        return list(:blockarg).first
      end

      ##
      # @return [Array]
      #
      def keyword_arguments
        return list(:kwoptarg)
      end

      ##
      # @return [Array]
      #
      def optional_arguments
        return list(:optarg)
      end

      ##
      # @return [RubyLint::Definition::RubyObject]
      #
      def rest_argument
        return list(:restarg).first
      end

      ##
      # Sets the return value of this method. If a block is given it will be
      # used as the return value. The block is *not* evaluated until it's
      # called.
      #
      # @example
      #  string.define_instance_method(:gsub) do |method|
      #    method.returns('...')
      #  end
      #
      # @param [Mixed] value
      #
      def returns(value = nil, &block)
        @return_value = block_given? ? block : value
      end

      ##
      # Defines a required argument for the method.
      #
      # @example
      #  method.define_argument('number')
      #
      # @param [String] name The name of the argument.
      #
      def define_argument(name)
        create_argument(:arg, name)
      end

      ##
      # Defines a keyword argument for the method.
      #
      # @see RubyLint::Definition::RubyObject#define_argument
      #
      def define_keyword_argument(name)
        create_argument(:kwoptarg, name)
      end

      ##
      # Defines a optional argument for the method.
      #
      # @see RubyLint::Definition::RubyObject#define_argument
      #
      def define_optional_argument(name)
        create_argument(:optarg, name)
      end

      ##
      # Defines a rest argument for the method.
      #
      # @see RubyLint::Definition::RubyObject#define_argument
      #
      def define_rest_argument(name)
        create_argument(:restarg, name)
      end

      ##
      # Defines a block argument for the method.
      #
      # @see RubyLint::Definition::RubyObject#define_argument
      #
      def define_block_argument(name)
        create_argument(:blockarg, name)
      end

      private

      ##
      # Adds a new argument to the method as well as adding it as a local
      # variable. Note that although the argument's variable is saved under a
      # argument key (e.g. `:arg`) the actual definition type is set to
      # `:lvar`.
      #
      # @param [Symbol] type The type of argument.
      # @param [String] name The name of the argument.
      #
      # @return [RubyLint::Definition::RubyObject]
      #
      def create_argument(type, name)
        argument = RubyObject.new(:type => :lvar, :name => name)

        add(argument.type, argument.name, argument)
        add(type, argument.name, argument)

        return argument
      end
    end # RubyMethod
  end # Definition
end # RubyLint

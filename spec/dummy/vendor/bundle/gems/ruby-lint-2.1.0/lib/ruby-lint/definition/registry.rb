module RubyLint
  module Definition
    ##
    # The Registry class is used to register and store definitions that have
    # to be applied to instances of {RubyLint::VirtualMachine}. It can also be
    # used to load constant definition files from a custom load path.
    #
    # @!attribute [r] load_path
    #  @return [Array] List of directories to search in for definitions.
    #
    # @!attribute [r] loaded_constants
    #  @return [Set] Set containing the constants loaded from the load path.
    #
    # @!attribute [r] registered
    #  @return [Hash] Returns the registered definitions as a Hash. The keys
    #   are set to the constant names, the values to `Proc` instances that,
    #   when evaluated, create the corresponding definitions.
    #
    class Registry
      attr_reader :load_path, :loaded_constants, :registered

      ##
      # The default load path to use.
      #
      # @return [Array]
      #
      DEFAULT_LOAD_PATH = [
        File.expand_path('../../definitions/core', __FILE__),
        File.expand_path('../../definitions/rails', __FILE__),
        File.expand_path('../../definitions/gems', __FILE__)
      ]

      def initialize
        @registered       = {}
        @load_path        = DEFAULT_LOAD_PATH.dup
        @loaded_constants = Set.new
      end

      ##
      # Registers a new definition with the given name.
      #
      # @param [String] name The name of the constant.
      #
      def register(name, &block)
        registered[name] = block
      end

      ##
      # Gets the constant with the given name.
      #
      # @param [String] constant
      # @raise [ArgumentError] Raised if the given constant doesn't exist.
      #
      def get(constant)
        found = registered[constant]

        if found
          return found
        else
          raise ArgumentError, "The constant #{constant} does not exist"
        end
      end

      ##
      # Returns `true` if the given constant has been registered.
      #
      # @param [String] constant
      # @return [TrueClass|FalseClass]
      #
      def include?(constant)
        return registered.key?(constant) || loaded_constants.include?(constant)
      end

      ##
      # Applies the definitions of a given name to the given
      # {RubyLint::Definition::RubyObject} instance.
      #
      # @param [String] constant
      # @param [RubyLint::Definition::RubyObject] definitions
      #
      def apply(constant, definitions)
        unless definitions.defines?(:const, constant)
          get(constant).call(definitions)
        end
      end

      ##
      # Tries to find a definition in the current load path and loads it if
      # found.
      #
      # @param [String] constant The name of the top level constant.
      #
      def load(constant)
        return if include?(constant)

        filename = file_for_constant(constant)

        load_path.each do |dir|
          filepath = File.join(dir, filename)

          if File.file?(filepath)
            require(filepath)

            # Only update the path if we actually found the right constant
            # file.
            if registered.key?(constant)
              loaded_constants << constant
            end

            break
          end
        end
      end

      private

      ##
      # @param [String] constant
      # @return [String]
      #
      def file_for_constant(constant)
        return constant.snake_case + '.rb'
      end
    end # Registry
  end # Definition
end # RubyLint

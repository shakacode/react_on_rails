module RubyLint
  module Definition
    ##
    # {RubyLint::Definition::ConstantProxy} is a proxy class for constant
    # definitions. The primary use case for this class is inheriting constants
    # in the pre-generated definitions found in the definitions directory. By
    # using this class when creating definitions the load order doesn't matter,
    # as long as the data is there at some point in time.
    #
    # @!attribute [r] proxy_source
    #  @return [RubyLint::Definition::RubyObject]
    #
    # @!attribute [r] proxy_name
    #  @return [String]
    #
    # @!attribute [r] registry
    #  @return [RubyLint::Definition::Registry]
    #
    # @!attribute [r] proxy_definition
    #  @return [RubyLint::Definition::RubyObject]
    #
    class ConstantProxy
      include VariablePredicates

      attr_reader :proxy_source, :proxy_name, :proxy_definition, :registry

      ##
      # @param [RubyLint::Definition::RubyObject] source The source definition
      #  to use for looking up the definition associated with the current
      #  proxy.
      #
      # @param [String] name The name/constant path of the constant that this
      #  proxy belongs to.
      #
      # @param [RubyLint::Registry] registry The registry to use when trying
      #  to autoload a constant.
      #
      def initialize(source, name, registry = nil)
        @proxy_source = source
        @proxy_name   = name
        @registry     = registry
      end

      # Pre-define all the methods of the definition, this is faster than
      # having to rely on method_missing.
      RubyObject.instance_methods(false).each do |method|
        define_method(method) do |*args, &block|
          lookup_proxy_definition

          proxy_definition.send(method, *args, &block) if proxy_definition
        end
      end

      ##
      # @return [String]
      #
      def inspect
        lookup_proxy_definition

        return proxy_definition ? proxy_definition.inspect : super
      end

      private

      ##
      # Looks up the associated definition and stores it if it exists.
      #
      def lookup_proxy_definition
        return if proxy_definition

        found = lookup_constant
        root  = root_constant

        if !found and use_registry?(root)
          registry.apply(root, proxy_source)

          found = lookup_constant
        end

        @proxy_definition = found
      end

      ##
      # @param [String] constant
      # @return [TrueClass|FalseClass]
      #
      def use_registry?(constant)
        return false unless registry

        # Don't load the constant if we already have it.
        return true if registry.include?(constant)

        registry.load(constant)

        return registry.include?(constant)
      end

      ##
      # @return [String]
      #
      def root_constant
        return proxy_name.split(RubyObject::PATH_SEPARATOR)[0]
      end

      ##
      # @return [RubyLint::Definition::RubyObject]
      #
      def lookup_constant
        return proxy_source.lookup_constant_path(proxy_name)
      end
    end # ConstantProxy
  end # Definition
end # RubyLint

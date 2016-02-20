module RubyLint
  ##
  # The Inspector class is a debugging related class primarily used for making
  # it easy to display a list of methods/constants of a given source constant.
  #
  # Note that this class is considered to be a private API and as such may
  # change without any notice.
  #
  # @!attribute [r] constant
  #  @return [Class]
  #
  # @!attribute [r] constant_name
  #  @return [String]
  #
  class Inspector
    attr_reader :constant, :constant_name

    ##
    # @param [String|Class] constant
    #
    def initialize(constant)
      @constant_name = constant.to_s

      if constant.is_a?(String)
        @constant = resolve_constant(constant)
      else
        @constant = constant
      end
    end

    ##
    # Returns an Array containing all constants and their child constants
    # (recursively).
    #
    # @param [Class] source
    # @param [Array] ignore
    # @return [Array<String>]
    #
    def inspect_constants(source = constant, ignore = [])
      names          = []
      source_name    = source.name
      have_children  = []
      include_source = source != Object

      if include_source and !ignore.include?(source_name)
        names  << source_name
        ignore << source_name
      end

      source.constants.each do |name|
        next if skip_constant?(source, name)

        full_name = include_source ? "#{source_name}::#{name}" : name.to_s

        # In certain cases this code tries to load a constant that apparently
        # *is* defined but craps out upon error (e.g. Bundler::Specification).
        begin
          constant = source.const_get(name)
        rescue Exception => error
          warn error.message
          next
        end

        # Skip those that we've already processed.
        if ignore.include?(full_name) or source == constant
          next
        end

        names         << full_name
        ignore        << full_name
        have_children << constant if process_child_constants?(constant)
      end

      have_children.each do |const|
        names |= inspect_constants(const, ignore)
      end

      # Reject every constant that, if we should include the source name, was
      # not defined under that constant. This applies on for example Rubinius
      # since `Range::Enumerator` is a constant that points to
      # `Enumerable::Enumerator`.
      if include_source
        names = names.select { |name| name.start_with?(source_name) }
      end

      return names
    end

    ##
    # Returns an Array containing all method objects sorted by their names.
    #
    # @return [Array]
    #
    def inspect_methods
      return [] unless constant.respond_to?(:methods)

      methods = get_methods.map do |name|
        method_information(:method, name)
      end

      return methods.sort_by(&:name)
    end

    ##
    # Returns an Array containing all instance methods sorted by their names.
    #
    # @return [Array]
    #
    def inspect_instance_methods
      return [] unless constant.respond_to?(:instance_methods)

      methods = get_methods(:instance_methods).map do |name|
        method_information(:instance_method, name)
      end

      return methods.sort_by(&:name)
    end

    ##
    # Returns the modules that are included in the constant.
    #
    # @return [Array]
    #
    def inspect_modules
      modules = []

      if constant.respond_to?(:ancestors)
        parent = inspect_superclass

        # Take all the modules included *directly* into the constant.
        modules = constant.ancestors.take_while do |ancestor|
          parent && ancestor != parent
        end

        # Get rid of non Module instances and modules that don't have a name.
        modules = modules.select do |mod|
          mod.instance_of?(Module) && mod.name
        end
      end

      return modules
    end

    ##
    # Returns the superclass of the current constant or `nil` if there is none.
    #
    # @return [Mixed]
    #
    def inspect_superclass
      parent = nil

      if constant.respond_to?(:superclass) \
      and constant.superclass \
      and constant.superclass.name
        return constant.superclass
      end

      return parent
    end

    ##
    # Gets the methods of the current constant minus those defined in Object.
    #
    # @param [Symbol] getter
    # @return [Array]
    #
    def get_methods(getter = :methods)
      parent = inspect_superclass || Object
      diff   = constant.__send__(getter, false) -
        parent.__send__(getter, false)

      methods = diff | constant.__send__(getter, false)

      # If the constant manually defines the initialize method (= private)
      # we'll also want to include it.
      if include_initialize?(getter)
        methods = methods | [:initialize]
      end

      return methods
    end

    private

    ##
    # @param [Symbol] getter
    # @return [TrueClass|FalseClass]
    #
    def include_initialize?(getter)
      return getter == :instance_methods \
        && constant.is_a?(Class) \
        && constant.private_instance_methods(false).include?(:initialize) \
        && constant.instance_method(:initialize).source_location
    end

    ##
    # @param [Module|Class] const
    # @param [Symbol] child_name
    # @return [TrueClass|FalseClass]
    #
    def skip_constant?(const, child_name)
      # Module and Class defines the same child constants as Object but in a
      # recursive manner. This is a bit of a dirty way to prevent this code
      # from going into an infinite loop.
      if const == Module or const == Class
        return true
      end

      # Config is deprecated and triggers a warning.
      if const == Object and child_name == :Config
        return true
      end

      return !const.const_defined?(child_name)
    end

    ##
    # @param [Class] constant
    # @return [TrueClass|FalseClass]
    #
    def process_child_constants?(constant)
      return constant.respond_to?(:constants) && !constant.constants.empty?
    end

    ##
    # Returns the method object for the given type and name.
    #
    # @param [Symbol] type
    # @param [Symbol] name
    # @return [UnboundMethod]
    #
    def method_information(type, name)
      return constant.__send__(type, name)
    end

    ##
    # Converts a String based constant path into an actual constant.
    #
    # @param [String] constant
    # @return [Class]
    # @raise [ArgumentError] Raised when one of the segments doesn't exist.
    #
    def resolve_constant(constant)
      current = Object
      final   = nil

      constant.split('::').each do |segment|
        if current.const_defined?(segment)
          current = final = current.const_get(segment)
        else
          raise(
            ArgumentError,
            "Constant #{segment} does not exist in #{constant}"
          )
        end
      end

      return final
    end
  end # Inspector
end # RubyLint

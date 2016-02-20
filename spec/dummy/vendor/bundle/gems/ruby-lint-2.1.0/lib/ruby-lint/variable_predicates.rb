module RubyLint
  ##
  # Module that provides various predicate methods for checking node/definition
  # types.
  #
  module VariablePredicates
    ##
    # Array containing various predicate methods to create.
    #
    # @return [Array]
    #
    PREDICATE_METHODS = [
      :array, :class, :const, :hash, :module, :self, :block, :gvar
    ]

    ##
    # Hash containing various Node types and the associated Ruby classes.
    #
    # @return [Hash]
    #
    RUBY_CLASSES = {
      :str    => 'String',
      :sym    => 'Symbol',
      :int    => 'Fixnum',
      :float  => 'Float',
      :regexp => 'Regexp',
      :array  => 'Array',
      :hash   => 'Hash',
      :irange => 'Range',
      :erange => 'Range',
      :lambda => 'Proc',
      :true   => 'TrueClass',
      :false  => 'FalseClass',
      :nil    => 'NilClass'
    }

    ##
    # List of variable types used in {#variable?}.
    #
    # @return [Array]
    #
    VARIABLE_TYPES = [:lvar, :ivar, :cvar, :gvar]

    PREDICATE_METHODS.each do |method|
      define_method("#{method}?") do
        return type == method
      end
    end

    ##
    # @return [TrueClass|FalseClass]
    #
    def constant?
      return type == :const || type == :module || type == :class
    end

    ##
    # @return [TrueClass|FalseClass]
    #
    def constant_path?
      return constant? && children[0].constant?
    end

    ##
    # @return [String]
    #
    def ruby_class
      return RUBY_CLASSES[type]
    end

    ##
    # @return [TrueClass|FalseClass]
    #
    def variable?
      return VARIABLE_TYPES.include?(type)
    end
  end # VariablePredicates
end # RubyLint

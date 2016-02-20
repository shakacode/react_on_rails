module RubyLint
  ##
  # {RubyLint::GeneratedConstant} contains information about a constant (and
  # its data) that was pre-generated using {RubyLint::DefinitionGenerator}.
  #
  # @!attribute [r] methods
  #  @return [Hash]
  #
  # @!attribute [r] name
  #  @return [String]
  #
  # @!attribute [r] constant
  #  @return [Class]
  #
  # @!attribute [r] superclass
  #  @return [String]
  #
  # @!attribute [r] modules
  #  @return [Array]
  #
  class GeneratedConstant
    attr_reader :methods, :name, :constant, :superclass, :modules

    ##
    # @param [Hash] attributes
    #
    def initialize(attributes = {})
      attributes.each do |key, value|
        instance_variable_set("@#{key}", value)
      end

      @modules    ||= []
      @methods    ||= []
      @superclass ||= 'Object'
    end
  end # GeneratedConstant
end # RubyLint

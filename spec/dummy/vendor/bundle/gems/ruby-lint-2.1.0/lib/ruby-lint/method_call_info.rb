module RubyLint
  ##
  # The MethodCallInfo class stores basic information about method calls such
  # as the definition of the method and location information of the method
  # call.
  #
  # @!attribute [r] definition
  #  @return [RubyLint::Definition::RubyMethod]
  #
  # @!attribute [r] line
  #  @return [Numeric] The line of the method call.
  #
  # @!attribute [r] column
  #  @return [Numeric] The column of the method call.
  #
  # @!attribute [r] file
  #  @return [String] The file of the method call.
  #
  class MethodCallInfo
    attr_reader :definition, :line, :column, :file

    ##
    # @param [Hash] options
    #
    def initialize(options = {})
      options.each do |key, value|
        instance_variable_set("@#{key}", value) if respond_to?(key)
      end
    end
  end # MethodCallInfo
end # RubyLint

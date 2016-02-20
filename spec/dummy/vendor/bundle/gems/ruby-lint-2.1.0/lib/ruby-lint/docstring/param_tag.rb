module RubyLint
  module Docstring
    ##
    # The ParamTag class contains information about YARD `@param` tags such as
    # the types of the parameter.
    #
    # @!attribute [r] name
    #  @return [String]
    #
    # @!attribute [r] types
    #  @return [Array]
    #
    # @!attribute [r] description
    #  @return [String]
    #
    class ParamTag
      attr_reader :name, :types, :description

      ##
      # @param [Hash] options
      #
      def initialize(options = {})
        @name        = options[:name]
        @types       = options[:types] || []
        @description = options[:description]
      end
    end # ParamTag
  end # Docstring
end # RubyLint

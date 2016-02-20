module RubyLint
  module Docstring
    ##
    # The ReturnTag class contains information about a YARD `@return` tag.
    #
    # @!attribute [r] types
    #  @return [Array]
    #
    # @!attribute [r] description
    #  @return [String]
    #
    class ReturnTag
      attr_reader :types, :description

      ##
      # @param [Hash] options
      #
      def initialize(options = {})
        @types       = options[:types] || []
        @description = options[:description]
      end
    end # ReturnTag
  end # Docstring
end # RubyLint

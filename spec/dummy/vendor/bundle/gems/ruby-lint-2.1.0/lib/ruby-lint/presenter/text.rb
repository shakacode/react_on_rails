module RubyLint
  module Presenter
    ##
    # {RubyLint::Presenter::Text} formats a instance of {RubyLint::Report} into
    # a text based, human readable format.
    #
    class Text < Base
      register 'text'

      ##
      # The default format to use when presenting report entries.
      #
      # @return [String]
      #
      FORMAT = '%{filename}: %{level}: line %{line}, column %{column}: ' \
        '%{message}'

      ##
      # @param [String] format The format to use for each entry.
      #
      def initialize(format = FORMAT.dup)
        @format = format
      end

      ##
      # @param [RubyLint::Report] report The report to present.
      # @return [String]
      #
      def present(report)
        entries = []

        report.entries.sort.each do |entry|
          entries << @format % entry.attributes
        end

        return entries.join("\n")
      end
    end # Text
  end # Presenter
end # RubyLint

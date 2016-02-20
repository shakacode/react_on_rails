module RubyLint
  module Presenter
    ##
    # Presenter that formats output that can be easily used in Syntastic
    # plugins.
    #
    class Syntastic < Base
      register 'syntastic'

      ##
      # The format to use for each entry.
      #
      # @return [String]
      #
      FORMAT = '%{file}:%{level}:%{line}:%{column}: %{message}'

      ##
      # @param [String] format
      #
      def initialize(format = FORMAT.dup)
        @format = format
      end

      ##
      # @param [RubyLint::Report] report
      # @return [String]
      #
      def present(report)
        entries = []

        report.entries.sort.each do |entry|
          attributes         = entry.attributes
          attributes[:level] = attributes[:level][0].upcase

          entries << @format % attributes
        end

        return entries.join("\n")
      end
    end # Syntastic
  end # Presenter
end # RubyLint

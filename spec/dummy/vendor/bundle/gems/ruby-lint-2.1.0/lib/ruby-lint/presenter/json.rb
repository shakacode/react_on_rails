module RubyLint
  module Presenter
    ##
    # {RubyLint::Presenter::JSON} formats a instance of {RubyLint::Report} into
    # a JSON formatted string.
    #
    class JSON < Base
      register 'json'

      ##
      # @param [RubyLint::Report] report The report to present.
      # @return [String]
      #
      def present(report)
        require 'json'

        return report.entries.sort.map(&:attributes).to_json
      end
    end # Text
  end # Presenter
end # RubyLint

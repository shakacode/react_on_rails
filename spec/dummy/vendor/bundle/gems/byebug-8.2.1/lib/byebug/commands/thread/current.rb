require 'byebug/helpers/thread'

module Byebug
  #
  # Reopens the +thread+ command to define the +current+ subcommand
  #
  class ThreadCommand < Command
    #
    # Information about the current thread
    #
    class CurrentCommand < Command
      include Helpers::ThreadHelper

      def self.regexp
        /^\s* c(?:urrent)? \s*$/x
      end

      def self.description
        <<-EOD
          th[read] c[urrent]

          #{short_description}
        EOD
      end

      def self.short_description
        'Shows current thread information'
      end

      def execute
        display_context(context)
      end
    end
  end
end

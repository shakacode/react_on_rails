require 'byebug/helpers/toggle'

module Byebug
  #
  # Reopens the +enable+ command to define the +breakpoints+ subcommand
  #
  class EnableCommand < Command
    #
    # Enables all or specific breakpoints
    #
    class BreakpointsCommand < Command
      include Helpers::ToggleHelper

      self.allow_in_post_mortem = true

      def self.regexp
        /^\s* b(?:reakpoints)? (?:\s+ (.+))? \s*$/x
      end

      def self.description
        <<-EOD
          en[able] b[reakpoints][ <ids>]

          #{short_description}

          Give breakpoint numbers (separated by spaces) as arguments or no
          argument at all if you want to enable every breakpoint.
        EOD
      end

      def self.short_description
        'Disable all or specific breakpoints'
      end

      def execute
        enable_disable_breakpoints('enable', @match[1])
      end
    end
  end
end

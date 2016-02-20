require 'byebug/subcommands'

require 'byebug/commands/disable/breakpoints'
require 'byebug/commands/disable/display'

module Byebug
  #
  # Disabling custom display expressions or breakpoints.
  #
  class DisableCommand < Command
    include Subcommands

    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* dis(?:able)? (?:\s+ (.+))? \s*$/x
    end

    def self.description
      <<-EOD
        dis[able][[ breakpoints| display)][ n1[ n2[ ...[ nn]]]]]

        #{short_description}
       EOD
    end

    def self.short_description
      'Disables breakpoints or displays'
    end
  end
end

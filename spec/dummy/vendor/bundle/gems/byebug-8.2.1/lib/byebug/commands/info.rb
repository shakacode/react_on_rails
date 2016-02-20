require 'byebug/subcommands'

require 'byebug/commands/info/breakpoints'
require 'byebug/commands/info/display'
require 'byebug/commands/info/file'
require 'byebug/commands/info/line'
require 'byebug/commands/info/program'

module Byebug
  #
  # Shows info about different aspects of the debugger.
  #
  class InfoCommand < Command
    include Subcommands

    self.allow_in_control = true
    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* i(?:nfo)? (?:\s+ (.+))? \s*$/x
    end

    def self.description
      <<-EOD
        info[ subcommand]

        #{short_description}
      EOD
    end

    def self.short_description
      'Shows several informations about the program being debugged'
    end
  end
end

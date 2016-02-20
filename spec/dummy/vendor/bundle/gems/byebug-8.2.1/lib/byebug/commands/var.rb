require 'byebug/subcommands'

require 'byebug/commands/var/all'
require 'byebug/commands/var/args'
require 'byebug/commands/var/const'
require 'byebug/commands/var/instance'
require 'byebug/commands/var/local'
require 'byebug/commands/var/global'

module Byebug
  #
  # Shows variables and its values
  #
  class VarCommand < Command
    include Subcommands

    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* v(?:ar)? (?:\s+ (.+))? \s*$/x
    end

    def self.description
      <<-EOD
        [v]ar <subcommand>

        #{short_description}
      EOD
    end

    def self.short_description
      'Shows variables and its values'
    end
  end
end

require 'byebug/command'
require 'byebug/helpers/path'
require 'shellwords'

module Byebug
  #
  # Restart debugged program from within byebug.
  #
  class RestartCommand < Command
    include Helpers::PathHelper

    self.allow_in_control = true
    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* restart (?:\s+(?<args>.+))? \s*$/x
    end

    def self.description
      <<-EOD
        restart [args]

        #{short_description}

        This is a re-exec - all byebug state is lost. If command arguments are
        passed those are used.
      EOD
    end

    def self.short_description
      'Restarts the debugged program'
    end

    def execute
      argv = [$PROGRAM_NAME]

      argv.unshift(bin_file) if Byebug.mode == :standalone

      argv += (@match[:args] ? @match[:args].shellsplit : $ARGV.compact)

      puts pr('restart.success', cmd: argv.shelljoin)
      exec(*argv)
    end
  end
end

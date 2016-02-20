require 'byebug/command'

module Byebug
  #
  # Send custom signals to the debugged program.
  #
  class KillCommand < Command
    self.allow_in_control = true

    def self.regexp
      /^\s* (?:kill) \s* (?:\s+(\S+))? \s*$/x
    end

    def self.description
      <<-EOD
        kill[ signal]

        #{short_description}

        Equivalent of Process.kill(Process.pid)
      EOD
    end

    def self.short_description
      'Sends a signal to the current process'
    end

    def execute
      if @match[1]
        signame = @match[1]

        unless Signal.list.member?(signame)
          return errmsg("signal name #{signame} is not a signal I know about\n")
        end
      else
        return unless confirm('Really kill? (y/n) ')

        signame = 'KILL'
      end

      processor.interface.close if 'KILL' == signame
      Process.kill(signame, Process.pid)
    end
  end
end

require 'byebug/command'
require 'byebug/helpers/parse'

module Byebug
  #
  # Implements the continue command.
  #
  # Allows the user to continue execution until the next stopping point, a
  # specific line number or until program termination.
  #
  class ContinueCommand < Command
    include Helpers::ParseHelper

    def self.regexp
      /^\s* c(?:ont(?:inue)?)? (?:\s+(\S+))? \s*$/x
    end

    def self.description
      <<-EOD
        c[ont[inue]][ <line_number>]

        #{short_description}
      EOD
    end

    def self.short_description
      'Runs until program ends, hits a breakpoint or reaches a line'
    end

    def execute
      if @match[1]
        num, err = get_int(@match[1], 'Continue', 0, nil)
        return errmsg(err) unless num

        filename = File.expand_path(frame.file)
        unless Breakpoint.potential_line?(filename, num)
          return errmsg(pr('continue.errors.unstopped_line', line: num))
        end

        Breakpoint.add(filename, num)
      end

      processor.proceed!

      Byebug.stop if Byebug.stoppable?
    end
  end
end

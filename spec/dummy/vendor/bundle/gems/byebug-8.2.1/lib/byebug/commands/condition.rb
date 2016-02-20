require 'byebug/command'
require 'byebug/helpers/parse'

module Byebug
  #
  # Implements conditions on breakpoints.
  #
  # Adds the ability to stop on breakpoints only under certain conditions.
  #
  class ConditionCommand < Command
    include Helpers::ParseHelper

    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* cond(?:ition)? (?:\s+(\d+)(?:\s+(.*))?)? \s*$/x
    end

    def self.description
      <<-EOD
        cond[ition] <n>[ expr]

        #{short_description}

        Specify breakpoint number <n> to break only if <expr> is true. <n> is
        an integer and <expr> is an expression to be evaluated whenever
        breakpoint <n> is reached. If no expression is specified, the condition
        is removed.
      EOD
    end

    def self.short_description
      'Sets conditions on breakpoints'
    end

    def execute
      return puts(help) unless @match[1]

      breakpoints = Byebug.breakpoints.sort_by(&:id)
      return errmsg(pr('condition.errors.no_breakpoints')) if breakpoints.empty?

      pos, err = get_int(@match[1], 'Condition', 1)
      return errmsg(err) if err

      breakpoint = breakpoints.find { |b| b.id == pos }
      return errmsg(pr('break.errors.no_breakpoint')) unless breakpoint

      unless syntax_valid?(@match[2])
        return errmsg(pr('break.errors.not_changed', expr: @match[2]))
      end

      breakpoint.expr = @match[2]
    end
  end
end

begin
  require 'io/console'
rescue LoadError
end

module Tins
  module Terminal

    module_function

    def winsize
      if IO.respond_to?(:console)
        console = IO.console
        if console.respond_to?(:winsize)
          console.winsize
        else
          []
        end
      else
        []
      end
    end


    def rows
      winsize[0] || `stty size 2>/dev/null`.split[0].to_i.nonzero? ||
        `tput lines 2>/dev/null`.to_i.nonzero? || 25
    end

    def lines
      rows
    end

    def columns
      winsize[1] || `stty size 2>/dev/null`.split[1].to_i.nonzero? ||
        `tput cols 2>/dev/null`.to_i.nonzero? || 80
    end

    def cols
      columns
    end
  end
end

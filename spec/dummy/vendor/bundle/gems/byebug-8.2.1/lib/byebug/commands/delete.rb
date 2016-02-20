require 'byebug/command'
require 'byebug/helpers/parse'

module Byebug
  #
  # Implements breakpoint deletion.
  #
  class DeleteCommand < Command
    include Helpers::ParseHelper

    self.allow_in_control = true
    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* del(?:ete)? (?:\s+(.*))?$/x
    end

    def self.description
      <<-EOD
        del[ete][ nnn...]

        #{short_description}

        Without and argument, deletes all breakpoints. With integer arguments,
        it deletes specific breakpoints.
      EOD
    end

    def self.short_description
      'Deletes breakpoints'
    end

    def execute
      unless @match[1]
        if confirm(pr('break.confirmations.delete_all'))
          Byebug.breakpoints.clear
        end

        return
      end

      @match[1].split(/ +/).each do |number|
        pos, err = get_int(number, 'Delete', 1)

        return errmsg(err) unless pos

        unless Breakpoint.remove(pos)
          return errmsg(pr('break.errors.no_breakpoint_delete', pos: pos))
        end
      end
    end
  end
end

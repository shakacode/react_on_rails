require 'byebug/command'
require 'byebug/helpers/eval'

module Byebug
  #
  # Implements exception catching.
  #
  # Enables the user to catch unhandled assertion when they happen.
  #
  class CatchCommand < Command
    include Helpers::EvalHelper

    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* cat(?:ch)? (?:\s+(\S+))? (?:\s+(off))? \s*$/x
    end

    def self.description
      <<-EOD
        cat[ch][ (off|<exception>[ off])]

        #{short_description}

        catch                 -- lists catchpoints
        catch off             -- deletes all catchpoints
        catch <exception>     -- enables handling <exception>
        catch <exception> off -- disables handling <exception>
      EOD
    end

    def self.short_description
      'Handles exception catchpoints'
    end

    def execute
      return info unless @match[1]

      return 'off' == @match[1] ? clear : add(@match[1]) unless @match[2]

      return errmsg pr('catch.errors.off', off: cmd) unless @match[2] == 'off'

      remove(@match[1])
    end

    private

    def remove(exception)
      unless Byebug.catchpoints.member?(exception)
        return errmsg pr('catch.errors.not_found', exception: exception)
      end

      puts pr('catch.removed', exception: exception)
      Byebug.catchpoints.delete(exception)
    end

    def add(exception)
      if warning_eval("#{exception.is_a?(Class)}")
        errmsg pr('catch.errors.not_class', class: exception)
      end

      puts pr('catch.added', exception: exception)
      Byebug.add_catchpoint(exception)
    end

    def clear
      Byebug.catchpoints.clear if confirm(pr('catch.confirmations.delete_all'))
    end

    def info
      if Byebug.catchpoints && !Byebug.catchpoints.empty?
        Byebug.catchpoints.each do |exception, _hits|
          puts("#{exception}: #{exception.is_a?(Class)}")
        end
      else
        puts 'No exceptions set to be caught.'
      end
    end
  end
end

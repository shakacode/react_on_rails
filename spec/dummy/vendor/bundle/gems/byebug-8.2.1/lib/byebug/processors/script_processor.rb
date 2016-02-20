require 'byebug/processors/command_processor'

module Byebug
  #
  # Processes commands from a file
  #
  class ScriptProcessor < CommandProcessor
    #
    # Available commands
    #
    def commands
      super.select(&:allow_in_control)
    end

    def process_commands
      while (input = interface.read_command(prompt))
        command = command_list.match(input)

        if command
          command.new(self).execute
        else
          errmsg('Unknown command')
        end
      end

      interface.close
    rescue IOError, SystemCallError
      interface.close
    rescue
      without_exceptions do
        puts "INTERNAL ERROR!!! #{$ERROR_INFO}"
        puts $ERROR_INFO.backtrace.map { |l| "  #{l}" }.join("\n")
      end
    end

    #
    # Prompt shown before reading a command.
    #
    def prompt
      '(byebug:ctrl) '
    end

    private

    def without_exceptions
      yield
    rescue
      nil
    end
  end
end

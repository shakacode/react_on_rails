require 'byebug/processors/command_processor'

module Byebug
  #
  # Processes commands when there's not program running
  #
  class ControlProcessor < CommandProcessor
    def initialize(context = nil)
      @context = context
    end

    #
    # Available commands
    #
    def commands
      super.select(&:allow_in_control)
    end

    #
    # Prompt shown before reading a command.
    #
    def prompt
      '(byebug:ctrl) '
    end
  end
end

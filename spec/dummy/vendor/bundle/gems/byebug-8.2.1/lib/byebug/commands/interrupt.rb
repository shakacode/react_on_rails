require 'byebug/command'

module Byebug
  #
  # Interrupting execution of current thread.
  #
  class InterruptCommand < Command
    self.allow_in_control = true

    def self.regexp
      /^\s*int(?:errupt)?\s*$/
    end

    def self.description
      <<-EOD
        int[errupt]

        #{short_description}
      EOD
    end

    def self.short_description
      'Interrupts the program'
    end

    def execute
      Byebug.thread_context(Thread.main).interrupt
    end
  end
end

require 'pry-byebug/helpers/navigation'

module PryByebug
  #
  # Run a number of Ruby statements and then stop again
  #
  class StepCommand < Pry::ClassCommand
    include Helpers::Navigation

    match 'step'
    group 'Byebug'
    description 'Step execution into the next line or method.'

    banner <<-BANNER
        Usage: step [TIMES]

        Step execution forward. By default, moves a single step.

        Examples:
          step   #=> Move a single step forward.
          step 5 #=> Execute the next 5 steps.
      BANNER

    def process
      PryByebug.check_file_context(target)

      breakout_navigation :step, times: args.first
    end
  end
end

Pry::Commands.add_command(PryByebug::StepCommand)

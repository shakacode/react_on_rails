require 'pry-byebug/helpers/navigation'

module PryByebug
  #
  # Run until the end of current frame
  #
  class FinishCommand < Pry::ClassCommand
    include PryByebug::Helpers::Navigation

    match 'finish'
    group 'Byebug'
    description 'Execute until current stack frame returns.'

    banner <<-BANNER
      Usage: finish
    BANNER

    def process
      PryByebug.check_file_context(target)

      breakout_navigation :finish
    end
  end
end

Pry::Commands.add_command(PryByebug::FinishCommand)

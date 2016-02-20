require 'pry-byebug/helpers/navigation'

module PryByebug
  #
  # Travel down the frame stack
  #
  class DownCommand < Pry::ClassCommand
    include Helpers::Navigation

    match 'down'
    group 'Byebug'

    description 'Move current frame down.'

    banner <<-BANNER
      Usage: down [TIMES]

      Move current frame down. By default, moves by 1 frame.

      Examples:
        down   #=> Move down 1 frame.
        down 5 #=> Move down 5 frames.
    BANNER

    def process
      PryByebug.check_file_context(target)

      breakout_navigation :down, times: args.first
    end
  end
end

Pry::Commands.add_command(PryByebug::DownCommand)

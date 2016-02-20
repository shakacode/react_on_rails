require 'pry-byebug/helpers/navigation'

module PryByebug
  #
  # Travel up the frame stack
  #
  class UpCommand < Pry::ClassCommand
    include Helpers::Navigation

    match 'up'
    group 'Byebug'

    description 'Move current frame up.'

    banner <<-BANNER
      Usage: up [TIMES]

      Move current frame up. By default, moves by 1 frame.

      Examples:
        up   #=> Move up 1 frame.
        up 5 #=> Move up 5 frames.
    BANNER

    def process
      PryByebug.check_file_context(target)

      breakout_navigation :up, times: args.first
    end
  end
end

Pry::Commands.add_command(PryByebug::UpCommand)

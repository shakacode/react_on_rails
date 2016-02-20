require 'pry-byebug/helpers/navigation'

module PryByebug
  #
  # Move to a specific frame in the callstack
  #
  class FrameCommand < Pry::ClassCommand
    include Helpers::Navigation

    match 'frame'
    group 'Byebug'

    description 'Move to specified frame #.'

    banner <<-BANNER
        Usage: frame [TIMES]

        Move to specified frame #.

        Examples:
          frame   #=> Show current frame #.
          frame 5 #=> Move to frame 5.
      BANNER

    def process
      PryByebug.check_file_context(target)

      breakout_navigation :frame, index: args.first
    end
  end
end

Pry::Commands.add_command(PryByebug::FrameCommand)

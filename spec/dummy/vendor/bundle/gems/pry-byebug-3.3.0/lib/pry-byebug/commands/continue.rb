require 'pry-byebug/helpers/navigation'
require 'pry-byebug/helpers/breakpoints'

module PryByebug
  #
  # Continue program execution until the next breakpoint
  #
  class ContinueCommand < Pry::ClassCommand
    include Helpers::Navigation
    include Helpers::Breakpoints

    match 'continue'
    group 'Byebug'
    description 'Continue program execution and end the Pry session.'

    banner <<-BANNER
      Usage: continue [LINE]

      Continue program execution until the next breakpoint, or the program
      ends. Optionally continue to the specified line number.

      Examples:
        continue   #=> Continue until the next breakpoint.
        continue 4 #=> Continue to line number 4.
    BANNER

    def process
      PryByebug.check_file_context(target)

      breakpoints.add_file(current_file, args.first.to_i) if args.first

      breakout_navigation :continue
    ensure
      Byebug.stop if Byebug.stoppable?
    end
  end
end

Pry::Commands.add_command(PryByebug::ContinueCommand)

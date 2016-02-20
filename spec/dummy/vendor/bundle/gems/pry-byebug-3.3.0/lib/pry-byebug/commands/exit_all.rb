module PryByebug
  #
  # Exit pry REPL with Byebug.stop
  #
  class ExitAllCommand < Pry::Command::ExitAll
    def process
      super
    ensure
      Byebug.stop if Byebug.stoppable?
    end
  end
end

Pry::Commands.add_command(PryByebug::ExitAllCommand)

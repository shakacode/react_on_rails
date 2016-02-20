require 'byebug/core'

module Byebug
  #
  # Extends raw byebug's processor.
  #
  class PryProcessor < CommandProcessor
    attr_accessor :pry

    extend Forwardable
    def_delegators :@pry, :output
    def_delegators Pry::Helpers::Text, :bold

    def self.start
      Byebug.start
      Setting[:autolist] = false
      Context.processor = self
      Byebug.current_context.step_out(4, true)
    end

    #
    # Wrap a Pry REPL to catch navigational commands and act on them.
    #
    def run(&_block)
      return_value = nil

      command = catch(:breakout_nav) do # Throws from PryByebug::Commands
        return_value = yield
        {} # Nothing thrown == no navigational command
      end

      # Pry instance to resume after stepping
      @pry = command[:pry]

      perform(command[:action], command[:options])

      return_value
    end

    #
    # Set up a number of navigational commands to be performed by Byebug.
    #
    def perform(action, options = {})
      return unless %i(next step finish up down frame).include?(action)

      send("perform_#{action}", options)
    end

    # --- Callbacks from byebug C extension ---

    #
    # Called when the debugger wants to stop at a regular line
    #
    def at_line
      resume_pry
    end

    #
    # Called when the debugger wants to stop right before a method return
    #
    def at_return(_return_value)
      resume_pry
    end

    #
    # Called when the debugger wants to stop right before the end of a class
    # definition
    #
    def at_end
      resume_pry
    end

    #
    # Called when a breakpoint is hit. Note that `at_line`` is called
    # inmediately after with the context's `stop_reason == :breakpoint`, so we
    # must not resume the pry instance here
    #
    def at_breakpoint(breakpoint)
      @pry ||= Pry.new

      output.puts bold("\n  Breakpoint #{breakpoint.id}. ") + n_hits(breakpoint)

      expr = breakpoint.expr
      return unless expr

      output.puts bold('Condition: ') + expr
    end

    private

    def n_hits(breakpoint)
      n_hits = breakpoint.hit_count

      n_hits == 1 ? 'First hit' : "Hit #{n_hits} times."
    end

    #
    # Resume an existing Pry REPL at the paused point.
    #
    def resume_pry
      new_binding = frame._binding

      run do
        if defined?(@pry) && @pry
          @pry.repl(new_binding)
        else
          @pry = Pry.start_without_pry_byebug(new_binding)
        end
      end
    end

    def perform_next(options)
      lines = (options[:lines] || 1).to_i
      context.step_over(lines, frame.pos)
    end

    def perform_step(options)
      times = (options[:times] || 1).to_i
      context.step_into(times, frame.pos)
    end

    def perform_finish(*)
      context.step_out(1)
    end

    def perform_up(options)
      times = (options[:times] || 1).to_i

      Byebug::UpCommand.new(self, "up #{times}").execute

      resume_pry
    end

    def perform_down(options)
      times = (options[:times] || 1).to_i

      Byebug::DownCommand.new(self, "down #{times}").execute

      resume_pry
    end

    def perform_frame(options)
      index = options[:index] ? options[:index].to_i : ''

      Byebug::FrameCommand.new(self, "frame #{index}").execute

      resume_pry
    end
  end
end

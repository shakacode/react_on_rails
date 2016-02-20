# Additional methods provided by pry-rescue.
class << Pry
  # Start a pry session on any unhandled exceptions within this block.
  #
  # @example
  #   Pry::rescue do
  #     raise "foo"
  #   end
  #
  # @return [Object] The return value of the block
  def rescue(&block)
    loop do
      catch(:try_again) do
        begin
          return with_rescuing(&block)
        rescue Exception => e
          rescued e unless SystemExit === e || SignalException === e
          raise e
        end
      end
    end
  end

  # Start a pry session on an exception that you rescued within a Pry::rescue{ }.
  #
  # @example
  #   Pry::rescue do
  #     begin
  #       raise "foo"
  #     rescue => e
  #       Pry::rescued(e)
  #     end
  #   end
  #
  def rescued(e=$!)
    if e.instance_variable_defined?(:@rescue_bindings)
      PryRescue.enter_exception_context(e)
    else
      stack = ''
      stack = "\n" + e.backtrace.join("\n") if e.backtrace
      case e
      when SystemStackError
        # Interception cannot reliably interept SystemStackErrors as it needs
        # to call a function at the point the stack runs out.
        # We use a special error message here, as it seems nicer to assume that
        # the user knows what they are doing, and it's the software that's
        # terrible.
        warn "WARNING: Insufficient stack space to inspect exception" + stack
      else
        # We used to raise an exception at this point, but that turned out to
        # not be very helpful as it obscured the original cause of the problem.
        # I considered adding an explicit 'raise e' here, but decided against
        # it on the grounds that the Pry::rescued call is normally in someone
        # else's error handler already.
        warn "WARNING: Tried to inspect exception outside of Pry::rescue{ }" + \
          stack
      end
    end

  end

  # Allow Pry::rescued(e) to work at any point in your program.
  #
  # @example
  #   Pry::enable_rescuing!
  #
  #   begin
  #     raise "foo"
  #   rescue => e
  #     Pry::rescued(e)
  #   end
  #
  def enable_rescuing!(block=nil)
    Interception.listen(block) do |exception, binding|
      bindings = binding.respond_to?(:callers) ? binding.callers : [binding]
      unless exception.instance_variable_defined?(:@rescue_bindings)
        exception.instance_variable_set(:@rescue_bindings, bindings)
        exception.instance_variable_set(:@rescue_cause, $!)
      end
    end
  end

  private

  # Ensure that Interception is active while running this block
  #
  # @param [Proc] block  the block
  def with_rescuing(&block)
    if @rescuing
      block.call
    else
      begin
        @rescuing = true
        enable_rescuing!(block)
      ensure
        @rescuing = false
      end
    end
  end
end

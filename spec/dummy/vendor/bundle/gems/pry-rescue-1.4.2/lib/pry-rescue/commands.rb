Pry::Commands.create_command "cd-cause", "Move to the exception that caused this exception to happen"  do

  banner <<-BANNER
    Usage: cd-cause [_ex_]

    Starts a new Pry session at the previously raised exception.

    If you have many layers of exceptions that are rescued and then re-raised,
    you can repeat cd-cause as many times as you need.

    The cd-cause command is useful if:
      - You've just caused an exception within Pry, and you want to see why
      - When an intermediate exception handler
        - Intentionally re-raises an exception
        - Has a bug that causes an inadvertent exception

    @example
      [2] pry(main)> foo
      RuntimeError: two
      from /home/conrad/0/ruby/pry-rescue/a.rb:4:in `rescue in foo'
      [3] pry(main)> cd-cause

          1: def foo
          2:   raise "one"
          3: rescue => e
       => 4:   raise "two"
          5: end

      [4] pry(main)> cd-cause

          1: def foo
       => 2:   raise "one"
          3: rescue => e
          4:   raise "two"
          5: end

    Once you have finished inspecting the exception, type <ctrl+d> or cd .. to
    return to where you were.
  BANNER

  def process
    return Pry.rescued target.eval(args.first) if args.any?

    ex = target.eval("defined?(_ex_) && _ex_")
    rescued = target.eval("defined?(_rescued_) && _rescued_")

    ex = ex.instance_variable_get(:@rescue_cause) if rescued == ex
    raise Pry::CommandError, "No previous exception to cd-cause into" if ex.nil? || ex == rescued

    Pry.rescued ex
  end
end

Pry::Commands.create_command "try-again", "Re-try the code that caused this exception" do

  banner <<-BANNER
    Usage: try-again

    Runs the code wrapped by Pry::rescue{ } again.

    This is useful if you've used `edit` or `edit-method` to fix the problem
    that caused this exception to be raised and you want a quick way to test
    your changes.

    NOTE: try-again may cause confusing results if the code that's run have
    side-effects (like deleting rows from a database) as it will try to do that
    again, which may not work.
  BANNER

  def process
    raise Pry::CommandError, "try-again only works in a pry session created by Pry::rescue{}" unless PryRescue.in_exception_context?
    throw :try_again
  end
end

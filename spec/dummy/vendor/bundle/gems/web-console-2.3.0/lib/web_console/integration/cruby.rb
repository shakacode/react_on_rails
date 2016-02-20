class Exception
  begin
    # We share the same exception binding extraction mechanism as better_errors,
    # so try to use it if it is already available. It also solves problems like
    # charliesome/better_errors#272, caused by an infinite recursion.
    require 'better_errors'

    # The bindings in which the exception originated in.
    def bindings
      @bindings || __better_errors_bindings_stack
    end
  rescue LoadError
    # The bindings in which the exception originated in.
    def bindings
      @bindings || []
    end

    # CRuby calls #set_backtrace every time it raises an exception. Overriding
    # it to assign the #bindings.
    def set_backtrace_with_binding_of_caller(*args)
      # Thanks to @charliesome who wrote this bit for better_errors.
      unless Thread.current[:__web_console_exception_lock]
        Thread.current[:__web_console_exception_lock] = true
        begin
          # Raising an exception here will cause all of the rubies to go into a
          # stack overflow. Some rubies may even segfault. See
          # https://bugs.ruby-lang.org/issues/10164 for details.
          @bindings = binding.callers.drop(1)
        ensure
          Thread.current[:__web_console_exception_lock] = false
        end
      end

      set_backtrace_without_binding_of_caller(*args)
    end

    alias_method :set_backtrace_without_binding_of_caller, :set_backtrace
    alias_method :set_backtrace, :set_backtrace_with_binding_of_caller
  end
end

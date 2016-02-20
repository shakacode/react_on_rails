ActionDispatch::DebugExceptions.class_eval do
  def render_exception_with_web_console(request, exception)
    render_exception_without_web_console(request, exception).tap do
      # Retain superficial Rails 5 compatibility.
      env = Hash === request ? request : request.env

      error = ActionDispatch::ExceptionWrapper.new(env, exception).exception

      # Get the original exception if ExceptionWrapper decides to follow it.
      env['web_console.exception'] = error

      # ActionView::Template::Error bypass ExceptionWrapper original
      # exception following. The backtrace in the view is generated from
      # reaching out to original_exception in the view.
      if error.is_a?(ActionView::Template::Error)
        env['web_console.exception'] = error.original_exception
      end
    end
  end

  alias_method :render_exception_without_web_console, :render_exception
  alias_method :render_exception, :render_exception_with_web_console
end

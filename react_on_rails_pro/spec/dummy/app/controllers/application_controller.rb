# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from ReactOnRails::PrerenderError do |err|
    log_prerender_error(err)
    return stream_prerender_error_response if response.committed?

    redirect_prerender_error_response
  end

  private

  def log_prerender_error(err)
    Rails.logger.error("Caught ReactOnRails::PrerenderError in ApplicationController error handler.")
    Rails.logger.error(err.message)
    Rails.logger.error(err.backtrace.join("\n"))
  end

  def stream_prerender_error_response
    Rails.logger.error(<<~ERROR)
      Error occurred after part of the response already sent,
      the error should happen during streaming react component
      and the error happen outside the shell
    ERROR

    error_message = <<~HTML
      <h2>Server-Side Rendering Error</h2>
      <p>We apologize, but an error occurred while rendering the page on the server.</p>
      <p>If you are not redirected, please
      <a href="#{server_side_log_throw_raise_invoker_path}">click here</a>.</p>
    HTML

    js_redirect = <<~JAVASCRIPT
      <script>
        document.getElementById('page-container').innerHTML = #{ActiveSupport::JSON.encode(error_message)};
        setTimeout(function() {
          window.location.href = '#{server_side_log_throw_raise_invoker_path}';
        }, 5000);
      </script>
    JAVASCRIPT

    meta_refresh = <<~HTML
      <meta http-equiv='refresh' content='5;url=#{server_side_log_throw_raise_invoker_path}'>
    HTML

    response.stream.write(error_message + js_redirect + meta_refresh)
  ensure
    response.stream.close
  end

  def redirect_prerender_error_response
    msg = <<~MSG
      Error prerendering in react_on_rails.
      Redirected back to '/server_side_log_throw_raise_invoker'.
      See server logs for output.
    MSG
    redirect_to server_side_log_throw_raise_invoker_path,
                flash: { error: msg }
  end
end

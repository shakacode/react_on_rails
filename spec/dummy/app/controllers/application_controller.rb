# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from ReactOnRails::PrerenderError do |err|
    raise err if err.err.is_a?(ReactOnRails::JsonParseError)

    Rails.logger.error("Caught ReactOnRails::PrerenderError in ApplicationController error handler.")
    Rails.logger.error(err.message)
    Rails.logger.error(err.backtrace.join("\n"))
    msg = <<-MSG.strip_heredoc
      Error prerendering in react_on_rails.
      Redirected back to '/server_side_log_throw_raise_invoker'.
      See server logs for output.
    MSG
    redirect_to server_side_log_throw_raise_invoker_path,
                flash: { error: msg }
  end
end

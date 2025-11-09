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
    msg = <<~MSG
      Error prerendering in react_on_rails.
      Redirected back to '/server_side_log_throw_raise_invoker'.
      See server logs for output.
    MSG
    redirect_to server_side_log_throw_raise_invoker_path,
                flash: { error: msg }
  end

  helper_method :uses_redux_shared_store?

  # Returns true if the current page uses Redux shared stores with inline registration
  # These pages require defer: true instead of async: true for proper script execution order
  def uses_redux_shared_store?
    # Pages that use redux_store helper with inline component registration
    action_name.in?(%w[
                      index
                      server_side_redux_app
                      server_side_redux_app_cached
                      server_side_hello_world_shared_store
                      server_side_hello_world_shared_store_defer
                      server_side_hello_world_shared_store_controller
                      client_side_hello_world_shared_store
                      client_side_hello_world_shared_store_defer
                      client_side_hello_world_shared_store_controller
                    ])
  end
end

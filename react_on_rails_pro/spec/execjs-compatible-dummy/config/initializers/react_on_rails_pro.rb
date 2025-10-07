# frozen_string_literal: true

# See documentation in docs/configuration.md
ReactOnRailsPro.configure do |config|
  # Get timing of server render calls
  config.tracing = true

  config.server_renderer = "ExecJS"
  # If you want Honeybadger or Sentry on the Node renderer side to report rendering errors
  config.throw_js_errors = false

  config.renderer_password = "myPassword1"

  config.renderer_url = "http://localhost:3800"

  # If true, then cache the evaluation of JS for prerendering using the standard Rails cache.
  # Applies to all rendering engines.
  # Default for `prerender_caching` is false.
  config.prerender_caching = true

  # Retry request in case of time out on the node-renderer side
  # 0 - no retry
  config.renderer_request_retry_limit = 1

  # If you want to profile the server rendering JS code
  # This will output some isolate-0x*.log files in the current directory
  # You can run rake react_on_rails_pro:process_v8_logs to process these files and generate a profile.v8log.json file
  # which can be analyzed using tools like Speed Scope (https://www.speedscope.app) or Chrome Developer Tools
  config.profile_server_rendering_js_code = true

  # Enable immediate hydration (Pro default is true, explicitly set for clarity)
  config.immediate_hydration = true
end

# Shown below are the defaults for configuration
ReactOnRails.configure do |config|
  # Client bundles are configured in application.js
  # Server bundle is a single file for all server rendering of components.
  config.server_bundle_js_file = "app/assets/javascripts/generated/server-bundle.js" # This is the default

  # Below options can be overriden by passing to the helper method.
  config.prerender = false # default is false
  config.generator_function = false # default is false, meaning that you expose ReactComponents directly
  config.trace = Rails.env.development? # default is true for development, off otherwise

  # For server rendering. This can be set to false so that server side messages are discarded.
  config.replay_console = true # Default is true. Be cautious about turning this off.
  config.logging_on_server = true # Default is true. Logs server rendering messags to Rails.logger.info

  # Settings for the pool of renderers:
  config.server_renderer_pool_size ||= 1 # ExecJS doesn't allow more than one on MRI
  config.server_renderer_timeout ||= 20 # seconds
end

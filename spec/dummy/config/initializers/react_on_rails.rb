ReactOnRails.configure do |config|
  # Client bundles are configured in application.js
  # Server bundle is a single file for all server rendering of components.
  config.server_bundle_js_file = "app/assets/javascripts/generated/server.js" # This is the default

  config.prerender = true # default is false
  config.replay_console = true # Default is true. Be cautious about turning this off.
  config.generator_function = false # default is false, meaning that you expose ReactComponents directly
  config.trace = Rails.env.development? # default is true for development, off otherwise
end

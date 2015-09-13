ReactOnRails.configure do |config|
  config.bundle_js_file = "app/assets/javascripts/generated/server.js" # This is the default
  config.prerender = true # default is false
  config.replay_console = true # Default is true. Be cautious about turning this off.
  config.generator_function = false # default is false, meaning that you expose ReactComponents directly
end

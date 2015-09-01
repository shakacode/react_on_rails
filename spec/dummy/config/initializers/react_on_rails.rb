ReactOnRails.configure do |config|
  config.bundle_js_file = "app/assets/javascripts/generated/server.js" # This is the default
  config.prerender = true # default is false
end

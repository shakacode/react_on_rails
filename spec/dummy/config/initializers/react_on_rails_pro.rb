ReactOnRailsPro.configure do |config|
  # See documentation in docs/configuration.md
  config.server_renderer = ENV["SERVER_RENDERER"].presence || "VmRenderer"

  # Setting the password myPasssword1 after the leading `:` and before the `@`
  config.renderer_url = "http://:myPassword1@localhost:3800"

  # Set this to false specs fail if remote renderer is not available
  config.renderer_use_fallback_exec_js = false
  config.prerender_caching = true

  # Get timing of server render calls
  config.tracing = true
end

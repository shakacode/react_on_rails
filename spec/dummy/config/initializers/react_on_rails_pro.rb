ReactOnRailsPro.configure do |config|
  config.renderer_url = "http://localhost:3800"
  config.server_render_method = "VmRenderer"
  config.use_fallback_renderer_exec_js = false
  config.prerender_caching = true
end

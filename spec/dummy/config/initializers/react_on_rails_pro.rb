# frozen_string_literal: true

# See documentation in docs/configuration.md
ReactOnRailsPro.configure do |config|
  # Get timing of server render calls
  config.tracing = true

  # Used to turn off the VmRenderer during on CI workflow
  config.server_renderer = ENV["SERVER_RENDERER"].presence || "VmRenderer"

  # Setting the password myPasssword1 after the leading `:` and before the `@`
  config.renderer_url = "http://:myPassword1@localhost:3800"

  # Set this to false specs fail if remote renderer is not available. We want to ensure
  # that the remote renderer works for CI.
  config.renderer_use_fallback_exec_js = false

  # If true, then cache the evaluation of JS for prerendering using the standard Rails cache.
  # Applies to all rendering engines.
  # Default for `prerender_caching` is false.
  config.prerender_caching = true

  # Array of globs to find any files for which changes should bust the fragment cache for
  # cached_react_component and cached_react_component_hash. This should
  # include any files used to generate the JSON props.
  config.serializer_globs = [File.join(Rails.root, "app", "views", "**", "*.jbuilder")]

  # In case if there is a remote vm renderer, you may require some
  # extra assets in addition to the bundle. These would be present on the main
  # Rails server, but not the renderer server.
  # This option allows a remote vm renderer (not localhost)
  # to have assets copied to the  vm-renderer instance right after assets:precompile task.
  # Value should be an Array of Hashes, with each Hash containing 2 keys:
  # file_path and content_type, like "application/json"
  config.assets_to_copy = [
    { filepath: Rails.root.join("public", "webpack", "production", "loadable-stats.json"),
      content_type: "application/json" }
  ]
end

# frozen_string_literal: true

# See documentation in docs/configuration.md
ReactOnRailsPro.configure do |config|
  # Get timing of server render calls
  config.tracing = true

  # Used to turn off the VmRenderer during on CI workflow
  config.server_renderer = ENV["SERVER_RENDERER"].presence || "VmRenderer"

  config.renderer_password = "myPassword1"

  config.renderer_url = "http://localhost:3800"

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

  # When using the vm renderer, you may require some extra assets in addition to the bundle.
  # The assets_to_copy option allows the vm renderer to have assets copied at the end of
  # the assets:precompile task or directly by the
  # react_on_rails_pro:copy_assets_to_vm_renderer tasks.
  # These assets are also transferred any time a new bundle is sent from Rails to the renderer.
  # The value should be a file_path or an Array of file_paths. The files should have extensions
  # to resolve the content types, such as "application/json".
  # Note, for spec/dummy, manifest.json is just used for testing
  config.assets_to_copy = Rails.root.join("public", "webpack", Rails.env, "manifest.json")
end

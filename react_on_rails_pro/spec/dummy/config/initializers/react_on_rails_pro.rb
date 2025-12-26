# frozen_string_literal: true

# See documentation in docs/configuration.md
ReactOnRailsPro.configure do |config|
  # Get timing of server render calls
  config.tracing = true

  config.rendering_returns_promises = true

  # RSC bundle configuration (moved from ReactOnRails.configure)
  config.rsc_bundle_js_file = "rsc-bundle.js"

  config.server_renderer = "NodeRenderer"
  # If you want Honeybadger or Sentry on the Node renderer side to report rendering errors
  config.throw_js_errors = false

  config.renderer_password = "myPassword1"

  config.enable_rsc_support = true
  config.renderer_url = "http://localhost:3800"
  config.rsc_payload_generation_url_path = "rsc_payload/"

  # Set this to false specs fail if remote renderer is not available. We want to ensure
  # that the remote renderer works for CI.
  config.renderer_use_fallback_exec_js = false

  config.ssr_timeout = 10

  config.raise_non_shell_server_rendering_errors = false

  # If true, then cache the evaluation of JS for prerendering using the standard Rails cache.
  # Applies to all rendering engines.
  # Default for `prerender_caching` is false.
  config.prerender_caching = true

  # Retry request in case of time out on the node-renderer side
  # 0 - no retry
  config.renderer_request_retry_limit = 1

  # Array of globs to find any files for which changes should bust the fragment cache for
  # cached_react_component and cached_react_component_hash. This should
  # include any files used to generate the JSON props.
  config.dependency_globs = [File.join(Rails.root, "app", "views", "**", "*.jbuilder")]

  # License auto-refresh configuration
  # Uncomment these lines for local testing with the licensing app
  # config.license_key = ENV.fetch("REACT_ON_RAILS_PRO_LICENSE_KEY", nil)
  # config.license_api_url = ENV.fetch("REACT_ON_RAILS_PRO_LICENSE_API_URL", "http://localhost:3000")
  # config.auto_refresh_license = true

  # When using the Node Renderer, you may require some extra assets in addition to the bundle.
  # The assets_to_copy option allows the Node Renderer to have assets copied at the end of
  # the assets:precompile task or directly by the
  # react_on_rails_pro:copy_assets_to_remote_vm_renderer task.
  # These assets are also transferred any time a new bundle is sent from Rails to the renderer.
  # The value should be a file_path or an Array of file_paths. The files should have extensions
  # to resolve the content types, such as "application/json".
  config.assets_to_copy = (if ENV["HMR"] != "true"
                             Rails.root.join("public", "webpack", Rails.env, "loadable-stats.json")
                           end)
end

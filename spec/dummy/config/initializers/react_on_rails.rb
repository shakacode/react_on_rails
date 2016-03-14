# Shown below are the defaults for configuration
ReactOnRails.configure do |config|
  # Client bundles are configured in application.js

  # Directory where your generated assets go
  config.generated_assets_dir = File.join(%w(app assets webpack))

  # Define the files for we need to check for webpack compilation when running tests
  config.webpack_generated_files = %w( app-bundle.js vendor-bundle.js server-bundle.js )

  # Server bundle is a single file for all server rendering of components.
  # If you wish to use render_js in your views without any file, set this to "" to avoid warnings.
  # Note, this is the default server bundle. If you have multiple ones, just pick any to be your
  # default one.
  config.server_bundle_js_file = "server-bundle.js"

  # Below options can be overriden by passing to the helper method.
  config.prerender = false # default is false
  config.trace = Rails.env.development? # default is true for development, off otherwise

  # For server rendering. This can be set to false so that server side messages are discarded.
  config.replay_console = true # Default is true. Be cautious about turning this off.
  config.logging_on_server = true # Default is true. Logs server rendering messags to Rails.logger.info
  config.raise_on_prerender_error = false # change to true to raise exception on server if the JS code throws

  # Server rendering only (not for render_component helper)
  config.server_renderer_pool_size  = 1   # increase if you're on JRuby
  config.server_renderer_timeout    = 20  # seconds

  # Default is false, enable if your content security policy doesn't include `style-src: 'unsafe-inline'`
  config.skip_display_none = false
end

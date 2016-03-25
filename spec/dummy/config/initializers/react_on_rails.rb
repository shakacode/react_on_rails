ReactOnRails.configure do |config|
  # Directory where your generated assets go. All generated assets must go to the same directory.
  # Configure this in your webpack config files. This relative to your Rails root directory.
  config.generated_assets_dir = File.join(%w(app assets webpack))

  # Define the files for we need to check for webpack compilation when running tests.
  config.webpack_generated_files = %w( app-bundle.js vendor-bundle.js server-bundle.js alternative-server-bundle.js )

  # The server bundle is a single file for all server rendering of components.
  # If you are not using server rendering `(prerender: true)`, set this to "".
  config.server_bundle_js_files = %w(server-bundle.js alternative-server-bundle.js)

  ################################################################################
  # CLIENT RENDERING OPTIONS
  # Below options can be overriden by passing options to the react_on_rails
  # `render_component` view helper method.
  ################################################################################
  config.prerender = false # default is false
  config.trace = Rails.env.development? # default is true for development, off otherwise

  ################################################################################
  # SERVER RENDERING OPTIONS
  ################################################################################
  # For server rendering. This can be set to false so that server side messages are discarded.
  config.replay_console = true # Default is true. Be cautious about turning this off.

  config.logging_on_server = true # Default is true. Logs server rendering messags to Rails.logger.info

  config.raise_on_prerender_error = false # change to true to raise exception on server if the JS code throws

  # Server rendering only (not for render_component helper)
  # You can configure your pool of JS virtual machines and specify where it should load code:
  # On MRI, use `therubyracer` for the best performance
  # (see [discussion](https://github.com/reactjs/react-rails/pull/290))
  # On MRI, you'll get a deadlock with `pool_size` > 1
  # If you're using JRuby, you can increase `pool_size` to have real multi-threaded rendering.
  config.server_renderer_pool_size  = 1   # increase if you're on JRuby
  config.server_renderer_timeout    = 20  # seconds

  ################################################################################
  # MISCELLANEOUS OPTIONS
  ################################################################################
  # Default is false, enable if your content security policy doesn't include `style-src: 'unsafe-inline'`
  config.skip_display_none = false
end

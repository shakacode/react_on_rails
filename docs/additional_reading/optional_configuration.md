# Optional Configuration

Create a file `config/react_on_rails.rb` to override any defaults (this file is automatically created for you when using the generator). If you don't specify this file, the default options are below.

The `server_bundle_js_file` must correspond to the bundle you want to use for server rendering.

```ruby
# Shown below are the defaults for configuration
ReactOnRails.configure do |config|
  # Client bundles are configured in application.js
  # Server bundle is a single file for all server rendering of components.
  # Set the server_bundle_js_file to "" if you know that you will not be server rendering.
  config.server_bundle_js_file = "server-bundle.js" # This is the default

  # Below options can be overriden by passing to the helper method.
  config.prerender = false # default is false
  config.trace = Rails.env.development? # default is true for development, off otherwise

  # For server rendering. This can be set to false so that server side messages are discarded.
  config.replay_console = true # Default is true. Be cautious about turning this off.
  config.logging_on_server = true # Default is true. Logs server rendering messags to Rails.logger.info

  # Settings for the pool of renderers:
  config.server_renderer_pool_size  ||= 1  # ExecJS doesn't allow more than one on MRI
  config.server_renderer_timeout    ||= 20 # seconds
end
```

You can configure your pool of JS virtual machines and specify where it should load code:

- On MRI, use `therubyracer` for the best performance (see [discussion](https://github.com/reactjs/react-rails/pull/290))
- On MRI, you'll get a deadlock with `pool_size` > 1
- If you're using JRuby, you can increase `pool_size` to have real multi-threaded rendering.

`config/initializers/react_on_rails_pro.rb`

1. Values beginning with `renderer` pertain only to using an external rendering server. You will need to ensure these values are consistent with your configuration for the external rendering server, as given in [docs/vm-renderer/js-configuration.md](./vm-renderer/js-configuration.md)
2. `config.prerender_caching` works for standard mini_racer server rendering and using an external rendering server.

# Example of Configuration

Also see [spec/dummy/config/initializers/react_on_rails_pro.rb](../../spec/dummy/config/initializers/react_on_rails_pro.rb) for how the testing app is setup.

```ruby
ReactOnRailsPro.configure do |config|
  # VmRenderer is for a renderer that is stateless. It does not need restarting when the JS bundles 
  # are updated. It is the only custom renderer currently supported. Leave blank to use the standard
  # mini_racer rendering.
  config.server_renderer = "VmRenderer"
  
  # If true, then cache the evaluation of JS for prerendering using the standard Rails cache.
  # Default is true.
  config.prerender_caching = true

  # You may provide a password and/or a port that will be sent to renderer for simple authentication. 
  # `https://:<password>@url:<port>`. For example: https://:myPassword1@renderer:3800. Don't forget
  # the leading `:` before the password. Your password must also not contain certain characters that
  # would break calling URI(config.renderer_url). This includes: `@`, `#`, '/'.
  # **Note:** Don't forget to set up **SSL** connection otherwise password will useless
  # since it will be easy to intercept it.
  # Default is http://localhost:3800. https is supported. 
  # If you provide an ENV value (for production) and there is no value, then you get the default.
  config.renderer_url = ENV["RENDERER_URL"] 
 
  # If you don't want to worry about special characters in your password within the url, use this config value
  # config.renderer_password = ENV["RENDERER_PASSWORD"]
  
  # If false, then crash if no backup rendering when the remote renderer is not available
  config.renderer_use_fallback_exec_js = true
  
  # Set +pool_size+ to limit the maximum number of connections allowed.
  # Defaults to 1/4 the number of allowed file handles.  You can have no more
  # than this many threads with active HTTP transactions.
  # The maximum size of the http connection pool, defaults to 10
  config.renderer_http_pool_size = 10
 
  # Seconds to wait for an available connection before a Timeout::Error is raised, defaults to 5
  config.renderer_http_pool_timeout = 5
  
  # warn_timeout  - Displays an error message if a checkout takes longer that the given time in seconds
  # (used to give hints to increase the pool size). Default is 0.25
  config.renderer_http_pool_warn_timeout = 0.25 # seconds
end
```

`config/initializers/react_on_rails_pro.rb`

```ruby
ReactOnRailsPro.configure do |config|
  # If true, then cache the evaluation of JS for prerendering using the standard Rails cache
  config.prerender_caching = true

  # Default is http://localhost:3800. https is supported.
  config.renderer_url = "http://localhost:3800"
  
  # VmRenderer is for a renderer that is stateless. It does not need restarting when the JS bundles 
  # are updated. It is the only custom renderer currently supported. Leave blank to use the standard
  # mini_racer rendering.
  config.server_render_method = "VmRenderer"
  
  # Password that will be sent to renderer for simple authentication. **Note:** Don't forget to set 
  # up **SSL** connection otherwise password will useless since it will be easy to intercept it.
  # config.renderer_password = "somethingSecret"
  
  # If false, then crash if no backup rendering when the remote renderer is not available
  config.use_fallback_renderer_exec_js = false
  
  # Set +pool_size+ to limit the maximum number of connections allowed.
  # Defaults to 1/4 the number of allowed file handles.  You can have no more
  # than this many threads with active HTTP transactions.
  
  # The maximum size of the http connection pool, defaults to 10
  # config.http_pool_size = 10
 
  # Seconds to wait for an available connection before a Timeout::Error is raised, defaults to 5
  # config.http_pool_timeout = 5
  
  # warn_timeout  - Displays an error message if a checkout takes longer that the given time
  # (used to give hints to increase the pool size). Default is 0.25
  # config.http_pool_warn_timeout
end
```

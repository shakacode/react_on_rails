`config/initializers/react_on_rails_pro.rb`

1. You don't need to create a initializer if you are satisfied with the defaults as described below. 
1. Values beginning with `renderer` pertain only to using an external rendering server. You will need to ensure these values are consistent with your configuration for the external rendering server, as given in [docs/vm-renderer/js-configuration.md](./vm-renderer/js-configuration.md)
1. `config.prerender_caching` works for standard mini_racer server rendering and using an external rendering server.

# Example of Configuration

Also see [spec/dummy/config/initializers/react_on_rails_pro.rb](../../spec/dummy/config/initializers/react_on_rails_pro.rb) for how the testing app is setup.

The below example is a typical production setup, using the separate `VmRenderer`, where development takes the defaults when the ENV values are not specified.

```ruby
ReactOnRailsPro.configure do |config|
  # If true, then capture timing of React on Rails Pro calls including server rendering and 
  # component rendering.
  # Default for `tracing` is false.
  config.tracing = true
  
  # Array of globs to find any files for which changes should bust the fragment cache for 
  # cached_react_component and cached_react_component_hash. This should
  # include any files used to generate the JSON props. 
  config.serializer_globs = [ File.join(Rails.root, "app", "views", "**", "*.jbuilder") ]
  

  # ALL OPTIONS BELOW ONLY APPLY IF SERVER RENDERING

  # If true, then cache the evaluation of JS for prerendering using the standard Rails cache.
  # Applies to all rendering engines.
  # Default for `prerender_caching` is false.  
  config.prerender_caching = true
  
  # VmRenderer is for a renderer that is stateless. It does not need restarting when the JS bundles 
  # are updated. It is the only custom renderer currently supported. Leave blank to use the standard
  # mini_racer rendering. Other option is VmRenderer
  # Default for `server_renderer` is "ExecJS"
  config.server_renderer = "VmRenderer"
  
  # You may provide a password and/or a port that will be sent to renderer for simple authentication. 
  # `https://:<password>@url:<port>`. For example: https://:myPassword1@renderer:3800. Don't forget
  # the leading `:` before the password. Your password must also not contain certain characters that
  # would break calling URI(config.renderer_url). This includes: `@`, `#`, '/'.
  # **Note:** Don't forget to set up **SSL** connection (https) otherwise password will useless
  # since it will be easy to intercept it.
  # If you provide an ENV value (maybe only for production) and there is no value, then you get the default.
  # Default for `renderer_url` is "http://localhost:3800". 
  config.renderer_url = ENV["RENDERER_URL"] 
 
  # If you don't want to worry about special characters in your password within the url, use this config value
  # Default for `renderer_password` is "" 
  # config.renderer_password = ENV["RENDERER_PASSWORD"]
  
  # If false, then crash if no backup rendering when the remote renderer is not available
  # Can be useful to set to false in development or testing to make sure that the remote renderer
  # works and any non-availability of the remote renderer does not just do ExecJS.
  # Default for `renderer_use_fallback_exec_js` is true. 
  config.renderer_use_fallback_exec_js = true
  
  # The maximum size of the http connection pool, 
  # Set +pool_size+ to limit the maximum number of connections allowed.
  # Defaults to 1/4 the number of allowed file handles.  You can have no more
  # than this many threads with active HTTP transactions.
  # Default for `renderer_http_pool_size` is 10
  config.renderer_http_pool_size = 10
 
  # Seconds to wait for an available connection before a Timeout::Error is raised
  # Default for `renderer_http_pool_timeout` is 5
  config.renderer_http_pool_timeout = 5
  
  # warn_timeout  - Displays an error message if a checkout takes longer that the given time in seconds
  # (used to give hints to increase the pool size). Default is 0.25
  config.renderer_http_pool_warn_timeout = 0.25 # seconds
  
  # Snippet of JavaScript to be run right at the beginning of the server rendering process. The code
  # to be executed must either be self contained or reference some globally exposed module.  
  # For example, suppose that we had to call `SomeLibrary.clearCache()`between every call to server
  # renderer to ensure no leakage of state between calls. Note, SomeLibrary needs to be globally 
  # exposed in the server rendering webpack bundle. This code is visible in the tracing of the calls
  # to do server rendering. Default is nil.
  config.ssr_pre_hook_js = "SomeLibrary.clearCache();" 

  # When using a remote, non-localhost vm renderer, you may require some extra assets
  # in addition to the bundle. Such assets would be present on the main Rails server, 
  # but not the renderer server.
  # The assets_to_copy option allows a remote, non-localhost, vm renderer to have assets 
  # copied at the end of assets:precompile task or directly by the 
  # react_on_rails_pro:copy_assets_to_vm_renderer tasks.
  # The value should be an Array of Hashes, with each Hash containing 2 keys: file_path and content_type,
  # like "application/json" 
  config.assets_to_copy = [
    { 
       filepath: Rails.root.join("public", "webpack", "production", "loadable-stats.json"),
       content_type: "application/json" 
    }
  ]
end
```

# Configuration

`config/initializers/react_on_rails_pro.rb`  

1. You don't need to create a initializer if you are satisfied with the defaults as described below.
1. Values beginning with `renderer` pertain only to using an external rendering server. You will need to ensure these values are consistent with your configuration for the external rendering server, as given in [JS configuration](https://www.shakacode.com/react-on-rails-pro/docs/node-renderer/js-configuration/)
1. `config.prerender_caching` works for standard mini_racer server rendering and using an external rendering server.

## Example of Configuration

Also see [spec/dummy/config/initializers/react_on_rails_pro.rb](https://github.com/shakacode/react_on_rails_pro/blob/master/spec/dummy/config/initializers/react_on_rails_pro.rb) for how the testing app is setup.

The below example is a typical production setup, using the separate `NodeRenderer`, where development takes the defaults when the ENV values are not specified.

```ruby
ReactOnRailsPro.configure do |config|
  # If true, then capture timing of React on Rails Pro calls including server rendering and
  # component rendering.
  # Default for `tracing` is false.
  config.tracing = true

  # Array of globs to find any files for which changes should bust the fragment cache for
  # cached_react_component and cached_react_component_hash. This should include any files used to
  # generate the JSON props, webpack and/or webpacker configuration files, and npm package lockfiles.
  # Default for `dependency_globs` is an empty array
  config.dependency_globs = [ File.join(Rails.root, "app", "views", "**", "*.jbuilder") ]

  # Array of globs to exclude from config.dependency_globs for ReactOnRailsPro cache key hashing
  # Default for `excluded_dependency_globs` is an empty array
  config.excluded_dependency_globs = [ File.join(Rails.root, "app", "views", "**", "dont_hash_this.jbuilder") ]

  # Remote bundle caching saves deployment time by caching bundles.
  # See /docs/bundle-caching.md for usage and an example of a module called S3BundleCacheAdapter.
  config.remote_bundle_cache_adapter = nil
  
  # ALL OPTIONS BELOW ONLY APPLY IF SERVER RENDERING

  # If true, then cache the evaluation of JS for prerendering using the standard Rails cache.
  # Applies to all rendering engines.
  # Default for `prerender_caching` is false.  
  config.prerender_caching = true

  # Retry request in case of time out on the node-renderer side
  # 5 - default, if not specified
  # 0 - no retry
  config.renderer_request_retry_limit = 5

  # NodeRenderer is for a renderer that is stateless. It does not need restarting when the JS bundles
  # are updated. It is the only custom renderer currently supported. Leave blank to use the standard
  # mini_racer rendering. Other option is NodeRenderer
  # Default for `server_renderer` is "ExecJS"
  config.server_renderer = "NodeRenderer"

  # React on Rails Node Renderer now support render functions returning promises! To enable this optional functionality,
  # toggle the following option.
  # Default is false.
  config.rendering_returns_promises = false

  # If you're using the NodeRenderer, a value of true allows errors to be thrown from the bundle
  # code for SSR so that an error tracking system on the NodeRender can use the exceptions.
  # If you are using ExecJS as your rendering method, set this to false.
  # Default is true.
  config.throw_js_errors = true

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

  # Set the `ssr_timeout` configuration so the Rails server will not wait more than this many seconds
  # for a SSR request to return once issued. 
  config.ssr_timeout = 5
  
  # If false, then crash if no backup rendering when the remote renderer is not available
  # Can be useful to set to false in development or testing to make sure that the remote renderer
  # works and any non-availability of the remote renderer does not just do ExecJS.
  # Suggest setting this to false if the SSR JS code cannot run in ExecJS
  # Default for `renderer_use_fallback_exec_js` is false.
  config.renderer_use_fallback_exec_js = false

  # The maximum size of the http connection pool,
  # Set +pool_size+ to limit the maximum number of connections allowed.
  # Defaults to 1/4 the number of allowed file handles.  You can have no more
  # than this many threads with active HTTP transactions.
  # Default for `renderer_http_pool_size` is 10
  config.renderer_http_pool_size = 10

  # Seconds to wait for an available connection before a timeout error is raised
  # Default for `renderer_http_pool_timeout` is 5
  config.renderer_http_pool_timeout = 5

  # warn_timeout  - Displays an error message if a request takes longer than the given time in seconds
  # (used to give hints to increase the pool size). Default is 0.25
  config.renderer_http_pool_warn_timeout = 0.25 # seconds

  # Snippet of JavaScript to be run right at the beginning of the server rendering process. The code
  # to be executed must either be self contained or reference some globally exposed module.  
  # For example, suppose that we had to call `SomeLibrary.clearCache()`between every call to server
  # renderer to ensure no leakage of state between calls. Note, SomeLibrary needs to be globally
  # exposed in the server rendering webpack bundle. This code is visible in the tracing of the calls
  # to do server rendering. Default is nil.
  config.ssr_pre_hook_js = "SomeLibrary.clearCache();"

  # When using the Node Renderer, you may require some extra assets in addition to the bundle.
  # The assets_to_copy option allows the Node Renderer to have assets copied at the end of
  # the assets:precompile task or directly by the
  # react_on_rails_pro:copy_assets_to_remote_vm_renderer task.
  # These assets are also transferred any time a new bundle is sent from Rails to the renderer.
  # The value should be a file_path or an Array of file_paths. The files should have extensions
  # to resolve the content types, such as "application/json".
  config.assets_to_copy = [
     Rails.root.join("public", "webpack", Rails.env, "loadable-stats.json"),
     Rails.root.join("public", "webpack", Rails.env, "manifest.json")
  ]

  ################################################################################
  # REACT SERVER COMPONENTS (RSC) CONFIGURATION
  ################################################################################

  # Enable React Server Components support
  # When enabled, React on Rails Pro will support RSC rendering and streaming
  # Default is false
  config.enable_rsc_support = true

  # Path to the RSC bundle file (relative to webpack output directory or absolute path)
  # The RSC bundle contains only server components and references to client components.
  # It's generated using the RSC Webpack Loader which transforms client components into
  # references. This bundle is specifically used for generating RSC payloads and is
  # configured with the 'react-server' condition.
  # Default is "rsc-bundle.js"
  config.rsc_bundle_js_file = "rsc-bundle.js"

  # Path to the React client manifest file (typically in your webpack output directory)
  # This manifest contains mappings for client components that need hydration.
  # It's automatically generated by the React Server Components Webpack plugin and is
  # required for client-side hydration of components.
  # Only set this if you've configured the plugin to use a different filename.
  # Default is "react-client-manifest.json"
  config.react_client_manifest_file = "react-client-manifest.json"

  # Path to the React server-client manifest file (typically in your webpack output directory)
  # This manifest is used during server-side rendering with RSC to properly resolve
  # references between server and client components.
  # It's automatically generated by the React Server Components Webpack plugin.
  # Only set this if you've configured the plugin to use a different filename.
  # Default is "react-server-client-manifest.json"
  config.react_server_client_manifest_file = "react-server-client-manifest.json"

  # These RSC configuration files are crucial when implementing React Server Components
  # with streaming, which offers benefits like:
  # - Reduced JavaScript bundle sizes
  # - Faster page loading
  # - Selective hydration of client components
  # - Progressive rendering with Suspense boundaries
end
```

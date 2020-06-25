# HMR and Hot Reloading with the webpack-dev-server

The webpack-dev-server provides:

1. Speedy compilation of client side assets
2. Optional HMR which means that the page will reload automatically when after
   compilation completes. Note, some developers do not like this, as you'll
   abruptly lose any tweaks within the Chrome development tools.
3. Optional hot-reloading. The older react-hot-loader has been deprecated in 
   favor of [fast-refresh](https://reactnative.dev/docs/fast-refresh).
   For use with webpack, see [react-refresh-webpack-plugin](https://github.com/pmmmwh/react-refresh-webpack-plugin).

If you are ***not*** using server-side rendering (***not*** using `prerender: true`),
then you can follow all the regular docs for using the `bin/webpack-dev-server` 
during development.


# Server Side Rendering with the Default rails/webpacker bin/webpack-dev-server

If you are using server-side rendering, then you have a couple options. The
recommended technique is to have a different webpack configuration for server
rendering.  




## If you use the same Webpack setup for your server and client bundles 
If you do use the webpack-dev-server for prerendering, be sure to set the
`config/initializers/react_on_rails.rb` setting of 

```
  config.same_bundle_for_client_and_server = true
```

`dev_server.hmr` maps to [devServer.hot](https://webpack.js.org/configuration/dev-server/#devserverhot).
This must be false if you're using the webpack-dev-server for client and server bundles.
 
`dev_server.inline` maps to [devServer.inline](https://webpack.js.org/configuration/dev-server/#devserverinline).
This must also be false.

If you don't configure these two to false, you'll see errors like:

* "ReferenceError: window is not defined" (if hmr is true)
* "TypeError: Cannot read property 'prototype' of undefined" (if inline is true)






# HMR and Hot Reloading with the webpack-dev-server

The `webpack-dev-server` provides:

1. Speedy compilation of client side assets
2. Optional HMR which means that the page will reload automatically when after
   compilation completes. Note, some developers do not like this, as you'll
   abruptly lose any tweaks within the Chrome development tools.
3. Optional hot-reloading. The older `react-hot-loader` has been deprecated in
   favor of [fast-refresh](https://reactnative.dev/docs/fast-refresh).
   For use with Webpack, see **Client Side rendering and HMR using react-refresh-webpack-plugin** section below or visit [react-refresh-webpack-plugin](https://github.com/pmmmwh/react-refresh-webpack-plugin) for additional details.

If you are **_not_** using server-side rendering (**_not_** using `prerender: true`),
then you can follow all the regular docs for using the `bin/shakapacker-dev-server`
during development.

# Server Side Rendering with the Default shakacode/shakapacker bin/shakapacker-dev-server

If you are using server-side rendering, then you have a couple of options. The
recommended technique is to have a different Webpack configuration for server
rendering.

## If you use the same Webpack setup for your server and client bundles

If you do use the `webpack-dev-server` for prerendering, be sure to set the
`config/initializers/react_on_rails.rb` setting of

```ruby
config.same_bundle_for_client_and_server = true
```

`dev_server.hmr` maps to [devServer.hot](https://webpack.js.org/configuration/dev-server/#devserverhot).
This must be false if you're using the webpack-dev-server for client and server bundles.

`dev_server.inline` maps to [devServer.inline](https://webpack.js.org/configuration/dev-server/#devserverinline).
This must also be false.

If you don't configure these two to false, you'll see errors like:

- `ReferenceError: window is not defined` (if `hmr` is true)
- `TypeError: Cannot read property 'prototype' of undefined` (if `inline` is true)

# Client-Side rendering with HMR using react-refresh-webpack-plugin

## Basic installation

To enable the HMR functionality, you have to use `./bin/shakapacker-dev-server`

1. In `config/shakapacker.yml` set `hmr` and `inline` `dev_server` properties to true.

   ```yaml
   dev_server:
     https: false
     host: localhost
     port: 3035
     public: localhost:3035
     hmr: true
     # Inline should be set to true if using HMR
     inline: true
   ```

2. Add react-refresh packages:

   ```bash
   yarn add -D @pmmmwh/react-refresh-webpack-plugin react-refresh
   ```

3. HMR is for use with the `webpack-dev-server`, so we only add this for the `webpack-dev-server`.

   ```js
   const { devServer } = require('shakapacker');

   const isWebpackDevServer = process.env.WEBPACK_DEV_SERVER;

   // plugins
   if (isWebpackDevServer) {
     environment.plugins.append(
       'ReactRefreshWebpackPlugin',
       new ReactRefreshWebpackPlugin({
         overlay: {
           sockPort: devServer.port,
         },
       }),
     );
   }
   ```

   We added `overlay.sockPort` option in `ReactRefreshWebpackPlugin` to match the webpack-dev-server port specified in `config/shakapacker.yml`. This makes SockJS works properly and fixes this error in browser console: `GET http://localhost:[port]/sockjs-node/info?t=[xxxxxxxxxx] 404 (Not Found)`. When using `ReactRefreshWebpackPlugin` with `v0.6.0` and newer, `overlay.sockPort` is [no longer supported](https://github.com/pmmmwh/react-refresh-webpack-plugin/pull/850) and should be omitted from the configurations.

4. Add the react-refresh plugin in `babel.config.js`

   ```js
   module.exports = function (api) {
     return {
       plugins: [process.env.WEBPACK_DEV_SERVER && 'react-refresh/babel'].filter(Boolean),
     };
   };
   ```

That's it :).
Now the browser should reflect changes in `.js` and `.css` files without reloading.

If for some reason the plugin doesn't work, you can revert the changes and leave only devServer `hmr`/`inline` set to true, affecting only CSS files.

These plugins are working and tested with

- babel 7
- webpacker 5
- bootstrap 4
- jest 26
- core-js 3
- node 12.10.0
- react-refresh-webpack-plugin@0.4.1
- react-refresh 0.8.3
- react_on_rails 11.1.4

configuration.

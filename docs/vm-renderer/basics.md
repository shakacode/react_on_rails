# Requirements
* You must React on Rails v11.0.7 or higher.

# Install the Gem and the Node Module
See [docs/installation.md](../installation.md).

# Setup Node VM Renderer Server
**Node.js** server for **react-on-rails-vm-renderer** is a standalone application to serve requests from **Rails** client. You don't need any **Ruby** code to setup and launch it. You can configure with the command line or with a launch file.

## Simple Command Line for vm-renderer

1. ENV values for the default config are (See [JS Configuration](./js-configuration.md) for more details):
    * `RENDERER_PORT`
    * `RENDERER_LOG_LEVEL`
    * `RENDERER_BUNDLE_PATH`
    * `RENDERER_WORKERS_COUNT`
    * `RENDERER_PASSWORD`
    * `RENDERER_ALL_WORKERS_RESTART_INTERVAL`
    * `RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS`
    * `RENDERER_SUPPORT_MODULES`
2. Configure ENV values and run the command. Note, you can set port with args `-p <PORT>`. For example, assuming vm-renderer is in your path:
   ```
   RENDERER_BUNDLE_PATH=/tmp/bundle-path vm-renderer
   ```
3. You can use a command line argument of `-p SOME_PORT` to override any ENV value for the PORT.

## JavaScript Configuration File
For the most control over the setup, create a JavaScript file to start the VmRenderer.

1. Create some project directory, let's say `renderer-app`:
   ```sh
   mkdir renderer-app
   cd renderer-app
   ```
2. Make sure you have **Node.js** version **8** or higher and **Yarn** installed.
3. Init node application and yarn add to install `react-on-rails-pro-vm-renderer` package.
   ```sh
   yarn init
   yarn add https://[your-github-token]:x-oauth-basic@github.com/shakacode/react_on_rails_pro.git\#master
   ```
3. Configure a JavaScript file that will launch the rendering server per the docs in [VM Renderer JavaScript Configuration](./js-configuration.md). For example, create a file `vm-renderer.js`. Here is a simple example that uses all the defaults except for bundlePath:

   ```javascript
   import path from 'path';
   import reactOnRailsProVmRenderer from 'react-on-rails-pro-vm-renderer';

   const config = {
     bundlePath: path.resolve(__dirname, '../tmp/bundles'),
   };

   reactOnRailsProVmRenderer(config);
   ```
5. Now you can launch your renderer server with `node vm-renderer.js`. You will probably add a script to your `package.json`.
6. You can use a command line argument of `-p SOME_PORT` to override any configured or ENV value for the port.

# Setup Rails Application
Create `config/initializers/react_on_rails_pro.rb` and configure the **renderer server**. See configuration values in [docs/configuration.md](../configuration.md). Pay attention to:

1. Set `config.server_renderer = "VmRenderer"`
1. Leave the default of `config.prerender_caching = true` and ensure your Rails cache is properly configured to handle the additional cache load.
1. Configure values beginning with `renderer_`
1. Use ENV values for values like `renderer_url` so that your deployed server is properly configured. If the ENV value is unset, the default for the renderer_url is `localhost:3800`.
1. Here's a tiny example using mostly defaults:
```ruby
ReactOnRailsPro.configure do |config|
 config.server_renderer = "VmRenderer"
 
 # when this ENV value is not defined, the local server at localhost:3800 is used 
 config.renderer_url = ENV["REACT_RENDERER_URL"] 
end
```

## Troublshooting

* See [JS Memory Leaks](../js-memory-leaks.md).
  
## Upgrading

The VmRenderer has a protocol version on both the Rails and Node sides. If the Rails server sends a protocol version that does not match the Node side, an error is returned. Ideally, you want to keep both the Rails and Node sides at the same version.

# References
* [Installation](../installation.md).
* [Rails Options for vm-renderer](../configuration.md)
* [JS Options for vm-renderer](./js-configuration.md)

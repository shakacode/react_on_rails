# React on Rails Pro

Node rendering and performance enhancements for React on Rails!

## Setup Node renderer server

**Node.js** server for **react-on-rails-vm-renderer** is a standalone application to serve requests from **Rails** client. You don't need any **Ruby** code to setup and launch it.

1. Create some project directory, let's say `renderer-app`:
   ```sh
   mkdir renderer-app
   cd renderer-app
   ```
2. Make sure you have **Node.js** version **8** or higher and **Yarn** installed.
3. Init node application and install `react-on-rails-pro-vm-renderer` package. Since the repository is private, you can generate and use **GitHub OAuth** token:
   ```sh
   yarn init
   yarn add https://[your-github-token]:x-oauth-basic@github.com/shakacode/react_on_rails_pro.git
   ```
4. Create entry point to config and launch renderer server, say `vm-renderer.js` with the following content. See **Renderer config** section below for available options.

   ```javascript
   const path = require('path');
   const reactOnRailsProVmRenderer = require('react-on-rails-pro-vm-renderer');

   const config = {
     bundlePath: path.resolve(__dirname, '../tmp/bundles'),
     port: 3800,
   };

   reactOnRailsProVmRenderer(config);
   ```
5. Now you can launch your renderer server with `node vm-renderer.js`.
6. If you do not plan to deploy renderer to **Heroku** or other hosting platforms, **do not forget to revoke your GitHub OAuth token!**

## Setup react_on_rails application

Assuming you already have your **Rails** app running on **react_on_rails** gem. To configure it to use **Node rendering**, do the following:

1. Add ruby gem to your **Gemfile**. Since the repository is private, you can generate and use **GitHub OAuth** token:
   ```ruby
   gem "react_on_rails_pro", git: "https://[your-github-token]:x-oauth-basic@github.com/shakacode/react_on_rails-pro.git"
   ```
2. Run `bundle install`.
3. Set `config.server_render_method = "VmRenderer"` in your `ReactOnRails.configure` block.
4. Create `config/initializers/react_on_rails_pro.rb` and configure a connection to **renderer server**. See **Rails client config** section below for available options.
   ```ruby
   ReactOnRailsPro.configure do |config|
     config.renderer_host = "localhost"
     config.renderer_port = 3800
   end
   ```
5. Now, if renderer server already started on port `3800` (see instructions above) you should be able to run your app normally with one of **procfiles**:
   ```sh
   foreman start -f Procfile.hot
   ```
6. If you do not plan to deploy your changes to **Heroku** or other hosting platforms, **do not forger to revoke your GitHub OAuth token!**

## Deploy Node renderer to Heroku

Assuming you did not revoke your **GitHub OAuth token** so you don't need to update your `package.json`:

1. Create your **Heroku** app with **Node.js** buildpack, say `renderer-test.herokuapp.com`.
2. Change port in your `vm-renderer.js` config to `process.env.PORT` so it will use port number provided by **Heroku** environment.
3. Set password in your `vm-renderer.js` to something like `process.env.AUTH_PASSWORD` and configure corresponding **ENV variable** on your **Heroku** dyno.
4. Run deployment process (usually by pushing changes to **Git** repo associated with created **Heroku** app).
5. Once deployment process is finished, renderer should start listening at `renderer-test.herokuapp.com` host.

## Deploy react_on_rails application to Heroku

Assuming you did not revoke your **GitHub OAuth token** so you don't need to update your `Gemfile`:

1. Create your **Heroku** app for `react_on_rails`, see [the doc on Heroku deployment](https://github.com/shakacode/react_on_rails/blob/master/docs/additional-reading/heroku-deployment.md#more-details-on-precompilation-using-webpack-to-create-javascript-assets).
2. Configure your app to communicate with renderer app you've created above. Put the following to your `initializers/react_on_rails_pro` (assuming you have **SSL** certificate uploaded to your renderer **Heroku** app or you use **Heroku** wildcard certificate under `*.herokuapp.com`) and configure corresponding **ENV variable** for the password on your **Heroku** dyno.
   ```ruby
     ReactOnRailsPro.configure do |config|
       config.server_render_method = "VmRenderer"
       config.renderer_protocol = "https"
       config.renderer_host = "renderer-test.herokuapp.com"
       config.renderer_port = 443
       config.password = ENV["RENDERER_PASSWORD"]
     end
   ```
3. Run deployment process (usually by pushing changes to **Git** repo associated with created **Heroku** app).
4. Once deployment process is finshed, all rendering requests form your `react_on_rails` app should be served by `renderer-test.herokuapp.com` app via **HTTPS**.
5. **Don't forget to revoke your GitHub OAuth tokens!**

## Renderer config

Here are the options available for renderer configuration object:

1. **bundlePath** (default: `undefined`) - Relative path to temp directory where uploaded bundle files will be stored. For example you can set it to `path.resolve(__dirname, '../tmp/bundles')` if you configured renderer form `app/client` directory. Note: you **must** pass this parameter to configuration.
2. **port** (default: `process.env.PORT || 3700`) - The port renderer should listen to.
3. **logLevel** (default: `'info'`) - Log lever for renderer. Set it to `'error'` to turn logging off. Available levels are: `{ error: 0, warn: 1, info: 2, verbose: 3, debug: 4, silly: 5 }`
4. **workersCount** (default: your CPUs number - 1) - Number of workers that will be forked to serve rendering requests. If you set this manually make sure that value is a **Number** and is `>= 1`.
5. **password** (default: `undefined`) - Password expected to receive form **Rails client** to authenticate rendering requests. If no password set, no authentication will be required.
6. **allWorkersRestartInterval** (default: `undefined`) - Interval in minutes between scheduled restarts of all cluster of workers. By default restarts are not enabled. If restarts are enabled, `delayBetweenIndividualWorkerRestarts` should also be set.
7. **delayBetweenIndividualWorkerRestarts** (default: `undefined`) - Interval in minutes between individual worker restarts (when cluster restart is triggered). By default restarts are not enabled. If restarts are enabled, `allWorkersRestartInterval` should also be set.

## Rails client config

Here are the options available for **react_on_rails_pro** configuration:

1. **server_render_method**: (default: nil) - Only option is "VmRenderer" to use the Node rendering server. Any other option uses Ruby Embedded JavaScript, aka [rails/execjs](https://github.com/rails/execjs).

### Options for VmRenderer
1. **renderer_protocol** (default: `"http"`) - Combined with **renderer_port** defines protocol type that will be used for renderer connection.
2. **renderer_host** (default: `"localhost"`) - Renderer host name without protocol and port.
3. **renderer_port** (default: `nil`) - Port that will be used to renderer connection. If not set - default HTTP port will be used.
4. **password** (default: `nil`) - Password that will be sent to renderer for simple authentication. **Note:** Don't forget to set up **SSL** connection otherwise password will useless since it will be easy to intercept it.

## Local deploy

Please see [CONTRIBUTING](CONTRIBUTING.md) if you want to deploy and test this project locally.

# Other References

* [Using Varnish for HTTP Caching](./docs/additional-reading/vm-renderer-with-varnish.md)

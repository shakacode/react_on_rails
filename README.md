# react-on-rails-renderer
Node rendering for React on Rails

## Setup Node renderer server

**Node.js** server for **react-on-rails-renderer** is a standalone application to serve requests form **Rails** client. You don't need any **Ruby** code to setup and launch it.

1. Create some project directory, let's say `renderer-app`:
```sh
mkdir renderer-app
cd renderer-app
```
2. Make sure you have **Node.js** version **6** or higher and **Yarn** installed.
3. Init node application and install `react-on-rails-renderer` package.  Since the repository is private, you can generate and use **GitHub OAuth** token:
```sh
yarn init
yarn add https://[your-github-token]:x-oauth-basic@github.com/shakacode/react-on-rails-renderer.git
```
4. Create entry point to config and launch renderer server, say `renderer.js` with the following content. See **Renderer config** section below for available options.
```javascript

const path = require('path');
const reactOnRailsRenderer = require('react-on-rails-renderer');

const config = {
  bundlePath: path.resolve(__dirname, '../tmp/bundles'),
  port: 3800,
};

reactOnRailsRenderer(config);
```
5. Now you can launch your renderer server with `node renderer.js`.
6. If you do not plan to deploy renderer to **Heroku** or other hosting platforms, **do not forger to revoke your GitHub OAuth token!**

## Setup react_on_rails application

Assuming you already have your **Rails** app running on **react_on_rails** gem. To configure it to use **Node rendering**, do the following:

1. Add ruby gem to your **Gemfile**. Since the repository is private, you can generate and use **GitHub OAuth** token:
```ruby
gem "react_on_rails_renderer", git: "https://[your-github-token]:x-oauth-basic@github.com/shakacode/react-on-rails-renderer.git"
```
2. Run `bundle install`.
3. Currently you have to monkeypatch `ReactOnRails::ServerRenderingPool` module at the end of `initializers/react_on_rails`:
```ruby
  module ReactOnRails
    module ServerRenderingPool
      class << self
        def pool
          if ReactOnRails.configuration.server_render_method == "NodeJS"
            ServerRenderingPool::Node
          elsif ReactOnRails.configuration.server_render_method == "NodeJSHttp"
            ReactOnRailsRenderer::RenderingPool
          else
            ServerRenderingPool::Exec
          end
        end

        # rubocop:disable Style/MethodMissing
        def method_missing(sym, *args, &block)
          pool.send sym, *args, &block
        end
      end
    end
  end
```
4. Set `config.server_render_method = "NodeJSHttp"` in your  `ReactOnRails.configure` block.

5. Create `initializers/react_on_rails_renderer` initializer and configure connection to **renderer server**. See **Rails client config** section below for available options.
```ruby
ReactOnRailsRenderer.configure do |config|
  config.renderer_host = "localhost"
  config.renderer_port = 3800
end
```
6. Now, if renderer server already started on port `3800` (see instructions above) you should be able to run your app normally with one of **procfiles**:
```sh
foreman start -f Procfile.hot
```
7. If you do not plan to deploy your changes to **Heroku** or other hosting platforms, **do not forger to revoke your GitHub OAuth token!**

## Deploy Node renderer to Heroku
Assuming you did not revoke your  **GitHub OAuth token** so you don't need to update your `package.json`:
1. Create your **Heroku** app with **Node.js** buildpack, say `renderer-test.herokuapp.com`.
2. Change port in your `renderer.js` config to `process.env.PORT` so it will use port number provided by **Heroku** environment.
3. Set password in your `renderer.js` to something like `process.env.AUTH_PASSWORD` and configure corresponding **ENV variable** on your **Heroku** dyno.
3. Run deployment process (usually by pushing changes to **Git** repo associated with created **Heroku** app).
4. Once deployment process is finshed, renderer should start listening at `renderer-test.herokuapp.com` host.

## Deploy react_on_rails application to Heroku
Assuming you did not revoke your  **GitHub OAuth token** so you don't need to update your `Gemfile`:
1. Create your **Heroku** app for `react_on_rails`, see [the doc on Heroku deployment](https://github.com/shakacode/react_on_rails/blob/master/docs/additional-reading/heroku-deployment.md#more-details-on-precompilation-using-webpack-to-create-javascript-assets).
2. Configure your app to communicate with renderer app you've created above. Put the following to your `initializers/react_on_rails_renderer` (assuming you have **SSL** sertificate uploaded to your renderer **Heroku** app or you use **Heroku** wildcard sertificate under `*.herokuapp.com`) and configure corresponding **ENV variable** for the password on your **Heroku** dyno.
```ruby
  ReactOnRailsRenderer.configure do |config|
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

## Rails client config
Here are the options available for **react_on_rails_renderer** configuration:
1. **renderer_protocol** (default: `"http"`) - Combined with **renderer_port** defines protocol type that will be used for renderer connection.
2. **renderer_host** (default: `"localhost"`) - Renderer host name without protocol and port.
3. **renderer_port** (default: `nil`) - Port that will be used to renderer connection. If not set - default HTTP port will be used.
4. **password** (default: `nil`) - Password that will be sent to renderer for simple authentication. **Note:** Don't forget to set up **SSL** connection otherwise password will useless since it will be easy to intercept it.

## Local deploy
Please see [CONTRIBUTING](CONTRIBUTING.md) if you want to deploy and test this project locally.

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
4. Create entry point to config and launch renderer server, say `renderer.js` with the following content:
```javascript

const path = require('path');
const reactOnRailsRenderer = require('react-on-rails-renderer');

const config = {
  bundlePath: path.resolve(__dirname, '../tmp'),
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

5. Create `initializers/react_on_rails_renderer` initializer and configure connection to **renderer server**:
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
3. Run deployment process (usually by pushing changes to **Git** repo associated with created **Heroku** app).
4. Once deployment process is finshed, renderer should start listening at `renderer-test.herokuapp.com` host.

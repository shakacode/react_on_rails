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
3. Init node application and install `react-on-rails-renderer` package. Since the repository is private, you can generate and use **GitHub OAuth** token:

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

4. Set `config.server_render_method = "NodeJSHttp"` in your `ReactOnRails.configure` block.

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

## Using Varnish HTTP cache locally

It is possible to use **Varnish** HTTP cache to avoid repeating rendering requests. It can speed up rendering and reduce load on Node processes.
Unfortunately **Varnish** does not cache `POST` requests by default and supports `POST` requests caching only starting form v5.x.x. So to use renderer with **Varnish** you need to:

1. Install **Varnish v5+**. See [Varnish releases & downloads page](https://varnish-cache.org/releases/index.html) to find installation instructions for your OS.
2. Since **Varnish** does not cache `POST` requests by default, you have to configure it using [VCL](https://www.varnish-cache.org/docs/5.1/users-guide/vcl.html). See [Changes in Varnish 5.0](https://www.varnish-cache.org/docs/5.0/whats-new/changes-5.0.html#request-body-sent-always-cacheable-post) for additional info. Open your **default.vcl** file (usually at **/etc/varnish/default.vcl**) and put this config (replace matching methods if some empty examples already exist):

```sh
# Default backend definition. Set this to point to your content server.
backend default {
    .host = "127.0.0.1";
    .port = "3800";
}

sub vcl_recv {
    # Happens before we check if we have this in cache already.
    #
    # Typically you clean up the request here, removing cookies you don't need,
    # rewriting the request, etc.

    if (req.method == "PRI") {
	/* We do not support SPDY or HTTP/2.0 */
	return (synth(405));
    }

    if (req.method != "GET" &&
      req.method != "HEAD" &&
      req.method != "PUT" &&
      req.method != "POST" &&
      req.method != "TRACE" &&
      req.method != "OPTIONS" &&
      req.method != "DELETE") {
        /* Non-RFC2616 or CONNECT which is weird. */
        return (pipe);
    }

    if (req.method != "GET" && req.method != "HEAD" && req.method != "POST") {
        return (pass);
    }

    if (req.method == "POST") {
	set req.http.x-method = req.method;
    }

    if (req.http.Authorization || req.http.Cookie) {
        /* Not cacheable by default */
        return (pass);
    }

    return (hash);
}

sub vcl_backend_fetch {
    set bereq.method = bereq.http.x-method;
    return (fetch);
}
```

3. Restart/launch your **Varnish** service: `(sudo) service varnish (re)start`
4. Point your Rails client to **Varnish** standart port:

```ruby
ReactOnRailsRenderer.configure do |config|
  config.renderer_host = "localhost"
  config.renderer_port = 6081
end
```

Currently Rails client prints response headers to console so you should be able to check if **Varnish** caches Reails client requests by inspecting printed `x-varnish` header. For example `:x_varnish=>"37719 37717"` means that **Varnish** returned response from cache (result to your request `#37719` returned from cache created on request `#37717`) and `:x_varnish=>"37721"` (with single id) means request hit Node server. If everything set up correctly you should see cached requests starting form second render of the same page.

## Deploy Node renderer to Heroku

Assuming you did not revoke your **GitHub OAuth token** so you don't need to update your `package.json`:

1. Create your **Heroku** app with **Node.js** buildpack, say `renderer-test.herokuapp.com`.
2. Change port in your `renderer.js` config to `process.env.PORT` so it will use port number provided by **Heroku** environment.
3. Set password in your `renderer.js` to something like `process.env.AUTH_PASSWORD` and configure corresponding **ENV variable** on your **Heroku** dyno.
4. Run deployment process (usually by pushing changes to **Git** repo associated with created **Heroku** app).
5. Once deployment process is finished, renderer should start listening at `renderer-test.herokuapp.com` host.

## Deploy react_on_rails application to Heroku

Assuming you did not revoke your **GitHub OAuth token** so you don't need to update your `Gemfile`:

1. Create your **Heroku** app for `react_on_rails`, see [the doc on Heroku deployment](https://github.com/shakacode/react_on_rails/blob/master/docs/additional-reading/heroku-deployment.md#more-details-on-precompilation-using-webpack-to-create-javascript-assets).
2. Configure your app to communicate with renderer app you've created above. Put the following to your `initializers/react_on_rails_renderer` (assuming you have **SSL** certificate uploaded to your renderer **Heroku** app or you use **Heroku** wildcard certificate under `*.herokuapp.com`) and configure corresponding **ENV variable** for the password on your **Heroku** dyno.

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
6. **allWorkersRestartInterval** (default: `undefined`) - Interval in minutes between scheduled restarts of all cluster of workers. By default restarts are not enabled. If restarts are enabled, `delayBetweenIndividualWorkerRestarts` should also be set.
7. **delayBetweenIndividualWorkerRestarts** (default: `undefined`) - Interval in minutes between individual worker restarts (when cluster restart is triggered). By default restarts are not enabled. If restarts are enabled, `allWorkersRestartInterval` should also be set.

## Rails client config

Here are the options available for **react_on_rails_renderer** configuration:

1. **renderer_protocol** (default: `"http"`) - Combined with **renderer_port** defines protocol type that will be used for renderer connection.
2. **renderer_host** (default: `"localhost"`) - Renderer host name without protocol and port.
3. **renderer_port** (default: `nil`) - Port that will be used to renderer connection. If not set - default HTTP port will be used.
4. **password** (default: `nil`) - Password that will be sent to renderer for simple authentication. **Note:** Don't forget to set up **SSL** connection otherwise password will useless since it will be easy to intercept it.

## Local deploy

Please see [CONTRIBUTING](CONTRIBUTING.md) if you want to deploy and test this project locally.

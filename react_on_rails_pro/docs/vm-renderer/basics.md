# Requirements
* You must React on Rails v11.0.7 or higher.



# Setup Node VM Renderer Server

**Node.js** server for **react-on-rails-vm-renderer** is a standalone application to serve requests from **Rails** client. You don't need any **Ruby** code to setup and launch it.

1. Create some project directory, let's say `renderer-app`:
   ```sh
   mkdir renderer-app
   cd renderer-app
   ```
2. Make sure you have **Node.js** version **8** or higher and **Yarn** installed.
3. Init node application and install `react-on-rails-pro-vm-renderer` package. Since the repository is private, you can generate and use a **GitHub OAuth** token. You should use a token that ONLY grants read access to this repo rather than access to all your repositories. Ask [justin@shakacode.com](mailto:justin@shakacode.com) to give you one.
   ```sh
   yarn init
   yarn add https://[your-github-token]:x-oauth-basic@github.com/shakacode/react_on_rails_pro.git
   ```
3. Configure a JavaScript file that will launch the rendering server. See docs in [js-configuration.md](./js-configuration.md). For example, create a file `vm-renderer.js` with the content as described in [VM Renderer JavaScript Configuration](./js-configuration.md). Here is a simple example that uses all the defaults:

   ```javascript
   const path = require('path');
   const reactOnRailsProVmRenderer = require('react-on-rails-pro-vm-renderer');

   const config = {
     bundlePath: path.resolve(__dirname, '../tmp/bundles'),
   };

   reactOnRailsProVmRenderer(config);
   ```
5. Now you can launch your renderer server with `node vm-renderer.js`. You will probably add a script to your `package.json`.

## Setup react_on_rails application
Assuming you already have your **Rails** app running on **react_on_rails** gem. To configure it to use **Node rendering**, do the following:
1. Add the `react_on_rails_pro` gem to your **Gemfile**. Since the repository is private, you will use the same **GitHub OAuth** token as described above:
   ```ruby
   gem "react_on_rails_pro", git: "https://[your-github-token]:x-oauth-basic@github.com/shakacode/react_on_rails-pro.git"
   ```
2. Run `bundle install`.
3. Create `config/initializers/react_on_rails_pro.rb` and configure the **renderer server**. See configuration values in [docs/configuration.md](../configuration.md). Pay attention to:
  1. Set `config.server_renderer = "VmRenderer"`
  1. Leave the default of `config.prerender_caching = true` and ensure your Rails cache is properly configured to handle the additional cache load.
  1. Configure values beginning with `renderer_`
  1. Use ENV values for values like `renderer_url` so that your deployed server is properly configured. If the ENV value is unset, the default for the renderer_url is `localhost:3800`.
  1. Here's a tiny example using mostly defaults:
  ```ruby
  ReactOnRailsPro.configure do |config|
   config.server_renderer = "VmRenderer"
   config.renderer_url = ENV["REACT_RENDERER_URL"]
  end
  ```  

## Deploy Node renderer to Heroku

1. Create your **Heroku** app with **Node.js** buildpack, say `renderer-test.herokuapp.com`.
2. Change port in your `vm-renderer.js` config to `process.env.PORT` so it will use port number provided by **Heroku** environment.
3. Set password in your `vm-renderer.js` to something like `process.env.AUTH_PASSWORD` and configure corresponding **ENV variable** on your **Heroku** dyno.
4. Run deployment process (usually by pushing changes to **Git** repo associated with created **Heroku** app).
5. Once deployment process is finished, renderer should start listening at `renderer-test.herokuapp.com` host.

## Deploy react_on_rails application to Heroku

1. Create your **Heroku** app for `react_on_rails`, see [the doc on Heroku deployment](https://github.com/shakacode/react_on_rails/blob/master/docs/additional-reading/heroku-deployment.md#more-details-on-precompilation-using-webpack-to-create-javascript-assets).
2. Configure your app to communicate with renderer app you've created above. Put the following to your `initializers/react_on_rails_pro` (assuming you have **SSL** certificate uploaded to your renderer **Heroku** app or you use **Heroku** wildcard certificate under `*.herokuapp.com`) and configure corresponding **ENV variable** for the render_url and/or password on your **Heroku** dyno.
3. Run deployment process (usually by pushing changes to **Git** repo associated with created **Heroku** app).
4. Once deployment process is finshed, all rendering requests form your `react_on_rails` app should be served by `renderer-test.herokuapp.com` app via **HTTPS**.
5. **Don't forget to revoke your GitHub OAuth tokens!**

### Options for VmRenderer
See [configuration.md](../configuration.md)


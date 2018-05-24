# Requirements
* You must React on Rails v11.0.7 or higher.

# Setup Node VM Renderer Server
**Node.js** server for **react-on-rails-vm-renderer** is a standalone application to serve requests from **Rails** client. You don't need any **Ruby** code to setup and launch it. You can configure with the command line or with a launch file.

## Simple Command Line

1. Install the vm-renderer executable. Substitute the branch name or tag for `master`
   ```
   yarn global add https://<your-github-token>:x-oauth-basic@github.com/shakacode/react_on_rails_pro.git\#master
   ```
1. ENV values for the default config are (See [JS Configuration](./js-configuration.md) for more details):
  * PORT
  * LOG_LEVEL
  * RENDERER_BUNDLE_PATH
  * RENDERER_WORKERS_COUNT
  * RENDERER_PASSWORD
  * RENDERER_ALL_WORKERS_RESTART_INTERVAL
  * RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS
2. Configure ENV values and run the command. Note, you can set port with args `-p <PORT>`. For example:
   ```
   RENDERER_BUNDLE_PATH=/tmp/bundle-path vm-renderer
   ```

## Configuration file

1. Create some project directory, let's say `renderer-app`:
   ```sh
   mkdir renderer-app
   cd renderer-app
   ```
2. Make sure you have **Node.js** version **8** or higher and **Yarn** installed.
3. Init node application and yarn add to install `react-on-rails-pro-vm-renderer` package. Since the repository is private, you can generate and use a **GitHub OAuth** token. You should use a token that ONLY grants read access to this repo rather than access to all your repositories. Ask [justin@shakacode.com](mailto:justin@shakacode.com) to give you one.
   ```sh
   yarn init
   yarn add https://[your-github-token]:x-oauth-basic@github.com/shakacode/react_on_rails_pro.git\#master
   ```
3. Configure a JavaScript file that will launch the rendering server. See docs in [js-configuration.md](./js-configuration.md). For example, create a file `vm-renderer.js` with the content as described in [VM Renderer JavaScript Configuration](./js-configuration.md). Here is a simple example that uses all the defaults except for bundlePath:

   ```javascript
   import path from 'path';
   import reactOnRailsProVmRenderer from 'react-on-rails-pro-vm-renderer';

   const config = {
     bundlePath: path.resolve(__dirname, '../tmp/bundles'),
   };

   reactOnRailsProVmRenderer(config);
   ```
5. Now you can launch your renderer server with `node vm-renderer.js`. You will probably add a script to your `package.json`.

# Setup react_on_rails application
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
   
   # when this ENV value is not defined, the local server at localhost:3800 is used 
   config.renderer_url = ENV["REACT_RENDERER_URL"] 
  end
  ```  
  
# Heroku
## Deploy Node renderer to Heroku

1. Create your **Heroku** app with **Node.js** buildpack, say `renderer-test.herokuapp.com`.
2. If using a custom configuration file:
   1. If setting the port, ensure the port uses `process.env.PORT` so it will use port number provided by **Heroku** environment. The default is to use the env value PORT if available.
   2. Set password in your configuration to something like `process.env.RENDERER_PASSWORD` and configure the corresponding **ENV variable** on your **Heroku** dyno.
3. Run deployment process (usually by pushing changes to **Git** repo associated with created **Heroku** app).
4. Once deployment process is finished, renderer should start listening at `renderer-test.herokuapp.com` host.

## Deploy react_on_rails application to Heroku

1. Create your **Heroku** app for `react_on_rails`, see [the doc on Heroku deployment](https://github.com/shakacode/react_on_rails/blob/master/docs/additional-reading/heroku-deployment.md#more-details-on-precompilation-using-webpack-to-create-javascript-assets).
2. Configure your app to communicate with renderer app you've created above. Put the following to your `initializers/react_on_rails_pro` (assuming you have **SSL** certificate uploaded to your renderer **Heroku** app or you use **Heroku** wildcard certificate under `*.herokuapp.com`) and configure corresponding **ENV variable** for the render_url and/or password on your **Heroku** dyno.
3. Run deployment process (usually by pushing changes to **Git** repo associated with created **Heroku** app).
4. Once deployment process is finshed, all rendering requests form your `react_on_rails` app should be served by `renderer-test.herokuapp.com` app via **HTTPS**.

# References
* [Rails Options for vm-renderer](../configuration.md)
* [JS Options for vm-renderer](./js-configuration.md)



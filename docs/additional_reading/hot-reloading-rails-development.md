# Hot Reloading of Assets For Rails Development

This document outlines the steps to setup your React On Rails Environment so that you can experience the pleasure of hot reloading of JavaScript and Sass during your Rails development work. There are 2 examples of this setup:
1. [spec/dummy](../spec/dummy): Simpler setup used for integration testing this gem.
1. [shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/). Full featured setup using Twitter bootstrap.

## High Level Strategy

We'll use a Webpack Dev server on port 3500 to provide the assets to Rails, rather than the asset pipeline, and only during development mode. This is configured via the `Procfile.hot`. 

`Procfile.static` provides an alternative that uses "static" assets, similar to a production deployment.

The secret sauce is in the [app/views/layouts/application.html.erb](spec/dummy/app/views/layouts/application.html.erb) where it uses view helpes to configure the correct assets to load, being either the "hot" assets or the "static" assets.

## Places to Configure (Files to Examine)

1. See the Webpack config files. Note, these examples are now setup for using [CSS Modules](https://github.com/css-modules/css-modules).
   1. [client/webpack.client.base.config.js](spec/dummy/client/webpack.client.base.config.js): Common configuration for hot or static assets.
   1. [client/webpack.client.hot.config.js](spec/dummy/client/webpack.client.hot.config.js): Setup for hot loading, using react-transform-hmr.
   1. [client/webpack.client.static.config.js](spec/dummy/client/webpack.client.static.config.js): Setup for static loading, as is done in a production deployment.
1. [app/views/layouts/application.html.erb](spec/dummy/app/views/layouts/application.html.erb): Uses the view helpers `env_stylesheet_link_tag` and `env_javascript_include_tag` which will either do the hot reloading or the static loading.
1. See the Procfiles: [Procfile.hot](spec/dummy/Procfile.hot) and [Procfile.static](spec/dummy/Procfile.static). These:
   1. Start the webpack processes, depending on the mode or HOT or not.
   2. Start the rails server, setting an ENV value of REACT_ON_RAILS_ENV to HOT if we're hot loading or else setting this to blank.
1. Configure the file Rails asset pipeline files:
   1. [app/assets/javascripts/application_static.js.erb](spec/dummy/app/assets/javascripts/application_static.js.erb): We have to only specify the `vendor-bundle` and `app-bundle` if we're not HOT loading, as Sprockets will throw an error if that is the case. Note the use of `require_asset`.
   1. [app/assets/stylesheets/application_static.js.erb](spec/dummy/app/assets/stylesheets/application_static.scss.erb): We have to only specify the `vendor-bundle` and `app-bundle` if we're not HOT loading, as Sprockets will throw an error if that is the case. Note the conditional around the @import.
1. Be sure your [config/initializers/assets.rb](spec/dummy/config/initializers/assets.rb) is configured to include the webpack generated files.
1. Copy the [client/server-rails-hot.js](spec/dummy/client/server-rails-hot.js) to the [client](client) directory.
1. Copy the scripts in the top level and client level `package.json` files:
   1. Top Level: [package.json](spec/dummy/package.json)
   1. Client Level: [package.json](spec/dummy/client/package.json)

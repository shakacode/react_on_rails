# Live Reloading vs. Hot Reloading (aka HMR)

The use of the [webpack-dev-server](https://webpack.js.org/configuration/dev-server/) provides "Live Reloading" by default. The difference between live and hot reloading is that live reloading will act similarly to hitting refresh in the browser. Hot reloading will attempt to preserve the state of any props.

See the Webpack document [Hot Module Replacement](https://webpack.js.org/concepts/hot-module-replacement/) for more details on the concepts of live vs. hot reloading.

The remainder of this document discusses HMR.

# Using the Webpacker Webpack setup

If you are using the default Webpacker setup of running the dev server with `bin/webpack-dev-server`, see the [Webpacker Webpack Dev Server discussion of HMR](https://github.com/rails/webpacker/blob/master/docs/webpack-dev-server.md#hot-module-replacement).


# Hot Reloading of Assets For Rails Development

_Note, this document is not yet updated for React on Rails v8+. See [PR #865](https://github.com/shakacode/react_on_rails/pull/865) for a detailed example of doing hot reloading using V8+ with Webpack v2. Any volunteers to update this page? See [#772](https://github.com/shakacode/react_on_rails/issues/772) and [#361](https://github.com/shakacode/react-webpack-rails-tutorial/issues/361)._

------

This document outlines the steps to setup your React On Rails Environment so that you can experience the pleasure of hot reloading of JavaScript and Sass during your Rails development work. See [Issue 332](https://github.com/shakacode/react_on_rails/issues/332) for troubleshooting. There are 3 examples of this setup:

1. [minimal demo here](https://github.com/retroalgic/react-on-rails-hot-minimal): The most simple and updated hot reloading setup.
1. [spec/dummy](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy): Simpler setup used for integration testing this gem.
1. [shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/). Full featured setup using Twitter bootstrap.

## Help Wanted

This doc might be outdated. PRs welcome!

## High Level Strategy

We'll use a Webpack Dev server on port 3500 to provide the assets to Rails, rather than the asset pipeline, and only during development mode. This is configured via the `Procfile.hot`. 

`Procfile.static` provides an alternative that uses "static" assets, similar to a production deployment.

## Places to Configure (Files to Examine)

1. See the Webpack config files. Note, these examples are now setup for using [CSS Modules](https://github.com/css-modules/css-modules).
   1. [client/webpack.client.base.config.js](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/client/webpack.client.base.config.js): Common configuration for hot or static assets.
   1. [client/webpack.client.rails.hot.config.js](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/client/webpack.client.rails.hot.config.js): Setup for hot loading, using react-transform-hmr.
   1. [client/webpack.client.rails.build.config.js](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/client/webpack.client.rails.build.config.js): Setup for static loading, as is done in a production deployment.
1. [app/views/layouts/application.html.erb](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/app/views/layouts/application.html.erb): Uses the view helpers `env_stylesheet_link_tag` and `env_javascript_include_tag` which will either do the hot reloading or the static loading.
1. See the Procfiles: [Procfile.hot](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/Procfile.hot) and [Procfile.static](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/Procfile.static). These:
   1. Start the webpack processes, depending on the mode or HOT or not.
   2. Start the rails server, setting an ENV value of REACT_ON_RAILS_ENV to HOT if we're hot loading or else setting this to blank.
1. Configure the file Rails asset pipeline files:
   1. [app/assets/javascripts/application_static.js](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/app/assets/javascripts/application_static.js) 
   1. [app/assets/stylesheets/application_non_webpack.scss](https://github.com/shakacode/react_on_rails/blob/master/spec/dummy/app/assets/stylesheets/application_non_webpack.scss)
1. Copy the [client/server-rails-hot.js](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/client/server-rails-hot.js) to the your client directory.
1. Copy the scripts in the top level and client level `package.json` files:
   1. Top Level: [package.json](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/package.json)
   1. Client Level: [package.json](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/client/package.json)


## Code Snippets
Please refer to the examples linked above in `spec/dummy` as these code samples might be out of date.


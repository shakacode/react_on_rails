# Hot Reloading of Assets For Rails Development

This document outlines the steps to setup your React On Rails Environment so that you can experience the pleasure of hot reloading of JavaScript and Sass during your Rails development work. There are 2 examples of this setup:

1. [spec/dummy](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy): Simpler setup used for integration testing this gem.
1. [shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/). Full featured setup using Twitter bootstrap.

## High Level Strategy

We'll use a Webpack Dev server on port 3500 to provide the assets to Rails, rather than the asset pipeline, and only during development mode. This is configured via the `Procfile.hot`. 

`Procfile.static` provides an alternative that uses "static" assets, similar to a production deployment.

The secret sauce is in the [app/views/layouts/application.html.erb](../../spec/dummy/app/views/layouts/application.html.erb) where it uses view helps to configure the correct assets to load, being either the "hot" assets or the "static" assets.

## Places to Configure (Files to Examine)

1. See the Webpack config files. Note, these examples are now setup for using [CSS Modules](https://github.com/css-modules/css-modules).
   1. [client/webpack.client.base.config.js](../../spec/dummy/client/webpack.client.base.config.js): Common configuration for hot or static assets.
   1. [client/webpack.client.rails.hot.config.js](../../spec/dummy/client/webpack.client.rails.hot.config.js): Setup for hot loading, using react-transform-hmr.
   1. [client/webpack.client.rails.build.config.js](../../spec/dummy/client/webpack.client.rails.build.config.js): Setup for static loading, as is done in a production deployment.
1. [app/views/layouts/application.html.erb](../../spec/dummy/app/views/layouts/application.html.erb): Uses the view helpers `env_stylesheet_link_tag` and `env_javascript_include_tag` which will either do the hot reloading or the static loading.
1. See the Procfiles: [Procfile.hot](../../spec/dummy/Procfile.hot) and [Procfile.static](../../spec/dummy/Procfile.static). These:
   1. Start the webpack processes, depending on the mode or HOT or not.
   2. Start the rails server, setting an ENV value of REACT_ON_RAILS_ENV to HOT if we're hot loading or else setting this to blank.
1. Configure the file Rails asset pipeline files:
   1. [app/assets/javascripts/application_static.js](../../spec/dummy/app/assets/javascripts/application_static.js) 
   1. [app/assets/stylesheets/application_static.css.scss](../../spec/dummy/app/assets/stylesheets/application_static.css.scss)
1. Be sure your [config/initializers/assets.rb](../../spec/dummy/config/initializers/assets.rb) is configured to include the webpack generated files.
1. Copy the [client/server-rails-hot.js](../../spec/dummy/client/server-rails-hot.js) to the your client directory.
1. Copy the scripts in the top level and client level `package.json` files:
   1. Top Level: [package.json](../../spec/dummy/package.json)
   1. Client Level: [package.json](../../spec/dummy/client/package.json)


## Code Snippets
Please refer to the examples linked above in `spec/dummy` as these code samples might be out of date.


### config/initializers/assets.rb

```ruby
# Add folder with webpack generated assets to assets.paths
Rails.application.config.assets.paths << Rails.root.join("app", "assets", "webpack")

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile << "server-bundle.js"

type = ENV["REACT_ON_RAILS_ENV"] == "HOT" ? "non_webpack" : "static"
Rails.application.config.assets.precompile +=
  [
    "application_#{type}.js",
    "application_#{type}.css"
  ]
```

### app/views/layouts/application.html.erb

```erb
<head>
  <title>Dummy</title>

  <!-- These do use turbolinks 5 -->
  <%= env_stylesheet_link_tag(static: 'application_static',
                              hot: 'application_non_webpack',
                              media: 'all',
                              'data-turbolinks-track' => "reload") %>

  <!-- These do not use turbolinks, so no data-turbolinks-track -->
  <!-- This is to load the hot assets. -->
  <%= env_javascript_include_tag(hot: ['http://localhost:3500/vendor-bundle.js',
                                       'http://localhost:3500/app-bundle.js']) %>

  <!-- These do use turbolinks 5 -->
  <%= env_javascript_include_tag(static: 'application_static',
                                 hot: 'application_non_webpack',
                                 'data-turbolinks-track' => "reload") %>

  <%= csrf_meta_tags %>
</head>
```

### Procfile.static
```
  # Run Rails without hot reloading (static assets).
  rails: REACT_ON_RAILS_ENV= rails s -b 0.0.0.0
  
  # Build client assets, watching for changes.
  rails-client-assets: npm run build:dev:client
  
  # Build server assets, watching for changes. Remove if not server rendering.
  rails-server-assets: npm run build:dev:server
```

### Procfile.hot

```
# Procfile for development with hot reloading of JavaScript and CSS 

# Development rails requires both rails and rails-assets
# (and rails-server-assets if server rendering)
rails: REACT_ON_RAILS_ENV=HOT rails s -b 0.0.0.0

# Run the hot reload server for client development
hot-assets: HOT_RAILS_PORT=3500 npm run hot-assets

# Keep the JS fresh for server rendering. Remove if not server rendering
rails-server-assets: npm run build:dev:server
```


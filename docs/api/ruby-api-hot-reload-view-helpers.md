## NOTE: These helpers are NOT needed if using webpacker

## Hot Reloading View Helpers
The `env_javascript_include_tag` and `env_stylesheet_link_tag` support the usage of a webpack dev server for providing the JS and CSS assets during development mode. See the [shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/) for a working example.

The key options are `static` and `hot` which specify what you want for static vs. hot. Both of these params are optional, and support either a single value, or an array.

static vs. hot is picked based on whether `ENV["REACT_ON_RAILS_ENV"] == "HOT"`

```erb
 <%= env_stylesheet_link_tag(static: 'application_static',
                             hot: 'application_non_webpack',
                             media: 'all',
                             'data-turbolinks-track' => true)  %>

 <!-- These do not use turbolinks, so no data-turbolinks-track -->
 <!-- This is to load the hot assets. -->
 
 <!-- Note, you can have multiple files here. It's an array. -->
 <%= env_javascript_include_tag(hot: ['http://localhost:3500/hello-world-bundle.js]') %>

 <!-- These do use turbolinks -->
 <%= env_javascript_include_tag(static: 'application_static',
                                hot: 'application_non_webpack',
                                'data-turbolinks-track' => true) %>
```

See application.html.erb for usage example and [application.html.erb](https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/app%2Fviews%2Flayouts%2Fapplication.html.erb)

Helper to set CSS and JS assets depending on if we want static or "hot", which means from the Webpack dev server.

In this example, `application_non_webpack` is simply a CSS asset pipeline file which includes styles not placed in the webpack build. The same can be said for `application_non_webpack` for JS files. Note, the suffix is not used in the helper calls.

We don't need styles from the webpack build, as those will come via the JavaScript include tags.

The key options are `static` and `hot` which specify what you want for static vs. hot. Both of
these params are optional, and support either a single value, or an array.

```erb
 <%= env_stylesheet_link_tag(static: 'application_static',
                             hot: 'application_non_webpack',
                             media: 'all',
                             'data-turbolinks-track' => true)  %>
```

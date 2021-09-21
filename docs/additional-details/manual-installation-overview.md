# Manual Installation Overview

TODO: Review this file


This file summarizes what the React on Rails generator does.

## Configure the `/client` Directory

This directory has no references to Rails outside of the destination directory for the files created by the various Webpack config files.

The only requirements within this directory for basic React on Rails integration are:

1. Your webpack configuration files:
   1. Create outputs in a directory like `/public/webpack`, which is customizable in your `config/initializers/react_on_rails.rb`.
   1. Provide server rendering if you wish to use that feature.
1. Your JavaScript code "registers" any components and stores per the ReactOnRails APIs of ReactOnRails.register(components) and ReactOnRails.registerStore(stores). See [our javascript API docs](https://www.shakacode.com/react-on-rails/docs/api/javascript-api/) and the [ReactOnRails.js source](https://github.com/shakacode/react_on_rails/tree/master/node_package/src/ReactOnRails.js).
1. Set your registration file as an "entry" point in your Webpack configs.
1. Add the [Manifest plugin](https://github.com/danethurber/webpack-manifest-plugin) to your config.
The default path: `public/webpack` can be loaded with webpackConfigLoader as shown in the dummy example.
1. You create scripts in `client/package.json` per the example apps. These are used for building your Webpack assets. Also do this for your top level `package.json`.

## Rails Steps (outside of /client)
1. Add  `gem "webpacker"` to the Gemfile, run bundle. The gem provides the `stylesheet_pack_tag` and `javascript_pack_tag` helpers which is used to load the bundled assets to your layouts.[Dummy Example](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/app/views/layouts/application.html.erb)
1. Configure the `config/initializers/react_on_rails.rb`. You can adjust some necessary settings and defaults. See file [https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/config/initializers/react_on_rails.rb](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/config/initializers/react_on_rails.rb) for a detailed example of configuration, including comments on the different values to configure.
1. Configure your Procfiles per the example apps. These are at the root of your Rails installation.
1. Configure your top level JavaScript files for inclusion in your layout. You'll want a version that you use for static assets, and you want a file for any files in your setup that are not part of your webpack build. The reason for this is for use with hot-reloading. If you are not using hot reloading, then you only need to configure your `application.js` file to include your Webpack generated files.
1. If you are deploying to Heroku, see [our heroku deployment documentation](https://www.shakacode.com/react-on-rails/docs/deployment/heroku-deployment/)

If I missed anything, please submit a PR or file an issue.

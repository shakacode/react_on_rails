# Installation Overview

Here's an overview of installation if you're not using the generator.

Note, the best way to understand how to use ReactOnRails is to study the examples:

1. Run the generator per the [Tutorial](../tutorial.md).
2. [spec/dummy](../../spec/dummy): Simple, no DB example.
3. [github.com/shakacode/react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial): Full featured example.

## Configure the `/client` Directory

Note, version 9.0 of React on Rails removed the requirement to place all client side files in the `/client` directory.

This directory has no references to Rails outside of the destination directory for the files created by the various Webpack config files.

The only requirements within this directory for basic React on Rails integration are:

1. Your webpack configuration files:
   1. Create outputs in a directory like `/public/webpack`, which is customizable in your `config/initializers/react_on_rails.rb`.
   1. Provide server rendering if you wish to use that feature.
1. Your JavaScript code "registers" any components and stores per the ReactOnRails APIs of ReactOnRails.register(components) and ReactOnRails.registerStore(stores). See API docs in [README.md](../../README.md) and the [ReactOnRails.js source](../../node_package/src/ReactOnRails.js).
1. Set your registration file as an "entry" point in your Webpack configs.
1. Add the [Manifest plugin](https://github.com/danethurber/webpack-manifest-plugin) to your config. For examples see [dummy config](../../spec/dummy/client/webpack.client.base.config.js).
The default path: `public/webpack` can be loaded with webpackConfigLoader as shown in the dummy example.
1. You create scripts in `client/package.json` per the example apps. These are used for building your Webpack assets. Also do this for your top level `package.json`.

## Rails Steps (outside of /client)
1. Add  `gem "webpacker"` to the Gemfile, run bundle. The gem provides the `stylesheet_pack_tag` and `javascript_pack_tag` helpers which is used to load the bundled assets to your layouts.[Dummy Example](../../spec/dummy/app/views/layouts/application.html.erb)
1. Configure the `config/initializers/react_on_rails.rb`. You can adjust some necessary settings and defaults. See file [spec/dummy/config/initializers/react_on_rails.rb](../../spec/dummy/config/initializers/react_on_rails.rb) for a detailed example of configuration, including comments on the different values to configure.
1. Configure your Procfiles per the example apps. These are at the root of your Rails installation.
1. Configure your top level JavaScript files for inclusion in your layout. You'll want a version that you use for static assets, and you want a file for any files in your setup that are not part of your webpack build. The reason for this is for use with hot-reloading. If you are not using hot reloading, then you only need to configure your `application.js` file to include your Webpack generated files. For more information on hot reloading, see [Hot Reloading of Assets For Rails Development](../additional-reading/hot-reloading-rails-development.md)
1. If you are deploying to Heroku, see [heroku-deployment.md](/docs/additional-reading/heroku-deployment.md)

If I missed anything, please submit a PR or file an issue.

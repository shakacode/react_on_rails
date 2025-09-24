# Manual Installation Overview

TODO: Review this file

This file summarizes what the React on Rails generator does.

## Configure the `/client` Directory

This directory has no references to Rails outside of the destination directory for the files created by the various Webpack config files.

The only requirements within this directory for basic React on Rails integration are:

1. Your Webpack configuration files:
   1. Create outputs in a directory like `/public/webpack`, which is customizable in your `config/initializers/react_on_rails.rb`.
   1. Provide server rendering if you wish to use that feature.
1. Your JavaScript code "registers" any components and stores per the ReactOnRails APIs of ReactOnRails.register(components) and ReactOnRails.registerStore(stores). See [our JavaScript API docs](../api/javascript-api.md) and the [React on Rails source](https://github.com/shakacode/react_on_rails/tree/master/node_package/src/ReactOnRails.client.ts).
1. Set your registration file as an "entry" point in your Webpack configs.
1. Configure scripts in `client/package.json` as shown in the example apps. These are used for building your Webpack assets. Also do this for your top-level `package.json`.

## Rails Steps (outside `/client`)

1. Add `gem "shakapacker"` to the Gemfile, run `bundle`. The gem provides the `stylesheet_pack_tag` and `javascript_pack_tag` helpers, which are used to load the bundled assets in your layouts. [Dummy Example](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/app/views/layouts/application.html.erb).
1. Configure the `config/initializers/react_on_rails.rb`. You can adjust some necessary settings and defaults. See file [https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/config/initializers/react_on_rails.rb](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/config/initializers/react_on_rails.rb) for a detailed example of configuration, including comments on the different values to configure.
1. Configure your Procfiles per the example apps. These are at the root of your Rails installation.
1. Configure your top-level JavaScript files for inclusion in your layout. Use one file for static assets, and a separate file for any files in your setup that are not part of your Webpack build. This separation is needed for hot reloading. If hot reloading is not needed, simply configure your `application.js` file to include the Webpack-generated files.
1. If you are deploying to Heroku, see [our Heroku deployment documentation](../deployment/heroku-deployment.md).

If I missed anything, please submit a PR or file an issue.

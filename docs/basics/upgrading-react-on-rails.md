# Upgrading React on Rails

## Upgrading to version 10

Pretty simple:
* Follow the steps to migrate to version 9 (except installing 10.x instead of 9.x)
* If you have `react_component` returning hashes, then switch to `react_component_hash` instead

## Upgrading to version 9

### With no interest of integrating webpacker
* Bump your ReactOnRails versions in `Gemfile` & `package.json`
* In `/config/initializers/react_on_rails.rb`, rename:
    *   config.npm_build_test_command ==> config.build_test_command
    *   config.npm_build_production_command ==> config.build_production_command

...and you're done.

### Integrating Webpacker
Reason for doing this: This enables your webpack bundles to bypass the Rails asset pipeline and it's extra minification, enabling you to use source-maps in production, while still maintaining total control over everything in the client directory

#### From version 8
See [our changelog for instructions](https://github.com/shakacode/react_on_rails/blob/master/CHANGELOG.md#90-from-8x-upgrade-instructions)

#### From version 7 or lower

##### ...while keeping your `client` directory
Unfortunately, this requires quite a few steps:
*   `.gitignore`: add `/public/webpack/*`
*   `Gemfile`: bump `react_on_rails` and add `webpacker`
*   layout views: anything bundled by webpack will need to be requested by a `javascript_pack_tag` or `stylesheet_pack_tag`
*   `config/initializers/assets.rb`: Delete it. You don't need it anymore.
*   `config/initializers/react_on_rails.rb`:
    *   Delete `config.generated_assets_dir`. Webpacker's config now supplies this information
    *   Replace `config.npm_build_(test|production)_command` with `config.build_(test|production)_command`
*   `config/webpacker.yml`: start with our [example config](https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/config/webpacker.yml) (feel free to modify it as needed). I recommend setting dev_server.hmr to false however since HMR is currently broken.
*   `client/package.json`: bump `react_on_rails` (I recommend bumping `webpack` as well). You'll also need `js-yaml` if you're not already using `eslint` and `webpack-manifest-plugin` regardless.

######  Client Webpack config:
  *   You'll need the following code to read data from the webpacker config:

```
const path = require('path');
const ManifestPlugin = require('webpack-manifest-plugin'); // we'll use this later

const webpackConfigLoader = require('react-on-rails/webpackConfigLoader');
const configPath = path.resolve('..', 'config');
const { output } = webpackConfigLoader(configPath);
```

  *   That output variable will be used for webpack's `output` rules:

```
  output: {
    filename: '[name]-[chunkhash].js', // [chunkhash] because we've got to do our own cache-busting now
    path: output.path,
    publicPath: output.publicPath,
  },
```

  *   ...as well as for the output of plugins like `webpack-manifest-plugin`:

```

      new ManifestPlugin({
        publicPath: output.publicPath,
        writeToFileEmit: true
      }),
```

  *   If you're using referencing files or images with `url-loader` & `file-loader`, their publicpaths will have to change as well: `publicPath: '/webpack/',`
  *   If you're using `css-loader`, `webpack.optimize.CommonsChunkPlugin`, or `extract-text-webpack-plugin`, they will also need cache-busting!

...and you're finally done!

##### ...while replacing your `client` directory
* Make the same changes to `config/initializers/react_on_rails.rb as described above`
* Upgrade RoR & add Webpacker in the Gemfile
* Upgrade RoR in the `client/package.json`
* Run `bundle`
* Run `rails webpacker:install`
* Run `rails webpacker:install:react`
* Run `rails g react_on_rails:install`
* Move your entry point files to `app/javascript/packs`
* Either:
    * Move all your source code to `app/javascript/bundles`, move your linter configs to the root directory, and then delete the `client` directory
    * or just delete the webpack config and remove webpack, its loaders, and plugins from your `client/package.json`.

...and you're done.

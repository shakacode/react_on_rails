# Upgrading React on Rails

## Upgrading to version 11
* Remove `server_render_method` from config/initializers/react_on_rails.rb. Alternate server rendering methods are part of React on Rails Pro. If you want to use a custom renderer, contact justin@shakacode.com. We have a custom node rendering solution in production for egghead.io.
* Remove your usage of ENV["TRACE_REACT_ON_RAILS"] usage. You can get all tracing with either specifying **`trace`** at your component or in your config/initializers/react_on_rails.rb file.
* ReactOnRails::Utils.server_bundle_file_name and ReactOnRails::Utils.bundle_file_name were removed. React on Rails Pro contains upgrades to enable component and other types caching with React on Rails.


## Upgrading to version 10

Pretty simple:
* Follow the steps to migrate to version 9 (except installing 10.x instead of 9.x)
* If you have `react_component` returning hashes, then switch to `react_component_hash` instead

## Upgrading to version 9

### Why Webpacker?
Webpacker provides areas of value:
* View helpers that support bypassing the asset pipeline, which allows you to avoid double minification and enable source maps in production. This is 100% a best practice as source maps in production greatly increases the value of services such as HoneyBadger or Sentry.
* A default Webpack config so that you only need to do minimal modifications and customizations. However, if you're doing server rendering, you may not want to give up control. Since Webpacker's default webpack config is changing often, we at Shakacode can give you definitive advice on webpack configuration best practices. In general, if you're happy with doing your own Webpack configuration, then we suggest using the `client` strategy discussed below. Most corporate projects will prefer having more control than direct dependence on webpacker easily allows.

### Integrating Webpacker
Reason for doing this: This enables your webpack bundles to bypass the Rails asset pipeline and it's extra minification, enabling you to use source-maps in production, while still maintaining total control over everything in the client directory

#### From version 7 or lower

##### ...while keeping your `client` directory
Unfortunately, this requires quite a few steps:
*   `.gitignore`: add `/public/webpack/*`
*   `Gemfile`: bump `react_on_rails` and add `webpacker`
*   layout views: anything bundled by webpack will need to be requested by a `javascript_pack_tag` or `stylesheet_pack_tag`
*   `config/initializers/assets.rb`: we no longer need to modify `Rails.application.config.assets.paths` or append anything to `Rails.application.config.assets.precompile`.
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

#### From version 8

For an example of upgrading, see [react-webpack-rails-tutorial/pull/416](https://github.com/shakacode/react-webpack-rails-tutorial/pull/416).

- Breaking Configuration Changes
  1. Added `config.node_modules_location` which defaults to `""` if Webpacker is installed. You may want to set this to 'client'` to `config/initializers/react_on_rails.rb` to keep your node_modules inside of `/client`
  2. Renamed
   * config.npm_build_test_command ==> config.build_test_command
   * config.npm_build_production_command ==> config.build_production_command

- Update the gemfile. Switch over to using the webpacker gem.

```rb
gem "webpacker"
```

- Update for the renaming in the `WebpackConfigLoader` in your webpack configuration.
  You will need to rename the following object properties:
  - webpackOutputPath      ==> output.path
  - webpackPublicOutputDir ==> output.publicPath
  - hotReloadingUrl        ==> output.publicPathWithHost
  - hotReloadingHostname   ==> settings.dev_server.host
  - hotReloadingPort       ==> settings.dev_server.port
  - hmr                    ==> settings.dev_server.hmr
  - manifest               ==> Remove this one. We use the default for Webpack of manifest.json
  - env                    ==> Use `const { env } = require('process');`
  - devBuild               ==> Use `const devBuild = process.env.NODE_ENV !== 'production';`

- Edit your Webpack.config files:
  - Change your Webpack output to be like this. **Be sure to have the hash or chunkhash in the filename,** unless the bundle is server side.:
    ```
    const webpackConfigLoader = require('react-on-rails/webpackConfigLoader');
    const configPath = resolve('..', 'config');
    const { output, settings } = webpackConfigLoader(configPath);
    const hmr = settings.dev_server.hmr;
    const devBuild = process.env.NODE_ENV !== 'production';

    output: {
      filename: isHMR ? '[name]-[hash].js' : '[name]-[chunkhash].js',
      chunkFilename: '[name]-[chunkhash].chunk.js',

      publicPath: output.publicPath,
      path: output.path,
    },
    ```
  - Change your ManifestPlugin definition to something like the following
    ```
    new ManifestPlugin({
        publicPath: output.publicPath,
        writeToFileEmit: true
      }),

    ```

- Find your `webpacker_lite.yml` and rename it to `webpacker.yml`
  - Consider copying a default webpacker.yml setup such as https://github.com/shakacode/react-on-rails-v9-rc-generator/blob/master/config/webpacker.yml
  - If you are not using the webpacker webpacker setup, be sure to put in `compile: false` in the `default` section.
  - Alternately, if you are updating from webpacker_lite, you can manually change these:
  - Add a default setting
    ```
    cache_manifest: false
    ```
  - For production, set:  
    ```
    cache_manifest: true
    ```
  - Add a section like this under your development env:
    ```
    dev_server:
      host: localhost
      port: 3035
      hmr: false
    ```
    Set hmr to your preference.
  - See the example `spec/dummy/config/webpacker.yml`.
  - Remove keys `hot_reloading_host` and `hot_reloading_enabled_by_default`. These are replaced by the `dev_server` key.
  - Rename `webpack_public_output_dir` to `public_output_path`.

- Edit your Procfile.dev
  - Remove the env value WEBPACKER_DEV_SERVER as it's not used
  - For hot loading:
    - Set the `hmr` key in your `webpacker.yml` to `true`.

### Without integrating webpacker
* Bump your ReactOnRails versions in `Gemfile` & `package.json`
* In `/config/initializers/react_on_rails.rb`:
    *  Rename `config.npm_build_test_command` ==> `config.build_test_command`
    *  Rename `config.npm_build_production_command` ==> `config.build_production_command`
    *  Add `config.node_modules_location = "client"`

...and you're done.

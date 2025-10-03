# Upgrading React on Rails

## Need Help Migrating?

If you would like help in migrating between React on Rails versions or help with implementing server rendering, please contact [justin@shakacode.com](mailto:justin@shakacode.com) for more information about our [React on Rails Pro Support](https://www.shakacode.com/react-on-rails-pro).

We specialize in helping companies to quickly and efficiently upgrade. The older versions use the Rails asset pipeline to package client assets. The current and recommended way is to use Webpack 4+ for asset preparation. You may also need help migrating from the `rails/webpacker`'s Webpack configuration to a better setup ready for Server Side Rendering.

## General Upgrade Process

After upgrading to any major version, always run the generator to get the latest defaults:

```bash
rails generate react_on_rails:install
```

**⚠️ Important**: Review generated changes carefully before applying to avoid overwriting custom configurations. The generator updates:

- `bin/dev` (improved development workflow)
- webpack configurations
- `shakapacker.yml` settings
- other configuration files

## Upgrading to v16

### Breaking Changes

- **Webpacker support completely removed**. Shakapacker >= 6.0 is now required.
- **Updated runtime requirements**:
  - Minimum Ruby version: 3.2
  - Minimum Node.js version: 20
- **Install generator now validates prerequisites** and requires at least one JavaScript package manager

### Migration Steps

1. **Update Dependencies**

   ```ruby
   # Gemfile
   gem "react_on_rails", "~> 16.0"
   ```

   ```json
   // package.json
   {
     "dependencies": {
       "react-on-rails": "^16.0.0"
     }
   }
   ```

2. **Install Updates**

   ```bash
   bundle update react_on_rails
   npm install
   ```

3. **Run Generator**

   ```bash
   rails generate react_on_rails:install
   ```

4. **Review and Apply Changes**

   - Check webpack configuration exports (function naming may have changed)
   - Review `shakapacker.yml` settings
   - Update `bin/dev` if needed

5. **Test Your Application**

   ```bash
   # Test asset compilation
   bundle exec rails assets:precompile

   # Test development server
   bin/dev

   # Run your test suite
   bundle exec rspec # or your test command
   ```

### Common Upgrade Issues

#### Build Fails with Module Resolution Errors

**Symptoms:** Webpack cannot find modules referenced in your configuration

**Solutions:**

1. Clear webpack cache: `rm -rf node_modules/.cache`
2. Verify all ProvidePlugin modules exist
3. Check webpack alias configuration

For troubleshooting build errors, see the [build errors guide](../javascript/troubleshooting-build-errors.md).

### Enhanced Features in v16

- **Enhanced error handling** in `react_on_rails:generate_packs` task with detailed debugging guidance
- **Improved development tooling** with better error messages and troubleshooting steps
- **Better package manager detection** with multi-strategy validation

## Upgrading to v13

### Breaking Change

Previously, the gem `webpacker` was a Gem dependency.

v13 has changed slightly to switch to `shakapacker`.

For details, see the Shakapacker guide to upgrading to [version 6](https://github.com/shakacode/shakapacker/blob/master/docs/v6_upgrade.md) and [version 7](https://github.com/shakacode/shakapacker/blob/master/docs/v7_upgrade.md)

In summary:

1. Change the gem reference from 'webpacker' to 'shakapacker'
2. Change the npm reference from '@rails/webpacker' to 'shakapacker'
3. Other updates, depending on what version of `rails/webpacker` that you had.

## Upgrading to v12

### Recent versions

Make sure that you are on a relatively more recent version of Rails and Webpacker. Yes, the [rails/webpacker](https://github.com/rails/webpacker) gem is required!
v12 is tested on Rails 6. It should work on Rails v5. If you're on any older version,
and v12 doesn't work, please file an issue.

### Removed Configuration config.symlink_non_digested_assets_regex

Remove `config.symlink_non_digested_assets_regex` from your `config/initializers/react_on_rails.rb`.
If you still need that feature, please file an issue.

### i18n default format changed to JSON

- If you're using the internationalization helper, then set `config.i18n_output_format = 'js'`. You can
  later update to the default JSON format as you will need to update your usage of that file. A JSON
  format is more efficient.

### Updated API for `ReactOnRails.register()`

In order to solve the issues regarding React Hooks compatibility, the number of parameters
for functions is used to determine if you have a Render-Function that will get invoked to
return a React component, or you are registering a React component defined by a function.
Please see [Render-Functions and the Rails Context](./render-functions-and-railscontext.md) for
more information on what a Render-Function is.

##### Update required for registered functions taking exactly 2 params.

Registered Objects are of the following type:

1. **Function that takes only zero or one params and returns a React Element**, often JSX. If the function takes zero or one params, there is **no migration needed** for that function.

   ```js
   export default (props) => <Component {...props} />;
   ```

2. **Function that takes only zero or one params and returns an Object (_not a React Element_)**. If the function takes zero or one params, **you need to add one or two unused params so you have exactly 2 params** and then that function will be treated as a render function and it can return an Object rather than a React element. If you don't do this, you'll see this obscure error message:

```
  [SERVER] message: Objects are not valid as a React child (found: object with keys {renderedHtml}). If you meant to render a collection of children, use an array instead.
  in YourComponentRenderFunction
```

So look in `YourComponentRenderFunction` and do this change

```js
export default (props) => ({
  renderedHTML: getRenderedHTML(),
});
```

To have exactly 2 arguments:

```js
export default (props, _railsContext) => ({
  renderedHTML: getRenderedHTML(),
});
```

3. Function that takes **2 params** and returns **a React function or class component**. _Migration is needed as the older syntax returned a React Element._
   A function component is a function that takes zero or one params and returns a React Element, like JSX. The correct syntax
   looks like:
   ```js
   export default (props, railsContext) => () => <Component {...{ ...props, railsContext }} />;
   ```
   Note, you cannot return a React Element (JSX). See below for the migration steps. If your function that took **two params returned
   an Object**, then no migration is required.
4. Function that takes **3 params** and uses the 3rd param, `domNodeId`, to call `ReactDOM.hydrate`. If the function takes 3 params, there is **no migration needed** for that function.
5. ES6 or ES5 class. There is **no migration needed**.

Previously, with case number 2, you could return a React Element.

The fix is simple. Here is an example of the change you'll do:

![2020-07-07_09-43-51 (1)](https://user-images.githubusercontent.com/1118459/86927351-eff79e80-c0ce-11ea-9172-d6855c45e2bb.png)

##### Broken, as this function takes two params and it returns a React Element from a JSX Literal

```js
export default (props, _railsContext) => <Component {...props} />;
```

If you make this mistake, you'll get this warning
`Warning: React.createElement: type is invalid -- expected a string (for built-in components) or a class/function (for composite components) but got: <Fragment />. Did you accidentally export a JSX literal instead of a component?`

And this error:
`react-dom.development.js:23965 Uncaught Error: Element type is invalid: expected a string (for built-in components) or a class/function (for composite components) but got: object.`

In this example, you need to wrap the `<Component {...props} />` in a function call like this which
results in the return value being a React function component.

```js
export default (props, _railsContext) => () => <Component {...props} />;
```

If you have a pure component, taking one or zero parameters, and you have an unnecessary function
wrapper such that you're returning a function rather than a React Element, then:

1. You won't see anything render.
2. You will see this warning in development mode: `Warning: Functions are not valid as a React child. This may happen if you return a Component instead of <Component /> from render. Or maybe you meant to call this function rather than return it.`

---

## Upgrading rails/webpacker from v3 to v4

### Custom Webpack build file

The default value for `extract_css` is **false** in `config/webpack.yml`. Custom Webpack builds should set this value to true, or else no CSS link tags are generated. You have a custom Webpack build if you are not using [rails/webpacker](https://github.com/rails/webpacker) to set up your Webpack configuration.

```yml
default: &default # other stuff
  extract_css: true
  # by default, extract and emit a css file. The default is false
```

## Upgrading to version 11

- Remove `server_render_method` from config/initializers/react_on_rails.rb. Alternate server rendering methods are part of React on Rails Pro. If you want to use a custom renderer, contact justin@shakacode.com. We have a custom node rendering solution in production for egghead.io.
- Remove your usage of ENV["TRACE_REACT_ON_RAILS"] usage. You can get all tracing with either specifying **`trace`** at your component or in your config/initializers/react_on_rails.rb file.
- ReactOnRails::Utils.server_bundle_file_name and ReactOnRails::Utils.bundle_file_name were removed. React on Rails Pro contains upgrades to enable component and other types caching with React on Rails.

## Upgrading to version 10

Pretty simple:

- Follow the steps to migrate to version 9 (except installing 10.x instead of 9.x)
- If you have `react_component` returning hashes, then switch to `react_component_hash` instead

## Upgrading to version 9

### Why Webpacker?

Webpacker provides areas of value:

- View helpers that support bypassing the asset pipeline, which allows you to avoid double minification and enable source maps in production. This is 100% a best practice, as source maps in production greatly increases the value of services such as HoneyBadger or Sentry.
- A default Webpack config so that you only need to do minimal modifications and customizations. However, if you're doing server rendering, you may not want to give up control. Since Webpacker's default Webpack config is changing often, we at Shakacode can give you definitive advice on Webpack configuration best practices. In general, if you're happy with doing your own Webpack configuration, then we suggest using the `client` strategy discussed below. Most corporate projects will prefer having more control than direct dependence on webpacker easily allows.

### Integrating Webpacker

Reason for doing this: This enables your Webpack bundles to bypass the Rails asset pipeline and its extra minification, enabling you to use source-maps in production, while still maintaining total control over everything in the client directory.

#### From version 7 or lower

##### ...while keeping your `client` directory

- `.gitignore`: add `/public/webpack/*`.
- `Gemfile`: bump `react_on_rails` and add `webpacker`.
- layout views: anything bundled by Webpack will need to be requested by a `javascript_pack_tag` or `stylesheet_pack_tag`.
- Search your codebase for javascript_include_tag. Use the
- `config/initializers/assets.rb`: we no longer need to modify `Rails.application.config.assets.paths` or append anything to `Rails.application.config.assets.precompile`.
- `config/initializers/react_on_rails.rb`:
  - Delete `config.generated_assets_dir`. Webpacker's config now supplies this information.
  - Replace `config.npm_build_(test|production)_command` with `config.build_(test|production)_command`.
- `config/webpacker.yml`: start with our [example config](https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/config/webpacker.yml) (feel free to modify it as needed). I recommend setting dev_server.hmr to false however since HMR is currently broken.
- `client/package.json`: bump `react_on_rails` (I recommend bumping `webpack` as well). You'll also need `js-yaml` if you're not already using `eslint` and `webpack-manifest-plugin` regardless.

###### Client Webpack config

- You'll need the following code to read data from the webpacker config:

```
const path = require('path');
const ManifestPlugin = require('webpack-manifest-plugin'); // we'll use this later

const webpackConfigLoader = require('react-on-rails/webpackConfigLoader');
const configPath = path.resolve('..', 'config');
const { output } = webpackConfigLoader(configPath);
```

- That output variable will be used for Webpack's `output` rules:

```
  output: {
    filename: '[name]-[chunkhash].js', // [chunkhash] because we've got to do our own cache-busting now
    path: output.path,
    publicPath: output.publicPath,
  },
```

- ...as well as for the output of plugins like `webpack-manifest-plugin`:

```

      new ManifestPlugin({
        publicPath: output.publicPath,
        writeToFileEmit: true
      }),
```

- If you're using referencing files or images with `url-loader` & `file-loader`, their publicpaths will have to change as well: `publicPath: '/webpack/',`
- If you're using `css-loader`, `webpack.optimize.CommonsChunkPlugin`, or `extract-text-webpack-plugin`, they will also need cache-busting!

...and you're finally done!

##### ...while replacing your `client` directory

- Make the same changes to `config/initializers/react_on_rails.rb as described above`
- Upgrade RoR & add Webpacker in the Gemfile
- Upgrade RoR in the `client/package.json`
- Run `bundle`
- Run `rails webpacker:install`
- Run `rails webpacker:install:react`
- Run `rails g react_on_rails:install`
- Move your entry point files to `app/javascript/packs`
- Either:
  - Move all your source code to `app/javascript/bundles`, move your linter configs to the root directory, and then delete the `client` directory
  - or just delete the Webpack config and remove Webpack, its loaders, and plugins from your `client/package.json`.

...and you're done.

#### From version 8

For an example of upgrading, see [react-webpack-rails-tutorial/pull/416](https://github.com/shakacode/react-webpack-rails-tutorial/pull/416).

- Breaking Configuration Changes

  1. Added `config.node_modules_location` which defaults to `""` if Webpacker is installed. You may want to set this to `'client'` in `config/initializers/react_on_rails.rb` to keep your `node_modules` inside the `/client` directory.
  2. Renamed
     - config.npm_build_test_command ==> config.build_test_command
     - config.npm_build_production_command ==> config.build_production_command

- Update the gemfile. Switch over to using the webpacker gem.

```rb
gem "webpacker"
```

- Update for the renaming in the `WebpackConfigLoader` in your Webpack configuration.
  You will need to rename the following object properties:

  - webpackOutputPath ==> output.path
  - webpackPublicOutputDir ==> output.publicPath
  - hotReloadingUrl ==> output.publicPathWithHost
  - hotReloadingHostname ==> settings.dev_server.host
  - hotReloadingPort ==> settings.dev_server.port
  - hmr ==> settings.dev_server.hmr
  - manifest ==> Remove this one. We use the default for Webpack of manifest.json
  - env ==> Use `const { env } = require('process');`
  - devBuild ==> Use `const devBuild = process.env.NODE_ENV !== 'production';`

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
  - If you are not using the webpacker Webpack setup, be sure to put in `compile: false` in the `default` section.
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

- Bump your ReactOnRails versions in `Gemfile` & `package.json`
- In `/config/initializers/react_on_rails.rb`:
  - Rename `config.npm_build_test_command` ==> `config.build_test_command`
  - Rename `config.npm_build_production_command` ==> `config.build_production_command`
  - Add `config.node_modules_location = "client"`

...and you're done.

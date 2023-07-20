# Client rendering crashes when configuring `optimization.runtimeChunk` to `multiple`

## Context

1. Ruby version: 3.1
2. Rails version: 7.0.6
3. Shakapacker version: 6.6.0
4. React on Rails version: 13.3.5

## The failure

Configuring Webpack to embed the runtime in each chunk and calling `react_component` twice in a rails view/partial causes the client render to crash with the following error:

```
Could not find component registered with name XXX. Registered component names include [ YYY ]. Maybe you forgot to register the component?
```

```
VM4859 clientStartup.js:132 Uncaught Error: ReactOnRails encountered an error while rendering component: XXX. See above error message.
    at Object.get (ComponentRegistry.js:40:15)
    at Object.getComponent (ReactOnRails.js:211:44)
    at render (VM4859 clientStartup.js:103:53)
    at forEachReactOnRailsComponentRender (VM4859 clientStartup.js:138:9)
    at reactOnRailsPageLoaded (VM4859 clientStartup.js:164:5)
    at renderInit (VM4859 clientStartup.js:205:9)
    at onPageReady (VM4859 clientStartup.js:234:9)
    at HTMLDocument.onReadyStateChange (VM4859 clientStartup.js:238:13)
```

## Configs

### Webpack configuration

```js
optimization: {
  runtimeChunk: 'multiple'
},
```

### Rails view

```haml
= react_component("XXX", props: @props)
= yield
= react_component("YYY", props: @props)
```

## The problem

Configuring Webpack to embed the runtime in each chunk and calling `react_component` twice in a rails view/partial causes the client render to crash.

Read more at https://github.com/shakacode/react_on_rails/issues/1558.

## Solution

To overcome this issue, we could use [shakapacker](https://github.com/shakacode/shakapacker)'s default optimization configuration (pseudo-code):

```js
const { webpackConfig: baseClientWebpackConfig } = require('shakapacker');

// ...

config.optimization = baseClientWebpackConfig.optimization;
```
As it set the `optimization.runtimeChunk` to `single`. See its source:

`package/environments/base.js:115`
```js
  optimization: {
    splitChunks: { chunks: 'all' },

    runtimeChunk: 'single'
  },
```
https://github.com/shakacode/shakapacker/blob/cdf32835d3e0949952b8b4b53063807f714f9b24/package/environments/base.js#L115-L119

Or set `optimization.runtimeChunk` to `single` directly.

# When `ReactOnRails.configuration.webpack_generated_files` is specified, it prevents usage of `manifest.json`

## Context

Rails: 5.0.2
react_on_rails: upgraded from 6.6.0 to 9.0.3

## The failure

Rspec failing with
```
Failure/Error: raise Webpacker::Manifest::MissingEntryError, missing_file_from_manifest_error(name)
     
     Webpacker::Manifest::MissingEntryError:
       Webpacker can't find webpack-bundle.js in /home/user/ws/pp/code/pp-core-checkout_spa_update_npm/public/webpack-test/manifest.json. Possible causes:
       1. You want to set webpacker.yml value of compile to true for your environment
          unless you are using the `webpack -w` or the webpack-dev-server.
       2. Webpack has not yet re-run to reflect updates.
       3. You have misconfigured Webpacker's config/webpacker.yml file.
       4. Your Webpack configuration is not creating a manifest.
       Your manifest contains:
       {
         "main.css": "/webpack-test/main-bundle.css",
         "main.js": "/webpack-test/main-dde0e05a2817931424c3.js"
       }
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/webpacker-3.0.1/lib/webpacker/manifest.rb:44:in `handle_missing_entry'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/webpacker-3.0.1/lib/webpacker/manifest.rb:40:in `find'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/webpacker-3.0.1/lib/webpacker/manifest.rb:27:in `lookup'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/react_on_rails-9.0.3/lib/react_on_rails/utils.rb:145:in `bundle_js_file_path_from_webpacker'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/react_on_rails-9.0.3/lib/react_on_rails/utils.rb:90:in `bundle_js_file_path'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/react_on_rails-9.0.3/lib/react_on_rails/test_helper/webpack_assets_status_checker.rb:56:in `block in all_compiled_assets'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/react_on_rails-9.0.3/lib/react_on_rails/test_helper/webpack_assets_status_checker.rb:55:in `map'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/react_on_rails-9.0.3/lib/react_on_rails/test_helper/webpack_assets_status_checker.rb:55:in `all_compiled_assets'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/react_on_rails-9.0.3/lib/react_on_rails/test_helper/webpack_assets_status_checker.rb:35:in `stale_generated_webpack_files'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/react_on_rails-9.0.3/lib/react_on_rails/test_helper/ensure_assets_compiled.rb:34:in `call'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/react_on_rails-9.0.3/lib/react_on_rails/test_helper.rb:85:in `ensure_assets_compiled'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/react_on_rails-9.0.3/lib/react_on_rails/test_helper.rb:39:in `block (2 levels) in configure_rspec_to_compile_assets'
     # /home/user/.rbenv/versions/2.3.1/lib/ruby/gems/2.3.0/gems/rspec-core-3.5.4/lib/rspec/core/example.rb:443:in `instance_exec'
...
```

At the same time dev/prod environments works fine (with extra webpack calling step outside rails).

## Configs

### webpack.config.js

```js
...
const ManifestPlugin = require('webpack-manifest-plugin');
...
const { output } = webpackConfigLoader(configPath);
...
  output: {
    filename: '[name]-[hash].js',

    // Leading and trailing slashes ARE necessary.
    publicPath: output.publicPath,
    path: output.path,
  },
...
  plugins: [
    ...
    new ManifestPlugin({
      publicPath: output.publicPath,
      writeToFileEmit: true
    }),
   ...
  ]
...
```

### config/webpacker.yml

is default from sample appliction v9.x

### config/initializers/react_on_rails.rb

```ruby
  ...
  # Define the files we need to check for webpack compilation when running tests.
  config.webpack_generated_files = %w( webpack-bundle.js main-bundle.css )
  ...
```

## The problem

When `ReactOnRails.configuration.webpack_generated_files` is specified, it prevents usage of `manifest.json`

## Solution

Removing of `config.webpack_generated_files` from `config/initializers/react_on_rails.rb` resolving issue.

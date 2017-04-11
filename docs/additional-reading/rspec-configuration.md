# RSpec Configuration
Because you will probably want to run RSpec tests that rely on compiled webpack assets (typically, your integration/feature specs where `js: true`), you will want to ensure you don't accidentally run tests on missing or stale webpack assets. If you did use stale Webpack assets, you will get invalid test results as your tests do not use the very latest JavaScript code.

ReactOnRails provides a helper method called `ReactOnRails::TestHelper.configure_rspec_to_compile_assets`. Call this method from inside of the `RSpec.configure` block in your `spec/rails_helper.rb` file, passing the config as an argument. See file [lib/react_on_rails/test_helper.rb](../../lib/react_on_rails/test_helper.rb) for more details. You can customize this to your particular needs by replacing any of the default components used by `ReactOnRails::TestHelper.configure_rspec_to_compile_assets`.

```ruby
RSpec.configure do |config|
  # Next line will ensure that assets are built if webpack -w is not running to build the bundles
  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
```

You can pass one or more RSpec metatags as an optional second parameter to this helper method if you want this helper to run on examples other than where `:js` or `:server_rendering` (those are the defaults). The helper will compile webpack files at most once per test run. The helper will not compile the webpack files unless they are out of date (stale). The helper is configurable in terms of what command is used to prepare the files.

If you are using Webpack to build CSS assets, you should do something like this to ensure that you assets are built for any specs under `specs/requests` or `specs/features`:

```ruby
  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config, :requires_webpack_assets)

  # Because we're using some CSS Webpack files, we need to ensure the webpack files are generated
  # for all feature specs. https://github.com/shakacode/react_on_rails/issues/792
  config.define_derived_metadata(file_path: %r{spec/(features|requests)}) do |metadata|
    metadata[:requires_webpack_assets] = true
  end
```

Please take note of the following:
- This utility uses your `npm_build_test_command` to build the static generated files. This command **must** not include the `--watch` option. If you have different server and client bundle files, this command **must** create all the bundles.
- By default, the webpack processes look for the `app/assets/webpack` folders (configured as setting `webpack_generated_files` in the `config/react_on_rails.rb`. If this folder is missing, is empty, or contains files in the `config.webpack_generated_files` list with `mtime`s older than any of the files in your `client` folder, the helper will recompile your assets. You can override the location of these files inside of `config/initializers/react_on_rails.rb` by passing a filepath (relative to the root of the app) to the `generated_assets_dir` configuration option.

The following `config/react_on_rails.rb` settings **must** match your setup:
```ruby
  # Directory where your generated assets go. All generated assets must go to the same directory.
  # Configure this in your webpack config files. This relative to your Rails root directory.
  config.generated_assets_dir = File.join(%w(app assets webpack))

  # Define the files we need to check for webpack compilation when running tests.
  config.webpack_generated_files = %w( webpack-bundle.js )
  
  # If you are using the ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
  # with rspec then this controls what yarn command is run
  # to automatically refresh your webpack assets on every test run.
  config.npm_build_test_command = "yarn run build:test"
```

If you want to speed up the re-compiling process, you can call `yarn run build:development` (per below script) to have webpack run in "watch" mode and recompile these files in the background, which will be much faster when making incremental changes than compiling from scratch, assuming you have your setup like this:

```
  "scripts": {
    "build:test": "webpack --config webpack.config.js",
    "build:production": "NODE_ENV=production webpack --config webpack.config.js",
    "build:development": "webpack -w --config webpack.config.js"
  },
```

[spec/dummy](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy) contains examples of how to set the proc files for this purpose.

## Hot Reloading
If you're using the hot reloading setup, you'll be running a Webpack development server to provide the JavaScript and mabye CSS assets to your Rails app. If you're doing server rendering, you'll also have a webpack watch process to refresh the server rendering file. **If your server and client bundles are different**, and you run specs, the client bundle files will not be created until React on Rails detects it's out of date. Then your script to create all bundle files will redo the server bundle file. There's a few simple remedies for this situation:

1. Switch to using static compilation of the webpack bundle files. This way, you're running a Webpack watch process to generate the same files used for tests as well as developmentment. You should have a separate Procfile for doing development using a "static" setup, rather than a "hot" setup.
2. Change your Procfile for starting the hot reloading server to also run a webpack process to automatically rebuild a the client assets while also doing hot reloading for browser testing.

Note, none of these issues matter if you're using the same file for both server and client side rendering.

## Using RubyMine and other IDEs that save files right before invoking tests
We had previously tried to allow using a process check to see if a Webpack watch process would already be automatically compiling the files. However, we removed this as it proved to be fragile with various setups. Thus, you want to hit the save keystroke when you save a JavaScript file, and then run your tests. Yes, you might not do this in time, and the test runner may be building the same files as you Webpack watch processes. This will probably happen infrequently, but if this does become an issue, we can look into bring back this functionality ([#398](https://github.com/shakacode/react_on_rails/pull/398)).

If you want to use a testing framework other than RSpec, please submit let us know on the changes you need to do and we'll update the docs.

![2016-01-27_02-36-43](https://cloud.githubusercontent.com/assets/1118459/12611951/7c56d070-c4a4-11e5-8a80-9615f99960d9.png)

![2016-01-27_03-18-05](https://cloud.githubusercontent.com/assets/1118459/12611975/a8011654-c4a4-11e5-84f9-1baca4835b4b.png)

# RSpec Configuration

_Click [here for minitest](./minitest-configuration.md)_

# If your Webpack configurations correspond to Shakapacker's default setup

If you're able to configure your Webpack configuration to be run by having your Webpack configuration
returned by the files in `/config/webpack`, then you have 2 options to ensure that your files are
compiled by Webpack before running tests and during production deployment:

1. **Use Shakapacker's compile option**: Configure your `config/shakapacker.yml` so that `compile: true` is for `test` and `production`
   environments. Ensure that your `source_path` is correct, or else `Shakapacker` won't correctly
   detect changes.
2. **Use the React on Rails settings and helpers**. Use the settings in `config/initializers/react_on_rails.rb`. Refer to [docs/configuration](./configuration.md).

```yml
config.build_test_command = "NODE_ENV=test RAILS_ENV=test bin/shakapacker"
```

Which should you use? If you're already using the `Shakapacker` way to configure Webpack, then
you can keep things simple and use the `Shakapacker` options.

# Checking for stale assets using React on Rails

Because you will probably want to run RSpec tests that rely on compiled Webpack assets (typically, your integration/feature specs where `js: true`), you will want to ensure you don't accidentally run tests on missing or stale Webpack assets. If you did use stale Webpack assets, you will get invalid test results as your tests do not use the very latest JavaScript code.

As mentioned above, you can configure `compile: true` in `config/shakapacker.yml` _if_ you've got configuration for
your Webpack in the standard `Shakapacker` spot of `config/webpack/<NODE_ENV>.js`

React on Rails also provides a helper method called `ReactOnRails::TestHelper.configure_rspec_to_compile_assets`. Call this method from inside of the `RSpec.configure` block in your `spec/rails_helper.rb` file, passing the config as an argument. See file [lib/react_on_rails/test_helper.rb](https://github.com/shakacode/react_on_rails/tree/master/lib/react_on_rails/test_helper.rb) for more details. You can customize this to your particular needs by replacing any of the default components used by `ReactOnRails::TestHelper.configure_rspec_to_compile_assets`.

```ruby
RSpec.configure do |config|
  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
```

You can pass one or more RSpec metatags as an optional second parameter to this helper method if you want this helper to run on examples other than where `:js`, `:server_rendering`, or `:controller` (those are the defaults). The helper will compile Webpack files at most once per test run. The helper will not compile the webpack files unless they are out of date (stale). The helper is configurable in terms of what command is used to prepare the files. If you don't specify these metatags for your relevant JavaScript tests, then you'll need to do the following.

If you are using Webpack to build CSS assets, you should do something like this to ensure that you assets are built for any specs under `specs/requests` or `specs/features`:

```ruby
  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config, :requires_webpack_assets)
  config.define_derived_metadata(file_path: %r{spec/(features|requests)}) do |metadata|
    metadata[:requires_webpack_assets] = true
  end
```

Please take note of the following:

- If you are using Shakapacker, be **SURE** to configure the `source_path` in your `config/shakapacker.yml` unless you are using the defaults for Shakapacker.

- This utility uses your `build_test_command` to build the static generated files. This command **must not** include the `--watch` option. If you have different server and client bundle files, this command **must** create all the bundles. If you are using Shakapacker, the default value will come from the `config/shakapacker.yml` value for the `public_output_path` and the `source_path`

- If you add an older file to your source files, that is already older than the produced output files, no new recompilation is done. The solution to this issue is to clear out your directory of Webpack generated files when adding new source files that may have older dates.

- By default, the Webpack processes look in the Webpack generated files folder, configured via the `config/shakapacker.yml` config values of `public_root_path` and `public_output_path`. If the webpack generated files folder is missing, is empty, or contains files in the `config.webpack_generated_files` list with `mtime`s older than any of the files in your `client` folder, the helper will recompile your assets.

The following `config/react_on_rails.rb` settings **must** match your setup:

```ruby
  # Define the files we need to check for Webpack compilation when running tests.
  config.webpack_generated_files = %w( manifest.json )

  # OR if you're not hashing the server-bundle.js, then you should include your server-bundle.js in the list.
  # config.webpack_generated_files = %w( server-bundle.js manifest.json )

  # If you are using the ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
  # with rspec then this controls what yarn command is run
  # to automatically refresh your Webpack assets on every test run.
  config.build_test_command = "yarn run build:test"
```

If you want to speed up the re-compiling process so you don't wait to run your tests to build the files, you can run your test compilation with the "watch" flags. For example, `yarn run build:test --watch`

![2016-01-27_02-36-43](https://cloud.githubusercontent.com/assets/1118459/12611951/7c56d070-c4a4-11e5-8a80-9615f99960d9.png)

![2016-01-27_03-18-05](https://cloud.githubusercontent.com/assets/1118459/12611975/a8011654-c4a4-11e5-84f9-1baca4835b4b.png)

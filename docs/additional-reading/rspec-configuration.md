# RSpec Configuration
Because you will probably want to run RSpec tests that rely on compiled webpack assets (typically, your integration/feature specs where `js: true`), you will want to ensure you don't accidentally run tests on missing or stale webpack assets. If you did use stale Webpack assets, you will get invalid test results as your tests do not use the very latest JavaScript code.

ReactOnRails provides a helper method called `ReactOnRails::TestHelper.configure_rspec_to_compile_assets`. Call this method from inside of the `RSpec.configure` block in your `spec/rails_helper.rb` file, passing the config as an argument. See file [lib/react_on_rails/test_helper.rb](../../lib/react_on_rails/test_helper.rb) for more details. You can customize this to your particular needs by replacing any of the default components used by `ReactOnRails::TestHelper.configure_rspec_to_compile_assets`.

```ruby
RSpec.configure do |config|
  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
```

You can pass one or more RSpec metatags as an optional second parameter to this helper method if you want this helper to run on examples other than where `:js`, `:server_rendering`, or `:controller` (those are the defaults). The helper will compile webpack files at most once per test run. The helper will not compile the webpack files unless they are out of date (stale). The helper is configurable in terms of what command is used to prepare the files. If you don't specify these metatags for your relevant JavaScript tests, then you'll need to do the following.

If you are using Webpack to build CSS assets, you should do something like this to ensure that you assets are built for any specs under `specs/requests` or `specs/features`:

```ruby
  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config, :requires_webpack_assets)
  config.define_derived_metadata(file_path: %r{spec/(features|requests)}) do |metadata|
    metadata[:requires_webpack_assets] = true
  end
```

Please take note of the following:
- If you are using Webpacker, be **SURE** to configure the `source_path` in your `config/webpacker.yml` unless you are using the defaults for webpacker. If you are not using webpacker, all files in the node_modules_location are used for your test sources.

- This utility uses your `build_test_command` to build the static generated files. This command **must not** include the `--watch` option. If you have different server and client bundle files, this command **must** create all the bundles. If you are using webpacker, the default value will come from the `config/webpacker.yml` value for the `public_output_path` and the `source_path`

- If you add an older file to your source files, that is already older than the produced output files, no new recompilation is done. The solution to this issue is to clear out your directory of webpack generated files when adding new source files that may have older dates. This is actually a common occurrence when you've built your test generated files and then you sync up your repository files.

- By default, the webpack processes look for the `config.generated_assets_dir` folder for generated files, configured via setting `webpack_generated_files`, in the `config/react_on_rails.rb`. If the `config.generated_assets_dir` folder is missing, is empty, or contains files in the `config.webpack_generated_files` list with `mtime`s older than any of the files in your `client` folder, the helper will recompile your assets. You can override the location of these files inside of `config/initializers/react_on_rails.rb` by passing a filepath (relative to the root of the app) to the `generated_assets_dir` configuration option.

The following `config/react_on_rails.rb` settings **must** match your setup:
```ruby
  # Directory where your generated assets go. All generated assets must go to the same directory.
  # Configure this in your webpack config files. This relative to your Rails root directory.
  # We recommend having different generated assets dirs per Rails env.
  config.generated_assets_dir = File.join(%w[public webpack], Rails.env)

  # Define the files we need to check for webpack compilation when running tests.
  # Generally, the manifest.json is good enough for this check if using webpacker
  config.webpack_generated_files = %w( hello-world-bundle.js )
  
  # If you are using the ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
  # with rspec then this controls what yarn command is run
  # to automatically refresh your webpack assets on every test run.
  config.build_test_command = "yarn run build:test"
```

If you want to speed up the re-compiling process so you don't wait to run your tests to build the files, you can run your test compilation with the "watch" flags.

[spec/dummy](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy) contains examples of how to set the proc files for this purpose.

If you want to use a testing framework other than RSpec, please submit let us know on the changes you need to do and we'll update the docs.

![2016-01-27_02-36-43](https://cloud.githubusercontent.com/assets/1118459/12611951/7c56d070-c4a4-11e5-8a80-9615f99960d9.png)

![2016-01-27_03-18-05](https://cloud.githubusercontent.com/assets/1118459/12611975/a8011654-c4a4-11e5-84f9-1baca4835b4b.png)

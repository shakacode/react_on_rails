# RSpec Configuration
Because you will probably want to run RSpec tests that rely on compiled webpack assets (typically, your integration/feature specs where `js: true`), you will want to ensure you don't accidentally run tests on missing or stale webpack assets. If you did use stale Webpack assets, you will get invalid test results as your tests do not use the very latest JavaScript code.

ReactOnRails provides a helper method called `ReactOnRails::TestHelper.configure_rspec_to_compile_assets`. Call this method from inside of the `RSpec.configure` block in your `spec/rails_helper.rb` file, passing the config as an argument. See file [lib/react_on_rails/test_helper.rb](../../lib/react_on_rails/test_helper.rb) for more details. You can customize this to your particular needs by replacing any of the default components used by `ReactOnRails::TestHelper.configure_rspec_to_compile_assets`.

```ruby
RSpec.configure do |config|
  # Next line will ensure that assets are built if webpack -w is not running to build the bundles
  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
```

You can pass an RSpec metatag as an optional second parameter to this helper method if you want this helper to run on examples other than where `js: true` (default). The helper will compile webpack files at most once per test run.

If you do not want to be slowed down by re-compiling webpack assets from scratch every test run, you can call `npm run build:client` (and `npm run build:server` if doing server rendering) to have webpack recompile these files in the background, which will be *much* faster. The helper looks for these processes and will abort recompiling if it finds them to be running.

If you want to use a testing framework other than RSpec, please submit let us know on the changes you need to do and we'll update the docs.

![2016-01-27_02-36-43](https://cloud.githubusercontent.com/assets/1118459/12611951/7c56d070-c4a4-11e5-8a80-9615f99960d9.png)

![2016-01-27_03-18-05](https://cloud.githubusercontent.com/assets/1118459/12611975/a8011654-c4a4-11e5-84f9-1baca4835b4b.png)

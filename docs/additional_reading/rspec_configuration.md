# RSpec Configuration
Because you will probably want to run RSpec tests that rely on compiled webpack assets (typically, your integration/feature specs where `js: true`), you will want to ensure you don't accidentally run tests on missing or stale webpack assets.

ReactOnRails provides a helper method called `configure_rspec_to_compile_assets`. Call this method from inside of the `RSpec.configure` block in your `spec/rails_helper.rb` file, passing the config as an argument.

You can pass an RSpec metatag as an optional second parameter to this helper method if you want this helper to run on examples other than where `js: true` (default). The helper will compile webpack files only once per test run.

If you are doing a TDD workflow and do not want to be slowed down by re-compiling webpack assets from scratch every test run, you can call `npm run build:client` (and `npm run build:server` if doing server rendering) to have webpack recompile these files in the background, which will be much faster. The helper looks for these processes and will abort recompiling if it finds them to be running.

If you want to use a testing framework other than RSpec, we suggest you implement similar logic.

# Testing Configuration

This guide explains how to configure React on Rails for optimal testing with RSpec, Minitest, or other test frameworks.

## Quick Start

For most applications, the recommended approach is React on Rails TestHelper with `build_test_command`:

```ruby
# config/initializers/react_on_rails.rb
ReactOnRails.configure do |config|
  config.build_test_command = "RAILS_ENV=test bin/shakapacker"
end
```

Then wire TestHelper into your test framework. If your app uses both RSpec and Minitest, wire both files.

**RSpec** — add to `spec/rails_helper.rb`:

```ruby
require "react_on_rails/test_helper"

RSpec.configure do |config|
  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
end
```

**Minitest** — add to `test/test_helper.rb`:

```ruby
require "react_on_rails/test_helper"

class ActiveSupport::TestCase
  setup do
    ReactOnRails::TestHelper.ensure_assets_compiled
  end
end
```

## Two Approaches to Test Asset Compilation

React on Rails supports two mutually exclusive approaches for compiling webpack assets during tests:

### Approach 1: React on Rails Test Helper + build_test_command (Recommended)

**Best for:** Most applications, especially SSR, large suites, and explicit build control

**Configuration:**

```ruby
# config/initializers/react_on_rails.rb
ReactOnRails.configure do |config|
  config.build_test_command = "NODE_ENV=test RAILS_ENV=test bin/shakapacker"

  # Or use your project's package manager with a custom script:
  # config.build_test_command = "pnpm run build:test"  # or: npm run build:test, yarn run build:test
end
```

In `config/shakapacker.yml`, keep test compilation off to avoid mixing approaches:

```yaml
test:
  <<: *default
  compile: false
  public_output_path: webpack/test
```

Then configure your test framework:

**RSpec:**

```ruby
# spec/rails_helper.rb
require "react_on_rails/test_helper"

RSpec.configure do |config|
  # Ensures webpack assets are compiled before the test suite runs
  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
end
```

See [lib/react_on_rails/test_helper.rb](https://github.com/shakacode/react_on_rails/blob/master/react_on_rails/lib/react_on_rails/test_helper.rb) for more details and customization options.

By default, the helper triggers compilation for examples tagged with `:js`, `:server_rendering`, or `:controller`. You can pass custom metatags as an optional second parameter if you need compilation for other specs — for example, if you use Webpack to build CSS assets for request and feature specs:

```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config, :requires_webpack_assets)
  config.define_derived_metadata(file_path: %r{spec/(features|requests)}) do |metadata|
    metadata[:requires_webpack_assets] = true
  end
end
```

**Minitest:**

```ruby
# test/test_helper.rb
require "react_on_rails/test_helper"

class ActiveSupport::TestCase
  setup do
    ReactOnRails::TestHelper.ensure_assets_compiled
  end
end
```

Alternatively, you can use a [Minitest plugin](https://github.com/seattlerb/minitest/blob/master/lib/minitest/test.rb#L119) to run the check in `before_setup`:

```ruby
module MyMinitestPlugin
  def before_setup
    super
    ReactOnRails::TestHelper.ensure_assets_compiled
  end
end

class Minitest::Test
  include MyMinitestPlugin
end
```

**Asset detection settings:**

The following settings in `config/initializers/react_on_rails.rb` control how the test helper detects stale assets:

```ruby
ReactOnRails.configure do |config|
  # Define the files to check for Webpack compilation when running tests.
  config.webpack_generated_files = %w( manifest.json )

  # If you're not hashing the server bundle, include it in the list:
  # config.webpack_generated_files = %w( server-bundle.js manifest.json )
end
```

> **Important:** The `build_test_command` **must not** include the `--watch` option. If you have separate server and client bundles, the command **must** build all of them.

**How it works:**

- Compiles assets at most once per test run, and only when they're out of date (stale)
- The helper checks the Webpack-generated files folder (configured via `public_root_path` and `public_output_path` in `config/shakapacker.yml`). If the folder is missing, empty, or contains files listed in `webpack_generated_files` with `mtime`s older than any source files, assets are recompiled.
- Uses the `build_test_command` configuration
- Fails fast if compilation has errors

**Pros:**

- ✅ Explicit control over compilation timing
- ✅ Assets compiled only once per test run
- ✅ Clear error messages if compilation fails
- ✅ Can customize the build command
- ✅ Reliable for SSR tests because assets are built before first render

**Cons:**

- ⚠️ Requires additional configuration in test helpers
- ⚠️ More setup to maintain
- ⚠️ Requires `build_test_command` to be set

**When to use:**

- You want to compile assets exactly once before tests
- You need to customize the build command
- You want explicit error handling for compilation failures
- Your test suite is slow and you want to optimize compilation
- You run SSR tests and need server bundles available before first request

### Approach 2: Shakapacker Auto-Compilation (Alternative)

**Best for:** Simpler non-SSR test setups or teams that prefer minimal configuration

**Configuration:**

```yaml
# config/shakapacker.yml
test:
  <<: *default
  compile: true
  public_output_path: webpack/test
```

And remove React on Rails TestHelper wiring:

- Remove `config.build_test_command`
- Remove `ReactOnRails::TestHelper` calls in `spec/rails_helper.rb` or `test/test_helper.rb`

**How it works:**

- Shakapacker compiles assets on demand when packs are requested
- No React on Rails TestHelper setup is required

**Pros:**

- ✅ Simpler setup
- ✅ Works across frameworks without helper wiring

**Cons:**

- ⚠️ Less explicit compilation timing
- ⚠️ May compile multiple times in long or parallel runs
- ⚠️ For SSR tests, first-request ordering can matter if server bundles are not prebuilt

## Don't Mix Approaches

**Do not use both approaches together.** They are mutually exclusive:

```yaml
# config/shakapacker.yml
test:
  compile: true # ← Don't do this...
```

```ruby
# config/initializers/react_on_rails.rb
config.build_test_command = "RAILS_ENV=test bin/shakapacker"  # ← ...with this

# spec/rails_helper.rb
ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)  # ← ...and this
```

This will cause assets to be compiled multiple times unnecessarily.

## Migrating Between Approaches

### From React on Rails Test Helper → Shakapacker Auto-Compilation

1. Set `compile: true` in `config/shakapacker.yml` test section:

   ```yaml
   test:
     compile: true
     public_output_path: webpack/test
   ```

2. Remove test helper configuration from spec/test helpers:

   ```ruby
   # spec/rails_helper.rb - REMOVE these lines:
   require "react_on_rails/test_helper"
   ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
   ```

3. Remove or comment out `build_test_command` in React on Rails config:
   ```ruby
   # config/initializers/react_on_rails.rb
   # config.build_test_command = "RAILS_ENV=test bin/shakapacker"  # ← Comment out
   ```

### From Shakapacker Auto-Compilation → React on Rails Test Helper

1. Set `compile: false` in `config/shakapacker.yml` test section:

   ```yaml
   test:
     compile: false
     public_output_path: webpack/test
   ```

2. Add `build_test_command` to React on Rails config:

   ```ruby
   # config/initializers/react_on_rails.rb
   config.build_test_command = "RAILS_ENV=test bin/shakapacker"
   ```

3. Add test helper configuration:

   ```ruby
   # spec/rails_helper.rb (for RSpec)
   require "react_on_rails/test_helper"

   RSpec.configure do |config|
     ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
   end
   ```

## Verifying Your Configuration

Use the React on Rails doctor command to verify your test configuration:

```bash
bundle exec rake react_on_rails:doctor
```

To auto-apply supported test-setup fixes (recommended path), run:

```bash
FIX=true bundle exec rake react_on_rails:doctor
```

The doctor will check:

- Whether `compile: true` is set in shakapacker.yml
- Whether `build_test_command` is configured
- Whether test helpers are properly set up
- Whether each detected framework (RSpec/Minitest) is wired independently
- Whether you're accidentally using both approaches

## Troubleshooting

### Assets not compiling during tests

**Problem:** Tests fail because JavaScript/CSS assets are not compiled.

**Solution:** Check which approach you're using:

1. **If using Shakapacker auto-compilation:**

   ```yaml
   # config/shakapacker.yml
   test:
     compile: true # ← Make sure this is true
   ```

2. **If using React on Rails test helper:**
   - Verify `build_test_command` is set
   - Check that test helper is configured in spec/test helper
   - Run `bundle exec rake react_on_rails:doctor`

### Assets compiling multiple times

**Problem:** Tests are slow because assets compile repeatedly.

**Solutions:**

1. **If using Shakapacker auto-compilation:**
   - Switch to React on Rails test helper for one-time compilation
   - Or ensure `cache_manifest: true` in shakapacker.yml

2. **If using React on Rails test helper:**
   - This shouldn't happen - assets should compile only once
   - Check that you don't also have `compile: true` in shakapacker.yml

### Stale assets not recompiling

**Problem:** You added a source file but the test helper doesn't trigger recompilation.

**Cause:** The test helper compares `mtime`s of source files against generated output files. If you add a source file that has an older timestamp than the existing output (e.g., copied from another directory or restored from version control), it won't be detected as a change.

**Solution:** Clear out your Webpack-generated files directory to force recompilation:

```bash
rm -rf public/webpack/test
```

### Build command fails

**Problem:** `build_test_command` fails with errors.

**Check:**

1. Does `bin/shakapacker` exist and is it executable?

   ```bash
   ls -la bin/shakapacker
   chmod +x bin/shakapacker  # If needed
   ```

2. Can you run the command manually?

   ```bash
   RAILS_ENV=test bin/shakapacker
   ```

3. Are your webpack configs valid for test environment?

### Test helper not found

**Problem:** `LoadError: cannot load such file -- react_on_rails/test_helper`

**Solution:** Make sure react_on_rails gem is available in test environment:

```ruby
# Gemfile
gem "react_on_rails", ">= 16.0"  # Not in a specific group

# Or explicitly in test group:
group :test do
  gem "react_on_rails"
end
```

## Performance Considerations

### Asset Compilation Speed

**Shakapacker auto-compilation:**

- Compiles on first request per test process
- May compile multiple times in parallel test environments
- Good for: Small test suites, simple webpack configs

**React on Rails test helper:**

- Compiles once before entire test suite
- Blocks test start until compilation complete
- Good for: Large test suites, complex webpack configs

### Faster Development with Watch Mode

If you're using the React on Rails test helper and want to avoid waiting for compilation on each test run, run your build command with the `--watch` flag in a separate terminal:

```bash
RAILS_ENV=test bin/shakapacker --watch

# Or with your package manager:
# pnpm run build:test --watch
# npm run build:test -- --watch
# yarn run build:test --watch
```

This keeps webpack running and recompiling automatically when files change, so your tests start faster.

> **Note:** The `--watch` flag should only be used in a separate terminal process — never include it in `build_test_command`, which must exit after compilation.

### Automatic Dev Asset Reuse (Static Mode)

When you run `bin/dev static`, React on Rails automatically detects the fresh development assets and reuses them for tests — **no extra commands or environment variables needed**.

```bash
# Terminal 1: Start static development
bin/dev static

# Terminal 2: Just run tests — they automatically use dev assets
bundle exec rspec
```

**How it works:** When `bundle exec rspec` (or Minitest) runs and test assets are stale or missing, the TestHelper checks if development assets in `public/packs/` are:

1. Present (manifest.json exists)
2. Static mode (not HMR — no `http://` URLs in manifest entries)
3. Fresh (manifest newer than all source files)

If all checks pass, React on Rails temporarily overrides Shakapacker's test config to point at the development output. You'll see:

```text
====> React on Rails: Reusing development assets from packs
      (detected fresh static-mode webpack output, skipping test compilation)
```

No `shakapacker.yml` changes are needed. The override only lasts for the test process.

### Running `bin/dev` (HMR) and Tests Together

HMR assets are served from webpack-dev-server memory and contain `http://` URLs in the manifest, so they **cannot** be reused by tests. When using HMR mode, you have two options:

**Option A: Let TestHelper compile on demand (simplest)**

```bash
# Terminal 1
bin/dev

# Terminal 2 — TestHelper runs build_test_command automatically if assets are stale
bundle exec rspec
```

This works but adds compilation time to the first test run.

**Option B: Use a test watcher for fast iteration**

```bash
# Terminal 1
bin/dev

# Terminal 2 — keeps test assets fresh in the background
bin/dev test-watch

# Terminal 3
bundle exec rspec
```

`bin/dev test-watch` auto-selects watch mode:

- `auto` (default): picks `client-only` if another shakapacker watcher is already running; otherwise `full`
- `full`: always builds test client + server bundles (`--test-watch-mode=full`)
- `client-only`: only builds test client bundles (`--test-watch-mode=client-only`)

### Which Mode Should I Use?

| Scenario                    | Recommendation                                               |
| --------------------------- | ------------------------------------------------------------ |
| General development         | `bin/dev static` — simpler, no FOUC, tests just work         |
| Need Hot Module Replacement | `bin/dev` + `bin/dev test-watch` for fast test iteration     |
| CI / no dev server running  | Just `bundle exec rspec` — TestHelper compiles automatically |
| Only running a few tests    | `bin/dev static` + `bundle exec rspec spec/path/to_spec.rb`  |

### Migration to `bin/dev test-watch`

If you previously ran manual test watcher commands, migrate to the new wrapper:

- Old: `RAILS_ENV=test bin/shakapacker --watch`
- New: `bin/dev test-watch`

- Old: `RAILS_ENV=test CLIENT_BUNDLE_ONLY=yes bin/shakapacker --watch`
- New: `bin/dev test-watch --test-watch-mode=client-only`

### Advanced: Manual Shared Output (Alternative)

If you prefer to manually share output paths instead of using automatic detection:

1. Set the test output path equal to development in `config/shakapacker.yml`:

   ```yaml
   development:
     public_output_path: packs

   test:
     public_output_path: packs
   ```

2. Run static development mode and tests:

   ```bash
   bin/dev static    # Terminal 1
   bundle exec rspec # Terminal 2
   ```

> **Warning:** Do not share output paths with `bin/dev` (HMR mode) — HMR manifests will cause test failures.

### Caching Strategies

Improve compilation speed with caching:

```yaml
# config/shakapacker.yml
test:
  cache_manifest: true # Cache manifest between runs
```

### Parallel Testing

When running tests in parallel (with `parallel_tests` gem):

**Shakapacker auto-compilation:**

- Each process compiles independently (may be slow)
- Consider precompiling assets before running parallel tests:
  ```bash
  RAILS_ENV=test bin/shakapacker
  bundle exec rake parallel:spec
  ```

**React on Rails test helper:**

- Compiles once before forking processes (efficient)
- Works well out of the box with parallel testing

## CI/CD Considerations

### GitHub Actions / GitLab CI

**Option 1: Precompile before tests**

```yaml
- name: Compile test assets
  run: RAILS_ENV=test bundle exec rake react_on_rails:assets:compile_environment

- name: Run tests
  run: bundle exec rspec
```

**Option 2: Use Shakapacker auto-compilation**

```yaml
# config/shakapacker.yml
test:
  compile: true

# CI workflow
- name: Run tests (assets auto-compile)
  run: bundle exec rspec
```

### Docker

When running tests in Docker, consider:

1. Caching `node_modules` between builds
2. Precompiling assets in Docker build stage
3. Using bind mounts for local development

## Best Practices

1. **Choose one approach** - Don't mix Shakapacker auto-compilation with React on Rails test helper
2. **Use doctor command** - Run `rake react_on_rails:doctor` to verify configuration
3. **Precompile in CI** - Consider precompiling assets before running tests in CI
4. **Cache node_modules** - Speed up installation with caching
5. **Monitor compile times** - If tests are slow, check asset compilation timing

## Summary Decision Matrix

| Scenario             | Recommendation                           |
| -------------------- | ---------------------------------------- |
| Default setup        | React on Rails test helper               |
| SSR test coverage    | React on Rails test helper               |
| Large test suite     | React on Rails test helper               |
| Parallel testing     | React on Rails test helper or precompile |
| CI/CD pipeline       | Precompile before tests                  |
| Quick local tests    | Shakapacker `compile: true`              |
| Custom build command | React on Rails test helper               |

## Related Documentation

- [Dev Server and Testing](./dev-server-and-testing.md) — How `bin/dev` (HMR vs static) interacts with Capybara, Playwright, Minitest system tests, and SSR request specs
- [Configuration Reference](../configuration/README.md#build_test_command)
- [Shakapacker Configuration](https://github.com/shakacode/shakapacker#configuration)
- [TestHelper Source Code](https://github.com/shakacode/react_on_rails/blob/master/react_on_rails/lib/react_on_rails/test_helper.rb)

## Need Help?

- **Forum:** [ShakaCode Forum](https://forum.shakacode.com/)
- **Docs:** [React on Rails Guides](https://reactonrails.com/docs/)
- **Support:** [justin@shakacode.com](mailto:justin@shakacode.com)

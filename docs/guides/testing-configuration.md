# Testing Configuration Guide

This guide explains how to configure React on Rails for optimal testing with RSpec, Minitest, or other test frameworks.

## Quick Start

For most applications, the simplest approach is to let Shakapacker handle asset compilation automatically:

```yaml
# config/shakapacker.yml
test:
  compile: true
  public_output_path: webpack/test
```

That's it! Shakapacker will automatically compile assets before running tests.

## Two Approaches to Test Asset Compilation

React on Rails supports two mutually exclusive approaches for compiling webpack assets during tests:

### Approach 1: Shakapacker Auto-Compilation (Recommended)

**Best for:** Most applications, especially simpler test setups

**Configuration:**

```yaml
# config/shakapacker.yml
test:
  <<: *default
  compile: true
  public_output_path: webpack/test
```

**How it works:**

- Shakapacker automatically compiles assets when they're requested
- No additional configuration in React on Rails or test helpers needed
- Assets are compiled on-demand during test runs

**Pros:**

- ✅ Simplest configuration
- ✅ No extra setup in spec helpers
- ✅ Automatically integrates with Rails test environment
- ✅ Works with any test framework (RSpec, Minitest, etc.)

**Cons:**

- ⚠️ May compile assets multiple times during test runs
- ⚠️ Less explicit control over when compilation happens
- ⚠️ Can slow down tests if assets change frequently

**When to use:**

- You want the simplest possible configuration
- Your test suite is relatively fast
- You don't mind automatic compilation on-demand

### Approach 2: React on Rails Test Helper (Explicit Control)

**Best for:** Applications needing precise control over compilation timing

**Configuration:**

```ruby
# config/initializers/react_on_rails.rb
ReactOnRails.configure do |config|
  config.build_test_command = "RAILS_ENV=test bin/shakapacker"
end
```

```ruby
# spec/rails_helper.rb (for RSpec)
require "react_on_rails/test_helper"

RSpec.configure do |config|
  # Ensures webpack assets are compiled before the test suite runs
  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
end
```

```ruby
# test/test_helper.rb (for Minitest)
require "react_on_rails/test_helper"

class ActiveSupport::TestCase
  # Ensures webpack assets are compiled before running tests
  ReactOnRails::TestHelper.ensure_assets_compiled
end
```

**How it works:**

- Compiles assets once before the test suite starts
- Uses the `build_test_command` configuration
- Fails fast if compilation has errors

**Pros:**

- ✅ Explicit control over compilation timing
- ✅ Assets compiled only once per test run
- ✅ Clear error messages if compilation fails
- ✅ Can customize the build command

**Cons:**

- ⚠️ Requires additional configuration in test helpers
- ⚠️ More setup to maintain
- ⚠️ Requires `build_test_command` to be set

**When to use:**

- You want to compile assets exactly once before tests
- You need to customize the build command
- You want explicit error handling for compilation failures
- Your test suite is slow and you want to optimize compilation

## ⚠️ Important: Don't Mix Approaches

**Do not use both approaches together.** They are mutually exclusive:

❌ **Wrong:**

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

The doctor will check:

- Whether `compile: true` is set in shakapacker.yml
- Whether `build_test_command` is configured
- Whether test helpers are properly set up
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

### Caching Strategies

Improve compilation speed with caching:

```yaml
# config/shakapacker.yml
test:
  cache_manifest: true # Cache manifest between runs
```

```ruby
# config/initializers/react_on_rails.rb
# If using test helper, webpack will use its own caching
config.build_test_command = "RAILS_ENV=test bin/shakapacker"
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
| Simple test setup    | Shakapacker `compile: true`              |
| Large test suite     | React on Rails test helper               |
| Parallel testing     | React on Rails test helper or precompile |
| CI/CD pipeline       | Precompile before tests                  |
| Quick local tests    | Shakapacker `compile: true`              |
| Custom build command | React on Rails test helper               |

## Related Documentation

- [Configuration Reference](../api-reference/configuration.md#build_test_command)
- [Shakapacker Configuration](https://github.com/shakacode/shakapacker#configuration)
- [RSpec Configuration](../building-features/rspec-configuration.md)
- [Minitest Configuration](../building-features/minitest-configuration.md)

## Need Help?

- **Forum:** [ShakaCode Forum](https://forum.shakacode.com/)
- **Docs:** [React on Rails Guides](https://www.shakacode.com/react-on-rails/docs/)
- **Support:** [justin@shakacode.com](mailto:justin@shakacode.com)

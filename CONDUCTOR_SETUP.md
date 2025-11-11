# Conductor Workspace Setup Guide

This guide helps you set up and run tests in a Conductor workspace for the React on Rails project.

## Quick Start

1. **Install dependencies:**

   ```bash
   bundle install
   cd spec/dummy
   bundle install
   yarn install
   cd ../..
   ```

2. **Set up local test configuration (for SSL issues):**

   ```bash
   cd spec/dummy/spec
   cp rails_helper.local.rb.example rails_helper.local.rb
   # Edit rails_helper.local.rb and uncomment the Conductor configuration
   ```

3. **Run tests:**

   ```bash
   cd spec/dummy
   bundle exec rspec './spec/system/integration_spec.rb:312'
   ```

## Common Issues

### SSL Certificate Verification Errors

**Symptom:**

```
OpenSSL::SSL::SSLError: SSL_connect returned=1 errno=0 state=error:
certificate verify failed (unable to get certificate CRL)
```

**Solution:**

Create `spec/dummy/spec/rails_helper.local.rb` with the following content:

```ruby
# frozen_string_literal: true

# Conductor workspace configuration
require "webdrivers"
Webdrivers.cache_time = 86_400 * 365 # Disable auto-updates

require "openssl"
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
```

**Note:** This file is gitignored and won't be committed. It's safe to use in isolated Conductor workspaces.

### Capybara/Rack Compatibility Issues

**Symptom:**

```
NameError: uninitialized constant Rack::Handler
```

**Solution:**
This was fixed by upgrading Capybara to 3.40.0. Run `bundle update capybara` in `spec/dummy/`.

## Environment Details

### What's Different in Conductor Workspaces?

- Each workspace is an isolated clone of the repository
- SSL certificate verification may fail due to sandbox restrictions
- Network access may be throttled or restricted
- Some system-level operations may behave differently

### Local Configuration Pattern

The project uses a local configuration pattern for environment-specific settings:

- `rails_helper.rb` - Main configuration (committed to git)
- `rails_helper.local.rb` - Local overrides (gitignored)
- `rails_helper.local.rb.example` - Template for local config (committed)

This allows developers to customize their test environment without affecting others.

## Running Different Test Suites

```bash
# Single test
bundle exec rspec './spec/system/integration_spec.rb:312'

# All system tests
bundle exec rspec spec/system/

# All specs in spec/dummy
bundle exec rspec

# With documentation format
bundle exec rspec --format documentation
```

## Debugging Tests

### View Browser Actions

Tests run headless by default. To see the browser:

1. Edit `spec/dummy/spec/support/capybara_setup.rb`
2. Change `selenium_chrome_headless` to `selenium_chrome`

### Screenshots on Failure

Failed tests automatically save screenshots to:

```
spec/dummy/tmp/capybara/failures_*.png
```

### Console Logging

JavaScript errors and console output are captured in test failures.

## Additional Resources

- [Main React on Rails README](../../README.md)
- [Testing Documentation](../../docs/basics/testing.md)
- [Conductor Documentation](https://conductor.build)

## Troubleshooting

### Tests Timing Out

Increase timeout in `spec/dummy/spec/support/capybara_setup.rb`:

```ruby
Capybara.default_max_wait_time = 10 # seconds
```

### Webdriver Version Mismatches

Update chromedriver:

```bash
# Let webdrivers download the latest
rm -rf ~/.webdrivers
```

### Port Conflicts

If port 5017 is in use, kill the process:

```bash
lsof -ti:5017 | xargs kill -9
```

## Getting Help

- **GitHub Issues**: [react_on_rails/issues](https://github.com/shakacode/react_on_rails/issues)
- **Conductor Support**: [humans@conductor.build](mailto:humans@conductor.build)
- **Community Forum**: [forum.shakacode.com](https://forum.shakacode.com)

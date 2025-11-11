# Testing Locally

## Reproducing CI Failures with Component Registration Race Conditions

If you see CI failures like "Could not find component registered with name ReduxSharedStoreApp", this is due to a race condition with async script loading. Here's how to reproduce and fix it locally:

### Quick Reproduction

```bash
cd spec/dummy

# Test with async loading (CI default for library users)
REACT_ON_RAILS_LOADING_STRATEGY=async bundle exec rspec spec/system/integration_spec.rb -e "shared_store"

# If that passes but CI fails, run multiple times to catch intermittent failures:
for i in {1..5}; do
  echo "Run $i:"
  REACT_ON_RAILS_LOADING_STRATEGY=async bundle exec rspec spec/system/integration_spec.rb:376 spec/system/integration_spec.rb:380
done
```

### Understanding the Issue

- **The dummy app defaults to `:defer`** to prevent race conditions during development
- **Real user apps default to `:async`** (when Shakapacker >= 8.2.0) for better performance
- **The race condition**: With async, `client-bundle.js` can execute before generated component packs, causing components to be missing from the registry when React tries to hydrate

### The Fix

The dummy app uses an environment variable to control the loading strategy:

```ruby
# spec/dummy/config/initializers/react_on_rails.rb
loading_strategy = ENV.fetch("REACT_ON_RAILS_LOADING_STRATEGY", "defer").to_sym
config.generated_component_packs_loading_strategy = loading_strategy
```

This allows testing both strategies without code changes.

### When CI Fails But Local Passes

1. **Check the loading strategy**: CI may be testing with `:async` while you're testing with `:defer`
2. **Run with async locally**: Use the environment variable to match CI conditions
3. **If it's intermittent**: The race condition timing varies - run tests multiple times

### SSL Issues (Not Related to Component Registration)

## Known Issues with Ruby 3.4.3 + OpenSSL 3.6

If you're running Ruby 3.4.3 with OpenSSL 3.6+, you may encounter SSL certificate verification errors in system tests:

```
SSL_connect returned=1 errno=0 peeraddr=185.199.108.153:443 state=error:
certificate verify failed (unable to get certificate CRL)
```

This is caused by OpenSSL 3.6's stricter CRL (Certificate Revocation List) checking when tests access external resources like GitHub Pages.

### Workaround

The SSL errors don't indicate issues with the code being tested - they're environment-specific. The attempted fix in `spec/rails_helper.rb` sets `OPENSSL_CONF`, but this doesn't affect all Ruby networking code.

### Recommendation

**Use CI as the source of truth for system tests**. These SSL issues don't occur in CI environments:

- CI uses containerized environments with compatible OpenSSL versions
- Local environment issues (SSL, certificates, Rack 3 compat) don't affect CI

### What You Can Test Locally

✅ **Unit tests** - Run reliably:

```bash
bundle exec rspec spec/react_on_rails/
```

✅ **Helper tests** - Run reliably:

```bash
bundle exec rspec spec/helpers/
```

✅ **Gem-only tests** - Skip system tests:

```bash
bundle exec rake run_rspec:gem
```

❌ **System tests** - May fail with SSL errors on Ruby 3.4.3 + OpenSSL 3.6

### Solution: Use Ruby 3.2 (Recommended)

The easiest fix is to switch to Ruby 3.2, which CI also uses:

```bash
# If using mise/rtx
mise use ruby@3.2

# Then reinstall dependencies
bundle install

# Run system tests
cd spec/dummy
bundle exec rspec spec/system/integration_spec.rb
```

Ruby 3.2 doesn't have the OpenSSL 3.6 compatibility issues and matches the CI environment more closely.

### Alternative Solutions

If you need to run system tests locally but want to stay on Ruby 3.4:

1. **Use Ruby 3.4 with OpenSSL 3.3** - Requires recompiling Ruby with an older OpenSSL
2. **Or rely on CI** for system test verification
3. **Focus local testing** on unit/integration tests that don't require browser automation

This issue is tracked in: https://github.com/openssl/openssl/issues/20385

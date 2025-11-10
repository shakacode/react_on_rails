# Testing Locally

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

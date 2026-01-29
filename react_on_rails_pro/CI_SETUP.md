# React on Rails Pro - CI/CD Setup Guide

This guide explains how React on Rails Pro works in CI/CD environments.

## No License Needed for CI/CD

**CI/CD environments work without a license.** No setup is needed to run tests, builds, or any CI tasks. React on Rails Pro runs in unlicensed mode automatically when no license is present.

This means:
- ✅ Tests run without a license
- ✅ Builds run without a license
- ✅ No environment variables to configure
- ✅ No secrets to manage for CI

**For production server configuration**, see [LICENSE_SETUP.md](./LICENSE_SETUP.md). The license is validated when the Rails app boots in production, not during CI/CD.

## Example CI Configurations

These examples show that no special license configuration is needed.

### GitHub Actions

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    # No license configuration needed
    steps:
      - uses: actions/checkout@v3

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.3
          bundler-cache: true

      - name: Set up Node
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: |
          bundle install
          pnpm install

      - name: Run tests
        run: bundle exec rspec
```

### GitLab CI/CD

```yaml
# .gitlab-ci.yml
image: ruby:3.3

variables:
  RAILS_ENV: test
  NODE_ENV: test

test:
  # No license configuration needed
  script:
    - bundle install --jobs $(nproc)
    - pnpm install
    - bundle exec rspec
```

### CircleCI

```yaml
# .circleci/config.yml
version: 2.1

jobs:
  test:
    docker:
      - image: cimg/ruby:3.3-node
    # No license configuration needed
    steps:
      - checkout
      - run:
          name: Install dependencies
          command: |
            bundle install --path vendor/bundle
            pnpm install
      - run:
          name: Run tests
          command: bundle exec rspec

workflows:
  version: 2
  test:
    jobs:
      - test
```

### Generic CI

```bash
# No license needed — just run your tests normally
bundle install
pnpm install
bundle exec rspec
```

### Docker-based CI

```bash
# No license needed
docker run your-test-image bundle exec rspec
```

## Troubleshooting

### Warning: "No license found" in CI

This is **expected behavior**. The application runs in unlicensed mode, which is fine for CI/CD environments. No action needed.

### Tests Pass Locally But Fail in CI

This is unrelated to licensing — CI doesn't need a license. Check for environment differences (Ruby/Node versions, missing dependencies).

## Support

Need help with CI setup?

- **Production license setup**: [LICENSE_SETUP.md](./LICENSE_SETUP.md)
- **Email Support**: support@shakacode.com

# React on Rails Pro - CI/CD Setup Guide

This guide explains how to configure React on Rails Pro for CI/CD environments.

## Quick Start

**CI/CD environments work without a license.** No setup is needed to run tests, builds, or other non-production CI tasks.

If your CI pipeline also **deploys to production**, ensure the production environment has a valid paid license configured via the `REACT_ON_RAILS_PRO_LICENSE` environment variable.

## Configuration by CI Provider

### GitHub Actions

If your workflow deploys to production, add the license to your deployment job:

**Step 1: Add License to Secrets**

1. Go to your repository settings
2. Navigate to: Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `REACT_ON_RAILS_PRO_LICENSE`
5. Value: Your complete JWT license token (starts with `eyJ...`)

**Step 2: Use in Workflow (Production Deployment Only)**

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    # No license needed for tests
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

  deploy:
    needs: test
    runs-on: ubuntu-latest
    env:
      # License needed only for production deployment
      REACT_ON_RAILS_PRO_LICENSE: ${{ secrets.REACT_ON_RAILS_PRO_LICENSE }}
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to production
        run: ./deploy.sh
```

### GitLab CI/CD

**Step 1: Add License to CI/CD Variables (for production deployment)**

1. Go to your project
2. Navigate to: Settings → CI/CD → Variables
3. Click "Add variable"
4. Key: `REACT_ON_RAILS_PRO_LICENSE`
5. Value: Your license token
6. ✅ Check "Protect variable" (optional)
7. ✅ Check "Mask variable" (recommended)

**Step 2: Use in Pipeline**

```yaml
# .gitlab-ci.yml
image: ruby:3.3

variables:
  RAILS_ENV: test
  NODE_ENV: test

test:
  # No license needed for tests
  script:
    - bundle install --jobs $(nproc)
    - pnpm install
    - bundle exec rspec

deploy:
  stage: deploy
  # License automatically available from CI/CD variables for production
  script:
    - ./deploy.sh
  only:
    - main
```

### CircleCI

**Step 1: Add License to Environment Variables (for production deployment)**

1. Go to your project settings
2. Navigate to: Project Settings → Environment Variables
3. Click "Add Environment Variable"
4. Name: `REACT_ON_RAILS_PRO_LICENSE`
5. Value: Your license token

**Step 2: Use in Config**

```yaml
# .circleci/config.yml
version: 2.1

jobs:
  test:
    docker:
      - image: cimg/ruby:3.3-node
    # No license needed for tests
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

  deploy:
    docker:
      - image: cimg/ruby:3.3-node
    # License available from environment variables for production
    steps:
      - checkout
      - run:
          name: Deploy to production
          command: ./deploy.sh

workflows:
  version: 2
  test-and-deploy:
    jobs:
      - test
      - deploy:
          requires:
            - test
          filters:
            branches:
              only: main
```

### Generic CI (Environment Variable)

For any CI system:

- **Tests and builds**: No license needed — just run your tests normally
- **Production deployment**: Set the `REACT_ON_RAILS_PRO_LICENSE` environment variable

```bash
# Tests work without a license
bundle install
pnpm install
bundle exec rspec

# For production deployment, set the license
export REACT_ON_RAILS_PRO_LICENSE="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
./deploy.sh
```

## Docker-based CI

If using Docker in CI:

```dockerfile
# Dockerfile
FROM ruby:3.3-node

# ... other setup ...

# License will be passed at runtime for production only
# DO NOT COPY license file into image
CMD ["bundle", "exec", "rspec"]
```

**Run tests (no license needed):**

```bash
docker run your-image
```

**Run with license (production deployment):**

```bash
docker run -e REACT_ON_RAILS_PRO_LICENSE="$REACT_ON_RAILS_PRO_LICENSE" your-image
```

## Verification

License validation happens automatically when Rails starts.

- ✅ **Tests run without a license** — the app runs in unlicensed mode
- ✅ **Production requires a valid paid license** — set the environment variable

### Debug License Issues

If production deployment fails with license errors:

```bash
# Check if license environment variable is set (show first 20 chars only)
echo "License set: ${REACT_ON_RAILS_PRO_LICENSE:0:20}..."

# Decode the license to check expiration
bundle exec rails runner "
  require 'jwt'
  payload = JWT.decode(ENV['REACT_ON_RAILS_PRO_LICENSE'], nil, false).first
  puts 'Email: ' + payload['sub']
  puts 'Expires: ' + Time.at(payload['exp']).to_s
  puts 'Expired: ' + (Time.now.to_i > payload['exp']).to_s
  puts 'Plan: ' + (payload['plan'] || 'none')
"
```

**Common issues:**
- License not set in production environment variables
- License truncated when copying (should be 500+ characters)
- License expired — contact [support@shakacode.com](mailto:support@shakacode.com) to renew
- License has a non-paid plan — purchase a paid license

## Security Best Practices

1. ✅ **Always use secrets/encrypted variables** — Never commit licenses to code
2. ✅ **Mask license in logs** — Most CI systems support this
3. ✅ **Limit license access** — Only give to production deployment jobs
4. ✅ **Use organization secrets** — Share across repositories when appropriate

## Troubleshooting

### Warning: "No license found" in CI

This is **expected behavior** for test and build jobs. The application runs in unlicensed mode, which is fine for non-production environments.

If you see this in a **production deployment**, ensure the `REACT_ON_RAILS_PRO_LICENSE` environment variable is set.

### Error: "License has expired"

**Solution:**
1. Contact [support@shakacode.com](mailto:support@shakacode.com) to renew your paid license
2. Update the `REACT_ON_RAILS_PRO_LICENSE` variable in your CI settings
3. No code changes needed

### Tests Pass Locally But Fail in CI

**Common causes:**
- Unrelated to licensing (CI doesn't need a license for tests)
- Check for environment differences (Ruby/Node versions, missing dependencies)

## Multiple Environments

### When to Use a License

- **CI/Test jobs**: No license needed
- **Staging (non-production)**: No license needed
- **Production deployment**: Paid license required

```yaml
# GitHub Actions example
jobs:
  test:
    # No license env needed

  staging-deploy:
    # No license env needed (non-production)

  production-deploy:
    env:
      REACT_ON_RAILS_PRO_LICENSE: ${{ secrets.PRODUCTION_LICENSE }}
```

## Support

Need help with CI setup?

- **Documentation**: [LICENSE_SETUP.md](./LICENSE_SETUP.md)
- **Email Support**: support@shakacode.com
- **Sales**: [justin@shakacode.com](mailto:justin@shakacode.com) for pricing

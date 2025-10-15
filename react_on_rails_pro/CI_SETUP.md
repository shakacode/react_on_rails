# React on Rails Pro - CI/CD Setup Guide

This guide explains how to configure React on Rails Pro licenses for CI/CD environments.

## Quick Start

**All CI/CD environments require a valid license!**

1. Get a FREE 3-month license at [shakacode.com/react-on-rails-pro](https://shakacode.com/react-on-rails-pro)
2. Add `REACT_ON_RAILS_PRO_LICENSE` to your CI environment variables
3. Done! Your tests will run with a valid license

**⚠️ Important: The free 3-month evaluation license is intended for personal, educational, and evaluation purposes only (including CI/CD testing). It should NOT be used for production deployments. Production use requires a paid license.**

## Getting a License for CI

You have two options:

### Option 1: Use a Team Member's License
- Any developer's FREE license works for CI
- Share it via CI secrets/environment variables
- Easy and quick

### Option 2: Create a Dedicated CI License
- Register with `ci@yourcompany.com` or similar
- Get a FREE 3-month evaluation license (for personal, educational, and evaluation purposes only)
- Renew every 3 months (or use a paid license for production)

## Configuration by CI Provider

### GitHub Actions

**Step 1: Add License to Secrets**

1. Go to your repository settings
2. Navigate to: Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `REACT_ON_RAILS_PRO_LICENSE`
5. Value: Your complete JWT license token (starts with `eyJ...`)

**Step 2: Use in Workflow**

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    env:
      REACT_ON_RAILS_PRO_LICENSE: ${{ secrets.REACT_ON_RAILS_PRO_LICENSE }}

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
          cache: 'yarn'

      - name: Install dependencies
        run: |
          bundle install
          yarn install

      - name: Run tests
        run: bundle exec rspec
```

### GitLab CI/CD

**Step 1: Add License to CI/CD Variables**

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

before_script:
  - gem install bundler
  - bundle install --jobs $(nproc)
  - curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
  - echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
  - apt-get update && apt-get install -y nodejs yarn
  - yarn install

test:
  script:
    - bundle exec rspec
  # License is automatically available from CI/CD variables
```

### CircleCI

**Step 1: Add License to Environment Variables**

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

    steps:
      - checkout

      - restore_cache:
          keys:
            - gem-cache-{{ checksum "Gemfile.lock" }}
            - yarn-cache-{{ checksum "yarn.lock" }}

      - run:
          name: Install dependencies
          command: |
            bundle install --path vendor/bundle
            yarn install

      - save_cache:
          key: gem-cache-{{ checksum "Gemfile.lock" }}
          paths:
            - vendor/bundle

      - save_cache:
          key: yarn-cache-{{ checksum "yarn.lock" }}
          paths:
            - node_modules

      - run:
          name: Run tests
          command: bundle exec rspec
          # License is automatically available from environment variables

workflows:
  version: 2
  test:
    jobs:
      - test
```

### Travis CI

**Step 1: Add License to Environment Variables**

1. Go to your repository settings on Travis CI
2. Navigate to: More options → Settings → Environment Variables
3. Name: `REACT_ON_RAILS_PRO_LICENSE`
4. Value: Your license token
5. ✅ Check "Display value in build log": **NO** (keep it secret)

**Step 2: Use in Config**

```yaml
# .travis.yml
language: ruby
rvm:
  - 3.3

node_js:
  - 18

cache:
  bundler: true
  yarn: true

before_install:
  - nvm install 18
  - node --version
  - yarn --version

install:
  - bundle install
  - yarn install

script:
  - bundle exec rspec
  # License is automatically available from environment variables
```

### Jenkins

**Step 1: Add License to Credentials**

1. Go to Jenkins → Manage Jenkins → Manage Credentials
2. Select appropriate domain
3. Add Credentials → Secret text
4. Secret: Your license token
5. ID: `REACT_ON_RAILS_PRO_LICENSE`
6. Description: "React on Rails Pro License"

**Step 2: Use in Jenkinsfile**

```groovy
// Jenkinsfile
pipeline {
    agent any

    environment {
        RAILS_ENV = 'test'
        NODE_ENV = 'test'
    }

    stages {
        stage('Setup') {
            steps {
                // Load license from credentials
                withCredentials([string(credentialsId: 'REACT_ON_RAILS_PRO_LICENSE', variable: 'REACT_ON_RAILS_PRO_LICENSE')]) {
                    sh 'echo "License loaded"'
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'bundle install'
                sh 'yarn install'
            }
        }

        stage('Test') {
            steps {
                withCredentials([string(credentialsId: 'REACT_ON_RAILS_PRO_LICENSE', variable: 'REACT_ON_RAILS_PRO_LICENSE')]) {
                    sh 'bundle exec rspec'
                }
            }
        }
    }
}
```

### Bitbucket Pipelines

**Step 1: Add License to Repository Variables**

1. Go to Repository settings
2. Navigate to: Pipelines → Repository variables
3. Name: `REACT_ON_RAILS_PRO_LICENSE`
4. Value: Your license token
5. ✅ Check "Secured" (recommended)

**Step 2: Use in Pipeline**

```yaml
# bitbucket-pipelines.yml
image: ruby:3.3

definitions:
  caches:
    bundler: vendor/bundle
    yarn: node_modules

pipelines:
  default:
    - step:
        name: Test
        caches:
          - bundler
          - yarn
        script:
          - apt-get update && apt-get install -y nodejs npm
          - npm install -g yarn
          - bundle install --path vendor/bundle
          - yarn install
          - bundle exec rspec
        # License is automatically available from repository variables
```

### Generic CI (Environment Variable)

For any CI system that supports environment variables:

**Step 1: Export Environment Variable**

```bash
export REACT_ON_RAILS_PRO_LICENSE="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**Step 2: Run Tests**

```bash
bundle install
yarn install
bundle exec rspec
```

The license will be automatically picked up from the environment variable.

## Docker-based CI

If using Docker in CI:

```dockerfile
# Dockerfile
FROM ruby:3.3-node

# ... other setup ...

# License will be passed at runtime via environment variable
# DO NOT COPY license file into image
ENV REACT_ON_RAILS_PRO_LICENSE=""

CMD ["bundle", "exec", "rspec"]
```

**Run with license:**

```bash
docker run -e REACT_ON_RAILS_PRO_LICENSE="$REACT_ON_RAILS_PRO_LICENSE" your-image
```

## Verification

License validation happens automatically when Rails starts.

✅ **If your CI tests run, your license is valid**
❌ **If license is invalid, Rails fails to start immediately**

**No verification step needed** - the application won't start without a valid license.

### Debug License Issues

If Rails fails to start in CI with license errors:

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
"
```

**Common issues:**
- License not set in CI environment variables
- License truncated when copying (should be 500+ characters)
- License expired (get a new FREE license at https://shakacode.com/react-on-rails-pro)

## Security Best Practices

1. ✅ **Always use secrets/encrypted variables** - Never commit licenses to code
2. ✅ **Mask license in logs** - Most CI systems support this
3. ✅ **Limit license access** - Only give to necessary jobs/pipelines
4. ✅ **Rotate regularly** - Get new FREE license every 3 months
5. ✅ **Use organization secrets** - Share across repositories when appropriate

## Troubleshooting

### Error: "No license found" in CI

**Checklist:**
- ✅ License added to CI environment variables
- ✅ Variable name is exactly `REACT_ON_RAILS_PRO_LICENSE`
- ✅ License value is complete (not truncated)
- ✅ License is accessible in the job/step

**Debug:**
```bash
# Check if variable exists (don't print full value!)
if [ -n "$REACT_ON_RAILS_PRO_LICENSE" ]; then
  echo "✅ License environment variable is set"
else
  echo "❌ License environment variable is NOT set"
fi
```

### Error: "License has expired"

**Solution:**
1. Get a new FREE 3-month license from [shakacode.com/react-on-rails-pro](https://shakacode.com/react-on-rails-pro)
2. Update the `REACT_ON_RAILS_PRO_LICENSE` variable in your CI settings
3. Done! No code changes needed

### Tests Pass Locally But Fail in CI

**Common causes:**
- License not set in CI environment
- Wrong variable name
- License truncated when copying

**Solution:**
Compare local and CI environments:

```bash
# Local
echo $REACT_ON_RAILS_PRO_LICENSE | wc -c  # Should be ~500+ characters

# In CI (add debug step)
echo $REACT_ON_RAILS_PRO_LICENSE | wc -c  # Should match local
```

## Multiple Environments

### Separate Licenses for Different Environments

If you want different licenses per environment:

```yaml
# GitHub Actions example
jobs:
  test:
    env:
      REACT_ON_RAILS_PRO_LICENSE: ${{ secrets.CI_LICENSE }}

  staging-deploy:
    env:
      REACT_ON_RAILS_PRO_LICENSE: ${{ secrets.STAGING_LICENSE }}

  production-deploy:
    env:
      REACT_ON_RAILS_PRO_LICENSE: ${{ secrets.PRODUCTION_LICENSE }}
```

### When to Use Different Licenses

- **CI/Test**: FREE evaluation license (for personal, educational, and evaluation purposes - renew every 3 months)
- **Staging**: Can use FREE evaluation license for non-production testing or paid license
- **Production**: Paid license (required - free licenses are NOT for production use)

## License Renewal

### Setting Up Renewal Reminders

FREE evaluation licenses (for personal, educational, and evaluation purposes only) expire every 3 months. Set a reminder:

1. **Calendar reminder**: 2 weeks before expiration
2. **CI notification**: Tests will fail when expired
3. **Email**: We'll send renewal reminders

### Renewal Process

1. Visit [shakacode.com/react-on-rails-pro](https://shakacode.com/react-on-rails-pro)
2. Log in with your email
3. Get new FREE license (or upgrade to paid)
4. Update `REACT_ON_RAILS_PRO_LICENSE` in CI settings
5. Done! No code changes needed

## Support

Need help with CI setup?

- **Documentation**: [LICENSE_SETUP.md](./LICENSE_SETUP.md)
- **Get FREE License**: [shakacode.com/react-on-rails-pro](https://shakacode.com/react-on-rails-pro)
- **Email Support**: support@shakacode.com
- **CI Issues**: Include your CI provider name and error message

## License Management

**Centralized License Management** (for teams):

1. **1Password/Vault**: Store license in team vault
2. **CI Variables**: Sync from secrets manager
3. **Documentation**: Keep renewal dates in team wiki
4. **Automation**: Script license updates across environments

```bash
# Example: Update license across multiple CI systems
./update-ci-license.sh "new-license-token"
```

---

**Quick Links:**
- 🎁 [Get FREE License](https://shakacode.com/react-on-rails-pro)
- 📚 [General Setup](./LICENSE_SETUP.md)
- 📧 [Support](mailto:support@shakacode.com)

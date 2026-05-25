# Installation

React on Rails Pro packages are published publicly on npmjs.org and RubyGems.org. A **paid license is required for production deployments only**.

**Friendly license model:** Try Pro freely in development, test, CI/CD, and staging. No token is required to evaluate. If no license is configured, Pro keeps running in unlicensed mode and logs license status instead of blocking your app.

When you are ready for production, visit [Pro pricing and sign up](https://pro.reactonrails.com/) or contact [justin@shakacode.com](mailto:justin@shakacode.com) for a license.

**Upgrading from GitHub Packages?** See the [Upgrading Guide](./updating.md) for migration instructions.

Check the [CHANGELOG](https://github.com/shakacode/react_on_rails/blob/main/CHANGELOG.md) to see what version you want.

## Version Format

For the commands below, choose versions 16.4.0 or greater from the CHANGELOG and replace placeholders like
`<gem_version>` and `<npm_version>`. Note that for pre-release versions:

- Gems use all periods: `16.4.0.beta.1`
- NPM packages use dashes: `16.4.0-beta.1`

# Generator Installation (Recommended)

The easiest way to set up React on Rails Pro is using the generator. This automates most of the manual steps described below.

## Fresh Installation

For new React on Rails apps, use the `--pro` flag:

```bash
# Add the Pro gem first (pin exact version)
bundle add react_on_rails_pro --version="<gem_version>" --strict

# The generator requires a clean git working tree
git add .
git commit -m "Prepare app for React on Rails Pro install"

# Run the generator with --pro
bundle exec rails generate react_on_rails:install --pro
```

This creates the Pro initializer, `renderer/node-renderer.js`, installs npm packages, and adds the Node Renderer to Procfile.dev.

## Upgrading an Existing App

For existing React on Rails apps, use the standalone Pro generator:

```bash
# Add the Pro gem to your Gemfile
bundle add react_on_rails_pro --version="<gem_version>" --strict

# Run the Pro generator
bundle exec rails generate react_on_rails:pro
```

The standalone generator adds Pro-specific files and modifies your existing webpack configs (`serverWebpackConfig.js` and `ServerClientOrBoth.js`) to enable Pro features like `libraryTarget: 'commonjs2'` and `target = 'node'`.

## After Running the Generator

Run a quick validation. For evaluation and non-production deployments, you can skip license setup.

```bash
bundle exec rails react_on_rails:doctor
bin/shakapacker
bin/dev
```

If port 3000 is already in use:

```bash
PORT=3001 bin/dev
```

For production deployments, set the license environment variable:

```bash
export REACT_ON_RAILS_PRO_LICENSE="your-license-token-here"
```

See [License Configuration](#license-configuration-production-only) below for other options and
[Pro pricing and sign up](https://pro.reactonrails.com/) when you need a production license.

## Adding React Server Components

RSC requires React on Rails Pro and React 19 with a compatible `react-on-rails-rsc` version. To add RSC support, use `--rsc` (fresh install) or the RSC generator (existing app):

```bash
# Fresh install with RSC
bundle exec rails generate react_on_rails:install --rsc

# Or add RSC to existing Pro app
bundle exec rails generate react_on_rails:rsc
```

The RSC generator creates `rscWebpackConfig.js`, adds `RSCWebpackPlugin` to both server and client webpack configs, configures `RSC_BUNDLE_ONLY` handling in `ServerClientOrBoth.js`, and sets up the RSC bundle watcher process. See [React Server Components](./react-server-components/tutorial.md) for more information.

---

# Manual Installation

The sections below describe manual installation steps. Use these if you need fine-grained control or want to understand what the generator creates.

# Ruby Gem Installation

## Prerequisites

Ensure your **Rails** app is using the **react_on_rails** gem, version 16.4.0 or higher.

## Install react_on_rails_pro Gem

Add the `react_on_rails_pro` gem to your **Gemfile**:

```ruby
gem "react_on_rails_pro", "= <gem_version>"
```

Then run:

```bash
bundle install
```

Or install directly:

```bash
gem install react_on_rails_pro --version "<version>"
```

## License Configuration (Production Only)

React on Rails Pro uses a friendly license model to simplify evaluation and development. A license token is optional for evaluation, local development, test environments, CI/CD pipelines, and staging/non-production deployments.

If no license is configured, the app continues running in unlicensed mode and logs license status instead of blocking startup. In production, that log message is a warning because a paid license is required; in non-production environments, it is informational.

**For production deployments**, set your license token as an environment variable:

```bash
export REACT_ON_RAILS_PRO_LICENSE="your-license-token-here"
```

⚠️ **Security Warning**: Never commit your license token to version control. For production, use environment variables or secure secret management systems (Rails credentials, Heroku config vars, AWS Secrets Manager, etc.).

### License Validation Lifecycle

React on Rails Pro validates licenses offline with the public key embedded in the gem and node renderer package. There
is no network call to ShakaCode during validation.

License validation happens in these places:

- Rails checks the license after application initialization and logs the result.
- The standalone node renderer checks the license when the renderer master process starts and logs the result.
- The browser receives `railsContext.rorPro` as a Pro-installed signal only; it does not validate the license.

A missing, expired, or invalid license does not prevent Rails or the node renderer from starting. In production, license
issues are logged as warnings, and Rails includes an HTML attribution comment indicating the license state.

### Verify License Compliance

Use the built-in task as a deploy or release gate:

```bash
RAILS_ENV=production bundle exec rake react_on_rails_pro:verify_license
```

For CI/CD or scripting, request JSON output:

```bash
RAILS_ENV=production FORMAT=json bundle exec rake react_on_rails_pro:verify_license
```

The task exits with a non-zero status when the license is missing, invalid, or expired. For valid but expiring
licenses, it exits 0 but reports `renewal_required: true` in JSON output when the license is expiring within 30 days.
When parsing JSON output, check `status` first: `renewal_required` is also `true` for already-expired licenses, which
exit non-zero. The built-in 30-day threshold is fixed; use the app-owned rake task below if you want a non-zero exit for
expiring-soon licenses or a custom warning threshold.

The full JSON output includes license metadata such as organization, plan, and expiration. Treat CI logs, step summaries,
and uploaded artifacts as internal if they include raw task output. For example, an expired license can include these
fields among the full response:

```json
{
  "status": "expired",
  "days_remaining": -2,
  "renewal_required": true
}
```

JSON parsers should branch on `status` before treating `renewal_required` as an expiring-soon signal:

```ruby
require "json"

# `output` is stdout captured from:
# RAILS_ENV=production FORMAT=json bundle exec rake react_on_rails_pro:verify_license
license_info = JSON.parse(output)
status = license_info["status"]
abort "Unexpected license info response: #{license_info.inspect}" unless status

case status
when "expired", "invalid", "missing"
  abort "React on Rails Pro license is #{status}."
when "valid"
  if license_info["renewal_required"]
    warn "React on Rails Pro license renewal is required soon."
  else
    puts "React on Rails Pro license is valid."
  end
else
  abort "Unexpected React on Rails Pro license status: #{status}."
end
```

#### Blocking CI Example

Use a blocking check inside your deployment workflow when an invalid license should stop a production deploy. The
reusable workflow below can be called before the deploy job and run manually when you need to verify a key outside a
deployment:

```yaml
# .github/workflows/react-on-rails-pro-license.yml
name: React on Rails Pro License

on:
  workflow_call:
    secrets:
      REACT_ON_RAILS_PRO_LICENSE:
        required: true
  workflow_dispatch:

permissions:
  contents: read

jobs:
  advisory-license-check:
    runs-on: ubuntu-latest
    env:
      RAILS_ENV: production
      REACT_ON_RAILS_PRO_LICENSE: ${{ secrets.REACT_ON_RAILS_PRO_LICENSE }}
    steps:
      - uses: actions/checkout@v4

      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true

      # Add database, credentials, Node/pnpm, and other app-specific setup required to boot Rails in production.
      - name: Verify React on Rails Pro license
        run: bundle exec rake react_on_rails_pro:verify_license
```

Call the reusable workflow before your deploy job and pass repository secrets from the caller:

```yaml
jobs:
  check-license:
    uses: ./.github/workflows/react-on-rails-pro-license.yml
    secrets: inherit

  deploy:
    needs: check-license
    # ...
```

The task depends on the Rails environment. If your production boot requires credentials or services such as
`RAILS_MASTER_KEY`, `DATABASE_URL`, database preparation, or Node package setup, add those to the workflow before
running the task.

#### Advisory CI Example

Use an advisory CI check when you want visibility without failing the workflow:

```yaml
# .github/workflows/react-on-rails-pro-license-advisory.yml
name: React on Rails Pro License Advisory

on:
  schedule:
    - cron: '0 15 * * 1' # Every Monday at 15:00 UTC
  workflow_dispatch:

permissions:
  contents: read

jobs:
  verify-license:
    runs-on: ubuntu-latest
    env:
      RAILS_ENV: production
      REACT_ON_RAILS_PRO_LICENSE: ${{ secrets.REACT_ON_RAILS_PRO_LICENSE }}
    steps:
      - uses: actions/checkout@v4

      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true

      # Add database, credentials, Node/pnpm, and other app-specific setup required to boot Rails in production.
      - name: Check React on Rails Pro license
        id: license-check
        continue-on-error: true
        run: >-
          bundle exec rake react_on_rails_pro:verify_license >
          "$RUNNER_TEMP/react_on_rails_pro_license.log" 2>&1

      - name: Summarize React on Rails Pro license
        env:
          LICENSE_CHECK_OUTCOME: ${{ steps.license-check.outcome }}
        run: |
          {
            echo "## React on Rails Pro license"
            echo
            if [ "$LICENSE_CHECK_OUTCOME" = "success" ]; then
              echo "License validation passed."
            else
              echo "License validation did not pass. Run the check locally or inspect a redacted log for details."
            fi
          } >> "$GITHUB_STEP_SUMMARY"

          if [ "$LICENSE_CHECK_OUTCOME" != "success" ]; then
            echo "::warning title=React on Rails Pro license::License validation did not pass. See job summary."
          fi
```

Use either CI example in workflows where repository secrets are available, such as trusted branch pushes, scheduled jobs,
manual runs, or deployment gates. To block deployment, call the blocking check from the deploy pipeline before the deploy
job. A standalone `push` workflow is only a post-merge signal. Pull requests from public forks usually cannot access
repository secrets, so these checks would report a missing token there.

The advisory workflow redirects raw task output to `$RUNNER_TEMP` and writes only pass/fail status to the step summary so
organization, plan, and expiration metadata are not copied into the summary. Remove the redirect or upload a redacted
artifact only after verifying that the task output is acceptable for everyone who can read your repository's Actions
logs. If the license secret is absent, the advisory workflow emits the warning but still exits successfully by design.

### Monitor License Expiration

If your organization wants an app-owned scheduled check with a custom warning threshold, add a wrapper task. The built-in
`react_on_rails_pro:verify_license` task and its exit codes are the stable scripting interface. This wrapper deliberately
calls `ReactOnRailsPro::Utils.license_info`, a lower-level internal helper that is not formally stable, so it can apply a
custom threshold in Ruby. Keep this task app-owned, cover it with a smoke test, and review it when upgrading
`react_on_rails_pro` because the helper name and returned metadata shape can evolve.

The wrapper reads the same license information that the built-in verification task formats and treats the built-in
30-day renewal window as the default. Known status values are `:valid`, `:expired`, `:missing`, and `:invalid`; any other
value should fail closed in the catch-all branch:

```ruby
# frozen_string_literal: true

# lib/tasks/react_on_rails_pro_license.rake
namespace :licenses do
  desc "Fail if the React on Rails Pro license is invalid, expired, or expiring soon"
  task check_react_on_rails_pro: :environment do
    threshold_days = begin
      Integer(ENV.fetch("DAYS", "30"))
    rescue ArgumentError
      abort "DAYS must be an integer number of days."
    end
    abort "DAYS must be a positive integer number of days." unless threshold_days.positive?

    info = ReactOnRailsPro::Utils.license_info
    status = info[:status]
    expiration = info[:expiration]
    expiration_time = expiration.respond_to?(:to_time) ? expiration.to_time : nil
    days_remaining = expiration_time && ((expiration_time - Time.current) / 1.day).ceil
    status_label = status.to_s.tr("_", " ")

    if status == :expired
      abort "React on Rails Pro license is expired. Renew and update REACT_ON_RAILS_PRO_LICENSE."
    elsif status == :missing
      abort "React on Rails Pro license is missing. Set REACT_ON_RAILS_PRO_LICENSE."
    elsif status != :valid
      abort "React on Rails Pro license status is #{status_label}. Update REACT_ON_RAILS_PRO_LICENSE."
    end

    # Guard against a future gem version returning :valid with a past expiration.
    if days_remaining && days_remaining <= 0
      abort(
        "React on Rails Pro license is expired (expiration date is in the past). " \
        "Renew and update REACT_ON_RAILS_PRO_LICENSE."
      )
    end

    if days_remaining && days_remaining <= threshold_days
      abort(
        "React on Rails Pro license expires in #{days_remaining} days. " \
        "Renew and update REACT_ON_RAILS_PRO_LICENSE."
      )
    end

    message = "React on Rails Pro license is valid"
    message += " (#{days_remaining} days remaining)" if days_remaining
    puts message
  end
end
```

Run it from your scheduler or CI:

```bash
RAILS_ENV=production DAYS=30 bundle exec rake licenses:check_react_on_rails_pro
```

For complete license setup instructions, see [LICENSE_SETUP.md](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails_pro/LICENSE_SETUP.md).

## Rails Configuration

You don't need to create an initializer if you are satisfied with the defaults as described in [Configuration](../oss/configuration/configuration-pro.md).

For basic setup:

```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  # Your configuration here
  # See docs/oss/configuration/configuration-pro.md for all options
end
```

# Client Package Installation

All React on Rails Pro users need to install the `react-on-rails-pro` npm package for client-side React integration.

## Install react-on-rails-pro

### Using npm:

```bash
npm install react-on-rails-pro@<npm_version> --save-exact
```

### Using yarn:

```bash
yarn add react-on-rails-pro@<npm_version> --exact
```

### Using pnpm:

```bash
pnpm add react-on-rails-pro@<npm_version> --save-exact
```

## Usage

**Important:** Import from `react-on-rails-pro`, not `react-on-rails`. The Pro package re-exports everything from the core package plus Pro-exclusive features.

```javascript
// Correct - use react-on-rails-pro
import ReactOnRails from 'react-on-rails-pro';

// Register components
ReactOnRails.register({ MyComponent });
```

Pro-exclusive imports:

```javascript
// React Server Components
import RSCRoute from 'react-on-rails-pro/RSCRoute';
import registerServerComponent from 'react-on-rails-pro/registerServerComponent/client';

// Async component loading
import wrapServerComponentRenderer from 'react-on-rails-pro/wrapServerComponentRenderer/client';
```

See the [React Server Components tutorial](./react-server-components/tutorial.md) for detailed usage.

# Node Renderer Installation

**Note:** You only need to install the Node Renderer if you are using the standalone node renderer (`NodeRenderer`). If you're using `ExecJS` (the default), skip this section.

## Install react-on-rails-pro-node-renderer

### Using npm:

```bash
npm install react-on-rails-pro-node-renderer@<npm_version> --save-exact
```

### Using yarn:

```bash
yarn add react-on-rails-pro-node-renderer@<npm_version> --exact
```

### Add to package.json:

```json
{
  "dependencies": {
    "react-on-rails-pro-node-renderer": "<npm_version>"
  }
}
```

## Node Renderer Setup

Create a JavaScript file to configure and launch the node renderer at `renderer/node-renderer.js`:

```js
const path = require('path');
const { reactOnRailsProNodeRenderer } = require('react-on-rails-pro-node-renderer');

const env = process.env;

const config = {
  serverBundleCachePath: path.resolve(__dirname, '../.node-renderer-bundles'),

  // Listen at RENDERER_PORT env value or default port 3800
  logLevel: env.RENDERER_LOG_LEVEL || 'debug', // show all logs

  // Password for Rails <-> Node renderer communication
  // See value in /config/initializers/react_on_rails_pro.rb
  password: env.RENDERER_PASSWORD || 'changeme',

  port: env.RENDERER_PORT || 3800,

  // supportModules should be set to true to allow the server-bundle code to
  // see require, exports, etc. (`false` is like the ExecJS behavior)
  // This option is required to equal `true` in order to use loadable components
  supportModules: true,

  // workersCount defaults to the number of CPUs minus 1
  workersCount: Number(env.NODE_RENDERER_CONCURRENCY || 3),

  // Optional: Automatic worker restarting (for memory leak mitigation)
  // allWorkersRestartInterval: 15, // minutes between restarting all workers
  // delayBetweenIndividualWorkerRestarts: 2, // minutes between each worker restart
  // gracefulWorkerRestartTimeout: undefined, // timeout for graceful worker restart; forces restart if worker stuck
};

// Renderer detects a total number of CPUs on virtual hostings like Heroku
// or CircleCI instead of CPUs number allocated for current container. This
// results in spawning many workers while only 1-2 of them really needed.
if (env.CI) {
  config.workersCount = 2;
}

reactOnRailsProNodeRenderer(config);
```

Add a script to your `package.json`:

```json
{
  "scripts": {
    "node-renderer": "node renderer/node-renderer.js"
  }
}
```

Start the renderer:

```bash
npm run node-renderer
```

## Rails Configuration for Node Renderer

Configure Rails to use the remote node renderer:

```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.server_renderer = "NodeRenderer"

  # Configure renderer connection
  config.renderer_url = ENV["REACT_RENDERER_URL"] || "http://localhost:3800"
  # Optional: omit this line to let Rails auto-read ENV["RENDERER_PASSWORD"].
  # config.renderer_password = ENV.fetch("RENDERER_PASSWORD")

  # Enable prerender caching (recommended)
  config.prerender_caching = true
end
```

### Configuration Options

See [Rails Configuration Options](../oss/configuration/configuration-pro.md) for all available settings.

Pay attention to:

- `config.server_renderer = "NodeRenderer"` - Required to use node renderer
- `config.renderer_url` - URL where your node renderer is running
- `config.renderer_password` - Shared secret for authentication
- `config.prerender_caching` - Enable caching (recommended)

## Webpack Configuration

Set your server bundle webpack configuration to use a target of `node` per the [Webpack docs](https://webpack.js.org/concepts/targets/#usage).

## Additional Documentation

- [Node Renderer Basics](../oss/building-features/node-renderer/basics.md)
- [Node Renderer JavaScript Configuration](../oss/building-features/node-renderer/js-configuration.md)
- [Rails Configuration Options](../oss/configuration/configuration-pro.md)
- [Error Reporting and Tracing](../oss/building-features/node-renderer/error-reporting-and-tracing.md)

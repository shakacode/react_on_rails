# Installation

React on Rails Pro packages are published publicly on npmjs.org and RubyGems.org. A **paid license is required for production deployments only**.

**ShakaCode Trust-Based Commercial Licensing:** Try Pro freely in development, test, CI/CD, and staging. No token is required to evaluate. If no license is configured, Pro keeps running in unlicensed mode and logs license status instead of blocking your app.

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

For production deployments, configure the license token. This environment-variable form remains supported:

```bash
export REACT_ON_RAILS_PRO_LICENSE="your-license-token-here"
```

See [License Configuration](#license-configuration-production-only) below for other options and
[Pro pricing and sign up](https://pro.reactonrails.com/) when you need a production license.

## Adding React Server Components

> **Using React 18, or not using RSC?** Skip this section and do not install
> `react-on-rails-rsc` — it is an **optional** peer dependency needed only when RSC
> support is enabled. React on Rails Pro works with React 18; only React Server
> Components require React 19, and RSC stays disabled unless you set
> `config.enable_rsc_support = true` (the default is `false`).

RSC requires React on Rails Pro and React 19 with a compatible `react-on-rails-rsc` version. To add RSC support, use `--rsc` (fresh install) or the RSC generator (existing app):

```bash
# Fresh install with RSC
bundle exec rails generate react_on_rails:install --rsc

# Or add RSC to existing Pro app
bundle exec rails generate react_on_rails:rsc
```

The RSC generator creates `rscWebpackConfig.js` in the active bundler config directory (`config/webpack/` or `config/rspack/`), adds the RSC bundler plugin to both server and client configs, configures `RSC_BUNDLE_ONLY` handling in `ServerClientOrBoth.js`, and sets up the RSC bundle watcher process. See [React Server Components](./react-server-components/tutorial.md) for more information.

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

React on Rails Pro uses **ShakaCode Trust-Based Commercial Licensing** to simplify evaluation and development. A license token is optional for evaluation, local development, test environments, CI/CD pipelines, and staging/non-production deployments.

If no license is configured, the app continues running in unlicensed mode and logs license status instead of blocking startup. In production, that log message is a warning because a paid license is required; in non-production environments, it is informational.

**For production deployments**, provide your license token to Rails through application configuration or the
environment. Explicit nonblank configuration takes precedence over the environment variable:

```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.license_token = Rails.application.credentials.dig(:react_on_rails_pro, :license_token)
end
```

Alternatively, set the environment variable:

```bash
export REACT_ON_RAILS_PRO_LICENSE="your-license-token-here"
```

Blank configured values fall back to `REACT_ON_RAILS_PRO_LICENSE`. Never commit your license token to version control.
Use Rails credentials, environment variables, or another secure secret manager.

If you run the standalone Node renderer, configure that process separately because Rails configuration does not cross
the process boundary:

```js
reactOnRailsProNodeRenderer({
  // Application-defined secret-manager integration:
  licenseToken: loadLicenseTokenFromYourSecretManager(),
});
```

The Node renderer also falls back to `REACT_ON_RAILS_PRO_LICENSE` when `licenseToken` is blank or omitted. Its
sanitized configuration logs never include the token value.

### License Validation Lifecycle

React on Rails Pro currently validates licenses offline with the public key embedded in the gem and node renderer
package. There is no network call to ShakaCode during validation.

License validation happens in these places:

- Rails checks the license after application initialization and logs the result.
- The standalone node renderer checks the license when the renderer starts and logs the result, including
  single-process mode (`workersCount: 0`).
- The browser receives `railsContext.rorPro` as a Pro-installed signal only; it does not validate the license.

A missing, expired, or invalid license does not prevent Rails or the node renderer from starting. In production, license
issues are logged as warnings, and Rails includes an HTML attribution comment indicating the license state.

### Verify License Compliance

Pro validates licenses **offline** at boot, and a missing, invalid, or expired license never crashes the app — Rails and the node renderer simply log the issue. The recommended way to catch license problems before they reach production is the built-in rake task, which exits non-zero when the license is missing, invalid, or expired:

```bash
RAILS_ENV=production bundle exec rake react_on_rails_pro:verify_license
```

Add it to your deploy pipeline as a one-line gate:

```yaml
- name: Verify React on Rails Pro license
  env:
    REACT_ON_RAILS_PRO_LICENSE: ${{ secrets.REACT_ON_RAILS_PRO_LICENSE }}
    RAILS_ENV: production
  run: bundle exec rake react_on_rails_pro:verify_license
```

A valid-but-expiring license (within 30 days) still exits 0; the task logs a renewal-required warning. To fail closed on expiring-soon licenses, send renewal emails, run advisory (non-blocking) scheduled checks, or parse the JSON output, see [License CI Integration](./license-ci-integration.md).

The rake task loads the Rails environment, so it honors `config.license_token` and Rails credentials. The workflow
example uses the environment variable because it is the simplest portable CI setup.

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
  password: env.RENDERER_PASSWORD,

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

> [!IMPORTANT]
> `config.prerender_caching` is safe for ordinary prerendered and streamed renders, but React on Rails Pro skips that
> cache for `stream_react_component_with_async_props` and other async-props renders. Async props can include
> per-request data that is not part of the prerender cache key. Keep prerender caching enabled as a default performance
> win, but use explicit fragment cache keys for async-props pages only when the rendered output is safe to share across
> requests.

### Configuration Options

See [Rails Configuration Options](../oss/configuration/configuration-pro.md) for all available settings.

Pay attention to:

- `config.server_renderer = "NodeRenderer"` - Required to use node renderer
- `config.renderer_url` - URL where your node renderer is running
- `config.renderer_password` - Shared secret for authentication
- `config.prerender_caching` - Enable prerender caching for supported SSR/streaming renders; async-props renders skip
  this cache

## Webpack Configuration

Set your server bundle webpack configuration to use a target of `node` per the [Webpack docs](https://webpack.js.org/concepts/targets/#usage).

## Additional Documentation

- [Node Renderer Basics](../oss/building-features/node-renderer/basics.md)
- [Node Renderer JavaScript Configuration](../oss/building-features/node-renderer/js-configuration.md)
- [Rails Configuration Options](../oss/configuration/configuration-pro.md)
- [Error Reporting and Tracing](../oss/building-features/node-renderer/error-reporting-and-tracing.md)

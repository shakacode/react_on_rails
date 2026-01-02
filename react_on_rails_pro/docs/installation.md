# Installation

React on Rails Pro packages are published publicly on npmjs.org and RubyGems.org. Installation requires a valid **license token** for runtime validation. Contact [justin@shakacode.com](mailto:justin@shakacode.com) to purchase a license.

**Upgrading from GitHub Packages?** See the [Upgrading Guide](./updating.md) for migration instructions.

Check the [CHANGELOG](https://github.com/shakacode/react_on_rails/blob/master/CHANGELOG.md) to see what version you want.

## Version Format

For the below docs, find the desired `<version>` in the CHANGELOG. Note that for pre-release versions:

- Gems use all periods: `16.2.0.beta.1`
- NPM packages use dashes: `16.2.0-beta.1`

# Ruby Gem Installation

## Prerequisites

Ensure your **Rails** app is using the **react_on_rails** gem, version 16.0.0 or higher.

## Install react_on_rails_pro Gem

Add the `react_on_rails_pro` gem to your **Gemfile**:

```ruby
gem "react_on_rails_pro", "~> 16.2"
```

Then run:

```bash
bundle install
```

Or install directly:

```bash
gem install react_on_rails_pro --version "<version>"
```

## License Configuration

Set your license token as an environment variable:

```bash
export REACT_ON_RAILS_PRO_LICENSE="your-license-token-here"
```

> **Paid subscribers:** Use `REACT_ON_RAILS_PRO_LICENSE_KEY` instead for automatic license renewal. See [LICENSE_SETUP.md](../LICENSE_SETUP.md#automatic-license-renewal-paid-subscriptions) for details.

Or configure it in your Rails initializer (not recommended for production):

```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.license_token = ENV["REACT_ON_RAILS_PRO_LICENSE"]
end
```

⚠️ **Security Warning**: Never commit your license token to version control. Always use environment variables or secure secret management systems (like Rails credentials, Heroku config vars, AWS Secrets Manager, etc.).

## Rails Configuration

You don't need to create an initializer if you are satisfied with the defaults as described in [Configuration](./configuration.md).

For basic setup:

```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  # Your configuration here
  # See docs/configuration.md for all options
end
```

# Client Package Installation

All React on Rails Pro users need to install the `react-on-rails-pro` npm package for client-side React integration.

## Install react-on-rails-pro

### Using npm:

```bash
npm install react-on-rails-pro
```

### Using yarn:

```bash
yarn add react-on-rails-pro
```

### Using pnpm:

```bash
pnpm add react-on-rails-pro
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
import { RSCRoute } from 'react-on-rails-pro/RSCRoute';
import registerServerComponent from 'react-on-rails-pro/registerServerComponent/client';

// Async component loading
import { wrapServerComponentRenderer } from 'react-on-rails-pro/wrapServerComponentRenderer/client';
```

See the [React Server Components tutorial](./react-server-components/tutorial.md) for detailed usage.

# Node Renderer Installation

**Note:** You only need to install the Node Renderer if you are using the standalone node renderer (`NodeRenderer`). If you're using `ExecJS` (the default), skip this section.

## Install react-on-rails-pro-node-renderer

### Using npm:

```bash
npm install react-on-rails-pro-node-renderer
```

### Using yarn:

```bash
yarn add react-on-rails-pro-node-renderer
```

### Add to package.json:

```json
{
  "dependencies": {
    "react-on-rails-pro-node-renderer": "^16.2.0"
  }
}
```

## Node Renderer Setup

Create a JavaScript file to configure and launch the node renderer, for example `react-on-rails-pro-node-renderer.js`:

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
    "node-renderer": "node ./react-on-rails-pro-node-renderer.js"
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
  config.renderer_password = ENV["RENDERER_PASSWORD"] || "changeme"

  # Enable prerender caching (recommended)
  config.prerender_caching = true
end
```

### Configuration Options

See [Rails Configuration Options](./configuration.md) for all available settings.

Pay attention to:

- `config.server_renderer = "NodeRenderer"` - Required to use node renderer
- `config.renderer_url` - URL where your node renderer is running
- `config.renderer_password` - Shared secret for authentication
- `config.prerender_caching` - Enable caching (recommended)

## Webpack Configuration

Set your server bundle webpack configuration to use a target of `node` per the [Webpack docs](https://webpack.js.org/concepts/targets/#usage).

## Additional Documentation

- [Node Renderer Basics](./node-renderer/basics.md)
- [Node Renderer JavaScript Configuration](./node-renderer/js-configuration.md)
- [Rails Configuration Options](./configuration.md)
- [Error Reporting and Tracing](./node-renderer/error-reporting-and-tracing.md)

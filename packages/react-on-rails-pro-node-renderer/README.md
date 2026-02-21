# react-on-rails-pro-node-renderer

A high-performance standalone Node.js server for server-side rendering (SSR) of React components in [React on Rails Pro](https://github.com/shakacode/react_on_rails) applications. Built on [Fastify](https://fastify.dev/) with worker pool management.

## Installation

```bash
npm install react-on-rails-pro-node-renderer
# or
yarn add react-on-rails-pro-node-renderer
# or
pnpm add react-on-rails-pro-node-renderer
```

**Prerequisites:** This package is used with the `react_on_rails_pro` Ruby gem and the `react-on-rails-pro` npm package. See the [full installation guide](https://www.shakacode.com/react-on-rails-pro/docs/installation/).

## Quick Start

### 1. Create the Node Renderer entry file

Create `node-renderer.js` in your project root:

```js
const path = require('path');
const { reactOnRailsProNodeRenderer } = require('react-on-rails-pro-node-renderer');

reactOnRailsProNodeRenderer({
  // Directory where the renderer caches uploaded server bundles
  serverBundleCachePath: path.resolve(__dirname, '.node-renderer-bundles'),

  // Port the renderer listens on (must match Rails config)
  port: Number(process.env.RENDERER_PORT) || 3800,

  // Enable Node.js globals in the rendering VM context
  supportModules: true,

  // Log level: 'fatal' | 'error' | 'warn' | 'info' | 'debug' | 'trace' | 'silent'
  logLevel: process.env.RENDERER_LOG_LEVEL || 'info',

  // Password for Rails <-> Node renderer authentication (must match Rails config)
  password: process.env.RENDERER_PASSWORD,

  // Number of worker processes (defaults to CPU count - 1)
  workersCount: Number(process.env.RENDERER_WORKERS_COUNT) || 3,
});
```

### 2. Configure Rails

```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.server_renderer = "NodeRenderer"
  config.renderer_url = ENV["RENDERER_URL"] || "http://localhost:3800"
  config.renderer_password = ENV["RENDERER_PASSWORD"]
end
```

### 3. Configure Webpack

Set your server bundle webpack configuration to target Node.js:

```js
// In serverWebpackConfig.js
serverWebpackConfig.target = 'node';

// In output config
libraryTarget: 'commonjs2',
```

### 4. Start the renderer

```bash
node node-renderer.js
```

Or add to your `Procfile.dev`:

```
node-renderer: node node-renderer.js
```

## Generator (Recommended)

The `react_on_rails:install --pro` generator automates all of the above setup:

```bash
bundle add react_on_rails_pro
rails generate react_on_rails:install --pro
```

## Configuration Options

All options can be set via the config object or environment variables. Config object values take precedence over environment variables.

| Option | Env Variable | Default | Description |
|--------|-------------|---------|-------------|
| `port` | `RENDERER_PORT` | `3800` | Port the renderer listens on |
| `logLevel` | `RENDERER_LOG_LEVEL` | `'info'` | Log level (`fatal`, `error`, `warn`, `info`, `debug`, `trace`, `silent`) |
| `logHttpLevel` | `RENDERER_LOG_HTTP_LEVEL` | `'error'` | HTTP server log level |
| `serverBundleCachePath` | `RENDERER_SERVER_BUNDLE_CACHE_PATH` | Auto-detected or `/tmp/...` | Directory for cached server bundles |
| `supportModules` | `RENDERER_SUPPORT_MODULES` | `false` | Enable Node.js globals in VM context (`Buffer`, `process`, `setTimeout`, etc.) |
| `workersCount` | `RENDERER_WORKERS_COUNT` | CPU count - 1 | Number of worker processes |
| `password` | `RENDERER_PASSWORD` | (none) | Shared secret for Rails authentication |
| `stubTimers` | `RENDERER_STUB_TIMERS` | `true` | Stub timer functions during SSR |
| `allWorkersRestartInterval` | `RENDERER_ALL_WORKERS_RESTART_INTERVAL` | (disabled) | Minutes between restarting all workers |
| `delayBetweenIndividualWorkerRestarts` | `RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS` | (disabled) | Minutes between each worker restart |
| `fastifyServerOptions` | — | `{}` | Additional [Fastify server options](https://fastify.dev/docs/latest/Reference/Server/#factory) |

## Advanced: Custom Fastify Configuration

For custom routes (e.g., health checks) or plugins, import the master/worker modules directly:

```js
import masterRun from 'react-on-rails-pro-node-renderer/master';
import run, { configureFastify } from 'react-on-rails-pro-node-renderer/worker';
import cluster from 'cluster';

const config = { /* your config */ };

configureFastify((app) => {
  app.get('/health', (request, reply) => {
    reply.send({ status: 'ok' });
  });
});

if (cluster.isPrimary) {
  masterRun(config);
} else {
  run(config);
}
```

## Error Reporting

Integrate with Sentry or Honeybadger:

```js
import { addNotifier, setupTracing } from 'react-on-rails-pro-node-renderer/integrations/api';

addNotifier((error) => {
  Sentry.captureException(error);
});
```

See [Error Reporting and Tracing docs](https://www.shakacode.com/react-on-rails-pro/docs/node-renderer/error-reporting-and-tracing/).

## Documentation

- [Node Renderer Basics](https://www.shakacode.com/react-on-rails-pro/docs/node-renderer/basics/)
- [JavaScript Configuration](https://www.shakacode.com/react-on-rails-pro/docs/node-renderer/js-configuration/)
- [Rails Configuration](https://www.shakacode.com/react-on-rails-pro/docs/configuration/)
- [Debugging](https://www.shakacode.com/react-on-rails-pro/docs/node-renderer/debugging/)
- [Troubleshooting](https://www.shakacode.com/react-on-rails-pro/docs/node-renderer/troubleshooting/)

## Package Relationships

```
Rails App
├── react_on_rails gem (base Rails integration)
├── react_on_rails_pro gem (Pro server rendering features)
├── react-on-rails-pro npm (client JS - replaces react-on-rails)
└── react-on-rails-pro-node-renderer npm (this package - standalone SSR server)
```

**Important:** When using `react_on_rails_pro` gem, you must use `react-on-rails-pro` npm package (not `react-on-rails`).

## License

Commercial software. No license required for evaluation, development, testing, or CI/CD. A paid license is required for production deployments. Contact [justin@shakacode.com](mailto:justin@shakacode.com) for licensing.

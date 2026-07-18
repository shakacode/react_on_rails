# Node Renderer Basics

> **Pro Feature** — Available with [React on Rails Pro](../../../pro/react-on-rails-pro.md).
> Free or very low cost for startups and small companies. [Upgrade or licensing details →](../../../pro/upgrading-to-pro.md#try-pro-risk-free)

## Requirements

- You must use **React on Rails Pro** v16.4.0 or higher.

## Install the Gem and the Node Module

See [Installation](../../../pro/installation.md).

## Memory Management

The Node Renderer reuses V8 VM contexts across requests for performance. This means **module-level state in your server bundle persists across all SSR requests**. Any unbounded caches, `_.memoize` calls, or growing data structures at module scope will leak memory until the worker restarts.

**Essential for production:**

- Set `NODE_OPTIONS=--max-old-space-size=<MB>` to prevent V8 from deferring garbage collection
- Enable worker rolling restarts via `allWorkersRestartInterval` and `delayBetweenIndividualWorkerRestarts`
- Audit your server bundle for module-level mutable state

See the [Memory Leaks guide](../../../pro/js-memory-leaks.md) for common leak patterns and how to fix them.

## Setup Node Renderer Server

**node-renderer** is a standalone Node application to serve React SSR requests from a **Rails** client. You don't need any **Ruby** code to setup and launch it. You can configure with the command line or with a launch file.

> **Generator shortcut:** Running `rails generate react_on_rails:install --pro` (or `rails generate react_on_rails:pro` for existing apps) automatically creates `renderer/node-renderer.js`, adds the Node Renderer process to `Procfile.dev`, and installs the required npm packages. See [Installation](../../../pro/installation.md) for details. The manual setup below is for apps that need custom configuration.

## Simple Command Line for node-renderer

1. ENV values for the default config are (See [JS Configuration](./js-configuration.md) for more details):
   - `RENDERER_PORT`
   - `RENDERER_HOST`
   - `RENDERER_LOG_LEVEL`
   - `RENDERER_SERVER_BUNDLE_CACHE_PATH`
   - `RENDERER_BUNDLE_PATH` (legacy alias)
   - `RENDERER_WORKERS_COUNT`
   - `RENDERER_PASSWORD`
   - `RENDERER_ALL_WORKERS_RESTART_INTERVAL`
   - `RENDERER_DELAY_BETWEEN_INDIVIDUAL_WORKER_RESTARTS`
   - `RENDERER_SUPPORT_MODULES`
2. Configure ENV values and run your launch script. For example:
   ```bash
   RENDERER_SERVER_BUNDLE_CACHE_PATH=/app/.node-renderer-bundles node renderer/node-renderer.js
   ```
   Or via a script you define in package.json, e.g. `pnpm run node-renderer` (see [JavaScript Configuration File](#javascript-configuration-file) below).
3. You can use a command line argument of `-p SOME_PORT` to override any ENV value for the PORT.

## JavaScript Configuration File

For the most control over the setup, create a JavaScript file to start the NodeRenderer.

1. Create some project directory, let's say `renderer-app`:
   ```sh
   mkdir renderer-app
   cd renderer-app
   ```
2. Make sure you have **Node.js 20+** and a JavaScript package manager such as **npm**, **pnpm**, **Yarn**, or **bun**. The default setup bundles Fastify 5, which requires Node.js 20+ — on Node.js 18 the renderer exits at startup unless you pin Fastify 4 via your package manager's dependency-override mechanism (npm [`overrides`](https://docs.npmjs.com/cli/v11/configuring-npm/package-json#overrides), Yarn/Bun [`resolutions`](https://yarnpkg.com/configuration/manifest#resolutions), or pnpm [`pnpm.overrides`](https://pnpm.io/package_json#pnpmoverrides)). (The package's `engines.node` floor is `>=18.19.0`, which applies only to that Fastify 4 path.)
3. Initialize a Node application and install the `react-on-rails-pro-node-renderer` package.
   ```sh
   npm init -y
   npm install react-on-rails-pro-node-renderer
   # or: pnpm add react-on-rails-pro-node-renderer
   # or: yarn add react-on-rails-pro-node-renderer
   # or: bun add react-on-rails-pro-node-renderer
   ```
4. Configure a JavaScript file that will launch the rendering server per the docs in [Node Renderer JavaScript Configuration](./js-configuration.md). For example, create a file `renderer/node-renderer.js`. Here is a simple example that uses all the defaults except for serverBundleCachePath:

   ```javascript
   import path from 'path';
   import reactOnRailsProNodeRenderer from 'react-on-rails-pro-node-renderer';

   const config = {
     serverBundleCachePath: path.resolve(__dirname, '../.node-renderer-bundles'),
   };

   reactOnRailsProNodeRenderer(config);
   ```

5. Now you can launch your renderer server with `node renderer/node-renderer.js`. You will probably add a script to your `package.json`.
6. You can use a command line argument of `-p SOME_PORT` to override any configured or ENV value for the port.

## Setup Rails Application

Create `config/initializers/react_on_rails_pro.rb` and configure the **renderer server**. See configuration values in [Configuration](../../configuration/configuration-pro.md). Pay attention to:

1. Set `config.server_renderer = "NodeRenderer"`
2. Decide whether to enable `config.prerender_caching = true`. The default is `false`; turn it on only if you want Rails cache-backed SSR result caching and your cache is configured for the additional load.
3. Configure values beginning with `renderer_`
4. Use ENV values for values like `renderer_url` so that your deployed server is properly configured. If the ENV value is unset, the default for the renderer_url is `localhost:3800`.
5. Here's a tiny example using mostly defaults:

```ruby
ReactOnRailsPro.configure do |config|
 config.server_renderer = "NodeRenderer"

 # when this ENV value is not defined, the local server at localhost:3800 is used
 config.renderer_url = ENV["REACT_RENDERER_URL"]
end
```

## Network Security

The Node Renderer executes JavaScript sent to it by the Rails application using Node.js `vm.runInContext()`. This makes it, by design, a **remote code execution service** — any client that can reach the HTTP port can execute arbitrary JavaScript on the host machine.

Node.js [`vm` contexts are not a security boundary](https://nodejs.org/api/vm.html#vm-executing-javascript). Escaping a `vm` sandbox to access the full Node.js runtime (file system, child processes, network) is well-documented and straightforward.

To mitigate this, the renderer uses the same approach as PostgreSQL: **it binds to `localhost` by default**, so it is not reachable from the network at all. This provides two layers of defense:

1. **Network layer** — Only processes on the same machine (or same Kubernetes pod network namespace) can reach the renderer. No remote attacker can connect.
2. **Authentication layer** — The optional `password` setting (required in production-like environments) protects against unauthorized local callers.

This means a developer running the renderer locally without a password is safe by default — the renderer is only reachable from their own machine, just as a default PostgreSQL installation only accepts local connections.

**When you must bind to `0.0.0.0`** (e.g., separate container workloads in Docker Compose or Kubernetes separate-workload deployments):

- Always set `RENDERER_PASSWORD` to a strong value
- Place the renderer behind private networking or firewall rules
- Never expose the renderer port to the public internet

See [JS Configuration](./js-configuration.md) for the `host` and `password` options, and [Container Deployment](./container-deployment.md) for architecture-specific guidance.

## CI and Test Environment Setup

Running tests that involve server-side rendering requires the Node Renderer to be running. Without it, tests will silently timeout with `Net::ReadTimeout` -- not crash with a clear error -- making the failure easy to misdiagnose.

### 1. Guard the initializer for test environments

A common mistake is guarding the Node Renderer configuration with `Rails.env.development?`, which excludes the test environment:

```ruby
# config/initializers/react_on_rails_pro.rb

# WRONG -- excludes test environment
if Rails.env.development?
  ReactOnRailsPro.configure do |config|
    config.server_renderer = "NodeRenderer"
  end
end

# CORRECT -- covers both development and test
if Rails.env.local?
  ReactOnRailsPro.configure do |config|
    config.server_renderer = "NodeRenderer"
  end
end
```

`Rails.env.local?` returns `true` for both `development` and `test` environments (available since Rails 7.1). For older Rails versions, use `Rails.env.development? || Rails.env.test?`.

### 2. Start the renderer in CI

The Node Renderer must be started as a background process before running tests. Add a step to your CI workflow:

```yaml
# .github/workflows/test.yml (GitHub Actions example)
jobs:
  test:
    runs-on: ubuntu-latest
    env:
      # Job-level: both the renderer and Rails test steps need this
      RENDERER_PASSWORD: ${{ secrets.RENDERER_PASSWORD }}
    steps:
      - name: Start Node Renderer
        run: |
          node renderer/node-renderer.js &
          # Wait for the renderer to be ready.
          # The renderer uses cleartext HTTP/2 (h2c), so use --http2-prior-knowledge for the probe.
          # --max-time 2 prevents hangs if the port is open but the process is stalled.
          for i in $(seq 1 30); do
            if curl -s --http2-prior-knowledge --max-time 2 http://localhost:3800/ > /dev/null 2>&1; then
              echo "Node Renderer is ready"
              break
            fi
            echo "Waiting for Node Renderer... ($i/30)"
            sleep 1
          done
          # Fail fast if renderer never became ready
          if ! curl -s --http2-prior-knowledge --max-time 2 http://localhost:3800/ > /dev/null 2>&1; then
            echo "Node Renderer failed to start in time" >&2
            exit 1
          fi
```

Key points:

- **Readiness check**: Poll port 3800 (or your configured port) before running tests. The renderer uses **cleartext HTTP/2 (h2c)**, so the `curl` probe must include `--http2-prior-knowledge`. Without it, `curl` sends an HTTP/1.1 request that the h2c server rejects.
- **`RENDERER_PASSWORD`**: Must be set in the CI environment and match the value configured in `react_on_rails_pro.rb`. Add it as a CI secret. **Important:** Declare this at the job level (not just the renderer step) so Rails can also read it when running tests.
- **Bundle pre-staging**: You do **not** need to set a bundle path env var for the renderer. In CI, run `rake react_on_rails_pro:pre_stage_bundle_for_node_renderer` after the webpack build and before starting the renderer — this symlinks the compiled bundle into the renderer's cache directory, eliminating the first-request upload latency. For remote renderers, use `rake react_on_rails_pro:copy_assets_to_remote_vm_renderer` instead.

### 3. Common CI failures

| Symptom                                   | Cause                          | Fix                                    |
| ----------------------------------------- | ------------------------------ | -------------------------------------- |
| All tests timeout with `Net::ReadTimeout` | Node Renderer not running      | Add the renderer start step above      |
| "Connection refused" errors               | Renderer started but not ready | Add the TCP readiness check loop       |
| Tests pass locally but fail in CI         | `Rails.env.development?` guard | Change to `Rails.env.local?`           |
| "Invalid password" errors                 | `RENDERER_PASSWORD` mismatch   | Ensure CI env var matches Rails config |

## Troubleshooting

- See [Memory Leaks guide](../../../pro/js-memory-leaks.md).

## Upgrading

The NodeRenderer has a protocol version on both the Rails and Node sides. If the Rails server sends a protocol version that does not match the Node side, an error is returned. Ideally, you want to keep both the Rails and Node sides at the same version.

## References

- [Installation](../../../pro/installation.md)
- [Rails Options for node-renderer](../../configuration/configuration-pro.md)
- [JS Options for node-renderer](./js-configuration.md)
- [Container Deployment](./container-deployment.md) — Sidecar vs. separate workloads, memory tuning, autoscaling, and troubleshooting

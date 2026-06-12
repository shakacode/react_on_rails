# Node Renderer Debugging

> **Pro Feature** — Available with [React on Rails Pro](../../../pro/react-on-rails-pro.md).
> Free or very low cost for startups and small companies. [Upgrade or licensing details →](../../../pro/upgrading-to-pro.md#try-pro-risk-free)

Because the renderer communicates over a port to Rails, you can start a local renderer instance with Node's inspector and debug the server-rendered JavaScript directly.

Use this page for breakpoints, renderer logs, and memory snapshots. For CPU flamegraphs, use [Profiling Server-Side Rendering Code](../../../pro/profiling-server-side-rendering-code.md). For React 19.2 Performance Tracks, hydration traces, and choosing the right profiling tool, use [React Performance Tracks and Profiling](../performance-tracks-and-profiling.md).

## Monorepo Workflow

For renderer debugging inside this repo, use the Pro dummy app at `react_on_rails_pro/spec/dummy`.
It is a `pnpm` workspace app and already points at the local packages in this monorepo.

## Debugging the Node Renderer

### Quick start: debugging with the full stack running

If you already have the dummy app running via `bin/dev` (which uses `Procfile.dev`), the node renderer is listening on port 3800 without `--inspect`. To attach a debugger, restart only the renderer with the inspector enabled:

```bash
cd react_on_rails_pro/spec/dummy
overmind stop node-renderer
pnpm run node-renderer:debug
```

Keep that terminal open while you debug. Then:

1. Open `chrome://inspect` in Chrome and connect to the renderer process.
2. Use overmind to isolate renderer logs: `overmind connect node-renderer` (Ctrl-B to detach).
3. Set breakpoints in the inspector and reload the page that triggers SSR.
4. After a server-bundle or renderer change, restart just the renderer.

If you prefer to keep the renderer under Overmind, temporarily add `--inspect` to the `node-renderer:` entry in `Procfile.dev`, then run `overmind restart node-renderer`.

### Isolated debugging: manual per-terminal startup

Use this when you need full control over the renderer process — different flags, a specific bundle, or rebuilding just the renderer package.

1. From the repo root, install dependencies and build the local packages:
   ```bash
   pnpm install
   pnpm run build
   ```
1. In one terminal, start the Pro dummy bundle watcher:
   ```bash
   cd react_on_rails_pro/spec/dummy
   pnpm run build:dev:watch
   ```
1. In another terminal, start the renderer with verbose logging:
   ```bash
   cd react_on_rails_pro/spec/dummy
   RENDERER_LOG_LEVEL=debug pnpm run node-renderer
   ```
1. If you want to attach a debugger instead, run:
   ```bash
   cd react_on_rails_pro/spec/dummy
   pnpm run node-renderer:debug
   ```
1. Reload the page that triggers the SSR issue and reproduce the problem.
1. If you change Ruby code in loaded gems, restart the Rails server.
1. If you change code under `packages/react-on-rails-pro-node-renderer`, rebuild that package before restarting the renderer:
   ```bash
   pnpm --filter react-on-rails-pro-node-renderer run build
   ```
1. If you are debugging an external app instead of the monorepo dummy app, refresh the installed renderer package using your local package workflow (for example `yalc`, `npm pack`, or a workspace link) before rerunning the renderer.

### Breakpoints vs. profiles

- Use `--inspect` breakpoints when you need to inspect props, globals, module state, or the exact branch taken during SSR.
- Use [the SSR profiling guide](../../../pro/profiling-server-side-rendering-code.md) when the code is correct but slow.
- Use [React Performance Tracks and Profiling](../performance-tracks-and-profiling.md) when the slow path includes browser hydration, Suspense, RSC timing, or client interactions.
- Use [Error Reporting and Tracing](./error-reporting-and-tracing.md) or [OpenTelemetry](../../../pro/node-renderer.md#observability-with-opentelemetry) for production request spans.

## Debugging Memory Leaks

If worker memory grows over time, use heap snapshots to find the source.

### Quick approach: `--heapsnapshot-signal` (no code changes)

Use Node's built-in flag to write heap snapshots on demand:

```bash
cd react_on_rails_pro/spec/dummy
# Adjust the port if your Rails app points at a different renderer URL.
NODE_OPTIONS="--heapsnapshot-signal=SIGUSR2" RENDERER_PORT=3800 node renderer/node-renderer.js
```

Then capture snapshots at different times:

```bash
kill -USR2 <worker-pid>   # writes a .heapsnapshot file to the working directory
```

This also works in production containers — set `NODE_OPTIONS="--heapsnapshot-signal=SIGUSR2"` as an environment variable, send the signal at different times, then copy the `.heapsnapshot` files to your local machine for analysis.

### Detailed approach: with forced GC

For more precise results, start the renderer with `--expose-gc` and a custom signal handler that forces garbage collection before each snapshot. See the [Memory Leaks guide](../../../pro/js-memory-leaks.md#2-take-v8-heap-snapshots) for the code.

### Analyzing snapshots

1. Load both `.heapsnapshot` files in Chrome DevTools (Memory tab → Load).
2. Use the **Comparison** view to see which objects accumulated between snapshots.
3. Look for growing `string`, `Object`, and `Array` counts — these typically point to module-level caches.

### Isolating memory issues with a separate renderer workload

When diagnosing memory leaks in a containerized environment, running the Node renderer as a separate workload (instead of a sidecar) makes it easier to:

- Monitor Node memory independently from Rails
- Capture heap snapshots without affecting the Rails process
- Restart or scale the renderer without restarting Rails

See the [Memory Leaks guide](../../../pro/js-memory-leaks.md) for common patterns and fixes.

## Debugging Jest tests

1. See [the Jest documentation](https://jestjs.io/docs/troubleshooting) for overall guidance.
2. For JetBrains IDEs, see [the RubyMine documentation](https://www.jetbrains.com/help/ruby/running-unit-tests-on-jest.html) for current instructions.

## Debugging the Ruby gem

Open the gemfile in the problematic app.

```ruby
gem "react_on_rails_pro", path: "../../../shakacode/react-on-rails/react_on_rails_pro"
```

Optionally, also specify react_on_rails to be local:

```ruby
gem "react_on_rails", path: "../../../shakacode/react-on-rails/react_on_rails"
```

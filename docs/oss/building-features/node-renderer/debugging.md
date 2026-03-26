# Node Renderer Debugging

> **Pro Feature** — Available with [React on Rails Pro](https://reactonrails.com/docs/pro/).
> Free or very low cost for startups and small companies. [Get a license →](https://pro.reactonrails.com/)

Because the renderer communicates over a port to the server, you can start a renderer instance locally in your application and debug it.

## Monorepo Workflow

For renderer debugging inside this repo, use the Pro dummy app at `react_on_rails_pro/spec/dummy`.
It is a `pnpm` workspace app and already points at the local packages in this monorepo.

## Debugging the Node Renderer

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
   pnpm run node-renderer-debug
   ```
1. Reload the page that triggers the SSR issue and reproduce the problem.
1. If you change Ruby code in loaded gems, restart the Rails server.
1. If you change code under `packages/react-on-rails-pro-node-renderer`, rebuild that package before restarting the renderer:
   ```bash
   pnpm --filter react-on-rails-pro-node-renderer run build
   ```
1. If you are debugging an external app instead of the monorepo dummy app, refresh the installed renderer package using your local package workflow (for example `yalc`, `npm pack`, or a workspace link) before rerunning the renderer.

## Debugging Memory Leaks

If worker memory grows over time, use heap snapshots to find the source:

1. Start the renderer with `--expose-gc` to enable forced GC before snapshots:
   ```bash
   cd react_on_rails_pro/spec/dummy
   RENDERER_PORT=3800 node --expose-gc client/node-renderer.js
   ```
2. Take heap snapshots at different times using `v8.writeHeapSnapshot()` (triggered via `SIGUSR2` signal or a custom endpoint).
3. Load both snapshots in Chrome DevTools (Memory tab → Load) and use the **Comparison** view to see which objects accumulated between snapshots.
4. Look for growing `string`, `Object`, and `Array` counts — these typically point to module-level caches.

See the [Memory Leaks guide](../../../pro/js-memory-leaks.md) for common patterns and fixes.

## Debugging using the Node debugger

1. See [this article](https://github.com/shakacode/react_on_rails/issues/1196) on setting up the debugger.

## Debugging Jest tests

1. See [the Jest documentation](https://jestjs.io/docs/troubleshooting) for overall guidance.
2. For RubyMine, see [the RubyMine documentation](https://www.jetbrains.com/help/ruby/running-unit-tests-on-jest.html) for the current information. The original [Testing With Jest in WebStorm](https://blog.jetbrains.com/webstorm/2018/10/testing-with-jest-in-webstorm/) post can be useful as well.

## Debugging the Ruby gem

Open the gemfile in the problematic app.

```ruby
gem "react_on_rails_pro", path: "../../../shakacode/react-on-rails/react_on_rails_pro"
```

Optionally, also specify react_on_rails to be local:

```ruby
gem "react_on_rails", path: "../../../shakacode/react-on-rails/react_on_rails"
```

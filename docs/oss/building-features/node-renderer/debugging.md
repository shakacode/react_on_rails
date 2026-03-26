# Node Renderer Debugging

> **Pro Feature** — Available with [React on Rails Pro](https://reactonrails.com/docs/pro/).
> Free or very low cost for startups and small companies. [Get a license →](https://pro.reactonrails.com/)

Because the renderer communicates over a port to the server, you can start a renderer instance locally in your application and debug it.

## Yalc Workflow

For repo contributors, the monorepo still uses [yalc](https://github.com/whitecolor/yalc) to wire local
`react-on-rails-pro-node-renderer` changes into `react_on_rails_pro/spec/dummy`. Running `pnpm install` in
`react_on_rails_pro/spec/dummy` triggers the dummy app's preinstall hook, which rebuilds the local packages
and refreshes the yalc link.

## Debugging the Node Renderer

1. `cd react_on_rails_pro/spec/dummy`
1. Run `bundle && pnpm install`
1. Start the dummy app with `overmind start -f Procfile.dev` (or `foreman start -f Procfile.dev`). The current `Procfile.dev` already runs the renderer with `node --inspect client/node-renderer.js`.
1. Reload the browser page that causes the renderer issue. You can then update the JS code and rerun the same command to restart the renderer with the new code.
1. Be sure to restart the rails server if you change any ruby code in loaded gems.
1. If you change code under `packages/react-on-rails-pro-node-renderer` or `react_on_rails_pro`, rerun `pnpm install` in `react_on_rails_pro/spec/dummy` to refresh the yalc link before testing again.
1. For a dedicated debugger session, run `pnpm run node-renderer-debug` from `react_on_rails_pro/spec/dummy`, or `cd react_on_rails_pro && nps renderer.debug` to debug the package directly.

## Debugging Memory Leaks

If worker memory grows over time, use heap snapshots to find the source:

1. Start the renderer with `--expose-gc` to enable forced GC before snapshots:
   ```bash
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

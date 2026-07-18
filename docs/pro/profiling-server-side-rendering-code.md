# Profiling Server-Side Rendering Code

This guide helps you profile server-side JavaScript running through React on Rails Pro so you can find slow paths and bottlenecks.

Use this page when you need a CPU profile of the Pro Node Renderer or an ExecJS/V8 log. For breakpoints and renderer logs, see [Node Renderer Debugging](../oss/building-features/node-renderer/debugging.md). For React 19.2 Performance Tracks, browser traces, and a profiling decision guide, see [React Performance Tracks and Profiling](../oss/building-features/performance-tracks-and-profiling.md).

The examples below use the sample app in `react_on_rails_pro/spec/dummy`.

**Prerequisite:** This guide assumes you have [Overmind](https://github.com/DarthSim/overmind) installed. On macOS, you can install it with `brew install overmind`.

## Profiling the Pro Node Renderer

1. Start the sample app with Overmind.

   ```bash
   cd react_on_rails_pro/spec/dummy
   overmind start -f Procfile.dev
   ```

1. In a second terminal, stop only the managed `node-renderer` process.

   ```bash
   cd react_on_rails_pro/spec/dummy
   overmind stop node-renderer
   ```

1. In that second terminal, restart the renderer manually with the Node inspector enabled.

   ```bash
   cd react_on_rails_pro/spec/dummy
   RENDERER_LOG_LEVEL=debug RENDERER_PORT=3800 node --inspect renderer/node-renderer.js
   ```

   Keep this terminal open while you profile. In the repository dummy app you can also use `pnpm run node-renderer:debug`, which runs the same renderer entry point with `--inspect`. In another app, use the same package script with your package manager, such as `npm run node-renderer:debug` or `yarn node-renderer:debug`.

1. Visit `chrome://inspect` in Chrome. You should see the Node renderer process:

   ![Chrome Inspect Tab](https://github.com/shakacode/react_on_rails_pro/assets/7099193/2a64660f-9381-4bbb-b385-318aa833389d)

1. Click the `inspect` link. This opens a dedicated DevTools window for the Node process. Open the **Performance** tab there.

   ![Chrome Performance Tab](https://github.com/shakacode/react_on_rails_pro/assets/7099193/ddf572bd-182f-4911-bb8f-4bafa4ec1034)

1. Click the record button.

   ![Chrome Performance Tab](https://github.com/shakacode/react_on_rails_pro/assets/7099193/20848091-d446-4690-988b-09db59ddf9e0)

1. Open the web app you want to test and refresh it multiple times. In the sample app, that means visiting [http://localhost:3000](http://localhost:3000).

   ![RORP Dummy App](https://github.com/shakacode/react_on_rails_pro/assets/7099193/8dc1ef3d-62e4-492d-a5b4-c693b7f7e08c)

1. If the page raises a `Timeout Error`, temporarily increase `ssr_timeout` in `config/initializers/react_on_rails_pro.rb`. Running the renderer with `--inspect` slows SSR enough that a normal development timeout can be too short.

   ```ruby
   config.ssr_timeout = 10
   ```

1. Stop performance recording.

   ![Running profiler at the performance tab](https://github.com/shakacode/react_on_rails_pro/assets/7099193/bc02bbd6-3358-4edf-ba3a-36e11620a096)

1. Inspect the recorded profile.

   ![Recorded Node JS profile](https://github.com/shakacode/react_on_rails_pro/assets/7099193/6dc098bb-9f07-49be-9a1f-2149f6712631)

## Profile Analysis

The first request usually includes extra work because Rails uploads component bundles and the renderer executes the server-side bundle code.

![Recorded Node JS profile](https://github.com/shakacode/react_on_rails_pro/assets/7099193/9ff91973-7190-465b-9750-c99d95f16711)

Zoom into that first request and search for `buildVM` with `Ctrl+F` or `Cmd+F`.

![NodeJS startup code profile](https://github.com/shakacode/react_on_rails_pro/assets/7099193/e16d2028-83a2-43e6-a2ca-c788873dd88c)

Code that runs inside that VM context appears under `runInContext`. For example, server-rendered components that use `renderToString` show up below that frame.

![runInContext function profile](https://github.com/shakacode/react_on_rails_pro/assets/7099193/a50f76de-83aa-4af7-8eb2-2941f419f4aa)

For later requests, zoom into another request-sized block of work.

![Recorded Node JS profile](https://github.com/shakacode/react_on_rails_pro/assets/7099193/6bfff9bf-375a-4ba8-817e-81509821e8df)

You should find a call to `serverRenderReactComponent`.

![serverRenderReactComponent function profile](https://github.com/shakacode/react_on_rails_pro/assets/7099193/6b2014e2-db85-4ba5-9dfc-2600cc863e98)

**If you cannot find any requests coming to the renderer server, component caching may be the cause.** You can try to disable React on Rails caching by adding the following line to `config/initializers/react_on_rails_pro.rb`:

```ruby
config.prerender_caching = false
```

If the slow path includes client hydration, browser layout, or React Server Components timing, collect a separate browser trace using [React Performance Tracks and Profiling](../oss/building-features/performance-tracks-and-profiling.md). The Node profile explains renderer CPU time; the browser trace explains what happened after the response reached the browser.

## Profiling Renderer With High Loads

To see renderer behavior under concurrent local traffic, use `ApacheBench (ab)` to make many HTTP requests to the same endpoint.

1. `ApacheBench (ab)` is installed on macOS by default. On Linux, install it with:

   ```bash
   sudo apt-get install apache2-utils
   ```

1. Follow the steps in [Profiling the Pro Node Renderer](#profiling-the-pro-node-renderer), but instead of opening the page in the browser, let `ab` drive the traffic:

   ```bash
   ab -n 100 -c 10 http://localhost:3000/
   ```

1. The Node profile should show the renderer responding to concurrent requests.

   ![Busy renderer profile](https://github.com/shakacode/react_on_rails_pro/assets/7099193/2ce69bf2-45ee-4a9d-af33-37e20aed86bc)

1. Analyze each request-sized block as described in [Profile Analysis](#profile-analysis).

## Profiling ExecJS

React on Rails Pro supports profiling with ExecJS starting from version **4.0.0**. You will need to do more work to profile ExecJS if you are using an older version.

If you are using **v4.0.0** or later, enable the profiler by setting `profile_server_rendering_js_code` in the React on Rails Pro initializer:

```ruby
config.profile_server_rendering_js_code = true
```

> **Prerequisites:**
>
> - **ExecJS renderer only**: This setting only applies when `server_renderer == "ExecJS"` (the default). If you're using the Pro Node Renderer, this setting has no effect — use the [Chrome DevTools profiling method](#profiling-the-pro-node-renderer) above instead.
> - **Node or V8 ExecJS runtime**: The ExecJS runtime must be Node or V8. Set this via the `EXECJS_RUNTIME` environment variable (e.g., `EXECJS_RUNTIME=Node`). Other runtimes will raise a configuration error.

Then, run the app you are profiling and open some pages in it. You will find log files named `isolate-0x*.log` in the root of your app. Use the following command to analyze the log files:

```bash
rake react_on_rails_pro:process_v8_logs
```

The task converts the logs to `profile.v8log.json` files and moves them to the **v8_profiles** directory.

You can analyze the `profile.v8log.json` file with `speedscope`:

```bash
pnpm dlx speedscope /path/to/profile.v8log.json
# or with npm:
npx speedscope /path/to/profile.v8log.json
# or with Yarn:
yarn dlx speedscope /path/to/profile.v8log.json
```

### Profiling ExecJS with Older Versions of React on Rails Pro

If you are using an older version of React on Rails Pro, you need to configure the ExecJS runtime manually.

If you are using `node` as the runtime for ExecJS, you can enable the profiler by adding the following code on top of the `ReactOnRailsPro` initializer.

```ruby
class CustomRuntime < ExecJS::ExternalRuntime
  def initialize
    super(
      name: 'Custom Node.js (with --prof)',
      command: ['node --prof'],
      runner_path: ExecJS.root + '/support/node_runner.js'
    )
  end
end

ExecJS.runtime = CustomRuntime.new
```

If you are using V8 as the runtime for ExecJS, you can enable the profiler by adding the following code on top of the `ReactOnRailsPro` initializer.

```ruby
class CustomRuntime < ExecJS::ExternalRuntime
  def initialize
    super(
      name: 'Custom V8 (with --prof)',
      command: ['d8 --prof'],
      runner_path: ExecJS.root + '/support/v8_runner.js'
    )
  end
end
```

After adding the code, run the app and open the pages you want to profile. You will find log files named `isolate-0x*.log` in the root of your app. Use these commands to analyze a log:

```bash
node --prof-process --preprocess -j isolate-0x*.log > profile.v8log.json
pnpm dlx speedscope /path/to/profile.v8log.json
# or with npm:
npx speedscope /path/to/profile.v8log.json
# or with Yarn:
yarn dlx speedscope /path/to/profile.v8log.json
```

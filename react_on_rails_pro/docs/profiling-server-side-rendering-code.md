# Profiling Server-Side Renderer In RORP

This guide helps you profile the server-side code running in RORP node-renderer. It may help you find slow parts or bottlenecks in code.

This guide uses the RORP dummy app in profiling the server-side code.

## Profiling Server-Side Code Running On Node Renderer

1. Run node-renderer using the `--inspect` node option.

   Open the `spec/dummy/Procfile.dev` file and update the `node-renderer` process to run the renderer using `node --inspect` command. Change the following line

   ```bash
   node-renderer: RENDERER_LOG_LEVEL=debug yarn run node-renderer
   ```

   To

   ```bash
   node-renderer: RENDERER_LOG_LEVEL=debug RENDERER_PORT=3800 node --inspect client/node-renderer.js
   ```

1. Run the App

   ```bash
   bin/dev
   ```

1. Visit `chrome://inspect` on Chrome browser and you should see something like this:

   ![Chrome Inspect Tab](https://github.com/shakacode/react_on_rails_pro/assets/7099193/2a64660f-9381-4bbb-b385-318aa833389d)

1. Click the `inspect` link. This should open a developer tools window. Open the performance tab there

   ![Chrome Performance Tab](https://github.com/shakacode/react_on_rails_pro/assets/7099193/ddf572bd-182f-4911-bb8f-4bafa4ec1034)

1. Click the `record` button

   ![Chrome Performance Tab](https://github.com/shakacode/react_on_rails_pro/assets/7099193/20848091-d446-4690-988b-09db59ddf9e0)

1. Open the web app you want to test and refresh it multiple times. We use the React on Rails Pro dummy app for this tutorial. So, we will open it in the browser by going to [http://localhost:3000](http://localhost:3000)

   ![RORP Dummy App](https://github.com/shakacode/react_on_rails_pro/assets/7099193/8dc1ef3d-62e4-492d-a5b4-c693b7f7e08c)

1. If you get any `Timeout Error` while visiting the page, you may need to increase the `ssr_timeout` in the Ruby on Rails initializer file. **Running node-renderer** using the `--inspect` flag makes it slower. So, you can increase the `ssr_timeout` to `10 seconds` by adding the following line to `config/initializers/react_on_rails_pro.rb` file

   ```ruby
   config.ssr_timeout = 10
   ```

1. Stop performance recording

   ![Running profiler at the performance tab](https://github.com/shakacode/react_on_rails_pro/assets/7099193/bc02bbd6-3358-4edf-ba3a-36e11620a096)

1. You should see something like this

   ![Recorded Node JS profile](https://github.com/shakacode/react_on_rails_pro/assets/7099193/6dc098bb-9f07-49be-9a1f-2149f6712631)

## Profile Analysis

You can see that there is much work done during the first request because it contains the process of uploading the component bundles and executing the server-side bundle code.

![Recorded Node JS profile](https://github.com/shakacode/react_on_rails_pro/assets/7099193/9ff91973-7190-465b-9750-c99d95f16711)

By zooming into it, you can see the function that’s called `buildVM` (you can also search for it by clicking Ctrl+f and type the function name)

![NodeJS startup code profile](https://github.com/shakacode/react_on_rails_pro/assets/7099193/e16d2028-83a2-43e6-a2ca-c788873dd88c)

All code that runs later inside that code context calls the `runInContext` function. Like this code that calls `renderToString` to render a specific react component

![runInContext function profile](https://github.com/shakacode/react_on_rails_pro/assets/7099193/a50f76de-83aa-4af7-8eb2-2941f419f4aa)

To check the profile of other requests, zoom into any of the following spots of work

![Recorded Node JS profile](https://github.com/shakacode/react_on_rails_pro/assets/7099193/6bfff9bf-375a-4ba8-817e-81509821e8df)

You should find a call to `serverRenderReactComponent`

![serverRenderReactComponent function profile](https://github.com/shakacode/react_on_rails_pro/assets/7099193/6b2014e2-db85-4ba5-9dfc-2600cc863e98)

**If you can’t find any requests coming to the renderer server, component caching may be the cause.** You can try to disable React on Rails caching by adding the following line to `config/initializers/react_on_rails_pro.rb` file

```ruby
config.prerender_caching = false
```

## Profiling Renderer With High Loads

To see the renderer behavior while there are many requests coming to it, you can use the `ApacheBench (ab)` tool that lets you make many HTTP requests to a specific end points at the same time.

1. The `ApacheBench (ab)` is installed on macOS by default. You can install it on Linux by running the following command

   ```bash
   sudo apt-get install apache2-utils
   ```

1. Do all steps in `Profiling Server-Side Code Running On Node Renderer` section except the step number 6. Instead of opening the page in the browser, let the `ab` tool make many HTTP requests for you by running the following command.

   ```bash
   ab -n 100 -c 10 http://localhost:3000/
   ```

1. Now, when you open the node-renderer profile, you will see it very busy responding to all requests

   ![Busy renderer profile](https://github.com/shakacode/react_on_rails_pro/assets/7099193/2ce69bf2-45ee-4a9d-af33-37e20aed86bc)

1. Then, you can analyze the renderer behavior of each request as stated in `Profile Analysis` section.

### ExecJS

React on Rails Pro supports profiling with ExecJS starting from version **4.0.0**. You will need to do more work to profile ExecJS if you are using an older version.

If you are using **v4.0.0** or later, you can enable the profiler by setting the `profile_server_rendering_js_code` config by adding the following line to the ReactOnRails initializer.

```ruby
config.profile_server_rendering_js_code = true
```

Then, run the app you are profiling and open some pages in it.
You will find many log files with the name `isloate-0x*.log` in the root of your app. You can use the following command to analyze the log files.

```bash
rake react_on_rails_pro:process_v8_logs
```

You will find all log files are converted to `profile.v8log.json` file and moved to the **v8_profiles** directory.

You can use `speedscope` to analyze the `profile.v8log.json` file. You can install `speedscope` by running the following command

```bash
npm install -g speedscope
```

Then, you can analyze the profile by running the following command

```bash
speedscope /path/to/profile.v8log.json
```

### Profiling ExecJS with Older Versions of React on Rails Pro

If you are using an older version of React on Rails Pro, you need to do more work to profile the server-side code running in the ExecJS.

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

After adding the code, you can run the app and open some pages in it. You will find many log files with the name `isloate-0x*.log` in the root of your app. You can use the following command to analyze any log file.

```bash
node --prof-process --preprocess -j isolate*.log > profile.v8log.json
npm install -g speedscope
speedscope /path/to/profile.v8log.json
```

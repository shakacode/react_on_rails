# Testing Configuration

This guide explains how to configure React on Rails for optimal testing with RSpec, Minitest, or other test frameworks.

## Quick Start

For most applications, the recommended approach is React on Rails TestHelper with `build_test_command`:

```ruby
# config/initializers/react_on_rails.rb
ReactOnRails.configure do |config|
  config.build_test_command = "RAILS_ENV=test bin/shakapacker" # NODE_ENV is derived from RAILS_ENV by Shakapacker
end
```

Leave `NODE_ENV` unset for Shakapacker asset builds: Shakapacker automatically sets `NODE_ENV` to match `RAILS_ENV`,
so `RAILS_ENV=test` is sufficient. Set `NODE_ENV=test` explicitly only when running a JavaScript test runner such as
Jest directly.

Then wire TestHelper into your test framework. If your app uses both RSpec and Minitest, wire both files.

**RSpec** — add to `spec/rails_helper.rb`:

```ruby
require "react_on_rails/test_helper"

RSpec.configure do |config|
  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
end
```

**Minitest** — add to `test/test_helper.rb`:

```ruby
require "react_on_rails/test_helper"

class ActiveSupport::TestCase
  setup do
    ReactOnRails::TestHelper.ensure_assets_compiled
  end
end
```

## RSC and Node Renderer System Tests

React Server Components add one more moving part to the standard test setup: system tests need compiled client, server, and RSC bundles, and the Rails test process must be able to reach a node-renderer process that uses the test bundle cache.

Use this recipe for Capybara, system, and end-to-end tests that exercise `stream_react_component`, `RSCRoute`, or the `rsc_payload_route`.

This recipe uses the React on Rails TestHelper with `build_test_command`: Rails checks whether generated bundles are stale, runs your test build command when needed, and fails fast if compilation fails.

The Step 3 renderer-lifecycle helper is **RSpec-focused** because it uses `before(:suite)` and `after(:suite)` hooks; for Minitest, see [Minitest Equivalent](#minitest-equivalent) for a parallel adaptation that reuses the same safety points from a `test/test_helper.rb` harness plus `Minitest.after_run`.

See [Two Approaches to Test Asset Compilation](#two-approaches-to-test-asset-compilation) for the underlying compilation tradeoffs.

### 1. Set Renderer ENV Before Rails Boots

The Pro initializer reads renderer settings while Rails boots. Set test renderer ENV values before requiring `config/environment` in `spec/rails_helper.rb`. Generated Pro apps read `REACT_RENDERER_URL`; some older or custom initializers read `RENDERER_URL`, so the example sets both names. Keep the worker ID normalization in a small support file so the Rails boot preamble and renderer lifecycle code cannot drift apart.

```ruby
# spec/support/rsc_test_worker.rb
module RscTestWorker
  ID = ENV.fetch("TEST_ENV_NUMBER", "")
          .gsub(/[^0-9]/, "")
          .then { |worker_id| worker_id.empty? ? "0" : worker_id }
end
```

```ruby
# spec/rails_helper.rb
ENV["RAILS_ENV"] ||= "test"
require_relative "support/rsc_test_worker"

ENV["RENDERER_PORT"] ||= (3900 + RscTestWorker::ID.to_i).to_s
renderer_url = "http://127.0.0.1:#{ENV["RENDERER_PORT"]}"
ENV["REACT_RENDERER_URL"] ||= renderer_url # used by config.renderer_url = ENV["REACT_RENDERER_URL"]
ENV["RENDERER_URL"] ||= renderer_url       # used by some older/custom initializers
ENV["RENDERER_SERVER_BUNDLE_CACHE_PATH"] ||=
  File.expand_path("../tmp/node-renderer-bundles-test-#{RscTestWorker::ID}", __dir__)

require_relative "../config/environment"
```

`TEST_ENV_NUMBER` is set by the `parallel_tests` gem. It uses `""` for the first worker, then `"2"`, `"3"`, and so on (skipping `"1"`), so the example uses ports 3900, 3902, 3903, and leaves a harmless gap at 3901. That unused 3901 port is expected; keeping the normalized worker ID stable matters more than filling every port number. Before adopting the 3900 range, check for existing listeners with `lsof -i :3900-3910`; if another service already uses these ports, set `RENDERER_PORT` before this snippet or change the base port in the example. If you use a different parallelization tool, update `spec/support/rsc_test_worker.rb` to normalize that tool's worker ID to a stable, path-safe `RscTestWorker::ID` so every worker gets a unique port, cache path, and renderer log.

If you run tests in parallel, each worker needs its own `RENDERER_PORT` and `RENDERER_SERVER_BUNDLE_CACHE_PATH`. Sharing a renderer cache across parallel workers can produce stale-bundle and missing-bundle failures that look like flaky RSC timeouts.

### 2. Compile Test Bundles Up Front

Configure the React on Rails test helper to compile assets before the first RSC example. Your `build_test_command` must build all bundles needed by the test environment, not only the browser bundle.

```ruby
# config/initializers/react_on_rails.rb
ReactOnRails.configure do |config|
  config.build_test_command = "NODE_ENV=test RAILS_ENV=test bin/shakapacker"
end
```

The Quick Start command only sets `RAILS_ENV` for the minimal browser-bundle case. The RSC recipe also sets `NODE_ENV=test` so JavaScript build scripts, webpack/shakapacker config, and the node-renderer all see the test environment consistently. If your app's build does not branch on `NODE_ENV`, the simpler Quick Start command is still enough for non-RSC tests.

> **Warning:** Three copy-paste hazards in the snippet below — read these before adapting it.
>
> - **The metatag list replaces TestHelper defaults.** Passing any metatags to `configure_rspec_to_compile_assets` replaces the defaults, so include `:js`, `:server_rendering`, and `:controller` alongside `:rsc` if your suite mixes RSC and non-RSC specs, or those tag groups will no longer trigger compilation.
> - **`define_derived_metadata` tags every `spec/system` and `spec/features` example.** That is intentional so the first browser request cannot race ahead of RSC bundle compilation, but it compiles for unrelated system tests too. If only some directories exercise RSC, narrow the regex to something like `%r{spec/(system/rsc|features/rsc)}` or tag those examples manually.
> - **Load `support/rsc_node_renderer` _after_ registering `configure_rspec_to_compile_assets`.** The Step 3 helper installs a `before(:suite)` hook that validates bundles when the renderer boots, so the compile hook must register first. On older RSpec, also compile assets in CI before running the spec process — see the Caveats note at the end of Step 3.

```ruby
# spec/rails_helper.rb
require "react_on_rails/test_helper"

RSpec.configure do |config|
  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(
    config,
    :rsc,
    :js,
    :server_rendering,
    :controller
  )

  config.define_derived_metadata(file_path: %r{spec/(system|features)}) do |metadata|
    metadata[:rsc] = true
  end
end

require_relative "support/rsc_node_renderer"
```

Tag request specs that hit the RSC payload endpoint explicitly with `:rsc`. If your suite uses a different tag scheme, pass the complete list of tags that should trigger compilation. The important part is that the build runs before the first request that can upload bundles to the node renderer.

### 3. Start One Test Renderer Per Worker

Start the renderer in `before(:suite)` after assets are compiled and stop it in `after(:suite)`. The example below assumes your app has a `node-renderer` package script that launches the node-renderer server, reads `RENDERER_PORT` and `RENDERER_SERVER_BUNDLE_CACHE_PATH` from ENV, and serves the RSC test bundle cache. See [Node Renderer JavaScript Configuration](node-renderer/js-configuration.md#example-launch-files) for launch-file and `package.json` script examples. Replace the package-manager command with the one your project uses.

> **Warning:** The generated `renderer/node-renderer.js` template hardcodes `serverBundleCachePath` to `path.resolve(__dirname, '../.node-renderer-bundles')`, so it ignores `RENDERER_SERVER_BUNDLE_CACHE_PATH` until you change it. Without this edit every parallel worker shares the same cache directory and you will see stale-bundle and missing-bundle flakes that look like RSC timeouts. Update the launch file to read the env var:
>
> ```js
> // renderer/node-renderer.js
> const config = {
>   serverBundleCachePath:
>     process.env.RENDERER_SERVER_BUNDLE_CACHE_PATH || path.resolve(__dirname, '../.node-renderer-bundles'),
>   port: Number(process.env.RENDERER_PORT) || 3800,
>   // ...
> };
> ```
>
> The renderer package's built-in default chain is `RENDERER_SERVER_BUNDLE_CACHE_PATH || RENDERER_BUNDLE_PATH || '/tmp/react-on-rails-pro-node-renderer-bundles'`. The middle term is intentionally omitted here because `RENDERER_BUNDLE_PATH` is deprecated; if your existing renderer config relies on it, migrate to `RENDERER_SERVER_BUNDLE_CACHE_PATH` before adopting this snippet so the per-worker cache path actually takes effect.

```ruby
# spec/support/rsc_node_renderer.rb
require "fileutils"
require "socket"
require_relative "rsc_test_worker"

module RscNodeRenderer
  module_function

  def wait_until_ready!(host:, port:, timeout_seconds: 30, log_path: nil, pid: nil)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout_seconds
    saw_reset = false

    loop do
      begin
        Socket.tcp(host, port, connect_timeout: 1).close
        break
      rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT
        # Port not yet open; renderer still booting.
      rescue Errno::ECONNRESET
        # Connection reset: renderer bound the port but closed the connection before accepting.
        # Fall through — the PID check below will detect a dead process and raise before the deadline.
        # If the deadline expires without a successful connect, the deadline error mentions the reset
        # so a port already used by another service is easier to diagnose than a generic timeout.
        saw_reset = true
      rescue Errno::EADDRNOTAVAIL, Errno::EHOSTUNREACH, SocketError => e
        raise "Cannot reach node renderer at #{host}:#{port}. " \
              "Check the host configuration (#{e.class}: #{e.message})."
      end

      if pid
        begin
          # Heuristic early-exit check: if the launcher process has already died, raise now rather than
          # waiting for the deadline. For `pnpm run <script>`, pnpm typically stays resident while Node
          # is alive, but process managers that exec directly into Node (or daemonize) will exit here even
          # though the renderer is still starting, surfacing a misleading ESRCH. The TCP probe above is
          # the authoritative readiness signal; this check is only a fast-fail shortcut for the common
          # pnpm/npm/yarn case. Replace it with an app-specific health check if your launcher daemonizes.
          Process.kill(0, pid)
        rescue Errno::ESRCH
          hint = log_path ? " Check #{log_path} for startup errors." : ""
          raise "Node renderer process (pid #{pid}) exited before binding to #{host}:#{port}.#{hint}"
        rescue Errno::EPERM
          # Process exists but we lack permission to signal it (different UID, seccomp, container boundary).
          # Continue waiting for the TCP port — the port probe is authoritative for readiness.
        end
      end

      if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
        hint = log_path ? " Check #{log_path} for startup errors." : ""
        reset_hint = saw_reset ? " (TCP connections were reset — another process may already be using this port)" : ""
        raise "Node renderer did not boot on #{host}:#{port} within #{timeout_seconds}s.#{hint}#{reset_hint}"
      end

      sleep 0.1
    end
  end
end

# Intentional suite-level closure state shared by before(:suite) and after(:suite).
# This avoids relying on RSpec hook instance variables while keeping mutation local to this support file.
rsc_node_renderer_pid = nil
rsc_node_renderer_waiter = nil

RSpec.configure do |config|
  config.before(:suite) do
    next unless ENV["RSC_NODE_RENDERER_TESTS"] == "1"

    cache_path = ENV.fetch("RENDERER_SERVER_BUNDLE_CACHE_PATH") do
      raise "RENDERER_SERVER_BUNDLE_CACHE_PATH is not set. " \
            "Follow Step 1 of this guide to set it before Rails boots so every parallel worker " \
            "gets a unique renderer bundle cache directory."
    end
    cache_path = cache_path.strip
    raise "RENDERER_SERVER_BUNDLE_CACHE_PATH is empty." if cache_path.empty?

    expanded_cache_path = File.expand_path(cache_path, Rails.root.to_s)
    FileUtils.mkdir_p(Rails.root.join("tmp"))
    tmp_root = Rails.root.join("tmp").to_s
    unless expanded_cache_path.start_with?("#{tmp_root}#{File::SEPARATOR}")
      raise "RENDERER_SERVER_BUNDLE_CACHE_PATH must be inside Rails.root/tmp " \
            "(got: #{expanded_cache_path}). " \
            "This path is deleted and recreated on every test run, so only paths " \
            "inside Rails.root/tmp are permitted to prevent accidental data loss."
    end
    FileUtils.rm_rf(expanded_cache_path)
    FileUtils.mkdir_p(expanded_cache_path)

    renderer_env = {
      "NODE_ENV" => "test",
      "RAILS_ENV" => "test",
      "RENDERER_PORT" => ENV.fetch("RENDERER_PORT") do
        raise "RENDERER_PORT is not set. " \
              "Follow Step 1 of this guide to set it before Rails boots so every parallel worker " \
              "gets a unique renderer port."
      end,
      "RENDERER_SERVER_BUNDLE_CACHE_PATH" => expanded_cache_path
    }

    renderer_port = begin
      Integer(renderer_env["RENDERER_PORT"])
    rescue ArgumentError
      raise "RENDERER_PORT must be an integer port number " \
            "(got: #{renderer_env['RENDERER_PORT'].inspect})"
    end
    begin
      Socket.tcp("127.0.0.1", renderer_port, connect_timeout: 1).close
      raise "RENDERER_PORT #{renderer_env['RENDERER_PORT']} is already in use. " \
            "A previous test run may have left an orphaned node renderer. " \
            "Kill it manually or restart the CI job."
    rescue Errno::ECONNREFUSED
      # Port refused immediately — nothing is listening; safe to spawn.
    rescue Errno::ETIMEDOUT
      # SYN silently dropped (firewall/throttle). Unusual on 127.0.0.1, so surface it in
      # CI logs but proceed — treating it as fatal would block tests whenever a stray DROP
      # rule is present on loopback.
      warn "RENDERER_PORT #{renderer_env['RENDERER_PORT']} pre-spawn probe timed out on 127.0.0.1; " \
           "this is unusual on loopback. Continuing under the assumption that the port is free."
    rescue Errno::ECONNRESET
      raise "RENDERER_PORT #{renderer_env['RENDERER_PORT']} accepted and reset a connection. " \
            "Another service may already be using it."
    rescue Errno::EADDRNOTAVAIL, Errno::EHOSTUNREACH, SocketError => e
      raise "Cannot probe RENDERER_PORT #{renderer_env['RENDERER_PORT']}: #{e.class}: #{e.message}"
    end

    FileUtils.mkdir_p(Rails.root.join("log"))
    renderer_log_path = Rails.root.join("log/node-renderer-test-#{RscTestWorker::ID}.log").to_s
    rsc_node_renderer_pid = Process.spawn(
      renderer_env,
      "pnpm", # replace with "npm", "yarn", or "bun" if that is your package manager
      "run",
      "node-renderer",
      chdir: Rails.root.to_s,
      out: renderer_log_path,
      err: [:child, :out],
      pgroup: true # place pnpm and its child Node process in a new process group
    )
    rsc_node_renderer_waiter = Process.detach(rsc_node_renderer_pid)

    renderer_timeout_value = ENV.fetch("RSC_NODE_RENDERER_BOOT_TIMEOUT", "30")
    renderer_timeout = begin
      Integer(renderer_timeout_value)
    rescue ArgumentError
      raise "RSC_NODE_RENDERER_BOOT_TIMEOUT must be an integer number of seconds " \
            "(got: #{ENV['RSC_NODE_RENDERER_BOOT_TIMEOUT'].inspect})"
    end
    begin
      RscNodeRenderer.wait_until_ready!(
        host: "127.0.0.1",
        port: renderer_port,
        timeout_seconds: renderer_timeout,
        log_path: renderer_log_path,
        pid: rsc_node_renderer_pid
      )
    rescue StandardError
      begin
        Process.kill("-TERM", rsc_node_renderer_pid)
      rescue Errno::ESRCH, Errno::EPERM
        # Already stopped or no permission to signal the process group; matches the after(:suite)
        # cleanup so the original startup failure isn't masked by an EPERM here.
      end
      rsc_node_renderer_waiter&.join(2)
      rsc_node_renderer_pid = nil
      rsc_node_renderer_waiter = nil
      raise
    end
  end

  config.after(:suite) do
    pid = rsc_node_renderer_pid
    next unless pid

    # Sends SIGTERM to the entire process group so pnpm and the Node child both stop.
    # Raises Errno::ESRCH if the group is already gone; caught by rescue below.
    Process.kill("-TERM", pid)
    # Thread#join returns the waiter thread when the process exits, and nil on timeout.
    # SIGKILL only fires when SIGTERM did not stop the process within the join window.
    unless rsc_node_renderer_waiter&.join(5)
      begin
        Process.kill("-KILL", pid)
      rescue Errno::ESRCH
        # Process stopped between the join timeout and the SIGKILL; nothing more to do.
      else
        unless rsc_node_renderer_waiter&.join(5)
          warn "Node renderer process group #{pid} did not stop after SIGKILL; " \
               "it may still occupy the renderer port for the next CI retry."
        end
      end
    end
  rescue Errno::ESRCH
    # Already stopped.
  rescue Errno::EPERM
    warn "No permission to stop node renderer process group #{pid}; " \
         "it may need manual cleanup."
  ensure
    rsc_node_renderer_pid = nil
    rsc_node_renderer_waiter = nil
  end
end
```

Require this file from `spec/rails_helper.rb` after loading `react_on_rails/test_helper`, unless your suite already loads `spec/support/**/*.rb`. On slow CI workers, increase `RSC_NODE_RENDERER_BOOT_TIMEOUT` instead of adding sleeps.

> **Note:** The setup writes per-worker artifacts to `tmp/node-renderer-bundles-test-*` and `log/node-renderer-test-*.log`. The default Rails `.gitignore` rules (`/tmp/*` and `/log/*`) cover both, but if you maintain a custom `.gitignore` confirm both paths are excluded so they do not show up as untracked changes on every test run.

**Caveats:**

- The TCP probe above is a fallback for renderers that do not expose a health endpoint; if your renderer has one, replace the probe with an HTTP health check. A successful TCP connection only proves the port is accepting connections, not that route handlers or bundle manifests are fully initialized.
- The `start_with?` safety check on `Rails.root/tmp` compares raw paths; it does **not** resolve symlinks. If your project's `tmp/` directory is a symlink (for example, mounted to a tmpfs path), an absolute `RENDERER_SERVER_BUNDLE_CACHE_PATH` pointing inside the resolved target will fail the check. Resolve both paths with `Pathname#realpath` before comparing if you need to support a symlinked `tmp/`.
- A reset during the pre-spawn probe usually means another service is already using the port and closing connections immediately.
- The `connect_timeout` call is enough for `127.0.0.1` because an unused localhost port refuses the connection immediately. If you adapt the helper for a remote renderer, the operating system may still apply a longer TCP timeout.
- The deadline is checked after each socket probe, so very tight timeouts can overshoot by up to `connect_timeout + sleep` per iteration (roughly 1.1 s with the defaults above).
- If CI hard-kills the Ruby process before `after(:suite)` runs, clear any orphaned renderer processes or occupied renderer ports before retrying the job.
- `pgroup: true` and the negative-PID `Process.kill("-TERM", pid)` / `Process.kill("-KILL", pid)` calls are POSIX-only. On Windows they raise `NotImplementedError`, so adapt the spawn options and shutdown calls (for example, kill only the spawned PID and rely on the renderer to clean up its child) if you need to run this guide on a native Windows host. CI on Linux/macOS and WSL is unaffected.
- The helper relies on the Step 2 `configure_rspec_to_compile_assets` setup so bundles are available before renderer-backed examples run. Load `support/rsc_node_renderer` after registering `configure_rspec_to_compile_assets` so modern RSpec can trigger compilation with `when_first_matching_example_defined` before suite hooks start the renderer. Older RSpec falls back to `before(:example, metatag)`, so compile assets in your CI job before running the spec process if your launcher validates bundles at boot or your suite starts renderer-backed requests outside examples tagged for compilation.

In CI, set `RSC_NODE_RENDERER_TESTS=1` for jobs that need the renderer. For local development, leaving it unset lets you run non-RSC specs without starting another process.

### 4. Write A Capybara RSC Smoke Test

Keep the first system test boring: visit a route that streams one Server Component and assert on visible HTML plus one hydrated Client Component interaction.

For specs that must prove the browser receives streamed RSC payload chunks, use a non-proxy browser driver and keep
Puffing Billy out of the RSC payload path. See
[System Specs for Streamed RSC Payloads](../../pro/react-server-components/system-spec-streaming-rsc.md) for the
driver shape, Billy compatibility boundary, and hydration assertions.

```ruby
RSpec.describe "Story page", :rsc, :js, type: :system do
  it "renders the streamed RSC page and hydrates client controls" do
    # Replace story_path and selectors with your app's RSC route and content.
    visit story_path("ruby-rails-react")

    expect(page).to have_css("h1", text: "Ruby, Rails, and React")
    expect(page).to have_button("Save")

    click_button "Save"
    expect(page).to have_text("Saved")
  end
end
```

Request specs are still useful for the payload endpoint:

```ruby
RSpec.describe "RSC payload endpoint", :rsc, type: :request do
  it "returns an RSC payload stream" do
    # Replace this path if your app customizes config.rsc_payload_generation_url_path
    # or rsc_payload_route.
    get "/rsc_payload/StoryPage", params: { props: { slug: "ruby-rails-react" }.to_json }

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/x-ndjson")

    chunks = response.body.lines.map(&:chomp).reject(&:empty?).map { |line| JSON.parse(line) }
    # "html" is emitted by the default React on Rails RSC renderer; verify custom renderer output explicitly.
    expect(chunks).to include(include("html" => anything))
  end
end
```

### 5. Stub External APIs At The Right Boundary

Ruby stubbing tools such as WebMock and VCR only intercept requests from the Rails process. They do not intercept HTTP requests made by JavaScript running inside the separate node-renderer process.

Prefer one of these patterns:

- Fetch external data in Rails, stub it with WebMock/VCR, and pass deterministic props into the RSC tree.
- Point Node-rendered code at a local fake API server started by the test harness.
- Inject an API base URL through props or environment variables so tests never call the real service.

Avoid letting system tests depend on live third-party APIs. RSC failures from external API drift usually look like renderer timeouts or missing payload chunks, which sends debugging in the wrong direction.

### 6. Parallelization Checklist

- Use one renderer port per worker.
- Use one renderer bundle cache directory per worker.
- Clear the renderer cache before starting the renderer.
- Compile assets before the renderer accepts requests.
- Do not share a mutable fake API server across workers unless it isolates state per worker.
- If flakes remain, serialize the RSC system-test group first, then re-enable parallelism once port/cache isolation is proven.

### Minitest Equivalent

Steps 1, 2, 5, and 6 apply to Minitest unchanged, with one path adjustment: Minitest-only projects (no `spec/` directory) should place the Step 1 `RscTestWorker` module at `test/support/rsc_test_worker.rb` so the `require_relative` below resolves correctly. For Step 4, adapt the RSpec system-test example to `ApplicationSystemTestCase` with `assert_css`/`assert_text`, and the request-spec example to an `ActionDispatch::IntegrationTest` subclass with `assert_response`/`assert_equal`. Only the suite-level renderer lifecycle differs: Minitest has no `before(:suite)` hook, so the renderer starts when `test/test_helper.rb` requires its support file (after assets compile) and stops in [`Minitest.after_run`](https://github.com/minitest/minitest/blob/master/lib/minitest.rb). The Rails.root/tmp containment check, port probe, spawn options, `wait_until_ready!` helper, and graceful SIGTERM→SIGKILL shutdown are all reused from [Step 3](#3-start-one-test-renderer-per-worker).

Rails-generated Minitest apps often enable `parallelize(workers: :number_of_processors)`. The file-scope startup below assumes each worker is an independent Ruby test process that loads `test/test_helper.rb` separately, such as a `parallel_tests` CI shard. If Rails-native process parallelization remains enabled for RSC system tests, move the renderer startup and cleanup into `parallelize_setup` / `parallelize_teardown` and derive the worker ID from the hook argument, or serialize the RSC system-test group. In that Rails-native variant, keep one cleanup owner per renderer: do not leave the file-scope `Minitest.after_run` block below stopping the same PID that `parallelize_teardown` already stops.

If a CI job can run the RSpec and Minitest RSC suites at the same time, give each suite a different renderer port range. For example, keep the RSpec recipe on the default `3900 + RscTestWorker::ID.to_i` range and set a Minitest-specific base such as `3950` before the `RENDERER_PORT` assignment below.

Wire `test/test_helper.rb` with the same ENV-before-Rails-boot preamble used in `spec/rails_helper.rb`, then require the renderer lifecycle support file before any test runs. Keep the compilation check at file scope: it runs once for ordinary Minitest suites and, when `RSC_NODE_RENDERER_TESTS=1`, populates the renderer bundle cache before the support file starts the node renderer.

```ruby
# test/test_helper.rb
ENV["RAILS_ENV"] ||= "test"
# Same module as Step 1. For Minitest-only projects, create test/support/rsc_test_worker.rb
# with the same content as spec/support/rsc_test_worker.rb.
require_relative "support/rsc_test_worker"

ENV["RENDERER_PORT"] ||= (3900 + RscTestWorker::ID.to_i).to_s
renderer_url = "http://127.0.0.1:#{ENV["RENDERER_PORT"]}"
ENV["REACT_RENDERER_URL"] ||= renderer_url # used by config.renderer_url = ENV["REACT_RENDERER_URL"]
ENV["RENDERER_URL"] ||= renderer_url       # used by some older/custom initializers
ENV["RENDERER_SERVER_BUNDLE_CACHE_PATH"] ||=
  File.expand_path("../tmp/node-renderer-bundles-test-#{RscTestWorker::ID}", __dir__)

require_relative "../config/environment"
require "rails/test_help"
require "react_on_rails/test_helper"

# Run once at suite start before the optional renderer spawns.
ReactOnRails::TestHelper.ensure_assets_compiled

require_relative "support/rsc_node_renderer"
```

The renderer support file mirrors `spec/support/rsc_node_renderer.rb`. The `RscNodeRenderer` module and `wait_until_ready!` helper are framework-agnostic; if your project uses both RSpec and Minitest, extract the module to a shared file (for example, `lib/test_support/rsc_node_renderer.rb`) and require it from both helper files instead of redefining it.

```ruby
# test/support/rsc_node_renderer.rb
require "fileutils"
require "socket"
require_relative "rsc_test_worker"

module RscNodeRenderer
  module_function

  # Keep in sync with spec/support/rsc_node_renderer.rb (Step 3).
  # Keep in sync with spec/support/rsc_node_renderer.rb (Step 3).
  # Prefer extracting this to a shared file (e.g. lib/test_support/rsc_node_renderer.rb)
  # and requiring it from both helpers. Copy it here only for single-framework (Minitest-only) projects
  # where a shared lib/ location adds unnecessary indirection.
  def wait_until_ready!(host:, port:, timeout_seconds: 30, log_path: nil, pid: nil)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout_seconds
    saw_reset = false

    loop do
      begin
        Socket.tcp(host, port, connect_timeout: 1).close
        break
      rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT
        # Port not yet open; renderer still booting.
      rescue Errno::ECONNRESET
        # Connection reset: renderer bound the port but closed the connection before accepting.
        # Fall through — the PID check below will detect a dead process and raise before the deadline.
        # If the deadline expires without a successful connect, the deadline error mentions the reset
        # so a port already used by another service is easier to diagnose than a generic timeout.
        saw_reset = true
      rescue Errno::EADDRNOTAVAIL, Errno::EHOSTUNREACH, SocketError => e
        raise "Cannot reach node renderer at #{host}:#{port}. " \
              "Check the host configuration (#{e.class}: #{e.message})."
      end

      if pid
        begin
          # Heuristic early-exit check: if the launcher process has already died, raise now rather than
          # waiting for the deadline. For `pnpm run <script>`, pnpm typically stays resident while Node
          # is alive, but process managers that exec directly into Node (or daemonize) will exit here even
          # though the renderer is still starting, surfacing a misleading ESRCH. The TCP probe above is
          # the authoritative readiness signal; this check is only a fast-fail shortcut for the common
          # pnpm/npm/yarn case. Replace it with an app-specific health check if your launcher daemonizes.
          Process.kill(0, pid)
        rescue Errno::ESRCH
          hint = log_path ? " Check #{log_path} for startup errors." : ""
          raise "Node renderer process (pid #{pid}) exited before binding to #{host}:#{port}.#{hint}"
        rescue Errno::EPERM
          # Process exists but we lack permission to signal it (different UID, seccomp, container boundary).
          # Continue waiting for the TCP port — the port probe is authoritative for readiness.
        end
      end

      if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
        hint = log_path ? " Check #{log_path} for startup errors." : ""
        reset_hint = saw_reset ? " (TCP connections were reset — another process may already be using this port)" : ""
        raise "Node renderer did not boot on #{host}:#{port} within #{timeout_seconds}s.#{hint}#{reset_hint}"
      end

      sleep 0.1
    end
  end
end

# File-scope state shared by the eager startup below and the Minitest.after_run hook.
rsc_node_renderer_pid = nil
rsc_node_renderer_waiter = nil

if ENV["RSC_NODE_RENDERER_TESTS"] == "1"
  cache_path = ENV.fetch("RENDERER_SERVER_BUNDLE_CACHE_PATH") do
    raise "RENDERER_SERVER_BUNDLE_CACHE_PATH is not set. " \
          "Follow Step 1 of this guide to set it before Rails boots so every parallel worker " \
          "gets a unique renderer bundle cache directory."
  end
  cache_path = cache_path.strip
  raise "RENDERER_SERVER_BUNDLE_CACHE_PATH is empty." if cache_path.empty?

  expanded_cache_path = File.expand_path(cache_path, Rails.root.to_s)
  FileUtils.mkdir_p(Rails.root.join("tmp"))
  tmp_root = Rails.root.join("tmp").to_s
  unless expanded_cache_path.start_with?("#{tmp_root}#{File::SEPARATOR}")
    raise "RENDERER_SERVER_BUNDLE_CACHE_PATH must be inside Rails.root/tmp " \
          "(got: #{expanded_cache_path}). " \
          "This path is deleted and recreated on every test run, so only paths " \
          "inside Rails.root/tmp are permitted to prevent accidental data loss."
  end
  FileUtils.rm_rf(expanded_cache_path)
  FileUtils.mkdir_p(expanded_cache_path)

  renderer_env = {
    "NODE_ENV" => "test",
    "RAILS_ENV" => "test",
    "RENDERER_PORT" => ENV.fetch("RENDERER_PORT") do
      raise "RENDERER_PORT is not set. " \
            "Follow Step 1 of this guide to set it before Rails boots so every parallel worker " \
            "gets a unique renderer port."
    end,
    "RENDERER_SERVER_BUNDLE_CACHE_PATH" => expanded_cache_path
  }

  renderer_port = begin
    Integer(renderer_env["RENDERER_PORT"])
  rescue ArgumentError
    raise "RENDERER_PORT must be an integer port number " \
          "(got: #{renderer_env['RENDERER_PORT'].inspect})"
  end
  begin
    Socket.tcp("127.0.0.1", renderer_port, connect_timeout: 1).close
    raise "RENDERER_PORT #{renderer_env['RENDERER_PORT']} is already in use. " \
          "A previous test run may have left an orphaned node renderer. " \
          "Kill it manually or restart the CI job."
  rescue Errno::ECONNREFUSED
    # Port refused immediately — nothing is listening; safe to spawn.
  rescue Errno::ETIMEDOUT
    # SYN dropped (firewall/throttle); assume nothing is listening and proceed.
  rescue Errno::ECONNRESET
    raise "RENDERER_PORT #{renderer_env['RENDERER_PORT']} accepted and reset a connection. " \
          "Another service may already be using it."
  rescue Errno::EADDRNOTAVAIL, Errno::EHOSTUNREACH, SocketError => e
    raise "Cannot probe RENDERER_PORT #{renderer_env['RENDERER_PORT']}: #{e.class}: #{e.message}"
  end

  FileUtils.mkdir_p(Rails.root.join("log"))
  renderer_log_path = Rails.root.join("log/node-renderer-test-#{RscTestWorker::ID}.log").to_s
  rsc_node_renderer_pid = Process.spawn(
    renderer_env,
    "pnpm", # replace with "npm", "yarn", or "bun" if that is your package manager
    "run",
    "node-renderer",
    chdir: Rails.root.to_s,
    out: renderer_log_path,
    err: [:child, :out],
    pgroup: true # place pnpm and its child Node process in a new process group
  )
  rsc_node_renderer_waiter = Process.detach(rsc_node_renderer_pid)

  renderer_timeout_value = ENV.fetch("RSC_NODE_RENDERER_BOOT_TIMEOUT", "30")
  renderer_timeout = begin
    Integer(renderer_timeout_value)
  rescue ArgumentError
    raise "RSC_NODE_RENDERER_BOOT_TIMEOUT must be an integer number of seconds " \
          "(got: #{ENV['RSC_NODE_RENDERER_BOOT_TIMEOUT'].inspect})"
  end
  begin
    RscNodeRenderer.wait_until_ready!(
      host: "127.0.0.1",
      port: renderer_port,
      timeout_seconds: renderer_timeout,
      log_path: renderer_log_path,
      pid: rsc_node_renderer_pid
    )
  rescue StandardError
    begin
      Process.kill("-TERM", rsc_node_renderer_pid)
    rescue Errno::ESRCH, Errno::EPERM
      # Already stopped or no permission to signal; surfaces the original startup error.
    end
    rsc_node_renderer_waiter&.join(2)
    rsc_node_renderer_pid = nil
    rsc_node_renderer_waiter = nil
    raise
  end
end

Minitest.after_run do
  pid = rsc_node_renderer_pid
  next unless pid

  begin
    # Sends SIGTERM to the entire process group so pnpm and the Node child both stop.
    Process.kill("-TERM", pid)
    # Thread#join returns the waiter thread when the process exits, and nil on timeout.
    # SIGKILL only fires when SIGTERM did not stop the process within the join window.
    unless rsc_node_renderer_waiter&.join(5)
      begin
        Process.kill("-KILL", pid)
      rescue Errno::ESRCH
        # Stopped between the join timeout and the SIGKILL; nothing more to do.
      else
        unless rsc_node_renderer_waiter&.join(5)
          warn "Node renderer process group #{pid} did not stop after SIGKILL; " \
               "it may still occupy the renderer port for the next CI retry."
        end
      end
    end
  rescue Errno::ESRCH
    # Already stopped.
  rescue Errno::EPERM
    warn "No permission to stop node renderer process group #{pid}; " \
         "it may need manual cleanup."
  ensure
    rsc_node_renderer_pid = nil
    rsc_node_renderer_waiter = nil
  end
end
```

The [caveats listed for the RSpec recipe](#3-start-one-test-renderer-per-worker) apply equally here: the TCP probe is a fallback for renderers without a health endpoint, `pgroup: true` and the negative-PID `Process.kill` calls are POSIX-only, and CI hard-kills bypass `Minitest.after_run` so clear orphaned renderer processes or occupied ports before retrying the job. Set `RSC_NODE_RENDERER_TESTS=1` on CI jobs that need the renderer; leaving it unset lets local non-RSC Minitest runs skip the renderer entirely.

## Two Approaches to Test Asset Compilation

React on Rails supports two mutually exclusive approaches for compiling webpack assets during tests:

### Approach 1: React on Rails Test Helper + build_test_command (Recommended)

**Best for:** Most applications, especially SSR, large suites, and explicit build control

**Configuration:**

```ruby
# config/initializers/react_on_rails.rb
ReactOnRails.configure do |config|
  config.build_test_command = "RAILS_ENV=test bin/shakapacker" # NODE_ENV is derived from RAILS_ENV by Shakapacker

  # Or use your project's package manager with a custom script:
  # config.build_test_command = "pnpm run build:test"  # or: npm run build:test, yarn run build:test
end
```

In `config/shakapacker.yml`, keep test compilation off to avoid mixing approaches:

```yaml
test:
  <<: *default
  compile: false
  public_output_path: webpack/test
```

Then configure your test framework:

**RSpec:**

```ruby
# spec/rails_helper.rb
require "react_on_rails/test_helper"

RSpec.configure do |config|
  # Ensures webpack assets are compiled before the test suite runs
  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
end
```

See [lib/react_on_rails/test_helper.rb](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails/lib/react_on_rails/test_helper.rb) for more details and customization options.

By default, the helper triggers compilation for examples tagged with `:js`, `:server_rendering`, or `:controller`. You can pass custom metatags as an optional second parameter if you need compilation for other specs — for example, if you use Webpack to build CSS assets for request and feature specs:

```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config, :requires_webpack_assets)
  config.define_derived_metadata(file_path: %r{spec/(features|requests)}) do |metadata|
    metadata[:requires_webpack_assets] = true
  end
end
```

**Minitest:**

```ruby
# test/test_helper.rb
require "react_on_rails/test_helper"

class ActiveSupport::TestCase
  setup do
    ReactOnRails::TestHelper.ensure_assets_compiled
  end
end
```

Alternatively, you can use a [Minitest plugin](https://github.com/minitest/minitest/blob/master/lib/minitest/test.rb#L119) to run the check in `before_setup`:

```ruby
module MyMinitestPlugin
  def before_setup
    super
    ReactOnRails::TestHelper.ensure_assets_compiled
  end
end

class Minitest::Test
  include MyMinitestPlugin
end
```

**Asset detection settings:**

The following settings in `config/initializers/react_on_rails.rb` control how the test helper detects stale assets:

```ruby
ReactOnRails.configure do |config|
  # Define the files to check for Webpack compilation when running tests.
  config.webpack_generated_files = %w( manifest.json )

  # If you're not hashing the server bundle, include it in the list:
  # config.webpack_generated_files = %w( server-bundle.js manifest.json )
end
```

> **Important:** The `build_test_command` **must not** include the `--watch` option. If you have separate server and client bundles, the command **must** build all of them.

**How it works:**

- Compiles assets at most once per test run, and only when they're out of date (stale)
- The helper checks the Webpack-generated files folder (configured via `public_root_path` and `public_output_path` in `config/shakapacker.yml`). If the folder is missing, empty, or contains files listed in `webpack_generated_files` with `mtime`s older than any source files, assets are recompiled.
- Uses the `build_test_command` configuration
- Fails fast if compilation has errors

**Pros:**

- ✅ Explicit control over compilation timing
- ✅ Assets compiled only once per test run
- ✅ Clear error messages if compilation fails
- ✅ Can customize the build command
- ✅ Reliable for SSR tests because assets are built before first render

**Cons:**

- ⚠️ Requires additional configuration in test helpers
- ⚠️ More setup to maintain
- ⚠️ Requires `build_test_command` to be set

**When to use:**

- You want to compile assets exactly once before tests
- You need to customize the build command
- You want explicit error handling for compilation failures
- Your test suite is slow and you want to optimize compilation
- You run SSR tests and need server bundles available before first request

### Approach 2: Shakapacker Auto-Compilation (Alternative)

**Best for:** Simpler non-SSR test setups or teams that prefer minimal configuration

**Configuration:**

```yaml
# config/shakapacker.yml
test:
  <<: *default
  compile: true
  public_output_path: webpack/test
```

And remove React on Rails TestHelper wiring:

- Remove `config.build_test_command`
- Remove `ReactOnRails::TestHelper` calls in `spec/rails_helper.rb` or `test/test_helper.rb`

**How it works:**

- Shakapacker compiles assets on demand when packs are requested
- No React on Rails TestHelper setup is required

**Pros:**

- ✅ Simpler setup
- ✅ Works across frameworks without helper wiring

**Cons:**

- ⚠️ Less explicit compilation timing
- ⚠️ May compile multiple times in long or parallel runs
- ⚠️ For SSR tests, first-request ordering can matter if server bundles are not prebuilt

## Don't Mix Approaches

**Do not use both approaches together.** They are mutually exclusive:

```yaml
# config/shakapacker.yml
test:
  compile: true # ← Don't do this...
```

```ruby
# config/initializers/react_on_rails.rb
config.build_test_command = "RAILS_ENV=test bin/shakapacker"  # ← ...with this

# spec/rails_helper.rb
ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)  # ← ...and this
```

This will cause assets to be compiled multiple times unnecessarily.

## Migrating Between Approaches

### From React on Rails Test Helper → Shakapacker Auto-Compilation

1. Set `compile: true` in `config/shakapacker.yml` test section:

   ```yaml
   test:
     compile: true
     public_output_path: webpack/test
   ```

2. Remove test helper configuration from spec/test helpers:

   ```ruby
   # spec/rails_helper.rb - REMOVE these lines:
   require "react_on_rails/test_helper"
   ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
   ```

3. Remove or comment out `build_test_command` in React on Rails config:
   ```ruby
   # config/initializers/react_on_rails.rb
   # config.build_test_command = "RAILS_ENV=test bin/shakapacker"  # ← Comment out
   ```

### From Shakapacker Auto-Compilation → React on Rails Test Helper

1. Set `compile: false` in `config/shakapacker.yml` test section:

   ```yaml
   test:
     compile: false
     public_output_path: webpack/test
   ```

2. Add `build_test_command` to React on Rails config:

   ```ruby
   # config/initializers/react_on_rails.rb
   config.build_test_command = "RAILS_ENV=test bin/shakapacker"
   ```

3. Add test helper configuration:

   ```ruby
   # spec/rails_helper.rb (for RSpec)
   require "react_on_rails/test_helper"

   RSpec.configure do |config|
     ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
   end
   ```

## Verifying Your Configuration

Use the React on Rails doctor command to verify your test configuration:

```bash
bundle exec rake react_on_rails:doctor
```

To auto-apply supported test-setup fixes (recommended path), run:

```bash
FIX=true bundle exec rake react_on_rails:doctor
```

The doctor will check:

- Whether `compile: true` is set in shakapacker.yml
- Whether `build_test_command` is configured
- Whether test helpers are properly set up
- Whether each detected framework (RSpec/Minitest) is wired independently
- Whether you're accidentally using both approaches

## Troubleshooting

### Assets not compiling during tests

**Problem:** Tests fail because JavaScript/CSS assets are not compiled.

**Solution:** Check which approach you're using:

1. **If using Shakapacker auto-compilation:**

   ```yaml
   # config/shakapacker.yml
   test:
     compile: true # ← Make sure this is true
   ```

2. **If using React on Rails test helper:**
   - Verify `build_test_command` is set
   - Check that test helper is configured in spec/test helper
   - Run `bundle exec rake react_on_rails:doctor`

### Assets compiling multiple times

**Problem:** Tests are slow because assets compile repeatedly.

**Solutions:**

1. **If using Shakapacker auto-compilation:**
   - Switch to React on Rails test helper for one-time compilation
   - Or ensure `cache_manifest: true` in shakapacker.yml

2. **If using React on Rails test helper:**
   - This shouldn't happen - assets should compile only once
   - Check that you don't also have `compile: true` in shakapacker.yml

### Stale assets not recompiling

**Problem:** You added a source file but the test helper doesn't trigger recompilation.

**Cause:** The test helper compares `mtime`s of source files against generated output files. If you add a source file that has an older timestamp than the existing output (e.g., copied from another directory or restored from version control), it won't be detected as a change.

**Solution:** Clear out your Webpack-generated files directory to force recompilation:

```bash
rm -rf public/webpack/test
```

If this started after switching branches or changing package versions, run `bin/dev clean` to stop any `bin/dev` watchers and clear the relevant generated bundles and build caches. See [Generated Bundle Files and Cache Cleanup](./dev-server-and-testing.md#generated-bundle-files-and-cache-cleanup) for the command-by-command cleanup behavior.

### Build command fails

**Problem:** `build_test_command` fails with errors.

**Check:**

1. Does `bin/shakapacker` exist and is it executable?

   ```bash
   ls -la bin/shakapacker
   chmod +x bin/shakapacker  # If needed
   ```

2. Can you run the command manually?

   ```bash
   RAILS_ENV=test bin/shakapacker
   ```

3. Are your webpack configs valid for test environment?

### Test helper not found

**Problem:** `LoadError: cannot load such file -- react_on_rails/test_helper`

**Solution:** Make sure react_on_rails gem is available in test environment:

```ruby
# Gemfile
gem "react_on_rails"  # Not in a specific group

# Or explicitly in test group:
group :test do
  gem "react_on_rails"
end
```

## Performance Considerations

### Asset Compilation Speed

**Shakapacker auto-compilation:**

- Compiles on first request per test process
- May compile multiple times in parallel test environments
- Good for: Small test suites, simple webpack configs

**React on Rails test helper:**

- Compiles once before entire test suite
- Blocks test start until compilation complete
- Good for: Large test suites, complex webpack configs

### Faster Development with Watch Mode

If you're using the React on Rails test helper and want to avoid waiting for compilation on each test run, run your build command with the `--watch` flag in a separate terminal:

```bash
RAILS_ENV=test bin/shakapacker --watch

# Or with your package manager:
# pnpm run build:test --watch
# npm run build:test -- --watch
# yarn run build:test --watch
```

This keeps webpack running and recompiling automatically when files change, so your tests start faster.

> **Note:** The `--watch` flag should only be used in a separate terminal process — never include it in `build_test_command`, which must exit after compilation.

### Automatic Dev Asset Reuse (Static Mode)

When you run `bin/dev static`, React on Rails automatically detects the fresh development assets and reuses them for tests — **no extra commands or environment variables needed**.

```bash
# Terminal 1: Start static development
bin/dev static

# Terminal 2: Just run tests — they automatically use dev assets
bundle exec rspec
```

**How it works:** When `bundle exec rspec` (or Minitest) runs and test assets are stale or missing, the TestHelper checks if development assets in `public/packs/` are:

1. Present (manifest.json exists)
2. Static mode (not HMR — no `http://` URLs in manifest entries)
3. Fresh (manifest newer than all source files)

If all checks pass, React on Rails temporarily overrides Shakapacker's test config to point at the development output. You'll see:

```text
====> React on Rails: Reusing development assets from packs
      (detected fresh static-mode webpack output, skipping test compilation)
```

No `shakapacker.yml` changes are needed. The override only lasts for the test process.

### Running `bin/dev` (HMR) and Tests Together

HMR assets are served from webpack-dev-server memory and contain `http://` URLs in the manifest, so they **cannot** be reused by tests. When using HMR mode, you have two options:

**Option A: Let TestHelper compile on demand (simplest)**

```bash
# Terminal 1
bin/dev

# Terminal 2 — TestHelper runs build_test_command automatically if assets are stale
bundle exec rspec
```

This works but adds compilation time to the first test run.

**Option B: Use a test watcher for fast iteration**

```bash
# Terminal 1
bin/dev

# Terminal 2 — keeps test assets fresh in the background
bin/dev test-watch

# Terminal 3
bundle exec rspec
```

`bin/dev test-watch` auto-selects watch mode:

- `auto` (default): picks `client-only` if another shakapacker watcher is already running; otherwise `full`
- `full`: always builds test client + server bundles (`--test-watch-mode=full`)
- `client-only`: only builds test client bundles (`--test-watch-mode=client-only`)

### Which Mode Should I Use?

| Scenario                    | Recommendation                                               |
| --------------------------- | ------------------------------------------------------------ |
| General development         | `bin/dev static` — simpler, no FOUC, tests just work         |
| Need Hot Module Replacement | `bin/dev` + `bin/dev test-watch` for fast test iteration     |
| CI / no dev server running  | Just `bundle exec rspec` — TestHelper compiles automatically |
| Only running a few tests    | `bin/dev static` + `bundle exec rspec spec/path/to_spec.rb`  |

### Migration to `bin/dev test-watch`

If you previously ran manual test watcher commands, migrate to the new wrapper:

- Old: `RAILS_ENV=test bin/shakapacker --watch`
- New: `bin/dev test-watch`

- Old: `RAILS_ENV=test CLIENT_BUNDLE_ONLY=yes bin/shakapacker --watch`
- New: `bin/dev test-watch --test-watch-mode=client-only`

### Advanced: Manual Shared Output (Alternative)

If you prefer to manually share output paths instead of using automatic detection:

1. Set the test output path equal to development in `config/shakapacker.yml`:

   ```yaml
   development:
     public_output_path: packs

   test:
     public_output_path: packs
   ```

2. Run static development mode and tests:

   ```bash
   bin/dev static    # Terminal 1
   bundle exec rspec # Terminal 2
   ```

> [!WARNING]
> Do not share output paths with `bin/dev` (HMR mode) — HMR manifests will cause test failures.

### Caching Strategies

Improve compilation speed with caching:

```yaml
# config/shakapacker.yml
test:
  cache_manifest: true # Cache manifest between runs
```

### Parallel Testing

When running tests in parallel (with `parallel_tests` gem):

**Shakapacker auto-compilation:**

- Each process compiles independently (may be slow)
- Consider precompiling assets before running parallel tests:
  ```bash
  RAILS_ENV=test bin/shakapacker
  bundle exec rake parallel:spec
  ```

**React on Rails test helper:**

- Compiles once before forking processes (efficient)
- Works well out of the box with parallel testing

## CI/CD Considerations

### GitHub Actions / GitLab CI

**Option 1: Precompile before tests**

```yaml
- name: Compile test assets
  run: RAILS_ENV=test bundle exec rake react_on_rails:assets:compile_environment

- name: Run tests
  run: bundle exec rspec
```

**Option 2: Use Shakapacker auto-compilation**

```yaml
# config/shakapacker.yml
test:
  compile: true

# CI workflow
- name: Run tests (assets auto-compile)
  run: bundle exec rspec
```

### Docker

When running tests in Docker, consider:

1. Caching `node_modules` between builds
2. Precompiling assets in Docker build stage
3. Using bind mounts for local development

## Best Practices

1. **Choose one approach** - Don't mix Shakapacker auto-compilation with React on Rails test helper
2. **Use doctor command** - Run `rake react_on_rails:doctor` to verify configuration
3. **Precompile in CI** - Consider precompiling assets before running tests in CI
4. **Cache node_modules** - Speed up installation with caching
5. **Monitor compile times** - If tests are slow, check asset compilation timing

## Summary Decision Matrix

| Scenario             | Recommendation                           |
| -------------------- | ---------------------------------------- |
| Default setup        | React on Rails test helper               |
| SSR test coverage    | React on Rails test helper               |
| Large test suite     | React on Rails test helper               |
| Parallel testing     | React on Rails test helper or precompile |
| CI/CD pipeline       | Precompile before tests                  |
| Quick local tests    | Shakapacker `compile: true`              |
| Custom build command | React on Rails test helper               |

## Related Documentation

- [Dev Server and Testing](./dev-server-and-testing.md) — How `bin/dev` (HMR vs static) interacts with Capybara, Playwright, Minitest system tests, and SSR request specs
- [Configuration Reference](../configuration/README.md#build_test_command)
- [Shakapacker Configuration](https://github.com/shakacode/shakapacker#configuration)
- [TestHelper Source Code](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails/lib/react_on_rails/test_helper.rb)

## Need Help?

- **Forum:** [ShakaCode Forum](https://forum.shakacode.com/)
- **Docs:** [React on Rails Guides](https://reactonrails.com/docs/)
- **Support:** [justin@shakacode.com](mailto:justin@shakacode.com)

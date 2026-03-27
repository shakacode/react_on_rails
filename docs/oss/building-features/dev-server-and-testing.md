# HMR, Dev Server Modes, and Testing

> Run `bin/dev --help` for all development server modes and options.

`bin/dev` starts your Rails server alongside webpack-dev-server with Hot Module Replacement (HMR) by default. HMR is great for development — changes appear instantly in the browser — but it affects how tests find compiled assets. This guide covers how each `bin/dev` mode interacts with your test framework and how to configure things so tests work reliably.

Your test setup depends on which testing framework you use. Pick your path:

- [**Capybara / Rails System Tests**](#capybara--rails-system-tests-rspec-and-minitest) — Standard Rails integration tests. Capybara boots its own server; assets must be on disk.
- [**Playwright / Cypress E2E**](#playwright--cypress-e2e) — External browser tools that connect to your running dev server. Any `bin/dev` mode works.

## How `bin/dev` Modes Affect Tests

`bin/dev` defaults to HMR mode (Hot Module Replacement). HMR serves JavaScript from webpack-dev-server's memory at `http://localhost:3035` — great for development, but those assets don't exist as files on disk.

| `bin/dev` Mode           | Assets on disk?                                | Capybara tests work?                            | Playwright/Cypress work? |
| ------------------------ | ---------------------------------------------- | ----------------------------------------------- | ------------------------ |
| `bin/dev` (HMR, default) | No — in memory only                            | Only with TestHelper (auto-compiles separately) | Yes                      |
| `bin/dev static`         | Yes — written to `public/webpack/development/` | Yes — auto-detected and reused                  | Yes                      |
| `bin/dev test-watch`     | Yes — written to `public/webpack/test/`        | Yes                                             | Yes                      |

**The key takeaway:** With [TestHelper properly configured](#test-helper-configuration), all `bin/dev` modes work with all test types. TestHelper auto-compiles test assets when needed, regardless of whether HMR or static mode is running.

## Capybara / Rails System Tests (RSpec and Minitest)

Capybara boots its **own** Puma server for each test run. That server reads `manifest.json` to find asset paths, so assets must exist as files on disk. HMR manifests contain `http://localhost:3035/...` URLs that Capybara's Puma can't serve — but this doesn't matter if TestHelper is configured, because it compiles separate test assets.

### Making It Just Work

Configure TestHelper once, and Capybara tests work with any `bin/dev` mode — or no dev server at all:

**1. Set the build command:**

```ruby
# config/initializers/react_on_rails.rb
ReactOnRails.configure do |config|
  config.build_test_command = "RAILS_ENV=test bin/shakapacker"
end
```

**2. Wire TestHelper into your test framework:**

```ruby
# spec/rails_helper.rb (RSpec)
require "react_on_rails/test_helper"

RSpec.configure do |config|
  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
end
```

```ruby
# test/test_helper.rb (Minitest)
require "react_on_rails/test_helper"

class ActiveSupport::TestCase
  setup do
    ReactOnRails::TestHelper.ensure_assets_compiled
  end
end
```

**3. Use separate output paths** (the default). These are the key settings — see your full `shakapacker.yml` for the complete config:

```yaml
# config/shakapacker.yml (key differences only)
development:
  public_output_path: webpack/development

test:
  compile: false # TestHelper handles compilation
  public_output_path: webpack/test # Must differ from development
```

That's it. Now:

```bash
bin/dev              # Terminal 1 — develop with HMR as usual
bundle exec rspec    # Terminal 2 — TestHelper auto-compiles test assets
```

### Speeding Up Test Runs

TestHelper compiles once per test run when assets are stale. To skip this wait:

```bash
bin/dev static           # Assets written to disk, auto-reused by tests (fastest)
# OR
bin/dev test-watch       # Keeps test assets fresh in background alongside HMR
```

When `bin/dev static` is running, `DevAssetsDetector` automatically reuses those assets — no compilation step needed at all.

## Playwright / Cypress E2E

Playwright and Cypress launch a real browser that connects to your running Rails server via HTTP. The browser fetches JavaScript from wherever the HTML points — including `http://localhost:3035` when HMR is active.

**Any `bin/dev` mode works.** Just start your server and run tests:

```bash
bin/dev              # Terminal 1 (HMR or static — both work)
pnpm test:e2e        # Terminal 2
```

### Playwright Configuration

```js
// playwright.config.js
export default defineConfig({
  use: {
    baseURL: 'http://localhost:3000/',
  },
  webServer: {
    command: 'bin/dev static',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120 * 1000,
  },
});
```

The `webServer` block starts `bin/dev static` if no server is already running. Locally it reuses your running dev server; in CI it always starts fresh.

## CI (No Dev Server)

In CI there's no dev server. TestHelper compiles assets automatically:

```bash
bundle exec rspec   # TestHelper runs build_test_command if assets are stale
```

Or precompile explicitly for faster parallel runs:

```bash
RAILS_ENV=test bin/shakapacker
bundle exec rspec
```

## Test Helper Configuration

Full configuration reference — see [Testing Configuration](./testing-configuration.md) for `build_test_command` vs `compile: true` and all options.

**RSpec** — add to `spec/rails_helper.rb`:

```ruby
require "react_on_rails/test_helper"

RSpec.configure do |config|
  # Compiles assets before first test that needs them.
  # Triggers for :js, :server_rendering, and :controller specs by default.
  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)

  # Optional: also trigger for request/feature specs that need webpack assets
  # ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config, :requires_webpack_assets)
  # config.define_derived_metadata(file_path: %r{spec/(features|requests)}) do |metadata|
  #   metadata[:requires_webpack_assets] = true
  # end
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

**Config** — add to `config/initializers/react_on_rails.rb`:

```ruby
ReactOnRails.configure do |config|
  # Command to compile test assets. Runs automatically when assets are stale.
  config.build_test_command = "RAILS_ENV=test bin/shakapacker"

  # Files to check when determining if assets are stale (default: manifest.json)
  # config.webpack_generated_files = %w(manifest.json)
end
```

## Advanced: External Server Mode

If you want Capybara to connect to your running dev server instead of starting its own, you get the benefit of HMR working during tests — the browser goes through the full dev stack. The tradeoff: `bin/dev` must be running for tests to pass.

Use an environment variable to toggle this so CI still boots its own server:

```ruby
# spec/rails_helper.rb
if ENV["CAPYBARA_EXTERNAL_SERVER"]
  # Local development: connect to your running `bin/dev` server.
  # Start `bin/dev` first, then run tests with:
  #   CAPYBARA_EXTERNAL_SERVER=1 bundle exec rspec
  Capybara.app_host = "http://localhost:3000"
  Capybara.run_server = false
else
  # CI and default: Capybara boots its own Puma server.
  # TestHelper compiles test assets automatically.
end
```

**Local usage** — start your dev server, then run tests with the env var:

```bash
bin/dev                                          # Terminal 1 — HMR running
CAPYBARA_EXTERNAL_SERVER=1 bundle exec rspec     # Terminal 2 — tests use your dev server
```

**CI** — no env var needed, tests run as normal:

```bash
bundle exec rspec    # Capybara boots its own server, TestHelper compiles assets
```

## Verifying Your Setup

```bash
bundle exec rake react_on_rails:doctor      # Check for misconfigurations
FIX=true bundle exec rake react_on_rails:doctor  # Auto-fix common issues
```

The doctor detects:

- Missing or conflicting test asset compilation settings
- Shared output paths with HMR enabled
- Minitest system tests without `ensure_assets_compiled`
- External server mode (`Capybara.run_server = false`)

## Troubleshooting

Each error includes a link to this documentation and suggests `bin/dev --help`.

### `React on Rails: build_test_command is not configured.`

```text
React on Rails: build_test_command is not configured.

You are using the React on Rails test helper (configure_rspec_to_compile_assets
or ensure_assets_compiled), but config.build_test_command is not set.
```

**Fix:** Add `config.build_test_command = "RAILS_ENV=test bin/shakapacker"` to `config/initializers/react_on_rails.rb`, or switch to `compile: true` in `shakapacker.yml` and remove the TestHelper calls.

### `React on Rails: Stale test assets detected`

```text
React on Rails: Stale test assets detected:
  public/webpack/test/manifest.json

Compiling with: `RAILS_ENV=test bin/shakapacker`
```

This is informational — compilation starts automatically. To skip the wait, run `bin/dev static` or `bin/dev test-watch` in another terminal.

### `React on Rails: Development assets use HMR`

```text
React on Rails: Development assets use HMR (manifest contains http:// URLs).
HMR assets cannot be reused for tests — they exist in webpack-dev-server memory, not on disk.
```

**Fix:** Use `bin/dev static` instead, or run `bin/dev test-watch` alongside HMR. If you have TestHelper configured, this is just informational — it will compile test assets separately.

### `React on Rails: Error building webpack assets!`

```text
React on Rails: Error building webpack assets!

The build_test_command failed. This means test assets could not be compiled.
```

**Fix:** Check the build output above this message for the actual webpack error. Quick workaround: `bin/dev static` or `RAILS_ENV=test bin/shakapacker` to compile manually.

### Blank pages in Capybara system tests (no Ruby error)

This happens when HMR manifest URLs end up in the test asset path. The manifest resolves but points to `http://localhost:3035/...`, which Capybara's Puma can't serve. The browser gets 404s for JS/CSS, resulting in blank pages.

**Fix:** Ensure test and development use separate `public_output_path` values in `shakapacker.yml`. Run `bundle exec rake react_on_rails:doctor` to detect this.

### `Shakapacker::Manifest::MissingEntryError`

```text
Shakapacker::Manifest::MissingEntryError: Shakapacker can't find application.js in
/path/to/public/webpack/test/manifest.json
```

No assets have been compiled at all. **Fix:** Wire up TestHelper (see [Test Helper Configuration](#test-helper-configuration)), or compile manually: `RAILS_ENV=test bin/shakapacker`.

## How It Works Under the Hood

When tests run, TestHelper checks if assets are stale. If they are, it tries `DevAssetsDetector` first:

1. Is `public/webpack/development/manifest.json` present?
2. Does it contain relative paths (not `http://` HMR URLs)?
3. Is it newer than all source files?

If all three pass, Shakapacker's test config is temporarily overridden to read from the development output (zero compilation). If not, `build_test_command` runs.

## Related Documentation

- [Testing Configuration](./testing-configuration.md) — `build_test_command` vs `compile: true` in detail
- [HMR and Hot Reloading](./hmr-and-hot-reloading-with-the-webpack-dev-server.md) — Setting up HMR
- [Process Managers](./process-managers.md) — Foreman/overmind for `bin/dev`

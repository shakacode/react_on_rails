# React on Rails Configuration Options

This document describes all configuration options for React on Rails. Configuration is done in `/config/initializers/react_on_rails.rb`.

> **💡 Good News!** Most applications only need 2-3 configuration options. React on Rails provides sensible defaults for everything else.

## Quick Start

See [Essential Configuration](#essential-configuration) below for the minimal configuration options you'll commonly use. Most applications only need 1-2 settings!

## Prerequisites

### `/config/shakapacker.yml`

First, you should have a `/config/shakapacker.yml` setup.

Here is the setup when using the recommended `/` directory for your `node_modules` and source files:

```yaml
# Note: Base output directory of /public is assumed for static files
default: &default
  compile: false
  # Used in your Webpack configuration. Must be created in the
  # public_output_path folder
  manifest: manifest.json
  cache_manifest: false

  # Source path is used to check if Webpack compilation needs to be run for `compile: true`
  source_path: client/app

development:
  <<: *default
  # Generated files for development, in /public/webpack/dev
  public_output_path: webpack/dev

test:
  <<: *default
  # Ensure that shakapacker invokes Webpack to build files for tests if not using the
  #   ReactOnRails rspec helper.
  compile: true

  # Generated files for tests, in /public/webpack/test
  public_output_path: webpack/test

production:
  <<: *default
  # Generated files for production, in /public/webpack/production
  public_output_path: webpack/production
  cache_manifest: true
```

## Configuration Categories

React on Rails configuration options are organized into two categories:

### Essential Configuration

Options you'll commonly configure for most applications:

- `server_bundle_js_file` - Server rendering bundle (recommended)
- `build_test_command` - Test environment build command (used with `ReactOnRails::TestHelper.configure_rspec_to_compile_assets`)

### Advanced Configuration

Options with sensible defaults that rarely need changing:

- Component loading strategies (auto-configured based on Pro license)
- Server bundle security and organization
- I18n configuration
- Server rendering pool settings
- Custom rendering extensions
- And more...

See sections below for complete documentation of all options.

## Essential Configuration

Here's a representative `/config/initializers/react_on_rails.rb` setup for essential options:

```ruby
# frozen_string_literal: true

ReactOnRails.configure do |config|
  ################################################################################
  # Server Rendering (Recommended)
  ################################################################################
  # This is the file used for server rendering of React when using `prerender: true`
  # Set to "" if you are not using server rendering
  config.server_bundle_js_file = "server-bundle.js"

  ################################################################################
  # Test Configuration
  # Used with ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
  # This controls what command is run to build assets during tests
  ################################################################################
  config.build_test_command = "RAILS_ENV=test bin/shakapacker"

  #
  # React Server Components and Streaming SSR are React on Rails Pro features.
  # For detailed configuration of RSC and streaming features, see:
  # https://github.com/shakacode/react_on_rails/blob/master/react_on_rails_pro/docs/configuration.md
  #
  # Key Pro configurations (configured in ReactOnRailsPro.configure block):
  # - rsc_bundle_js_file: Path to RSC bundle
  # - react_client_manifest_file: Client component manifest for RSC
  # - react_server_client_manifest_file: Server manifest for RSC
  # - enable_rsc_support: Enable React Server Components
  #
  # See Pro documentation for complete setup instructions.

  ################################################################################
  # SERVER BUNDLE SECURITY AND ORGANIZATION
  ################################################################################

  # ⚠️ RECOMMENDED: Use Shakapacker 9.0+ for Automatic Configuration
  #
  # For Shakapacker 9.0+, add to config/shakapacker.yml:
  #   private_output_path: ssr-generated
  #
  # React on Rails will automatically detect and use this value, eliminating the need
  # to configure server_bundle_output_path here. This provides a single source of truth.
  #
  # For older Shakapacker versions or custom setups, manually configure:
  # This configures the directory (relative to the Rails root) where the server bundle will be output.
  # By default, this is "ssr-generated". If set to nil, the server bundle will be loaded from the same
  # public directory as client bundles. For enhanced security, use this option in conjunction with
  # `enforce_private_server_bundles` to ensure server bundles are only loaded from private directories
  # config.server_bundle_output_path = "ssr-generated"

  # When set to true, React on Rails will only load server bundles from private, explicitly
  # configured directories (such as `ssr-generated`), and will raise an error if a server
  # bundle is found in a public or untrusted location. This helps prevent accidental or
  # malicious execution of untrusted JavaScript on the server, and is strongly recommended
  # for production environments. Also prevents leakage of server-side code to the client
  # (especially important for React Server Components).
  # Default is false for backward compatibility, but enabling this option is a best practice
  # for security.
  config.enforce_private_server_bundles = false

  ################################################################################
  # BUNDLE ORGANIZATION EXAMPLES
  ################################################################################
  #
  # This configuration creates a clear separation between client and server assets:
  #
  # CLIENT BUNDLES (Public, Web-Accessible):
  #   Location: public/webpack/[environment]/ or public/packs/ (According to your shakapacker.yml configuration)
  #   Files: application.js, manifest.json, CSS files
  #   Served by: Web server directly
  #   Access: ReactOnRails::Utils.public_bundles_full_path
  #
  # SERVER BUNDLES (Private, Server-Only):
  #   Location: ssr-generated/ (when server_bundle_output_path configured)
  #   Files: server-bundle.js, rsc-bundle.js
  #   Served by: Never served to browsers
  #   Access: ReactOnRails::Utils.server_bundle_js_file_path
  #
  # Example directory structure with recommended configuration:
  #   app/
  #   ├── ssr-generated/           # Private server bundles
  #   │   ├── server-bundle.js
  #   │   └── rsc-bundle.js
  #   └── public/
  #       └── webpack/development/ # Public client bundles
  #           ├── application.js
  #           ├── manifest.json
  #           └── styles.css
  #
  ################################################################################

  # `prerender` means server-side rendering
  # default is false. This is an option for view helpers `render_component` and `render_component_hash`.
  # Set to true to change the default value to true.
  config.prerender = false

  # THE BELOW OPTIONS FOR SERVER-SIDE RENDERING RARELY NEED CHANGING
  #
  # This value only affects server-side rendering when using the webpack-dev-server
  # If you are hashing the server bundle and you want to use the same bundle for client and server,
  # you'd set this to `true` so that React on Rails reads the server bundle from the webpack-dev-server.
  # Normally, you have different bundles for client and server, thus, the default is false.
  # Furthermore, if you are not hashing the server bundle (not in the manifest.json), then React on Rails
  # will only look for the server bundle to be created in the typical file location, typically by
  # a `shakapacker --watch` process.
  # If true, ensure that in config/shakapacker.yml that you have both dev_server.hmr and
  # dev_server.inline set to false.
  config.same_bundle_for_client_and_server = false

  # If set to true, this forces Rails to reload the server bundle if it is modified
  # Default value is Rails.env.development?
  # You probably will never change this.
  config.development_mode = Rails.env.development?

  # For server rendering so that the server-side console replays in the browser console.
  # This can be set to false so that server side messages are not displayed in the browser.
  # Default is true. Be cautious about turning this off, as it can make debugging difficult.
  # Default value is true
  config.replay_console = true

  # Default is true. Logs server rendering messages to Rails.logger.info. If false, you'll only
  # see the server rendering messages in the browser console.
  config.logging_on_server = true

  # Default is true only for development? to raise exception on server if the JS code throws for
  # server rendering. The reason is that the server logs will show the error and force you to fix
  # any server rendering issues immediately during development.
  config.raise_on_prerender_error = Rails.env.development?

  # This configuration allows logic to be applied to client rendered props, such as stripping props that are only used during server rendering.
  # Add a module with an adjust_props_for_client_side_hydration method that expects the component's name & props hash
  # See below for an example definition of RenderingPropsExtension
  config.rendering_props_extension = RenderingPropsExtension

  ################################################################################
  # Server Renderer Configuration for ExecJS
  ################################################################################
  # The default server rendering is ExecJS, by default using Node.js runtime
  # If you wish to use an alternative Node server rendering for higher performance,
  # contact justin@shakacode.com for details.
  #
  # For ExecJS:
  # You can configure your pool of JS virtual machines and specify where it should load code:
  # On MRI, use `node.js` runtime for the best performance
  # (see https://github.com/shakacode/react_on_rails/issues/1438)
  # Also see https://github.com/shakacode/react_on_rails/issues/1457#issuecomment-1165026717 if using `mini_racer`
  # On MRI, you'll get a deadlock with `pool_size` > 1
  # If you're using JRuby, you can increase `pool_size` to have real multi-threaded rendering.
  config.server_renderer_pool_size = 1 # increase if you're on JRuby
  config.server_renderer_timeout = 20 # seconds

  ################################################################################
  ################################################################################
  # FILE SYSTEM BASED COMPONENT REGISTRY
  # `render_component` and `render_component_hash` view helper methods can
  # auto-load the bundle for the generated component, to avoid having to specify the
  # bundle manually for each view with the component.
  #
  # SHAKAPACKER VERSION REQUIREMENTS:
  # - Basic pack generation: Shakapacker 6.5.1+
  # - Advanced auto-registration with nested entries: Shakapacker 7.0.0+
  # - Async loading support: Shakapacker 8.2.0+
  #
  # Feature Compatibility Matrix:
  # | Shakapacker Version | Basic Pack Generation | Auto-Registration | Nested Entries | Async Loading |
  # |-------------------|----------------------|-------------------|----------------|---------------|
  # | 6.5.1 - 6.9.x     | ✅ Yes                | ❌ No              | ❌ No           | ❌ No          |
  # | 7.0.0 - 8.1.x     | ✅ Yes                | ✅ Yes             | ✅ Yes          | ❌ No          |
  # | 8.2.0+            | ✅ Yes                | ✅ Yes             | ✅ Yes          | ✅ Yes         |
  #
  ################################################################################
  # components_subdirectory is the name of the subdirectory matched to detect and register components automatically
  # The default is nil. You can enable the feature by updating it in the next line.
  config.components_subdirectory = nil
  # Change to a value like this example to enable this feature
  # config.components_subdirectory = "ror_components"

  # stores_subdirectory is the name of the subdirectory matched to detect and register Redux stores automatically.
  # Works the same way as components_subdirectory but for Redux stores used with the `redux_store` helper.
  # Note: Redux stores are less common since React Hooks were introduced. Most new apps use
  # components without Redux. Only configure this if your app uses Redux stores.
  # The default is nil. You can enable the feature by updating it in the next line.
  config.stores_subdirectory = nil
  # Change to a value like this example to enable this feature
  # config.stores_subdirectory = "ror_stores"

  # Default is false.
  # The default can be overridden as an option in calls to view helpers
  # `react_component`, `react_component_hash`, and `redux_store`.
  # You may set to true to change the default to auto loading.
  # NOTE: Requires Shakapacker 6.5.1+ for basic functionality, 7.0.0+ for full auto-registration features.
  # See version requirements matrix above for complete feature compatibility.
  config.auto_load_bundle = false

  # Default is false
  # Set this to true & instead of trying to import the generated server components into your existing
  # server bundle entrypoint, the PacksGenerator will create a server bundle entrypoint using
  # config.server_bundle_js_file for the filename.
  config.make_generated_server_bundle_the_entrypoint = false

  # Configuration for how generated component packs are loaded.
  # Options: :sync, :async, :defer
  # - :sync (default for Shakapacker < 8.2.0): Loads scripts synchronously
  # - :async (default for Shakapacker ≥ 8.2.0): Loads scripts asynchronously for better performance
  # - :defer: Defers script execution until after page load
  config.generated_component_packs_loading_strategy = :async

  # DEPRECATED: Use `generated_component_packs_loading_strategy` instead.
  # Migration: `defer_generated_component_packs: true` → `generated_component_packs_loading_strategy: :defer`
  # Migration: `defer_generated_component_packs: false` → `generated_component_packs_loading_strategy: :sync`
  # See [16.0.0 Release Notes](docs/release-notes/16.0.0.md) for more details.
  # config.defer_generated_component_packs = false

  ################################################################################
  # DEPRECATED CONFIGURATION
  ################################################################################
  # 🚫 DEPRECATED: immediate_hydration is no longer used
  #
  # This configuration option has been removed. Immediate hydration is now
  # automatically enabled for React on Rails Pro users and cannot be disabled.
  #
  # If you still have this in your config, it will log a deprecation warning:
  # config.immediate_hydration = false  # ⚠️ Logs warning, has no effect
  #
  # Action Required: Remove this line from your config/initializers/react_on_rails.rb
  # See CHANGELOG.md for migration instructions.
  #
  # Historical Context:
  # Previously controlled whether Pro components hydrated immediately upon their
  # server-rendered HTML reaching the client, vs waiting for full page load.

  ################################################################################
  # I18N OPTIONS
  ################################################################################
  # Replace the following line to the location where you keep translation.js & default.js for use
  # by the npm packages react-intl. Be sure this directory exists!
  # config.i18n_dir = Rails.root.join("client", "app", "libs", "i18n")
  #
  # If not using the i18n feature, then leave this section commented out or set the value
  # of config.i18n_dir to nil.
  #
  # Replace the following line to the location where you keep your client i18n yml files
  # that will source for automatic generation on translations.js & default.js
  # By default(without this option) all yaml files from Rails.root.join("config", "locales")
  # and installed gems are loaded
  config.i18n_yml_dir = Rails.root.join("config", "locales")

  # Possible output formats are js and json
  # The default format is json
  config.i18n_output_format = 'json'

  # Possible YAML.safe_load options pass-through for locales
  # config.i18n_yml_safe_load_options = { permitted_classes: [Symbol] }

  ################################################################################
  ################################################################################
  # TEST CONFIGURATION OPTIONS
  # Below options are used with the use of this test helper:
  # ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
  #
  # NOTE:
  # Instead of using this test helper, you may ensure fresh test files using Shakapacker via:
  # 1. Have `config/webpack/test.js` exporting an array of objects to configure both client and server bundles.
  # 2. Set the compile option to true in config/shakapacker.yml for env test
  ################################################################################

  # If you are using this in your spec_helper.rb (or rails_helper.rb):
  #
  # ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
  #
  # with rspec then this controls what yarn command is run
  # to automatically refresh your Webpack assets on every test run.
  #
end
```

### server_bundle_js_file

**Type:** String
**Default:** `""`
**Required for:** Server-side rendering

The filename of your server bundle used for server-side rendering with `prerender: true`.

- Set to `"server-bundle.js"` if using server rendering
- Set to `""` if not using server rendering
- This file is used by React on Rails' JavaScript execution pool for server rendering

Note: There should be ONE server bundle that can render all your server-rendered components, unlike client bundles where you minimize size.

### build_test_command

**Type:** String
**Default:** `""`
**Used with:** `ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)`

**Important:** This option is only needed if you're using the React on Rails test helper. The two approaches below are **mutually exclusive** - use one or the other, not both.

#### Recommended Approach: Shakapacker Auto-Compilation

Set `compile: true` in `config/shakapacker.yml` for the test environment. Shakapacker will automatically compile assets before running tests:

```yaml
test:
  compile: true
  public_output_path: webpack/test
```

**Pros:**

- Simpler configuration (no extra setup in spec helpers)
- Managed by Shakapacker directly
- Automatically integrates with Rails test environment

**Cons:**

- Less explicit control over when compilation happens
- May compile more often than necessary

#### Alternative Approach: React on Rails Test Helper

Use `build_test_command` with `ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)` if you need explicit control:

```ruby
# config/initializers/react_on_rails.rb
config.build_test_command = "RAILS_ENV=test bin/shakapacker"
```

```ruby
# spec/rails_helper.rb (or spec_helper.rb)
require "react_on_rails/test_helper"

RSpec.configure do |config|
  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
end
```

**Pros:**

- Explicit control over compilation timing
- Only compiles once before test suite runs
- Can customize the build command

**Cons:**

- Requires additional setup in spec helpers
- More configuration to maintain

For more details on testing configuration, see the [Testing Configuration Guide](../building-features/testing-configuration.md).

## File-Based Component Registry

If you have many components and want to avoid manually managing webpack entry points for each one, React on Rails can automatically generate component packs based on your file system structure. This feature is particularly useful for large applications with dozens of components. Redux store auto-registration is also supported (see the linked guide).

For complete information about the file-based component registry feature (including `components_subdirectory`, `auto_load_bundle`, and `make_generated_server_bundle_the_entrypoint` configuration options), see:

[Auto-Bundling: File-System-Based Automated Bundle Generation](../core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md)

## Advanced Configuration

The following sections document advanced configuration options. Most applications won't need to change these as they have sensible defaults.

### Component Loading Strategy

#### generated_component_packs_loading_strategy

**Type:** Symbol (`:async`, `:defer`, or `:sync`)
**Default:** `:async` for Pro users with Shakapacker 8.2.0+, `:defer` for non-Pro users, `:sync` for older Shakapacker
**Auto-configured:** ✅ Yes

Controls how generated component pack scripts are loaded:

- `:async` - Loads scripts asynchronously (Pro users, best performance)
- `:defer` - Defers script execution until after page load (non-Pro users)
- `:sync` - Loads scripts synchronously (fallback for Shakapacker < 8.2.0)

**You typically don't need to set this** - React on Rails automatically selects the best strategy based on your Pro license status and Shakapacker version.

**When to override:** Only change this if you have specific performance requirements or constraints. For example, you might use `:defer` if you need to ensure all page content loads before scripts execute, or `:sync` for testing purposes.

```ruby
config.generated_component_packs_loading_strategy = :defer
```

### Server Bundle Security and Organization

#### server_bundle_output_path

**Type:** String or nil
**Default:** `"ssr-generated"`

> ⚠️ **DO NOT change this setting unless you have a specific reason.** The default is correct for virtually all applications.

Directory (relative to Rails root) where server bundles are output.

```ruby
# No need to set this - the default is recommended
# config.server_bundle_output_path = "ssr-generated"
```

- When set to a string: Server bundles output to this directory (e.g., `ssr-generated/`)
- When `nil`: Server bundles loaded from same public directory as client bundles (not recommended)

The default `"ssr-generated"` keeps server bundles separate from public assets for security.

#### enforce_private_server_bundles

**Type:** Boolean
**Default:** `false`
**Recommended for production:** `true`

When true, React on Rails only loads server bundles from private directories (configured via `server_bundle_output_path`), preventing accidental exposure of server code:

```ruby
config.enforce_private_server_bundles = true
```

Benefits:

- Prevents server-side code from being web-accessible
- Protects against malicious JavaScript execution
- Especially important for React Server Components

### Production Build

#### build_production_command

**Type:** String or Module
**Default:** `nil`
**Typical usage:** Only if customizing asset compilation

Command to run during `assets:precompile` to build production assets:

```ruby
config.build_production_command = "RAILS_ENV=production bin/shakapacker"
```

**Important:** When setting this, you must disable Shakapacker's precompile by setting `shakapacker_precompile: false` in `config/shakapacker.yml`.

**Most apps don't need this** - Shakapacker handles asset compilation automatically.

### Common Configuration

These are commonly used configuration options that many applications will need:

#### rendering_extension

**Type:** Module
**Default:** `nil`

Module that adds custom values to the `railsContext` object passed to all components:

```ruby
module RenderingExtension
  def self.custom_context(view_context)
    {
      somethingUseful: view_context.session[:something_useful],
      currentUser: view_context.current_user&.as_json
    }
  end
end

config.rendering_extension = RenderingExtension
```

#### rendering_props_extension

**Type:** Module
**Default:** `nil`

Module that modifies props for client-side hydration (useful for stripping server-only props):

```ruby
module RenderingPropsExtension
  def self.adjust_props_for_client_side_hydration(component_name, props)
    component_name == 'HelloWorld' ? props.except(:server_side_only) : props
  end
end

config.rendering_props_extension = RenderingPropsExtension
```

### Server Rendering Options

#### prerender

**Type:** Boolean
**Default:** `false`

Global default for server-side rendering. When true, all `react_component` calls will server render by default.

**Most apps prefer to set this at the `react_component` call level** rather than globally:

```ruby
# Preferred: Set per-component
react_component("MyComponent", prerender: true)
```

To set a global default:

```ruby
config.prerender = true  # Server render all components by default
```

You can override the global setting per-component:

```ruby
react_component("MyComponent", prerender: false)  # Skip SSR for this component
```

### Development and Debugging

#### trace

**Type:** Boolean
**Default:** `Rails.env.development?`
**Auto-configured:** ✅ Yes

Enables detailed logging for server rendering, including stack traces for setTimeout/setInterval calls:

```ruby
config.trace = Rails.env.development?  # default
```

#### development_mode

**Type:** Boolean
**Default:** `Rails.env.development?`
**Auto-configured:** ✅ Yes

Forces Rails to reload server bundle when modified:

```ruby
config.development_mode = Rails.env.development?  # default
```

#### replay_console

**Type:** Boolean
**Default:** `true`

When true, server-side console messages replay in the browser console. This is valuable for debugging server-rendering issues.

```ruby
config.replay_console = true  # default
```

**When to disable:** You might set this to `false` in production if console logs contain sensitive data or to reduce client-side payload size.

#### logging_on_server

**Type:** Boolean
**Default:** `true`

Logs server rendering messages to `Rails.logger.info`:

```ruby
config.logging_on_server = true  # default
```

**Pro Node Renderer Note:** When using the Pro Node Renderer, you might set this to `false` to avoid duplication of logs, as the Node Renderer handles its own logging.

#### raise_on_prerender_error

**Type:** Boolean
**Default:** `Rails.env.development?`
**Auto-configured:** ✅ Yes

Raises exceptions when JavaScript errors occur during server rendering (development only by default):

```ruby
config.raise_on_prerender_error = Rails.env.development?  # default
```

### Development Server (bin/dev)

#### check_database_on_dev_start

**Type:** Boolean
**Default:** `true`

Controls whether `bin/dev` checks database connectivity before starting the development server. When enabled, it verifies the database exists and is accessible, and warns about pending migrations.

```ruby
config.check_database_on_dev_start = false  # Disable the check
```

This is the lowest-priority opt-out mechanism. You can also disable the check per-invocation via the `--skip-database-check` CLI flag or the `SKIP_DATABASE_CHECK=true` environment variable. See the [Process Managers guide](../building-features/process-managers.md#database-connectivity-check) for details.

### Server Renderer Pool (ExecJS)

#### server_renderer_pool_size

**Type:** Integer
**Default:** `1` (or environment-based)
**Auto-configured:** ✅ Yes

Number of JavaScript execution instances in the server rendering pool:

```ruby
config.server_renderer_pool_size = 1  # MRI default (avoid deadlock)
config.server_renderer_pool_size = 5  # JRuby (can handle multi-threading)
```

**MRI users:** Keep at 1 to avoid deadlocks
**JRuby users:** Can increase for multi-threaded rendering

#### server_renderer_timeout

**Type:** Integer (seconds)
**Default:** `20`

Maximum time to wait for server rendering to complete:

```ruby
config.server_renderer_timeout = 20  # default
```

### Component DOM IDs

#### random_dom_id

**Type:** Boolean
**Default:** `true`

Controls whether component DOM IDs include a random UUID:

- `true` - IDs like `MyComponent-react-component-a1b2c3d4`
- `false` - IDs like `MyComponent-react-component`

```ruby
config.random_dom_id = false  # Use fixed IDs
```

**When to use false:** Modern apps typically have one component instance per page.
**When to use true:** Multiple instances of same component on one page.

Can be overridden per-component:

```ruby
react_component("MyComponent", random_dom_id: false)
```

### Component Registry Timeout

#### component_registry_timeout

**Type:** Integer (milliseconds)
**Default:** `5000`

Maximum time to wait for client-side component registration after page load:

```ruby
config.component_registry_timeout = 5000  # default (5 seconds)
```

Set to `0` to wait indefinitely (not recommended for production).

### I18n Configuration

These options are for applications using [react-intl](https://formatjs.io/docs/react-intl/) or similar internationalization libraries. If your application doesn't need i18n, you can skip this section.

#### i18n_dir

**Type:** String or nil
**Default:** `nil`

Directory where i18n translation files are output for use by react-intl:

```ruby
config.i18n_dir = Rails.root.join("client", "app", "libs", "i18n")
```

Set to `nil` to disable i18n features.

#### i18n_yml_dir

**Type:** String
**Default:** `Rails.root.join("config", "locales")`

Directory where i18n YAML source files are located:

```ruby
config.i18n_yml_dir = Rails.root.join("config", "locales")
```

#### i18n_output_format

**Type:** String
**Default:** `'json'`

Format for generated i18n files (`'json'` or `'js'`):

```ruby
config.i18n_output_format = 'json'  # default
```

#### i18n_yml_safe_load_options

**Type:** Hash
**Default:** `{}`

Options passed to `YAML.safe_load` when reading locale files:

```ruby
config.i18n_yml_safe_load_options = { permitted_classes: [Symbol] }
```

### Webpack Integration

#### webpack_generated_files

**Type:** Array of Strings
**Default:** `%w[manifest.json]` (auto-populated with server bundle files)

Files that webpack generates, used by test helper to check if compilation is needed:

```ruby
config.webpack_generated_files = %w[server-bundle.js manifest.json]
```

**Note:** Don't include hashed filenames (from manifest.json) as they change on every build.

#### same_bundle_for_client_and_server

**Type:** Boolean
**Default:** `false`

When true, React on Rails reads the server bundle from webpack-dev-server (useful if using same hashed bundle for client and server):

```ruby
config.same_bundle_for_client_and_server = false  # default
```

**This should almost never be true.** Almost all apps should use separate client/server bundles.

When true, also set in `config/shakapacker.yml`:

```yaml
dev_server:
  hmr: false
  inline: false
```

### Internal Options

#### node_modules_location

**Type:** String
**Default:** `Rails.root`

Location of `node_modules` directory. With Shakapacker, this should typically be `""` (project root):

```ruby
config.node_modules_location = ""  # Shakapacker default
```

#### server_render_method

**Type:** String
**Default:** `nil`

Server rendering method. Only `"ExecJS"` is currently supported:

```ruby
config.server_render_method = nil  # Uses ExecJS
```

For alternative server rendering methods, contact [justin@shakacode.com](mailto:justin@shakacode.com).

For deprecated configuration options, see [configuration-deprecated.md](configuration-deprecated.md).

## Complete Example

Here's a complete example showing commonly changed options:

```ruby
# frozen_string_literal: true

ReactOnRails.configure do |config|
  ################################################################################
  # Essential Configuration
  ################################################################################

  # Server rendering bundle
  config.server_bundle_js_file = "server-bundle.js"

  # Test configuration
  config.build_test_command = "RAILS_ENV=test bin/shakapacker"

  # File-based component registry
  config.components_subdirectory = "ror_components"
  config.auto_load_bundle = true
  # config.stores_subdirectory = "ror_stores"  # Optional: for Redux store auto-registration

  ################################################################################
  # Optional Overrides (most apps don't need these)
  ################################################################################

  # Production build (only if not using standard Shakapacker)
  # config.build_production_command = "RAILS_ENV=production bin/shakapacker"

  # Server bundle security (recommended for production)
  # config.enforce_private_server_bundles = true

  # Custom rendering hooks
  # config.rendering_extension = RenderingExtension
  # config.rendering_props_extension = RenderingPropsExtension
end
```

## Pro Features

For React Server Components (RSC) and other Pro-specific configuration options, see:
[configuration-pro.md](configuration-pro.md)

## Deprecated Options

For deprecated and removed configuration options, see:
[configuration-deprecated.md](configuration-deprecated.md)

## Support Examples

### Custom Rendering Extension

```ruby
module RenderingExtension
  def self.custom_context(view_context)
    if view_context.controller.is_a?(ActionMailer::Base)
      {}
    else
      {
        somethingUseful: view_context.session[:something_useful],
        currentUser: view_context.current_user&.as_json
      }
    end
  end
end
```

### Custom Props Extension

```ruby
module RenderingPropsExtension
  def self.adjust_props_for_client_side_hydration(component_name, props)
    # Strip server-only props before sending to client
    props.except(:server_side_authentication_token, :internal_admin_data)
  end
end
```

### Custom Build Command Module

```ruby
module BuildProductionCommand
  include FileUtils

  def self.call
    sh "RAILS_ENV=production NODE_ENV=production bin/shakapacker"
    # Additional custom build steps here
  end
end

# In your config:
config.build_production_command = BuildProductionCommand
```

## Bundle Organization Example

Recommended directory structure with private server bundles:

```text
app/
├── ssr-generated/           # Private server bundles (never served to browsers)
│   ├── server-bundle.js
│   └── rsc-bundle.js
└── public/
    └── webpack/development/ # Public client bundles (web-accessible)
        ├── application.js
        ├── manifest.json
        └── styles.css
```

Access methods:

- **Client bundles:** `ReactOnRails::Utils.public_bundles_full_path`
- **Server bundles:** `ReactOnRails::Utils.server_bundle_js_file_path`

## Need Help?

- **Documentation:** [React on Rails Guides](https://www.shakacode.com/react-on-rails/docs/)
- **Pro Features:** [React on Rails Pro](https://www.shakacode.com/react-on-rails-pro/)
- **Support:** [ShakaCode Forum](https://forum.shakacode.com/)
- **Consulting:** [justin@shakacode.com](mailto:justin@shakacode.com)

---

**Note:** This configuration file is meant to be a complete reference. For most applications, you'll only use a small subset of these options. Start with the [Essential Configuration](#essential-configuration) and add advanced options only as needed.

# React on Rails Configuration Options

This document describes all configuration options for React on Rails. Configuration is done in `/config/initializers/react_on_rails.rb`.

> **💡 Good News!** Most applications only need 2-3 configuration options. React on Rails provides sensible defaults for everything else.

## Quick Start

For most applications, your configuration file can be as simple as:

```ruby
ReactOnRails.configure do |config|
  config.server_bundle_js_file = "server-bundle.js"
  config.build_test_command = "RAILS_ENV=test bin/shakapacker"
end
```

See [Essential Configuration](#essential-configuration) below for the options you'll commonly use.

## Prerequisites

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
- `build_test_command` - Test environment build command (alternative to Shakapacker compile setting)

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

**Note:** It's generally preferred to set `compile: true` in your `config/shakapacker.yml` for the test environment instead of using this configuration option. Use this option only if you need to customize the build command or want explicit control over test asset compilation.

The command to run to build webpack assets during test runs:

```ruby
config.build_test_command = "RAILS_ENV=test bin/shakapacker"
```

**Preferred alternative:** Set `compile: true` in `config/shakapacker.yml`:

```yaml
test:
  compile: true
```

## File-Based Component Registry

For information about the file-based component registry feature (including `components_subdirectory`, `auto_load_bundle`, and `make_generated_server_bundle_the_entrypoint` configuration options), see:

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

To override the default:

```ruby
config.generated_component_packs_loading_strategy = :defer
```

### Server Bundle Security and Organization

#### server_bundle_output_path

**Type:** String or nil
**Default:** `"ssr-generated"`

Directory (relative to Rails root) where server bundles are output. **You should not need to set this** - the default value is recommended for all applications.

```ruby
config.server_bundle_output_path = "ssr-generated"  # default (no need to set)
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

When true, server-side console messages replay in the browser console:

```ruby
config.replay_console = true  # default
```

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

```
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

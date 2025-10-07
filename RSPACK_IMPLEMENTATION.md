# Rspack Generator Option Implementation

This document summarizes the implementation of the `--rspack` option for the React on Rails generator, based on the patterns from [PR #20 in react_on_rails-demos](https://github.com/shakacode/react_on_rails-demos/pull/20).

## Overview

The `--rspack` flag allows users to generate a React on Rails application using Rspack instead of Webpack as the bundler. Rspack provides significantly faster build times (~53-270ms vs typical webpack builds).

## Changes Made

### 1. Install Generator (`lib/generators/react_on_rails/install_generator.rb`)

- **Added `--rspack` class option** (line 31-35): Boolean flag to enable Rspack bundler
- **Updated `invoke_generators`** (line 82-83): Pass rspack option to base generator
- **Added `add_rspack_dependencies` method** (line 499-513): Installs Rspack core packages:
  - `@rspack/core`
  - `rspack-manifest-plugin`
- **Updated `add_dev_dependencies`** (line 515-534): Conditionally installs rspack or webpack refresh plugins:
  - Rspack: `@rspack/cli`, `@rspack/plugin-react-refresh`, `react-refresh`
  - Webpack: `@pmmmwh/react-refresh-webpack-plugin`, `react-refresh`
- **Updated `add_js_dependencies`** (line 433): Calls `add_rspack_dependencies` when rspack flag is set

### 2. Base Generator (`lib/generators/react_on_rails/base_generator.rb`)

- **Added `--rspack` class option** (line 22-26): Boolean flag (passed from install generator)
- **Updated `copy_packer_config`** (line 85-100): Calls `configure_rspack_in_shakapacker` after copying config
- **Added `configure_rspack_in_shakapacker` method** (line 404-426):
  - Adds `assets_bundler: 'rspack'` to shakapacker.yml default section
  - Changes `webpack_loader` to `'swc'` (Rspack works best with SWC transpiler)

### 3. Webpack Configuration Templates

Updated webpack configuration templates to support both webpack and rspack bundlers with unified config approach:

**development.js.tt**:

- Added `config` to shakapacker require to access `assets_bundler` setting
- Conditional React Refresh plugin loading based on `config.assets_bundler`:
  - Rspack: Uses `@rspack/plugin-react-refresh`
  - Webpack: Uses `@pmmmwh/react-refresh-webpack-plugin`
- Prevents "window not found" errors when using rspack

**serverWebpackConfig.js.tt**:

- Added `bundler` variable that conditionally requires `@rspack/core` or `webpack`
- Changed `webpack.optimize.LimitChunkCountPlugin` to `bundler.optimize.LimitChunkCountPlugin`
- Enables same config to work with both bundlers without warnings
- Avoids hardcoding webpack-specific imports

### 4. Bundler Switching Script (`lib/generators/react_on_rails/templates/base/base/bin/switch-bundler`)

Created a new executable script that allows switching between webpack and rspack after installation:

**Features:**

- Updates `shakapacker.yml` with correct `assets_bundler` setting
- Switches `webpack_loader` between 'swc' (rspack) and 'babel' (webpack)
- Removes old bundler dependencies from package.json
- Installs new bundler dependencies
- Supports npm, yarn, and pnpm package managers
- Auto-detects package manager from lock files

**Usage:**

```bash
bin/switch-bundler rspack   # Switch to Rspack
bin/switch-bundler webpack  # Switch to Webpack
```

**Dependencies managed:**

- **Webpack**: webpack, webpack-cli, webpack-dev-server, webpack-assets-manifest, webpack-merge, @pmmmwh/react-refresh-webpack-plugin
- **Rspack**: @rspack/core, @rspack/cli, @rspack/plugin-react-refresh, rspack-manifest-plugin

## Usage

### Generate new app with Rspack:

```bash
rails generate react_on_rails:install --rspack
```

### Generate with Rspack and TypeScript:

```bash
rails generate react_on_rails:install --rspack --typescript
```

### Generate with Rspack and Redux:

```bash
rails generate react_on_rails:install --rspack --redux
```

### Switch existing app to Rspack:

```bash
bin/switch-bundler rspack
```

## Configuration Changes

When `--rspack` is used, the following configuration changes are applied to `config/shakapacker.yml`:

```yaml
default: &default
  source_path: app/javascript
  assets_bundler: 'rspack' # Added
  # ... other settings
  webpack_loader: 'swc' # Changed from 'babel'
```

## Dependencies

### Rspack-specific packages installed:

**Production:**

- `@rspack/core` - Core Rspack bundler
- `rspack-manifest-plugin` - Manifest generation for Rspack

**Development:**

- `@rspack/cli` - Rspack CLI tools
- `@rspack/plugin-react-refresh` - React Fast Refresh for Rspack
- `react-refresh` - React Fast Refresh runtime

### Webpack packages NOT installed with --rspack:

**Production:**

- `webpack`
- `webpack-assets-manifest`
- `webpack-merge`

**Development:**

- `webpack-cli`
- `webpack-dev-server`
- `@pmmmwh/react-refresh-webpack-plugin`

## Performance Benefits

According to PR #20:

- Build times: ~53-270ms with Rspack vs typical webpack builds
- Approximately 20x faster transpilation with SWC (used by Rspack)
- Faster development builds and CI runs

## Testing

The implementation follows existing generator patterns and passes RuboCop checks with zero offenses.

## Compatibility

- Works with existing webpack configuration files (unified config approach)
- Compatible with TypeScript option (`--typescript`)
- Compatible with Redux option (`--redux`)
- Supports all package managers (npm, yarn, pnpm)
- Reversible via `bin/switch-bundler` script

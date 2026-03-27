# Webpack Configuration: custom setup for Webpack or Shakapacker?

## Webpack vs. Shakapacker

[Webpack](https://webpack.js.org) is the JavaScript npm package that prepares all your client-side assets. The Rails asset pipeline used to be the preferable way to prepare client-side assets.

[Shakapacker](https://github.com/shakacode/shakapacker) (the official successor of [rails/webpacker](https://github.com/rails/webpacker)) is the Ruby gem that mainly gives us 2 things:

1. View helpers for placing the Webpack bundles on your Rails views. React on Rails depends on these view helpers.
2. A layer of abstraction on top of Webpack customization. The base setup works great for the client-side Webpack configuration.

To get a deeper understanding of Shakapacker, watch [RailsConf 2020 CE - Webpacker, It-Just-Works, But How? by Justin Gordon](https://youtu.be/sJLoOpc5LD8).

## Rspack vs. Webpack

[Rspack](https://rspack.dev/) is a high-performance JavaScript bundler written in Rust that provides significantly faster builds than Webpack (~20x improvement). React on Rails supports both bundlers through unified configuration.

### Using Rspack

Generate a new app with Rspack:

```bash
rails generate react_on_rails:install --rspack
```

Or switch an existing app to Rspack:

```bash
bin/switch-bundler rspack
```

### Performance Benefits

- **Build times**: ~53-270ms with Rspack vs typical webpack builds
- **~20x faster transpilation** with SWC (used by Rspack)
- **Faster development** builds and CI runs

### Unified Configuration

React on Rails generates unified webpack configuration files that work with both bundlers:

**config/webpack/development.js** - Conditional plugin loading:

```javascript
const { config } = require('shakapacker');

if (config.assets_bundler === 'rspack') {
  // Rspack uses @rspack/plugin-react-refresh
  const ReactRefreshPlugin = require('@rspack/plugin-react-refresh');
  clientWebpackConfig.plugins.push(new ReactRefreshPlugin());
} else {
  // Webpack uses @pmmmwh/react-refresh-webpack-plugin
  const ReactRefreshWebpackPlugin = require('@pmmmwh/react-refresh-webpack-plugin');
  clientWebpackConfig.plugins.push(new ReactRefreshWebpackPlugin());
}
```

**config/webpack/serverWebpackConfig.js** - Dynamic bundler detection:

```javascript
const { config } = require('shakapacker');

const bundler = config.assets_bundler === 'rspack' ? require('@rspack/core') : require('webpack');

// Use bundler-specific APIs
serverWebpackConfig.plugins.unshift(new bundler.optimize.LimitChunkCountPlugin({ maxChunks: 1 }));
```

### Configuration in shakapacker.yml

Rspack configuration is controlled via `config/shakapacker.yml`:

```yaml
default: &default
  assets_bundler: 'rspack' # or 'webpack'
  webpack_loader: 'swc' # Rspack works best with SWC
```

The `bin/switch-bundler` script automatically updates this configuration when switching bundlers.

### Server Bundle Configuration (Shakapacker 9.0+)

**Recommended**: For Shakapacker 9.0+, use `private_output_path` in `shakapacker.yml` for server bundles:

```yaml
default: &default # ... other config ...
  private_output_path: ssr-generated
```

This provides a single source of truth for server bundle location. React on Rails automatically detects this configuration, eliminating the need to set `server_bundle_output_path` in your React on Rails initializer.

In your `config/webpack/serverWebpackConfig.js`:

```javascript
const { config } = require('shakapacker');

serverWebpackConfig.output = {
  filename: 'server-bundle.js',
  globalObject: 'this',
  path: config.privateOutputPath, // Automatically uses shakapacker.yml value
};
```

**Benefits:**

- Single source of truth in `shakapacker.yml`
- Automatic synchronization between webpack and React on Rails
- No configuration duplication
- Better maintainability

**For older Shakapacker versions:** Use hardcoded paths and manual configuration as shown in the generator templates.

Per the example repo [shakacode/react_on_rails_demo_ssr_hmr](https://github.com/shakacode/react_on_rails_demo_ssr_hmr),
you should consider keeping your codebase mostly consistent with the defaults for [Shakapacker](https://github.com/shakacode/shakapacker).

# React on Rails

Version 9 of React on Rails added support for the Shakapacker (`rails/webpacker` of that time) view helpers so that Webpack produced assets would no longer pass through the Rails asset pipeline. As part of this change, React on Rails added a configuration option to support customization of the node_modules directory. This allowed React on Rails to support the Shakapacker configuration of the Webpack configuration.

A key decision in your use React on Rails is whether you go with the Shakapacker default setup or the traditional React on Rails setup of putting all your client side files under the `/client` directory. While there are technically 2 independent choices involved, the directory structure and the mechanism of Webpack configuration, for simplicity sake we'll assume that these choices go together.

## Option 1: Default Generator Setup: Shakapacker app/javascript

Typical Shakapacker apps have a standard directory structure as documented [here](https://github.com/shakacode/shakapacker/blob/master/README.md#configuration-and-code). If you follow [the basic tutorial](../getting-started/tutorial.md), you will see this pattern in action. In order to customize the Webpack configuration, consult the [Shakapacker webpack customization docs](https://github.com/shakacode/shakapacker#webpack-configuration).

The _advantage_ of using Shakapacker to configure Webpack is that there is very little code needed to get started, and you don't need to understand really anything about Webpack customization.

## Option 2: Traditional React on Rails using the /client directory

Until version 9, all React on Rails apps used the `/client` directory for configuring React on Rails in terms of the configuration of Webpack and location of your JavaScript and Webpack files, including the `node_modules` directory. Version 9 changed the default to `/` for the `node_modules` location using this value in `config/initializers/react_on_rails.rb`: `config.node_modules_location`.

You can access values from `config/shakapacker.yml`:

```js
const { config, devServer } = require('shakapacker');
```

You will want to consider using some of the same values set in these files:

- https://github.com/shakacode/shakapacker/blob/master/package/environments/base.ts
- https://github.com/shakacode/shakapacker/blob/master/package/environments/development.ts

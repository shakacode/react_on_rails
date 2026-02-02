# Migrating from Webpack to Rspack

This guide documents the process of migrating from Webpack to Rspack using Shakapacker 9+. Rspack is a high-performance bundler written in Rust that provides significantly faster builds (~20x improvement) while maintaining Webpack API compatibility.

## Prerequisites

- Shakapacker 9.0+ (Rspack support was added in 9.0)
- Node.js 20+
- React on Rails 13+

## Quick Start

For new projects or simple migrations, the generator handles most of the setup:

```bash
# Generate with Rspack from scratch
rails generate react_on_rails:install --rspack

# Or switch an existing app
bin/switch-bundler rspack
```

For complex projects with SSR, CSS Modules, or custom configurations, continue reading for important considerations.

## Breaking Changes in Shakapacker 9

### CSS Modules: Named vs Default Exports

**This is the most critical breaking change.** Shakapacker 9 changed the default CSS Modules configuration from default exports to named exports (`namedExport: true`).

**Symptoms:**

- CSS modules returning `undefined`
- SSR errors: `Cannot read properties of undefined (reading 'className')`
- Build warnings: `export 'default' (imported as 'css') was not found`

**Affected code pattern:**

```javascript
// This pattern breaks with Shakapacker 9 defaults
import css from './Component.module.scss';
console.log(css.myClass); // undefined!
```

**Solution:** Configure CSS loader to use default exports in your webpack configuration:

```javascript
// config/webpack/commonWebpackConfig.js
const { generateWebpackConfig, merge } = require('shakapacker');

const commonWebpackConfig = () => {
  const baseWebpackConfig = generateWebpackConfig();

  // Fix CSS modules to use default exports for backward compatibility
  baseWebpackConfig.module.rules.forEach((rule) => {
    if (rule.use && Array.isArray(rule.use)) {
      const cssLoader = rule.use.find((loader) => {
        const loaderName = typeof loader === 'string' ? loader : loader?.loader;
        return loaderName?.includes('css-loader');
      });

      if (cssLoader?.options?.modules) {
        cssLoader.options.modules.namedExport = false;
        cssLoader.options.modules.exportLocalsConvention = 'camelCase';
      }
    }
  });

  return baseWebpackConfig;
};

module.exports = commonWebpackConfig;
```

**Key insight:** This configuration must be inside the function so it applies to a fresh config each time.

## Rspack-Specific Configuration

### Bundler Auto-Detection Pattern

Use conditional logic to support both Webpack and Rspack in the same configuration files:

```javascript
// config/webpack/commonWebpackConfig.js
const { config } = require('shakapacker');

// Auto-detect bundler from shakapacker config
const bundler = config.assets_bundler === 'rspack' ? require('@rspack/core') : require('webpack');

// Use for plugins that need the bundler reference
clientConfig.plugins.push(
  new bundler.ProvidePlugin({
    /* ... */
  }),
);
serverConfig.plugins.unshift(new bundler.optimize.LimitChunkCountPlugin({ maxChunks: 1 }));
```

**Benefits:**

- Single codebase for both bundlers
- Easy to compare configurations
- Clear visibility of bundler-specific differences

### Server Bundle: CSS Extract Plugin Filtering

Rspack uses a different CSS extract loader path than Webpack. Server-side rendering configs that filter out CSS extraction must handle both:

```javascript
// config/webpack/serverWebpackConfig.js
const configureServer = (serverWebpackConfig) => {
  serverWebpackConfig.module.rules.forEach((rule) => {
    if (rule.use && Array.isArray(rule.use)) {
      // Filter out CSS extraction loaders for SSR
      rule.use = rule.use.filter((item) => {
        let testValue;
        if (typeof item === 'string') {
          testValue = item;
        } else if (typeof item.loader === 'string') {
          testValue = item.loader;
        }

        // Handle both Webpack and Rspack CSS extract loaders
        return !(
          testValue?.match(/mini-css-extract-plugin/) ||
          testValue?.includes('cssExtractLoader') || // Rspack uses this path
          testValue === 'style-loader'
        );
      });
    }
  });
};
```

**Why this matters:** Rspack uses `@rspack/core/dist/cssExtractLoader.js` instead of Webpack's `mini-css-extract-plugin`. Without this fix, CSS extraction remains in the server bundle, causing intermittent SSR failures.

### Server Bundle: Preserve CSS Modules Configuration

When configuring SSR, merge CSS modules options instead of replacing them:

```javascript
// ❌ Wrong - overwrites namedExport setting
if (cssLoader && cssLoader.options) {
  cssLoader.options.modules = { exportOnlyLocals: true };
}

// ✅ Correct - preserves existing settings
if (cssLoader && cssLoader.options && cssLoader.options.modules) {
  cssLoader.options.modules = {
    ...cssLoader.options.modules, // Preserve namedExport: false
    exportOnlyLocals: true,
  };
}
```

## React Runtime Configuration

### SWC React Runtime for SSR

If using SWC (common with Rspack), you may need to use the classic React runtime for SSR compatibility:

```javascript
// config/swc.config.js
const customConfig = {
  options: {
    jsc: {
      transform: {
        react: {
          runtime: 'classic', // Use 'classic' instead of 'automatic' for SSR
          refresh: env.isDevelopment && env.runningWebpackDevServer,
        },
      },
    },
  },
};
```

**Symptom:** SSR error about invalid `renderToString` call or function signature detection issues.

## Additional Configuration

### ReScript Support

If using ReScript, add `.bs.js` to resolve extensions:

```javascript
// config/webpack/commonWebpackConfig.js
const commonOptions = {
  resolve: {
    extensions: ['.css', '.ts', '.tsx', '.bs.js'],
  },
};
```

### Development Hot Reloading

Different plugins are required for hot reloading:

```javascript
// config/webpack/development.js
const { config } = require('shakapacker');

if (config.assets_bundler === 'rspack') {
  const ReactRefreshPlugin = require('@rspack/plugin-react-refresh');
  clientWebpackConfig.plugins.push(new ReactRefreshPlugin());
} else {
  const ReactRefreshWebpackPlugin = require('@pmmmwh/react-refresh-webpack-plugin');
  clientWebpackConfig.plugins.push(new ReactRefreshWebpackPlugin());
}
```

## Shakapacker Configuration

Enable Rspack in `config/shakapacker.yml`:

```yaml
default: &default
  assets_bundler: 'rspack' # or 'webpack'
  webpack_loader: 'swc' # Rspack works best with SWC
```

## Troubleshooting

### CSS Modules Return `undefined`

**Symptoms:**

- `css.className` is `undefined`
- SSR crashes with property access errors
- Works in development but fails in SSR

**Solutions:**

1. Configure `namedExport: false` (see Breaking Changes section)
2. Ensure server config preserves CSS modules settings
3. Filter Rspack's `cssExtractLoader` from server bundle

### Intermittent SSR Failures

**Cause:** Incomplete CSS extraction filtering in server config.

**Solution:** Update the CSS extract loader filter to include `cssExtractLoader` for Rspack (see Server Bundle section).

### Module Resolution Errors

**Symptom:** `Module not found: Can't resolve './file.bs.js'`

**Solution:** Add the file extension to webpack's resolve.extensions configuration.

### Third-Party Package Issues

Some packages may not ship compiled files. Use `patch-package` to fix:

```bash
pnpm add --save-dev patch-package postinstall-postinstall
```

Add to package.json:

```json
{
  "scripts": {
    "postinstall": "patch-package"
  }
}
```

## Performance Benefits

After migration, expect:

- **Build times:** ~53-270ms with Rspack (vs seconds with Webpack)
- **~20x faster transpilation** with SWC
- **Faster CI runs** and development iteration

## Reference Implementation

For a complete working example, see the [react-webpack-rails-tutorial Rspack migration PR](https://github.com/shakacode/react-webpack-rails-tutorial/pull/680).

## Related Documentation

- [Webpack Configuration](../core-concepts/webpack-configuration.md) - Rspack vs Webpack overview
- [Server-Side Rendering](../core-concepts/react-server-rendering.md) - SSR configuration
- [Troubleshooting Guide](../deployment/troubleshooting.md) - General troubleshooting

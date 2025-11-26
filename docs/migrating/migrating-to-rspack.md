# Migrating from Webpack to Rspack

This guide documents the process of migrating a React on Rails project from Webpack to Rspack using Shakapacker 9. It covers all known issues and their solutions based on real-world migrations.

## Prerequisites

- Shakapacker 9.0.0 or later (Rspack support was added in v9)
- Node.js 18+ (Node.js 22+ recommended)
- Working React on Rails application using Webpack

## Overview

Rspack is a high-performance bundler written in Rust that aims to be drop-in compatible with Webpack. While mostly compatible, there are several configuration differences and breaking changes in Shakapacker 9 that require attention during migration.

**Reference Implementation:** [react-webpack-rails-tutorial PR #680](https://github.com/shakacode/react-webpack-rails-tutorial/pull/680)

## Step 1: Update Dependencies

### Install Rspack

Add Rspack core package:

```bash
yarn add -D @rspack/core
```

### Update shakapacker.yml

Configure Shakapacker to use Rspack as the bundler:

```yaml
# config/shakapacker.yml
default: &default # ... existing configuration ...
  assets_bundler: rspack # Add this line
```

## Step 2: Fix CSS Modules (Breaking Change)

> ⚠️ **CRITICAL**: Shakapacker 9 changed the default CSS Modules configuration

### The Problem

Shakapacker 9 defaults CSS Modules to use named exports (`namedExport: true`). This breaks existing code that imports CSS modules as default exports:

```javascript
// This pattern breaks with Shakapacker 9 defaults
import css from './Component.module.scss';
console.log(css.someClass); // undefined!
```

**Error messages you might see:**

- SSR: `Cannot read properties of undefined (reading 'someClassName')`
- Build: `ESModulesLinkingWarning: export 'default' (imported as 'css') was not found in './Component.module.scss'`

### The Solution

Configure CSS loader to preserve default export behavior in your webpack config:

```javascript
// config/webpack/commonWebpackConfig.js
const { generateWebpackConfig, merge } = require('shakapacker');

const commonWebpackConfig = () => {
  const baseWebpackConfig = generateWebpackConfig();

  // Fix CSS modules to use default exports for backward compatibility
  // Shakapacker 9 defaults to namedExport: true which breaks existing code
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

  return merge({}, baseWebpackConfig, commonOptions);
};

module.exports = commonWebpackConfig;
```

> **Important:** This configuration must be inside the function so it applies to a fresh config each time the function is called.

## Step 3: Update Server Bundle Configuration

If you use server-side rendering (SSR), update your server webpack configuration.

### Fix CSS Extract Plugin Filtering

Rspack uses a different loader path for CSS extraction than Webpack:

- **Webpack:** `mini-css-extract-plugin`
- **Rspack:** `@rspack/core/dist/cssExtractLoader.js`

Update your server config to filter both:

```javascript
// config/webpack/serverWebpackConfig.js
const configureServer = (clientConfig) => {
  // ... other configuration ...

  serverConfig.module.rules.forEach((rule) => {
    if (rule.use && Array.isArray(rule.use)) {
      // Filter out CSS extraction loaders for server bundle
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
          testValue?.includes('cssExtractLoader') || // Rspack loader
          testValue === 'style-loader'
        );
      });
    }
  });

  return serverConfig;
};
```

### Preserve CSS Modules Configuration for SSR

When configuring CSS modules for SSR (using `exportOnlyLocals`), merge the settings instead of replacing them:

```javascript
// Wrong - overwrites the namedExport setting
if (cssLoader?.options) {
  cssLoader.options.modules = { exportOnlyLocals: true };
}

// Correct - preserves namedExport: false from common config
if (cssLoader?.options?.modules) {
  cssLoader.options.modules = {
    ...cssLoader.options.modules, // Preserve existing settings
    exportOnlyLocals: true,
  };
}
```

## Step 4: Bundler Auto-Detection Pattern

For projects that need to support both Webpack and Rspack, use conditional logic:

```javascript
// config/webpack/commonWebpackConfig.js
const { config } = require('shakapacker');

// Auto-detect bundler from shakapacker config
const bundler = config.assets_bundler === 'rspack' ? require('@rspack/core') : require('webpack');

// Use for plugins that differ between bundlers
clientConfig.plugins.push(
  new bundler.ProvidePlugin({
    React: 'react',
  }),
);

serverConfig.plugins.unshift(new bundler.optimize.LimitChunkCountPlugin({ maxChunks: 1 }));
```

This approach:

- Keeps all configs in the same `config/webpack/` directory
- Makes differences between bundlers explicit
- Simplifies debugging and maintenance

## Step 5: Handle SWC React Runtime (If Using SWC)

If you use SWC for transpilation and server-side rendering, you may need to use the classic React runtime:

```javascript
// config/swc.config.js
const customConfig = {
  options: {
    jsc: {
      transform: {
        react: {
          runtime: 'classic', // Use 'classic' instead of 'automatic'
          refresh: env.isDevelopment && env.runningWebpackDevServer,
        },
      },
    },
  },
};
```

**Why?** React on Rails SSR detects render function signatures. The automatic runtime's transformed output may not be detected correctly, causing errors like:

```
Invalid call to renderToString. Possibly you have a renderFunction,
a function that already calls renderToString, that takes one parameter.
```

## Step 6: Handle ReScript (If Applicable)

If your project uses ReScript:

### Add `.bs.js` Extension Resolution

```javascript
// config/webpack/commonWebpackConfig.js
const commonOptions = {
  resolve: {
    extensions: ['.css', '.ts', '.tsx', '.bs.js'],
  },
};
```

### Patch Broken Dependencies

Some ReScript packages may not include compiled `.bs.js` files. Use `patch-package`:

```bash
yarn add -D patch-package postinstall-postinstall
```

Add to `package.json`:

```json
{
  "scripts": {
    "postinstall": "patch-package"
  }
}
```

## Complete Configuration Example

Here's a complete example of a dual Webpack/Rspack compatible configuration:

```javascript
// config/webpack/commonWebpackConfig.js
const { generateWebpackConfig, merge, config } = require('shakapacker');

// Auto-detect bundler
const bundler = config.assets_bundler === 'rspack' ? require('@rspack/core') : require('webpack');

const commonOptions = {
  resolve: {
    extensions: ['.css', '.ts', '.tsx'],
  },
};

/**
 * Generate common webpack configuration with CSS modules fix.
 * Must be called as a function to get fresh config each time.
 */
const commonWebpackConfig = () => {
  const baseWebpackConfig = generateWebpackConfig();

  // Fix CSS modules for backward compatibility with Shakapacker 9
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

  return merge({}, baseWebpackConfig, commonOptions);
};

module.exports = commonWebpackConfig;
module.exports.bundler = bundler;
```

```javascript
// config/webpack/serverWebpackConfig.js
const { merge } = require('shakapacker');

/**
 * Configure server-side rendering bundle.
 * Handles both Webpack and Rspack CSS extraction loaders.
 */
const configureServer = (clientConfig) => {
  const serverConfig = merge({}, clientConfig);

  serverConfig.module.rules.forEach((rule) => {
    if (rule.use && Array.isArray(rule.use)) {
      // Filter CSS extraction loaders (different paths for Webpack vs Rspack)
      rule.use = rule.use.filter((item) => {
        let testValue;
        if (typeof item === 'string') {
          testValue = item;
        } else if (typeof item.loader === 'string') {
          testValue = item.loader;
        }
        return !(
          testValue?.match(/mini-css-extract-plugin/) ||
          testValue?.includes('cssExtractLoader') ||
          testValue === 'style-loader'
        );
      });

      // Configure CSS modules for SSR (exportOnlyLocals)
      const cssLoader = rule.use.find((loader) => {
        const loaderName = typeof loader === 'string' ? loader : loader?.loader;
        return loaderName?.includes('css-loader');
      });

      if (cssLoader?.options?.modules) {
        cssLoader.options.modules = {
          ...cssLoader.options.modules, // Preserve namedExport: false
          exportOnlyLocals: true,
        };
      }
    }
  });

  return serverConfig;
};

module.exports = configureServer;
```

## Troubleshooting

### CSS Modules Return `undefined` in SSR

**Cause:** CSS extraction loader not filtered from server bundle, or CSS modules configuration being overwritten.

**Solution:**

1. Ensure `cssExtractLoader` is filtered (see Step 3)
2. Ensure CSS modules config is merged, not replaced

### Tests Pass Locally But Fail Intermittently in CI

**Cause:** Incomplete CSS extraction filtering causes non-deterministic behavior.

**Solution:** Add the `cssExtractLoader` filter for Rspack (see Step 3).

### Module Not Found Errors

**Cause:** Rspack may have stricter module resolution.

**Solution:**

1. Check `resolve.extensions` in webpack config
2. Ensure all required file extensions are listed
3. For ReScript, add `.bs.js` extension

### Build Warnings About Named Exports

**Warning:** `export 'default' (imported as 'css') was not found`

**Cause:** Shakapacker 9's `namedExport: true` default.

**Solution:** Apply the CSS modules fix in Step 2.

## Performance Benefits

After migrating to Rspack, you should see significant build time improvements:

- **Development builds:** 2-5x faster
- **Production builds:** 2-3x faster
- **Hot Module Replacement:** Near-instant updates

## Additional Resources

- [Shakapacker Rspack Support Issue](https://github.com/shakacode/shakapacker/issues/693)
- [Rspack Documentation](https://rspack.dev/)
- [Shakapacker Documentation](https://github.com/shakacode/shakapacker)

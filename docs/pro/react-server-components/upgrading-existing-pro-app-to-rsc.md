# Upgrading an Existing React on Rails Pro App to RSC

Already running React on Rails Pro? This guide covers adding React Server Components to your existing app using the standalone RSC generator. If you're starting from scratch, see the [RSC tutorial](./tutorial.md) instead.

> **This guide is for existing Pro apps.** If you're on OSS and want RSC, first [upgrade to Pro](../upgrading-to-pro.md), then come back here.

## Prerequisites

Before running the generator, verify:

- **React on Rails Pro v4.0.0+** with **React on Rails v16.0.0+**
- **React 19.0.x** (`react` and `react-dom` both at 19.0.4 or later within the 19.0.x range). React 19.1.x and later are not yet supported.
- **Node renderer** configured and running (RSC requires server-side JavaScript execution via the node renderer, not ExecJS)
- **Shakapacker** (or webpack configured via Shakapacker)
- **Node.js 20+**
- **Pro initializer exists** at `config/initializers/react_on_rails_pro.rb`

Check your versions:

```bash
# Check gem version
bundle show react_on_rails_pro

# Check npm package version
yarn why react-on-rails-pro  # or: npm ls react-on-rails-pro

# Check React version (must be 19.0.x)
yarn why react

# Verify Pro initializer exists
ls config/initializers/react_on_rails_pro.rb
```

> **React version note:** `react-on-rails-rsc` versions 19.0.0 through 19.0.3 vendored older builds of `react-server-dom-webpack` with known vulnerabilities (CVE-2025-55182, CVE-2025-67779, CVE-2026-23864). Use 19.0.4 or later.

## Run the Generator

```bash
bundle exec rails generate react_on_rails:rsc
```

For TypeScript projects:

```bash
bundle exec rails generate react_on_rails:rsc --typescript
```

The generator is idempotent -- it skips files that already exist and checks for existing configuration before making changes.

## What the Generator Creates and Modifies

### New files

| File                                                            | Purpose                                                     |
| --------------------------------------------------------------- | ----------------------------------------------------------- |
| `config/webpack/rscWebpackConfig.js`                            | RSC webpack bundle config (derives from your server config) |
| `app/javascript/src/HelloServer/ror_components/HelloServer.jsx` | Example RSC component (registered as a Server Component)    |
| `app/javascript/src/HelloServer/components/HelloServer.jsx`     | Server component implementation                             |
| `app/javascript/src/HelloServer/components/LikeButton.jsx`      | Example client component with `'use client'` directive      |

### Modified files

| File                                        | Change                                                                               |
| ------------------------------------------- | ------------------------------------------------------------------------------------ |
| `config/initializers/react_on_rails_pro.rb` | Adds `enable_rsc_support`, `rsc_bundle_js_file`, `rsc_payload_generation_url_path`   |
| `config/webpack/serverWebpackConfig.js`     | Adds `RSCWebpackPlugin` import, `rscBundle` parameter to `configureServer()`         |
| `config/webpack/clientWebpackConfig.js`     | Adds `RSCWebpackPlugin` import and plugin                                            |
| `config/webpack/ServerClientOrBoth.js`      | Adds RSC config import, `RSC_BUNDLE_ONLY` env handling, includes RSC in multi-bundle |
| `config/routes.rb`                          | Adds `rsc_payload_route` and `hello_server` route                                    |
| `Procfile.dev`                              | Adds RSC bundle watcher: `rsc-bundle: RSC_BUNDLE_ONLY=yes bin/shakapacker --watch`   |

### NPM dependencies added

- `react-on-rails-rsc` -- RSC webpack loader, plugin, and runtime
- `react-server-dom-webpack` -- React's RSC wire protocol

## Legacy vs Current Webpack Export Styles

The generator handles both webpack config export styles transparently. No manual action is required -- the generated `rscWebpackConfig.js` includes backward-compatibility logic.

### Current style (Pro generator output)

If you ran the Pro generator recently, your `serverWebpackConfig.js` exports an object with named exports:

```js
module.exports = {
  default: configureServer,
  extractLoader,
};
```

The `extractLoader` function is used by the RSC config to find babel-loader or swc-loader in your webpack rules.

### Legacy style (older Pro installs or manual setup)

Older installations export the function directly:

```js
module.exports = configureServer;
```

### How the RSC config handles both

The generated `rscWebpackConfig.js` uses this pattern:

```js
const serverWebpackModule = require('./serverWebpackConfig');

// Works with both export styles
const serverWebpackConfig = serverWebpackModule.default || serverWebpackModule;
const extractLoader =
  serverWebpackModule.extractLoader ||
  ((rule, loaderName) => {
    // Inline fallback implementation
    if (!Array.isArray(rule.use)) return null;
    return rule.use.find((item) => {
      const testValue = typeof item === 'string' ? item : item.loader;
      return testValue && testValue.includes(loaderName);
    });
  });
```

This means:

- **Current style**: Uses `serverWebpackModule.default` and `serverWebpackModule.extractLoader` directly
- **Legacy style**: Falls back to `serverWebpackModule` itself (the function) and provides an inline `extractLoader`

You do not need to update your `serverWebpackConfig.js` export style for RSC to work.

## Verification Checklist

After running the generator, verify everything works:

### 1. Build all bundles

```bash
bin/dev
# or: foreman start -f Procfile.dev
```

Watch for build errors in the terminal output. All three bundles (client, server, RSC) should compile successfully.

### 2. Check generated files

```bash
# RSC bundle should exist in your server bundle output directory
ls ssr-generated/rsc-bundle.js

# RSC manifests should exist in your webpack output directory
ls public/packs/react-client-manifest.json
ls public/packs/react-server-client-manifest.json
```

> **Note:** The paths above assume default configuration. Your `server_bundle_output_path` and webpack output directory may differ.

### 3. Visit the example page

Navigate to [http://localhost:3000/hello_server](http://localhost:3000/hello_server). You should see the HelloServer component rendered with a "Like" button that works client-side.

### 4. Verify the RSC payload route

Navigate to [http://localhost:3000/rsc_payload/HelloServer](http://localhost:3000/rsc_payload/HelloServer). You should see RSC payload output (a stream of encoded React component data), not an error page.

### 5. Run the doctor

```bash
bundle exec rails react_on_rails:doctor
```

This validates that your React on Rails configuration is consistent.

## Troubleshooting

### Generator reports "Pro is not installed"

The RSC generator requires `config/initializers/react_on_rails_pro.rb` to exist. Run the Pro generator first:

```bash
bundle exec rails generate react_on_rails:pro
```

### Webpack transform warnings

If the generator reports "Some RSC webpack transforms may not have applied correctly", your webpack configs have been customized in a way the generator's regex-based transforms couldn't match. Check the [modified files table](#modified-files) above and apply the changes manually. The [Preparing Your App](../../oss/migrating/rsc-preparing-app.md) guide has detailed "What this does" callouts explaining each change.

### RSC bundle fails to build

Common causes:

- **Missing `react-server-dom-webpack`**: Run `yarn install` or `npm install` to ensure the RSC npm dependencies were added
- **`react-dom/server` import error**: The RSC config aliases `react-dom/server` to `false`. If you have a custom webpack config that re-adds it, remove that alias for the RSC bundle
- **React version mismatch**: RSC requires React 19.0.x specifically. Check with `yarn why react`

### HelloServer page returns 500

Check the node renderer logs for errors. Common issues:

- Node renderer not running (check `Procfile.dev`)
- RSC bundle not built yet (wait for the RSC watcher to finish)
- Missing `rsc_payload_route` in `config/routes.rb`

## Next Steps

- [RSC Tutorial](./tutorial.md) -- Learn RSC concepts step by step
- [Preparing Your App for RSC Migration](../../oss/migrating/rsc-preparing-app.md) -- Detailed manual setup for migrating existing components
- [How RSC Works](./how-react-server-components-work.md) -- Technical deep-dive into bundling
- [Migrating to RSC](../../oss/migrating/migrating-to-rsc.md) -- Full migration series for converting components

## Implementation Context

This upgrade path was implemented in [#2284](https://github.com/shakacode/react_on_rails/pull/2284) (generator flags) and [#2424](https://github.com/shakacode/react_on_rails/pull/2424) (standalone RSC generator compatibility). The backward-compatible webpack export handling ensures the generator works with both legacy and current Pro installations.

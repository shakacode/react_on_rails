# Rspack Compatibility with React Server Components

> **Status**: Experimental — generator support is complete; runtime verification is in progress.

This page documents the compatibility status of [Rspack](https://rspack.dev/) with React on Rails Pro's React Server Components (RSC) implementation.

## Overview

React on Rails Pro's RSC implementation uses a three-bundle architecture (client, server, RSC).
The generator already supports Rspack — when `assets_bundler: rspack` is detected in `shakapacker.yml`, all RSC config files are created in `config/rspack/` instead of `config/webpack/`.

The RSC implementation depends on the `react-on-rails-rsc` npm package, which provides:

- **WebpackPlugin** — generates client/server component manifest files
- **WebpackLoader** — transforms `'use client'` files into client reference proxies in the RSC bundle

## Compatibility Matrix

| Component                                                        | Rspack Compatible  | Notes                                                                           |
| ---------------------------------------------------------------- | ------------------ | ------------------------------------------------------------------------------- |
| **RSC bundle config** (`rscWebpackConfig.js`)                    | Yes                | Does not use WebpackPlugin; only uses loader + resolve settings                 |
| **WebpackLoader** (`react-on-rails-rsc/WebpackLoader`)           | Yes                | Standard loader interface (`this.resourcePath`, source transform)               |
| **`conditionNames: ['react-server', '...']`**                    | Yes                | Rspack supports conditional exports resolution                                  |
| **`resolve.alias`** (`react-dom/server: false`)                  | Yes                | Rspack supports alias to `false`                                                |
| **`LimitChunkCountPlugin`**                                      | Yes                | Generated configs use bundler-agnostic `bundler.optimize.LimitChunkCountPlugin` |
| **Loader chain (SWC + Babel)**                                   | Yes                | Generated config handles both `function` and `Array` `rule.use` styles          |
| **WebpackPlugin** (`react-on-rails-rsc/WebpackPlugin`)           | Needs verification | Uses webpack internal APIs (see below)                                          |
| **Three-bundle build** (`RSC_BUNDLE_ONLY`, `SERVER_BUNDLE_ONLY`) | Yes                | Environment variable routing is bundler-agnostic                                |

## WebpackPlugin Compatibility Details

The `RSCWebpackPlugin` is the critical compatibility question. It wraps React's
`react-server-dom-webpack/plugin`, which uses these webpack internal APIs:

- `webpack/lib/dependencies/ModuleDependency` — base class for dependency tracking
- `webpack/lib/dependencies/NullDependency` — null dependency template
- `webpack/lib/Template` — template utilities
- `webpack.AsyncDependenciesBlock` — async dependency blocks
- `webpack.Compilation.PROCESS_ASSETS_STAGE_REPORT` — asset processing hooks
- `webpack.sources.RawSource` — source output
- Compiler hooks: `beforeCompile`, `thisCompilation`, `make`
- Compilation hooks: `processAssets`
- Parser hooks: `program`
- `compilation.chunkGraph` — chunk/module graph traversal

**Why this matters**: The plugin generates `react-client-manifest.json` and
`react-ssr-manifest.json`, which map client component file paths to their chunk
IDs and bundle filenames. Without these manifests, the RSC runtime cannot resolve
`'use client'` component references during streaming.

**Rspack v2 compatibility**: Rspack v2 has significantly improved webpack plugin
compatibility. The [Rspack team has confirmed](https://github.com/shakacode/react_on_rails/issues/1828#issuecomment-3350629010)
that Rspack supports RSC with the JavaScript API. However, runtime verification
with the specific `react-on-rails-rsc` plugin is still needed.

## How the RSC Bundle Avoids the Plugin

The RSC bundle config (`rscWebpackConfig.js`) calls `serverWebpackConfig(true)`,
which skips adding `RSCWebpackPlugin`. The RSC bundle only uses:

1. The **WebpackLoader** to transform `'use client'` files into client reference proxies
2. **`conditionNames: ['react-server', '...']`** to resolve React's server entry points
3. **Aliases** to exclude `react-dom/server` from the RSC bundle

This means the RSC bundle itself should work with Rspack today. The plugin is only
added to the **server** and **client** bundles for manifest generation.

## Testing with Rspack

To test RSC with Rspack in your project:

1. Ensure `assets_bundler: rspack` is set in `config/shakapacker.yml`
2. Run the RSC generator: `rails generate react_on_rails:rsc`
3. Verify configs are in `config/rspack/`
4. Build all three bundles and check for:
   - `rsc-bundle.js` in the output
   - `react-client-manifest.json` and `react-ssr-manifest.json` (from the plugin)
   - No webpack/Rspack compilation errors

## Known Limitations

1. **No `react-server-dom-rspack` package**: React does not ship a dedicated Rspack
   variant of the RSC wire protocol. The `react-server-dom-webpack` package is used,
   relying on Rspack's webpack compatibility layer.

2. **Plugin `require('webpack')` call**: The `react-server-dom-webpack/plugin`
   internally calls `require('webpack')`, which loads webpack even in Rspack projects.
   Rspack's compatibility layer must intercept the compiler/compilation interactions
   for the plugin to function correctly.

3. **No official React Rspack support**: The React team has not officially tested or
   endorsed `react-server-dom-webpack` with Rspack. Compatibility is provided by
   Rspack's webpack API compatibility layer.

## Related Resources

- [Issue #1828: Rspack support for RSC](https://github.com/shakacode/react_on_rails/issues/1828)
- [Rspack RSC support PR](https://github.com/web-infra-dev/rspack/pull/5824)
- [Three-bundle architecture](./how-react-server-components-work.md)
- [Upgrading an existing Pro app to RSC](./upgrading-existing-pro-app.md)

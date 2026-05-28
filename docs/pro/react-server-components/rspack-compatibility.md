# Rspack Compatibility with React Server Components

> **Status**: Experimental — generated Rspack configs now emit the RSC manifests; full Pro Node Renderer hydration verification is still in progress.

This page documents the compatibility status of [Rspack](https://rspack.dev/) with React on Rails Pro's React Server Components (RSC) implementation.

## Overview

React on Rails Pro's RSC implementation uses a three-bundle architecture (client, server, RSC).
The generator already supports Rspack — when `assets_bundler: rspack` is detected in `shakapacker.yml`, all RSC config files are created in `config/rspack/` instead of `config/webpack/`.

The RSC implementation depends on the `react-on-rails-rsc` npm package, which provides:

- **WebpackPlugin** — generates client/server component manifest files for webpack builds
- **WebpackLoader** — transforms `'use client'` files into client reference proxies in the RSC bundle

For Rspack builds, generated configs use `config/rspack/rscManifestPlugin.js` instead of applying
`react-on-rails-rsc/WebpackPlugin` directly. The helper scans Shakapacker source paths for `'use client'`
modules, adds those modules to the client and server bundle graphs, and emits the two manifest files
expected by the Pro Node Renderer:

- `react-client-manifest.json`
- `react-server-client-manifest.json`

## Compatibility Matrix

| Component                                                        | Rspack Compatible | Notes                                                                           |
| ---------------------------------------------------------------- | ----------------- | ------------------------------------------------------------------------------- |
| **RSC bundle config** (`rscWebpackConfig.js`)                    | Yes               | Does not use WebpackPlugin; only uses loader + resolve settings                 |
| **WebpackLoader** (`react-on-rails-rsc/WebpackLoader`)           | Yes               | Standard loader interface (`this.resourcePath`, source transform)               |
| **`conditionNames: ['react-server', '...']`**                    | Yes               | Rspack supports conditional exports resolution                                  |
| **`resolve.alias`** (`react-dom/server: false`)                  | Yes               | Rspack supports alias to `false`                                                |
| **`LimitChunkCountPlugin`**                                      | Yes               | Generated configs use bundler-agnostic `bundler.optimize.LimitChunkCountPlugin` |
| **Loader chain (SWC + Babel)**                                   | Yes               | Generated config handles both `function` and `Array` `rule.use` styles          |
| **WebpackPlugin** (`react-on-rails-rsc/WebpackPlugin`)           | Webpack only      | Uses webpack internal APIs (see below)                                          |
| **Rspack manifest helper** (`rscManifestPlugin.js`)              | Yes               | Emits the Pro RSC client/server manifests without webpack-only plugin APIs      |
| **Three-bundle build** (`RSC_BUNDLE_ONLY`, `SERVER_BUNDLE_ONLY`) | Yes               | Environment variable routing is bundler-agnostic                                |

## WebpackPlugin Compatibility Details

The `RSCWebpackPlugin` remains the webpack path. It wraps React's
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
`react-server-client-manifest.json`, which map client component file paths to their chunk
IDs and bundle filenames. Without these manifests, the RSC runtime cannot resolve
`'use client'` component references during streaming.

**Rspack v2 compatibility**: Applying this webpack plugin directly to Rspack is not supported.
Rspack does not expose every webpack compiler and compilation object used by the plugin. Generated
Rspack configs therefore route manifest generation through `rscManifestPlugin.js`, which uses Rspack's
public compilation hooks and keeps the existing `react-on-rails-rsc` wire protocol.

## How the RSC Bundle Avoids the Plugin

The RSC bundle config (`rscWebpackConfig.js`) calls `serverWebpackConfig(true)`,
which skips adding `RSCWebpackPlugin`. The RSC bundle only uses:

1. The **WebpackLoader** to transform `'use client'` files into client reference proxies
2. **`conditionNames: ['react-server', '...']`** to resolve React's server entry points
3. **Aliases** to exclude `react-dom/server` from the RSC bundle

This means the RSC bundle itself should work with Rspack today. The plugin is only
added to the **server** and **client** bundles for manifest generation when using webpack. With Rspack,
the generated manifest helper is added to those bundles instead.

## Testing with Rspack

To test RSC with Rspack in your project:

1. Ensure `assets_bundler: rspack` is set in `config/shakapacker.yml`
2. Run the RSC generator: `rails generate react_on_rails:rsc`
3. Verify configs are in `config/rspack/`
4. Build all three bundles and check for:
   - `rsc-bundle.js` in the output
   - `react-client-manifest.json`
   - `react-server-client-manifest.json`
   - No webpack/Rspack compilation errors

## Known Limitations

1. **Runtime support remains experimental**: The generated Rspack helper emits the manifests
   expected by React on Rails Pro, but each app should still verify an interactive `'use client'`
   boundary through the Pro Node Renderer before treating Rspack + RSC as production-ready.

2. **Plugin `require('webpack')` call**: The `react-server-dom-webpack/plugin`
   internally calls `require('webpack')`, which loads webpack even in Rspack projects.
   Generated Rspack configs avoid that direct plugin path and use `rscManifestPlugin.js`.

3. **New client files may need a dev-server restart**: The generated helper scans
   Shakapacker source paths while the Rspack config is evaluated. Editing an existing
   `'use client'` file is picked up by normal rebuilds, but adding a brand-new client
   component while `rspack serve` is already running may require restarting the dev server
   so the helper can add that file to the bundle entries. This scan is synchronous and runs
   once in each generated client/server config at startup, so very large source trees can add
   bundler startup time. Missing-reference warnings are deduped for the dev-server session; if
   a warned reference later fixes and regresses, restart the dev server to see that warning again.

4. **Wildcard named-export tracking**: The Rspack helper records each client reference with
   `name: '*'` rather than enumerating individual named exports through `compilation.moduleGraph`
   the way `RSCWebpackPlugin` does on webpack. Apps that destructure named exports from
   `'use client'` modules across the server/client boundary should verify those code paths
   under Rspack; if the RSC runtime relies on specific export names, stay on webpack for now
   or contribute a Rspack-side enumeration.

5. **Native Rspack RSC is a future migration path**: Rspack documents native RSC support through
   `@rspack/core`'s `experiments.rsc` APIs and `react-server-dom-rspack`, but that path currently
   targets React 19.1+ and a different manifest/runtime shape. React on Rails Pro's current RSC
   integration stays on the `react-on-rails-rsc` protocol for React 19.0.x compatibility.

## Related Resources

- [Issue #1828: Rspack support for RSC](https://github.com/shakacode/react_on_rails/issues/1828)
- [Rspack RSC support PR](https://github.com/web-infra-dev/rspack/pull/5824)
- [Rspack React Server Components guide](https://v2.rspack.rs/guide/tech/rsc)
- [Three-bundle architecture](./how-react-server-components-work.md)
- [Upgrading an existing Pro app to RSC](./upgrading-existing-pro-app.md)

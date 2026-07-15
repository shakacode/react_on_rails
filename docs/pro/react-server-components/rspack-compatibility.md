# Rspack Compatibility with React Server Components

> **Status**: Experimental — the generator scaffolds the native Rspack plugin and the proven runtime path, but the end-to-end gate is not yet wired into this repo's CI. See [issue #3488](https://github.com/shakacode/react_on_rails/issues/3488).

This page documents the compatibility status of [Rspack](https://rspack.dev/) with React on Rails Pro's React Server Components (RSC) implementation.

## Overview

React on Rails Pro's RSC implementation uses a three-bundle architecture (client, server, RSC).
The generator supports Rspack — when `assets_bundler: rspack` is detected in `shakapacker.yml`, all RSC config files are created in `config/rspack/` instead of `config/webpack/`, and the server/client configs are scaffolded with the **native `RSCRspackPlugin`** instead of `RSCWebpackPlugin`.

The RSC implementation depends on the `react-on-rails-rsc` npm package, which provides bundler-specific manifest plugins plus a shared loader:

- **WebpackPlugin** (`react-on-rails-rsc/WebpackPlugin`) — generates client/server component manifest files under webpack.
- **RspackPlugin** (`react-on-rails-rsc/RspackPlugin`) — the rspack-native equivalent (`RSCRspackPlugin`). It emits the **same manifest JSON schema** using only standard rspack public APIs, so the RSC runtime resolves client references identically. Exported by stable `react-on-rails-rsc` 19.2.1 and later on the 19.2.x package line.
- **WebpackLoader** (`react-on-rails-rsc/WebpackLoader`) — transforms `'use client'` files into client reference proxies in the RSC bundle. Works under both webpack and rspack.

## React and Package Version Policy

Generated RSC apps on React on Rails Pro 17 use React 19.2.x: `react@~19.2.7`
and `react-dom@~19.2.7`. React 19.0.x is no longer a supported Pro RSC runtime
line in v17 because the generator, peer metadata, and node-renderer startup check
now target the coordinated React 19.2.7 / `react-on-rails-rsc` 19.2.1 package
line.

The React on Rails Pro 17 generator pins stable `react-on-rails-rsc@19.2.1`
for both webpack and rspack projects. Keep React, React DOM, and
`react-on-rails-rsc` upgraded as a coordinated set.

## Compatibility Matrix

| Component                                                        | Rspack Compatible  | Notes                                                                           |
| ---------------------------------------------------------------- | ------------------ | ------------------------------------------------------------------------------- |
| **RSC bundle config** (`rscWebpackConfig.js`)                    | Yes                | Does not use WebpackPlugin; only uses loader + resolve settings                 |
| **WebpackLoader** (`react-on-rails-rsc/WebpackLoader`)           | Yes                | Standard loader interface (`this.resourcePath`, source transform)               |
| **`conditionNames: ['react-server', '...']`**                    | Yes                | Rspack supports conditional exports resolution                                  |
| **React server file aliases**                                    | Yes                | Rspack supports exact aliases that keep React's RSC dispatcher shared           |
| **`resolve.alias`** (`react-dom/server: false`)                  | Yes                | Rspack supports alias to `false`                                                |
| **`LimitChunkCountPlugin`**                                      | Yes                | Generated configs use bundler-agnostic `bundler.optimize.LimitChunkCountPlugin` |
| **Loader chain (SWC + Babel)**                                   | Yes                | Generated config handles both `function` and `Array` `rule.use` styles          |
| **Manifest plugin** (`RSCRspackPlugin`)                          | Yes                | Native rspack plugin; emits the same manifest schema (see below)                |
| **WebpackPlugin** (`react-on-rails-rsc/WebpackPlugin`)           | Not used on rspack | Replaced by `RSCRspackPlugin` under rspack; remains the webpack-only plugin     |
| **Three-bundle build** (`RSC_BUNDLE_ONLY`, `SERVER_BUNDLE_ONLY`) | Yes                | Environment variable routing is bundler-agnostic                                |

## Manifest Plugin: Native `RSCRspackPlugin`

The manifest plugin is the critical compatibility question. It generates
`react-client-manifest.json` and `react-server-client-manifest.json`, which map client
component file paths to their chunk IDs and bundle filenames. Without these manifests, the
RSC runtime cannot resolve `'use client'` component references during streaming.

Under **webpack**, this is `RSCWebpackPlugin`, which wraps React's
`react-server-dom-webpack/plugin` and depends on webpack-internal APIs
(`webpack/lib/dependencies/*`, `webpack.AsyncDependenciesBlock`,
`compilation.chunkGraph`, the `processAssets`/`thisCompilation`/`make` hooks, etc.).

Under **rspack**, the generator instead scaffolds the native **`RSCRspackPlugin`**
(`react-on-rails-rsc/RspackPlugin`). Rather than rely on Rspack's webpack-compatibility
layer for those internal APIs, the native plugin emits the **same manifest JSON schema**
using only standard rspack public APIs. It discovers `'use client'` modules with a tagging
loader, injects them as named async chunks, and walks `compilation.chunkGroups` at
`processAssets`. Because the output schema is identical, the RSC runtime
(`buildServerRenderer` / `buildClientRenderer`) works unchanged regardless of bundler. The
two plugins share the same `{ isServer, clientReferences }` options.

> [!NOTE]
> **Why native instead of the webpack plugin under Rspack's compat layer?** A controlled
> A/B on a real app showed the webpack-plugin path producing valid-looking manifests that
> still failed ~7/11 RSC routes at runtime under Rspack, while the native `RSCRspackPlugin`
> rendered and hydrated every route. The native plugin is therefore the supported Rspack
> path. The remaining work to drop the "experimental" label — wiring the demo
> route-hydration gate into this repo's CI — is tracked in [issue #3488](https://github.com/shakacode/react_on_rails/issues/3488)
> (superseding the abandoned manifest-helper approach in
> [PR #3385](https://github.com/shakacode/react_on_rails/pull/3385)).

## How the RSC Bundle Avoids the Plugin

The RSC bundle config (`rscWebpackConfig.js`) calls `serverWebpackConfig(true)`,
which skips adding the manifest plugin (`RSCRspackPlugin` under rspack,
`RSCWebpackPlugin` under webpack). The RSC bundle only uses:

1. The **WebpackLoader** to transform `'use client'` files into client reference proxies
2. **`conditionNames: ['react-server', '...']`** to resolve React's server entry points
3. **React server file aliases** to keep the RSC renderer and app Server Components on one React server package instance
4. **Aliases** to exclude `react-dom/server` from the RSC bundle

The manifest plugin is only added to the **server** and **client** bundles.

## Testing with Rspack

To test RSC with Rspack in your project:

1. Ensure `assets_bundler: rspack` is set in `config/shakapacker.yml`
2. Run the RSC generator: `rails generate react_on_rails:rsc`
3. Verify configs are in `config/rspack/`
4. Build all three bundles and check for:
   - `rsc-bundle.js` in the output
   - `react-client-manifest.json` and `react-server-client-manifest.json` (from `RSCRspackPlugin`)
   - No Rspack compilation errors

## Known Limitations

1. **React on Rails does not use Rspack's experimental native RSC system**:
   As of Rspack v2, Rspack ships its own [built-in RSC
   support](https://v2.rspack.rs/guide/tech/rsc) (driven by `builtin:swc-loader` and
   `rspackExperiments.reactServerComponents`). React on Rails Pro does **not** use that
   experimental path. Its RSC integration is built on the `react-on-rails-rsc` package:
   manifest generation uses the native **`RSCRspackPlugin`** (standard rspack public APIs,
   not Rspack's webpack-compatibility layer), while the RSC bundle still uses the
   `react-server-dom-webpack` loader and runtime.

2. **The RSC bundle still uses the `react-server-dom-webpack` loader**: Only the
   manifest plugin is bundler-native. The RSC bundle transforms `'use client'` files with
   `react-on-rails-rsc/WebpackLoader` (which wraps React's `react-server-dom-webpack`
   node loader) under both bundlers. This loader is compatible with rspack.

3. **No official React Rspack support**: The React team has not officially tested or
   endorsed the `react-server-dom-webpack` runtime with Rspack. The native
   `RSCRspackPlugin` is maintained by ShakaCode in `react-on-rails-rsc`.

## Related Resources

- [Issue #3488: Rspack RSC path to production-ready (native RSCRspackPlugin)](https://github.com/shakacode/react_on_rails/issues/3488)
- [Issue #1828: Rspack support for RSC](https://github.com/shakacode/react_on_rails/issues/1828)
- [PR #3385: Manifest-helper approach for Rspack builds (superseded by the native plugin)](https://github.com/shakacode/react_on_rails/pull/3385)
- [Rspack v2 React Server Components guide](https://v2.rspack.rs/guide/tech/rsc)
- [Three-bundle architecture](./how-react-server-components-work.md)
- [Upgrading an existing Pro app to RSC](./upgrading-existing-pro-app.md)

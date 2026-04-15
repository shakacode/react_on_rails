# RSC + Rspack Implementation Plan

Planning/investigation doc for issue [shakacode/react_on_rails#3141](https://github.com/shakacode/react_on_rails/issues/3141).

**Audience:** React on Rails + Shakapacker maintainer with strong webpack knowledge and no deep rspack internals experience.

**Goal:** Drive a decision on _how_ to make React Server Components (RSC) run end-to-end under rspack before a single line of production code is written.

**Status tags used in this doc:**
- **VERIFIED** — confirmed by source reading in this repo
- **NEEDS VERIFICATION** — plausible but not runtime-tested
- **UNKNOWN** — open question
- **ASSUMED** — working assumption; flag before committing

---

## Table of Contents

1. [Current Architecture Overview](#1-current-architecture-overview)
2. [Compatibility Analysis (Webpack vs Rspack)](#2-compatibility-analysis-webpack-vs-rspack)
3. [Critical Discussion Points](#3-critical-discussion-points-decide-before-coding)
4. [Refactoring Opportunities](#4-refactoring-opportunities-before-implementation)
5. [Implementation Plan (Phased)](#5-implementation-plan-phased)
6. [Open Questions and Unknowns](#6-open-questions-and-unknowns)
7. [Risk Matrix](#7-risk-matrix)
8. [Related Links / References](#8-related-links--references)

---

## 1. Current Architecture Overview

### 1.1 Three-bundle architecture

RSC requires three separate bundles. Each is produced from the same monorepo source but with different loaders, conditions, and targets:

| Bundle | Config file | Runtime | Purpose |
|---|---|---|---|
| Client | `config/webpack/clientWebpackConfig.js` | Browser | Ships `use client` components + hydration runtime |
| Server (SSR) | `config/webpack/serverWebpackConfig.js` | VM sandbox via `vm.createContext` inside the Node renderer | Renders HTML (including server components) |
| RSC | `config/webpack/rscWebpackConfig.js` | Full Node | Renders the RSC Flight payload (server components are real; client components are turned into `registerClientReference` stubs) |

VERIFIED in the Pro dummy: `react_on_rails_pro/spec/dummy/config/webpack/{client,server,rsc}WebpackConfig.js`.

Routing between the three is controlled by env vars (`CLIENT_BUNDLE_ONLY`, `SERVER_BUNDLE_ONLY`, `RSC_BUNDLE_ONLY`) inside `ServerClientOrBoth.js` — the single entrypoint invoked by `webpack.config.js` / `rspack.config.js`. See `react_on_rails/lib/generators/react_on_rails/templates/base/base/config/webpack/ServerClientOrBoth.js.tt`.

### 1.2 Where the RSC webpack plugin/loader are wired

The `react-on-rails-rsc` npm package ships two build-time hooks:

| Hook | Attached to | What it does |
|---|---|---|
| `react-on-rails-rsc/WebpackLoader` | RSC bundle only | Runs `react-server-dom-webpack-node-loader.production.js#load()` over every JS/TS file. Files with a `"use client"` directive get every export rewritten to a `registerClientReference(…)` stub (see `docs/pro/react-server-components/how-react-server-components-work.md:9-73`) |
| `RSCWebpackPlugin` (wrapping `react-server-dom-webpack/plugin`) | Client **and** Server (SSR) bundles; **intentionally NOT on the RSC bundle** | Discovers `"use client"` files, emits each as a webpack entry, and writes `react-client-manifest.json` + `react-ssr-manifest.json` |

The RSC bundle opts out via `serverWebpackConfig(true)` (see `react_on_rails/lib/generators/react_on_rails/templates/rsc/base/config/webpack/rscWebpackConfig.js.tt:22-23`). That's why current docs say the RSC bundle itself "should work with rspack today" — it uses only a loader + `resolve.conditionNames + resolve.alias`, which are vanilla bundler features.

The WebpackPlugin is the hard part. It is attached in both `clientWebpackConfig.js` and `serverWebpackConfig.js` templates (behind `<% if use_rsc? %>` blocks) and is the sole producer of the two manifest files that React's runtime needs.

### 1.3 Webpack internals the plugin reaches into

From `packages/react-on-rails-rsc/src/react-server-dom-webpack/cjs/react-server-dom-webpack-plugin.js` (vendored copy inside the `react-on-rails-rsc` repo at `/mnt/ssd/react-on-rails-rsc/src/react-server-dom-webpack/cjs/react-server-dom-webpack-plugin.js:12-19`, 409 lines total):

```js
var path = require("path"),
    url = require("url"),
    asyncLib = require("neo-async"),
    acorn = require("acorn-loose"),
    ModuleDependency = require("webpack/lib/dependencies/ModuleDependency"),
    NullDependency = require("webpack/lib/dependencies/NullDependency"),
    Template = require("webpack/lib/Template"),
    webpack = require("webpack");
```

Specific webpack internals exercised:

| Webpack API | File:line | What it does in the plugin |
|---|---|---|
| `webpack/lib/dependencies/ModuleDependency` | `react-server-dom-webpack-plugin.js:16, 87` | Base class for `ClientReferenceDependency` — a custom dependency type |
| `webpack/lib/dependencies/NullDependency` | `react-server-dom-webpack-plugin.js:17, 161` | Template for rendering the dependency as nothing (just registering it) |
| `webpack/lib/Template` | `react-server-dom-webpack-plugin.js:18, 177` | `Template.toPath()` to sanitize chunk names from user requests |
| `webpack.AsyncDependenciesBlock` | `react-server-dom-webpack-plugin.js:178` | Creates a split chunk per `use client` file |
| `webpack.Compilation.PROCESS_ASSETS_STAGE_REPORT` | `react-server-dom-webpack-plugin.js:203` | Hooks into the final asset-emission stage |
| `webpack.sources.RawSource` | `react-server-dom-webpack-plugin.js:300` | Emits the manifest JSON as an asset |
| `webpack.WebpackError` | `react-server-dom-webpack-plugin.js:208` | Pushes a compilation warning |
| Compiler hooks | `react-server-dom-webpack-plugin.js:134, 154, 199` | `beforeCompile` (resolve client references), `thisCompilation` (register dep factories + parser hooks), `make` (attach `processAssets`) |
| Compilation hooks | `react-server-dom-webpack-plugin.js:200` | `processAssets` (emit the manifest) |
| `compilation.dependencyFactories.set` | `react-server-dom-webpack-plugin.js:158` | Tell webpack how to resolve `ClientReferenceDependency` |
| `compilation.dependencyTemplates.set` | `react-server-dom-webpack-plugin.js:159` | Tell webpack how to render the dep |
| `normalModuleFactory.hooks.parser.for('javascript/{auto,esm,dynamic}').tap` | `react-server-dom-webpack-plugin.js:188-196` | Intercept parsing of the `react-on-rails-rsc/client.{browser,node}.js` modules to inject dependencies for every `use client` file |
| `parser.hooks.program.tap` | `react-server-dom-webpack-plugin.js:164` | AST-level hook: fires at the top of every parsed module |
| `parser.state.module.addBlock(asyncBlock)` | `react-server-dom-webpack-plugin.js:184` | Programmatically attach an async dep block to the registration module |
| `compilation.chunkGraph.getChunkModulesIterable` | `react-server-dom-webpack-plugin.js:282` | Traverse every module in every chunk |
| `compilation.chunkGraph.getModuleId` | `react-server-dom-webpack-plugin.js:284` | Resolve concrete module IDs |
| `compilation.chunkGroups`, `entrypoint.getRuntimeChunk()` | `react-server-dom-webpack-plugin.js:235-241, 241` | Walk runtime chunks to build the manifest |
| `compilation.emitAsset` | `react-server-dom-webpack-plugin.js:298` | Write the manifest file |

This is _deep_ webpack — well past the public plugin surface. It is the hardest chunk of the compatibility story.

### 1.4 What the two manifests do

The plugin emits two JSON files into the public output dir (`public/packs/...` or equivalent):

- **`react-client-manifest.json`** — consumed by the RSC bundle at render time. Maps `file:///absolute/path/to/Component.jsx` → `{ id, chunks: [chunkId, chunkFile, …], name }`. Read from disk by `buildServerRenderer` in `/mnt/ssd/react-on-rails-rsc/src/server.node.ts:16-27`. Its `filePathToModuleMetadata` is passed to React's `renderToPipeableStream` so the Flight payload can reference client components by module ID + chunk filenames.
- **`react-ssr-manifest.json`** — consumed during SSR of the Flight payload in `buildClientRenderer` (`/mnt/ssd/react-on-rails-rsc/src/client.node.ts:4-33`). Cross-references `clientManifest.filePathToModuleMetadata[x].id` with the server bundle's module IDs so that the SSR pass can actually require the client component implementation.

### 1.5 Runtime primitives baked into React's Flight client

VERIFIED in `/mnt/ssd/react-on-rails-rsc/src/react-server-dom-webpack/cjs/react-server-dom-webpack-client.browser.production.js:58-112`:

```js
var promise = __webpack_require__(id);
...
chunkFilename = __webpack_chunk_load__(chunkId);
...
webpackGetChunkFilename = __webpack_require__.u;
__webpack_require__.u = function (chunkId) { ... };
```

React's _runtime_ code (not just the build-time plugin) depends on:
- `__webpack_require__(id)` — synchronous module access by ID
- `__webpack_chunk_load__(chunkId)` — promise-returning chunk loader
- `__webpack_require__.u` — chunk filename resolver (React monkey-patches it to inject `crossOrigin` / `moduleLoading.prefix`)

Rspack v1+ emits webpack-compatible runtime code (`__webpack_require__` etc.) by design, so the runtime piece is NEEDS VERIFICATION but is substantially more likely to "just work" than the plugin. See §2.

### 1.6 Generator integration

The generator logic that wires all this up (VERIFIED):

- `react_on_rails/lib/generators/react_on_rails/rsc_generator.rb` — thin wrapper calling `rsc_setup.rb`
- `react_on_rails/lib/generators/react_on_rails/rsc_setup.rb` — 705 lines doing the orchestration:
  - `create_rsc_webpack_config` (line 149) — copies `rscWebpackConfig.js.tt` to destination
  - `update_server_webpack_config_for_rsc` (line 374) — injects `RSCWebpackPlugin` via regex
  - `update_client_webpack_config_for_rsc` (line 413) — injects `RSCWebpackPlugin` via regex
  - `update_server_client_or_both_for_rsc` (line 318) — wires the RSC bundle into the dispatcher
- `generator_helper.rb:203-207` — `destination_config_path` remaps `config/webpack/` → `config/rspack/` for rspack projects
- `generator_helper.rb:373-379` — `rspack_configured_in_project?` detects rspack via `shakapacker.yml`

The generator already produces correct content for rspack projects today — the _generated output_ is bundler-agnostic. What's unverified is whether `RSCWebpackPlugin`, once installed, will _run_ under rspack.

### 1.7 RSC runtime flow (for reference)

From `docs/pro/react-server-components/rendering-flow.md:82-107`:

1. View calls `stream_react_component` → Node renderer gets rendering request
2. Server bundle calls `generateRSCPayload(name, props)` (global injected by the Node renderer; see `packages/react-on-rails-pro/src/RSCRequestTracker.ts:32-38`)
3. RSC bundle runs → produces Flight payload stream
4. Server bundle (via `react-on-rails-rsc/client.node` → `buildClientRenderer`) decodes the Flight payload back into React elements, rendering HTML + embedding the Flight payload into the response
5. Client bundle hydrates from embedded Flight payload (no separate round-trip)

The client/server bundle pair's ability to do step 4 depends entirely on `react-ssr-manifest.json` + `react-client-manifest.json`, which exist only if `RSCWebpackPlugin` ran successfully.

---

## 2. Compatibility Analysis (Webpack vs Rspack)

### 2.1 Build time — what each component needs from the bundler

Legend: ✅ works unchanged · ⚠️ expected to work, needs runtime verification · ❌ definitely won't work without rspack-side changes or our own adapter

| Component | File | Webpack | Rspack v1 | Rspack v2 | Notes |
|---|---|---|---|---|---|
| RSC bundle config (loader chain, `resolve.conditionNames`, `resolve.alias`) | `rscWebpackConfig.js.tt` | ✅ | ✅ | ✅ | Vanilla bundler surface. Already covered by 9 generator specs added in #3120 |
| `react-on-rails-rsc/WebpackLoader` | `src/WebpackLoader.ts` | ✅ | ⚠️ | ⚠️ | Uses `this.resourcePath` + async source transform (standard loader API). Almost certainly works. The `await import('./…-node-loader.production.js')` path ships ESM; rspack's ESM loader interop needs verification |
| `extractLoader` helper (function vs array `rule.use`) | `rscWebpackConfig.js.tt:34-61` | ✅ | ✅ | ✅ | Covered by generator specs; handles SWC (function) and Babel (array) styles |
| `resolve.alias: { 'react-dom/server': false }` | `rscWebpackConfig.js.tt:69-74` | ✅ | ✅ | ✅ | Rspack supports `alias: false` (VERIFIED in Rspack docs & existing shakapacker `resolve.fallback` usage) |
| `conditionNames: ['react-server', '...']` | `rscWebpackConfig.js.tt:66-68` | ✅ | ✅ | ✅ | Rspack supports `conditionNames` and the `'...'` continuation token |
| `LimitChunkCountPlugin` | `serverWebpackConfig.js.tt:84` | ✅ | ✅ | ✅ | Accessed via `bundler.optimize.LimitChunkCountPlugin` where `bundler = require('@rspack/core')` — rspack exports this |
| `RSCWebpackPlugin` → `react-server-dom-webpack/plugin` | `react-on-rails-rsc/WebpackPlugin.ts` → vendored plugin | ✅ | ❌ most likely | ⚠️ | The nine specific internal APIs in §1.3 are the crux. Rspack's "webpack plugin compat layer" covers most public hooks but is known to not cover `webpack/lib/dependencies/ModuleDependency` direct imports. See §2.2 below |
| Three-bundle env routing (`RSC_BUNDLE_ONLY`) | `ServerClientOrBoth.js.tt` | ✅ | ✅ | ✅ | Pure JS env var check; bundler-independent |

### 2.2 `RSCWebpackPlugin` — the blocker in detail

The plugin does four distinct things. Each has a different compatibility picture:

#### (a) Discover `"use client"` files

File: `react-server-dom-webpack-plugin.js:307-407`.

Uses `compiler.resolverFactory.get('context')` and `contextModuleFactory.resolveDependencies()`. **VERIFIED to exist in rspack** (rspack exposes `resolverFactory` as part of its webpack-compat API). ASSUMED to work.

#### (b) Register `ClientReferenceDependency` as a webpack dependency type

File: `react-server-dom-webpack-plugin.js:87-94, 158-162`.

```js
class ClientReferenceDependency extends ModuleDependency { … }
compilation.dependencyFactories.set(ClientReferenceDependency, normalModuleFactory);
compilation.dependencyTemplates.set(ClientReferenceDependency, new NullDependency.Template());
```

This requires `require('webpack/lib/dependencies/ModuleDependency')` to resolve to a real class with the expected shape. Rspack does **not** provide `webpack/lib/…` deep paths. There are three possible outcomes:

1. If `webpack` is also installed (common in a rspack project because shakapacker still has it as a devDep): `require('webpack/lib/…')` resolves to real webpack internals. But the _compiler_ passed to `apply()` is from rspack. Mixing a webpack-class-derived dependency with an rspack compilation is untested. — NEEDS VERIFICATION
2. If `webpack` is not installed: `require` throws, and the plugin crashes on load before ever seeing the compiler. — VERIFIED via code inspection
3. Rspack's webpack-compat layer might transparently aliasing `webpack/lib/dependencies/*` to rspack equivalents in v2. — UNKNOWN

The Rspack team's public statement (see [#1828 comment from @SyMind](https://github.com/shakacode/react_on_rails/issues/1828#issuecomment-3350629010)) says rspack "already supports RSC with JavaScript API", citing Next.js. Next.js, however, uses its _own_ bundled RSC plugin, not `react-server-dom-webpack/plugin`. So this comment does not directly answer our question.

#### (c) Attach async dependency blocks

File: `react-server-dom-webpack-plugin.js:178-184`:

```js
chunkName = new webpack.AsyncDependenciesBlock({ name: chunkName }, null, dep.request);
chunkName.addDependency(dep);
module.addBlock(chunkName);
```

`webpack.AsyncDependenciesBlock` is available on the top-level `webpack` export. Rspack v2 ASSUMED to expose `AsyncDependenciesBlock` via `@rspack/core` for compat, but NEEDS VERIFICATION. Even if the class exists, calling `module.addBlock(asyncBlock)` on an rspack-originated `module` object assumes matching internal shape — a _behavioral_ compat question that can only be answered by runtime test.

#### (d) Walk the chunk graph + emit the manifest asset

File: `react-server-dom-webpack-plugin.js:235-301`:

```js
compilation.chunkGroups.forEach(…)
chunkGroup.chunks.forEach(c => { ... })
compilation.chunkGraph.getChunkModulesIterable(chunk)
compilation.chunkGraph.getModuleId(module)
compilation.emitAsset(name, new webpack.sources.RawSource(…))
```

`chunkGraph`, `chunkGroups`, `emitAsset`, and `sources.RawSource` are all standard webpack-compat APIs that rspack claims to support. ASSUMED to work. NEEDS VERIFICATION.

### 2.3 Runtime (React's Flight client inside the browser bundle)

`__webpack_require__(id)`, `__webpack_chunk_load__(chunkId)`, and `__webpack_require__.u` are emitted by both webpack and rspack in the generated runtime code. Rspack explicitly treats these globals as part of its compatibility contract. ASSUMED to work without modification. This is the strongest part of the compat story.

### 2.4 Rspack v1 vs v2 summary

| Feature | v1 | v2 |
|---|---|---|
| `peerDependencies: ^1.0.0` in shakapacker | Yes | Yes (shakapacker currently pins `^1.5.8` devDep) |
| Webpack plugin compatibility layer | Partial | Improved |
| Hooks coverage (`beforeCompile`, `thisCompilation`, `processAssets`, etc.) | High | Higher |
| `webpack/lib/dependencies/*` deep imports | UNKNOWN | UNKNOWN |
| Production-stable | Yes | Beta → RC as of 2026-04 |
| Built-in RSC support | No | Being designed (per @chenjiahan, [rspack PR #5824 comment](https://github.com/web-infra-dev/rspack/pull/5824#issuecomment-3425376710), Oct 2025) |

Per Justin's direction (#1828 comment 2026-04-01): target v2. Shakapacker upgrade path needed because its current peerDep is `^1.0.0`.

---

## 3. Critical Discussion Points (decide BEFORE coding)

These are decisions that change the shape of the implementation. Resolve each one before Phase 2.

### 3.1 Single plugin vs separate plugins?

**Options:**

- **A. Single `RSCBundlerPlugin`** that feature-detects the compiler at `apply(compiler)` time and dispatches to either a webpack or rspack implementation.
- **B. Two separate exports:** `react-on-rails-rsc/WebpackPlugin` (unchanged) and `react-on-rails-rsc/RspackPlugin`. Generator picks the right one.
- **C. Single export that abstracts over a `BundlerPlugin` interface**, with two backends behind it.

**Trade-offs:**

- A has the smallest user-facing change but forces all rspack-specific logic to live next to webpack logic — hard to review.
- B makes the two paths explicit and easy to test independently. Users see "oh, this is the rspack one." More files to ship.
- C looks clean but adds indirection. Only worth it if the _logic_ is mostly shared — and it won't be if we ever write a from-scratch rspack manifest plugin.

**Recommendation placeholder:** Leaning toward **B**. Simpler to test and to evolve independently if rspack ships built-in RSC later.

### 3.2 Does `react-server-dom-webpack` work with rspack, or do we need an rspack-specific alternative?

This is the single biggest unknown. Three scenarios:

- **3.2.a — It works.** Runtime test passes; manifests generate correctly. Minimal work required; update docs only.
- **3.2.b — Build-time plugin fails, runtime works.** We need to write a replacement manifest plugin using rspack-native APIs (`Compilation.PROCESS_ASSETS_STAGE_REPORT` + `sources.RawSource` are supported). The replacement must produce identical JSON shape so `buildServerRenderer` / `buildClientRenderer` keep working unchanged.
- **3.2.c — Runtime breaks too.** We need to either (i) use a bundled `react-server-dom-rspack` if/when it exists, or (ii) wait for rspack's built-in RSC support. There's no evidence a `react-server-dom-rspack` package exists as of 2026-04.

**Action:** Phase 0 _must_ distinguish 3.2.a from 3.2.b before we commit to any architectural direction.

### 3.3 Rspack v1 vs v2 target

Justin's call: **v2**. v2 has better compatibility; shakapacker will need to bump its peerDep from `^1.0.0` to `^1.0.0 || ^2.0.0-0`. Potential downstream: users already on v1 get a supported config for longer if we DON'T bump. Decide:

- Support both v1 and v2 during a transition window (generator detects version; RSC docs call out the minimum required)
- Only support v2 for RSC (simpler; narrower surface to test)

**Recommendation placeholder:** Only v2 for RSC. Users on rspack v1 stick with non-RSC setups (which already work today).

### 3.4 How to handle `require('webpack')` inside `react-server-dom-webpack/plugin`?

Line 19 of the vendored plugin: `webpack = require("webpack");`. Even if the compiler is rspack, this forces the _webpack_ npm package to be installed so the `require` resolves.

Options:

- **Leave as-is; require users to keep `webpack` as a devDep.** Fragile: dependency sprawl; the compiler and the `webpack` module are not in sync, so some globals (`webpack.AsyncDependenciesBlock`) come from webpack but the compiler is rspack.
- **Module alias at install time:** Generator or install hook aliases `webpack` → `@rspack/core` in `package.json` (`resolutions` / `pnpm.overrides`). Brittle — rspack's top-level exports don't fully match webpack's.
- **Fork/patch the vendored plugin** in `react-on-rails-rsc` to accept a bundler instance via its constructor options (`new RSCWebpackPlugin({ isServer, bundler: require('@rspack/core') })`). Then no top-level `require` of `webpack` is needed. Requires patching `react-server-dom-webpack-plugin.js` — but the file is already vendored, so this is an option.
- **Use a Node `Module._resolveFilename` hook at install time** to redirect `webpack/lib/*` → rspack equivalents. Too hacky; reject.

**Recommendation placeholder:** Fork + patch the vendored plugin to receive an explicit `bundler` handle. This is a one-time change, localized to the `react-on-rails-rsc` package, and keeps us out of monkey-patching Node.

### 3.5 Rename `*WebpackConfig.js` → bundler-neutral names?

Issue #2552 is an open RFC. The rename is a breaking change across 5 templates + 57 Ruby refs + 181 spec refs + 15 dummy files + 18 doc files.

Options (abbreviated from #2552):
- **A.** Rename to `commonConfig.js`, `clientConfig.js`, `serverConfig.js`, `rscConfig.js`
- **B.** Keep names; add doc comment clarifying bundler-agnosticism
- **C.** Bundler-specific names per bundler (`serverRspackConfig.js` for rspack installs)
- **D.** Rename for new installs only; keep back-compat regex in the generator

**Recommendation placeholder:** Option D bundled into the next major version. Not a blocker for RSC-rspack work. **Do this work _separately_ to avoid entangling a breaking rename with the runtime verification.** If we _are_ going to do it anyway, do it before or after, not mixed in.

### 3.6 Testing strategy — separate CI job?

The current CI matrix (see `.github/workflows/pro-integration-tests.yml`) runs the Pro dummy's full test suite. Adding an rspack permutation doubles runtime for every RSC test. Options:

- **Dedicated smoke-test job:** `pro-rsc-rspack-smoke.yml` that only builds the three bundles + checks manifests exist + runs one E2E test. Fast.
- **Parametric matrix:** Every pro-integration test runs on both webpack and rspack. Comprehensive but expensive.
- **Separate dummy app:** `react_on_rails_pro/spec/dummy-rspack-rsc/` shadow app with identical specs. Maintainability nightmare.

**Recommendation placeholder:** Start with the smoke-test job. Graduate to a matrix _after_ the smoke test has been green for a while.

### 3.7 What to do about the two vendored pieces of React source?

`react-on-rails-rsc` currently vendors:
- `src/react-server-dom-webpack/cjs/` — compiled React runtime (client + server + static)
- `src/react-server-dom-webpack/esm/react-server-dom-webpack-node-loader.production.js`
- `src/react-server-dom-webpack/plugin.js` → `cjs/react-server-dom-webpack-plugin.js`

Vendoring means:
- We can patch (good for §3.4)
- We must track React upstream carefully — version bumps are non-trivial
- Users running the loader/plugin use OUR copy of React's internals

Decision: Do we continue vendoring, or depend on the published `react-server-dom-webpack` npm package?

**Recommendation placeholder:** Keep vendoring for now. Vendoring is what makes §3.4's "fork & patch the plugin" feasible. Revisit once React ships officially supported rspack variants.

---

## 4. Refactoring Opportunities (before implementation)

Cheap, invisible-to-users refactors that make the rspack work safer, smaller, and more reviewable. **Do these first.**

### 4.1 Extract the bundler-specific `require('webpack')` out of the plugin

**Current:** `react-server-dom-webpack-plugin.js` top-of-file hardcodes every webpack import.

**Proposed:** `WebpackPlugin.ts` already wraps the plugin. Change the wrapper to accept an injected `bundler` and re-export a constructor that reads from that bundler:

```ts
// react-on-rails-rsc/src/BundlerPlugin.ts (new name / new interface)
export interface BundlerPluginOptions {
  isServer: boolean;
  bundler?: typeof import('webpack') | typeof import('@rspack/core');
  // ...
}
```

Make `bundler` default to `require('webpack')` for back-compat. Then the vendored plugin accesses its dependencies via this option instead of `require()`-ing webpack directly. Small API change; shippable as a non-breaking minor of `react-on-rails-rsc`.

### 4.2 Normalize naming in `react-on-rails-rsc` package exports

**Current exports:** `./WebpackPlugin`, `./WebpackLoader` (with the "Webpack" literal baked in).

**Proposed:** Add `./BundlerPlugin` and `./BundlerLoader` as aliases. Keep the webpack-named exports for back-compat. Generator emits imports against the new names for new projects.

Same philosophy as #2552 but localized to this npm package — no Ruby generator ripples.

### 4.3 Lift the three-bundle awareness into a single module

**Current:** `ServerClientOrBoth.js` is template-assembled via ERB branching (`<% if use_rsc? %>`), and the env-var dispatch logic is rewritten by `rsc_setup.rb#update_server_client_or_both_for_rsc` (four `gsub_file` calls, lines 318-372, fragile regex).

**Proposed:** Ship a `buildBundleDispatcher(configs: { client, server, rsc? })` helper in `shakapacker` or in `react-on-rails`. The generated `ServerClientOrBoth.js` becomes:

```js
const { buildBundleDispatcher } = require('react-on-rails/bundler-dispatcher');
module.exports = buildBundleDispatcher({
  client: require('./clientConfig'),
  server: require('./serverConfig'),
  rsc: require('./rscConfig'), // omit for non-RSC installs
});
```

Generator stops surgical-editing the file; it just re-emits it when RSC is added. This also fixes the brittle `gsub_file` patterns in `rsc_setup.rb:318-372`.

Effort: medium. Risk: medium (changes a long-standing config layout). Not a blocker but a real gain.

### 4.4 Consolidate `extractLoader` in one place

Currently duplicated in:
- `react_on_rails/lib/generators/react_on_rails/templates/rsc/base/config/webpack/rscWebpackConfig.js.tt:12-19`
- `react_on_rails/lib/generators/react_on_rails/templates/base/base/config/webpack/serverWebpackConfig.js.tt:14-25`
- `react_on_rails_pro/spec/dummy/config/webpack/serverWebpackConfig.js:7-20`

And the RSC template has a fallback inline version. Propose exporting `extractLoader` from a small utility module in the generated config tree (`config/webpack/utils/extractLoader.js`) so there's one copy.

### 4.5 Move rspack-vs-webpack branching into a helper

**Current:** `const bundler = config.assets_bundler === 'rspack' ? require('@rspack/core') : require('webpack');` is duplicated in `serverWebpackConfig.js.tt` and (potentially) other templates.

**Proposed:** Export `resolveBundler()` from shakapacker (already exists under `shakapacker/webpack` and `shakapacker/rspack` sub-paths but not as a neutral resolver). Generated configs use that once.

Discuss this with the shakapacker team — cross-repo change.

### 4.6 Decouple generator regex rewrites from template shape

`rsc_setup.rb` does 10+ `gsub_file` calls to inject RSC wiring into existing webpack configs. These regexes assume:

- The exact string `const configureServer = () =>` exists in `serverWebpackConfig.js`
- `serverWebpackConfig.plugins.unshift(new bundler.optimize.LimitChunkCountPlugin` appears exactly once
- Import lines match specific shapes

Any divergence (e.g., an rspack project that uses `@rspack/core` via a differently-named local helper) will silently fail. The `verify_rsc_webpack_transforms` check (line 441) catches _some_ failures but warns on others.

**Proposed:** Convert these `gsub_file` rewrites to a single idempotent re-template step. I.e., instead of incremental patching, mark config files with a sentinel comment that the generator owns, and rewrite the whole section each time. Lower risk of silent rewrite failure.

---

## 5. Implementation Plan (Phased)

### Phase 0 — Discovery (prerequisite for all other phases)

**Goal:** Answer §3.2 definitively. Produce a runnable artifact that builds all three bundles using rspack v2 and demonstrates whether `RSCWebpackPlugin` works.

**Scope:**
- Create a fresh Pro dummy or a minimal repro in `react_on_rails_pro/spec/rsc-rspack-smoke/`
- Configure it for rspack v2 (bump `@rspack/core` to `^2.0.0-0`)
- Run `RSC_BUNDLE_ONLY=true bin/shakapacker` — expect ✅
- Run `SERVER_BUNDLE_ONLY=true bin/shakapacker` — this is the critical one
  - If plugin crashes on load (can't find `webpack/lib/...`) → confirms 3.2.b
  - If plugin loads but the manifest is malformed/empty → confirms 3.2.b with a different fix
  - If manifest matches the webpack-produced shape byte-for-byte → confirms 3.2.a
- Run `CLIENT_BUNDLE_ONLY=true bin/shakapacker` — same
- Run the Pro dummy's RSC E2E test against the rspack-built bundles — confirms runtime

**Specific file changes:** None to production code. This is pure spike.

**Risks:**
- We don't have an rspack v2 in the lockfile today; may need temporary `@rspack/core@canary`
- shakapacker may need patching to accept rspack v2 (peer dep says `^1.0.0`)

**Effort:** Small (1-3 days assuming no surprises; medium if shakapacker bumps are needed)

**Blockers:** shakapacker v2 peer-dep acceptance (may require a shakapacker PR)

**Deliverable:** A short internal note with concrete findings — which of §3.2.a/b/c we're in.

### Phase 1 — Refactoring (non-user-visible prep)

**Goal:** Do §4.1, §4.4, §4.6 to make Phase 2 small and reviewable.

**Specific file changes:**
- `packages/react-on-rails-rsc/src/WebpackPlugin.ts` → Accept optional `bundler` option (4.1)
- `packages/react-on-rails-rsc/src/react-server-dom-webpack/cjs/react-server-dom-webpack-plugin.js` → Use an injected `bundler` handle instead of top-level `require('webpack')` (4.1)
- Add `react-on-rails-rsc/BundlerPlugin` + `BundlerLoader` export aliases (4.2 — trivial)
- `react_on_rails/lib/generators/react_on_rails/templates/rsc/base/config/webpack/rscWebpackConfig.js.tt` → Use shared `extractLoader` (4.4)
- `react_on_rails/lib/generators/react_on_rails/rsc_setup.rb` → Replace `gsub_file` patching with full re-template where possible (4.6)

**Risks:**
- Changing the plugin wrapper signature could break existing users on webpack. Mitigate by keeping the old constructor shape as the default and making `bundler` option additive.
- Refactoring `rsc_setup.rb` re-templating may clobber user-customized configs. Add a backup step and a prompt before overwriting.

**Effort:** Medium

**Blockers:** None

### Phase 2 — Compatibility fixes

**Goal:** Make RSC run end-to-end under rspack v2. Specifics depend on Phase 0 outcome.

**If Phase 0 → 3.2.a (plugin works unchanged):**
- Small: just flip on the generator path, update `rspack-compatibility.md` from "Experimental" → "Supported"
- Effort: small

**If Phase 0 → 3.2.b (plugin needs rewrite):**
- Write `RSCRspackPlugin` in `react-on-rails-rsc` using only rspack-compatible APIs:
  - `@rspack/core` top-level exports (`AsyncDependenciesBlock`, `Compilation`, `sources`) if they exist in v2
  - If `dependencyFactories.set` is rspack-incompatible: use the `compilation.hooks.finishModules` → walk modules → inject a synthesized module technique that Parcel's RSC plugin uses (needs research)
  - Emit identical JSON manifest shape so `buildClientRenderer`/`buildServerRenderer` keep working unchanged
- Generator emits `RSCRspackPlugin` for rspack and `RSCWebpackPlugin` for webpack
- Effort: large

**If Phase 0 → 3.2.c (runtime breaks too):**
- Stop. Wait for either:
  - rspack's built-in RSC support to ship (timeline: UNKNOWN)
  - a `react-server-dom-rspack` npm package from React/Rspack
- Update `rspack-compatibility.md` to explicitly list "RSC + rspack = not supported, here's why, here's the tracking issue"
- Effort: small (just docs)

**Risks:**
- If we take the rewrite path, the JSON manifest shape must stay identical or the `react-on-rails-rsc` client module breaks. Add a snapshot test of the manifest JSON shape before refactoring.
- React's Flight runtime MIGHT emit chunk loading code that rspack's runtime doesn't satisfy. Hard to detect without E2E test.

**Effort:** Range — small (a) → large (b) → small (c)

**Blockers:** Phase 0 outcome. Also potentially: shakapacker upstream changes if rspack v2 isn't supported there yet (see shakapacker#984).

### Phase 3 — Testing infrastructure

**Goal:** Prevent regression once Phase 2 ships.

**Specific file changes:**
- `.github/workflows/pro-rsc-rspack-smoke.yml` — new. Minimal 3-bundle build + check manifests + one E2E navigation test
- `react_on_rails_pro/spec/dummy/` — add an rspack-flavored config alongside the webpack one (behind an env var switch) OR create a sibling dummy
- `react_on_rails/spec/react_on_rails/generators/rsc_generator_spec.rb` — extend the existing "Rspack RSC runtime compatibility" block (added in PR #3120) with assertions that the _generated_ configs now reference the `BundlerPlugin` aliases
- `packages/react-on-rails-rsc/tests/` — Jest tests for the refactored plugin wrapper (injection of bundler option, default webpack path)

**Risks:**
- Rspack binaries are native; CI image sizing / install time. Mitigate via caching.
- Test flakiness due to rspack v2 beta churn. Pin exact version; bump deliberately.

**Effort:** Medium

**Blockers:** Phase 2 done

### Phase 4 — Documentation

**Specific file changes:**
- `docs/pro/react-server-components/rspack-compatibility.md` — update status from "Experimental" → "Supported" (or "Limited" depending on Phase 2 outcome). Remove speculation. Add verified compatibility matrix.
- `docs/pro/react-server-components/create-without-ssr.md` — add rspack-specific notes where needed
- `docs/pro/react-server-components/index.md` — link to rspack-compatibility doc
- `docs/oss/migrating/migrating-from-webpack-to-rspack.md` — add RSC section
- `docs/oss/migrating/rsc-preparing-app.md` — callouts for rspack users
- `CHANGELOG.md` — per `.claude/docs/changelog-guidelines.md`
- `packages/react-on-rails-rsc/README.md` — document the new `bundler` option and BundlerPlugin exports
- Generator output messages — print "Rspack" vs "Webpack" where applicable (already partly done)

**Risks:** None meaningful. Docs-only.

**Effort:** Small

**Blockers:** Phases 2 and 3

---

## 6. Open Questions and Unknowns

Items that require external input or runtime verification.

| # | Question | Needs input from | Why it matters |
|---|---|---|---|
| Q1 | Does `compilation.dependencyFactories.set(ClientReferenceDependency, factory)` work when `ClientReferenceDependency` extends a webpack class but the compilation is rspack? | Rspack team / runtime test | Determines whether §3.2.a or §3.2.b is reality |
| Q2 | Does rspack v2's top-level `@rspack/core` export include `AsyncDependenciesBlock`? | Rspack docs / source inspection | Governs §3.4 decision |
| Q3 | Does rspack emit `__webpack_require__`, `__webpack_chunk_load__`, and `__webpack_require__.u` in an ABI-identical way to webpack 5? | Runtime test | If not, React's Flight client won't work |
| Q4 | Is the Rspack team's built-in RSC support going to land in 2026? If so, when? Is there a public roadmap? | Rspack team (@SyMind, @chenjiahan) | Affects §3.2.c fallback; could obviate custom plugin work |
| Q5 | Should `react-on-rails-rsc` depend on `react-server-dom-webpack` as an npm dependency instead of vendoring? (Vendoring makes §3.4 feasible but creates maintenance burden on every React release.) | shakacode internal | §3.7 decision |
| Q6 | If we fork the plugin, how do we keep it in sync with upstream React? | React team or internal policy | Sustainability |
| Q7 | Does Next.js's RSC + Rspack setup (cited by @SyMind) use `react-server-dom-webpack/plugin` or a fork/replacement? | Next.js source + Rspack team | Datapoint for Q1/Q2 |
| Q8 | Is `react-server-dom-rspack` in anyone's roadmap? (Google search negative as of 2026-04-14) | React team | §3.2.c path |
| Q9 | Is the shakapacker team OK with bumping rspack peer dep to `^1.0.0 \|\| ^2.0.0-0`? | shakapacker maintainers | Gates rspack v2 adoption |
| Q10 | Should RSC support require a specific minimum shakapacker version? If so, which? | Internal | Generator prereq check |
| Q11 | Does the `@rspack/core` bundle include working `sources.RawSource`? | Rspack source inspection | `emitAsset` path |
| Q12 | How do rspack's `ContextModule` semantics compare to webpack's? The plugin uses `contextModuleFactory.resolveDependencies` to enumerate the app tree. | Runtime test | Plugin step (a) |
| Q13 | Do we need to handle HMR / dev-server behavior differently? Rspack's dev server is compatible, but the RSC plugin's `beforeCompile` hook fires differently in watch mode. | Runtime test | Dev-mode usability |

---

## 7. Risk Matrix

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| R1 | `react-server-dom-webpack/plugin` fails on rspack v2 due to webpack internals incompatibility | High | High | Phase 0 discovery before committing; if it fails, write rspack-native plugin OR wait for rspack's built-in RSC |
| R2 | Manifests produced by rspack have different JSON shape than webpack, breaking `buildServerRenderer` / `buildClientRenderer` | Medium | High | Add snapshot tests for manifest JSON shape; ensure any rspack-native plugin produces identical output |
| R3 | React's Flight client runtime expects webpack-specific chunk loading ABI that rspack doesn't emit | Low | High | Validate at runtime in Phase 0; issue upstream to React if real |
| R4 | Rspack v2 GA slips; shakapacker peer dep bump delays the whole feature | Medium | Medium | Gate RSC-rspack support on shakapacker shipping v2 compat; ship non-RSC rspack work independently |
| R5 | React upstream releases a new `react-server-dom-webpack` internals shape before we finish, breaking our vendored fork | Medium | Medium | Version-pin vendored React pieces; treat bumps as code changes, not dependency bumps |
| R6 | Generator regex rewrites in `rsc_setup.rb` silently fail when applied to rspack project configs that have drifted from templates | Medium | Medium | Convert to re-template approach (§4.6); expand `verify_rsc_webpack_transforms` coverage |
| R7 | CI time doubles because RSC tests now run twice (webpack + rspack) | Low | Medium | Start with a single smoke-test job; add matrix later |
| R8 | Breaking change to `react-on-rails-rsc` plugin constructor signature breaks existing webpack users | Low | High | Keep old constructor shape as default; make `bundler` option additive and back-compat |
| R9 | Rspack built-in RSC support ships while we're mid-implementation, making our custom plugin obsolete | Medium | Low | Our plugin targets both v1 and v2; switching to rspack's built-in later is a docs-only change |
| R10 | The fork-and-patch of the vendored React plugin diverges from upstream and accumulates drift | Medium | Medium | Minimal patches; annotate every change with upstream commit hash; document patch strategy in `react-on-rails-rsc/README.md` |
| R11 | Users who already deployed `enable_rsc_support = true` with rspack hit a runtime error (because we said "Experimental" but it works for generator/doesn't work at runtime) | High (already shipped) | Medium | Ship a version bump that makes the failure mode explicit and actionable; update `rspack-compatibility.md` to reflect reality once Phase 0 is done |
| R12 | Rename of `*WebpackConfig.js` (#2552) lands concurrently and invalidates all our generator regex patches | Medium | High | Coordinate with #2552 author; do not land #2552 during Phase 1/2 |
| R13 | Phase 2 rewrite is large and slips, blocking a release train | Medium | Medium | Ship phases independently; Phase 0 is time-boxed; if Phase 2 grows, ship `rspack-compatibility.md` update first |
| R14 | React's `renderToPipeableStream` behavior depends on exact module ID scheme used by the bundler; rspack module IDs might not match | Low | High | Validate in Phase 0; fall back to deterministic-ID config if needed |

---

## 8. Related Links / References

### Tracking issues and PRs

- [#1828](https://github.com/shakacode/react_on_rails/issues/1828) — Rspack support for RSC (P1, original tracker; @SyMind Rspack-team comment; Justin's "let's focus on rspack v2" directive 2026-04-01)
- [#2552](https://github.com/shakacode/react_on_rails/issues/2552) — RFC: Rename bundler-agnostic config files from `*WebpackConfig.js`
- [#2633](https://github.com/shakacode/react_on_rails/issues/2633) — Follow-up: tighten Doctor/SystemChecker webpack config diagnostics during Rspack migration
- [#3120](https://github.com/shakacode/react_on_rails/pull/3120) — Add Rspack + RSC compatibility tests and documentation (merged; added 9 generator specs + `rspack-compatibility.md`)
- [#3128](https://github.com/shakacode/react_on_rails/issues/3128) — Gumroad public comparison repo: React 19 + Rspack + RSC findings
- [#3141](https://github.com/shakacode/react_on_rails/issues/3141) — THIS ISSUE: Revise Rspack support and plan RSC + Rspack compatibility
- [#1862](https://github.com/shakacode/react_on_rails/issues/1862) — Rake task to generate and export reference webpack/rspack configurations
- [#2410](https://github.com/shakacode/react_on_rails/issues/2410) — Generator creates rspack configs in deprecated `config/webpack/` (closed by #2417)
- [#2417](https://github.com/shakacode/react_on_rails/pull/2417) — Generate `--rspack` configs under `config/rspack/` (merged)
- [shakacode/shakapacker#984](https://github.com/shakacode/shakapacker/issues/984) — Switch to rspack drops compression plugin and optimization
- [shakacode/shakapacker#1090](https://github.com/shakacode/shakapacker/issues/1090) — Doctor reports false SWC issues for hybrid setups (referenced by #3141)
- [web-infra-dev/rspack#5824](https://github.com/web-infra-dev/rspack/pull/5824) — feat: rsc plugin (closed; superseded by future built-in support per @chenjiahan 2025-10)

### Existing docs

- `docs/pro/react-server-components/rspack-compatibility.md` — starting-point doc; compatibility matrix
- `docs/pro/react-server-components/how-react-server-components-work.md` — the loader + plugin + manifest explainer
- `docs/pro/react-server-components/rendering-flow.md` — three-bundle architecture + VM sandbox vs full Node distinction
- `docs/pro/react-server-components/create-without-ssr.md` — step-by-step RSC setup
- `docs/oss/migrating/migrating-from-webpack-to-rspack.md` — general rspack migration guide
- `.claude/docs/analysis/RSPACK_IMPLEMENTATION.md` — historical notes on the `--rspack` flag rollout

### Key source files in this repo

- `react_on_rails/lib/generators/react_on_rails/rsc_setup.rb` — 705-line RSC generator orchestration
- `react_on_rails/lib/generators/react_on_rails/rsc_generator.rb` — generator entry
- `react_on_rails/lib/generators/react_on_rails/generator_helper.rb:190-207, 373-379` — rspack detection + path remap
- `react_on_rails/lib/generators/react_on_rails/templates/rsc/base/config/webpack/rscWebpackConfig.js.tt`
- `react_on_rails/lib/generators/react_on_rails/templates/base/base/config/webpack/{server,client,common}WebpackConfig.js.tt`
- `react_on_rails/lib/generators/react_on_rails/templates/base/base/config/webpack/ServerClientOrBoth.js.tt`
- `react_on_rails_pro/spec/dummy/config/webpack/{client,server,rsc}WebpackConfig.js` — reference working setup
- `packages/react-on-rails-pro/src/RSCRoute.tsx`, `RSCProvider.tsx`, `RSCRequestTracker.ts`, `capabilities/proRSC.ts`, `getReactServerComponent.server.ts`, `ReactOnRailsRSC.ts` — Pro runtime

### External source files (outside this repo)

- `/mnt/ssd/react-on-rails-rsc/src/WebpackPlugin.ts` — `RSCWebpackPlugin` wrapper
- `/mnt/ssd/react-on-rails-rsc/src/WebpackLoader.ts` — the `use client` transform loader
- `/mnt/ssd/react-on-rails-rsc/src/react-server-dom-webpack/cjs/react-server-dom-webpack-plugin.js` — **the critical 409-line vendored React plugin** using all the webpack internals
- `/mnt/ssd/react-on-rails-rsc/src/react-server-dom-webpack/cjs/react-server-dom-webpack-client.browser.production.js:58-112` — proof that runtime uses `__webpack_require__` et al
- `/mnt/ssd/react-on-rails-rsc/src/{client.node,client.browser,server.node}.ts` — the shakacode-owned API surface on top of React's internals
- `/mnt/ssd/shakacode-related/shakapacker/package/plugins/rspack.ts`, `rules/rspack.ts` — reference for how shakapacker wires rspack today
- `/mnt/ssd/shakacode-related/shakapacker/package.json:54-55, 102-103` — rspack peer-dep `^1.0.0` (needs bump for v2)

### Rspack references

- Rspack docs: https://rspack.dev/
- Rspack webpack API compatibility: https://rspack.dev/guide/migration/webpack-compat
- Rspack v2 release notes: (UNKNOWN — check https://rspack.dev/blog/ at implementation time)
- Next.js Rspack integration (per @SyMind's reference): https://github.com/vercel/next.js

### React RSC references

- React docs — How to build support for Server Components: https://react.dev/reference/rsc/server-components#how-do-i-build-support-for-server-components
- React source — `react-server-dom-webpack`: https://github.com/facebook/react/tree/main/packages/react-server-dom-webpack

### Our own Claude-oriented docs (for Phase 3 context)

- `.claude/docs/avoiding-ci-failure-cycles.md`
- `.claude/docs/replicating-ci-failures.md`
- `.claude/docs/playwright-e2e-testing.md`
- `.claude/docs/project-architecture.md`
- `.claude/docs/rails-engine-nuances.md`
- `.claude/docs/debugging-webpack.md`
- `.claude/docs/testing-build-scripts.md`
- `.claude/docs/changelog-guidelines.md`

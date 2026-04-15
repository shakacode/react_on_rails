# RSC + Rspack: Plugin Implementation Plan

**Status:** Design complete, ready for implementation
**Related tracking issue:** [shakacode/react_on_rails#3141](https://github.com/shakacode/react_on_rails/issues/3141)
**Related tests branch:** [shakacode/react_on_rails_rsc#test/rspack-compatibility](https://github.com/shakacode/react_on_rails_rsc/tree/test/rspack-compatibility) (31 tests proving runtime compat)
**Companion docs:**
- [`.claude/docs/rspack-rsc-support-state.md`](./rspack-rsc-support-state.md) — state of rspack's official RSC support
- [`.claude/docs/rsc-rspack-implementation-plan.md`](./rsc-rspack-implementation-plan.md) — original high-level plan (superseded by this doc for plugin specifics)

---

## Executive Summary

**Only ONE file in `react-on-rails-rsc` is incompatible with rspack: `RSCWebpackPlugin`.** Everything else (loader, server.node, client.node, client.browser) works with rspack unchanged — proven empirically by a 31-test suite that builds and runs all four components under rspack v1.7.11.

**The plan:** dual-path plugin behind the existing `RSCWebpackPlugin` facade. Webpack projects keep the current code path (unchanged). Rspack projects get a new path that uses only standard rspack-compatible bundler APIs — no dependency on rspack's experimental RSC system, no configuration flags, no `react-server-dom-rspack`. The manifest JSON schemas stay identical, so `server.node.ts`, `client.node.ts`, and `client.browser.ts` require zero changes.

**Open item to validate during implementation:** the `chunkCache` behavior in `react-server-dom-webpack`'s browser runtime. `react-server-dom-rspack` ships a 394-line patch removing the cache; likely needed for us too.

---

## Table of Contents

1. [What We Verified Empirically](#1-what-we-verified-empirically)
2. [Why Only the Plugin Needs Changing](#2-why-only-the-plugin-needs-changing)
3. [What Rspack's Built-in RSC Does (and Why We Won't Use It)](#3-what-rspacks-built-in-rsc-does-and-why-we-wont-use-it)
4. [Manifest Schema Comparison](#4-manifest-schema-comparison)
5. [Plugin Architecture Decision](#5-plugin-architecture-decision)
6. [Discovery Technique: FS Walk vs. Module Graph Walk](#6-discovery-technique-fs-walk-vs-module-graph-walk)
7. [Chunk-Splitting Technique: Custom Dependency vs. AsyncDependenciesBlock](#7-chunk-splitting-technique-custom-dependency-vs-asyncdependenciesblock)
8. [Runtime Compatibility Risks](#8-runtime-compatibility-risks)
9. [Implementation Plan](#9-implementation-plan)
10. [Known Unknowns to Validate in Prototype](#10-known-unknowns-to-validate-in-prototype)
11. [References](#11-references)

---

## 1. What We Verified Empirically

### 1.1 The 31-test compatibility suite

Pushed to `shakacode/react_on_rails_rsc` on branch `test/rspack-compatibility`. Seven test suites:

| Suite | Tests | Verifies |
|---|---|---|
| `static-analysis.test.ts` | 10 | No webpack internals imported in any of the 4 target files |
| `rspack-runtime-abi.test.ts` | 6 | Rspack emits `__webpack_require__`, `__webpack_chunk_load__`, mutable `__webpack_require__.u` |
| `webpack-loader.rspack.test.ts` | 3 | `RSCWebpackLoader` runs under rspack, produces `registerClientReference` stubs |
| `server-node.rspack.test.ts` | 3 | `server.node` bundles with rspack; `renderToPipeableStream` works in the rspack-built output |
| `client-node.rspack.test.ts` | 3 | `client.node` bundles with rspack; `buildClientRenderer` callable |
| `client-browser.rspack.test.ts` | 5 | `client.browser` bundles for web target; `createFromFetch` / `createFromReadableStream` exported; `__webpack_require__.u` assignable |
| `end-to-end.rspack.test.ts` | 1 | **Full pipeline:** rspack-bundled server encodes a React tree → rspack-bundled client decodes it → tree matches input |

All 31 tests green in 5.9 seconds. The end-to-end test is the strongest evidence: a complete Flight-encode → Flight-decode round trip works when both sides are produced by rspack.

### 1.2 A working pure-rspack RSC demo (no React on Rails)

Location: `/mnt/ssd/demos/rspack-rsc-pure`. Runs at http://localhost:3000. Produces full HTML server-side with embedded Flight payload. Uses:
- `@rspack/core@2.0.0-rc.2` (released 2026-04-14)
- `react-server-dom-rspack@0.0.2` (maintained by SyMind / ByteDance)
- `react@19.2.0` + Express 5 + `worker_threads`

This proves RSC is buildable with rspack end-to-end today, outside React on Rails.

### 1.3 Rspack's public runtime globals

From direct inspection of `@rspack/core` v1.7.11 exports:

| Needed by RoR's runtime | Rspack provides |
|---|---|
| `__webpack_require__(id)` | ✓ emitted identically |
| `__webpack_chunk_load__(chunkId)` | ✓ emitted identically |
| `__webpack_require__.u(chunkId)` | ✓ emitted as assignable property (React monkey-patches it) |
| `AsyncDependenciesBlock` | ✓ `rspack.AsyncDependenciesBlock` (top-level export) |
| `Compilation.PROCESS_ASSETS_STAGE_REPORT` | ✓ `rspack.Compilation.PROCESS_ASSETS_STAGE_REPORT = 5000` |
| `sources.RawSource` | ✓ `rspack.sources.RawSource` |
| `Template.toPath` | ✓ `rspack.Template.toPath` |
| `WebpackError` | ✓ `rspack.WebpackError` |

Only the `webpack/lib/*` deep imports (`ModuleDependency`, `NullDependency`) are not exposed — these are the webpack-internals that make the current `RSCWebpackPlugin` rspack-incompatible.

---

## 2. Why Only the Plugin Needs Changing

### 2.1 The complete compatibility scorecard for `react-on-rails-rsc`

| File | Rspack-compatible? | Why |
|---|---|---|
| `src/WebpackLoader.ts` | ✅ | Only uses `this.resourcePath`. No webpack internals. |
| `src/server.node.ts` | ✅ | Renders via `renderToPipeableStream`; only Node built-ins + `react-dom` needed. No `require('webpack')`. |
| `src/client.node.ts` | ✅ | Uses `__webpack_require__` / `__webpack_chunk_load__` at runtime — rspack emits both. |
| `src/client.browser.ts` | ✅ | Same — uses runtime globals only. |
| `src/types.ts` | ✅ | Types only; no runtime code. |
| **`src/WebpackPlugin.ts`** | ❌ | Wraps `react-server-dom-webpack/plugin` which imports `webpack/lib/dependencies/ModuleDependency`, `webpack/lib/dependencies/NullDependency`, `webpack/lib/Template`, and `webpack` itself. Also calls `contextModuleFactory.resolveDependencies()` which rspack doesn't expose. |
| `src/react-server-dom-webpack/cjs/react-server-dom-webpack-plugin.js` (vendored, 409 lines) | ❌ | The actual file with the webpack-internal imports. |

### 2.2 The first failure point (runtime-verified)

I actually ran the current plugin with rspack. First thrown error:

```
TypeError: contextModuleFactory.resolveDependencies is not a function
  at react-server-dom-webpack-plugin.js:345:38
```

This is in phase (a) of the plugin — the `"use client"` file discovery. Rspack's `ContextModuleFactory` doesn't expose `resolveDependencies`. We can't get past this without a rewrite of the discovery phase.

### 2.3 Why `client.node`, `client.browser`, `server.node` all work

Key architectural insight: the Flight wire protocol is self-describing. When the server encodes a React tree to Flight, each client reference appears in the payload as:

```
c:I["./src/Dialog.tsx",["src_Dialog_tsx","src_Dialog_tsx.js"],"Dialog"]
```

That `I` row contains `[moduleId, chunks, exportName]` inline. The browser-side decoder doesn't need a manifest — it reads the tuple out of the payload and calls `__webpack_require__(moduleId)` + `__webpack_chunk_load__(chunks[0])` directly. Proof from the compiled browser code:

```js
// dist/static/main.js:18599 — the browser passes NULL manifests to the decoder
return new ResponseInstance(null, null, null, /* callbacks */, ...);
```

Server-side SSR decoder does need the manifest (to find the SSR-layer module ID and load the actual client component), but that manifest's shape is nearly identical between webpack and rspack (see §4).

---

## 3. What Rspack's Built-in RSC Does (and Why We Won't Use It)

### 3.1 How rspack's native RSC support works

Rspack v2 ships a built-in RSC system comprising:

1. **Rust core at `crates/rspack_plugin_rsc/`** — 15 Rust files handling discovery, manifest build, chunk layout
2. **SWC loader integration** — `rspackExperiments.reactServerComponents: true` enables `"use client"` / `"use server"` detection during parse
3. **`rspack.experiments.rsc.createPlugins()` API** — returns `{ ServerPlugin, ClientPlugin }` JS handles
4. **Layers machinery** — `Layers.rsc` / `Layers.ssr` for server-side layer tagging
5. **Runtime module** at `crates/rspack_plugin_rsc/src/manifest_runtime_module.rs` — emits `__webpack_require__.rscM = JSON.parse("...")` into server bundles
6. **JS-side `onManifest` callback** on `ServerPlugin` — exposes the manifest as a JSON string

### 3.2 `react-server-dom-rspack` (the wrapper package)

Maintained by SyMind (Cong-Cong Pan, ByteDance). Repo: https://github.com/SyMind/react-server-dom-rspack

Architecture of the wrapper:
- TypeScript source in `src/server.node.ts`, `src/client.node.ts`, etc. (thin wrappers, <700 lines total)
- Vendors `react-server-dom-webpack` at build time via `cpx`
- Applies a **394-line patch** to the vendored code removing `chunkCache` in 12 files
- Wrapper calls into the vendored React code, substituting manifests read from `__rspack_rsc_manifest__` (aliased to `__webpack_require__.rscM` by rspack's runtime module)

### 3.3 Why we're skipping this entire path

**Decision: do NOT use rspack's built-in RSC system. Do NOT use `react-server-dom-rspack`.** Reasons:

1. **Tight coupling** — rspack's ServerPlugin + ClientPlugin require the SWC loader flag + Layers machinery + specific plugin lifecycle. You can't pick one piece; it's all or nothing.
2. **Experimental status** — `rspackExperiments.reactServerComponents` is behind an experiments flag. `@rspack/core@2.0.0-rc.2` (the first version with built-in RSC) was released 2026-04-14, still pre-stable.
3. **React-on-rails-rsc has its own mental model** — three bundles (client, server, RSC), specific manifest file names, Ruby-side orchestration. Adopting rspack's built-in would require restructuring all of this OR running two parallel systems.
4. **Coupling to `react-server-dom-rspack`** — ByteDance-maintained, not upstream React. Depending on it pins us to their release cadence.
5. **Rsbuild direction** — the rspack team recommends `rsbuild-plugin-rsc` (which wraps their built-in RSC). RoR uses Shakapacker, not Rsbuild. Using rspack's built-in would pull us toward a parallel tooling stack.

What we WILL do: write our own plugin using rspack's **standard public APIs** (the same APIs webpack provides). No `rspackExperiments` flag, no `experiments.rsc.createPlugins`, no Layers.

---

## 4. Manifest Schema Comparison

### 4.1 `clientManifest` (passed to `renderToPipeableStream` server-side)

**React on Rails (webpack):**
```json
{
  "file:///path/to/Component.jsx": {
    "id": "./app/javascript/components/Component.jsx",
    "chunks": ["client25", "js/client25.js"],
    "name": "*"
  }
}
```

**Rspack:**
```json
{
  "/absolute/path/to/Dialog.tsx": {
    "id": "./src/Dialog.tsx",
    "name": "*",
    "chunks": ["src_Dialog_tsx", "src_Dialog_tsx.js"],
    "async": false
  }
}
```

**Differences:** RoR keys use `file://` URI prefix; rspack keys use raw paths. Rspack has an extra `async` field (defaults to `false`, harmless to RoR). Otherwise identical.

### 4.2 SSR Manifest (passed to `createFromNodeStream` server-side)

**React on Rails:**
```json
{
  "moduleLoading": { "prefix": "/packs/...", "crossOrigin": null },
  "moduleMap": {
    "./app/javascript/components/Dialog.jsx": {
      "*": { "id": "./app/javascript/...", "chunks": [...], "name": "*" }
    }
  }
}
```

**Rspack:**
```json
{
  "moduleMap": { "./src/Dialog.tsx": { "*": { ... } } },
  "moduleLoading": { "prefix": "static/" },
  "serverModuleMap": { "<hash>": { "id": "...", "chunks": [...] } }  // server actions
}
```

**Differences:** Rspack adds a third `serverModuleMap` for server actions (RoR doesn't support server actions yet). Otherwise field names and shapes match.

### 4.3 Decision: Keep RoR's schema unchanged

The rspack plugin we write will emit JSON files with **RoR's existing schema** (`filePathToModuleMetadata` + `moduleLoading`). No changes to `server.node.ts`, `client.node.ts`, or `client.browser.ts`. No changes to Ruby-side code.

This means we drop rspack's `async` field and `serverModuleMap` section. Server actions stay unsupported; that's an orthogonal feature to address later.

---

## 5. Plugin Architecture Decision

### 5.1 Options considered

**A. Single plugin, feature-detect at `apply()` time, dispatch to webpack/rspack path internally.**
- One import path for users and generators
- Two code paths internally
- Simpler from outside; more complex inside

**B. Two separate plugin exports (`RSCWebpackPlugin` and `RSCRspackPlugin`).**
- Generator picks based on `assets_bundler` config
- Cleaner internal separation
- Breaks the "one import path" idiom

**C. Unified interface, two backends.**
- Most abstract; least code reuse since the two paths share very little

### 5.2 Decision: Option A (dual-path, single facade)

```ts
// react-on-rails-rsc/src/WebpackPlugin.ts (renamed conceptually but export preserved)

import createWebpackPlugin = require('./react-server-dom-webpack/plugin');
import createRspackPlugin = require('./react-server-dom-rspack/plugin');

export class RSCWebpackPlugin {
  private plugin: { apply(compiler: any): void };

  constructor(options: Options) {
    const bundler = options.bundler || require('webpack');
    const isRspack = typeof bundler.rspackVersion === 'string';

    if (isRspack) {
      this.plugin = new (createRspackPlugin(bundler))(options);
    } else {
      this.plugin = new (createWebpackPlugin(bundler))(options);
    }
  }

  apply(compiler: any) { this.plugin.apply(compiler); }
}

// Optional alias for semantic clarity in new projects:
export { RSCWebpackPlugin as RSCBundlerPlugin };
```

**Justification:**
- Back-compat preserved (existing webpack users' generated configs continue to work)
- One import path (generators don't need to branch at template level)
- Rspack-specific code fully isolated in `react-server-dom-rspack/plugin.js` (new file)
- Webpack path requires only a trivial wrapping change (factory function taking `bundler`)

---

## 6. Discovery Technique: FS Walk vs. Module Graph Walk

### 6.1 Our current webpack plugin's approach (FS walk)

```
CONFIG: clientReferences = [{ directory: "./app/javascript", recursive: true,
                              include: /\.(js|ts|jsx|tsx)$/ }]

→ Walk filesystem
→ For every matching file:
    - Read file from disk
    - Parse with acorn-loose
    - Check for "use client" directive
    - If found: create ClientReferenceDependency, register via AsyncDependenciesBlock

MISSES:
  ✗ node_modules/@lib/Client.tsx (outside configured dir)
  ✗ Files resolved via TS path aliases outside directory
  ✗ Virtual modules (no FS file)

FALSE POSITIVES:
  ✗ DeadFile.tsx — present in directory, matches regex, has "use client",
                   but never imported → still ends up in manifest
```

### 6.2 Rspack's native approach (module graph walk)

```
→ SWC loader tags modules during parse (sets bit on module metadata)
→ collect_component_info_from_entry_dependency starts from each entry
→ Walks ESM/CJS import edges
→ Uses visited set to handle cycles
→ For each visited module, if SWC-tagged as "use client", record it

FINDS:
  ✓ Any file reachable via imports, anywhere — node_modules, aliases, virtual modules
EXCLUDES:
  ✓ Dead code (not parsed, not tagged)
  ✓ Files not reachable from entry
```

### 6.3 Decision: module graph walk via loader-based tagging

We adapt rspack's approach (minus the SWC integration, since we don't require rspack's experimental flags). The technique:

1. **Small loader** — reads module source, checks for `"use client"` directive, records findings in a shared `Set<string>` keyed on module.resource path
2. **Plugin reads the set in `compilation.hooks.finishModules`** — by that time, every module reachable from an entry has been loaded and (if a client component) tagged
3. **Per-module chunk lookup** via `compilation.chunkGraph.getModuleChunks(module)` — simpler than walking all chunk groups

Advantages over the current webpack plugin:
- No `directory` / `include` regex — works with any rspack resolution (aliases, node_modules, conditional exports)
- Dead code automatically excluded
- Single pass (file read once by bundler, tagged by loader, used by plugin) — no double I/O
- Per-entry accuracy available (we start simple with single-compilation-wide manifest, matching current webpack plugin behavior)

We should apply the **same technique to the webpack path** eventually, since it's strictly better than the current FS walk. For this implementation we'll keep the webpack path unchanged (conservative) and use the new technique only on the rspack path.

---

## 7. Chunk-Splitting Technique: Custom Dependency vs. AsyncDependenciesBlock

### 7.1 Webpack plugin's technique (today)

```js
class ClientReferenceDependency extends ModuleDependency { ... }
compilation.dependencyFactories.set(ClientReferenceDependency, normalModuleFactory);
compilation.dependencyTemplates.set(ClientReferenceDependency, new NullDependency.Template());

// In parser hooks, for each client file:
const asyncBlock = new webpack.AsyncDependenciesBlock({ name: chunkName }, null, dep.request);
asyncBlock.addDependency(new ClientReferenceDependency(file));
clientRegistrationModule.addBlock(asyncBlock);
```

**Works because:** webpack's `ModuleDependency` is a JS class you can extend from userland. Webpack's `dependencyFactories.set()` accepts arbitrary JS dep classes.

**Doesn't work on rspack because:** rspack's `Dependency` base class is Rust-backed. Extending it from JS doesn't round-trip into rspack's Rust module graph.

### 7.2 The rspack path (decision)

Use `AsyncDependenciesBlock` attached to a registration module **without** a custom dependency subclass. Rspack's `AsyncDependenciesBlock` accepts standard built-in dependency types (`ImportDependency`, `EntryPlugin.createDependency`-style deps) as children.

```js
// Pseudocode for rspack path
for (const file of tagged_client_files) {
  const asyncBlock = new rspack.AsyncDependenciesBlock({ name: toChunkName(file) });
  asyncBlock.addDependency(standardImportDep(file));  // use a built-in dep type
  registrationModule.addBlock(asyncBlock);
}
```

**Benefits:**
- Same mechanism as the webpack plugin (familiar); different dependency shape
- No custom subclass means no rspack internal-API coupling
- Each client file ends up as a named async chunk (desired behavior)

**To validate at prototype time:** the exact built-in dep type to use. Options:
- `rspack.dependencies.ImportDependency` (if exposed)
- `EntryPlugin.createDependency(file, options)` — already exposed; creates an entry dep
- A built-in module-resolution dependency

If none of the built-in deps work as-is, a fallback is to skip the `AsyncDependenciesBlock` entirely and use `compilation.addEntry()` with `entry.runtime: false` to create named runtime-less chunks per client file. Less elegant but well-supported.

---

## 8. Runtime Compatibility Risks

### 8.1 The `react-server-dom-webpack` chunk-cache patch

`react-server-dom-rspack@0.0.2` applies a uniform 394-line patch across 12 files in the vendored `react-server-dom-webpack`. The patch:

```diff
- var chunkId = chunks[i++],
-   chunkFilename = chunks[i++],
-   entry = chunkCache.get(chunkId);
- void 0 === entry
-   ? ((chunkFilename = loadChunk(chunkId, chunkFilename)),
-     promises.push(chunkFilename),
-     ...,
-     chunkCache.set(chunkId, chunkFilename))
-   : null !== entry && promises.push(entry);
+ var chunkId = chunks[i++];
+ i++;
+ var thenable = __webpack_chunk_load__(chunkId);
+ promises.push(thenable);
+ thenable.catch(ignoreReject);
```

**What it does:** removes the JS-level `chunkCache` and always calls `__webpack_chunk_load__(chunkId)` directly, relying on the bundler's own idempotency instead of React's JS cache.

**Why it exists:** unclear from the patch file alone, but likely one of:
- Rspack's `__webpack_chunk_load__` doesn't return the same Promise object on repeated calls (but still loads only once — i.e., idempotent but not referentially equal)
- Rspack's module materialization timing differs, and React's cached promise resolves before the module is fully ready
- Edge case with concurrent dynamic imports

**Risk to RoR:** medium. Our vendored `react-server-dom-webpack` has the same chunkCache code. When rspack loads a chunk multiple times in quick succession (e.g., Suspense boundaries referencing the same client component), we may hit the same bug `react-server-dom-rspack` patched around.

**Mitigation:** apply the same patch to our vendored copy at build time. The patch is uniform, mechanical, and small. Alternative: use `react-server-dom-rspack/client.browser` in place of our `client.browser.ts` when running on rspack (hybrid approach).

**Action:** during prototype, build RoR's RSC test apps against an rspack project and watch for chunk-loading bugs. If none observed, defer the patch. If observed, port the patch.

### 8.2 Module ID shape differences

Rspack's SSR-layer module IDs include prefixes like `(server-side-rendering)/./src/Dialog.tsx`. Webpack's are plain like `./app/javascript/components/Dialog.jsx`.

**Risk:** low. RoR's code doesn't compare these IDs; it passes them through to `__webpack_require__(id)`, and that's bundler-internal (rspack's IDs work with rspack's require). No expected issue.

**Action:** test in prototype. If any code in `client.node.ts` or `server.node.ts` does string manipulation on IDs, review it.

### 8.3 Missing `async` and `serverModuleMap` fields

Our plugin will not emit these rspack-specific fields. React's Flight decoder accepts missing `async` (treats as `false`). `serverModuleMap` only matters for server actions (RoR doesn't support them). No risk.

---

## 9. Implementation Plan

### Phase 0 — Prototype (validate assumptions)

**Goal:** resolve the open items in §10 before writing production code.

Tasks:
1. Implement a minimal `RSCRspackPlugin` (single file) that:
   - Registers a tiny loader that tags `"use client"` modules
   - Hooks `compilation.hooks.finishModules` to iterate tagged modules
   - Uses `compilation.chunkGraph.getModuleChunks(module)` to build chunks array
   - Emits a single manifest matching RoR's format
2. Wire into a test rspack project that builds server + client bundles
3. Verify manifest shape matches RoR's expectations by hand
4. Verify `renderToPipeableStream` (from RoR's unpatched `react-server-dom-webpack`) works with rspack-built output
5. Verify `createFromNodeStream` works for SSR
6. Verify the browser client works (watch for chunk-cache issue)

Outputs:
- Working prototype plugin (~200 lines)
- Decision on which built-in dep type to use with `AsyncDependenciesBlock` (see §7.2)
- Decision on whether to port the chunk-cache patch (see §8.1)

Effort: small (~1-3 days)

### Phase 1 — Refactor the webpack path for parameterization

**Goal:** make the existing `RSCWebpackPlugin` accept a `bundler` parameter without changing behavior.

Tasks:
1. Convert `src/react-server-dom-webpack/cjs/react-server-dom-webpack-plugin.js` from a module with hard-coded `require('webpack')` to a factory function that accepts `bundler`
2. Update `src/WebpackPlugin.ts` to pass `bundler` through (defaults to `require('webpack')` for back-compat)
3. Run all existing tests to verify no regression

Outputs:
- `react-server-dom-webpack/plugin` now exports a factory
- `WebpackPlugin.ts` accepts optional `bundler` option, defaults to webpack

Effort: small (~1 day)

### Phase 2 — Implement the rspack path

**Goal:** write `src/react-server-dom-rspack/plugin.js` and the companion loader.

Tasks:
1. Write the loader (`src/react-server-dom-rspack/loader.js`):
   - Tiny file, reads source, checks for `"use client"` directive
   - Records findings in a shared `Set` (module-level singleton or compilation-scoped)
2. Write the plugin (`src/react-server-dom-rspack/plugin.js`):
   - In `thisCompilation`, ensure the loader runs on all JS/TS
   - Hook `finishModules` to collect tagged modules
   - For each tagged module, attach an `AsyncDependenciesBlock` to a central registration module
   - Hook `processAssets` at `PROCESS_ASSETS_STAGE_REPORT` to walk the chunk graph and emit the JSON
3. Update `WebpackPlugin.ts` dispatcher to detect rspack via `bundler.rspackVersion` and route accordingly
4. Add a `rspack` devDep to the `react-on-rails-rsc` package (already done for tests)

Outputs:
- New files: `src/react-server-dom-rspack/{plugin.js,loader.js,package.json}`
- Updated dispatcher: `src/WebpackPlugin.ts`

Effort: medium (~3-5 days, most of it in edge cases)

### Phase 3 — Apply chunk-cache patch (conditional on Phase 0 findings)

Only if Phase 0 confirms the bug:

Tasks:
1. Port the 394-line patch from `react-server-dom-rspack` to our vendored `react-server-dom-webpack`
2. Apply via a build-time patch script OR inline into the vendored files
3. Add a regression test that specifically triggers the original bug (concurrent client-component loads)

Outputs:
- Vendored files updated
- Patch script in repo

Effort: small (~1 day)

### Phase 4 — Update `react-on-rails` generator

**Goal:** generator produces correct rspack config when `assets_bundler: rspack`.

Tasks:
1. Generator emits new `*RspackConfig.js` templates (or shared templates that handle both) that:
   - Pass `bundler: require('@rspack/core')` to `RSCWebpackPlugin` when on rspack
   - Apply the loader to all JS/TS rules
2. Update `rsc_setup.rb` to write the correct config for both bundlers
3. Extend existing generator specs to cover rspack paths

Outputs:
- Generator changes
- New template files

Effort: medium (~3-5 days)

### Phase 5 — Testing infrastructure

**Goal:** CI catches rspack-specific regressions.

Tasks:
1. `.github/workflows/pro-rsc-rspack-smoke.yml` — builds three bundles + checks manifests exist + one E2E navigation test under rspack
2. Add rspack permutation to the existing RSC dummy (behind env var switch)
3. Snapshot test for the manifest JSON shape (must stay byte-compatible with the webpack path)

Outputs:
- New CI workflow
- Extended dummy config
- Snapshot tests

Effort: medium (~2-3 days)

### Phase 6 — Documentation

Tasks:
1. Update `docs/pro/react-server-components/rspack-compatibility.md` from "Experimental" to "Supported"
2. Add rspack section to `docs/oss/migrating/migrating-from-webpack-to-rspack.md`
3. Document the `bundler` option in `packages/react-on-rails-rsc/README.md`
4. Changelog entry per `.claude/docs/changelog-guidelines.md`

Effort: small (~1 day)

### Total effort estimate

| Phase | Size |
|---|---|
| 0 — Prototype | Small |
| 1 — Webpack refactor | Small |
| 2 — Rspack plugin | Medium |
| 3 — Chunk-cache patch (conditional) | Small |
| 4 — Generator | Medium |
| 5 — Testing infra | Medium |
| 6 — Docs | Small |

---

## 10. Known Unknowns to Validate in Prototype

1. **Exact rspack built-in dep type for `AsyncDependenciesBlock.addDependency()`** (§7.2). Likely `EntryPlugin.createDependency(file, options)` or a module-resolution dep, but must be verified.

2. **Whether the chunk-cache patch is required for RoR** (§8.1). Triggered by concurrent client-component loads; easy to test once the prototype runs.

3. **Whether per-module chunk lookup (`chunkGraph.getModuleChunks`) returns the right chunks for `AsyncDependenciesBlock`-created chunks**. In webpack, the dep is materialized into a chunk; rspack may or may not use the same internal mapping.

4. **Whether our `"use client"` detection loader can coexist with users' other SWC/Babel loaders**. Should run first in the chain (priority `pre` or via loader order).

5. **Module ID format for the entries** — webpack uses relative paths (`./src/Dialog.tsx`); rspack sometimes includes layer prefixes (`(server-side-rendering)/...`). Need to confirm which format appears in the manifest we emit and whether it round-trips through `__webpack_require__(id)` at runtime.

6. **`compilation.entrypoints.forEach` vs `compilation.chunkGroups.forEach` semantics** on rspack for walking client components. Should match webpack but worth verifying.

7. **`configuredCrossOriginLoading` / `outputOptions.crossOriginLoading`** — webpack has this output option; rspack should too but with potentially different defaults.

---

## 11. References

### In this repo
- [`.claude/docs/rspack-rsc-support-state.md`](./rspack-rsc-support-state.md) — rspack's official RSC state
- [`.claude/docs/rsc-rspack-implementation-plan.md`](./rsc-rspack-implementation-plan.md) — original high-level plan
- [`docs/pro/react-server-components/rspack-compatibility.md`](../../docs/pro/react-server-components/rspack-compatibility.md) — current status doc

### Tracking
- [shakacode/react_on_rails#3141](https://github.com/shakacode/react_on_rails/issues/3141) — this investigation's parent issue
- [shakacode/react_on_rails#1828](https://github.com/shakacode/react_on_rails/issues/1828) — original "rspack support for RSC" tracker
- [shakacode/react_on_rails#2552](https://github.com/shakacode/react_on_rails/issues/2552) — RFC: rename `*WebpackConfig.js` (do NOT land concurrently with this work)
- [shakacode/react_on_rails_rsc test/rspack-compatibility](https://github.com/shakacode/react_on_rails_rsc/tree/test/rspack-compatibility) — 31 verification tests

### External
- [web-infra-dev/rspack#12012](https://github.com/web-infra-dev/rspack/pull/12012) — rspack's built-in RSC landing PR
- [SyMind/react-server-dom-rspack](https://github.com/SyMind/react-server-dom-rspack) — the wrapper; we're NOT using it but its patch file is our reference for the chunk-cache issue
- [rstackjs/rspack-rsc-examples](https://github.com/rstackjs/rspack-rsc-examples) — working pure-rspack RSC example we validated
- [Rspack runtime API docs](https://rspack.rs/api/runtime-api/module-variables) — documents `__webpack_*` global compatibility

### Working prototype (for reference during Phase 0)
- `/mnt/ssd/demos/rspack-rsc-pure/` — running pure-rspack RSC app
- `/mnt/ssd/demos/ror-rspack-demo/` — React on Rails + rspack + no RSC (from earlier in this investigation)
- `/mnt/ssd/react-on-rails-rsc/` on branch `test/rspack-compatibility` — 31 compat tests

---

## Revision History

| Date | Change |
|---|---|
| 2026-04-14 | Initial draft after investigation |

# RSC Rspack client reference inclusion decision record — 2026-06-27

## Purpose

Record the maintainer-facing history and current decision points for React on Rails Pro + React Server Components + Rspack client-reference manifest generation.

This is an internal decision record, not user docs. It reconstructs the sequence from the first Rspack client-manifest plugin through the lazyCompilation fix, then records which longer-term Rspack inclusion mechanisms remain viable. It exists so future ROR/RORP/RSC work does not rediscover the same traps around:

- RSC client manifest entries;
- async client-reference chunks;
- `RSCRspackPlugin` inclusion mechanisms;
- Rspack `lazyCompilation` in Rails dev-server setups;
- `compilation.addInclude` versus source-level dynamic import injection;
- missing public Rspack JavaScript APIs for Webpack-style async dependency blocks.

## Current status

- Fresh generated RORP RSC + Rspack apps now work in normal `bin/dev` because `react_on_rails` disables top-level Rspack `lazyCompilation` for generated RSC + Rspack dev-server configs in [react_on_rails#4227](https://github.com/shakacode/react_on_rails/pull/4227).
- [react_on_rails#4213](https://github.com/shakacode/react_on_rails/pull/4213) and [react_on_rails#4223](https://github.com/shakacode/react_on_rails/pull/4223) added interim install/doctor/artifact diagnostics before the runtime dev-server fix.
- [react_on_rails#4234](https://github.com/shakacode/react_on_rails/pull/4234) added follow-up docs and doctor guardrails.
- [react_on_rails#4243](https://github.com/shakacode/react_on_rails/issues/4243) tracks a smaller doctor false-warning gap for equivalent custom lazy-compilation configs.
- Longer-term Rspack RSC architecture remains unresolved. Existing tracking:
  - [react_on_rails#3488](https://github.com/shakacode/react_on_rails/issues/3488) — pivot to native `RSCRspackPlugin` / production-ready Rspack RSC.
  - [react_on_rails#3553](https://github.com/shakacode/react_on_rails/issues/3553) — derive RSC client refs from the actual RSC graph.
- The `compilation.addInclude`-only client inclusion approach documented below should not be treated as the final client-bundle architecture. It proved one useful fact: `addInclude` can make the manifest contain real modules without lazy-compilation proxies. It also exposed a blocker: client refs became eager entry code (`chunks: []`) instead of selective async client-reference chunks.

## RSC client manifest model

React Flight client references need a manifest entry that maps a file/export to:

- a bundler module id;
- JavaScript chunks that must be loaded before requiring that module;
- export name metadata.

Typical shape:

```json
{
  "file:///app/javascript/src/HelloServer/components/LikeButton.jsx": {
    "id": "./app/javascript/src/HelloServer/components/LikeButton.jsx",
    "chunks": ["123", "js/client0-abc123.chunk.js"],
    "name": "*"
  }
}
```

`chunks` is not just decoration. It preserves RSC's selective client-island loading:

- non-empty `chunks` means Flight can load only the client component chunks needed by the current RSC payload;
- `chunks: []` means the module is already in the initial/entry chunk, so no extra chunk needs loading.

`chunks: []` is valid, but it weakens the architecture if many client references are included up front in the generated RSC entry. It keeps correctness, but loses the intended async splitting benefit.

## Timeline and mechanism history

### 1. `react_on_rails_rsc#29`: first Rspack plugin using `addInclude`

[react_on_rails_rsc#29](https://github.com/shakacode/react_on_rails_rsc/pull/29) introduced `RSCRspackPlugin` as a Rspack-native manifest emitter. The PR described three phases:

1. scan configured `clientReferences` for `'use client'` files;
2. inject discovered files with `compilation.addInclude` / `EntryPlugin.createDependency`;
3. emit `react-client-manifest.json` and `react-server-client-manifest.json`.

The important design constraint already existed: Rspack's Rust-backed dependency model did not expose Webpack's custom dependency/subclass APIs cleanly to JavaScript, so the implementation used public Rspack APIs.

Problem discovered after #29: using `addInclude` with generated names like `client0`, `client1`, etc. creates entry-like chunks, not Webpack-style async child chunks of the Flight runtime. That distinction matters because React Flight expects client-reference chunks to register modules into the runtime that loads the RSC page.

Bad shape:

```text
client ref -> addInclude(name: client0)
           -> standalone entry/IIFE/runtime
```

Desired shape:

```text
client ref -> async block under Flight runtime
           -> async chunk registers modules with shared runtime
```

Separate entry/IIFE chunks can trap modules in a private runtime, duplicate shared dependencies, and break hydration/runtime lookup assumptions.

### 2. `react_on_rails_rsc#36`: server parity/export fixes, then injection-loader direction

[react_on_rails_rsc#36](https://github.com/shakacode/react_on_rails_rsc/pull/36) fixed production/server-side issues found after #29:

- server bundles also needed client-reference inclusion when refs were outside the server entry import tree;
- server-side `addInclude` needed to reuse an existing server entry name to avoid Rspack node-target chunk/external crashes;
- injected modules needed `setUsedInUnknownWay()` so production export mangling did not rename exports that Flight resolves by original name.

The final code path moved the client-side inclusion mechanism toward an injection loader. Current `react_on_rails_rsc` source still has this architecture:

```text
client refs -> loader prepends import("/abs/client-ref") into Flight runtime -> Rspack creates async chunks
```

Current source references:

- [`src/react-server-dom-rspack/injection-loader.ts`](https://github.com/shakacode/react_on_rails_rsc/blob/main/src/react-server-dom-rspack/injection-loader.ts)
- [`src/react-server-dom-rspack/plugin.ts`](https://github.com/shakacode/react_on_rails_rsc/blob/main/src/react-server-dom-rspack/plugin.ts)

Why this mechanism was chosen: for the client bundle, dynamic `import()` is Rspack's public path for producing real async chunks from JavaScript plugin code. It goes through normal code splitting and produces chunks that register into the shared runtime.

### 3. `react_on_rails_rsc#38`: stabilize injection-loader manifest generation

[react_on_rails_rsc#38](https://github.com/shakacode/react_on_rails_rsc/pull/38) fixed failures surfaced after the injection-loader move:

- loader matching against the Flight runtime;
- chunk group walking for manifest chunk lists;
- filtering manifest entries to resolved `clientReferences` rather than every `'use client'` file in an app;
- excluding `node_modules` from directive detection;
- making test fixtures compile the Flight client runtime entry so injected imports actually create chunks.

Simple terms: #38 made the injection-loader path produce scoped, usable manifests in static/prod-style builds. It was not proof that normal Rspack dev-server lazy-compilation/HMR mode worked.

### 4. `react_on_rails#3553`, `react_on_rails_rsc#46`, `react_on_rails#3556`: derive refs from the real RSC graph

[react_on_rails#3553](https://github.com/shakacode/react_on_rails/issues/3553) proposed deriving RSC client references from the actual RSC graph instead of broad file scanning.

Related work:

- [react_on_rails_rsc#46](https://github.com/shakacode/react_on_rails_rsc/pull/46) — package-side graph-derived refs PR; closed, paired with the ROR/RORP integration work.
- [react_on_rails#3556](https://github.com/shakacode/react_on_rails/pull/3556) — merged ROR/RORP integration.

This solved a different problem:

```text
Which files are RSC client refs?
```

It did not solve:

```text
How should Rspack include those refs so dev-server lazy compilation does not proxy them and so async chunk metadata remains correct?
```

Graph-derived refs reduce false positives. They do not, by themselves, provide a safe Rspack client-reference inclusion primitive.

### 5. `react_on_rails#4200` and `react_on_rails#4227`: normal `bin/dev` failure

[react_on_rails#4200](https://github.com/shakacode/react_on_rails/issues/4200) described the fresh-app normal `bin/dev` failure. [react_on_rails#4213](https://github.com/shakacode/react_on_rails/pull/4213) and [react_on_rails#4223](https://github.com/shakacode/react_on_rails/pull/4223) improved diagnostics around that failure first; [react_on_rails#4227](https://github.com/shakacode/react_on_rails/pull/4227) later changed the generated dev config so normal `bin/dev` works.

Failure shape:

- `/hello_server` returned 200;
- server render failed because `react-client-manifest.json` was empty;
- static mode worked;
- browser requested `POST /_rspack/lazy/trigger` against the Rails origin and got 404.

Root cause:

```text
injection-loader inserted dynamic import("/abs/LikeButton.jsx")
-> Rspack dev-server lazyCompilation proxied dynamic imports
-> manifest builder saw lazy proxies or unbuilt modules, not real client refs
-> server render needed manifest before browser lazy trigger could build modules
```

Rspack docs say web-target lazy compilation defaults to `{ entries: false, imports: true }`, and lazy compilation proxies unexecuted entries/dynamic imports until runtime requests trigger compilation. Default trigger prefix is `/_rspack/lazy/trigger`.

Sources:

- <https://rspack.rs/config/lazy-compilation>
- <https://rspack.rs/guide/features/lazy-compilation>

[react_on_rails#4227](https://github.com/shakacode/react_on_rails/pull/4227) shipped the short-term fix:

```js
clientWebpackConfig.lazyCompilation = false;
```

Only for generated RSC + Rspack dev-server config.

This was intentionally a minimal runtime fix, not a full Rspack RSC architecture rewrite.

### 6. `react_on_rails#4234` and `react_on_rails#4243`: docs/doctor follow-up

[react_on_rails#4234](https://github.com/shakacode/react_on_rails/pull/4234) improved docs and doctor guidance around the lazyCompilation footgun.

[react_on_rails#4243](https://github.com/shakacode/react_on_rails/issues/4243) tracks that the doctor check currently recognizes the generated literal assignment pattern, not every equivalent final config:

```js
clientWebpackConfig.lazyCompilation = false;
```

Empirical variants that produced effective `lazyCompilation: false` but still warned included:

- `Object.assign(clientWebpackConfig, { lazyCompilation: false })`;
- helper function in a separate file;
- ternary assignment when RSC config exists;
- disabling in `clientWebpackConfig.js` or `rspack.config.js`;
- object form such as `{ entries: false, imports: false }`.

## `addInclude` implementation tests

Three concrete `compilation.addInclude` shapes were tested after the lazyCompilation failure. Each shape answered a specific question about whether `addInclude` can replace source-level dynamic imports for RSC client-reference inclusion. These were June 2026 local implementation tests, not merged package changes; rerun them against current `react_on_rails_rsc` before using any result as design proof.

### Test 1: separate `addInclude` entry/group

Result:

- avoids lazy dynamic import proxying;
- preserves real module resources;
- can create split-looking output;
- but creates new entry-like chunks, not async child chunks;
- node target + externals can crash with errors like `Cannot fulfil chunk condition of external node-commonjs "fs"`;
- production output can duplicate shared dependencies and/or isolate module maps in standalone IIFEs.

This is not acceptable as a client-side RSC chunk strategy.

### Test 2: `addInclude` into an existing generated entry

This approach attached discovered refs to an existing generated RSC entry instead of creating new standalone include entries:

```text
LikeButton.jsx -> generated/HelloServer
```

Result:

- a freshly generated app rendered in normal `bin/dev` Rspack dev-server mode;
- Playwright click/HMR worked;
- no `lazy-compilation-proxy`;
- no `/_rspack/lazy` requests;
- manifest contained `LikeButton.jsx`;
- but manifest entries had `chunks: []`.

Meaning:

```text
LikeButton.jsx was bundled into generated/HelloServer.js up front.
```

That fixes rendering correctness but loses async client-reference chunk splitting. It should not be considered final unless the project explicitly accepts eager client refs for generated RSC entries and measures the bundle-size/runtime impact.

### Test 3: all-entry `addInclude`

This approach added discovered refs to every configured entry. It proved that `addInclude` can force real modules into the build graph, but it polluted unrelated entries, including non-RSC application entries. This is not a viable design.

### Ownership metadata

Ownership was introduced only because `addInclude` requires a target entry name. Existing injection-loader architecture does not need ownership metadata.

For an `addInclude` design, ownership means:

```text
Which generated RSC entry caused this client ref to be needed?
```

Example:

```text
generated/HelloServer -> LikeButton.jsx
generated/ProductServer -> ProductButton.jsx
```

Without ownership, `addInclude` choices are all bad:

- add every ref to every entry: duplication/pollution;
- create standalone entries: separate runtime/IIFE problems;
- attach to arbitrary first entry: wrong for multiple RSC entries.

Native Rspack RSC also cares about ownership. [web-infra-dev/rspack#13880](https://github.com/web-infra-dev/rspack/pull/13880) groups client chunks by server-entry ownership and treats shared/multi-owner modules specially.

## Rspack public JavaScript API blocker

The Webpack RSC-style client inclusion primitive is roughly:

```js
const block = new webpack.AsyncDependenciesBlock({ name: 'client0' });
block.addDependency(dep);
module.addBlock(block);
```

This attaches an async dependency block to the Flight runtime module. The bundler emits async chunks that register into the same runtime module table.

Rspack is aware of this API gap:

- [web-infra-dev/rspack#7174](https://github.com/web-infra-dev/rspack/issues/7174) remains open for `Module.addBlock(...)` and `new AsyncDependenciesBlock(...)` parity.
- [web-infra-dev/rspack#8469](https://github.com/web-infra-dev/rspack/issues/8469) listed missing RSC framework APIs, including:
  - `AsyncDependenciesBlock`;
  - `block.addDependency`;
  - `module.blocks`;
  - `module.addBlock`.

#8469 is closed, but not because public JavaScript `module.addBlock` parity exists. It closed after Rspack/Modern.js concluded RSC support could be built with Rspack-provided APIs and native/internal Rspack RSC mechanisms.

As of 2026-06-27, Rspack main exposes read-side block wrappers, not the Webpack-style construction/mutation API:

- `AsyncDependenciesBlock.dependencies` getter;
- `AsyncDependenciesBlock.blocks` getter;
- `Module.blocks` getter.

It does not expose a safe public JS path for:

- constructing `AsyncDependenciesBlock`;
- adding dependencies to a block;
- attaching a block to a module.

Rspack PR [#9661](https://github.com/web-infra-dev/rspack/pull/9661) added JS API identity support such as `block instanceof AsyncDependenciesBlock`, not full block construction/mutation.

## Rspack native RSC direction

Rspack is actively solving RSC, but mostly inside its native/plugin internals rather than by exposing Webpack-compatible JS plugin APIs.

Relevant work:

- [web-infra-dev/rspack#13136](https://github.com/web-infra-dev/rspack/pull/13136) replaced loader-generated dynamic imports with a custom `ClientEntryDependency` / `ClientEntryModule` approach so native RSC is compatible with lazy compilation. The PR explains the same bug class: loader-created `import()` becomes `DynamicImport`, lazy compilation proxies it, and Flight expects real modules synchronously after chunk load.
- [web-infra-dev/rspack#13880](https://github.com/web-infra-dev/rspack/pull/13880) groups RSC client chunks by server-entry ownership.
- Current Rspack native RSC source uses internal Rust `AsyncDependenciesBlock` creation in [`crates/rspack_plugin_rsc/src/rsc_entry_module.rs`](https://github.com/web-infra-dev/rspack/blob/main/crates/rspack_plugin_rsc/src/rsc_entry_module.rs). `rspack_plugin_rsc` is a Rust crate compiled into the Rspack binary, not an npm package or public JavaScript plugin API.

This is useful prior art. It is not a drop-in replacement for RORP today because RORP's RSC integration, generated pack layout, Rails routing, SSR/node-renderer flow, and manifest consumption differ from Rspack native RSC's same-name entry/layer model.

## Rails + Rspack lazyCompilation is broader than RSC

This failure mode is not purely RSC-specific.

Rails split dev topology:

```text
Rails serves HTML:           http://localhost:<base>
Rspack dev-server serves JS: http://localhost:<base+1>
```

If Rspack lazy compilation injects a runtime trigger using the page origin, dynamic import execution can do:

```text
POST /_rspack/lazy/trigger -> Rails -> 404
```

Evidence outside the RORP RSC fresh-app repro:

- In [shakacode/shakapacker#984](https://github.com/shakacode/shakapacker/issues/984#issuecomment-4089667879), a Shakapacker/Rspack adopter said they had to disable Rspack lazy compilation because the Shakapacker server did not handle it out of the box.
- In [web-infra-dev/rspack#14194](https://github.com/web-infra-dev/rspack/issues/14194), a Rails + Shakapacker + Rspack starter hit lazy-trigger 404s around optional dynamic imports. The workaround was top-level `lazyCompilation: false`.

Internal context: Hichee's Rspack migration also disabled top-level `lazyCompilation` in its Rails/Rspack dev-server wiring; see private PR `shakacode/hichee#9508` for the RSC + Rspack migration context.

Implication:

- For RSC: disabling lazy compilation is currently required in generated dev-server config because server render needs a complete client manifest before any browser trigger can run.
- For non-RSC Rails + Rspack apps: dynamic imports may still need either disabled lazy compilation, a correct `lazyCompilation.serverUrl`, or a Rails proxy to Rspack's lazy middleware. This belongs more naturally in Shakapacker than React on Rails.

## Mechanism comparison

| Mechanism                                              |                  Client async chunks? |           Avoids lazy proxy? |                              Server manifest parity? | Main problems                                                                |
| ------------------------------------------------------ | ------------------------------------: | ---------------------------: | ---------------------------------------------------: | ---------------------------------------------------------------------------- |
| Injection-loader dynamic imports, lazy off             |                                   Yes |                          Yes | Needs server-side handling/fallbacks depending graph | Loader/runtime matching, module-global loader state, splitChunks guardrails  |
| Injection-loader dynamic imports, lazy on              | Theoretically yes, practically broken |                           No |                                    No for normal dev | Lazy proxies dynamic imports; manifest can be empty or proxy-backed          |
| `addInclude` with new generated include entries        |           Looks split, but wrong kind |                          Yes |                                                Risky | Separate runtime/IIFE, node externals crash, duplicated deps, hydration risk |
| `addInclude` into existing generated owner entry       |  No: refs become eager (`chunks: []`) |                          Yes |                 Better, but server side needs retest | Loses async client-ref chunking; needs ownership/multi-owner policy          |
| Native Rspack RSC plugin                               |          Yes, via internal primitives | Rspack solved in native path |                                         Native model | Bigger architecture migration; not drop-in for RORP                          |
| Public JS `module.addBlock` / `AsyncDependenciesBlock` |                               Desired |     Would avoid fake imports |                         Desired with server handling | Not available today; track Rspack #7174                                      |

## Decisions

### Decision 1: Keep #4227 as short-term fix

Disabling top-level `lazyCompilation` for generated RSC + Rspack dev-server config is justified and already shipped.

Reason: the current client inclusion mechanism uses dynamic imports to create async chunks. Rspack lazy compilation proxies those imports. RSC server render needs the manifest before browser lazy triggers can compile modules.

### Decision 2: Do not ship client-side `addInclude`-only as long-term fix yet

Two tested shapes are bad in different ways:

- new include entries preserve separate files but create entry/IIFE/runtime problems;
- existing owner entry fixes runtime correctness but turns client refs eager (`chunks: []`).

A client-side `addInclude` design should not proceed unless it proves async chunk preservation or explicitly accepts eager client refs with measured bundle impact.

### Decision 3: Treat injection-loader as a pragmatic async-chunk bridge, not just a hack

Given missing public Rspack JS `AsyncDependenciesBlock` mutation APIs, source-level dynamic imports are currently the public Rspack-compatible way for a JS plugin to create async chunks.

The injection-loader remains fragile because it:

- must match the Flight runtime module;
- mutates source to express build-only relationships;
- shares discovered refs through loader/plugin process state;
- needs splitChunks guardrails;
- breaks under lazy compilation.

But with lazy disabled, it preserves async chunk behavior better than the tested `addInclude` approaches.

### Decision 4: Best near-term architectural candidate is hybrid, not full `addInclude`

Candidate:

```text
Client bundle:
  keep injection-loader/dynamic imports to preserve async chunks
  disable or exclude lazyCompilation for RSC-critical imports

Server bundle:
  use addInclude into existing server entry when needed for manifest parity
  reuse existing generated entry names, not new include entries
  mark exports used in unknown way
```

This matches the #36 research direction: client async chunks need bundler code-splitting; server bundle can use existing-entry `addInclude` because server output is usually merged into one server bundle and does not need browser async chunk semantics. Existing-entry reuse is a hard constraint: new include entries can trigger Rspack node-target external chunk errors such as `Cannot fulfil chunk condition of external node-commonjs "fs"`.

This candidate still needs implementation and validation against current `react_on_rails_rsc` main before PR work.

### Decision 5: Native Rspack RSC remains possible but larger

Native Rspack RSC has mechanisms RORP needs:

- client entry modules/dependencies instead of loader-generated imports;
- lazy-compatible client refs;
- ownership-aware chunk grouping;
- internal async block support.

But adopting it in RORP is a larger architecture migration, not a narrow fix for current generated apps.

## Open questions and next actions

1. **Rspack public API follow-up**
   - Comment on or file upstream context for Rspack #7174.
   - Ask whether public JavaScript `module.addBlock` / `AsyncDependenciesBlock` mutation is planned.
   - Explain the RORP use case: create RSC client-reference async chunks from a JavaScript plugin without source injection.

2. **Shakapacker lazyCompilation follow-up**
   - Decide whether Shakapacker should disable or configure Rspack `lazyCompilation` for Rails split dev-server setups.
   - Evidence suggests the Rails lazy-trigger 404 problem is broader than RSC.
   - Potential Shakapacker fixes:
     - default `lazyCompilation: false` when using `rspack serve` through Shakapacker;
     - set `lazyCompilation.serverUrl` to the Rspack dev-server origin;
     - document Rails proxy requirements if lazy remains enabled.

3. **RORP hybrid implementation follow-up**
   - Track package-side follow-up in [react_on_rails_rsc#72](https://github.com/shakacode/react_on_rails_rsc/issues/72).
   - Revalidate the hybrid client/server design against current `react_on_rails_rsc` main.
   - Required checks:
     - client manifest chunks remain non-empty for split refs;
     - server manifest has real module ids for unimported refs;
     - a freshly generated app works in normal `bin/dev` Rspack dev-server mode;
     - Playwright click/HMR works;
     - production chunk sizes do not regress;
     - #29/#36 failure modes remain covered.

4. **Graph-derived refs with ownership metadata**
   - Reintroduce ownership metadata only if pursuing `addInclude` or native-like grouping.
   - Ownership is less urgent if the current injection-loader stays flat and scoped by explicit refs.
   - Multi-owner refs need explicit policy, not arbitrary first-owner assignment.

5. **Tracking issue update**
   - Link this decision record from #3488 after the doc lands so future Rspack RSC work starts from this context.

## Reference links

React on Rails / RORP:

- [react_on_rails#3488 — Rspack RSC production-ready tracking](https://github.com/shakacode/react_on_rails/issues/3488)
- [react_on_rails#3553 — graph-derived client refs RFC](https://github.com/shakacode/react_on_rails/issues/3553)
- [react_on_rails#3556 — derive Pro RSC client refs from graph](https://github.com/shakacode/react_on_rails/pull/3556)
- [react_on_rails#4200 — empty Rspack dev-server client manifest](https://github.com/shakacode/react_on_rails/issues/4200)
- [react_on_rails#4213 — install and doctor diagnostics](https://github.com/shakacode/react_on_rails/pull/4213)
- [react_on_rails#4223 — RSC doctor artifact diagnostics](https://github.com/shakacode/react_on_rails/pull/4223)
- [react_on_rails#4227 — short-term lazyCompilation fix](https://github.com/shakacode/react_on_rails/pull/4227)
- [react_on_rails#4234 — docs/doctor follow-up](https://github.com/shakacode/react_on_rails/pull/4234)
- [react_on_rails#4243 — doctor false-warning follow-up](https://github.com/shakacode/react_on_rails/issues/4243)

RSC package:

- [react_on_rails_rsc#29 — initial Rspack plugin](https://github.com/shakacode/react_on_rails_rsc/pull/29)
- [react_on_rails_rsc#36 — server injection/export preservation](https://github.com/shakacode/react_on_rails_rsc/pull/36)
- [react_on_rails_rsc#38 — Rspack manifest generation fixes](https://github.com/shakacode/react_on_rails_rsc/pull/38)
- [react_on_rails_rsc#46 — graph-derived refs package PR, closed](https://github.com/shakacode/react_on_rails_rsc/pull/46)
- [react_on_rails_rsc#72 — package improvement tracking](https://github.com/shakacode/react_on_rails_rsc/issues/72)

Rspack / Shakapacker:

- [Rspack lazyCompilation config](https://rspack.rs/config/lazy-compilation)
- [Rspack lazyCompilation guide](https://rspack.rs/guide/features/lazy-compilation)
- [web-infra-dev/rspack#7174 — Module.addBlock API](https://github.com/web-infra-dev/rspack/issues/7174)
- [web-infra-dev/rspack#8469 — missing RSC framework APIs](https://github.com/web-infra-dev/rspack/issues/8469)
- [web-infra-dev/rspack#9661 — JS identity support for dependency blocks](https://github.com/web-infra-dev/rspack/pull/9661)
- [web-infra-dev/rspack#13136 — native RSC lazy-compatible client entry module](https://github.com/web-infra-dev/rspack/pull/13136)
- [web-infra-dev/rspack#13880 — RSC ownership-based client chunk grouping](https://github.com/web-infra-dev/rspack/pull/13880)
- [web-infra-dev/rspack#14194 — Rails/Shakapacker lazyCompilation opt-out issue](https://github.com/web-infra-dev/rspack/issues/14194)
- [shakacode/shakapacker#984 comment — adopter disabled lazyCompilation](https://github.com/shakacode/shakapacker/issues/984#issuecomment-4089667879)

# 04 — Next.js (App Router) + Turbopack: A Deep Dive

> Researched against a fresh clone of **`vercel/next.js`** (v16.3.0‑canary) including the full
> `turbopack/` + `crates/` Rust source, and **`facebook/react`** (the `react-server-dom-*` runtimes).
> 🧒 ELI5 boxes explain the ideas; 🛠️ sections give exact files/symbols (paths relative to the
> next.js repo root). Read alongside docs 01–03 — the concepts map almost one‑to‑one onto React on
> Rails Pro, just with different names and a Rust bundler.

---

## 1. 🧒 ELI5: What even is Next.js here?

Next.js is a **whole restaurant in a box**: it's the kitchen (server), the menu/routing (which dish
for which table), the waiters (client router), _and_ the lunchbox‑packing machine (the bundler,
**Turbopack**). React on Rails is "bring your own restaurant (Rails) and we'll handle the React
cooking station." Next.js owns the entire building.

Three words you'll see constantly:

- **App Router** = Next's newer routing system where your **folders are your URLs** and files named
  `page.tsx` / `layout.tsx` describe the page. This is the part that's built around Server Components.
- **Flight / RSC payload** = the exact same "order ticket" idea from doc 01. Next calls the inlined
  global array **`self.__next_f`** (React on Rails calls it `REACT_ON_RAILS_RSC_PAYLOADS`).
- **Turbopack** = Next's bundler, written in **Rust**, that replaces webpack. It's the
  counterpart to "webpack/rspack via Shakapacker," but built into the framework and RSC‑aware in Rust.

---

## 2. The server render flow (the Next.js analog of doc 01)

### 2.1 🧒 ELI5

Same restaurant story as React on Rails Pro:

1. Browser asks for `/dashboard`.
2. Next looks at your **folders** to figure out which dishes (`layout.tsx` wrapping `page.tsx`) make
   up that page — this folder map is called the **loader tree**.
3. The **RSC kitchen** cooks the server components into an order ticket (Flight payload), with "use
   your kit #47" labels for client components.
4. Next takes a **photo of the plate** (SSR → HTML) so you see it instantly, and **staples the order
   ticket to the photo** as `<script>self.__next_f.push(...)</script>` tags.
5. The photo + ticket stream to the browser as it cooks (Suspense = "send the appetizer now, dessert
   later").
6. The browser rebuilds the real interactive plate from the ticket and connects the buttons
   (hydration).

### 2.2 🛠️ The real call chain (server)

```
Browser GET /dashboard
   │
   ▼
AppPageRouteModule.render()                    packages/next/src/server/route-modules/app-page/module.ts
   → renderToHTMLOrFlight()                    packages/next/src/server/app-render/app-render.tsx
       → renderToHTMLOrFlightImpl()
            loaderTree = ComponentMod.routeModule.userland.loaderTree   ← folders → tree (built by next-app-loader)
            manifests  = getClientReferenceManifest()                   ← load-components.ts → manifests-singleton.ts
            │
            ├── isRSCRequest? (a navigation/prefetch with the `RSC` header)
            │      → generateDynamicFlightRenderResult()  → Flight stream ONLY (no HTML)
            │
            └── document request
                   → renderToStream()  (app-render.tsx)
```

**The loader tree** is the file‑system route tree — a recursive tuple
`[segment, parallelRoutes, modules, …]` where `modules` holds lazy importers for
`layout`/`page`/`loading`/`error`/`not-found` (`packages/next/src/server/lib/app-dir-module.ts`).
This is Next's equivalent of "which component(s) does this Rails route render," except it's derived
from your folder structure instead of a controller calling `stream_react_component`.

**Two passes inside one `renderToStream`** (exactly the doc‑01 two‑pass model):

```
PASS 1 — RSC render (produces the Flight payload)
  getRSCPayload(loaderTree, ctx)                          app-render.tsx (getRSCPayload)
    → createFlightRouterStateFromLoaderTree(...)          (the routing state)
    → createComponentTree(...)  → CacheNodeSeedData       (the actual React element tree)
    → returns InitialRSCPayload { P, c, f:[tree,seed,head], G, S, b, ... }   (short keys to save bytes)
  renderToNodeFlightStream(ComponentMod, payload, clientModules, {...})   stream-ops.node.ts
    → ComponentMod.renderToPipeableStream(payload, clientModules, opts)
    → = react-server-dom-webpack/server (or -turbopack)  → Flight stream

PASS 2 — SSR render (turns Flight into HTML)
  <App reactServerStream={rscStream.tee()} ...>           app-render.tsx (function App)
    → ReactClient.use(getFlightStream(stream))            use-flight-response.tsx
        → createFromNodeStream(stream, ssrModuleMapping)  ← deserialize Flight on the server
    → <AppRouter actionQueue=... />
  renderToNodeFizzStream(appElement, fizzOptions)         stream-ops.node.ts
    → react-dom/server renderToPipeableStream             → HTML shell + Suspense streaming
```

🧒 **Why two passes?** Same reason as React on Rails Pro: Pass 1 makes the _description_ (works for
both first paint and hydration); Pass 2 turns that description into a _photo_ (HTML) so the user sees
content before any JS runs. The same Flight stream is **tee'd** — one copy feeds the HTML pass, the
other gets inlined for the browser.

### 2.3 🛠️ Streaming + inlining: `self.__next_f` (≈ `REACT_ON_RAILS_RSC_PAYLOADS`)

`createInlinedDataReadableStream` (`use-flight-response.tsx`) wraps the Flight stream and emits
`<script>` tags that push onto a global array:

```html
<script>
  (self.__next_f = self.__next_f || []).push([0]);
</script>
<!-- bootstrap marker -->
<script>
  self.__next_f.push([1, '<flight chunk text>']);
</script>
<!-- a Flight data chunk -->
<script>
  self.__next_f.push([2, formState]);
</script>
<!-- form state -->
<script>
  self.__next_f.push([3, '<base64>']);
</script>
<!-- binary chunk -->
```

The HTML stream and these inline‑data scripts are merged by `continueFizzStream`
(`stream-ops.node.ts`) through a transform chain:

- `createFlightDataInjectionTransform(...)` — **interleaves** `__next_f` scripts with the HTML so a
  Suspense boundary's data lands near its HTML;
- `createHeadInsertionTransform(getServerInsertedHTML)` — injects `<head>` content (preloads, CSS,
  meta);
- bootstrap `<script src=…>` from `required-scripts.tsx` kicks off hydration.

| Next.js                           | React on Rails Pro (doc 01)                           |
| --------------------------------- | ----------------------------------------------------- |
| `self.__next_f.push([1, "…"])`    | `REACT_ON_RAILS_RSC_PAYLOADS[key].push("…")`          |
| `createInlinedDataReadableStream` | `injectRSCPayload.ts` (3 ordered buffers)             |
| `continueFizzStream` transforms   | `stream.rb` queue + `injectRSCPayload` flush ordering |
| `[0]/[1]/[2]/[3]` tuple tags      | length‑prefixed `metadata\thexlen\ncontent` NDJSON    |

Both solve the identical problem (stream HTML + inline the Flight payload, ordered so the browser
never uses data that hasn't arrived). Different wire encoding, same idea.

### 2.4 🛠️ Manifests at render time

`getClientReferenceManifest()` (`manifests-singleton.ts`) returns a proxy over the per‑route
`globalThis.__RSC_MANIFEST[...]`. It exposes the maps React/Flight need:

- `clientModules` → passed to the **RSC render** to encode client refs as `{ id, chunks, name }`;
- `ssrModuleMapping` / `edgeSSRModuleMapping` + `moduleLoading` → passed to `createFromNodeStream`
  during the **SSR pass** to load the real client modules for HTML;
- `serverModuleMap` (from `server-reference-manifest`) → resolve `'use server'` actions.

These are the direct analog of React on Rails Pro's `react-client-manifest.json` /
`react-server-client-manifest.json`.

### 2.5 🛠️ PPR (Partial Prerendering) — the thing React on Rails doesn't have

🧒 **ELI5:** PPR lets Next pre‑photograph the _static_ parts of a plate at build time (the menu
border, the logo) and leave **holes** where the personalized food goes. At request time it ships the
pre‑made static shell **instantly** and streams just the holes. It's like having the place settings
already on the table before you even order.

🛠️ When `isRoutePPREnabled`/`cacheComponents`, `prerenderToStream` uses **`react-dom/static`'s
`prerender`** to produce a static prelude; dynamic holes call `react.unstable_postpone` and the
postponed React state is serialized (`getDynamic{HTML,Data}PostponedState`, `postponed-state.ts`).
At request time `resumeToFizzStream` resumes rendering into the holes. There's no React on Rails
equivalent today — RoR's closest analog is **async props / incremental streaming** (doc 01 §6), which
streams updates but doesn't split a build‑time static shell from request‑time dynamic holes.

### 2.6 Server render diagram

```
GET /dashboard ──► AppPageRouteModule.render ──► renderToHTMLOrFlight ──► renderToStream
                                                          │
   loaderTree (folders)         manifests (__RSC_MANIFEST)│
        │                              │                  │
        ▼                              ▼                  ▼
   PASS 1 RSC:  getRSCPayload → createComponentTree → CacheNodeSeedData
                renderToNodeFlightStream → react-server-dom-*/server
                       │  Flight stream ─────────────┐ tee
                       │                             │
        ┌──────────────┴───────────┐    ┌────────────┴───────────────┐
        ▼ PASS 2 SSR               │    ▼ INLINE                      │
   <App reactServerStream>          │  createInlinedDataReadableStream │
    use(getFlightStream)            │   <script>self.__next_f.push([1,"…"])</script>
     createFromNodeStream(ssrMap)   │            │
    <AppRouter/>                    │            │
   renderToNodeFizzStream           │            │
    react-dom/server → HTML ────────┴── continueFizzStream (interleave + head + bootstrap)
                                                 │
 ◄───────────────── single HTML document stream ─┘
   <html>…shell…<script>__next_f.push([1,"…"])</script>…<script src=app-bundle>…</html>
```

---

## 3. The client runtime (the Next.js analog of doc 01 §F–G)

### 3.1 🧒 ELI5

The browser gets the photo (HTML) and the order ticket (the `__next_f` scripts). The Next.js
**waiters** (the client router) read the ticket, rebuild the real interactive plate, and wire up the
buttons (hydration). After that, when you click a link, the waiter fetches **just a new ticket for
the parts that changed** — never the whole page — and even **pre‑fetches** tickets for links you're
about to click so navigation feels instant.

### 3.2 🛠️ Hydration bootstrap

```
app-next.ts → appBootstrap() → hydrate()                packages/next/src/client/app-{next,bootstrap,index}.tsx
  self.__next_f.forEach(nextServerDataCallback)          ← drain chunks pushed before JS loaded
  self.__next_f.push = nextServerDataCallback            ← monkey-patch push to feed a ReadableStream
  createFromReadableStream<InitialRSCPayload>(stream)     ← react-server-dom-webpack/client: rebuild tree
  createMutableActionQueue(createInitialRouterState(...)) ← seed router state from payload
  React.startTransition(() =>
    hydrateRoot(document, <AppRouter actionQueue .../>, { formState, onRecoverableError, ... }))
```

This is the same shape as React on Rails Pro's `createFromPreloadedPayloads` →
`createFromReadableStream` → `hydrateRoot`. The `__next_f` "drain then patch `push`" trick is how
Next handles chunks that arrive _both_ before and after the runtime loads — RoR's `injectRSCPayload`
init‑array ordering plays the same role.

### 3.3 🛠️ The router, its two caches, and soft navigation

The App Router (`packages/next/src/client/components/app-router.tsx`) runs a reducer/action queue
(`router-reducer.ts`, `app-router-instance.ts`). Two state shapes matter:

- **`FlightRouterState`** — the tree of _which segments are active_ (`[segment, parallelRoutes, …]`).
- **`CacheNode`** — the tree of _rendered React nodes_ per segment (`{ rsc, prefetchRsc, head, slots,
… }`). `rsc === null` ⇒ "suspend here."

Two cache layers:

1. **Router cache** = the `CacheNode` tree in reducer state (currently shown).
2. **Segment Cache / prefetch cache** = a **separate global store** (`segment-cache/cache.ts`) keyed
   by route + segment, holding prefetched static RSC. This is the PPR‑era prefetch system.

**Soft navigation** (click `<Link>`):

```
<Link> click → linkClicked (preventDefault) → dispatchNavigateAction
   → navigateReducer → navigate()                        segment-cache/navigation.ts
        cacheKey = createCacheKey(href, nextUrl)
        ├─ prefetch HIT  → reuse shared CacheNodes (startPPRNavigation), fetch only dynamic holes
        └─ MISS          → fetchServerResponse(url, { flightRouterState, nextUrl })
              GET url?_rsc=…   headers:
                 RSC: 1
                 Next-Router-State-Tree: <encoded current tree>
                 Next-Url: <nextUrl>
              ◄── text/x-component  (createFromFetch) → NavigationFlightResponse { f: FlightData, … }
        apply FlightData to the router cache (only the changed segments), update history/URL
```

🧒 **The key idea:** the browser tells the server "here's the tree I currently have"
(`Next-Router-State-Tree`), and the server replies with **only the parts that differ** — a
segment‑level diff, not a whole page. This is Next's big steady‑state win, and it's the same concept
as React on Rails Pro's `fetchRSC` → `/rsc_payload/:component_name` (doc 01 §G), just with richer
segment‑level granularity baked into the framework.

### 3.4 🛠️ Prefetching

`<Link>` uses a shared `IntersectionObserver` (200px margin) to prefetch when a link scrolls near the
viewport (disabled in dev), plus hover/touch intent (`links.ts`). A priority‑scheduled task
(`segment-cache/scheduler.ts`) fetches the **route tree** (`Next-Router-Segment-Prefetch: /_tree`)
then **per‑segment** static RSC (`Next-Router-Prefetch: 1`). `prefetch={true}` = full (incl. dynamic);
`prefetch="auto"`/null = partial/PPR (static only). React on Rails Pro has **no built‑in prefetch
system** — this is a place where the full‑framework approach buys a lot.

### 3.5 🛠️ Server Actions

🧒 **ELI5:** a Server Action is a button at your table that, when pressed, runs a secret recipe **in
the kitchen** (server) and sends back both an answer _and_ an updated plate — in one trip.

🛠️ React's `callServer` (`app-call-server.ts`) → `fetchServerAction` (`server-action-reducer.ts`)
POSTs to the current URL with header **`Next-Action: <actionId>`** and a body encoded by
`encodeReply` (from `react-server-dom-webpack/client`). The single Flight response carries **both**
`a: actionResult` **and** `f: FlightData` (updated tree) — so the action's return value _and_ a
re‑render arrive together. The `actionId → module` mapping is the **server‑reference‑manifest**.
React on Rails Pro has no direct server‑actions analog; the closest is calling a Rails endpoint and
refetching an RSC payload.

### 3.6 Client diagrams

```
INITIAL HYDRATION
  <script>__next_f.push([0])</script> … push([1,"…"]) (streamed)
        │
  app-next.ts → appBootstrap → hydrate
        forEach(drain) ; __next_f.push = callback → ReadableStream
        createFromReadableStream<InitialRSCPayload>
        createInitialRouterState → action queue
        startTransition(hydrateRoot(document, <AppRouter/>, {formState}))
        │
        └─► IntersectionObserver starts prefetching visible <Link>s

SOFT NAVIGATION
  click <Link> ──► dispatchNavigateAction ──► navigate()
     HIT  → reuse shared CacheNodes + fetch only dynamic holes
     MISS → fetchServerResponse: GET ?_rsc, RSC:1, Next-Router-State-Tree, Next-Url
              ◄ text/x-component (createFromFetch) → apply segment diff to router cache
     HistoryUpdater: pushState(tree), update URL, re-prefetch visible links
```

---

## 4. Turbopack architecture (the Next.js answer to "webpack/rspack via Shakapacker")

### 4.1 🧒 ELI5: What makes Turbopack different?

webpack/rspack think in **whole dishes**: change one ingredient, they re‑cook that whole dish (and
anything that used it). Turbopack thinks in **tiny memoized steps**: "chop onion," "toast bun,"
"read file X." Every step remembers its answer. Change one character in one file and Turbopack only
re‑runs the handful of tiny steps whose inputs actually changed — everything else is reused from
memory (even across restarts). That "remember every tiny step" engine is called **turbo‑tasks**, and
it's why Turbopack is so fast at incremental rebuilds.

### 4.2 🛠️ The crates (Rust packages)

Two layers: the **generic bundler** (`turbopack/crates/*`) and the **Next.js integration**
(`crates/*`).

| Crate                                                     | Job                                                                                                                       |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `turbo-tasks`                                             | the incremental computation engine: memoized functions, `Vc<T>` value cells, automatic dependency tracking + invalidation |
| `turbo-tasks-fs`                                          | the filesystem as tracked tasks (a file read is a task → edits invalidate downstream)                                     |
| `turbo-persistence`                                       | on‑disk cache so incrementality survives restarts                                                                         |
| `turbopack-core`                                          | the central model: `Source` → `Module` → `OutputAsset`, `AssetContext`, `ModuleGraph`, `ChunkingContext`                  |
| `turbopack`                                               | orchestration: `ModuleAssetContext`, the **transition** system, module‑option rules                                       |
| `turbopack-ecmascript`                                    | JS/TS/JSX via SWC: parse → analyze → transform → chunk                                                                    |
| `turbopack-css` / `-image` / `-static` / `-wasm` / `-mdx` | other source types                                                                                                        |
| `turbopack-browser` / `-nodejs`                           | output targets (browser vs node chunking contexts + runtime)                                                              |
| `turbopack-dev-server`                                    | the dev HTTP/WebSocket server + update streaming                                                                          |
| `turbopack-node`                                          | run JS in Node from Rust (SSR, evaluation, **webpack‑loader compat shim**)                                                |
| **`next-core`**                                           | Next semantics: client/server/RSC contexts, the `react-server` condition, client‑reference modules, manifests             |
| **`next-api`**                                            | the `Project`/`Endpoint`/`Route` API the JS side drives (build & dev)                                                     |
| `next-custom-transforms`                                  | Next's SWC transforms incl. `react_server_components.rs`, `server_actions.rs`                                             |
| `next-napi-bindings`                                      | the N‑API bridge exposing Rust to Node                                                                                    |

### 4.3 🛠️ turbo‑tasks: the heart

🧒 **ELI5:** imagine a giant spreadsheet. Each cell is a small computation. When you change one cell,
only the cells that referenced it recalculate. turbo‑tasks is that spreadsheet, for a bundler.

🛠️ The primitives (`turbopack/crates/turbo-tasks/README.md`, `src/vc/README.md`):

- A `#[turbo_tasks::function]` is a **memoized function**; a function + specific args = a **task**.
- `Vc<T>` ("Value Cell") is a reference to a task's pending/cached output (like a spreadsheet cell).
- **Reading** a `Vc` (`.await`) registers the current task as a **dependent**. When the cell's value
  changes (compared via `PartialEq` when written), all dependents are **invalidated** and re‑run,
  **bottom‑up**. Unchanged parts do zero work.
- Tasks run on Tokio (parallel by default). `turbo-persistence` caches results across sessions.

This is _fundamentally_ finer‑grained than webpack/rspack's module‑level invalidation — the core
reason Turbopack's incremental builds are fast.

### 4.4 🛠️ Module graph & chunking

`turbopack-core` models three layers (`layers.md`): **`Source`** (raw bytes) →
**`Module`** (parsed understanding, exposes `references()`) → **`OutputAsset`** (bytes to emit).
`AssetContext::process(source) -> Module` applies module‑option rules; the graph is built by a
parallel DFS following `ModuleReference`s. **Chunking** (`chunk/`) walks the graph following only
references whose `ChunkingType` is non‑`None` (`Parallel`/`Async`/`Isolated`/`Shared`/`Traced`),
turns `ChunkableModule`s into `ChunkItem`s, splits by `ChunkType`, and emits `Chunk` → `OutputAsset`
via a `BrowserChunkingContext` or `NodeJsChunkingContext`.

🧒 **vs webpack:** webpack has one big mutable `Compilation` it runs through phases. Turbopack has
**no monolithic compilation object** — every step (read, parse, analyze, resolve, chunk, render) is a
separate memoized task. The "graph" that matters is the _task graph_; the module graph is just data
tasks produce.

### 4.5 🛠️ Dev server & HMR

```
file edit ──► turbo-tasks-fs read cell changes ──► invalidation propagates up the task graph
   │
   ▼
compute_update_stream  (turbopack-dev-server/src/update/stream.rs)
   re-runs on every invalidation (it's a turbo_tasks::function), computes a Version diff:
   Update::{None | Partial | Total | Missing}     (turbopack-core/src/version.rs)
   │  (None ⇒ no message sent; unchanged ⇒ no traffic)
   ▼
UpdateServer (WebSocket)   hmr-protocol: turbopack-subscribe / partial / restart / issues
   ▼
Browser hmr-client.ts + hmr-runtime.ts:  module.hot accept/dispose ; React Fast Refresh
   (unrecoverable → location.reload())
```

🧒 **ELI5:** because every step is memoized, the dev server can compute _exactly_ what changed and
send the browser a tiny "swap just this" message — and if nothing meaningfully changed, it sends
nothing at all. The browser's HMR runtime (which speaks the same `module.hot` dialect as webpack, so
React Fast Refresh works) swaps the module in place.

This is conceptually the same outcome as Shakapacker's webpack‑dev‑server HMR + React Refresh (doc
02), but driven by turbo‑tasks invalidation instead of webpack recompiling affected modules. Note:
Next's **server/SSR bundles also hot‑update** (Node‑side HMR via `next-api`), whereas React on Rails
Pro rebuilds its server/RSC bundles to disk with `--watch` and the node‑renderer reloads them.

### 4.6 🛠️ RSC support is **native** in Turbopack (the big architectural divergence)

This is the headline difference from React on Rails. In RoR, RSC is bolted onto a general‑purpose
bundler via **JS plugins/loaders** (`react-on-rails-rsc/WebpackPlugin` + `WebpackLoader`, doc 03). In
Next + Turbopack, RSC is **built into the bundler in Rust**:

- **Three contexts / the `react-server` condition** (`crates/next-core/src/next_server/context.rs`):
  `ServerContextType::{AppRSC, AppSSR, AppRoute, …}`. `should_use_react_server_condition()` returns
  true for the RSC contexts and pushes the `react-server` resolve condition — the Rust equivalent of
  RoR's `conditionNames: ['react-server', '...']` in `rscWebpackConfig.js`.
- **Client‑reference modules as first‑class graph nodes**
  (`crates/next-core/src/next_client_reference/…`): at a `'use client'` boundary, the
  `NextEcmascriptClientReferenceTransition` runs the _same source_ through **two** sub‑transitions
  (client + ssr) and wraps them in an `EcmascriptClientReferenceModule`. On the RSC server graph that
  module renders as a **reference**, not the real component — natively, no JS loader stripping it out.
- **Directive detection in SWC** (`crates/next-custom-transforms/src/transforms/react_server_components.rs`,
  `server_actions.rs`): `'use client'`/`'use server'` are detected and rewritten in Rust.
- **Manifest emission in Rust** (`crates/next-core/src/next_manifests/client_reference_manifest.rs`):
  emits the same `globalThis.__RSC_MANIFEST[...]` JSON (`clientModules`, `ssrModuleMapping`, …) that
  the webpack `ClientReferenceManifestPlugin` emits — **byte‑compatible**, so the render runtime is
  bundler‑agnostic.
- **The runtime swap:** `crates/next-core/src/next_import_map.rs` aliases
  `react-server-dom-webpack/*` → **`react-server-dom-turbopack/*`**. Same React Flight engine,
  Turbopack‑flavored chunk loading (`__turbopack_load_by_url__` / `__turbopack_require__` instead of
  `__webpack_*`). (See doc 05 for why these per‑bundler runtimes exist.)

### 4.7 🛠️ JS ↔ Rust bridge

`next dev` / `next build` (JS) call into Rust via N‑API: `packages/next/src/build/swc/index.ts`
(`loadBindings`, `bindingToApi` → `createProject`, `entrypointsSubscribe`, `hmrEvents`, `writeToDisk`)
→ `crates/next-napi-bindings` → `crates/next-api` `Project`/`Endpoint`/`Route`. Reactive subscriptions
use a `RootTask` whose body re‑runs on invalidation and pushes results to a JS `ThreadsafeFunction` —
that's how `hmrEvents` streams `Update`s up to the dev server, which forwards them over the WebSocket.

### 4.8 Turbopack architecture diagram

```
 JS:  next dev/build → build/swc/index.ts (createProject, hmrEvents, writeToDisk)
                                  │ N-API
 Rust bindings:  crates/next-napi-bindings (subscribe + RootTask + ThreadsafeFunction)
                                  │
 Next layer:  crates/next-api (Project/Endpoint/Route)   crates/next-core (AppRSC/AppSSR contexts,
              react-server condition, EcmascriptClientReferenceModule, __RSC_MANIFEST emit,
              RSDW→RSDT alias)   crates/next-custom-transforms ('use client'/'use server')
 ═══════════════════════════════════════════════════════════════════════════════════════════
 turbo-tasks (incremental engine): #[turbo_tasks::function] memoized tasks, Vc<T> cells,
     await ⇒ dependency edge, cell change ⇒ invalidate dependents, bottom-up, turbo-persistence
                                  │  (every step below is a task)
 MODULE GRAPH:  Source ─AssetContext.process()→ Module ─references()→ Module …  (SWC parse/analyze)
                                  │
 CHUNKING:  follow refs by ChunkingType → ChunkItem → split by ChunkType → Chunk → OutputAsset
                     │                                          │
                     ▼ build                                    ▼ dev
            OutputAssets → .next/                       turbopack-dev-server:
                                                          compute_update_stream (re-runs on
                                                          invalidation) → Version diff → Update
                                                          UpdateServer (WebSocket, hmr-protocol)
                                                              │
                                                          Browser hmr-client/runtime (module.hot,
                                                          React Fast Refresh; else reload)
```

---

## 5. Build / production & the three module "layers"

🧒 **ELI5:** to make Server Components work, Next builds your code **three times wearing three
different pairs of glasses**: once as the **RSC server** (sees server components for real, sees client
components as labels), once as the **SSR** layer (runs client components on the server to make the
photo), once as the **browser** layer (the real interactive client code). A "join table" (the
client‑reference manifest) reconnects the label on the server side to the real chunk on the browser
side.

🛠️ The layers (`packages/next/src/lib/constants.ts` → `WEBPACK_LAYERS`):

| Layer                     | String              | Role                                         | `react-server` condition? |
| ------------------------- | ------------------- | -------------------------------------------- | ------------------------- |
| `reactServerComponents`   | `rsc`               | Server Components (+ `'use server'` modules) | **yes**                   |
| `serverSideRendering`     | `ssr`               | run Client Components on the server → HTML   | no                        |
| `appPagesBrowser`         | `app-pages-browser` | real client code shipped to the browser      | no                        |
| `actionBrowser`           | `action-browser`    | actions imported from client components      | no                        |
| `middleware`/`instrument` | …                   | server‑only edge code                        | yes                       |

The **webpack path** realizes RSC with JS plugins (the legible map of the machinery):

- `FlightClientEntryPlugin` — walks the RSC graph, finds `'use client'` boundaries, injects them as
  **real** entries into the SSR + browser graphs, and creates server‑action entries.
- `ClientReferenceManifestPlugin` — emits per‑page `…_client-reference-manifest.js`
  (`globalThis.__RSC_MANIFEST[...]`) mapping client module → `{ id, chunks }` + reverse ssr/rsc maps.
- `next-flight-loader` — in the server graph, replaces a `'use client'` module with
  `registerClientReference(...)` stubs (or a `createProxy` for CJS) so the real client code never
  enters the server graph.

🧒 The payoff: a `'use client'` file is a **thin reference** in the server (rsc) graph and a **real
module** in the ssr + browser graphs; the client‑reference‑manifest is the join table. `'use server'`
actions are tracked symmetrically by the **server‑reference‑manifest**. The `react-server` export
condition is what physically forks **React itself** between the server‑components graph and the
ssr/client graphs (it picks `react.react-server.js`).

🛠️ **Turbopack reimplements all of this in Rust** (`crates/next-core` + `crates/next-api`) and emits
**byte‑compatible manifests**, so `server/app-render/` consumes either bundler's output unchanged.
Build branches in `packages/next/src/build/index.ts` (`Bundler.Turbopack` → `turbopackBuild`; else
the webpack/rspack path).

### Build pipeline diagram

```
SOURCE (app/: page.tsx, layout.tsx, 'use client', 'use server')
   │  SWC: inject markers __next_internal_client_entry__ / __next_internal_action_entry__
   ├──────────────── SERVER/EDGE compiler (rsc, ssr-record, action layers) ─── run first ──┐
   │  conditionNames: ['react-server', …]                                                  │
   │  next-flight-loader: 'use client' ⇒ registerClientReference/createProxy (stub)        │
   │  FlightClientEntryPlugin: find boundaries → inject client entries → record ids ───────┼─┐
   │  → server-reference-manifest (actions)                                                │ │
   └────────────────────────────────────────────────────────────────────────────────────-┘ │
   ┌──────────────── CLIENT compiler (app-pages-browser, action-browser) ── run second ─────┘
   │  real 'use client' modules → browser chunks
   │  ClientReferenceManifestPlugin → server/app/<route>/page_client-reference-manifest.js (__RSC_MANIFEST)
   └────────────────────────────────────────────────────────────────────────────────────────
   MANIFESTS → runtime: app-render.tsx getClientReferenceManifest() feeds Flight server (clientModules),
   SSR (ssrModuleMapping), action-handler (serverModuleMap). Turbopack emits identical manifests in Rust.
```

---

## 6. Quick file index (next.js repo)

**Server render**

- `packages/next/src/server/route-modules/app-page/module.ts` — `AppPageRouteModule.render`
- `packages/next/src/server/app-render/app-render.tsx` — `renderToHTMLOrFlight`, `renderToStream`, `getRSCPayload`, `prerenderToStream`, `App`
- `packages/next/src/server/app-render/use-flight-response.tsx` — `getFlightStream`, `createInlinedDataReadableStream` (`__next_f`)
- `packages/next/src/server/app-render/stream-ops.node.ts` — `renderToNodeFlightStream`, `renderToNodeFizzStream`, `continueFizzStream`
- `packages/next/src/server/load-components.ts` + `…/manifests-singleton.ts` — manifest loading
- `packages/next/src/shared/lib/app-router-types.ts` — `InitialRSCPayload`, `FlightRouterState`, `CacheNodeSeedData`

**Client runtime**

- `packages/next/src/client/app-{next,bootstrap,index}.tsx` — hydration bootstrap
- `packages/next/src/client/components/app-router.tsx`, `router-reducer/*`, `app-router-instance.ts`
- `packages/next/src/client/components/segment-cache/{navigation,cache,scheduler,prefetch}.ts`
- `packages/next/src/client/components/router-reducer/fetch-server-response.ts`
- `packages/next/src/client/components/app-router-headers.ts` — `RSC`, `Next-Router-State-Tree`, `Next-Action`, …
- `packages/next/src/client/app-call-server.ts`, `…/reducers/server-action-reducer.ts`

**Turbopack / build**

- `turbopack/crates/turbo-tasks/README.md`, `src/vc/README.md`
- `turbopack/crates/turbopack-core/{layers.md,chunking.md}`, `turbopack-dev-server/src/update/{stream,server}.rs`
- `crates/next-core/src/next_server/context.rs`, `…/next_client_reference/…`, `…/next_manifests/client_reference_manifest.rs`
- `crates/next-custom-transforms/src/transforms/{react_server_components,server_actions}.rs`
- `packages/next/src/build/index.ts`, `…/build/webpack/plugins/{flight-client-entry-plugin,flight-manifest-plugin}.ts`
- `packages/next/src/lib/constants.ts` — `WEBPACK_LAYERS`

**Next:** `05-compare-and-contrast.md` puts React on Rails Pro and Next.js side by side.

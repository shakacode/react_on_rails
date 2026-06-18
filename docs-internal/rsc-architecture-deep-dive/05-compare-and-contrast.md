# 05 — React on Rails Pro vs Next.js: Compare & Contrast

> The synthesis. 🧒 ELI5 first, then the tables and trade‑offs. This assumes docs 01–04.

---

## 1. 🧒 ELI5: Two restaurants serving the same dish

Both React on Rails Pro and Next.js serve the **same meal** — React Server Components — and they use
the **same recipe book** (React's Flight protocol). The difference is the _building_:

- **Next.js** is a **purpose‑built RSC restaurant.** The kitchen, the menu, the waiters, and the
  lunchbox machine were all designed together, in one language, to serve this exact meal as fast as
  possible. You move in and everything's wired up — but it's _their_ building, _their_ rules.
- **React on Rails Pro** is a **React cooking station you add to your existing Rails restaurant.**
  Your Rails building already has its own kitchen, menu, and staff (your app, your routes, your auth,
  your database). React on Rails Pro bolts a world‑class React/RSC station onto it, reusing a
  general‑purpose lunchbox machine (webpack/rspack). You keep your building and your rules.

Neither is "better" — they're answers to different questions. _"I'm building a React app and want a
backend"_ points at Next.js. _"I have a Rails app and want great React/RSC in it"_ points at React on
Rails Pro.

---

## 2. The Rosetta Stone (terminology map)

Same concepts, different names. Keep this handy when reading either codebase.

| Concept                                 | React on Rails Pro                                                                 | Next.js (App Router)                                                     |
| --------------------------------------- | ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| What renders the page                   | a Rails controller calling `stream_react_component`                                | file‑system route (`page.tsx`/`layout.tsx`) → **loader tree**            |
| RSC payload (the "order ticket")        | "RSC payload" / Flight                                                             | "Flight" / RSC payload                                                   |
| Inlined‑payload global                  | `window.REACT_ON_RAILS_RSC_PAYLOADS[key]`                                          | `self.__next_f`                                                          |
| Inliner                                 | `injectRSCPayload.ts` (4 ordered buffers)                                          | `createInlinedDataReadableStream` + `continueFizzStream`                 |
| Wire framing                            | length‑prefixed `metadata\thexlen\ncontent` NDJSON                                 | tuple pushes `push([0 \| 1 \| 2 \| 3, …])`                               |
| Make payload (server)                   | `serverRenderRSCReactComponent` → `buildServerRenderer`                            | `renderToNodeFlightStream` → `react-server-dom-*/server`                 |
| Payload → HTML (SSR)                    | server bundle `createFromNodeStream`                                               | `App` → `getFlightStream` → `createFromNodeStream`                       |
| Hydrate from inlined payload            | `createFromPreloadedPayloads` → `createFromReadableStream`                         | drain `__next_f` → `createFromReadableStream`                            |
| Refetch on navigation                   | `fetchRSC` → `GET /rsc_payload/:name?props=`                                       | `fetchServerResponse` → `GET ?_rsc` + `Next-Router-State-Tree`           |
| Client‑reference manifest               | `react-client-manifest.json`                                                       | `…_client-reference-manifest.js` (`globalThis.__RSC_MANIFEST`)           |
| SSR consumer manifest                   | `react-server-client-manifest.json`                                                | `ssrModuleMapping` (in `__RSC_MANIFEST`)                                 |
| The RSC bundle/graph                    | `rsc-bundle.js` (3rd webpack config)                                               | the `rsc` **layer** (`WEBPACK_LAYERS.reactServerComponents`)             |
| `react-server` condition                | `conditionNames: ['react-server','...']` in `rscWebpackConfig.js`                  | `should_use_react_server_condition()` / per‑layer in `webpack-config.ts` |
| Strip `'use client'` in server graph    | `react-on-rails-rsc/WebpackLoader`                                                 | `next-flight-loader` / Rust `EcmascriptClientReferenceModule`            |
| Discover `'use client'` + emit manifest | `react-on-rails-rsc/WebpackPlugin`                                                 | `FlightClientEntryPlugin` + `ClientReferenceManifestPlugin` (or Rust)    |
| SSR/RSC execution host                  | the **node‑renderer** (Fastify worker pool)                                        | the Next server process (Node or Edge runtime)                           |
| RSC runtime package                     | `react-on-rails-rsc` (vendors `react-server-dom-webpack`; +`-rspack` since 19.0.5) | `react-server-dom-webpack` (webpack/rspack) or `-turbopack`              |
| Incremental dev rebuild                 | webpack/rspack HMR + `--watch` to disk                                             | Turbopack turbo‑tasks invalidation + Node‑side HMR                       |

---

## 3. Side‑by‑side request flow

```
                REACT ON RAILS PRO                          NEXT.JS (App Router)
   ────────────────────────────────────────   ────────────────────────────────────────────
   Browser GET /page                            Browser GET /dashboard
        │                                             │
   Rails controller                              AppPageRouteModule.render
   stream_view_containing_react_components       renderToHTMLOrFlight → renderToStream
        │                                             │
   helper stream_react_component                 loaderTree (from folders)
        │                                             │
   ── PASS 1: RSC bundle ──                       ── PASS 1: rsc layer ──
   serverRenderRSCReactComponent                 getRSCPayload → renderToNodeFlightStream
   react-server-dom-webpack renderToPipeableStream  react-server-dom-(webpack|turbopack)
        │  Flight payload                             │  Flight payload
   ── PASS 2: server bundle ──                    ── PASS 2: ssr layer ──
   streamServerRenderedReactComponent            <App> use(getFlightStream)→createFromNodeStream
   createFromNodeStream → react-dom/server HTML  → react-dom/server HTML
        │                                             │
   injectRSCPayload (4 buffers, ordered)         createInlinedDataReadableStream + continueFizzStream
   REACT_ON_RAILS_RSC_PAYLOADS[key].push(...)    self.__next_f.push([1,"..."])
        │                                             │
   response.stream (via Async fibers, stream.rb) HTML document stream
        ▼                                             ▼
   Browser: createFromPreloadedPayloads →         Browser: drain __next_f →
            createFromReadableStream → hydrateRoot          createFromReadableStream → hydrateRoot
        │                                             │
   Navigation: fetchRSC → /rsc_payload/:name      Navigation: fetchServerResponse → ?_rsc
                                                   (+ segment-level diff, + prefetch, + server actions)
```

**The shapes are nearly identical.** Both do RSC‑render → SSR‑render → inline‑and‑stream → hydrate →
refetch‑on‑nav. The differences are at the **edges**: who owns routing, how granular the nav diff is,
what extra features exist, and what bundles the code.

---

## 4. The one difference that explains all the others: **where RSC lives**

```
   REACT ON RAILS PRO                              NEXT.JS
   ──────────────────                              ───────
   RSC is BOLTED ONTO a general-purpose            RSC is BUILT INTO the bundler + framework
   bundler via JS plugins/loaders:                 in Rust:
     • react-on-rails-rsc/WebpackPlugin              • crates/next-core: EcmascriptClientReferenceModule
     • react-on-rails-rsc/WebpackLoader              • crates/next-core: react-server condition (native)
     • react-server-dom-webpack runtime              • crates/next-core: __RSC_MANIFEST emit (native)
     • a 3rd webpack config (rscWebpackConfig.js)    • crates/next-custom-transforms: 'use client'/'use server'
                                                     • RSDW → RSDT runtime alias
   Bundler-agnostic by NECESSITY (webpack &         Bundler-native; Turbopack is the default;
   rspack both supported, same JS plugins).         webpack/rspack also supported in Next.
```

Everything downstream follows from this:

- Next can offer **PPR**, **segment‑level prefetch**, and **server actions** because the framework
  owns routing + the bundler + the runtime together.
- React on Rails Pro can drop into **any Rails app** and reuse your existing routing, controllers,
  auth, and the rest of the Rails ecosystem, because it _doesn't_ own those — it only owns the React
  station.

The trade is **integration depth vs. host flexibility.** Next's tight integration buys features and
speed; RoR's loose coupling buys "it's your Rails app, RSC is just a capability you added."

---

## 5. Bundlers head‑to‑head (the part you specifically asked about)

|                                      | **webpack**                                        | **Rspack**                                                                                                                                          | **Turbopack**                                                                                 |
| ------------------------------------ | -------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| Language                             | JavaScript/Node                                    | Rust (SWC inside)                                                                                                                                   | Rust, on **turbo‑tasks** (SWC inside)                                                         |
| webpack‑API compatible               | yes (the reference)                                | **yes** — near drop‑in (same loaders/plugins)                                                                                                       | **no** — own config (`turbopack.rules`), loaders only via a Node IPC shim                     |
| Incremental granularity              | module‑level (recompile affected modules, re‑seal) | same model, Rust‑fast                                                                                                                               | **function/task‑level** memoization (`Vc` cells), bottom‑up invalidation, cross‑session cache |
| Plugin model                         | tapable hooks (JS)                                 | tapable + native Rust plugins                                                                                                                       | Rust crates / transitions; **webpack plugins don't port**                                     |
| RSC integration                      | JS plugin/loader + `react-server-dom-webpack`      | reuse the Webpack plugin/loader + `react-server-dom-webpack`, **or** native `RspackPlugin`/`RspackLoader` + `react-server-dom-rspack` (RoR, 19.0.5) | **native Rust** + `react-server-dom-turbopack`                                                |
| Used by React on Rails (Shakapacker) | ✅                                                 | ✅ (preferred for speed; SWC)                                                                                                                       | ❌ (Turbopack is Next‑internal)                                                               |
| Used by Next.js                      | `--webpack` (legacy/fallback)                      | `next-rspack` (experimental)                                                                                                                        | default (`--turbopack`)                                                                       |

🔑 **Two findings that matter most for you:**

1. **Rspack is "webpack in Rust."** In Next's own repo, enabling Rspack literally **swaps `@rspack/core`
   in where webpack is required and runs the _same_ webpack config + plugin tree** (`get-webpack-bundler.ts`,
   gated on `NEXT_RSPACK`). Shakapacker treats it the same way at the config layer — same
   `rscWebpackConfig.js` and the same `react-on-rails-rsc/WebpackLoader` under both bundlers — but the
   Pro dummy now **selects the native `RSCRspackPlugin` (from `react-on-rails-rsc/RspackPlugin`) when
   `assets_bundler === 'rspack'`** instead of the webpack `RSCWebpackPlugin` (see doc 03 §6.5). So the
   _loader_ is shared; the _manifest plugin_ is bundler‑specific.

2. **Rspack can reuse `react-server-dom-webpack`** — and there's no `-rspack` build in **React's
   monorepo** or **Next.js**. Because Rspack is webpack‑API‑compatible, RSC under Rspack can reuse
   **`react-server-dom-webpack`** (webpack‑shaped chunk loading via
   `__webpack_require__`/`__webpack_chunk_load__`). **Next.js independently proves this path is sound:**
   Next runs RSC under Rspack on `react-server-dom-webpack` too. _Caveat (updated):_ React on Rails
   has gone a step further — `react-on-rails-rsc@19.0.5` now **also** ships a native
   `RspackPlugin`/`RspackLoader` backed by its own vendored `react-server-dom-rspack` build (the GA
   direction). So a `react-server-dom-rspack` does exist — in `react-on-rails-rsc`, not upstream.
   Turbopack still needs `react-server-dom-turbopack` because it isn't webpack‑compatible (different
   chunk‑loading primitives — see doc 03 §1 and below).

### Why a different bundler needs a different RSC runtime (the crux)

The Flight **algorithm** is identical everywhere (it lives once in React's private `react-server` /
`react-client`). Only the **"go load chunk #47 at runtime"** primitive differs per bundler:

| Bundler          | runtime require             | chunk load                            | chunk metadata shape                                |
| ---------------- | --------------------------- | ------------------------------------- | --------------------------------------------------- |
| webpack / rspack | `__webpack_require__(id)`   | `__webpack_chunk_load__(chunkId)`     | double‑indexed `[id, [chunkId, filename, …], name]` |
| Turbopack        | `__turbopack_require__(id)` | `__turbopack_load_by_url__(filename)` | flat `[id, [filename,…], name]`                     |
| Parcel           | `parcelRequire(id)`         | `parcelRequire.load(url)`             | refs resolved at build time                         |

That's the _entire_ reason there's a `react-server-dom-<bundler>` family. webpack and rspack share one
because they share the `__webpack_*` primitives. (Detail: see the React monorepo's
`ReactFlightClientConfigBundler*.js` files.)

---

## 6. Feature scorecard

| Capability                                       | React on Rails Pro                   | Next.js                                        |
| ------------------------------------------------ | ------------------------------------ | ---------------------------------------------- |
| Server Components + Flight streaming             | ✅                                   | ✅                                             |
| SSR + hydration of RSC                           | ✅                                   | ✅                                             |
| Inlined payload (no double fetch on load)        | ✅ (`injectRSCPayload`)              | ✅ (`__next_f`)                                |
| Refetch RSC on client navigation                 | ✅ (`fetchRSC`)                      | ✅ (`fetchServerResponse`)                     |
| **Segment‑level** nav diffing                    | partial (component‑level)            | ✅ (FlightRouterState segment diff)            |
| **Prefetching** (viewport/hover)                 | ❌ (not built‑in)                    | ✅ (IntersectionObserver + scheduler)          |
| **Server Actions** (RPC + re‑render in one trip) | ❌ (use Rails endpoints)             | ✅ (`Next-Action`)                             |
| **PPR** (static shell + streamed holes)          | ❌ (async props is the nearest)      | ✅ (`react-dom/static` + postpone)             |
| Async props / incremental streaming              | ✅ (`handleIncrementalRenderStream`) | partial (PPR/Suspense covers a different need) |
| Edge runtime target                              | n/a (Rails/Node)                     | ✅ (node + edge)                               |
| Use your existing Rails app/routes/auth/DB       | ✅ (the whole point)                 | ❌ (Next owns the server)                      |
| Bundler choice                                   | webpack **or** rspack (Shakapacker)  | turbopack / webpack / rspack                   |
| Default dev bundler speed                        | webpack (slow) or rspack (fast, SWC) | Turbopack (fastest, turbo‑tasks)               |
| Separate SSR process to manage                   | ✅ (node‑renderer + worker pool)     | ❌ (one server process)                        |

🧒 The pattern: **Next has more RSC‑era features out of the box** (prefetch, server actions, PPR,
segment diffing, Turbopack) because it owns the whole stack. **React on Rails Pro gives you RSC inside
a real Rails app** with all of Rails' strengths, at the cost of building/managing a couple more moving
parts (the node‑renderer, the third bundle) and not (yet) having every Next convenience.

---

## 7. Dev/prod build models compared

|                          | React on Rails Pro (doc 02)                                                       | Next.js (doc 04)                                           |
| ------------------------ | --------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| Dev process model        | 5 processes (rails, dev‑server, server‑watch, rsc‑watch, node‑renderer)           | 1 (`next dev` drives Turbopack via N‑API)                  |
| Client HMR               | webpack/rspack dev‑server + React Refresh                                         | Turbopack HMR + React Fast Refresh                         |
| Server/RSC reload in dev | `--watch` rebuild to disk; node‑renderer reloads bundle                           | Node‑side HMR (server bundles hot‑update too)              |
| Incrementality           | module‑level (webpack/rspack)                                                     | task‑level (turbo‑tasks), cross‑session cache              |
| Prod build               | `rake assets:precompile` → 3 webpack configs + manifests + node‑renderer pre‑seed | `next build` → 3 layers + manifests (Turbopack or webpack) |
| Output hashing           | client hashed; server/RSC single unhashed chunks                                  | `.next/` chunks hashed; per‑page manifests                 |

The dev ergonomics gap is real: Next is one command; React on Rails Pro orchestrates several
processes (managed by `bin/dev`/Procfiles). That's the price of bolting onto Rails rather than owning
the server.

---

## 8. Strategic takeaways for React on Rails

1. **The architecture is validated by Next.** Your RSC flow (RSC‑render → SSR → inline → hydrate →
   refetch) is structurally the same as Next's, down to the inlined global array. You're not doing
   anything exotic; you're implementing the same React contract with Rails as the host.

2. **The Shakapacker dual‑bundler RSC bet is sound.** Next.js itself runs RSC under both webpack and
   rspack with the single `react-server-dom-webpack` runtime and **no `-rspack` package** in its tree
   — validating the "rspack reuses the webpack runtime" path. React on Rails has now gone further: the
   native Rspack path (`RspackPlugin`/`RspackLoader` + vendored `react-server-dom-rspack`) **ships** in
   `react-on-rails-rsc@19.0.5` as the GA direction, while the webpack‑compatible path keeps
   working as a fallback.

3. **Turbopack is not a competitor you can adopt** — it's welded to Next's framework (the
   `crates/next-core`/`next-api` layer _is_ the RSC implementation). The transferable idea is
   **turbo‑tasks‑style function‑level incrementality**; the transferable _reality_ for RoR is \*\*rspack

   - SWC\*\*, which gets most of the speed without leaving the webpack‑compatible world Shakapacker
     depends on.

4. **The biggest feature gaps to consider** (if you want to close them): built‑in **prefetching**,
   **server actions**, and **PPR**. Each is enabled by Next owning routing + bundler together; in RoR
   they'd need design that respects Rails owning the router. Async props (doc 01 §6) is your existing
   lever in this space.

5. **The separate `react-on-rails-rsc` npm package is unavoidable and correct.** It exists for the
   same reason Next vendors `react-server-dom-turbopack` and React keeps `react-server`/`react-client`
   private: the Flight runtime is **version‑welded to React's private internals** and must be a
   pinned, vendored, per‑bundler build. Managing it as its own package on React's cadence is the right
   call (doc 03).

---

## 9. One‑paragraph executive summary

React on Rails Pro and Next.js implement the **same React Server Components contract** with the **same
runtime family** (`react-server-dom-*`) and the **same end‑to‑end shape**: render Server Components to
a Flight payload, SSR that payload to HTML, inline the payload into the HTML (`REACT_ON_RAILS_RSC_PAYLOADS`
≈ `__next_f`), hydrate from it without a re‑fetch, then refetch just‑the‑changes on navigation. The
decisive difference is **ownership**: Next.js builds RSC **into** a Rust bundler (Turbopack) and a
framework it fully controls, which buys it Turbopack's task‑level incrementality plus prefetching,
server actions, and PPR; React on Rails Pro **bolts** RSC onto a general‑purpose bundler
(webpack/rspack via Shakapacker) using JS plugins/loaders and the vendored `react-on-rails-rsc`
runtime, which buys it the ability to add world‑class RSC to **any real Rails app** without giving up
Rails. Bundler‑wise, **rspack is "webpack in Rust"** and can run RSC on the **webpack** runtime (proven by
Next running RSC under rspack on `react-server-dom-webpack`); React on Rails additionally ships a
native rspack path (`react-server-dom-rspack`) since `react-on-rails-rsc@19.0.5`. **Turbopack**
is the one bundler that _requires_ a distinct runtime (`react-server-dom-turbopack`), purely because
its runtime chunk‑loading primitives differ from webpack's.

# 01 — The Complete RSC Request Flow in React on Rails Pro

> **Audience note.** Each section starts with a 🧒 **ELI5** box (explain‑it‑like‑I'm‑5/7/10),
> then a 🛠️ **The real thing** section with exact file paths, function names, and the wire
> format. Read the ELI5 boxes top‑to‑bottom for the story; dive into the real‑thing sections
> when you want the receipts.

---

## 0. The one‑paragraph mental model (for someone who already knows SSR + hydration)

You already understand the classic React on Rails loop: Rails renders a view, `react_component`
emits a `<div>` plus a JSON props blob, the **server bundle** runs in Node (the Pro node‑renderer)
to produce SSR HTML, the browser paints that HTML, then the **client bundle** calls `hydrateRoot`
to attach event handlers. **RSC inserts a third rendering pass _before_ SSR.** A new **RSC bundle**
(built with React's `react-server` package condition) renders your Server Components into a
**serialized React tree** — not HTML, not JS source — called the **RSC payload** (a.k.a. the
"Flight" stream). That payload is then (a) turned into HTML by the SSR pass so the first paint is
instant, and (b) **inlined into the HTML as data** so the client can rebuild the exact same React
tree and hydrate without re‑fetching. Client Components inside the tree are not serialized; they
appear as **references** ("module #47, props {…}") that the client bundle resolves from its own
chunks. That's the whole trick: **the server streams a description of the UI, with holes where the
interactive parts go.**

---

## 1. 🧒 ELI5: What problem are Server Components even solving?

Imagine you order food at a restaurant.

- **The kitchen = the server.** It can touch the secret ingredients (the database, secret files,
  API keys). You at the table can never see those.
- **A Server Component is a dish the kitchen finishes completely.** It comes out plated. You can't
  change how it was cooked — but it was cooked using secret ingredients you'll never have to ship to
  your table. (Translation: Server Components run **only** on the server, can read the DB directly,
  and **their code is never sent to the browser** — so your JavaScript bundle gets smaller.)
- **A Client Component is a build‑your‑own‑taco kit at your table.** It's interactive — you press
  buttons, it has state, it wiggles. (Translation: Client Components are the normal React you know —
  `useState`, `onClick`, etc. They run in the browser.)

The clever part is **how the kitchen tells your table what's on the plate.** It does _not_ send you
the recipe (the source code). It sends an **order ticket** that says:

> "Table 5 gets: a finished bowl of soup (here's exactly what it looks like) **and** a taco kit —
> you already have the taco kit at your seat (kit #47), just fill it with these toppings."

That order ticket is the **RSC payload**. The "you already have kit #47" part is the magic: the
interactive pieces aren't re‑described, they're **referenced**, because the browser already
downloaded those pieces in the client bundle.

🛠️ **The real thing.** The "order ticket" is React's **Flight** wire format produced by
`react-server-dom-webpack`'s `renderToReadableStream`/`renderToPipeableStream`. Server Components are
serialized as a tree of plain data; Client Components are serialized as **client references**
(`{ id, chunks, name }`) that point into the client manifest. See
`packages/react-on-rails-pro/src/ReactOnRailsRSC.ts` and the vendored runtime in
`react-on-rails-rsc/server.node`.

---

## 2. The three bundles (this is the thing to internalize first)

Classic React on Rails has **two** JavaScript builds. RSC adds a **third**. Everything else follows
from this.

```
                            ┌──────────────────────────────────────────────┐
                            │  Your app's React components (.tsx / .jsx)     │
                            └──────────────────────────────────────────────┘
                                   │              │              │
            built with             │              │              │
            react-server  ┌────────▼─────┐ ┌──────▼───────┐ ┌────▼─────────┐
            condition  →  │  RSC BUNDLE  │ │ SERVER BUNDLE │ │ CLIENT BUNDLE │
                          │ rsc-bundle.js│ │server-bundle.js│ │client-xxxx.js │
                          └──────┬───────┘ └──────┬────────┘ └────┬──────────┘
   runs where:            Node (node-renderer)  Node (node-renderer)  Browser
   what it makes:         RSC payload (Flight)  HTML (from payload)   hydration + interactivity
   sees 'use client' as:  a *reference* stub    real client comp      real client comp
   sees Server Comp as:   real (runs it)        (gets it via payload) (gets it via payload)
   sends source to client? NO                   NO                    YES (only client comps)
```

| Bundle                                 | Built with                                                                         | Runs in       | Produces                        | Key trait                                                                                                                                       |
| -------------------------------------- | ---------------------------------------------------------------------------------- | ------------- | ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| **RSC bundle** (`rsc-bundle.js`)       | `conditionNames: ['react-server', '...']` + the `react-on-rails-rsc/WebpackLoader` | node‑renderer | **RSC payload** (Flight stream) | This is the _only_ bundle that actually executes your Server Components. `'use client'` files are stripped out and replaced by reference stubs. |
| **Server bundle** (`server-bundle.js`) | normal Node target                                                                 | node‑renderer | **HTML**                        | Consumes the RSC payload and runs the SSR pass (`react-dom/server`) to turn it into HTML. Also where non‑RSC `react_component` SSR happens.     |
| **Client bundle** (`client-[hash].js`) | normal web target                                                                  | browser       | **interactivity**               | Hydrates the HTML. Resolves client references from the RSC payload using the **client manifest**.                                               |

🛠️ **The real thing.** Bundle selection lives in
`react_on_rails_pro/spec/dummy/config/webpack/ServerClientOrBoth.js`. The RSC‑specific config is
`config/webpack/rscWebpackConfig.js` (sets `conditionNames: ['react-server', '...']`, aliases
`react` → `react.react-server.js`, adds `react-on-rails-rsc/WebpackLoader`, filters out
`react-dom/server`). Covered in depth in **`02-shakapacker-dev-and-prod-builds.md`** and
**`03-rsc-npm-package-react19-webpack-vs-rspack.md`**.

---

## 3. 🧒 ELI5: What actually happens when you load the page?

1. You knock on the restaurant door (your browser asks Rails for `/some-page`).
2. Rails tells the kitchen: "Cook component `MyPage`." The **RSC kitchen** cooks it into an order
   ticket (the RSC payload).
3. Because nobody likes staring at an empty plate, the kitchen also snaps a **photo of the finished
   plate** (SSR turns the payload into HTML) and sends the photo out **first** so you see your food
   immediately.
4. Stapled to the photo is the **order ticket itself** (the RSC payload, inlined as data in the
   HTML). The browser keeps it.
5. Your browser reads the order ticket, rebuilds the _real_ interactive plate from your at‑table
   kits (client components), and the waiter connects all the buttons (**hydration**).
6. Later, when you press a button that needs a fresh dish, your table calls the kitchen for **just a
   new order ticket** (a fetch that returns a new RSC payload) — no full page reload, no new photo
   needed.

The performance wins, in kid terms: you see food **fast** (step 3 streams as it cooks), you don't
re‑download things you already have (step 4 reuses the inlined ticket), and updates are **tiny**
(step 6 fetches a description, not a whole page).

---

## 4. 🛠️ The complete flow, with real names

### Stage A — Rails receives the request

A controller streams a view that contains React components.

```
Browser ──GET /page──▶ Rails Controller
                          │
                          ▼
   stream_view_containing_react_components(template: 'pages/my_page')
```

- `react_on_rails_pro/lib/react_on_rails_pro/concerns/stream.rb` →
  **`stream_view_containing_react_components(template:, close_stream_at_end:, content_type:, **opts)`**.
It opens an async fiber (`Sync { }`), sets up an `Async::Barrier`and an`Async::LimitedQueue`
(`@main_output_queue`), renders the template, captures the first HTML chunk, then
**`drain_streams_concurrently`** runs a producer/consumer loop: each React component streams chunks
into the queue; one writer task dequeues and writes to `response.stream`.

### Stage B — The view helper kicks off rendering

Inside the template, you call a helper:

```erb
<%= stream_react_component("MyPage", props: { id: 42 }) %>
```

- `react_on_rails_pro/app/helpers/react_on_rails_pro_helper.rb` →
  **`stream_react_component`** (HTML + inlined RSC payloads, Suspense‑aware) or
  **`rsc_payload_react_component`** (pure payload, NDJSON, no HTML).
- `stream_react_component` → `internal_stream_react_component` sets `render_mode: :html_streaming`
  and calls `internal_react_component` → **`server_rendered_react_component(render_options)`** in the
  base gem (`react_on_rails/lib/react_on_rails/helper.rb`).

### Stage C — Build the JS, send it to the node‑renderer

- `react_on_rails/lib/react_on_rails/helper.rb` → **`server_rendered_react_component`**:
  1. builds JS via `ServerRenderingJsCode.server_rendering_component_js_code`,
  2. executes it via `ServerRenderingPool.server_render_js_with_console_logging`,
  3. if `render_options.streaming?`, returns a transformable stream.
- `react_on_rails_pro/lib/react_on_rails_pro/server_rendering_js_code.rb`:
  - **`render(...)`** picks the JS entrypoint: `'streamServerRenderedReactComponent'` (server bundle,
    HTML + RSC streaming) vs `'serverRenderRSCReactComponent'` (RSC bundle, payload only).
  - **`generate_rsc_payload_js_function(render_options)`** defines
    `generateRSCPayload(componentName, props, railsContext)`, which calls
    **`runOnOtherBundle(rscBundleHash, newRenderingRequest)`** — i.e. "hop over to the RSC bundle to
    cook the payload."
- `react_on_rails_pro/lib/react_on_rails_pro/server_rendering_pool/node_rendering_pool.rb`:
  **`eval_streaming_js`** calls either `ReactOnRailsPro::Request.render_code_as_stream(...)` or
  `...render_code_with_incremental_updates(...)` (the latter for **async props**, see §6).

### Stage D — The node‑renderer executes JS in a VM and streams back

- `packages/react-on-rails-pro-node-renderer/src/worker/handleRenderRequest.ts` →
  **`prepareResult`** calls `executionContext.runInVM(renderingRequest, bundleFilePath, cluster)`.
  If the result is a readable stream, it returns `{ status: 200, stream }`; otherwise
  `{ status: 200, data }`.
- The VM runs `ReactOnRails.streamServerRenderedReactComponent(...)` from the **server bundle**.
  React 18.3+ `renderToPipeableStream(<MyPage/>)` runs the SSR pass. When it hits a Server Component
  boundary (`<RSCRoute>`), it calls `generateRSCPayload()` → `runOnOtherBundle(rscBundleHash, …)` →
  the **RSC bundle** runs `serverRenderRSCReactComponent(...)` →
  `react-server-dom-webpack`'s `renderToReadableStream(<ServerComponent/>)` → **Flight payload**.

```
   server-bundle VM                         rsc-bundle VM
   ────────────────                         ─────────────
   renderToPipeableStream(<MyPage/>)
        │ hits <RSCRoute>
        │ generateRSCPayload(name, props) ─runOnOtherBundle──▶ serverRenderRSCReactComponent()
        │                                                          │
        │                                          renderToReadableStream(<ServerComp/>)
        │  ◀──────────── Flight payload stream ─────────────────────┘
        ▼
   HTML chunks  +  inlined Flight payload  ──▶ back to Rails ──▶ response.stream ──▶ Browser
```

### Stage E — Interleaving HTML and payload on the wire

This is the cleverest piece of the Pro implementation, in
`packages/react-on-rails-pro/src/injectRSCPayload.ts`.

**Wire format (length‑prefixed):**

```
<metadata JSON>\t<hex content length, zero‑padded to 8 digits>\n<raw content bytes>
```

The content (HTML, or a Flight chunk) is **not** part of the metadata JSON — it rides as
the raw bytes after the `\n`, length‑prefixed so it never needs escaping. This is the whole
point of the framing: keeping the bulk of the payload out of `JSON.stringify` avoids ~30%
escaping overhead (`packages/react-on-rails-pro/src/streamingUtils.ts`). The metadata is a
small JSON object built by `buildRenderMetadata` (in `react-on-rails/serverRenderUtils`),
e.g.
`{"consoleReplayScript":"…","clientProps":{…},"hasErrors":false,"renderingError":null,"isShellReady":true,"payloadType":"string"}`
(`payloadType` is appended in `streamingUtils.ts`). Note there is **no `html` field**.

`injectRSCPayload` maintains **four ordered buffers** and flushes them in a strict order so the
browser never tries to use a payload that hasn't arrived:

```
   1) rscInitializationBuffers   →  <script>(self.REACT_ON_RAILS_RSC_PAYLOADS||={})[key]||=[]</script>
   2) rscClientStylesheetBuffers →  <link rel="stylesheet" href="…" data-precedence="rsc-css">
   3) htmlBuffers                →  <div id="MyPage-react-component-0">…SSR HTML…</div>
   4) rscPayloadBuffers          →  <script>(self.REACT_ON_RAILS_RSC_PAYLOADS[key]).push("<flight chunk>")</script>
```

- Flush is driven by React calling `destination.flush()` at the end of each render cycle (React 18.3+
  convention), with a `setTimeout(flush, 0)` fallback if it never fires.
- Order guarantee: **init array → RSC client stylesheets → HTML → payload pushes**, so the global
  array exists before any `.push`, the stylesheets for RSC client chunks land before the HTML that
  React's reveal script can make visible, and the HTML exists before the client tries to hydrate it.

🧒 **Why the weird format?** It's a single pipe carrying two kinds of stuff (the photo of the plate,
and the order ticket), chopped into labeled pieces so the browser can tell them apart and reassemble
them in the right order even though they arrive interleaved and out of order.

### Stage F — The browser hydrates from the inlined payload (no re‑fetch)

- `packages/react-on-rails-pro/src/RSCRoute.tsx` → during initial load/hydration, `<RSCRoute>` reads
  the embedded payload from `window.REACT_ON_RAILS_RSC_PAYLOADS[cacheKey]`.
- `packages/react-on-rails-pro/src/getReactServerComponent.client.ts` →
  **`createFromPreloadedPayloads(payloads, componentName)`** turns the array of raw Flight strings
  into a `ReadableStream` and calls React's **`createFromReadableStream`** to deserialize the tree.
  (No console replay here — the server already injected console output during SSR.)
- `packages/react-on-rails-pro/src/registerServerComponent/client.tsx` →
  `wrapServerComponentRenderer` hydrates the DOM node and, importantly, does a **side‑effect import
  of `react-on-rails-rsc/client.browser`** so the bundler includes the RSC client runtime (the
  `RSCWebpackPlugin` detects it).
- `packages/react-on-rails-pro/src/RSCProvider.tsx` → `createRSCProvider` provides
  `getComponent`/`refetchComponent` (cache + `useTransition`) so nested components can request RSC.

```
Browser parses HTML ─┬─▶ window.REACT_ON_RAILS_RSC_PAYLOADS[key] = ["<flight>", …]   (from inlined <script>s)
                     │
                     ├─▶ React hydrateRoot starts
                     │
                     └─▶ <RSCRoute> → createFromPreloadedPayloads(...) → createFromReadableStream(...)
                              → rebuilds the SAME tree the server produced → buttons wired up ✅
```

### Stage G — Client navigation / refetch (the steady‑state win)

When something interactive needs fresh server data (route change, refresh), you do **not** reload the
page. You fetch **just a new payload**:

- `packages/react-on-rails-pro/src/getReactServerComponent.client.ts` →
  **`fetchRSC`** builds `GET /<rscPayloadGenerationUrlPath>/<componentName>?props=<JSON>` and calls
  **`createFromFetch(fetch(url), …)`**, parsing the length‑prefixed stream with
  `LengthPrefixedStreamParser`, then `createFromReadableStream`.
- Rails side of that endpoint:
  `react_on_rails_pro/lib/react_on_rails_pro/concerns/rsc_payload_renderer.rb` →
  **`rsc_payload`** action → `stream_view_containing_react_components(template: 'rsc_payload.text.erb')`,
  `content_type: "application/x-ndjson"`. (The HTTP `Content-Type` header is `application/x-ndjson`, but
  the body itself uses the length‑prefixed framing described in §4.E — the client always parses it with
  `LengthPrefixedStreamParser`, not as line‑delimited JSON.)
  Route defined in `react_on_rails_pro/lib/react_on_rails_pro/routes.rb` → **`rsc_payload_route`**
  (`GET /rsc_payload_generation_url/:component_name`). Template:
  `react_on_rails_pro/app/views/react_on_rails_pro/rsc_payload.text.erb`.

```
User clicks ──▶ RSCRoute.refetch() ──▶ fetch(/rsc_payload/MyPage?props=…)
                                              │
                                Rails rsc_payload action ──▶ rsc-bundle ──▶ renderToReadableStream
                                              │
                  length-prefixed Flight ◀────┘
                                              │
        createFromFetch → createFromReadableStream → React swaps in the new subtree (useTransition)
```

---

## 5. Server vs Client component registration (why there are `.rsc`, `.server`, `.client` files)

The same component name is registered differently in each bundle, which is why you see triplet files:

| File                                     | Bundle        | What it does                                                                                                                                                                                        |
| ---------------------------------------- | ------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `registerServerComponent/server.rsc.ts`  | RSC bundle    | Just `ReactOnRails.register(...)`. **No wrapping** — the RSC bundle only _generates_ the payload, it never hydrates.                                                                                |
| `registerServerComponent/client.tsx`     | client bundle | Wraps with `wrapServerComponentRenderer` (client) → provides RSC context + the `react-on-rails-rsc/client.browser` side‑effect import.                                                              |
| `wrapServerComponentRenderer/server.tsx` | server bundle | Wraps `<Component>` in `<RSCProvider><Suspense><Component/></Suspense></RSCProvider>`, validates `railsContext.getRSCPayloadStream()` exists so nested Server Components can fetch nested payloads. |

`getReactServerComponent.server.ts` is the server‑side fetcher: it calls
`railsContext.getRSCPayloadStream(name, props)`, loads the manifests via
`buildClientRenderer(reactClientManifest, reactServerManifest)` (from `react-on-rails-rsc/client.node`),
transforms the stream (`transformRSCStream`), and calls React's **`createFromNodeStream`** to render.

---

## 6. Async props / incremental streaming (the advanced performance lever)

Pro supports **async props**: the server can start rendering with partial props and **push updates**
as more data resolves, instead of blocking the whole render on the slowest query.

- `react_on_rails_pro/lib/react_on_rails_pro/server_rendering_js_code.rb` → `async_props_setup_js`
  wraps props with `ReactOnRails.addAsyncPropsCapabilityToComponentProps(usedProps, sharedExecutionContext)`.
- `node_rendering_pool.rb` → `eval_streaming_js` routes to
  `ReactOnRailsPro::Request.render_code_with_incremental_updates(path, js_code, async_props_block:)`.
- `packages/react-on-rails-pro-node-renderer/src/worker/handleIncrementalRenderStream.ts` →
  **`handleIncrementalRenderStream`**: the first JSON object triggers the render
  (`onRenderRequestReceived`), subsequent JSON objects are **updates** (`onUpdateReceived`), each
  guarded by `withChunkTimeout()`.

🧒 **ELI5:** instead of waiting for the _whole_ meal before sending the photo, the kitchen sends the
appetizer photo now and texts you updated photos as each dish finishes. Your plate fills in live.

---

## 7. Where the performance actually comes from (summary)

| Optimization                        | Mechanism                                                                     | File(s)                                              |
| ----------------------------------- | ----------------------------------------------------------------------------- | ---------------------------------------------------- |
| **Smaller JS bundles**              | Server Component source is never sent to the browser; only client refs travel | RSC bundle + `WebpackLoader` strips `'use client'`   |
| **Fast first paint**                | SSR turns the payload into HTML, streamed as it's produced                    | `streamServerRenderedReactComponent`, `stream.rb`    |
| **No double fetch on load**         | Payload is **inlined** into the HTML, reused for hydration                    | `injectRSCPayload.ts`, `createFromPreloadedPayloads` |
| **Cheap updates**                   | Navigation fetches a _description_ (Flight), not a page                       | `fetchRSC` / `rsc_payload` action                    |
| **No render‑blocking on slow data** | Async props stream incremental updates                                        | `handleIncrementalRenderStream.ts`                   |
| **Suspense‑aware streaming**        | Buffers flushed in init→HTML→payload order on React's flush signal            | `injectRSCPayload.ts`                                |

---

## 8. Quick file index (relative to repo root)

**Ruby / Rails**

- `react_on_rails_pro/app/helpers/react_on_rails_pro_helper.rb` — `stream_react_component`, `rsc_payload_react_component`
- `react_on_rails_pro/lib/react_on_rails_pro/concerns/stream.rb` — `stream_view_containing_react_components`
- `react_on_rails_pro/lib/react_on_rails_pro/concerns/rsc_payload_renderer.rb` — `rsc_payload` action
- `react_on_rails_pro/lib/react_on_rails_pro/routes.rb` — `rsc_payload_route`
- `react_on_rails_pro/lib/react_on_rails_pro/server_rendering_pool/node_rendering_pool.rb` — `eval_streaming_js`
- `react_on_rails_pro/lib/react_on_rails_pro/server_rendering_js_code.rb` — `generate_rsc_payload_js_function`, `render`
- `react_on_rails/lib/react_on_rails/helper.rb` — `server_rendered_react_component`
- `react_on_rails_pro/app/views/react_on_rails_pro/rsc_payload.text.erb`

**Node renderer (Fastify)**

- `packages/react-on-rails-pro-node-renderer/src/worker/handleRenderRequest.ts` — `prepareResult`, `runInVM`
- `packages/react-on-rails-pro-node-renderer/src/worker/handleIncrementalRenderStream.ts`

**JS/TS runtime (`packages/react-on-rails-pro/src/`)**

- `ReactOnRailsRSC.ts` — server‑side payload generation (`buildServerRenderer`)
- `getReactServerComponent.server.ts` / `.client.ts` — fetchers (`createFromNodeStream` / `createFromFetch`)
- `wrapServerComponentRenderer/server.tsx` / `client.tsx`
- `registerServerComponent/server.rsc.ts` / `client.tsx`
- `RSCProvider.tsx`, `RSCRoute.tsx`
- `injectRSCPayload.ts`, `parseLengthPrefixedStream.ts`, `transformRSCNodeStream.ts`

---

**Next:** `02-shakapacker-dev-and-prod-builds.md` (how these three bundles get built and watched in
dev vs prod) and `03-rsc-npm-package-react19-webpack-vs-rspack.md` (why `react-on-rails-rsc` exists,
React 19 pinning, webpack vs rspack).

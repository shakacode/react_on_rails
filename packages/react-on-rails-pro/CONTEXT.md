# React on Rails Pro — RSC

React Server Components support for Rails apps: server-side Flight payload generation, embedding into SSR HTML, client-side caching, and loader-time prefetch for client routers.

## Language

**RSC Payload**:
The Flight-serialized output of rendering a server component for a given `componentName + componentProps` pair.
_Avoid_: flight data, RSC chunk (chunk means one stream segment, not the whole payload)

**Provider Cache**:
The per-`RSCProvider`-instance cache of decoded payload promises (`Promise<ReactNode>`), keyed by `createRSCPayloadKey(componentName, componentProps)`; the source of truth once a component renders.
_Avoid_: RSC cache (ambiguous with the other stores)

**Embedded Payload Registry**:
The `window.REACT_ON_RAILS_RSC_PAYLOADS` global written during SSR streaming and consulted by the client before any HTTP fetch.
_Avoid_: preloaded payloads store

**Prefetch Store**:
A module-level, page-scoped registry of decoded payload promises created by `prefetchServerComponent(...)` from outside React context (router loaders/preloads), awaiting adoption by a Provider Cache.

**Self-eviction**:
A failed prefetch removes its own Prefetch Store entry, so the subsequent render fetches normally — a failed prefetch behaves as if it never happened.

**Adoption**:
The act of a `RSCProvider` copying a Prefetch Store entry into its own Provider Cache on the first `getComponent` call for that key. Adoption is one-time per Provider Cache: if that provider later evicts the key, the next `getComponent` call fetches fresh data instead of re-adopting the old prefetch.

## Relationships

- Each root component wrapped by `wrapServerComponentRenderer/client` gets its own **RSCProvider**, hence its own **Provider Cache**.
- The **Prefetch Store** is shared across all providers on the page; a prefetched entry may be adopted once by any number of Provider Caches (payloads for the same key are identical and immutable). Once any provider has adopted an entry, a later same-key loader prefetch starts a fresh warm request for the next render instead of treating the adopted entry as reusable loader state.
- The Prefetch Store holds **decoded** promises (`Promise<ReactNode>`), never raw fetch streams — a stream body is single-consumption, a decoded promise is not.
- `refetchComponent` bypasses the Prefetch Store entirely: refetch means "fresh data" and always goes to the network. The store is only consulted on first `getComponent` for a key.
- The Embedded Payload Registry outranks a network fetch; a prefetch for a key already embedded in the SSR HTML must be a no-op.
- `prefetchServerComponent` returns `Promise<void>` (warm-cache only, never a `ReactNode`): resolves once decoded into the Prefetch Store, once the caller's `AbortSignal` aborts its wait, or once a fetch/decode failure has self-evicted from the store. Fetch/decode failures do not reject the public promise, so fire-and-forget usage produces no unhandled-rejection noise. Rendering payloads is exclusively `<RSCRoute />`'s job.
- Signature: `prefetchServerComponent(componentName, componentProps, { signal?, skipIfEmbedded? })`. `headers`/`credentials` are intentionally absent: fetch options are not part of the cache key, so anything that could change payload content must be identical across all fetch paths (per-app needs belong in a global fetch config, not a per-prefetch parameter). `signal` cancels only the caller's wait; it does not cancel the shared fetch for other same-key callers or a later render. `skipIfEmbedded` defaults to `true`; set it to `false` only when deliberately warming a sibling root even though another matching root already has an embedded SSR payload.
- Prefetch has **no extra CSP/console-replay surface**: it calls the shared client-fetch path with its default `replayConsoleScripts` policy off. Because Adoption makes prefetched and render-fetched payloads interchangeable, a per-path CSP fork would make inline-script emission timing-dependent. Non-prefetched client-navigation fetches explicitly opt into the legacy console replay behavior; adopted prefetched payloads do not replay server console scripts. Same-request SSR payload injection remains nonce-capable via `cspNonce`.
- During SSR, `prefetchServerComponent` is a **resolving no-op** (server conditional export): SSR guarantees the payload is embedded via `injectRSCPayload`, so this is the degenerate case of the "embedded payload ⇒ prefetch no-ops" rule. It must never reject — loaders legitimately run on the server.
- The Prefetch Store is **bounded** (mirror the Provider Cache's `BoundedLRU`): entries that are never adopted must not accumulate.
- The Prefetch Store is cleared on soft page unload, so same-key prefetches from a previous Turbo/Turbolinks page cannot be adopted by the next page.

## Example dialogue

> **Dev:** "The router loader prefetched `Dashboard`, but there are two React roots on this page — which one gets the payload?"
> **Domain expert:** "Both can. The **Prefetch Store** is page-global; each **RSCProvider** performs **Adoption** into its own **Provider Cache** on first `getComponent`. One network fetch, any number of adopters."
> **Dev:** "If a loader runs again for the same key after adoption, does it just no-op?"
> **Domain expert:** "No. Adoption means the old store entry has served a render. A later loader prefetch starts a fresh warm request so the next provider cache miss can still be warm."
> **Dev:** "And if the user hits refresh-data, do we reuse the prefetched entry?"
> **Domain expert:** "No — `refetchComponent` always bypasses the Prefetch Store."

## CSS & FOUC

_Verified against the code (July 2026): the FOUC-prevention mechanism is manifest-driven
`preinit` **with a `precedence` option** — render-blocking per Suspense boundary — plus
stream-level fallback layers. An earlier provisional note claimed the framework calls no
`preinit`; that was wrong. What the framework avoids is `preinit`/`preload` **without**
precedence, which is non-blocking and flicker-prone._

**FOUC (Flash of Unstyled Content)**:
The interval in which streamed DOM paints with zero styling before its stylesheet
applies — "flashes unstyled, then everything styles at once." Distinct from FOUT (fonts)
and from layout shift.
_Avoid_: flicker, flaking, flashing (all used loosely for the same thing)

**Shell CSS**:
The stylesheets for the immediately-flushed HTML shell, render-blocking in `<head>`;
these gate first paint, so the set must stay minimal. Loaded via the Rails layout pack
tags, not by the RSC pipeline.
_Avoid_: head CSS; critical CSS

**Manifest CSS**:
The per-client-reference `css` href arrays recorded in `react-client-manifest.json` by
the bundler manifest plugin. This is the **root input** of FOUC prevention: every other
layer exists to compensate when it is missing. Under Rspack it is only populated on the
`react-on-rails-rsc` 19.2.1+ line, and only when `output.publicPath` is a concrete
string.

**Stylesheet Hint**:
The `preinit(href, { as: 'style', precedence: 'rsc-css' })` call the framework fires
during the Flight render for each rendered client reference with Manifest CSS. React
carries the hint through the payload, emits the `<link rel="stylesheet"
data-precedence="rsc-css">`, and **blocks that boundary's reveal until the sheet loads**.
When hints work, React itself prevents FOUC; the framework adds no scraping.

**Streamed (per-boundary) CSS**:
Stylesheets for components that arrive later in the stream, emitted as
`<link data-precedence="rsc-css">` ahead of the component's Suspense reveal — so they
block that boundary's reveal, not first paint.

**`rsc-css` precedence**:
The React 19 `data-precedence` bucket the whole pipeline keys off, shared by Stylesheet
Hints and by the fallback-injected links. React hoists the bucket to the end of
`<head>` and dedupes by href. App authors may reuse the bucket for hand-authored
critical CSS.

**FOUC fallback layers**:
The stream-level compensations that act only when Manifest CSS (and therefore Stylesheet
Hints) are missing or late: promotion of streamed stylesheet **preload** tags to
render-blocking links; inference of stylesheet links from client-chunk names in the raw
Flight text (fed by a `loadable-stats.json` chunk→CSS map); and **Suspense-reveal
deferral** — holding React's reveal script back briefly so an inferred link can flush
first. These layers are heuristic and dev/test-only in practice: in production-mode
builds numeric chunk ids defeat the chunk-name inference (and its deferral), and
id-based CSS filenames defeat preload promotion — so a default production build is
protected by Stylesheet Hints alone. The deferral protects only a short window per
payload stream.
_This is the precise referent of the July 2026 review's "multiple batches": the layered
fallbacks, contrasted with the reviewer's abandoned single-module "loader" (which is the
same idea as Stylesheet Hints — attach CSS to the boundary and let the reveal block on
it)._

**Server-rendered client component**:
A component fully server-rendered into the streamed HTML but hydrated (made interactive)
on the client. "Client component" is a misnomer: it is not client-only, it is
server-rendered-but-not-yet-hydrated.
_Avoid_: client-only component

### CSS & FOUC relationships

- Manifest CSS ⇒ Stylesheet Hints ⇒ React-owned reveal blocking. The fallback layers are
  redundant whenever this chain is healthy; they carry the page only when it is broken.
- Dev HMR builds inline CSS into JS, so neither FOUC nor its prevention is observable in
  HMR — absence of flicker in dev proves nothing about production.
- See `docs/adr/0002-rsc-css-data-precedence-over-preinit.md` for why per-boundary
  `data-precedence` blocking was chosen over all-CSS-in-`<head>` and over non-blocking
  preloads.

## Flagged ambiguities

- (none — the "batch"/"loader" ambiguity from the July 2026 review is resolved under
  **FOUC fallback layers** above)

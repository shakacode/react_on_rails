<!--
  PORTED DOCUMENT — provenance:
    Source repo:   shakacode/react_on_rails_rsc
    Source file:   internal/docs/ppr-spike-findings.md
    Source PR:     https://github.com/shakacode/react_on_rails_rsc/pull/194 (CLOSED 2026-07-16)
    Source branch: experimental-ppr-implementation
    Source SHA:    4c27ec84250cb06449a321796bcad1b9c9d175fb
    Ported:        2026-08-13 into shakacode/react_on_rails for issue #4885
      (Deliverable 1 item 1: preserve the architecture description, layer
      diagram, delimiter protocol, and Production Readiness Gap table before
      the closed PR's branch is garbage-collected).
    Body below is verbatim from the source except for the annotated
    "References > Documentation" section at the end, whose relative paths
    refer to the react_on_rails_rsc repository, not this one.
-->

# PPR Spike Findings: Partial Prerendering for React on Rails

**Issue:** shakacode/react-on-rails-demo-marketplace-rsc#113 (Task T6)
**Date:** 2026-07-14
**Status:** Experimental spike -- not production-ready

---

## 1. Executive Summary

Partial Prerendering (PPR) is a rendering strategy that splits a page into a
**static shell** (cached HTML) and **dynamic holes** (streamed at request time).
The static shell -- containing above-the-fold layout, navigation, hero images,
and skeleton placeholders -- is served instantly from cache, delivering a near-
zero TTFB. Dynamic content (product details, reviews, personalized data) streams
into the postponed Suspense boundary slots using React 19.2's resume APIs.

**Key result:** PPR combines the TTFB of a fully static page with the freshness
of server-side rendering. Users see meaningful content immediately while dynamic
data loads progressively.

This spike implemented PPR across three repositories:

1. **react-on-rails-rsc** (npm): Flight-level prerender API (`./static.node` export)
2. **react_on_rails** (gem + Pro monorepo): Fizz-level prerender/resume integration with Rails caching
3. **react-on-rails-demo-marketplace-rsc**: Demo product page with PPR variant

The implementation validates the architecture end-to-end. Production adoption
requires React 19.2 stabilization, integration tests, cache warm-up mechanisms,
and observability tooling.

---

## 2. Architecture Overview

### Two-Phase Rendering Model

PPR splits server rendering into two distinct phases:

**Phase 1 -- Prerender (build/warm time or first request):**
Produces an HTML shell containing all static content, skeleton placeholders for
dynamic boundaries, and an opaque `PostponedState` that records which Suspense
boundaries were not yet resolved.

**Phase 2 -- Resume (every request):**
Serves the cached shell HTML immediately, then streams dynamic content into the
postponed Suspense boundary slots. The client receives both the shell and
streamed chunks; standard React hydration handles the combined output without
PPR-specific client code.

### React 19.2 APIs

PPR relies on two API pairs: one at the **Flight layer** (RSC payload) and one
at the **Fizz layer** (HTML rendering).

#### Fizz APIs (HTML rendering)

```typescript
// react-dom/static.node
prerenderToNodeStream(
  element: ReactNode,
  options?: {
    signal?: AbortSignal;
    bootstrapScripts?: string[];
    onError?: (error: Error) => void;
  }
): Promise<{
  prelude: Readable;              // HTML shell stream
  postponed: PostponedState | null; // null = everything resolved; non-null = has dynamic holes
}>
```

```typescript
// react-dom/server.node
resumeToPipeableStream(
  element: ReactNode,
  postponedState: PostponedState,
  options?: {
    onError?: (error: Error) => void;
    onShellReady?: () => void;
  }
): {
  pipe: <W extends Writable>(destination: W) => W;
  abort: (reason?: unknown) => void;
}
```

**Key behaviors:**

- `PostponedState` is opaque and JSON-serializable. It contains segment IDs and
  replay node metadata that React uses to match resumed content to shell slots.
- Suspense boundaries that have unresolved async work when the prerender
  completes (or when an `AbortController` signal fires) become postponed.
- `postpone()` is NOT a publicly exported API in React 19.2. Postponement is
  triggered by unresolved async server components or by aborting via
  `AbortController.signal`.
- The element tree passed to `resumeToPipeableStream` MUST be structurally
  identical to the tree used in `prerenderToNodeStream`. React replays the tree
  and skips prerendered segments using the `PostponedState` map.

#### Flight APIs (RSC payload)

```typescript
// react-server-dom-webpack/static.node
prerenderToNodeStream(
  model: ReactClientValue,
  clientManifest: ClientManifest,
  options?: {
    signal?: AbortSignal;
    onError?: (error: unknown) => void;
    onPostpone?: () => void;
    identifierPrefix?: string;
  }
): Promise<{ prelude: Readable }>
```

The Flight prerender generates a complete RSC payload for all resolved server
components. It is distinct from the Fizz prerender -- it produces an RSC wire-
format stream (not HTML). This Flight payload is consumed by
`createFromNodeStream` to build the React element tree that Fizz then renders
to HTML.

### Layer Diagram

```
                          Prerender Path                    Resume Path
                          ============                      ===========

    Server Components     App + static props                App + ALL props
         |                     |                                 |
    Flight Layer          Flight prerenderToNodeStream       Flight renderToPipeableStream
    (RSC payload)              |                                 |
         |                RSC payload (static)              RSC payload (complete)
         |                     |                                 |
    SSR Layer             createFromNodeStream              createFromNodeStream
    (React tree)               |                                 |
         |                React element tree                React element tree
         |                (with unresolved Suspense)        (fully resolved)
         |                     |                                 |
    Fizz Layer            Fizz prerenderToNodeStream         Fizz resumeToPipeableStream
    (HTML)                     |                                 |
         |                { prelude, postponed }            Dynamic HTML chunks
         |                     |                            streamed into shell slots
         |                Cache (shell + PostponedState)
         v                     v                                 v
    Client                Instant shell HTML ---------> Complete page with hydration
```

---

## 3. Implementation Details

### 3.1 npm Package: react-on-rails-rsc

**File:** `src/static.node.ts`
**Export:** `./static.node` in `package.json`

Wraps the Flight `prerenderToNodeStream` from `react-server-dom-webpack/static.node`
with the same `withStylesheetHints` Proxy that the existing `renderToPipeableStream`
wrapper uses. This ensures CSS stylesheet hints (`preinit` calls with
`precedence: 'rsc-css'`) are injected during prerender, just as they are during
normal streaming rendering.

**Exported API:**

```typescript
// Standalone function
prerenderToNodeStream(
  model: unknown,
  clientManifest: BundleManifest,
  options?: PrerenderOptions
): Promise<{ prelude: Readable }>

// Web Streams variant
prerender(
  model: unknown,
  clientManifest: BundleManifest,
  options?: PrerenderOptions
): Promise<{ prelude: ReadableStream }>

// Factory (mirrors buildServerRenderer pattern)
buildServerPrerenderer(clientManifest: BundleManifest): {
  prerenderToNodeStream: (model, options?) => Promise<{ prelude: Readable }>;
  prerender: (model, options?) => Promise<{ prelude: ReadableStream }>;
  reactClientManifest: FilePathToModuleMetadata;
}
```

**PrerenderOptions:**

```typescript
interface PrerenderOptions {
  environmentName?: string;
  onError?: (error: unknown) => void;
  onPostpone?: () => void;
  identifierPrefix?: string;
  signal?: AbortSignal;
}
```

**Design rationale:** The `buildServerPrerenderer` factory mirrors
`buildServerRenderer` from `server.node.ts`. Both construct the stylesheet-hint
Proxy once and close over it, avoiding per-call Proxy creation. The standalone
`prerenderToNodeStream` function is also provided for simpler use cases.

**Test coverage:** `tests/flight-prerender.rsc.test.ts` covers four scenarios:

1. Basic prerender producing RSC payload with expected content
2. Factory prerender via `buildServerPrerenderer`
3. Stylesheet hint injection (CSS entries produce `:HS` / `preinit` hints)
4. Error callback propagation (`onError`)

### 3.2 Pro npm Package: react-on-rails-pro

**File:** `pprServerRenderedReactComponent.ts`

Two primary functions registered on the ReactOnRails global via `proStreaming.ts`:

#### `pprPrerenderServerRenderedReactComponent`

Orchestrates the prerender phase:

1. Renders the RSC tree through Flight `renderToPipeableStream` (standard path,
   NOT the Flight prerender -- the Flight payload must be complete for Fizz to
   consume)
2. Pipes the Flight payload through `createFromNodeStream` to build the React
   element tree
3. Calls Fizz `prerenderToNodeStream` with an `AbortController` signal to
   produce the HTML shell and `PostponedState`
4. Streams the HTML prelude through `injectRSCPayload` (inline RSC payload for
   client hydration)
5. Appends the `<!--PPR_POSTPONED_STATE-->` delimiter followed by the
   JSON-serialized `PostponedState`
6. Wires through `streamServerRenderedComponent` for tracker setup and error
   enrichment

#### `pprResumeServerRenderedReactComponent`

Orchestrates the resume phase:

1. Receives the stored `PostponedState` from the Rails cache
2. Renders the full RSC tree (with all props, including async data) through
   Flight `renderToPipeableStream`
3. Builds the React element tree via `createFromNodeStream`
4. Calls Fizz `resumeToPipeableStream` with the element tree and
   `PostponedState`
5. Pipes the dynamic HTML through `injectRSCPayload`
6. Runtime guard: checks for `resumeToPipeableStream` availability
   (React 19.2+ required)

Both functions use the existing error handling infrastructure: RSC diagnostic
enrichment, owner stack capture, and consumer abort support.

### 3.3 Pro Gem: react_on_rails_pro

#### RenderOptions

Added two new render modes:

- `:ppr_prerender` -- triggers `pprPrerenderServerRenderedReactComponent`
- `:ppr_resume` -- triggers `pprResumeServerRenderedReactComponent`

#### ServerRenderingJsCode

Extracted helper methods:

- `resolve_render_function_name` -- maps render mode to the corresponding JS
  function name on the ReactOnRails global
- `ppr_resume_context_params_js` -- builds the JS context object for resume
  calls, including the `PostponedState`

#### `ReactOnRailsProHelper#ppr_react_component`

The Rails view helper that orchestrates the two-phase cached render:

```ruby
ppr_react_component("ProductPage",
  props: { product: @product },
  cache_key: ["product", @product.id],
  cache_ttl: 60.seconds,
  tag_keys: ["product:#{@product.id}"]
)
```

**Execution flow:**

1. Compute cache key (includes bundle digests via
   `ReactOnRailsPro::Cache.react_component_cache_key`)
2. Check cache for existing shell + PostponedState
3. On cache miss:
   a. Call `internal_stream_react_component` with `render_mode: :ppr_prerender`
   b. Parse response at `<!--PPR_POSTPONED_STATE-->` delimiter
   c. Extract HTML shell and PostponedState JSON
   d. Write both to cache with TTL
4. Serve cached HTML shell to client immediately
5. Call `internal_stream_react_component` with `render_mode: :ppr_resume`,
   passing PostponedState
6. Stream dynamic content to client

**Key implementation detail:** Uses `reverse_merge` instead of `merge` when
calling `internal_stream_react_component` to preserve the caller's
`render_mode`. With `merge`, the internal method's defaults would overwrite
`:ppr_prerender` / `:ppr_resume` with the standard streaming render mode.

**Tag-based revalidation:** Supported through the existing
`ReactOnRailsPro::Cache` infrastructure, allowing targeted invalidation (e.g.,
invalidate all product shells when a product is updated).

---

## 4. Data Flow

### Complete Request Lifecycle

```
                                     Request
                                        |
                                        v
                            Rails Controller Action
                                        |
                                        v
                          ppr_react_component helper
                                        |
                              +---------+---------+
                              |                   |
                              v                   |
                         Cache Lookup             |
                              |                   |
                     +--------+--------+          |
                     |                 |          |
                   [HIT]             [MISS]       |
                     |                 |          |
                     |                 v          |
                     |    Node: pprPrerender      |
                     |         |                  |
                     |         v                  |
                     |    Flight renderToPipeable  |
                     |         |                  |
                     |         v                  |
                     |    createFromNodeStream     |
                     |         |                  |
                     |         v                  |
                     |    Fizz prerenderToNodeStream
                     |         |                  |
                     |         v                  |
                     |    HTML shell + PostponedState
                     |         |                  |
                     |         v                  |
                     |    injectRSCPayload         |
                     |         |                  |
                     |         v                  |
                     |    Append <!--PPR_POSTPONED_STATE-->
                     |    + JSON PostponedState    |
                     |         |                  |
                     |         v                  |
                     |    Cache Write             |
                     |         |                  |
                     +---------+                  |
                              |                   |
                              v                   |
                    Serve Cached Shell HTML        |
                    (instant TTFB)                 |
                              |                   |
                              +-------------------+
                              |
                              v
                   Node: pprResume
                              |
                              v
                   Flight renderToPipeableStream
                   (full props, including async data)
                              |
                              v
                   createFromNodeStream
                              |
                              v
                   Fizz resumeToPipeableStream
                   (with PostponedState)
                              |
                              v
                   Dynamic HTML chunks
                   streamed to client
                              |
                              v
                   Client: hydrateRoot()
                   (handles shell + streamed chunks)
```

### Delimiter Protocol

The prerender response uses a simple delimiter protocol to transmit both the
HTML shell and the PostponedState in a single stream:

```
[HTML shell bytes]
<!--PPR_POSTPONED_STATE-->
{"type":"postponed","value":{"segments":[...],"slots":[...]}}
```

The Rails helper splits at the delimiter, caches both parts, and discards the
delimiter itself. The PostponedState JSON is never sent to the client.

---

## 5. Key Design Decisions

### 5.1 Delimiter Protocol: `<!--PPR_POSTPONED_STATE-->`

**Decision:** Use an HTML comment as the delimiter between shell HTML and
PostponedState JSON.

**Rationale:** HTML comments are well-defined, cannot conflict with React's
rendered output (React does not emit `PPR_POSTPONED_STATE` as an internal
comment), and are trivially parseable with a simple string split. Alternatives
like custom HTTP headers or multipart responses were considered but add
complexity for no benefit in a single-stream architecture.

### 5.2 Shell + PostponedState Cached Together

**Decision:** Cache the HTML shell and its PostponedState as a unit, not
separately.

**Rationale:** The PostponedState is structurally tied to the exact HTML shell
that produced it. A PostponedState from one prerender cannot be used with a
shell from a different prerender -- the segment IDs and replay nodes would not
match. Caching them together makes this invariant impossible to violate.

### 5.3 Component Identity Between Phases

**Decision:** The same component tree must be rendered in both prerender and
resume phases.

**Rationale:** This is a React requirement, not a design choice. Fizz's resume
path replays the element tree and uses PostponedState to skip prerendered
segments. If the tree structure differs (different components, different
conditional branches, different key assignments), React cannot match resumed
content to the correct shell slots.

**Implication for consumers:** Props that affect component tree structure
(conditional rendering, different component types based on data) must be
available in both phases. Only the data inside Suspense boundaries can differ.

### 5.4 Render Mode Propagation via `reverse_merge`

**Decision:** Use `reverse_merge` instead of `merge` when passing options to
`internal_stream_react_component`.

**Rationale:** `internal_stream_react_component` applies default options
including a default `render_mode`. Using `merge` would let these defaults
overwrite the PPR-specific `:ppr_prerender` or `:ppr_resume` mode. With
`reverse_merge`, the caller's explicit render mode takes precedence over
internal defaults.

### 5.5 Flight Render (Not Flight Prerender) for Fizz Input

**Decision:** The Fizz prerender and resume both consume a Flight payload
generated by the standard `renderToPipeableStream`, not the Flight
`prerenderToNodeStream`.

**Rationale:** The Flight prerender API (`react-on-rails-rsc/static.node`)
produces a complete, finalized RSC payload. While useful for caching Flight
payloads, the Fizz prerender needs a live Flight stream that it can consume
incrementally with an AbortController signal to determine which Suspense
boundaries become dynamic holes. Using the Flight prerender would force all
Flight content to resolve before Fizz can begin, defeating the purpose of the
signal-based postponement.

The `react-on-rails-rsc/static.node` export serves a different purpose: caching
the RSC payload itself for static pages that do not need PPR.

### 5.6 Error Handling Parity

**Decision:** PPR prerender and resume use the same error handling
infrastructure as existing RSC streaming.

**Rationale:** RSC diagnostic enrichment (owner stacks, component names, error
context) and consumer abort support are critical for debuggability. Reusing
`streamServerRenderedComponent` wiring ensures PPR errors surface with the same
fidelity as standard streaming errors.

### 5.7 React Version Guard

**Decision:** Runtime check for `resumeToPipeableStream` availability.

**Rationale:** `resumeToPipeableStream` is only available in React 19.2+. A
runtime guard produces a clear error message rather than a cryptic
`undefined is not a function` crash, and allows the Pro gem to support both
React 19.0.x (non-PPR) and 19.2.x (PPR-capable) installations.

---

## 6. Limitations and Known Issues

### React Version Dependency

`resumeToPipeableStream` requires React 19.2+. Environments still on React
19.0.x cannot use the resume path. The npm package (`react-on-rails-rsc`)
already declares `react: ^19.2.7` as a peer dependency, but the gem
installation may have mismatched React versions.

### PostponedState is Opaque

There is no public API to inspect, modify, or validate a `PostponedState`
object. If a cached PostponedState becomes corrupted or incompatible (e.g., due
to a React version upgrade that changes the internal format), the only recovery
is to invalidate the cache and re-prerender.

### Flight Prerender vs Fizz Prerender Serve Different Purposes

The `react-on-rails-rsc/static.node` export (Flight prerender) produces RSC
wire-format payloads. The Fizz-level prerender in the gem produces HTML. They
are not interchangeable:

- Flight prerender: useful for caching RSC payloads for static pages
- Fizz prerender: the core PPR mechanism that produces the HTML shell + PostponedState

There is currently no Flight-level cache layer that composes with Fizz PPR.
Adding one could further reduce prerender cost for static RSC content.

### Demo Limitations

The demo product page uses the SSR component structure without true async server
components in Suspense boundaries. As a result, `PostponedState` is `null` in
the simplest configurations -- a more complete demo would need async server
components that remain pending at prerender time to produce non-null
PostponedState with actual dynamic holes.

### Missing Infrastructure

- **No warm-up mechanism:** Cache population relies on the first request (cold
  start). There is no background prerender worker or build-time prerender step.
- **No A/B testing:** No built-in support for comparing cached vs. fresh shells.
- **No cache observability:** Cache hit/miss rates are not instrumented or
  logged beyond basic Rails cache logging.
- **No graceful degradation:** If the resume phase fails, there is no fallback
  to full SSR rendering.

---

## 7. Performance Expectations

### Time to First Byte (TTFB)

| Scenario         | Expected TTFB                               |
| ---------------- | ------------------------------------------- |
| SSR (standard)   | Server render time (50-200ms typical)       |
| RSC streaming    | First chunk time (similar to SSR for shell) |
| PPR (cache miss) | Server render time + cache write overhead   |
| PPR (cache hit)  | Near-zero (~1-5ms cache read)               |

PPR cache hits should deliver dramatically faster TTFB because no server
rendering occurs for the shell -- the cached HTML is served directly.

### Largest Contentful Paint (LCP)

The static shell should include all above-the-fold content:

- Navigation header
- Product hero image (URL in static props)
- Product name, brand, price, rating
- Skeleton placeholders for dynamic sections

Since LCP elements are in the shell, LCP on PPR cache hits should match or beat
SSR/RSC LCP, as the content arrives with the first response bytes rather than
after server render completes.

### Time to Interactive (TTI)

Dynamic holes stream in progressively via inline `<script>` completion chunks,
identical to standard React streaming behavior. TTI depends on:

1. Time for dynamic data to resolve on the server
2. Client JavaScript bundle load time
3. Hydration time

PPR does not change the streaming or hydration model -- only the shell delivery
is accelerated. TTI for dynamic content should be comparable to RSC streaming.

### Cache Invalidation

- **TTL-based:** Configurable per-component, default 60 seconds for the spike
- **Tag-based:** Leverages existing `ReactOnRailsPro::Cache` tag infrastructure
  for targeted invalidation (e.g., invalidate all product shells on product
  update)
- **Digest-based:** Cache keys include bundle digests, so deployments with new
  JavaScript bundles automatically invalidate stale shells

---

## 8. Production Readiness Gap

The following work items are needed to move from spike to production:

### Must Have

| Item                                              | Effort   | Notes                                              |
| ------------------------------------------------- | -------- | -------------------------------------------------- |
| React 19.2 stabilization                          | External | `resumeToPipeableStream` must be stable            |
| Integration tests (prerender + resume round-trip) | Medium   | End-to-end test with real Suspense boundaries      |
| Graceful degradation on resume failure            | Medium   | Fall back to full SSR if PostponedState is invalid |
| PostponedState versioning / validation            | Small    | Detect stale PostponedState after React upgrades   |
| Cache warm-up mechanism                           | Medium   | Background job or build step to populate cache     |

### Should Have

| Item                                        | Effort | Notes                                       |
| ------------------------------------------- | ------ | ------------------------------------------- |
| Cache hit/miss monitoring                   | Small  | Instrument `ppr_react_component` helper     |
| Performance benchmarks                      | Medium | Controlled comparison: PPR vs SSR vs RSC    |
| Error recovery for corrupted PostponedState | Small  | Auto-evict and re-prerender                 |
| Documentation and migration guide           | Medium | Public-facing API docs for Pro consumers    |
| Dynamic hole timeout                        | Small  | Abort resume if dynamic data takes too long |

### Nice to Have

| Item                                           | Effort | Notes                                                     |
| ---------------------------------------------- | ------ | --------------------------------------------------------- |
| Flight payload caching (compose with Fizz PPR) | Large  | Cache RSC payload to skip Flight render on resume         |
| A/B testing support                            | Medium | Compare PPR vs non-PPR for the same component             |
| Incremental shell updates                      | Large  | Update portions of cached shell without full re-prerender |
| Multi-region cache coordination                | Large  | CDN-level shell caching                                   |

---

## 9. Comparison with Next.js PPR

Both React on Rails PPR and Next.js PPR use the same underlying React 19.2 APIs
(`prerenderToNodeStream`, `resumeToPipeableStream`). The key differences are in
integration scope and granularity.

| Aspect                      | Next.js PPR                                                          | React on Rails PPR                               |
| --------------------------- | -------------------------------------------------------------------- | ------------------------------------------------ |
| **Granularity**             | Route-level (entire page)                                            | Component-level (per `ppr_react_component` call) |
| **Router integration**      | File-system router, automatic PPR for routes with `experimental_ppr` | Manual opt-in per component in Rails views       |
| **Cache infrastructure**    | Built-in Data Cache + Full Route Cache                               | Rails.cache with tag-based revalidation          |
| **Build integration**       | `next build` prerenders at build time                                | First-request prerender or background warm-up    |
| **Static/dynamic boundary** | `Suspense` boundary in page component                                | `Suspense` boundary in RSC component tree        |
| **Framework coupling**      | Tightly integrated with Next.js router, middleware, and ISR          | Additive to existing React on Rails streaming    |
| **Deployment model**        | Vercel-optimized, self-host available                                | Standard Rails deployment, any hosting           |

### Advantages of React on Rails Approach

- **Component-level granularity:** Different components on the same page can
  independently opt into PPR with different cache TTLs and invalidation
  strategies. Next.js PPR operates at the route level.
- **Rails cache ecosystem:** Leverages existing Rails.cache infrastructure
  (Redis, Memcached, etc.) with mature tag-based invalidation. No proprietary
  cache layer required.
- **Incremental adoption:** PPR is additive -- existing SSR and RSC streaming
  components continue to work unchanged. Components can be migrated to PPR
  individually.

### Advantages of Next.js Approach

- **Zero-configuration:** PPR is automatic for routes that use Suspense
  boundaries. No explicit cache key management.
- **Build-time prerender:** Static shells are generated at build time, not on
  first request. No cold-start penalty.
- **Mature infrastructure:** Next.js PPR has been in experimental use since
  Next.js 14, with extensive production testing at Vercel.

---

## 10. Open Questions

1. **PostponedState compatibility across React patches:** Will a PostponedState
   generated by React 19.2.7 work with React 19.2.8? React does not make
   stability guarantees for this internal format. Cache invalidation on React
   upgrades may be necessary.

2. **Cold start mitigation:** Should shell prerendering happen at deploy time
   (build step), on application boot (initializer), or lazily on first request?
   Each has trade-offs in deployment complexity vs. user experience.

3. **Multi-variant shells:** If a page has user-specific static content (e.g.,
   locale, theme), should PPR produce per-variant shells, or should all
   user-specific content be dynamic? Per-variant shells multiply cache storage
   and warm-up cost.

4. **Flight payload caching composition:** Can the Flight prerender
   (`react-on-rails-rsc/static.node`) be composed with Fizz PPR to avoid
   re-running Flight rendering on resume? This would require caching the RSC
   payload separately and feeding it to `createFromNodeStream` during resume.

5. **Streaming shell delivery:** Currently the shell is served as a complete
   HTML chunk. For very large shells, should the cached content be streamed
   incrementally from the cache backend?

---

## 11. References

### React APIs

- `react-dom/static.node` -- `prerenderToNodeStream` (Fizz prerender)
- `react-dom/server.node` -- `resumeToPipeableStream` (Fizz resume)
- `react-server-dom-webpack/static.node` -- `prerenderToNodeStream` (Flight prerender)
- `react-server-dom-webpack/server.node` -- `renderToPipeableStream` (Flight render)
- `react-server-dom-webpack/client.node` -- `createFromNodeStream` (Flight client)

### Repository Artifacts

| Repo                                | Key files                                                                                                                  | PR                                                                                        |
| ----------------------------------- | -------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| react_on_rails_rsc                  | `src/static.node.ts`, `tests/flight-prerender.rsc.test.ts`, `package.json` (exports)                                       | [#192](https://github.com/shakacode/react_on_rails_rsc/pull/192)                          |
| react_on_rails (Pro)                | `pprServerRenderedReactComponent.ts`, `proStreaming.ts`, `RenderOptions`, `ServerRenderingJsCode`, `ReactOnRailsProHelper` | [#4659](https://github.com/shakacode/react_on_rails/pull/4659)                            |
| react-on-rails-demo-marketplace-rsc | PPR product page variant                                                                                                   | Issue [#113](https://github.com/shakacode/react-on-rails-demo-marketplace-rsc/issues/113) |

### Documentation

> Porting note (2026-08-13): the three paths below are relative to the
> **shakacode/react_on_rails_rsc** repository (where this document originated),
> not to shakacode/react_on_rails. `ppr-spike-spec.md` lived on the same closed
> PR #194 branch (`experimental-ppr-implementation`, SHA
> `4c27ec84250cb06449a321796bcad1b9c9d175fb`); the other two are on that
> repository's main branch.

- PPR Spike Spec: `internal/docs/ppr-spike-spec.md` (react_on_rails_rsc repo)
- React on Rails RSC versioning: `internal/docs/versioning.md` (react_on_rails_rsc repo)
- React runtime strategy: `internal/docs/eliminate-react-fork.md` (react_on_rails_rsc repo)

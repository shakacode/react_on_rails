# Next.js + Separate Rails Backend vs. React on Rails Pro Async Props and Streaming

Date: 2026-07-13

## Question

When the alternative is a Next.js App Router frontend backed by a separate Rails API, does React on
Rails Pro have a meaningful advantage because Rails can resolve request-specific data and stream it
into React as async props? Do the current comparison docs explain that advantage accurately?

## Source snapshot

- React on Rails checkout: [`5abee39`](https://github.com/shakacode/react_on_rails/commit/5abee39bbe1898c9abb28ab054c740d4caf44f73)
- React on Rails / Pro version: `17.0.0.rc.6`; bidirectional pull-mode async props shipped in
  [`c32a19d84`](https://github.com/shakacode/react_on_rails/commit/c32a19d84629897a66523a4bd453f9a55d67e9e5)
- Next.js App Router documentation checked 2026-07-13: [Fetching Data](https://nextjs.org/docs/app/getting-started/fetching-data),
  [Data Security](https://nextjs.org/docs/app/guides/data-security), and
  [Backend for Frontend](https://nextjs.org/docs/app/guides/backend-for-frontend)
- React documentation checked 2026-07-13: [Server Components](https://react.dev/reference/rsc/server-components),
  [`<Suspense>`](https://react.dev/reference/react/Suspense), and
  [`renderToReadableStream`](https://react.dev/reference/react-dom/server/renderToReadableStream)

Only first-party documentation and repository source are used below.

## Executive answer

**Yes, React on Rails Pro has a concrete architectural advantage for Rails-owned, request-specific
data, especially when the Rails API would exist only to feed the Next.js frontend.** Async props let
Rails keep authentication, authorization, tenancy, caching, query objects, and ActiveRecord in the
Rails request path while still giving React a Promise per slow value. React can put those Promises
behind separate Suspense boundaries and stream each resolved section into the original page response.
The app does not need a separate application/page-data JSON or GraphQL endpoint, a Next.js data-access wrapper, or manual session
forwarding for that page data. The implementation is a bidirectional HTTP/2 NDJSON channel between
Rails and the Pro Node renderer, not a callback from React to a Rails API.

Version 17.0.0.rc.6 makes the comparison stronger than eager streaming alone. Pro supports both
**push mode**, where Rails starts known work and emits values as they resolve, and **pull mode**, where
the rendered React tree requests a named prop and Rails starts only the corresponding allowlisted
work. Mixed mode can eagerly push critical data while pulling optional, branch-dependent data. This
gives Rails-owned data the same important demand-driven property as a Next.js async Server Component
that calls its backend only when that component branch renders.

**But the comparison must not claim that Next.js cannot do equivalent progressive rendering.** A
Next.js Server Component can fetch a separate Rails API, suspend, and stream its UI through
`<Suspense>`. Multiple Rails API requests can start in parallel, and React/Next can reveal their
boundaries independently. Next's official docs explicitly support external HTTP APIs from Server
Components and demonstrate both parallel fetching and component-level streaming.

The strongest accurate claim is therefore:

> For data already owned by Rails, React on Rails Pro async props preserve Suspense streaming while
> removing the separate application API/auth/BFF boundary that a Next.js + Rails split requires.

That can improve latency, resource use, security ergonomics, and maintenance, but it is a hypothesis
to benchmark for a representative application rather than a universal performance guarantee. React
on Rails Pro still serializes props and crosses an internal Rails-to-Node renderer boundary; Next.js
may offset its extra Rails API hop with route prefetching, framework caching, Partial Prerendering,
or edge/static delivery.

## Do the current public comparisons address this?

**At the source snapshot, before this branch's companion documentation edits, only partially.** The
evidence existed, but it was scattered and the dedicated decision guide missed the most important
streaming comparison.

- The dedicated [Next.js + separate Rails backend guide](../../docs/oss/getting-started/nextjs-with-separate-rails-backend.md)
  describes two deployables, auth complexity, and API contracts, but says nothing about async props,
  Suspense, or how the best Next.js implementation would fetch Rails during server rendering.
- The broader [alternatives guide](../../docs/oss/getting-started/comparing-react-on-rails-to-alternatives.md)
  mentions fewer cross-service hops and less API serialization as _potential_ React on Rails
  advantages. That is directionally correct but too abstract to answer the streaming question.
- The [Next.js migration guide](../../docs/oss/migrating/migrating-from-nextjs.md) makes the key data
  access point: a Next.js Server Component fetches the Rails API over HTTP and forwards auth, while
  the integrated path uses ActiveRecord from Rails and deletes frontend-only API endpoints. It maps
  Next streaming to `stream_react_component_with_async_props`, but it does not walk through both
  streaming timelines.
- The [RSC architecture comparison](../../docs/pro/react-server-components/nextjs-comparison.md)
  says async props can stream each slow value independently and that Rails keeps its app/routes/auth/DB.
  However, its Next.js column says only “Related via Suspense/PPR,” which undersells the fact that a
  Next Server Component can directly fetch a Rails endpoint and progressively reveal the result.
- The [Pro streaming guide](../../docs/pro/streaming-ssr.md) documents the full async-props mechanism,
  the Rails-to-renderer channel, concurrency requirements, and why renderer-side Rails API fetches are
  discouraged. At the baseline it did not explain the already-shipped push/pull choice or frame that
  mechanism against a separately deployed Next.js frontend.

The companion documentation changes on this branch put the end-to-end comparison in the dedicated
Next.js + Rails guide, add the push/pull API to the streaming and helper references, and correct the
Next.js column so it explicitly acknowledges direct Rails API fetching behind Suspense. That is the
right resolution: retain this analysis as the evidence and nuance behind the shorter public copy.

## First clarify the terminology

Calling this “asynchronous queries in the controller” is close, but not quite accurate.

- The Rails controller owns request-level policy and starts the streamed view through
  `stream_view_containing_react_components`.
- Fast values can be prepared synchronously and passed through `props:`.
- A slow query must run inside the `stream_react_component_with_async_props` emitter block (usually
  through a scope or query object). If the controller resolves it before rendering, it delays the
  shell and defeats progressive streaming.
- The emitter block runs in the Rails streaming flow and can access controller/view request context.
  It is still Rails-owned application code even though the slow query is not literally executed in
  the controller method.

This is documented explicitly in the [Pro streaming guide](../../docs/pro/streaming-ssr.md#3-add-the-component-to-your-rails-view)
and implemented by [`Request.render_code_with_incremental_updates`](../../react_on_rails_pro/lib/react_on_rails_pro/request.rb),
which starts the render response and runs the async-props block in a separate fiber.

Do not confuse async props with [`async_react_component`](../../docs/oss/api-reference/ruby-api-pro.md#async_react_componentcomponent_name-options--).
The latter starts multiple complete component renderer calls concurrently and returns `AsyncValue`
objects; it is not the mechanism that resolves Rails data behind Suspense boundaries.

## The fair architecture comparison

The fair Next.js baseline is **a Server Component fetching Rails directly**, not a Client Component
that waits until hydration and not a Server Component calling its own Next Route Handler.

| Architecture                                       | Data path for initial page                                                                                                         | Can progressively reveal server-rendered UI?             | Extra application boundary                                                                              |
| -------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| React on Rails Pro eager push                      | Browser → Rails; Rails starts known query/policy/cache work → internal Node renderer prop stream → Suspense HTML → browser         | Yes, one boundary per async prop                         | No separate Rails page-data API is required; there is still an internal Rails ↔ Node renderer boundary |
| React on Rails Pro on-demand pull                  | Browser → Rails; rendered React branch requests a named prop → Rails runs allowlisted work → prop stream → Suspense HTML → browser | Yes, and an unused branch need not start its Rails query | Same internal renderer boundary, but no separate page-data API                                          |
| Next Server Component → Rails API                  | Browser → Next; Next `fetch` → Rails API → JSON → Suspense HTML/RSC → browser                                                      | Yes, one boundary per async component/promise            | Rails API contract plus server-to-server HTTP and auth propagation                                      |
| Next Server Component → Next Route Handler → Rails | Browser → Next render; server-side absolute `fetch` → Next public handler → Rails                                                  | Yes, but with avoidable work                             | Adds a Next BFF/handler hop on top of the Rails API                                                     |
| Next Client Component → Rails API                  | Browser gets shell/JS, hydrates, then browser → Rails API                                                                          | Not as server-rendered data on the initial response      | Browser-facing Rails API plus auth/CORS/CSRF and client loading/cache state                             |

Next's official [Backend for Frontend guide](https://nextjs.org/docs/app/guides/backend-for-frontend#server-components)
says Server Components should fetch directly from the source rather than call Route Handlers, because
the latter creates an extra HTTP round trip. In the split architecture, Rails is that external source.
A Next Route Handler remains useful for browser-facing aggregation, validation, cookie normalization,
or hiding backend topology, but it is not the preferred render-time data path merely because it is
called a BFF.

Next's [Data Security guide](https://nextjs.org/docs/app/guides/data-security#external-http-apis)
explicitly supports existing REST/GraphQL backends and shows reading a cookie in Next and forwarding
an auth cookie to the external API. That is a valid architecture, not a Next.js workaround; it simply
makes the cross-app auth and API contract part of the system.

## What React on Rails Pro async props actually do

The current product path is deeper than “Rails sends some JSON before React renders”:

1. Rails starts an incremental rendering request to the Pro Node renderer over a bidirectional HTTP/2
   NDJSON stream. The initial line starts the render while a separate Rails fiber executes the
   async-props block. See
   [`request.rb`](../../react_on_rails_pro/lib/react_on_rails_pro/request.rb).
2. Each `emit.call(name, value)` JSON-serializes one value and writes an update to that request's
   renderer stream. See
   [`async_props_emitter.rb`](../../react_on_rails_pro/lib/react_on_rails_pro/async_props_emitter.rb).
3. The request-scoped `AsyncPropsManager` holds a stable Promise for each name. `setProp` resolves that
   Promise when Rails emits the corresponding value; unresolved Promises are rejected when the stream
   closes. See
   [`AsyncPropsManager.ts`](../../packages/react-on-rails-pro/src/AsyncPropsManager.ts).
4. React suspends on that Promise, and the Pro renderer uses `renderToPipeableStream` to send the shell
   and later boundary completions. See
   [`streamServerRenderedReactComponent.ts`](../../packages/react-on-rails-pro/src/streamServerRenderedReactComponent.ts)
   and the [streaming guide's execution sequence](../../docs/pro/streaming-ssr.md#6-what-happens-during-streaming).

This preserves one Rails-owned request policy surface. The controller/filter chain can establish the
authenticated user, tenant, locale, feature flags, and authorization context; query objects and model
scopes resolve display-safe values; Rails caching can be applied deliberately; and React receives
only the serialized values it needs.

Version 17.0.0.rc.6 also supports bidirectional **pull mode**: the renderer requests a named prop only
when `getReactOnRailsAsyncProp` reads it, and Rails services names from `emit.pull_requests`. Passing
`push_props: []` selects pure pull; passing selected names keeps those eager while other names are
pulled. See the [17.0.0.rc.6 changelog](../../CHANGELOG.md),
[`AsyncPropsManager#getProp`](../../packages/react-on-rails-pro/src/AsyncPropsManager.ts), and
[`AsyncPropsEmitter`](../../react_on_rails_pro/lib/react_on_rails_pro/async_props_emitter.rb).

Pull mode is the closest direct comparison to component-local Next.js fetching:

- Next.js: rendering an async Server Component starts that component's Rails API `fetch`.
- React on Rails Pro: reading an async prop sends a `propRequest` control message to Rails, which
  starts only the allowlisted Rails query or service call associated with that name.

The key distinction remains the application boundary. Both are demand-driven; Next crosses a Rails
application API, while Pro crosses its internal renderer protocol and keeps the query in the active
Rails page request. Pull should not replace push indiscriminately: waiting for React's request starts
work later and can create a waterfall. Push critical/always-needed values early, and pull expensive
optional values whose branch may never render. Pulled names must be allowlisted and rejected when
unknown rather than mapped dynamically to constants, methods, or SQL.

## What Next.js can do with a separate Rails backend

Next.js supports the same underlying React streaming semantics:

- Server Components may use asynchronous I/O, including `fetch` to an API. An uncached fetch blocks
  the component that awaits it, and placing that component under Suspense lets the rest of the page
  stream. See [Next.js Fetching Data](https://nextjs.org/docs/app/getting-started/fetching-data#server-components)
  and [Streaming](https://nextjs.org/docs/app/getting-started/fetching-data#streaming).
- A Server Component can start a Promise without awaiting it, pass it to another component, and let a
  Suspense boundary reveal the result later. React documents the same cross-server/client Promise
  pattern in [Server Components](https://react.dev/reference/rsc/server-components#async-components-with-server-components).
- Independent requests can be initiated together. Next documents `Promise.all` for parallel fetching
  and notes that sequential `await` statements still create waterfalls. See
  [Parallel data fetching](https://nextjs.org/docs/app/getting-started/fetching-data#parallel-data-fetching).
- Next can stream component-level fallbacks and completions, not merely a whole-page loading screen.
  Its docs recommend placing Suspense close to uncached/runtime data for granular streaming.
- Next's framework-level advantages remain substantial: route-segment prefetching, route/RSC caching,
  Partial Prerendering/static shells, and tighter App Router integration. These can matter more than
  the Rails API hop for cacheable public pages or navigation-heavy apps.

Therefore the comparison must not say “Next waits for Rails before it can stream.” It waits only for
the particular Rails response awaited by a given component; other UI and other boundaries can stream.

## Where the React on Rails Pro advantage is concrete

### 1. It removes a redundant separate application/page-data API boundary

If the only consumer of a Rails endpoint is the Next.js page, React on Rails Pro can replace:

```text
Next Server Component → authenticated HTTP endpoint → Rails controller serializer → JSON
```

with:

```text
Rails streamed view → Rails query/policy/cache → async prop → React Suspense boundary
```

The Rails-to-Node renderer stream remains, but it is rendering infrastructure rather than a second
application-facing data API. The team no longer maintains endpoint routing, request/response schemas,
auth forwarding, error translation, and compatibility solely to move Rails-owned view data into React.

### 2. Request security and data policy stay in one owner

In the split stack, Rails must authorize every API request and Next must correctly forward or exchange
the user's credential. A BFF can centralize that forwarding, but then there are two policy-aware server
layers. With async props, Rails filters, policies, scopes, tenancy, and display-safe serialization all
run in the request that owns the page. This reduces integration surface; it does not remove the need
to authorize each query or minimize serialized values.

### 3. Independent Rails sources can map directly to independent Suspense boundaries

One Rails emitter value maps to one stable React Promise. That is a natural fit for a dashboard where
the shell and fast props render immediately while posts, metrics, and recommendations arrive
independently. Achieving the same result in Next.js is possible, but normally means independent Rails
API calls/endpoints (or a custom streaming/`defer` protocol from Rails). Aggregating all values into
one conventional JSON response reduces HTTP request count but reintroduces head-of-line blocking on
the slowest field.

Pull mode adds a second concrete advantage for conditional UI: Rails can avoid executing an optional
query entirely when React never reads that prop. Next.js can avoid the corresponding API call by not
rendering the async component, so the demand behavior is not unique; Pro's distinction is achieving it
without making that data source a separately authenticated Rails API endpoint.

### 4. It can be incrementally applied inside existing Rails pages

The async-props path can enhance one component in an ERB-rendered page without making Next's App
Router the owner of the route or creating a separate frontend application. That is a product and
migration advantage even when raw request latency is similar.

## Important limits and tradeoffs

### “Async” does not automatically mean parallel database queries

The emitter block is sequential by default. Two consecutive queries still form a waterfall even
though each value is delivered asynchronously relative to the shell. Independent work must be fanned
out explicitly with the `async` reactor. For ActiveRecord, the documented safe path requires Rails
7.1+ fiber isolation, enough pooled connections, `with_connection`, captured request state, and a
fiber-aware database driver. Blocking drivers or CPU-bound work do not gain I/O parallelism. See
[Database Queries in Async Props Blocks](../../docs/pro/async-props-database-queries.md) and the
[parallel fan-out section](../../docs/pro/streaming-ssr.md#loading-multiple-slow-sources-in-parallel).

Next.js has the analogous waterfall risk: sequential `await` statements serialize requests, while
eager initiation/`Promise.all` or separate async component boundaries allow overlap.

Pull mode adds the opposite scheduling tradeoff. It can save unused work, but it begins wanted work
only after the React read reaches Rails. Use eager push/preload for critical known data and pull for
expensive optional branches in both designs.

### React on Rails Pro does not eliminate serialization or process boundaries

Async props are JSON-serialized into NDJSON update chunks and cross from Rails to a Node renderer.
The browser response then carries streamed HTML and RSC payload data. The advantage is removal of the
_application API_ round trip and contract, not “zero serialization” or “one process.” Pro SSR/RSC also
requires a Node renderer runtime alongside Rails.

### Async-props prerender caching is intentionally bypassed

The [streaming guide](../../docs/pro/streaming-ssr.md#progressive-data-with-async-props) says Pro skips
prerender caching for async-props renders because results may depend on request-specific data outside
the cache key. Explicit fragment caching is appropriate only with a safe key. Next's current docs say
`fetch` is not cached by default, but Next can opt appropriate data or UI into its cache model. For
public, reusable content, caching may dominate any per-request async-props advantage.

### Streaming changes HTTP semantics and requires compatible infrastructure

Once the response shell is committed, either framework has limited ability to change the HTTP status.
Pro routes must make redirects/status/cache decisions before the first write; Next's `loading.js`
documentation likewise notes that streamed responses have already sent headers. Reverse proxies,
load balancers, and CDNs must also avoid buffering. Next explicitly documents this for
[self-hosting](https://nextjs.org/docs/app/guides/self-hosting#streaming-and-suspense); the React on
Rails migration guide's nginx example disables buffering for both stacks.

### Next.js remains the better fit when the API boundary is valuable

The extra boundary is not waste when the same Rails API serves mobile, partner, or multiple web
clients; when separate teams and release trains are an explicit goal; or when the product benefits
heavily from Next's App Router, route prefetch, cache/ISR/PPR, or deployment ecosystem. In those cases,
external HTTP APIs are an intentional architecture, and Next's own security guide recommends them for
existing large applications and separately managed backends.

## Performance verdict

React on Rails Pro async props should have the strongest advantage when all of these are true:

- Rails already owns the database, authorization, tenancy, and cache policy.
- The Rails endpoints would otherwise exist mainly for the Next.js web frontend.
- The page has multiple request-specific or slow data regions that benefit from independent reveal.
- Next and Rails would be separate services, especially across a nontrivial network boundary.
- The Rails queries or service calls can actually overlap safely.

The advantage becomes smaller or may reverse when:

- Rails API results are already shared, stable, and cached near Next.
- The page is mostly static/cacheable and benefits from Next's prefetch/PPR/CDN model.
- Next and Rails are colocated with very low-latency persistent connections.
- The workload is one fast API call rather than several independently useful regions.
- Rails fiber/database configuration serializes the supposedly concurrent work.

So “better” is plausible and architecturally well founded, but it should be stated as **fewer
application-layer boundaries with preserved streaming**, then verified with measurements.

## Benchmark needed before making a performance claim

Compare the best implementation of each architecture, not a client-fetch straw man:

1. React on Rails Pro: one `stream_react_component_with_async_props` root, one Suspense boundary per
   data source, safe parallel fan-out where supported.
2. Next.js: Server Components fetch the Rails API directly, one Suspense boundary per data source,
   requests initiated in parallel, no render-time call through a Next Route Handler.
3. Run one-source and three-source scenarios with equivalent Rails queries, output, authorization,
   cache policy, deployment region, and proxy buffering configuration.
4. Record p50/p95 TTFB, shell arrival, each boundary's arrival, FCP/LCP, response bytes, Rails/Next/Node
   CPU, database connections, Rails query time, server-to-server request time, and error behavior.
5. Repeat cold/warm cache and low/high concurrency runs. A new code or deployment head invalidates the
   comparison evidence.

This would show whether the removed Rails API/BFF work is material in the actual product and whether
Rails fiber concurrency holds under load.

## Recommended documentation shape

The companion public-doc changes should add a prominent “Async Rails data and streaming” section to
[`nextjs-with-separate-rails-backend.md`](../../docs/oss/getting-started/nextjs-with-separate-rails-backend.md),
and link it from the RSC comparison capability table. The section should:

1. Compare React on Rails Pro async props with the **best-practice Next Server Component → Rails API**
   path.
2. State that both support Suspense streaming and parallel independent work.
3. Explain the concrete Pro advantage: Rails-owned query/policy/cache code feeds React Promises without
   a separate Rails page-data API, manual auth forwarding, or a Next BFF, in eager push or on-demand pull mode.
4. Clarify that the slow work runs in the async-props emitter block/query object, not before rendering
   in the controller action.
5. State the honest costs: internal Rails-to-Node serialization, Node renderer operations, async-props
   cache limits, and ActiveRecord/fiber pool requirements.
6. Preserve Next's strengths: API reuse and team separation, route/prefetch/cache/PPR integration, and
   edge/static delivery.
7. Use “can reduce” or “has a structural opportunity to reduce” for latency until a same-workload
   benchmark exists.

Suggested headline copy:

> **Both stacks can stream Rails-backed data through Suspense.** With Next.js, a Server Component
> normally fetches the separate Rails API over HTTP and forwards the user's credential. React on Rails
> Pro async props keep that query and authorization in Rails and stream each resolved value into the
> React render, so pages whose API exists only for the frontend can remove that API/BFF boundary. This
> often reduces coordination and may reduce latency, but Next's caching, prefetching, PPR, and reusable
> API architecture can be the better trade for other applications.

## Bottom line

The baseline docs contained the ingredients but did not make this the center of the Next.js + Rails
comparison. The companion edits address that gap. React on Rails Pro's distinctive value is not that
it alone can stream or lazily start work. It is that it can
combine **Rails-native request/data ownership** with **React-native Promise, Suspense, RSC, and HTML
streaming semantics**, including demand-driven pull, without turning Rails into a separate web API
for its own view layer.

## Recommended disposition

- Land the companion comparison, RSC-table, streaming, and helper-reference updates together so the
  push/pull capability and the honest Next.js baseline do not drift apart.
- Lead with “both stream; Pro removes a separate page-data application boundary for Rails-owned data.”
- Keep fixed latency/speedup claims out of public copy until the same-workload benchmark above exists.
- Treat pull mode as a documented public capability from 17.0.0.rc.6 onward, with allowlisting and
  push-versus-pull scheduling guidance beside every example.

## Primary sources

- [Next.js: Fetching Data](https://nextjs.org/docs/app/getting-started/fetching-data) — Server Component
  async I/O, Suspense streaming, and sequential versus parallel request patterns.
- [Next.js: Data Security](https://nextjs.org/docs/app/guides/data-security) — external HTTP APIs,
  explicit cookie forwarding, DALs, authorization, and DTO guidance.
- [Next.js: Backend for Frontend](https://nextjs.org/docs/app/guides/backend-for-frontend) — public Route
  Handlers, backend proxying, and the warning not to call a Route Handler from a Server Component.
- [Next.js: Self-Hosting](https://nextjs.org/docs/app/guides/self-hosting#streaming-and-suspense) —
  end-to-end streaming and proxy-buffering requirements.
- [React: Server Components](https://react.dev/reference/rsc/server-components#async-components-with-server-components)
  and [React: Suspense](https://react.dev/reference/react/Suspense) — Promise suspension and progressive reveal.
- [React on Rails Pro streaming guide](../../docs/pro/streaming-ssr.md) and
  [async-props database guide](../../docs/pro/async-props-database-queries.md) — eager push, on-demand
  pull, controller/view placement, fan-out, caching, and database constraints.
- [React on Rails 17.0.0.rc.6 changelog](../../CHANGELOG.md) and
  [pull-mode implementation commit](https://github.com/shakacode/react_on_rails/commit/c32a19d84629897a66523a4bd453f9a55d67e9e5) —
  shipped bidirectional async-props contract.
- [`Request.render_code_with_incremental_updates`](../../react_on_rails_pro/lib/react_on_rails_pro/request.rb),
  [`AsyncPropsEmitter`](../../react_on_rails_pro/lib/react_on_rails_pro/async_props_emitter.rb), and
  [`AsyncPropsManager`](../../packages/react-on-rails-pro/src/AsyncPropsManager.ts) — Rails-to-renderer
  protocol and request-scoped Promise lifecycle.

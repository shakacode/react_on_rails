# Next.js with a Separate Rails Backend: Pros and Drawbacks

Teams evaluating React on Rails often ask whether they should instead run Next.js as a standalone frontend and Rails as a separate backend API.

This guide outlines the tradeoffs so you can decide based on architecture and team constraints, not trend pressure.

## What This Architecture Means

In this model:

- Next.js owns the web UI, frontend routing, and frontend SSR.
- Rails exposes JSON/GraphQL APIs and usually owns business rules, persistence, and background jobs.
- Frontend and backend become independent deployables with an explicit API contract between them.

## Pros

- Clear frontend/backend ownership boundaries
- API reuse for additional clients (mobile apps, partner integrations, internal tools)
- Frontend release cadence can move independently from backend release cadence
- Strong fit for organizations already staffed like separate frontend and platform teams

## Drawbacks

- Two deploy pipelines and two production runtimes to monitor
- Cross-app authentication/session complexity (cookies, CSRF, token flows, refresh behavior)
- More contract maintenance between teams (versioning, schema drift, backwards compatibility)
- Extra integration testing burden to catch frontend/backend contract regressions
- More distributed debugging across service boundaries

## Where React on Rails Differs

React on Rails keeps Rails and React integrated in one app boundary:

- React components can be rendered directly from Rails views
- You can avoid mandatory API-first architecture for server-rendered pages
- End-to-end debugging and deployment are often simpler for Rails-first teams

This is often a better fit when your primary goal is substantial React UI in a Rails app without taking on full frontend/backend split complexity.

## The Streaming Difference Most Comparisons Miss

Both architectures can stream a shell immediately and reveal slow sections behind React `<Suspense>` boundaries. The
important difference is not whether streaming exists. It is **where a suspended component gets its data**.

### Next.js with a separate Rails backend

A Next.js Server Component can call a Rails JSON or GraphQL endpoint and sit behind `<Suspense>`:

```text
Browser -> Next.js route
             |
             +-> Server Component -> Rails API -> authorization/query -> JSON
             |
             +-> Suspense resolves -> HTML/RSC chunk -> Browser
```

This can produce excellent progressive rendering. The browser does not need a second client-side request when Next
fetches from Rails during the server render. There is still a required **Next server -> Rails API** boundary, however:

- Rails must expose and maintain an endpoint for each query shape or an aggregate page endpoint.
- Each response crosses an HTTP and serialization boundary before React can resume rendering.
- Authentication, tenancy, locale, tracing, and cache context must be propagated across that boundary.
- One aggregate endpoint is simple, but its response normally waits for its slowest field. Independent Suspense
  boundaries usually require independent requests or a custom streaming API contract.

Next.js Route Handlers can proxy those calls as a backend-for-frontend layer, but that adds another boundary. The
[official Next.js BFF guide](https://nextjs.org/docs/app/guides/backend-for-frontend) specifically warns that a Server
Component fetching a Route Handler is slower because of the extra HTTP round trip. For this architecture, a Server
Component should normally call the Rails service directly rather than proxying through its own Route Handler.

### React on Rails Pro async props

React on Rails Pro keeps data loading inside the Rails page request:

This path assumes the Pro Node renderer is running and React Server Components are enabled with
`config.enable_rsc_support = true`; see the [streaming prerequisites](../../pro/streaming-ssr.md#prerequisites).

```text
Browser -> Rails controller/view -> Pro Node renderer -> HTML shell -> Browser
                |                         ^
                +-> Rails query ----------+
                    async prop update      Suspense resolves and streams
```

The controller starts the streaming view and still owns request-level authentication, authorization, tenancy, and
fast synchronous props. Slow work should not be completed in the controller action before rendering, because that
would block the shell. Instead, a thin `stream_react_component_with_async_props` block calls the same Rails model
scopes, policies, caches, or query objects and emits each result when it is ready.

React on Rails and React on Rails Pro 17.0.0 or newer support two async-props styles:

- **Push:** Rails starts known work and emits each prop as it resolves.
- **Pull:** React requests a named prop only when the rendered component tree reads it; Rails then resolves and emits
  that prop. Mixed mode can push critical props while pulling optional ones on demand.

In both cases, the value resolves a request-scoped Promise in the Node renderer, and React flushes the matching
Suspense boundary into the same browser response. This gives a Rails application a Next-like demand-driven rendering
flow without turning its controller/model boundary into a separate page-data API.

There is still an internal Rails -> Node renderer transport and JSON serialization step; React on Rails Pro does not
make cross-runtime serialization disappear. The architectural advantage is that this renderer protocol is provided
by the framework and stays inside one Rails-owned request rather than becoming an application API that two separately
deployed products must coordinate.

### Is React on Rails Pro faster?

It **can be**, especially when the page is Rails-owned and several slow, request-specific queries should fill
independent Suspense boundaries. Avoiding page-data API endpoints and their network, authentication propagation, and
contract overhead is a real advantage.

It is not a universal benchmark result. Next.js can start multiple Rails API requests in parallel and stream each
Server Component as its request completes. Query time, service placement, payload size, caching, connection pools, and
renderer capacity may dominate the extra hop. Treat React on Rails Pro's design as a strong architectural advantage
and potential latency advantage for Rails-centric pages, then benchmark representative pages before claiming a fixed
speedup.

Also, async props do not make sequential Ruby code parallel automatically. Independent Rails queries need the
[documented async fan-out and database connection setup](../../pro/async-props-database-queries.md) to overlap safely.
With per-fiber isolation enabled, child tasks do not inherit `CurrentAttributes`; capture `current_user`, tenant, and
similar request state into local IDs before fan-out so every query remains correctly scoped.

## Practical Comparison

| Question                                                     | React on Rails Pro                                                            | Next.js + separate Rails backend                                   |
| ------------------------------------------------------------ | ----------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| Who owns the browser page request?                           | Rails                                                                         | Next.js                                                            |
| Where do Rails-owned queries run?                            | In the active Rails request, through scopes/query objects used by async props | Behind Rails API endpoints called by Next                          |
| Can slow sections stream independently?                      | Yes, one async prop and Suspense boundary per section                         | Yes, one suspended fetch/component per section                     |
| Can React request data only when a rendered branch needs it? | Yes, with bidirectional pull-mode async props                                 | Yes, by rendering an async Server Component that calls Rails       |
| Required application boundary for page data                  | No separate page-data API; the Pro renderer protocol is internal              | Rails HTTP/GraphQL API contract                                    |
| Strongest fit                                                | Rails owns the product, domain, and request context                           | The API boundary and independent frontend are product requirements |

## Decision Checklist

Choose **Next.js + separate Rails backend** if most of these are true:

- You explicitly want API-first boundaries as a long-term architecture
- You already operate with independent frontend/backend ownership
- You need the same API consumed by multiple external clients

Choose **React on Rails** if most of these are true:

- You want one integrated deployment and ownership model
- Your team is Rails-heavy and wants React without full stack separation
- You want to incrementally adopt React within existing Rails views/pages
- You want Rails-owned queries to resolve streamed Suspense boundaries without creating page-data API endpoints

## Related Reading

- [Comparing React on Rails to alternatives](./comparing-react-on-rails-to-alternatives.md)
- [Comparison with alternatives (feature matrix and benchmarks)](./comparison-with-alternatives.md)
- [Installation into an Existing Rails App](./installation-into-an-existing-rails-app.md)
- [React on Rails Pro streaming SSR and async props](../../pro/streaming-ssr.md)
- [RSC data-fetching patterns](../migrating/rsc-data-fetching.md)
- [Next.js data fetching and streaming](https://nextjs.org/docs/app/getting-started/fetching-data)

# Performance Benchmarks

This page covers the performance characteristics of React on Rails across different rendering strategies, with data from real-world deployments and comparative benchmarks.

## SSR Performance: ExecJS vs Node Renderer

The default ExecJS renderer evaluates JavaScript synchronously inside a single-threaded pool. The [Node Renderer](../building-features/node-renderer/basics.md) (React on Rails Pro) runs a dedicated Node.js master process with worker processes (via `cluster.fork()`), providing dramatically better throughput.

### Key Differences

| Metric            | ExecJS (mini_racer)           | ExecJS (Node.js runtime)      | Node Renderer (Pro)        |
| ----------------- | ----------------------------- | ----------------------------- | -------------------------- |
| Architecture      | V8 isolate in Ruby process    | New process per eval call     | Persistent Node.js workers |
| Concurrency (MRI) | Single-threaded (pool size 1) | Single-threaded (pool size 1) | Multi-worker               |
| Async support     | None                          | None                          | Full (Promises, timers)    |
| Streaming SSR     | Not supported                 | Not supported                 | Supported                  |
| RSC support       | Not supported                 | Not supported                 | Supported                  |
| Typical speedup   | Baseline                      | Comparable                    | 3-10x over ExecJS          |

The Node Renderer's persistent process supports full async rendering and multi-worker concurrency, which are the primary sources of the performance difference. Popmenu reported a [73% decrease in response times](#popmenu) after switching to Pro. ExecJS is limited to synchronous rendering within a single-threaded pool, so the gap widens for pages with many async data sources or large component trees.

## Bundle Splitting Impact

React on Rails supports [code splitting](../building-features/code-splitting.md) (Pro feature) to reduce the amount of JavaScript sent to the browser. The impact depends on your application's structure:

### Client Bundle Size

Code splitting with dynamic `import()` breaks your application into smaller chunks loaded on demand:

- **Without splitting:** A single bundle contains all components, even those not needed on the current page
- **With splitting:** Only the components required for the current route are loaded initially; others load on navigation

For applications with many routes and components, code splitting can substantially reduce initial bundle size. The actual reduction depends on how much code is shared across routes — apps with mostly independent route content typically see larger gains.

### Server Bundle Size

Server bundles are not typically split because the server can load the full bundle once at startup. However, with React Server Components, server-only dependencies are excluded from the client bundle entirely, which compounds the benefits of code splitting.

## Streaming SSR Benefits

[Streaming SSR](../building-features/streaming-server-rendering.md) (Pro feature) uses React's `renderToPipeableStream` to send HTML progressively as components resolve:

### Time to First Byte (TTFB)

| Rendering Strategy                 | TTFB                      | Full Page Load              |
| ---------------------------------- | ------------------------- | --------------------------- |
| Client-side only                   | Fast (empty shell)        | Slow (fetch + render)       |
| Traditional SSR (`renderToString`) | Slow (waits for all data) | Fast (complete HTML)        |
| Streaming SSR                      | Fast (shell immediately)  | Progressive (chunks arrive) |

Streaming SSR provides the best of both approaches: the browser receives the initial HTML shell immediately (fast TTFB) while data-dependent sections stream in as they resolve. This is especially valuable for pages with multiple independent data sources.

### Selective Hydration

With streaming SSR and React 18+, components can hydrate independently as their JavaScript loads:

- Navigation can become interactive while main content is still streaming
- User interactions automatically prioritize hydration of the clicked component
- No single "hydration wall" where the entire page freezes

**Note:** By default, React on Rails uses `defer` scripts which delay all hydration until the page finishes streaming. To enable selective hydration, configure your initializer:

```ruby
config.generated_component_packs_loading_strategy = :async
```

See [Selective Hydration in Streamed Components](../../pro/react-server-components/selective-hydration-in-streamed-components.md) for complete details.

## React Server Components Impact

React Server Components (Pro feature) provide additional performance benefits on top of streaming SSR:

### Client Bundle Reduction

Server components and their dependencies are excluded from the client bundle. In practice, this means:

```jsx
// These imports stay server-side — zero client cost
import { format } from 'date-fns'; // ~30KB
import { marked } from 'marked'; // ~35KB
import numeral from 'numeral'; // ~25KB
```

Applications that use heavy formatting, parsing, or data-processing libraries on the server side see the largest gains. Frigade reported a [62% reduction in client-side bundle size](https://frigade.com/blog/bundle-size-reduction-with-rsc-and-frigade) after migrating to RSC.

### No Hydration for Server Components

Server components produce HTML that does not need hydration — they have no client-side JavaScript. Only client components (those with `'use client'`) require hydration. This reduces Total Blocking Time and improves Time to Interactive.

## Real-World Results

### Non-Production Local Directional Benchmark: Gumroad-Style RSC Demo (April 2026) {#gumroad-style-rsc-demo}

The [Gumroad-style RSC benchmark demo](https://github.com/shakacode/react-on-rails-demo-gumroad-rsc)
is a public ShakaCode comparison repo modeled after a creator-dashboard surface with product listings and sales metrics,
not an official Gumroad integration. It measures the same reduced presenter data and outer layout across two routes. The
comparison changes three axes at once (RSC, the Pro Node renderer, and SSR), so the deltas cannot be attributed to any
single factor. The routes are:

- Inertia-style control: `/dashboard/inertia_demo` (uses the actual `inertia_rails` gem; no Pro renderer or SSR)
- React on Rails Pro + React Server Components: `/dashboard/rsc_demo`

> [!NOTE]
> Both routes use the same Shakapacker with Rspack page-asset build, so this is a route-level comparison rather than a
> bundler comparison. It also does not isolate a renderer-only baseline: the Inertia route has no React on Rails Pro
> renderer or SSR, while the RSC route uses the Pro Node renderer. Treat the deltas as the combined route-level effect;
> see the [SSR Performance table](#ssr-performance-execjs-vs-node-renderer) for the renderer baseline.

The April 30, 2026 local benchmark used eight strictly alternating measured runs between the Inertia and RSC routes
(Inertia, RSC, Inertia, RSC, and so on), four per route. Before each of the eight measured runs, the harness sent one
warmup request to the route being measured.

Conditions:

- Compiled page assets from the same Shakapacker with Rspack configuration for both routes
- Compiled RSC demo bundles
- Rails server without the Shakapacker dev server running
- Dedicated React on Rails Pro Node renderer on `RENDERER_PORT=3800`
- Chrome 147 with matching ChromeDriver 147

> [!WARNING]
> The original artifact does not yet publish `RAILS_ENV`, so the absolute timing values may include development-mode or
> other non-production Rails overhead. It also does not publish browser cache behavior between measured runs, hardware/OS,
> or Ruby/Node/Rails versions. Unknown browser cache state between measured runs affects repeatability. The single warmup
> request before each measured run may also be insufficient for the Pro Node renderer worker pool to reach JIT and
> RSC-payload-compilation steady state, which is more likely to make the RSC route look slower than its steady-state
> performance than to inflate its advantage.
> [Issue 3253](https://github.com/shakacode/react_on_rails/issues/3253) tracks the missing environment metadata. Until
> that is resolved, treat these numbers as directional signals rather than a stable baseline.

The median results showed this directional signal:

| Source  | Metric                                      | Inertia demo | RSC demo | Delta % (negative = RSC faster) |
| ------- | ------------------------------------------- | -----------: | -------: | ------------------------------: |
| Browser | Navigation duration                         |     775.40ms | 607.15ms |                          -21.7% |
| Browser | Largest Contentful Paint                    |     794.00ms | 634.00ms |                          -20.2% |
| Browser | `responseEnd`                               |     644.80ms | 588.80ms |                           -8.7% |
| Rails   | Controller `action_total` (Rails wall time) |     346.87ms | 339.20ms |                -2.2% (variance) |

`action_total` is the Rails wall-time field from the raw benchmark artifact, not a browser Performance API metric. The
artifact does not yet publish enough logger or extraction-script context to confirm whether it is the full
`process_action` duration including rendering or a narrower controller-action field, so do not use it to infer the
server-rendering split. [Issue 3263](https://github.com/shakacode/react_on_rails/issues/3263) tracks the missing
distribution and source artifacts.

Derived from the median table above, the RSC route's post-`responseEnd` browser processing time (`navigation duration -
responseEnd`, including HTML parsing, sub-resource loading, layout, and paint) was about 18ms, compared with about 130ms
for the Inertia control. That gap helps explain why the navigation-duration gain (-21.7%) was larger than the
`responseEnd` gain (-8.7%).

The page-specific script request count, recorded as Chrome DevTools Network panel `Script`-type requests after loading
each route, changed from 6 requests for the Inertia demo to 1 request for the RSC demo. The artifact reports this as a
fixed post-load request-count observation, not a per-run timing median or statistical sample, and it does not measure
combined transfer size or cache behavior. Fewer requests do not necessarily imply a smaller browser payload. See
[Issue 3259](https://github.com/shakacode/react_on_rails/issues/3259).

- _All timing values are medians from the raw benchmark artifact values (n=4 per route); sample size is too small to
  establish statistical significance._
- _The `action_total` delta is shown with a variance qualifier because its -2.2% difference is likely within expected
  variance at n=4._
- _Distribution and variance artifacts are tracked in [Issue 3263](https://github.com/shakacode/react_on_rails/issues/3263)._

#### Worst-case `responseEnd` counter-signal {#gumroad-rsc-worst-case-responseend}

| Metric                             | Inertia demo | RSC demo | Delta % (negative = RSC faster) |
| ---------------------------------- | -----------: | -------: | ------------------------------: |
| Worst-case `responseEnd` (max n=4) |     730.62ms | 768.25ms |                           +5.2% |

The source artifact labels this as p95, but with four samples it is effectively the maximum observed value, not a
stable tail-latency estimate. It shows a +5.2% RSC regression on worst-case `responseEnd` (high variance is expected at
n=4), indicating the Inertia control had a faster worst-case `responseEnd` than the RSC route.

Use these numbers as a case-study signal, not a universal performance claim. The RSC route combines RSC, the Pro Node
renderer, and SSR, while the Inertia control has none of those three factors. With that caveat, the RSC route was faster
on user-visible median navigation duration and LCP while sending fewer page-specific script requests. The p95
`responseEnd` counter-signal was faster for the Inertia control. A stable deployed repeat, renderer-internal timing,
environment metadata, and distribution artifacts are still required before making stronger production-performance claims.

See [Issue 3128](https://github.com/shakacode/react_on_rails/issues/3128) and
[Issue 3144](https://github.com/shakacode/react_on_rails/issues/3144) for the ongoing tracking discussion.

### Production Case Study: Popmenu {#popmenu}

Popmenu, a restaurant platform serving tens of millions of SSR requests daily, adopted React on Rails Pro and reported:

- **73% decrease** in average response times
- **20-25% lower** Heroku hosting costs
- Stable performance under high traffic with the Node Renderer's worker pool

See the [full case study](https://www.shakacode.com/recent-work/popmenu/).

## Measuring Your Own Performance

### Key Metrics to Track

- **Time to First Byte (TTFB):** How quickly the server begins sending HTML
- **Largest Contentful Paint (LCP):** When the main content becomes visible
- **Total Blocking Time (TBT):** Time the main thread is blocked during page load
- **Client bundle size:** Total JavaScript downloaded by the browser
- **Server render time:** Time spent in the SSR process (not logged by default — measure wall clock time in Ruby around the render call; on Pro, enable `config.tracing = true` in `config/initializers/react_on_rails_pro.rb` to log render timings)

### Tools

- **Chrome DevTools Performance tab:** Profile page load and hydration timing
- **Lighthouse:** Automated performance scoring with LCP, TBT, and other Core Web Vitals
- **`webpack-bundle-analyzer`:** Visualize bundle composition and identify large dependencies
- **Rails server logs:** Server-side console messages replayed to `Rails.logger` when `config.logging_on_server = true`
- **Node Renderer logs:** Renderer lifecycle and error details controlled by `RENDERER_LOG_LEVEL` (Pro)

## Related Documentation

- [ExecJS Limitations](./execjs-limitations.md) — constraints of the default rendering engine
- [Streaming Server Rendering](../building-features/streaming-server-rendering.md) — setup and best practices
- [Code Splitting](../building-features/code-splitting.md) — route-based bundle splitting
- [Node Renderer Basics](../building-features/node-renderer/basics.md) — Pro Node.js renderer setup
- [OSS vs Pro](../getting-started/oss-vs-pro.md) — feature comparison
- [React Server Components](../../pro/react-server-components/index.md) — RSC overview and guides

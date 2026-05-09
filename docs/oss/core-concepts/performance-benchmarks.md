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

### Gumroad-Style RSC Benchmark Demo

The [Gumroad-style RSC benchmark demo](https://github.com/shakacode/react-on-rails-demo-gumroad-rsc)
is a public ShakaCode comparison repo, not an official Gumroad integration. It measures a bounded creator-dashboard
surface with the same reduced presenter data and outer layout across two routes:

- Inertia-style control: `/dashboard/inertia_demo`
- React on Rails Pro + React Server Components: `/dashboard/rsc_demo`

> **Note:** These results reflect two distinct value propositions: **Rspack** addresses build speed and development
> iteration time, while **React Server Components** target runtime JavaScript reduction and server-side composition.
> The benchmark below measures only the RSC dimension.

The April 30, 2026 production-like local benchmark used eight alternating cycles between the Inertia and RSC routes,
with one warmup request before each measured run. It used compiled Shakapacker/Rspack assets, compiled RSC demo bundles,
Rails without the Shakapacker dev server, a dedicated React on Rails Pro Node renderer on `RENDERER_PORT=3800`, and
matching Chrome 147 and ChromeDriver 147. The median results showed this directional signal:

| Metric                    | Inertia demo | RSC demo |  Delta |
| ------------------------- | -----------: | -------: | -----: |
| Navigation duration       |     775.40ms | 607.15ms | -21.7% |
| Largest Contentful Paint  |     794.00ms | 634.00ms | -20.2% |
| Response end              |     644.80ms | 588.80ms |  -8.7% |
| Controller `action_total` |     346.87ms | 339.20ms |  -2.2% |
| Page-specific JS requests |            6 |        1 | -83.3% |
| p95 `responseEnd`         |     730.62ms | 768.25ms |  +5.2% |

Use these numbers as a case-study signal, not a universal performance claim. The RSC route was faster on
user-visible median navigation duration and LCP while sending much less page-specific JavaScript, but the p95 response
timing still favored the Inertia control. A stable deployed repeat, renderer-internal timing, and hardware details for
the local run are still required before making stronger production-performance claims.

See [Issue 3128](https://github.com/shakacode/react_on_rails/issues/3128) and
[Issue 3144](https://github.com/shakacode/react_on_rails/issues/3144) for the current tracking discussion, and
[Issue 3253](https://github.com/shakacode/react_on_rails/issues/3253) for the environment-metadata follow-up.

### Popmenu

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

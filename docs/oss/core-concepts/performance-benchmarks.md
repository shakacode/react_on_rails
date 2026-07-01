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

## Benchmarking RSC Against Warm SSR Caches

React Server Components reduce client JavaScript, hydration work, and duplicated data-fetching paths. They do not
automatically beat an already-warm SSR cache on every first-paint metric. If the existing page uses
[`cached_react_component` or `cached_react_component_hash`](../building-features/caching.md#level-2-fragment-caching),
the fair baseline is a warm fragment-cache hit. If it uses
[`config.prerender_caching = true`](../building-features/caching.md#level-1-prerender-caching) without fragment caching,
the fair baseline is a warm prerender-cache hit. Do not compare RSC against an uncached SSR request unless that uncached
state is the production baseline.

This distinction matters most for mostly static public pages. On a fragment-cache hit, React on Rails Pro can skip prop
assembly, JSON serialization, and JavaScript evaluation. Fragment-caching helpers skip the prerender cache for that render
call because the full fragment is already cached. On a prerender-cache hit, props are still assembled and serialized, but
the JavaScript render result is reused. Either warm path can be very hard for an RSC conversion to beat on TTFB, FCP, or
LCP because there may be little server-rendering work left to remove.

### Static landing-page pattern

A cache-optimized landing page often looks like this:

```erb
<%
  cache_key = [
    "welcome-page",
    current_user,
    device_type_cache_key,
    release_cache_key,
    cms_last_updated_at,
    I18n.locale
  ]

  rendered = cached_react_component_hash(
    "WelcomePage",
    cache_key:,
    auto_load_bundle: false
  ) do
    build_welcome_page_props
  end
%>

<% append_javascript_pack_tag("generated/WelcomePage") %>
<% append_stylesheet_pack_tag("generated/WelcomePage") %>
<%= preload_pack_asset("generated/WelcomePage.css") %>
<%= rendered["componentHtml"] %>
<%= content_for :script_tags, rendered["consoleReplayScript"] %>
```

In this shape, `auto_load_bundle: false` keeps asset loading explicit so the page can preserve head ordering and preload
the critical CSS. That per-call option only disables automatic loading when the app has not enabled
`config.auto_load_bundle` globally; if the global setting is `true`, preserve the resulting asset behavior in both the SSR
baseline and the RSC experiment. An RSC experiment must keep the same data, release, device, locale, CMS state, CSS
delivery, font preloads, and hero/image priority before claiming that RSC changed rendering performance. Otherwise the
comparison is apples to oranges: a lower JavaScript payload or lower Total Blocking Time can coexist with worse LCP if the
conversion delays CSS, fonts, or the LCP resource.

### Cache-state matrix

Measure each relevant state intentionally and label it in the report:

| Variant           | How to prepare it                                                                                   | What it answers                                                                  |
| ----------------- | --------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| Cold uncached SSR | Clear fragment/prerender caches and measure the first request for the SSR page                      | Cost of prop assembly, serialization, and JavaScript rendering before caching    |
| Warm cached SSR   | Prime the exact cache key, then measure repeated hits; log `RORP_CACHE_HIT` when available          | Repeat-visitor/server steady state for the existing cached implementation        |
| RSC cold          | Clear relevant Rails/browser/renderer caches and measure the first RSC request                      | First-hit cost of the RSC render, Flight payload generation, and asset discovery |
| RSC warm          | Prime the RSC route under the same data and browser-cache policy, then measure repeated navigations | Steady state for RSC rendering, hydration, Flight payload, and cached assets     |

Use the same production build mode, data snapshot, asset host, CDN/cache policy, browser cache policy, throttling, and
sample order for control and experiment. Include both desktop and mobile runs, and keep visual regression checks in the
same gate as performance checks so a faster page is still the same page.

### Reading RSC wins and non-wins

RSC is most likely to win when the page currently pays a large browser cost: heavy client bundles, long hydration tasks,
large client-only data parsing, repeated interactive subtrees that can become Server Components, or server-only
formatting/parsing libraries that can leave the client bundle entirely. Judge those migrations by Total Blocking Time,
long tasks, JavaScript bytes, hydration/interactivity marks, and navigation responsiveness in addition to LCP.

Warm cached SSR may already be close to optimal when the page is static or cacheable, the cache key is stable, prop
assembly is skipped by `cached_react_component_hash`, critical CSS/fonts are manually preloaded, and the remaining client
JavaScript is already small. In that case, an RSC conversion can still be valuable for maintainability or lower browser
work, but the benchmark should say that clearly instead of framing a warm-cache first-paint tie as an RSC failure.

For RSC pages, also measure what moved into the HTML response. The initial Flight payload is usually embedded in the
HTML stream rather than fetched as a separate `/rsc_payload/*` resource, so `PerformanceResourceTiming` may show fewer
JavaScript requests while the navigation response grows. Pair JavaScript byte counts with HTML transfer size, Flight
payload bytes, FCP/LCP, TBT, and server/renderer timing before drawing conclusions.

## Real-World Results

> [!NOTE]
> This section links to a public live demo first, then covers a non-production local directional benchmark, then a production case study. For validated,
> at-scale results, see the [Production Case Study: Popmenu](#popmenu) below.

### Marketplace demo {#public-marketplace-rsc-demo}

The [Marketplace demo](https://rsc.reactonrails.com/) is a public,
inspectable React on Rails Pro + RSC demo showing the same page families
rendered with traditional SSR, client rendering, and React Server Components.
See the [Live Demo and Evidence](../../pro/react-server-components/index.md#live-demo-and-evidence)
section for the canonical link inventory and caveats: performance showcase, raw
Lighthouse reports, bundle-size breakdowns, the `/why-rsc` walkthrough, and the
demo source.

### Non-Production Local Directional Benchmark: Gumroad-Style RSC Demo (April 2026) {#gumroad-style-rsc-demo}

The [Gumroad-style RSC benchmark demo](https://github.com/shakacode/react-on-rails-demo-gumroad-rsc)
is a public ShakaCode comparison repo modeled after a creator-dashboard surface with product listings and sales metrics,
not an official Gumroad integration. The benchmark methodology, earlier-run artifacts, and the April 30, 2026
production-like local run with median and p95 timings are documented in
[`docs/performance-findings.md`](https://github.com/shakacode/react-on-rails-demo-gumroad-rsc/blob/010b3564398dbb9c8f5caafab25daed65b6f425c/docs/performance-findings.md#production-like-compiled-asset-8-cycle-repeat)
on stacked demo PR
[shakacode/react-on-rails-demo-gumroad-rsc#12](https://github.com/shakacode/react-on-rails-demo-gumroad-rsc/pull/12);
the per-run JSON files remain gitignored local artifacts
([Issue 3263](https://github.com/shakacode/react_on_rails/issues/3263) tracks publishing per-run distribution data).
It measures the same reduced presenter data and outer layout across two routes. The comparison
changes three axes at once (RSC, the Pro Node renderer, and SSR), so the deltas cannot be attributed to any single
factor. The routes are:

- Inertia-style control: `/dashboard/inertia_demo` (uses the actual `inertia_rails` gem; no Pro renderer or SSR)
- React on Rails Pro + React Server Components: `/dashboard/rsc_demo`

> [!NOTE]
> Both routes use the same Shakapacker with Rspack page-asset build, so this is a route-level comparison rather than a
> bundler comparison. It also does not isolate a renderer-only baseline: the Inertia route has no React on Rails Pro
> renderer or SSR, while the RSC route uses the Pro Node renderer. Treat the deltas as the combined route-level effect;
> see the [SSR Performance table](#ssr-performance-execjs-vs-node-renderer) for the renderer baseline.

The April 30, 2026 local benchmark used eight cycles, each measuring both routes in alternating cycle order
(cycle 1: Inertia then RSC; cycle 2: RSC then Inertia; cycle 3: Inertia then RSC; and so on), producing sixteen
measured runs total — eight per route. Before each measured run, the harness sent one warmup request to the route
being measured.

Conditions:

- Compiled page assets from the same Shakapacker with Rspack configuration for both routes
- Compiled RSC demo bundles
- Rails server without the Shakapacker dev server running
- Dedicated React on Rails Pro Node renderer on `RENDERER_PORT=3800`
- Chrome 147 with matching ChromeDriver 147

> [!WARNING]
> The original April 30, 2026 local run did not preserve `RAILS_ENV`, hardware/OS, Ruby/Node/Rails versions, or
> browser-cache state between measured runs, and those values are not recoverable for that run. The absolute timing
> values may therefore include `RAILS_ENV=development` overhead (no eager loading, active code reloader, no asset
> caching), and unknown browser-cache state between measured runs affects repeatability. The single warmup request
> before each measured run may also be insufficient for the Pro Node renderer worker pool to reach JIT and
> RSC-payload-compilation steady state, which is more likely to make the RSC route look slower than its steady-state
> performance than to inflate its advantage. Treat these numbers as directional signals rather than a stable baseline.
> [Issue 3253](https://github.com/shakacode/react_on_rails/issues/3253) tracks a deployed/staging repeat that will
> publish full environment metadata; see [Environment metadata to capture for a new
> run](#gumroad-rsc-env-metadata-checklist) below for the required fields.

The median results showed this directional signal. The source artifact's navigation-duration metric comes from its
Playwright harness and may differ from `PerformanceNavigationTiming.duration`.

| Source  | Metric                                          | Inertia demo | RSC demo | Delta % (negative = RSC faster) |
| ------- | ----------------------------------------------- | -----------: | -------: | ------------------------------: |
| Browser | Navigation duration                             |        775ms |    607ms |                          -21.7% |
| Browser | Largest Contentful Paint                        |        794ms |    634ms |                          -20.2% |
| Browser | `responseEnd`                                   |        645ms |    589ms |                           -8.7% |
| Rails   | Controller `action_total` (Rails wall time) [†] |        347ms |    339ms |                           -2.3% |

[†] `action_total` scope is unconfirmed; do not use it to infer the server-rendering split — see the paragraph below.

`action_total` is the Rails wall-time field from the raw benchmark artifact, not a browser Performance API metric. The
artifact does not yet publish enough logger or extraction-script context to confirm whether it is the full
`process_action` duration including rendering or a narrower controller-action field, so do not use it to infer the
server-rendering split. Because the Pro Node renderer runs in a separate OS process, Rails wall time may also exclude
RSC rendering cost that the Inertia control keeps in-process, so the two `action_total` values may not measure identical
scopes of work. The source artifact publishes median and p95 for `responseEnd` but not for `action_total`;
[Issue 3263](https://github.com/shakacode/react_on_rails/issues/3263) tracks publishing per-run distribution data.

The navigation-duration gain (-21.7%) was larger than the `responseEnd` gain (-8.7%), which is consistent with the RSC
route delivering fully server-rendered HTML — the browser has minimal client-side hydration work after `responseEnd`,
while the Inertia control must hydrate the React component tree on the client. Because the navigation-duration value
comes from the source artifact's Playwright harness rather than `PerformanceNavigationTiming.duration`, the two metrics
are not from the same timing source and a direct `navigation duration - responseEnd` subtraction is not reported here.

The same April 30, 2026 benchmark also captured per-navigation resource bytes via the `PerformanceResourceTiming` API
for resources whose URL contains `/packs/` and ends in `.js`, plus the HTML response via
`PerformanceNavigationTiming`. Medians across n=8 measured runs per route:

| Metric                                                              | Inertia demo | RSC demo |
| ------------------------------------------------------------------- | -----------: | -------: |
| Page-specific JS requests (`/packs/*.js`)                           |            6 |        1 |
| Page-specific JS transfer (wire bytes)                              |      3,587 B |      0 B |
| Page-specific JS encoded body                                       |      3,287 B |      0 B |
| Page-specific JS decoded body                                       |     10,947 B |      0 B |
| HTML response transfer (`PerformanceNavigationTiming.transferSize`) |     14,523 B | 12,673 B |

These transfer-size values are warmed-cache wire bytes, not cold-cache bundle totals. The harness sends one warmup
request to the measured route before each measured run, which primes Chrome's HTTP disk cache so the Resource Timing
API reports `transferSize: 0` for assets already cached by the warmup. For the Inertia demo, 5 of the 6 `/packs/` JS
files (webpack-runtime, webpack-commons, two vendor chunks, and the inertia bundle) are served from disk cache on the
measured run; the freshly-fetched bytes (~3.3 KB compressed, ~10.9 KB decompressed) come from a route-specific page
chunk. For the RSC demo, the single page-specific JS file (the React on Rails Pro client bootstrap) is served from
cache on the measured run, so its measured `transferSize` is `0`.

The RSC route's Flight payload is not delivered as a separate `/rsc_payload/*` request in this benchmark; it is inlined
in the HTML response, so the HTML transfer column (12,673 B vs 14,523 B for the Inertia control) captures most of the
route-specific data delivered per navigation. The combined route-specific new bytes per warmed-cache navigation are
roughly ~18.1 KB for the Inertia control (~3.6 KB JS + ~14.5 KB HTML) and ~12.7 KB for the RSC demo (~0 KB JS + ~12.7 KB
HTML) — a ~30% warmed-cache wire-byte reduction, materially smaller than the -83% page-specific JS request-count
reduction implies. Cold-cache bundle totals (what a first-time visitor downloads before any caching kicks in) are not
captured by this benchmark methodology and remain a follow-up; see
[Issue 3259](https://github.com/shakacode/react_on_rails/issues/3259).

- _All timing values are medians from the raw benchmark artifact values (n=8 per route); sample size is too small to
  establish statistical significance._
- _The published `responseEnd` p95 (731ms Inertia vs 768ms RSC, see the
  [`responseEnd` p95 counter-signal](#gumroad-rsc-worst-case-responseend) below) is larger than the other route's
  median in both directions (Inertia p95 731ms > RSC median 589ms; RSC p95 768ms > Inertia median 645ms), so
  the per-run `responseEnd` ranges overlap and the median -8.7% RSC-favored delta is consistent with measurement noise
  rather than a stable RSC win on this metric._
- _The source artifact does not publish a p95 or per-run distribution for `action_total`, so its -2.3% median delta
  cannot be distinguished from measurement noise at n=8._

#### `responseEnd` p95 counter-signal {#gumroad-rsc-worst-case-responseend}

| Metric                  | Inertia demo | RSC demo | Delta % (negative = RSC faster) |
| ----------------------- | -----------: | -------: | ------------------------------: |
| `responseEnd` p95 (n=8) |        731ms |    768ms |                           +5.1% |

At n=8 the p95 is interpolated near the second-worst observed value rather than the maximum, but with only eight
samples it remains a coarse tail estimate rather than a stable population p95. It shows a +5.1% RSC regression on tail
`responseEnd` (high variance is expected at n=8), indicating the Inertia control had a faster tail
`responseEnd` than the RSC route on this run.

Use these numbers as a case-study signal, not a universal performance claim. The RSC route combines RSC, the Pro Node
renderer, and SSR, while the Inertia control has none of those three factors. With that caveat, the RSC route showed
faster median navigation duration and LCP on the measured routes. The `responseEnd` p95 counter-signal favored
the Inertia control. A stable deployed repeat, renderer-internal timing, environment metadata, and distribution artifacts
are still required before making stronger production-performance claims.

See [Issue 3128](https://github.com/shakacode/react_on_rails/issues/3128) and
[Issue 3144](https://github.com/shakacode/react_on_rails/issues/3144) for the ongoing tracking discussion.

#### Environment metadata to capture for a new run {#gumroad-rsc-env-metadata-checklist}

For any new local or staging Gumroad benchmark run, record the following so readers can calibrate the results. Missing
fields should be listed explicitly rather than left implied.

- **Environment:** `RAILS_ENV`, `NODE_ENV`
- **Hardware/OS:** machine model, CPU, RAM, OS version
- **Tool versions:** Ruby, Node.js, Rails, React on Rails, React on Rails Pro, Shakapacker, Rspack, Chrome, ChromeDriver
- **Cache state:** Rails fragment/SQL cache mode, browser cache behavior between measured runs (cold vs warm), Pro Node
  renderer cache state
- **Run protocol:** warmup requests per route, measured runs per route, alternation pattern, total wall-clock duration
- **Renderer setup:** dedicated vs shared Pro Node renderer, `RENDERER_PORT`, worker count, eager-loading status
- **Renderer-internal timing:** whether `config.tracing = true` was enabled on the Pro initializer, or `Server-Timing`
  was emitted for the RSC render/payload path
- **Distribution:** raw per-run values for each metric (not just medians), enough to publish variance and tail values

[Issue 3253](https://github.com/shakacode/react_on_rails/issues/3253) tracks applying this checklist to a stable
deployed/staging repeat.

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

## JSON Serialization Performance

React on Rails serializes component props to JSON before passing them to the JavaScript renderer. The performance of this serialization depends on which version of Ruby's `json` gem you have installed.

### Upgrading the JSON Gem

Ruby's bundled `json` gem (versions 2.5–2.7) is slower than it needs to be. Version 2.8.0 introduced a major performance rewrite that makes it **2x faster** for large payloads. To get this improvement, add to your `Gemfile`:

```ruby
gem 'json', '>= 2.8'
```

### Benchmark Results

For a ~3 MB props payload on Ruby 3.3:

| JSON Gem Version  | Serialization Time | Improvement     |
| ----------------- | ------------------ | --------------- |
| 2.7.2 (bundled)   | 21.5 ms            | Baseline        |
| 2.19.8 (upgraded) | 10.2 ms            | **2.1x faster** |

The improvement scales with payload size — approximately **3-4 ms saved per MB** of props data.

### When This Matters

This optimization is most impactful for:

- **Large component trees** with many props
- **Data-heavy pages** (dashboards, tables, lists)
- **Traditional SSR** where props are serialized before rendering

For typical pages with small props (under 100 KB), the difference is negligible (< 1 ms).

### Compatibility

JSON gem 2.19.8 (latest) supports Ruby 2.7+, so it works with all Ruby versions supported by React on Rails.

## Related Documentation

- [ExecJS Limitations](./execjs-limitations.md) — constraints of the default rendering engine
- [Streaming Server Rendering](../building-features/streaming-server-rendering.md) — setup and best practices
- [Code Splitting](../building-features/code-splitting.md) — route-based bundle splitting
- [Node Renderer Basics](../building-features/node-renderer/basics.md) — Pro Node.js renderer setup
- [OSS vs Pro](../getting-started/oss-vs-pro.md) — feature comparison
- [React Server Components](../../pro/react-server-components/index.md) — RSC overview and guides

# Performance Benchmarks

The point of this page is not to admire numbers. It is to help you **make a page measurably
faster and prove the win** — increasingly with an AI agent doing the conversion while a benchmark
harness keeps it honest.

The React on Rails v17 story (React 19.2, [React Server Components](../../pro/react-server-components/index.md),
[streaming SSR](../building-features/streaming-server-rendering.md), and the
[Node renderer](../building-features/node-renderer/basics.md)) is that an existing SSR or
client-rendered page can be converted to a faster rendering strategy — often by prompting a coding
agent — and the result can be verified with a trustworthy A/B benchmark instead of a hopeful
before/after. The rest of this page is the loop, the harness that proves it, the levers you pull,
and how to read the result without fooling yourself.

## The improve-and-prove loop

A modern performance change on React on Rails looks like this:

1. **Point an agent at a page.** "Convert the `home` page to React Server Components," or "move
   this dashboard's formatting libraries server-side." The [RSC performance skill](../migrating/rsc-performance-validation.md)
   and guides give the agent the conversion patterns.
2. **The agent converts the page** on a branch, keeping the same data, routes, and visual output.
3. **A paired A/B benchmark proves the win** — control (your default branch) versus experiment
   (the branch) — under production builds and mobile throttling, with a statistical test that
   survives a noisy laptop.

Step 3 is what makes the loop real rather than vibes. An agent iterating in a tight loop is running
on the _same machine_ it is benchmarking; conventional "run before, run after, compare the average"
measurement is dominated by that noise and will happily report a phantom win or hide a real
regression. The harness below is built to cancel that noise so the agent (and you) can trust the
number after every single change.

## Proving a change with ShakaPerf

[ShakaPerf](https://github.com/shakacode/shakaperf) is the ShakaCode benchmarking toolkit we use to
verify React on Rails performance work. It is source-available and public on
[npm](https://www.npmjs.com/package/shaka-perf) and [GitHub](https://github.com/shakacode/shakaperf).
The methodology is what matters — any harness that runs two production builds side by side under
identical throttling with paired sampling and a significance test gives the same signal — but
ShakaPerf packages the whole thing, so it is the path of least resistance.

### Twin dockerized servers take the noise out

ShakaPerf stands up **two production-mode servers side by side** in Docker:

- **Control** — built from your baseline branch (typically `main`). Your reference point.
- **Experiment** — built from your current branch. What you are measuring.

Both containers run the same data and configuration in production mode; the only difference is the
code on each branch (surfaced to the app as a `PERF_EXPERIMENT` environment variable). Because the
two servers are real, isolated builds running at the same time, you get a genuine side-by-side
comparison instead of "run the old code, change branches, rebuild, hope nothing else drifted."

```bash
# In your app, after a one-time twin-servers setup:
pnpm exec shaka-perf servers    # detect stale images → rebuild → start both containers → start servers
# Control:    http://localhost:3020
# Experiment: http://localhost:3030
```

### Paired, simultaneous sampling — no quiet machine required

The reason ShakaPerf is trustworthy on a developer laptop (or a shared CI box) is that it does not
try to average noise away. It **aligns the noise and subtracts it**:

- Each iteration measures control and experiment **at the same instant** (`Promise.all`), so both
  sides experience the same CPU contention, thermal state, and background interference. Whatever
  noise hits iteration `i` hits both samples equally.
- Analysis runs on the per-iteration **paired difference** `d[i] = control[i] − experiment[i]`,
  where the shared noise cancels. Significance is a **Wilcoxon signed-rank test** (with the exact
  null distribution for small `n`, so an 8-sample run can still reach significance), and the point
  estimate is the paired **Hodges-Lehmann** estimator. Both are non-parametric and robust to the
  heavy-tailed outliers Lighthouse produces.

The practical payoff: you do **not** need a dedicated quiet machine or a silent CI runner. Shared
noise cancels inside each pair, which is exactly what lets an agent benchmark reliably on the same
machine it is coding on. (The full statistical justification, including why paired Wilcoxon beats
Mann-Whitney U and Welch's t-test here, is in ShakaPerf's
[`used_statistics.md`](https://github.com/shakacode/shakaperf/blob/main/packages/shaka-perf/used_statistics.md).)

### What it measures

A single Playwright-based `abTest` definition drives every check. From it, ShakaPerf collects:

- **Core Web Vitals and load metrics:** FCP, LCP, TBT, CLS, Speed Index, TTFB, and INP.
- **Network/byte metrics:** total downloads and JavaScript bytes (with request counts and
  before-LCP variants), so a JavaScript-payload reduction shows up directly.
- **Custom timing marks:** any `performance.mark()` you emit. `hydration-start` and `hydration-end`
  are measured out of the box, which is how you see hydration cost move on an RSC conversion.
- **Visual regression:** screenshot diffs of control vs experiment across viewports, so "faster"
  is gated on "still the same page."
- **Accessibility (axe-core):** violations, so a conversion does not silently regress a11y.

### Running the comparison

```bash
# Perf + visual regression across both branches:
pnpm exec shaka-perf compare --categories perf,visreg \
  --controlURL http://localhost:3020 \
  --experimentURL http://localhost:3030 \
  --full-report-zip
```

Results land in `compare-results/` — `self-contained-performance-report.html` (a single portable
file to attach to a PR), `full-report.html`, and `report.json` for machine parsing; add
`--full-report-zip` to bundle everything into one archive. Key knobs live in an
`abtests.config.ts` file — `numberOfMeasurements` (default 20), `regressionThreshold` (default
50 ms), `pValueThreshold` (default 0.05), and `samplingMode` (default `simultaneous`). See
ShakaPerf's [twin-servers guide](https://github.com/shakacode/shakaperf/blob/main/packages/shaka-perf/README-twin-servers.md)
for the one-time Docker setup.

> [!NOTE]
> ShakaPerf is source-available under the ShakaPerf License (not MIT). It is **free** for reading
> and studying the source, a 45-day evaluation (agents welcome), education, personal projects,
> supporting public open-source projects, and production use by small organizations (under 10
> people **and** under $1M revenue **and** under $1M raised). Larger or funded organizations need a
> paid subscription. See [shakaperf.com](https://shakaperf.com) for terms and pricing. The
> methodology on this page applies to any equivalent paired-A/B harness.

### In-repo example

React on Rails uses ShakaPerf as a release gate for the RSC `'use client'` CSS fix — a real, small
`abTest` you can copy from. See
[`test/shakaperf/rsc-fouc/`](https://github.com/shakacode/react_on_rails/tree/main/test/shakaperf/rsc-fouc)
for the config and the `.abtest.ts` definition.

## The performance levers

Once you can prove a change, these are the levers with the largest payoff, roughly in order of
impact for a typical server-rendered React on Rails page. Each links to its deep dive.

### SSR engine: ExecJS vs the Node Renderer

The default ExecJS renderer evaluates JavaScript synchronously inside a single-threaded pool. The
[Node Renderer](../building-features/node-renderer/basics.md) (React on Rails Pro) runs a dedicated
Node.js master process with worker processes (default: one per CPU minus one), providing
dramatically better throughput.

| Metric            | ExecJS (mini_racer)           | ExecJS (Node.js runtime)        | Node Renderer (Pro)        |
| ----------------- | ----------------------------- | ------------------------------- | -------------------------- |
| Architecture      | V8 isolate in Ruby process    | New process per eval call       | Persistent Node.js workers |
| Concurrency (MRI) | Single-threaded (pool size 1) | Single-threaded (pool size 1)   | Multi-worker               |
| Async support     | None                          | None                            | Full (Promises, timers)    |
| Streaming SSR     | Not supported                 | Not supported                   | Supported                  |
| RSC support       | Not supported                 | Not supported                   | Supported                  |
| Relative speed    | Baseline                      | Slower (process spawn per eval) | Substantially faster       |

On MRI Ruby, `server_renderer_pool_size` must stay at 1 to avoid deadlocks (see
[ExecJS Limitations](./execjs-limitations.md)); JRuby can raise it. The Node Renderer's persistent
workers support full async rendering and multi-worker concurrency, which are the primary sources of
the difference — the gap widens for pages with many async data sources or large component trees.
[Popmenu measured a 73% response-time reduction](#popmenu) in production after switching to Pro;
the exact multiple is workload-dependent, so benchmark your own pages rather than quoting a headline
number.

### React Server Components: ship less JavaScript

[React Server Components](../../pro/react-server-components/index.md) (Pro) exclude server components
and their dependencies from the client bundle entirely:

```jsx
// These imports stay server-side — zero client cost
import { format } from 'date-fns'; // ~30KB
import { marked } from 'marked'; // ~35KB
import numeral from 'numeral'; // ~25KB
```

Server components produce HTML that needs **no hydration** — only client components (`'use client'`)
hydrate — which cuts Total Blocking Time and improves Time to Interactive. Applications that lean on
heavy formatting, parsing, or data-processing libraries on the server see the largest gains.
[Frigade reported a 62% reduction in client-side bundle size](https://frigade.com/blog/bundle-size-reduction-with-rsc-and-frigade)
after migrating to RSC. This is the conversion the improve-and-prove loop most often targets; see the
[RSC Performance Validation Playbook](../migrating/rsc-performance-validation.md).

### Streaming SSR and selective hydration

[Streaming SSR](../building-features/streaming-server-rendering.md) (Pro) uses React's
`renderToPipeableStream` to send HTML progressively as components resolve:

| Rendering Strategy                 | TTFB                      | Full Page Load              |
| ---------------------------------- | ------------------------- | --------------------------- |
| Client-side only                   | Fast (empty shell)        | Slow (fetch + render)       |
| Traditional SSR (`renderToString`) | Slow (waits for all data) | Fast (complete HTML)        |
| Streaming SSR                      | Fast (shell immediately)  | Progressive (chunks arrive) |

The browser gets the initial HTML shell immediately (fast TTFB) while data-dependent sections stream
in as they resolve — especially valuable for pages with multiple independent data sources. With
streaming and React 18+, components can hydrate independently as their JavaScript loads: navigation
can become interactive while main content is still streaming, and user interactions prioritize
hydration of the clicked component, so there is no single "hydration wall."

> [!NOTE]
> Selective hydration requires `:async` script loading. In **React on Rails Pro** apps on
> Shakapacker ≥ 8.2.0 this is already the default when the setting is unset — no initializer change
> is needed. Non-Pro apps default to `:defer` (which delays all hydration until streaming finishes),
> and `:async` is a Pro capability there. On Shakapacker < 8.2.0, script loading falls back to
> `:sync`. See [Selective Hydration in Streamed Components](../../pro/react-server-components/selective-hydration-in-streamed-components.md)
> and [Hydration Scheduling](../building-features/hydration-scheduling.md) for control over when
> individual islands hydrate.

### Caching, code splitting, and the smaller levers

- **[Caching](../building-features/caching.md):** prerender caching and fragment caching
  (`cached_react_component_hash`) can skip prop assembly, JSON serialization, and JavaScript
  evaluation on a warm hit. This is often the highest-leverage change for mostly static pages — and,
  as the next section explains, it sets the fair baseline any RSC conversion must beat.
- **[Code splitting](../building-features/code-splitting.md)** (Pro) and
  **[bundle caching](../building-features/bundle-caching.md)** (Pro) reduce initial and rebuilt
  JavaScript. Gains scale with how independent your routes are.
- **[React Compiler](../building-features/react-compiler.md)** adds build-time memoization with no
  source changes.
- **[Critical resource hints](../../pro/react-server-components/critical-resource-hints.md)**
  (`preload`, `preinit`, `preconnect`) let React itself prioritize the LCP resource, CSS, and fonts
  — a React-native alternative to hand-rolled `preload_pack_asset` tags.
- **JSON serialization:** see [JSON Serialization Performance](#json-serialization-performance) below.

## Reading the result honestly

A faster number is only a real win if it is the same page, measured against the right baseline, and
you understand _which_ metric moved.

### Decompose the metrics — do not just stare at LCP

The fix depends on which signals moved together:

| Signal                              | Likely cause                                                            | Where to look                                                                                             |
| ----------------------------------- | ----------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| **FCP and TBT both high**           | JS-bundle / hydration bound — the `'use client'` tail ships too much    | Reduce client boundaries ([chunk contamination](../migrating/rsc-troubleshooting.md#chunk-contamination)) |
| **LCP high while FCP is also high** | LCP is gated on a late FCP; the element is healthy but cannot paint yet | Fix FCP first by reducing client JS; LCP usually follows                                                  |
| **LCP high while FCP is healthy**   | The LCP element or its asset delivery is slow                           | Inspect the hero/image resource, CDN headers, preload/fetch priority                                      |
| **INP high in RUM**                 | Long client tasks delay input, often the same JS tail that raises TBT   | Follow the FCP/TBT path, verify with RUM or traces                                                        |

A high FCP dragging LCP behind it is the common RSC-conversion pattern: the largest element is
healthy, it just cannot paint until a late first render lets it. Fix FCP first.

### Benchmarking RSC against warm SSR caches {#benchmarking-rsc-against-warm-ssr-caches}

React Server Components reduce client JavaScript, hydration work, and duplicated data-fetching
paths. They do **not** automatically beat an already-warm SSR cache on every first-paint metric. If
the existing page uses [`cached_react_component` or `cached_react_component_hash`](../building-features/caching.md#level-2-fragment-caching),
the fair baseline is a warm fragment-cache hit. If it uses
[`config.prerender_caching = true`](../building-features/caching.md#level-1-prerender-caching)
without fragment caching, the fair baseline is a warm prerender-cache hit. Do not compare RSC
against an uncached SSR request unless that uncached state is the production baseline.

This matters most for mostly static public pages. On a fragment-cache hit, React on Rails Pro can
skip prop assembly, JSON serialization, and JavaScript evaluation. On a prerender-cache hit, props
are still assembled and serialized, but the JavaScript render result is reused. Either warm path can
be very hard for an RSC conversion to beat on TTFB, FCP, or LCP because there is little
server-rendering work left to remove.

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
```

An RSC experiment must keep the same data, release, device, locale, CMS state, CSS delivery, font
preloads, and hero/image priority before claiming that RSC changed rendering performance. Otherwise
the comparison is apples to oranges: a lower JavaScript payload can coexist with worse LCP if the
conversion delays CSS, fonts, or the LCP resource. This is exactly why the ShakaPerf harness gates
performance on **visual regression** in the same run — a faster page has to still be the same page.

Measure each cache state intentionally and label it in the report:

| Variant           | How to prepare it                                                                          | What it answers                                                                  |
| ----------------- | ------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------- |
| Cold uncached SSR | Clear fragment/prerender caches; measure the first request                                 | Cost of prop assembly, serialization, and JavaScript rendering before caching    |
| Warm cached SSR   | Prime the exact cache key, then measure repeated hits; log `RORP_CACHE_HIT` when available | Repeat-visitor steady state for the existing cached implementation               |
| RSC cold          | Clear relevant Rails/browser/renderer caches; measure the first RSC request                | First-hit cost of the RSC render, Flight payload generation, and asset discovery |
| RSC warm          | Prime the RSC route under the same data and cache policy; measure repeated navigations     | Steady state for RSC rendering, hydration, Flight payload, and cached assets     |

For RSC pages, also measure what moved into the HTML response. The initial Flight payload is usually
embedded in the HTML stream rather than fetched as a separate `/rsc_payload/*` resource, so you may
see fewer JavaScript requests while the navigation response grows. Pair JavaScript byte counts with
HTML transfer size, Flight payload bytes, FCP/LCP, TBT, and server/renderer timing before drawing
conclusions.

It is valid for an RSC migration to be a win on TBT and JavaScript bytes, a wash on LCP, and still
worth doing for maintainability or lower browser work. Say that plainly rather than framing a
warm-cache first-paint tie as a failure. For the full PR evidence checklist — same-machine
control/experiment, stable package stack, one variable per run, archived output — use the
[RSC Performance Validation Playbook](../migrating/rsc-performance-validation.md).

## Real-world results

> [!NOTE]
> Start with the public live demo, then the production case study. For a fully inspectable,
> side-by-side comparison of rendering strategies, use the Marketplace demo.

### Marketplace demo {#public-marketplace-rsc-demo}

The [Marketplace demo](https://rsc.reactonrails.com/) is a public, inspectable React on Rails Pro +
RSC demo showing the same page families rendered with traditional SSR, client rendering, and React
Server Components. See the [Live Demo and Evidence](../../pro/react-server-components/index.md#live-demo-and-evidence)
section for the canonical link inventory: performance showcase, raw Lighthouse reports, bundle-size
breakdowns, the `/why-rsc` walkthrough, and the demo source.

### Production case study: Popmenu {#popmenu}

Popmenu, a restaurant platform serving tens of millions of SSR requests daily, adopted React on
Rails Pro and reported:

- **73% decrease** in average response times
- **20-25% lower** Heroku hosting costs
- Stable performance under high traffic with the Node Renderer's worker pool

See the [full case study](https://www.shakacode.com/recent-work/popmenu/).

### Earlier directional experiment: Gumroad-style RSC demo

An earlier local A/B (April 2026) compared an Inertia-style control route against an RSC route in the
public [Gumroad-style demo repo](https://github.com/shakacode/react-on-rails-demo-gumroad-rsc). It
produced a directional RSC-favored signal on navigation duration and LCP, but the run predated the
paired-A/B methodology above — it used a single warmup, `n=8`, unrecorded environment metadata, and
showed a `responseEnd` p95 counter-signal — so it is not a stable baseline. It is preserved only as
an early data point; run a fresh paired comparison with ShakaPerf for any current claim.

## Measuring your own performance

### Key metrics to track

- **Time to First Byte (TTFB):** how quickly the server begins sending HTML
- **Largest Contentful Paint (LCP):** when the main content becomes visible
- **Total Blocking Time (TBT):** time the main thread is blocked during load
- **Client bundle size / JavaScript bytes:** total JavaScript downloaded
- **Server render time:** not logged by default — measure wall-clock time in Ruby around the render
  call; on Pro, enable `config.tracing = true` in `config/initializers/react_on_rails_pro.rb` to log
  render timings

### Tools

- **[ShakaPerf](https://github.com/shakacode/shakaperf):** paired twin-server A/B for a trustworthy
  branch-vs-branch verdict (the harness above)
- **[Performance tracks and profiling](../building-features/performance-tracks-and-profiling.md):**
  the React on Rails-specific profiling workflow and metric clusters
- **[Web Vitals and RUM](../building-features/web-vitals-and-rum.md):** field data from real users
- **Chrome DevTools Performance tab / Lighthouse:** ad-hoc profiling and Core Web Vitals scoring
- **`webpack-bundle-analyzer`:** visualize bundle composition and large dependencies
- **Rails server logs:** server-side console messages replayed to `Rails.logger` when
  `config.logging_on_server = true`
- **Node Renderer logs:** lifecycle and error detail via `RENDERER_LOG_LEVEL` (Pro)

## JSON Serialization Performance

React on Rails serializes component props to JSON before passing them to the JavaScript renderer.
The speed of that serialization depends on which version of Ruby's `json` gem you have.

Ruby's bundled `json` gem (2.5–2.7, as shipped with Ruby 3.3) is slower than it needs to be. Version
2.8.0 introduced a performance rewrite that makes it roughly **2x faster** for large payloads:

```ruby
gem 'json', '>= 2.8'
```

For a ~3 MB props payload on Ruby 3.3:

| JSON Gem Version  | Serialization Time | Improvement     |
| ----------------- | ------------------ | --------------- |
| 2.7.2 (bundled)   | 21.5 ms            | Baseline        |
| 2.19.8 (upgraded) | 10.2 ms            | **2.1x faster** |

The improvement scales with payload size — roughly **3-4 ms saved per MB** of props. It is most
impactful for large component trees, data-heavy pages (dashboards, tables, lists), and traditional
SSR where props are serialized before rendering. For typical pages with small props (under 100 KB),
the difference is negligible (< 1 ms).

React on Rails v17 requires Ruby ≥ 3.3, whose bundled `json` predates 2.8; on Ruby 3.4+ the bundled
gem is already 2.9+, so the explicit upgrade is unnecessary. The upgraded `json` gem supports all
Ruby versions React on Rails supports.

## Related documentation

- [RSC Performance Validation Playbook](../migrating/rsc-performance-validation.md) — the full PR evidence workflow
- [Performance Tracks and Profiling](../building-features/performance-tracks-and-profiling.md) — profiling workflow
- [Web Vitals and RUM](../building-features/web-vitals-and-rum.md) — field data from real users
- [Caching](../building-features/caching.md) — prerender and fragment caching (the warm-cache baseline)
- [Hydration Scheduling](../building-features/hydration-scheduling.md) — control when islands hydrate
- [Streaming Server Rendering](../building-features/streaming-server-rendering.md) — setup and best practices
- [Code Splitting](../building-features/code-splitting.md) and [Bundle Caching](../building-features/bundle-caching.md) — JavaScript reduction (Pro)
- [React Compiler](../building-features/react-compiler.md) — build-time memoization
- [Node Renderer Basics](../building-features/node-renderer/basics.md) — Pro Node.js renderer setup
- [ExecJS Limitations](./execjs-limitations.md) — constraints of the default rendering engine
- [OSS vs Pro](../getting-started/oss-vs-pro.md) — feature comparison
- [React Server Components](../../pro/react-server-components/index.md) — RSC overview and guides

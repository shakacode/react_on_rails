# React Performance Tracks and Profiling

React on Rails apps have three broad performance questions that look similar but need different tool clusters:

1. **What did the browser do?** Use Chrome DevTools Performance recordings with [React Performance Tracks](https://react.dev/reference/dev-tools/react-performance-tracks).
2. **What did the React on Rails Pro Node Renderer do?** Use the Node inspector and the renderer tracing integrations.
3. **What did real users experience?** Use field metrics such as [Web Vitals and Real User Monitoring](./web-vitals-and-rum.md).

React Performance Tracks are most useful when you can reproduce a slow interaction locally. They show React scheduler work, component render and effect durations, and, for React Server Components in development builds, server request and Server Component timing. They do not replace production telemetry, but they make the local trace much easier to read than a JavaScript stack alone.

## Choose the right profiling path

| Symptom                                              | Start with                                                                                                                                                     | Why                                                                                                                  |
| ---------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Slow click, navigation, or hydration in the browser  | Chrome DevTools Performance recording with React Performance Tracks                                                                                            | Shows React scheduler priority, component render cost, effects, network, layout, and paint on one timeline.          |
| A specific component renders too often               | React Components track, React DevTools, and optional `<Profiler>` boundaries                                                                                   | Shows component render/effect duration and, in development builds, prop changes for selected entries.                |
| Slow server rendering in the Pro Node Renderer       | [Profiling Server-Side Rendering Code](../../pro/profiling-server-side-rendering-code.md)                                                                      | Attaches Chrome DevTools to the Node process and records CPU work such as bundle upload, VM setup, and render calls. |
| Renderer breakpoints or request-by-request debugging | [Node Renderer Debugging](./node-renderer/debugging.md)                                                                                                        | Uses `--inspect`, renderer logs, and focused restarts for breakpoint debugging.                                      |
| Production SSR latency or error correlation          | [Error Reporting and Tracing](./node-renderer/error-reporting-and-tracing.md) and [OpenTelemetry](../../pro/node-renderer.md#observability-with-opentelemetry) | Captures spans and errors from live requests without attaching an inspector to production traffic.                   |
| Memory growth in the renderer                        | [Memory Leaks](../../pro/js-memory-leaks.md)                                                                                                                   | Uses heap snapshots and worker restart strategy instead of CPU flamegraphs.                                          |

## Record React Performance Tracks

Use this workflow for browser-side interaction, hydration, Suspense, and RSC timing investigations.

1. Run the app in development with React 19.2 or newer when your app supports that React line. For React on Rails Pro RSC apps, keep the React version supported by the current RSC guide and release notes; do not upgrade a generated RSC app only to capture Performance Tracks.
2. Install and enable the React Developer Tools browser extension when you want the Components track to include the full component tree.
3. Open Chrome DevTools, then open the **Performance** panel.
4. Start recording, reload the page or perform the slow interaction, then stop recording.
5. Inspect the React tracks alongside the normal browser tracks for network, JavaScript, layout, paint, and user timing.

React enables Performance Tracks automatically in development builds. In profiling builds, the Scheduler track is enabled by default. The Components track is limited to subtrees wrapped in `<Profiler>` unless the React DevTools extension is enabled. React's Server Components and Server Requests tracks are development-build only.

## Read the React tracks

The **Scheduler** track explains the priority and phase of React work:

- **Blocking** work usually comes from direct user interactions.
- **Transition** work comes from non-blocking updates scheduled with `startTransition`.
- **Suspense** work shows fallback and reveal timing.
- **Idle** work runs only after higher-priority work is clear.

Within those lanes, look for update, render, commit, and remaining-effect spans. A render followed by repeated updates or long effects often points to avoidable state changes, expensive effects, or missing memoization boundaries.

The **Components** track shows component render and effect durations as flamegraphs. Use it to answer:

- Which component subtree is expensive?
- Did the cost happen during render, layout effects, or passive effects?
- Did a selected component receive changed props that explain the render?

The **Server** tracks are relevant when you use React Server Components in development. The Server Requests track visualizes async work that flows into Server Components, and the Server Components tracks show the component work and awaited Promises. Treat these as React-level RSC timing: they do not include every Rails controller, Fastify, network, or renderer worker cost.

## Keep names readable

Profiles are only useful when component and function names survive the build.

- Prefer named functions and named component exports over anonymous inline components.
- Set `displayName` on components wrapped by helpers such as `memo` or `forwardRef` when the wrapper hides the useful name.
- Use a development build first. It gives the clearest component names and enables the full React development instrumentation.
- For a production-like profiling build, alias `react-dom/client` to `react-dom/profiling` at build time as described in the [React Performance Tracks docs](https://react.dev/reference/dev-tools/react-performance-tracks#using-profiling-builds), and preserve function/class names in that temporary build if minification erases useful labels. For Terser-style minifiers, that means profiling-only `keep_fnames` and `keep_classnames` settings or the equivalent setting in your bundler/minifier. Do not turn those knobs on blindly for production, since they can increase bundle size and reduce minification.

## Correlate browser and server work

For a local SSR/RSC investigation, collect one browser trace and one renderer trace for the same scenario:

1. Record the browser interaction with React Performance Tracks.
2. Record the renderer process with the [SSR profiling workflow](../../pro/profiling-server-side-rendering-code.md).
3. Compare timestamps, request logs, and component names. The browser trace shows hydration, interaction, Suspense, and paint timing. The renderer trace shows CPU spent before HTML or RSC payloads reach the browser.

If your server-rendered code needs its own named spans in a renderer CPU profile, add temporary User Timing marks around the code under investigation:

```js
performance.mark('ror:ssr:ProductSummary:start');
try {
  // Render or data preparation work under investigation.
} finally {
  performance.mark('ror:ssr:ProductSummary:end');
  performance.measure('ror:ssr:ProductSummary', 'ror:ssr:ProductSummary:start', 'ror:ssr:ProductSummary:end');
}
```

In the Pro Node Renderer VM, `performance` is available when `supportModules: true`; otherwise inject it with `additionalContext`. See [Runtime Globals for SSR and RSC](./node-renderer/js-configuration.md#runtime-globals-for-ssr-and-rsc).

## Use production telemetry for production questions

Do not attach `--inspect` to production traffic as your primary profiling strategy. It slows the renderer and changes the workload you are trying to measure.

Use production-safe instrumentation instead:

- [Web Vitals and RUM](./web-vitals-and-rum.md) for user-visible browser outcomes such as LCP, INP, CLS, FCP, and TTFB.
- [OpenTelemetry](../../pro/node-renderer.md#observability-with-opentelemetry) for SSR request spans from the Pro Node Renderer.
- [Error Reporting and Tracing](./node-renderer/error-reporting-and-tracing.md) for Sentry, Honeybadger, and custom tracing integrations.
- [Profiling Server-Side Rendering Code](../../pro/profiling-server-side-rendering-code.md) for short, local CPU profiling sessions when you can reproduce the slow path.

## Measuring an RSC conversion with a paired A/B

When you convert a page to React Server Components, the only honest way to know whether you regressed user-visible performance is a paired, throttled A/B comparison of the page before and after the conversion. The profiling workflows above tell you _where_ time goes inside one build; this workflow tells you whether the conversion moved the numbers that users feel.

### Why paired and throttled is mandatory

An unthrottled load on `localhost` will hide the regression almost entirely. Local hardware is fast and the network is effectively free, so the page is bound by main-thread and loopback timing that no real user shares. The regression only surfaces under Lighthouse mobile throttling, which models a phone on a slow connection:

- **Slow 4G** network throttling.
- **4x CPU** slowdown.

Sampling matters as much as throttling. A single server measured sequentially — control runs, then experiment runs — is noise-dominated: background load, thermal state, and JIT warmup drift between the two runs and swamp the effect you are trying to measure. Sample the two variants **simultaneously (paired)** instead, so each control sample shares its environment with the experiment sample it is compared against.

### Setup

Stand up two production-mode servers serving identical data and config, side by side:

| Variant        | Build                                                            |
| -------------- | ---------------------------------------------------------------- |
| **Control**    | Pre-RSC baseline (your default branch before the RSC conversion) |
| **Experiment** | RSC branch                                                       |

Then:

1. Build both variants in production mode on the same data and configuration.
2. Drive both with the **same throttled Lighthouse config** (Slow 4G + 4x CPU).
3. Collect **10 to 15 paired samples** per page so the comparison has reliable power. Six paired
   samples is only a weak smoke-test floor: with the two-sided exact Wilcoxon signed-rank test, you
   need unanimous agreement across all six pairs to reach p < 0.05 — one dissenting sample pushes
   you above it.
4. Report a **Wilcoxon signed-rank p-value**; treat **p < 0.05** as strong directional evidence of a real shift when the paired samples consistently move in the same direction.

We use [ShakaPerf](https://github.com/shakacode/shakaperf) for this — it brings up the twin production-local servers and runs the paired comparison with `shaka-perf compare --categories perf`. The methodology is what matters, not the tool: any harness that runs two production builds side by side under identical mobile throttling with paired sampling and a significance test gives you the same signal.

### Reading the result

Do not just stare at LCP. Decompose the metrics, because the fix depends on which ones moved:

| Signal                                    | Likely cause                                                                              | Where to look                                                                                                           |
| ----------------------------------------- | ----------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **FCP and TBT both high**                 | JS-bundle / hydration bound — the `'use client'` tail is shipping and executing too much  | Reduce client boundaries. See [Chunk Contamination](../migrating/rsc-troubleshooting.md#chunk-contamination).           |
| **LCP high while FCP is also high**       | LCP is gated on late FCP; the largest element may be healthy but cannot paint yet         | Fix FCP first by reducing client JS boundaries; LCP usually follows.                                                    |
| **LCP high while FCP is healthy**         | The LCP element or its asset delivery is slow                                             | Inspect the hero/image resource, asset host, CDN cache headers, preload/fetch priority, and responsive image selection. |
| **INP high in RUM or interaction traces** | Long client tasks delay input responsiveness, often from the same JS tail that raises TBT | Follow the FCP/TBT path, then verify the affected interactions with RUM or browser traces.                              |
| **CLS and Lighthouse score**              | Corroboration                                                                             | Use as secondary confirmation, not as the primary signal.                                                               |

A high FCP that drags LCP behind it is the common RSC-conversion pattern: the largest element is healthy, it simply cannot paint until the late first render lets it. Fix FCP first and LCP usually follows.

### Iterate

Treat each fix as one controlled change:

1. Apply one fix.
2. Rebuild the **experiment only** — the control stays fixed as your baseline.
3. Re-measure the paired comparison.
4. Repeat.

Because the control never moves, every change has a defensible before/after instead of a number you have to argue about.

### Case study: HiChee home and FAQ

A real RSC conversion of the HiChee `home` and `faq` pages, measured with a paired ShakaPerf A/B under Slow 4G + 4x CPU (p ≈ 0.03), shows the initial regression state that triggered investigation. These are not final shipped metrics; add your own post-fix rows after each client-boundary or CSS-delivery change.

| Page     | FCP          | LCP          | TBT              | Lighthouse       |
| -------- | ------------ | ------------ | ---------------- | ---------------- |
| **Home** | 2.0s → 9.3s  | 2.1s → 21.1s | 0 → 928ms        | 79 → 8.5         |
| **FAQ**  | 2.0s → 15.9s | 2.2s → 20.5s | — (not captured) | — (not captured) |

The FAQ run did not capture TBT or Lighthouse score. The captured signals pointed straight at the `'use client'` JS tail: FCP regressed on both pages, Home TBT blew up, and LCP was gated on late FCP because first render arrived far too late, not because the hero element itself was slow.

A CSS broadcast fix (react_on_rails_rsc [#108](https://github.com/shakacode/react_on_rails_rsc/pull/108) → [#110](https://github.com/shakacode/react_on_rails_rsc/pull/110) / [#113](https://github.com/shakacode/react_on_rails_rsc/pull/113), shipped in `react-on-rails-rsc` 19.2.0-rc.3) was correct, but it was a **second-order** effect. The dominant driver was the client JS tail, not CSS delivery. Chasing the CSS fix first would have spent effort without moving the metrics that mattered.

The lesson to take from this: **measure paired and throttled, then decompose FCP/TBT versus LCP before choosing a fix.** A related second-order CSS concern worth knowing about is the end-of-`<head>` rsc-css precedence trap described in [CSS and styling for RSC](../../pro/react-server-components/css-and-styling.md#rsc-stylesheet-cascade-order-end-of-head-precedence) — but confirm with the decomposition that CSS delivery is actually on your critical path before you spend time there.

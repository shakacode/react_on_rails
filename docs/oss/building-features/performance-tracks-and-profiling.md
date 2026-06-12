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

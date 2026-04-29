# React on Rails v16.3 — Production Readiness: All Bugs Found

**Date:** 2026-04-22  
**Method:** 25+ autonomous agents running real HTTP requests and Playwright browser tests against a live Rails 7.2 + React 19 + Node Renderer stack.  
**Total issues:** 65 bugs + 6 security config issues + 42 documentation gaps

---

## CRITICAL

**1. RSC Manifest Files Missing — All Streaming/RSC SSR Silently Broken**  
All 11 RSC/streaming pages return HTTP 200 but produce zero component content. The Node Renderer fails with `ENOENT` on `react-client-manifest.json` and `react-server-client-manifest.json` because the RSC webpack build doesn't generate them in dev mode. The failure is completely silent — pages embed a hidden `<template data-msg="Switched to client rendering...">` that only React sees. Users get blank content areas with no error indication. This affects `stream_async_components`, `rsc_posts_page_over_http`, `test_incremental_rendering`, and 8 more pages. Reproduction: `curl -s http://localhost:3199/stream_async_components | grep -o 'data-msg="[^"]*"'`

**2. No Progressive Streaming — Everything Delivered in One Chunk**  
All streaming pages deliver their entire ~17KB response in a single HTTP chunk at 0-1ms despite `Transfer-Encoding: chunked`. Zero progressive rendering occurs. Pages with explicit `sleep 1` calls for async props still return in 1ms with the async data entirely absent. The core streaming SSR feature doesn't actually stream in practice. This defeats the purpose of the entire streaming architecture.

**3. Arbitrary File Read via Node Renderer**  
With `supportModules: true`, an authenticated user can `require('fs')` in bundle code and read any file on the server. Demonstrated by reading `/etc/passwd` via HTTP 200 response. The VM sandbox doesn't restrict filesystem access.

**4. Full `process.env` Dump via Node Renderer**  
The `process` object is exposed in the VM context. Authenticated users can dump all environment variables (CI tokens, SSH info, paths) by sending `JSON.stringify(process.env)` as the renderingRequest.

**5. Worker Kill DoS via Node Renderer**  
`process.exit(1)` in a renderingRequest terminates the worker. Rapidly killing all workers causes full service disruption — all subsequent requests return HTTP 000 until workers respawn.

**6. Loadable Components Double Execution**  
`ChunkExtractor.getScriptTags()` and `javascript_pack_tag('client-bundle')` both load the same entry bundle, causing all JavaScript to execute twice. Confirmed by source-track agent tracing the exact overlap.

**7. EADDRINUSE Infinite Restart Loop**  
If port 3800 is already bound when the Node Renderer starts, workers crash and restart in an infinite loop (286 crash-loops per 15 seconds). The compiled `lib/` was missing `startupErrorHandler.js`. Fix exists in source but requires recompilation.

---

## HIGH

**8. SSR Timeout Compounding — 10s Config Becomes 50s Wait**  
`ssr_timeout: 10` results in a 50-second wall-clock wait. Two retry layers compound: HTTPX plugin retries (`max_retries: 1`) x manual retry loop (`renderer_request_retry_limit: 1`) = `10 * 2 * 2 + overhead = ~50s`. This can exhaust all Puma worker threads in production. Reproduction: `curl -sL http://localhost:3199/stress_ssr_timeout -w "HTTP %{http_code} in %{time_total}s\n"` returns HTTP 500 in 50.7s.

**9. Redux Store Leak Between Turbo Navigations**  
`unmountAllStores()` clears `storeRenderers` but never calls `clearHydratedStores()`. The function exists in `StoreRegistry.ts` but is never imported or called anywhere. Stores from previous pages persist and serve stale data to components on new pages after Turbo navigation.

**10. Stale `railsContext` in OSS After Turbo Navigation**  
The OSS `unmountAllComponents()` in `ClientRenderer.ts` does NOT call `resetRailsContext()`. The Pro package already has this fix. After Turbo navigation, OSS users get stale `i18nLocale`, `pathname`, `href` values. One-line fix: add `resetRailsContext()` to `unmountAllComponents()`.

**11. Cached Component HTML Served in Wrong Locale**  
SSR HTML cached in one locale is served when pages are requested in a different locale. The cache key doesn't include the locale, so French-rendered HTML is served to English users.

**12. Retry Storm Under Concurrency — No Circuit Breaker**  
No circuit breaker exists in the Node Renderer request handler. With `renderer_request_retry_limit: 5`, timed-out requests retry and multiply load on an already overwhelmed renderer, turning a slowdown into a complete outage.

**13. Turbolinks Loaded But Not Initialized**  
The Turbolinks JS bundle is loaded and `data-turbo-track` attributes exist on 13 elements, but `window.Turbolinks` is undefined at runtime. All navigation does full page reloads instead of SPA-style replacement. Verified with Playwright by setting a window marker and confirming it's gone after clicking a sidebar link.

**14. `performance` Not Defined in VM Context**  
The Node Renderer's VM sandbox provides timer polyfills but omits the `performance` global that React's Suspense scheduler uses. `/stream_native_metadata` and `/hybrid_metadata_streaming` fail SSR with `ReferenceError: performance is not defined`, falling back to client render with a visible flash.

**15. Password Leaked in Protocol Version Error**  
Protocol version check runs before authentication. A request with missing `protocolVersion` reflects the full request body (including the password) in the error response.

**16. Cached Streaming Caches Error State (Cache Poisoning)**  
`cached_stream_react_component` caches whatever the server renders, including error states. If the first render fails (e.g., transient Node Renderer outage), the broken output is cached and served to all subsequent users until the cache expires. The cache key doesn't account for rendering failures.

---

## MEDIUM

**17. CSP Nonces Stale in Cached Fragments**  
`<script nonce="...">` tags in console replay scripts are cached on the first render. On cache hits, the stale nonce from the original request is served, causing Content Security Policy violations in production.

**18. Auth Handler Timing Leak**  
The Node Renderer auth handler returns early before `timingSafeEqual` when buffer lengths differ, leaking password length via response timing.

**19. Node Renderer Requires Node 20+ But Doesn't Enforce**  
Node 18 crashes with `diagnostics.tracingChannel is not a function` (Fastify dependency). The minimum Node version is not checked at startup and not documented.

**20. `cached_react_component` Mutates Caller's Options Hash**  
`sanitized_options = raw_options` is a reference, not a copy. The helper mutates the caller's hash. Inconsistent with streaming/async helpers that correctly use `.merge`.

**21. Path Traversal in `/asset-exists`**  
`../../../../../etc/passwd` traversal via the `filename` query parameter confirms file existence on the server. The endpoint uses `authenticate()` directly instead of `performRequestPrechecks()`.

**22. No Rate Limiting on Node Renderer Auth Failures**  
100 concurrent brute-force attempts complete instantly with no blocking or lockout.

**23. Stream Cache Stampede**  
`cached_stream_react_component` uses non-atomic read-then-write (`Rails.cache.read` + render + `Rails.cache.write`). Under concurrent cold-cache requests, all N requests trigger independent SSR renders.

**24. TanStack Router Hydration Mismatch**  
Server renders route content directly but client wraps in `<Suspense fallback={null}>`. React discards the server HTML and re-renders the entire tree on the client.

**25. Image Example Hydration Mismatch — Broken Images**  
Server renders image `src` as relative paths, client hydrates with `/webpack/development/` prefix. All 4 images show as broken 404s.

**26. Loadable Component ReactOnRails Global Mismatch**  
Visiting `/loadable` throws "ReactOnRails global object mismatch detected" — the loadable component renders nothing. react-on-rails core is being mixed with react-on-rails-pro.

**27. Cache Demo Hydration Mismatch**  
Cached timestamp from server diverges from client `Date.now()`, causing hydration failure. React regenerates the entire tree, negating caching benefits.

**28. React Router 404s Return HTTP 200**  
Non-existent routes in the React Router app return HTTP 200 with "404 Not Found" in the body. No proper status code for SEO.

**29. `connection_pool` 3.0.2 Incompatible with Ruby 3.3.0**  
`connection_pool` 3.0.2 uses anonymous keyword rest parameter syntax in blocks — a SyntaxError on Ruby 3.3.0 (fixed in 3.3.1+). Blocks Rails startup entirely.

---

## LOW

**30. RSC Payload Data Accumulates in Global Object (Memory Leak)**  
`window.REACT_ON_RAILS_RSC_PAYLOADS` accumulates RSC flight data across Turbo navigations and is never cleaned up. Each page adds entries; flight data strings can be kilobytes per component.

**31. `hydratedStores` Never Cleared (Memory Leak)**  
In both core and Pro `StoreRegistry.ts`, hydrated Redux store instances persist across Turbo navigations. Page unload callbacks unmount React roots but never call `clearHydratedStores()`.

**32. `CallbackRegistry.notUsedItems` Accumulates**  
The `notUsedItems` Set tracks registered-but-unused items. It's not cleared during page unload, only via `clear()`.

**33. `/info` Endpoint Exposes Versions Without Auth**  
Node and renderer versions available to unauthenticated users.

**34. `NODE_ENV` Defaults to `'production'` in Renderer**  
Breaks the development-mode version mismatch check.

**35. Two Auto-Bundled Components Return 500**  
`/context_function_return_jsx` and `/pure_component_wrapped_in_function` — auto-generated bundle packs were never created.

**36. Double Caching**  
View-level and prerender-level caches independently store different representations of the same content when both `cached_stream_react_component` and `prerender_caching` are enabled.

---

## Security (Dummy App Config — Relevant if Pattern is Copied)

**37-42.** GraphQL backtrace leak, GraphQL CSRF disabled, REST API CSRF disabled, Rails debug endpoints exposed, GraphiQL accessible, no query complexity limits. These are development defaults but the docs/generators don't warn about securing them in production.

---

## Previously Missing (added after cross-check)

### Medium

**43. Async Component Cache Stampede (separate from stream cache)**  
`cached_async_react_component` uses the same non-atomic `Rails.cache.read` + render + `Rails.cache.write` pattern. Unlike the streaming variant, this IS fixable by switching to `Rails.cache.fetch` since the result is a complete string. Source: `react_on_rails_pro/app/helpers/react_on_rails_pro_helper.rb:377-407`.

**44. `dependencies_cache_key` Permanently Memoized**  
In non-development environments, `@dependency_checksum` is permanently memoized after first computation. Requires server restart after dependency file changes. No cache invalidation mechanism.

**45. Cache Write Failure Crashes Streaming Response**  
If `Rails.cache.write` fails in the `on_complete` callback for `cached_stream_react_component`, it crashes the streaming response even though the HTML was already successfully delivered to the client.

**46. No ChunkLoadError Recovery for Code Splitting**  
Failed dynamic `import()` chunk loads have no retry mechanism. Network glitches cause permanent broken pages until the user hard-refreshes. No `ChunkLoadError` boundary or retry logic exists.

**47. Null Byte Injection Leaks Server Paths**  
Sending `test%00null` in the `bundleTimestamp` to the Node Renderer causes an error that reveals the full server directory structure in the error response.

**48. `/asset-exists` Skips Protocol Version Check**  
The `/asset-exists` endpoint uses `authenticate()` directly instead of `performRequestPrechecks()`, bypassing the protocol version validation that other endpoints enforce.

**49. URL-Encoded Body Bypasses `fieldSizeLimit`**  
The Node Renderer's 10MB `fieldSizeLimit` only applies to multipart uploads. URL-encoded bodies bypass this limit entirely.

**50. RSC Payload Fetch "Connection Closed" Error**  
`/async_on_server_sync_on_client_client_render` produces a distinct JS error: "Failed to fetch RSC payload for component 'SimpleComponent': Connection closed." The RSC payload endpoint terminates the connection before delivering data.

**51. SSR Crash Fallback Hydration Mismatch**  
When SSR crashes and falls back to client render, the server renders a `<pre>` error tag but the client renders a `<div>`. This hydration mismatch causes React to discard and re-render the entire tree.

**52. Error Boundary Pages Render Blank — No Fallback UI**  
`/stream_error_demo` and `/stream_shell_error_demo` show zero visible content. No error boundary UI is rendered; the error handling path produces no user-visible feedback at all, just a blank page.

**53. Incremental Rendering Delivers No Async Data**  
`/test_incremental_rendering` renders only the heading; the async props data (books, researches) from `stream_react_component_with_async_props` with `sleep 1` never appears in the response or DOM. The async emission protocol fails silently.

**54. Slow Loris DoS — No `first_data_timeout` in Puma**  
Puma accepts connections and waits 30s for complete headers with no timeout. With only 10 threads (2 workers x 5 threads), 10 slow connections exhaust the server. Reproduction: send partial headers at 1 byte/sec, server waits 30s then serves 200.

**55. `railsContext` Echoes URL Input and Discloses Versions**  
The `js-react-on-rails-context` JSON block echoes attacker-controlled URL components (`href`, `location`, `search`) and discloses `rorVersion`, `rorProVersion`, and `railsEnv` on every page.

**56. ExecJS Returns Empty Object for Async Render Functions**  
When using ExecJS (not Node Renderer), async render functions return `{}` instead of actual content. This limitation isn't documented — developers may build async components that silently fail on ExecJS.

**57. Rspack Has No End-to-End Build Test**  
The `--rspack` generator option exists with config templates, but no CI pipeline or integration test exercises an actual Rspack build. Regressions could ship undetected.

**58. 404 Pages and Error Fallbacks Leak Stack Traces**  
When `raise_on_prerender_error: false`, the error fallback HTML includes full stack traces with gem versions and file paths, visible in the page source.

### Low

**59. `Array.push` Monkey-Patch in RSC Never Restored**  
`createRSCStreamFromArray` replaces the native `push` method on each payload array with a closure capturing a `ReadableStreamController`. Combined with the `REACT_ON_RAILS_RSC_PAYLOADS` global leak (#30), these closures persist indefinitely.

**60. `pageLifecycle` Event Listeners Never Removed**  
3 permanent `document.addEventListener` calls for page lifecycle events are added but never cleaned up with `removeEventListener`.

**61. `replayConsole` Appends Unremoved Script Elements**  
Console replay injects `<script>` elements into the DOM that accumulate across navigations without cleanup.

**62. `CallbackRegistry.registeredItems` Leaks on HMR**  
Hot module replacement re-registers components but stale references from previous registrations persist in the registry.

**63. Store Dependencies Are Page-Level, Not Per-Component**  
`data-store-dependencies` on each component includes ALL stores registered on the page, not just the ones that component uses. Could delay hydration on pages with many stores.

**64. `redis_receiver_for_testing` Requires Undocumented Parameter**  
`/redis_receiver_for_testing` returns HTTP 500 with "request_id is required at the url" — the required parameter is not documented in the route definition.

**65. `dependency_checksum` and `bundle_hash` Race on First Request**  
Class-level memoization without mutex means multiple threads on first request(s) redundantly compute the same deterministic values. No data corruption, but wasted filesystem I/O.

---

## Documentation Gaps

42 gaps identified (6 Critical, 14 High), 24 fixed across 12 doc files. Key unfixed gaps:

- Streaming SSR without RSC has no documented component pattern
- "Async Props" is completely undocumented as a concept
- TanStack Router docs don't match actual API
- Build pipeline order (generate_packs before webpack) undocumented
- No basic Turbo Drive navigation example

Full docs analysis: `production_readiness/reports/docs-gaps-master.md`

---

## What Works Well

- **Basic SSR**: All non-RSC server-rendered pages work correctly
- **Redux SSR**: Shared stores, large state (10K items, 1.2MB), Unicode, XSS protection — all pass
- **React Router SSR**: Nested routes, hydration data, client navigation — all pass
- **React 19 Metadata**: Title hoisting, deduplication — works
- **Fragment Caching**: Cache key strategies, conditional caching, invalidation — all correct
- **Auto-Bundling**: 52 packs, component discovery, staleness detection — fully functional
- **i18n**: Locale generation, nested YAML, runtime switching — works
- **Concurrent Load**: 50 simultaneous SSR requests — all 200, no corruption
- **Error Recovery**: SSR crash fallback to client render — works
- **Client Disconnect**: Server handles mid-stream disconnects gracefully
- **XSS Protection**: All special characters properly escaped in SSR output
- **Node Renderer Under Load**: 50 concurrent renders at 12-121ms latency

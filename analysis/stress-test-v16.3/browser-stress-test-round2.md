# Browser Stress Test Round 2

**Date:** 2026-04-23
**App:** react_on_rails_pro spec/dummy on Rails 7.2, React 19, react_on_rails v16.5.1
**Method:** Playwright (chromium headless), 64 routes tested, screenshots captured
**Server:** Rails on :3199, Node Renderer on :3800 (2 workers)

---

## New Bugs Found

### BUG-R2-01: All RSC/streaming pages fail SSR — missing react-client-manifest.json

**Routes:** `/stream_async_components`, `/stream_async_components_for_testing`, `/cached_stream_async_components_for_testing`, `/test_incremental_rendering`, `/stream_async_components_for_testing_client_render`, `/rsc_posts_page_over_http`, `/rsc_posts_page_over_redis`, `/rsc_echo_props`, `/rsc_native_metadata`, `/async_on_server_sync_on_client`, `/async_on_server_sync_on_client_client_render`, `/stream_error_demo`, `/stream_shell_error_demo` (13 routes total). Navigated to each page. Every one throws `ENOENT: no such file or directory, open '.../.node-renderer-bundles/.../react-client-manifest.json'` and `react-server-client-manifest.json`. SSR fails completely; pages fall back to client-side rendering (or render blank). The webpack build warns "Client runtime at react-on-rails-rsc/client was not found. React Server Components module map file react-server-client-manifest.json was not created." This means the RSC webpack config is not generating the required manifest files. Evidence: 7-9 console.error per page, 2 uncaught exceptions per page, screenshots at `screenshots/rsc_*.png` and `screenshots/stream_*.png`.

### BUG-R2-02: /stream_error_demo and /stream_shell_error_demo render blank — no error boundary UI visible

**Routes:** `/stream_error_demo`, `/stream_shell_error_demo`. Navigated to each page. The main content area is completely empty (0 visible characters in `.app-main-content`). Despite being "error demo" pages, no error boundary UI, fallback message, or error text is shown to the user. Only the sidebar renders. Console shows 9 errors and 2 uncaught exceptions (all the manifest errors from BUG-R2-01). Screenshots: `screenshots/stream_error_demo.png`, `screenshots/stream_shell_error_demo.png`.

### BUG-R2-03: /stream_native_metadata and /hybrid_metadata_streaming crash with "performance is not defined"

**Routes:** `/stream_native_metadata`, `/hybrid_metadata_streaming`. Navigated to each page. Uncaught error: `Switched to client rendering because the server rendering errored: performance is not defined`. The Node renderer's SSR environment doesn't provide the `performance` global, causing the component to crash during server rendering. Falls back to client render. Pages render content via client-side only. Screenshot: `screenshots/stream_native_metadata.png`.

### BUG-R2-04: /image_example has 4 broken images and hydration mismatch

**Route:** `/image_example`. Navigated to the page. 4 images return 404 Not Found — their `src` attributes use paths like `/static/assets/images/256egghead-56c6d1ce61e86e0d344e.png` and `/static/components/ImageExample/bower-84b294626064a0c1f5a5.png` which don't exist at those URLs. Also triggers a React hydration mismatch warning: "A tree hydrated but some attributes of the server rendered HTML didn't match the client properties." The large Google SVG logo loads fine. Screenshot: `screenshots/image_example.png`.

### BUG-R2-05: /loadable/ throws ReactOnRails global object mismatch error

**Route:** `/loadable/`. Navigated to the page. Uncaught error: `ReactOnRails global object mismatch detected. The current global ReactOnRails object is different from the one created by this package. This usually means: 1. You're mixing react-on-rails (core) with react-on-rails-pro`. The loadable chunk likely imports `react-on-rails` core while the main bundle uses `react-on-rails-pro`, causing the global mismatch. The page shows the server code source but the component doesn't render interactively. Screenshot: `screenshots/loadable_.png`.

### BUG-R2-06: Three routes return HTTP 500 — auto-loaded bundle missing for legacy components

**Routes:** `/context_function_return_jsx`, `/pure_component_wrapped_in_function`, `/react_helmet_broken`. Navigated to each. All return HTTP 500 with `ReactOnRails::SmartError: Auto-loaded Bundle Missing`. The components (`ContextFunctionReturnInvalidJSX`, `PureComponentWrappedInFunction`, `ReactHelmetAppBroken`) are referenced in views but don't exist in `ror-auto-load-components/`. The SmartError page has good diagnostics (expected path, suggested fix), but these routes are broken. Screenshot: `screenshots/500_detail__context_function_return_jsx.png`.

### BUG-R2-07: No progressive streaming — all streaming pages arrive in a single chunk

**Routes:** `/stream_async_components`, `/stream_async_components_for_testing`, `/test_incremental_rendering`, `/stream_native_metadata`. Used raw HTTP `http.get` to check `Transfer-Encoding: chunked` and count data chunks. All pages use `Transfer-Encoding: chunked` but deliver the entire response in exactly 1 chunk (15-17KB). Non-streaming pages (`/server_side_hello_world`) also deliver in 1 chunk. This means there is no observable progressive streaming — the response doesn't trickle in over time as async components resolve.

### BUG-R2-08: 61 pages emit client bundle optimization warnings

**All pages.** Every page logs two console warnings: `Optimization opportunity: "react-on-rails" includes ~14KB of server-rendering code. Browsers may not...` and the same for `react-on-rails-pro`. This indicates the client bundle includes server-only code that bloats the browser download. Not a crash bug but a significant bundle size issue for production.

### BUG-R2-09: 40 pages emit outdated JSX transform warning

**Most pages.** 40 out of 64 pages log: `Your app (or one of its dependencies) is using an outdated JSX transform. Update to the modern JSX transform...`. This indicates the babel/webpack config is not using the automatic JSX runtime.

### BUG-R2-10: /rsc_echo_props generates 54 console errors and 12 uncaught exceptions

**Route:** `/rsc_echo_props`. Navigated to the page. The page renders 6 different RSC echo components (testing special characters in props like backticks, template syntax, dollar signs). Each one independently fails with the manifest ENOENT error and falls back to client render, generating 54 total console errors and 12 uncaught exceptions. The page eventually renders via client-side fallback but the error storm is extreme. Screenshot: `screenshots/rsc__rsc_echo_props.png`.

### BUG-R2-11: /server_side_log_throw_plain_js shows server-side TypeError details in browser console

**Route:** `/server_side_log_throw_plain_js`. Navigated to the page. 4 console errors appear, including the full server-side JavaScript source code and stack trace: `TypeError: ReactOnRails.getComponent(...).world is not a function at evalmachine.<anonymous>:11:54`. While this is an intentional error-throwing demo, the server code and internal paths are fully visible in the browser console, which could be a security concern in production.

---

## Known Bugs Verified

### #1 — All RSC/streaming pages render blank (manifest missing)
**Still exists: YES** — 13 routes affected. Root cause: webpack RSC build does not generate `react-client-manifest.json` or `react-server-client-manifest.json`. The build outputs a warning about this. See BUG-R2-01.

### #2 — No progressive streaming
**Still exists: YES** — All streaming pages deliver the full response in a single chunk despite using `Transfer-Encoding: chunked`. See BUG-R2-07.

### #3 — Turbolinks not initialized
**NO LONGER EXISTS** — With `?enableTurbolinks=true`, `window.Turbolinks` is now defined and Turbolinks intercepts navigation correctly. Tested navigation between sidebar pages — no full page reload detected.

### #4 — TanStack Router hydration mismatch
**CHANGED** — No hydration mismatch error detected in the console. The page renders correctly with 2453 chars of content. However, the hydration test flagged a debug log (`RENDERED TanStackRouterAppAsync to dom node`) that was picked up by the keyword filter. The actual hydration works cleanly.

### #5 — Image example broken images
**Still exists: YES** — 4 images return 404. Paths use `/static/` prefix that doesn't map to any served directory. See BUG-R2-04.

### #6 — Loadable component "global mismatch" error
**Still exists: YES** — `ReactOnRails global object mismatch detected` error. See BUG-R2-05.

### #7 — Cache demo hydration mismatch
**NO LONGER EXISTS** — `/server_side_redux_app_cached` renders the same content on repeated loads. No hydration errors detected. Cache content matches fresh content.

### #8 — `performance is not defined` on streaming metadata pages
**Still exists: YES** — `/stream_native_metadata` and `/hybrid_metadata_streaming` both crash with this error. See BUG-R2-03.

### #9 — SSR timeout takes 50s instead of 10s
**NOT REPRODUCED** — `/server_render_with_timeout` loaded in 730ms. Could not reproduce the 50s delay. The ssr_timeout config is set to 10s and seems to be working.

### #10 — Error demo pages render blank
**Still exists: YES** — `/stream_error_demo` and `/stream_shell_error_demo` show completely blank content areas. See BUG-R2-02.

---

## Docs/Generator Issues Encountered

**RSC webpack config produces no manifest files** — The build logs `WARNING: Client runtime at react-on-rails-rsc/client was not found. React Server Components module map file react-server-client-manifest.json was not created.` There is no documentation explaining what additional webpack configuration is needed to generate the RSC manifest files, or whether a separate build step is required.

**SmartError for missing components is good but routes shouldn't reference missing components** — The error page for `/context_function_return_jsx` etc. has excellent diagnostics (expected path, suggested solution), but the routes.rb and views reference components that were never created in `ror-auto-load-components/`. This suggests these are legacy test routes that were never updated to match the current component structure.

**`uri` gem version conflict blocks `pnpm run build:dev`** — Running `pnpm run build:dev` fails with `You have already activated uri 1.1.1, but your Gemfile requires uri 1.0.3`. Requires manually uninstalling the conflicting uri gem version. The Gemfile should pin `uri` or the binstub should handle this gracefully.

---

## Pages That Work Perfectly

The following 41 routes render correctly with no console errors, no hydration issues, proper SSR content (where applicable), and functional interactivity:

- `/` (root — multiple components, sidebar navigation)
- `/empty` (intentionally empty)
- `/client_side_hello_world`
- `/client_side_hello_world_shared_store` (Redux input propagation works)
- `/client_side_hello_world_shared_store_controller`
- `/client_side_hello_world_shared_store_defer`
- `/server_side_hello_world` (SSR verified with JS disabled — 2921 chars visible)
- `/server_side_hello_world_hooks`
- `/server_side_hello_world_shared_store`
- `/server_side_hello_world_shared_store_controller`
- `/server_side_hello_world_shared_store_defer`
- `/server_side_hello_world_es5`
- `/server_side_redux_app`
- `/server_side_redux_app_cached` (caching works, content matches across reloads)
- `/server_side_hello_world_with_options`
- `/server_side_log_throw` (intended error handling works)
- `/client_side_manual_render`
- `/render_js`
- `/pure_component`
- `/css_modules_images_fonts_example`
- `/turbolinks_cache_disabled`
- `/rendered_html`
- `/xhr_refresh`
- `/react_helmet` (SSR metadata works)
- `/broken_app` (error boundary catches and displays sidebar)
- `/server_render_with_timeout` (loaded in 730ms)
- `/posts_page`
- `/react_router/` (client navigation and back button work)
- `/tanstack_router_async/` (renders, hydrates, navigates cleanly)
- `/cached_react_helmet`
- `/cached_redux_component`
- `/apollo_graphql`
- `/lazy_apollo_graphql`
- `/console_logs_in_async_server` (server logs replayed to browser console)
- `/server_router/` (navigation works)
- `/server_router_client_render/` (navigation works)
- `/async_render_function_returns_string`
- `/async_render_function_returns_component`
- `/async_components_demo` (renders with async content)
- `/native_metadata` (title and 5 meta tags rendered correctly)

**Navigation stress test:** Rapidly navigated 16 pages in sequence — 0 navigation errors, 0 console errors, memory stable at 33.5MB.

**Recovery test:** After visiting `/broken_app`, navigating to `/server_side_hello_world` works correctly — app recovers fully from error states.

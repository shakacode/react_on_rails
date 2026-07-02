# Change Log

All notable changes to this project's source code will be documented in this file. Items under `Unreleased` is upcoming features that will be out in the next version.

> **This is the unified changelog for both React on Rails (open source) and React on Rails Pro.**
> Pro-specific changes are tagged inline with **[Pro]**. For pre-monorepo Pro history (versions 4.0.0-rc.15 and earlier), see the [archived Pro CHANGELOG](https://github.com/shakacode/react_on_rails_pro/blob/4.0.0/CHANGELOG.md).

Migration instructions for the major updates can be found [here](https://reactonrails.com/docs/upgrading/upgrading-react-on-rails#upgrading-to-version-9). Some smaller migration information can be found here.

## Want to Save Time Updating?

If you need help upgrading `react_on_rails`, `webpacker` to `shakapacker`, or JS packages, contact justin@shakacode.com. We can upgrade your project and improve your development and customer experiences, allowing you to focus on building new features or fixing bugs instead.

For an overview of working with us, see our [Client Engagement Model](https://www.shakacode.com/blog/client-engagement-model/) article and [how we bill for time](https://www.shakacode.com/blog/shortcut-jira-trello-github-toggl-time-and-task-tracking/).

If you think ShakaCode can help your project, [click here](https://meetings.hubspot.com/justingordon/30-minute-consultation) to book a call with [Justin Gordon](mailto:justin@shakacode.com), the creator of React on Rails and Shakapacker.

## Contributors

Please follow the recommendations outlined at [keepachangelog.com](http://keepachangelog.com/). Please use the existing headings and styling as a guide.
After a release, run `/update-changelog` in Claude Code to analyze commits, write entries, and create a PR. Alternatively, run `bundle exec rake update_changelog` to add version headers only (you must write entries manually).

## Versions

### [Unreleased]

#### Added

- **Generated Rails response TypeScript contracts**: Rails apps can now register explicit JSON response
  contracts with `ReactOnRails::TypeScriptResponseTypes` and run
  `rake react_on_rails:generate_response_types` to emit importable `.d.ts` declarations plus a
  `RailsResponseTypes` lookup map for TanStack Query clients. Fixes
  [Issue 4247](https://github.com/shakacode/react_on_rails/issues/4247). [PR 4259](https://github.com/shakacode/react_on_rails/pull/4259) by [justin808](https://github.com/justin808).

- **Typed Rails action callers for TanStack Query mutations**: The `react-on-rails/railsAction`
  subpath now exports `createRailsAction`, a same-origin JSON caller that attaches Rails CSRF headers and
  lets mutation code type responses with the generated `RailsResponseType<'controller.action'>` lookup.
  Fixes [Issue 4248](https://github.com/shakacode/react_on_rails/issues/4248). [PR 4260](https://github.com/shakacode/react_on_rails/pull/4260) by [justin808](https://github.com/justin808).
- **[Pro]** **Typed Rails action callers for TanStack Query mutations**: The Pro package mirrors the
  `createRailsAction` helper at `react-on-rails-pro/railsAction`. [PR 4260](https://github.com/shakacode/react_on_rails/pull/4260) by [justin808](https://github.com/justin808).

- **`bin/dev clean` clears generated bundles and caches**: The command stops development processes, reads `config/shakapacker.yml` or `SHAKAPACKER_CONFIG`, removes configured Shakapacker public/private output and cache paths plus common Rails, JavaScript, and renderer bundle caches, and skips unsafe paths outside the app root. [PR 4218](https://github.com/shakacode/react_on_rails/pull/4218) by [justin808](https://github.com/justin808).
- **[Pro]** **Buffered RSC rendering for static pages**:
  `buffered_stream_react_component` and `cached_buffered_stream_react_component`
  now render server components through the Pro streaming/RSC renderer while
  returning complete HTML to Rails, so static or cacheable pages can avoid
  `ActionController::Live` response commits when progressive streaming is not
  needed. When RSC support is enabled, prerendered Pro fragment cache keys now
  include the RSC bundle digest, or a missing-bundle sentinel until that bundle
  exists, so deploys that update only the RSC bundle invalidate cached RSC output
  consistently. Fixes
  [Issue 4263](https://github.com/shakacode/react_on_rails/issues/4263).
  [PR 4268](https://github.com/shakacode/react_on_rails/pull/4268) by
  [justin808](https://github.com/justin808).
- **[Pro]** **Opt-in browser performance marks for streamed RSC observability**: Pro streaming can now emit inline browser marks for RSC stream completion, embedded Flight payload chunks, Node-side flushes, hydration start, and first interactive client effects, with byte counts and timing details that avoid serialized props or payload contents. The documented path uses body-delivered marks and a fallback queue instead of HTTP trailers, so apps can measure streamed RSC responses across CDN paths that may strip or hide trailer timing. Fixes [Issue 4205](https://github.com/shakacode/react_on_rails/issues/4205), [Issue 4206](https://github.com/shakacode/react_on_rails/issues/4206), and [Issue 4207](https://github.com/shakacode/react_on_rails/issues/4207). [PR 4222](https://github.com/shakacode/react_on_rails/pull/4222) by [justin808](https://github.com/justin808).

- **[Pro]** **`Server-Timing` attribution for streamed RSC responses**: When `rsc_stream_observability: true`, the streamed RSC response now also carries a `Server-Timing` response header with a `ror_stream_shell` metric (Rails shell render, including the blocking wait for each component's first renderer chunk), set in the narrow window before `ActionController::Live` commits headers and appended to any existing `Server-Timing` entries. The Node renderer additionally emits a `ror_renderer_prepare` metric (execution-context build plus render start) on its HTTP response. This is the server/renderer-side complement to the browser performance marks above, letting a reviewer attribute the streamed `responseEnd` tail to a specific phase rather than guessing. Total/stream-complete time stays on the `react-on-rails:rsc:stream` mark because `ActionController::Live` does not support HTTP trailers. Closes [Issue 4239](https://github.com/shakacode/react_on_rails/issues/4239). [PR 4251](https://github.com/shakacode/react_on_rails/pull/4251) by [justin808](https://github.com/justin808).

- **[Pro]** **Focused RSC doctor artifact diagnostics**: `rake react_on_rails:doctor:rsc` and
  `Doctor.new(only: ...)` now run the RSC artifact checks directly, reporting missing,
  stale, invalid, or dev-server-backed RSC bundle and manifest files with rebuild guidance
  while explaining when Pro path resolution is unavailable. Closes
  [Issue 4204](https://github.com/shakacode/react_on_rails/issues/4204).
  [PR 4223](https://github.com/shakacode/react_on_rails/pull/4223) by
  [justin808](https://github.com/justin808).

#### Changed

- **[Pro]** **Fail fast for RSC with Rspack v1**: When React Server Components are enabled and Shakapacker is
  configured for Rspack, app boot and `react_on_rails:doctor` now reject `@rspack/core` v1 or a missing
  `@rspack/core` package with explicit Rspack v2 upgrade instructions. This guard only runs when RSC is enabled,
  so Rspack v1 remains allowed for non-RSC apps, and bundler detection now honors `SHAKAPACKER_ASSETS_BUNDLER`
  before `config/shakapacker.yml`.
  [PR 4289](https://github.com/shakacode/react_on_rails/pull/4289) by [justin808](https://github.com/justin808).
- **Redux is now hidden from the V17 install generator path**: The `react_on_rails:install --redux` option is no longer shown in install generator help or usage text, and recovery guidance no longer recommends `--redux` for new installs. The hidden legacy path and direct `react_on_rails:react_with_redux` generator now warn that Redux scaffolding is legacy while keeping runtime Redux APIs available. Closes [Issue 4272](https://github.com/shakacode/react_on_rails/issues/4272) and [Issue 4273](https://github.com/shakacode/react_on_rails/issues/4273). [PR 4277](https://github.com/shakacode/react_on_rails/pull/4277) by [justin808](https://github.com/justin808).

- **`create-react-on-rails-app` now defaults to Pro for React 19.2 support**: Running
  `npx create-react-on-rails-app my-app` no longer asks setup questions and generates the recommended
  React on Rails Pro scaffold by default. Automation note: non-TTY environments, including CI and piped
  commands, previously auto-selected Standard mode; they now select Pro. Add `--standard` to any command
  that intentionally checks or creates an open-source-only scaffold. Use `--rsc` when you want Pro with the
  generated React Server Components example.

#### Fixed

- **[Pro]** **Async-props prerender stream cache isolation**: Pro prerender stream caching now
  bypasses renders that use async props, so per-request async stream output cannot be replayed from
  another request's cached stream. Fixes
  [Issue 4359](https://github.com/shakacode/react_on_rails/issues/4359).
  [PR 4376](https://github.com/shakacode/react_on_rails/pull/4376) by
  [justin808](https://github.com/justin808).

- **`hydrate_on: nil` falls back to immediate hydration**: Passing `hydrate_on: nil` now behaves
  like the default `:immediate` mode instead of raising, while invalid explicit values still fail
  fast. Fixes [Issue 4342](https://github.com/shakacode/react_on_rails/issues/4342).
  [PR 4350](https://github.com/shakacode/react_on_rails/pull/4350) by
  [justin808](https://github.com/justin808).

- **[Pro]** **Dropped pull-mode prop requests are logged**: Streaming SSR now warns when the Node
  renderer sends a `propRequest` control frame without an emitter or with a missing, empty, or
  oversized `propName`, making dropped pull-mode requests diagnosable while preserving valid
  enqueue and `renderComplete` behavior. Fixes
  [Issue 4314](https://github.com/shakacode/react_on_rails/issues/4314).
  [PR 4352](https://github.com/shakacode/react_on_rails/pull/4352) by
  [justin808](https://github.com/justin808).

- **[Pro]** **Gemfile loader source encodings are honored under C/POSIX locales**:
  The Pro Gemfile now loads its shared dependency fragments in binary mode, applies Ruby
  source-encoding magic comments or a UTF-8 default, and validates content before override-gem
  scanning and evaluation. This affects any environment that evaluates the Pro Gemfile through
  Bundler, including local setup and CI, so Pro apps with non-ASCII dependency comments no longer
  fail under shells where Ruby's default external encoding is US-ASCII. Fixes
  [Issue 4276](https://github.com/shakacode/react_on_rails/issues/4276).
  [PR 4281](https://github.com/shakacode/react_on_rails/pull/4281) by
  [justin808](https://github.com/justin808).

- **Precompile hook no longer forces UTF-8 onto a non-UTF-8 locale**:
  The shared Shakapacker precompile hook now widens a spawned `bundle exec` / shakapacker subprocess
  to UTF-8 **only** under a bare C/POSIX locale, where the locale-derived encoding is US-ASCII — a
  strict subset of UTF-8, so the widening cannot corrupt genuinely-ASCII content. Under a real
  national locale (for example a Brazilian developer's `LANG=pt_BR.ISO8859-1`) it now leaves
  `LANG`/`LC_ALL`/`RUBYOPT` untouched and lets the child inherit the working locale, instead of
  force-pinning `-EUTF-8` and re-decoding the developer's latin-1/CP1252 source files as UTF-8 (which
  raised `invalid byte sequence in UTF-8`). The locale gate reads `Encoding.find("locale")` so it is
  not masked by Rails setting `Encoding.default_external` to UTF-8 at boot. This removes the
  `RUBYOPT`-rewriting machinery added in
  [PR 4231](https://github.com/shakacode/react_on_rails/pull/4231) while keeping the original
  C/POSIX-locale crash fix from
  [PR 4169](https://github.com/shakacode/react_on_rails/pull/4169).
  [PR 4244](https://github.com/shakacode/react_on_rails/pull/4244) by
  [justin808](https://github.com/justin808).

- **[Pro]** **RSC Rspack doctor no longer false-warns on equivalent `lazyCompilation` configs**:
  `react_on_rails:doctor:rsc` only recognizes the generated literal
  `clientWebpackConfig.lazyCompilation = false` assignment. Apps that disable lazy
  compilation an equivalent way (object form, `Object.assign`, a helper, a ternary,
  or a different config file) now get a warning that says doctor could not _confirm_
  the setting rather than asserting lazy compilation is still enabled, plus guidance
  to confirm the effective dev-server config and ignore the warning if it is already
  disabled. Follow-up to
  [PR 4234](https://github.com/shakacode/react_on_rails/pull/4234).
  [PR 4249](https://github.com/shakacode/react_on_rails/pull/4249) by
  [justin808](https://github.com/justin808).

- **Generated Tailwind apps load Tailwind from the layout.** The install generator now declares Tailwind through a layout-owned pack instead of component-owned imports, keeps generated layout head metadata mobile/CSP-ready, and warns safely when custom layouts need manual pack-tag replacement. [PR 4182](https://github.com/shakacode/react_on_rails/pull/4182) by [ihabadham](https://github.com/ihabadham).

- **[Pro]** **Rspack RSC dev-server setup is easier to diagnose and customize**:
  Generated RSC helper code now verifies client-reference discovery support
  through the sibling `rscWebpackConfig.js` file instead of assuming
  `config/webpack`, so Rspack apps keep using `config/rspack/rscWebpackConfig.js`.
  The RSC doctor also warns existing Rspack apps when normal `bin/dev` can leave
  the React Client Manifest empty because `lazyCompilation` is still enabled,
  and the troubleshooting guide documents the `lazy-compilation-proxy` /
  `POST /_rspack/lazy/trigger` 404 symptom path. Follow-up to
  [PR 4227](https://github.com/shakacode/react_on_rails/pull/4227).
  [PR 4234](https://github.com/shakacode/react_on_rails/pull/4234) by
  [justin808](https://github.com/justin808).

- **Precompile hook UTF-8 hardening now handles conflicting `RUBYOPT` encoding flags**:
  The shared Shakapacker precompile hook strips pre-existing Ruby encoding flags such as
  `-EUS-ASCII`, `--encoding=US-ASCII`, `--external-encoding=US-ASCII`, and
  `--internal-encoding=US-ASCII` before pinning subprocesses to `-EUTF-8:UTF-8`, so C/POSIX-locale
  builds do not crash when the parent shell exports a conflicting `RUBYOPT`. The shipped generated
  `bin/shakapacker-precompile-hook` template now uses the same UTF-8 subprocess environment for RSC
  client-reference discovery. Follow-up to
  [PR 4169](https://github.com/shakacode/react_on_rails/pull/4169).
  [PR 4231](https://github.com/shakacode/react_on_rails/pull/4231) by
  [justin808](https://github.com/justin808).

- **[Pro]** **Generated RSC + Rspack apps render in normal `bin/dev`**:
  RSC + Rspack generator output now disables Rspack lazy compilation while the
  dev server is running, so discovered client references are compiled before
  the React Client Manifest is read during server rendering. Fresh generated
  apps no longer fail `/hello_server` with an empty `react-client-manifest.json`
  in normal HMR mode. Fixes Issue 4226.
  [PR 4227](https://github.com/shakacode/react_on_rails/pull/4227) by
  [ihabadham](https://github.com/ihabadham).

- **[Pro]** **RSC doctor now catches stale install and client-manifest setup failures**:
  The doctor now validates installed `react-on-rails-rsc` peer requirements
  against `react` and `react-dom`, warns when the installed RSC package is
  behind newer prerelease npm dist-tags, and reports missing, dev-server-backed,
  invalid, or empty RSC client manifests with `bin/dev static` and clean rebuild
  guidance. Pro RSC render errors that fail to resolve a React Client Manifest
  module now include the same stale/empty/cross-version manifest hint instead of
  leaving the upstream "probably a bug in the RSC bundler" text as the only clue.
  Fixes [Issue 4198](https://github.com/shakacode/react_on_rails/issues/4198)
  and [Issue 4200](https://github.com/shakacode/react_on_rails/issues/4200);
  addresses [Issue 4199](https://github.com/shakacode/react_on_rails/issues/4199)
  and scopes [Issue 4204](https://github.com/shakacode/react_on_rails/issues/4204).
  [PR 4213](https://github.com/shakacode/react_on_rails/pull/4213) by
  [justin808](https://github.com/justin808).

- **Dummy app setup uses native Nokogiri gems on macOS**: The dummy app lockfile now includes Darwin platforms so `bin/setup` installs native Nokogiri gems on Apple Silicon and Intel macOS instead of attempting a source build that can fail with a missing `nokogiri_gumbo.h` header. [PR 4218](https://github.com/shakacode/react_on_rails/pull/4218) by [justin808](https://github.com/justin808).

- **[Pro]** **ScoutApm Node renderer instrumentation no longer depends on Gemfile load order**: Pro now installs `NodeRenderingPool.exec_server_render_js` instrumentation from a Rails engine initializer that runs after `scout_apm.start`, instead of checking `defined?(ScoutApm)` at class load time. Apps without ScoutApm still boot normally, and apps that load `scout_apm` after `react_on_rails_pro` no longer silently skip the Pro Node renderer span. Fixes [Issue 4208](https://github.com/shakacode/react_on_rails/issues/4208). [PR 4210](https://github.com/shakacode/react_on_rails/pull/4210) by [justin808](https://github.com/justin808).

- **[Pro]** **RSCProvider now evicts a rejected `getComponent` promise so transient failures can retry**: When the underlying RSC fetch for `getComponent` rejected — a transient renderer/network/deploy failure — the rejected promise stayed in the provider's bounded payload cache, so every later same-key `getComponent` returned that cached rejection and the RSC route/component stayed wedged in its error state even after the backend recovered; only an explicit `refetchComponent` or a full reload cleared it. `getComponent` now attaches a rejection handler that re-throws (so React's Suspense machinery still observes the failure) and evicts the cached entry one macrotask later, guarded on promise identity so a newer same-key `getComponent`/`refetchComponent` started in that window is never evicted by the stale failure. Pins are preserved so the existing `.finally()` still owns the matching unpin. Payloads that _resolve_ with an `Error` value are intentionally left cached — that retryability is a separate `getServerComponent` contract decision. Fixes [Issue 3929](https://github.com/shakacode/react_on_rails/issues/3929). [PR 4189](https://github.com/shakacode/react_on_rails/pull/4189) by [justin808](https://github.com/justin808).

- **[Pro]** **Clear page-scoped RSC payload globals on client navigation**: Pro's client-navigation teardown (`unmountAll`, fired on page unload) now deletes the page-scoped `REACT_ON_RAILS_RSC_PAYLOADS` and `REACT_ON_RAILS_RSC_ERRORS` globals that injected RSC payload `<script>` tags populate during server-streamed hydration. Previously they were left in place after components and stores unmounted, so they accumulated one entry per embedded RSC component for the life of a long-lived client-navigation (Turbo) session; and with non-random DOM ids (`config.random_dom_id = false`) a revisited payload key could append the next page's streamed chunks onto the previous page's array. Same-page streaming (the `||=` append used while a page is still rendering) is unchanged. This affects only the not-yet-released Pro RSC feature, so no published version is impacted. Closes [Issue 3932](https://github.com/shakacode/react_on_rails/issues/3932). [PR 4023](https://github.com/shakacode/react_on_rails/pull/4023) by [justin808](https://github.com/justin808).

- **[Pro]** **Precompile hook no longer crashes under a non-UTF-8 (C/POSIX) locale**: The shared Shakapacker precompile hook now forces a UTF-8 locale on every `bundle exec` / shakapacker subprocess it spawns — pack generation, the i18n locale generation added in [PR 4128](https://github.com/shakacode/react_on_rails/pull/4128), and the RSC client-reference discovery build. Without `LANG`/`LC_ALL` set, those children inherited a US-ASCII default external encoding and died parsing Gemfiles containing non-ASCII bytes (e.g. `react_on_rails_pro/Gemfile.loader`: `invalid byte sequence in US-ASCII`), aborting the entire precompile. Extends the UTF-8 hardening from [PR 3949](https://github.com/shakacode/react_on_rails/pull/3949) from the hook's own file reads to the subprocess boundary. [PR 4169](https://github.com/shakacode/react_on_rails/pull/4169) by [justin808](https://github.com/justin808).

### [17.0.0.rc.6] - 2026-06-21

#### Added

- **[Pro]** **Bidirectional async props streaming (pull mode)**: `stream_react_component_with_async_props` can now let React request lazy props during incremental rendering, complementing the existing eager push model. The stream protocol carries `propRequest` / `renderComplete` control messages from the node renderer back to Rails, `AsyncPropsManager` can request or reject props on demand, and the Pro dummy app now covers pure pull, mixed push/pull, Redis-backed fixtures, and rejection/error-boundary scenarios. Closes [Issue 4046](https://github.com/shakacode/react_on_rails/issues/4046). [PR 4048](https://github.com/shakacode/react_on_rails/pull/4048).
- **Owner Stacks in development error reports**: When a React component throws during rendering, React on Rails now enriches its development error reporting with React 19.1+'s dev-only [`captureOwnerStack`](https://react.dev/reference/react/captureOwnerStack) output — the chain of components that rendered the failing one (e.g. `at Avatar` / `at PostCard` / `at PostList`). On the **server-side rendering** path, the owner stack is captured synchronously inside the Pro streaming `onError` callback and appended to the error's stack, so it flows through to the Rails-side `ReactOnRails::PrerenderError` / `SmartError` (`:server_rendering_error`) output and the streamed shell-error HTML. On the **client**, recoverable hydration mismatches (`onRecoverableError`) automatically gain an owner-stack line in the branded development log, and apps that register their own `onCaughtError`/`onUncaughtError` handler get an additive `[ReactOnRails] Render error ... Owner stack:` line for client render errors. To avoid displacing React's own built-in development diagnostics (component stacks, error-boundary hints), React on Rails does not auto-attach caught/uncaught handlers solely to log owner stacks. Owner-stack capture requires React >= 19.1 running its development build, so it is a strict no-op on older React and in all production builds (no capture, no `captureOwnerStack` call), asserted by tests. The ExecJS rendering path is out of scope (capture must happen JS-side, synchronously, inside React's error callback). Closes [Issue 3887](https://github.com/shakacode/react_on_rails/issues/3887). [PR 4089](https://github.com/shakacode/react_on_rails/pull/4089) by [justin808](https://github.com/justin808).
- **hydrate_on scheduling**: `react_component` now accepts a `hydrate_on:` option to defer client hydration of an island until it is needed — `:immediate` (default, unchanged), `:visible` (hydrate when the container scrolls near the viewport via `IntersectionObserver`), or `:idle` (hydrate during browser idle time via `requestIdleCallback`). Deferred roots are cleaned up on Turbo/Turbolinks navigation and re-scheduled if their node is detached and reattached; unsupported modes raise, and non-`:immediate` modes are rejected when React on Rails Pro is installed. Closes [Issue 3890](https://github.com/shakacode/react_on_rails/issues/3890). [PR 4037](https://github.com/shakacode/react_on_rails/pull/4037) by [justin808](https://github.com/justin808).

#### Changed

- **Breaking (types only): `RenderFunction` no longer accepts the legacy 3-argument renderer shape**: The exported `RenderFunction` type is now exactly the 2-argument server/client render-function form (`(props, railsContext) => RenderFunctionResult`), equal to the existing `ServerRenderFunction`. It previously also accepted a 3-argument `(props, railsContext, domNodeId) => RenderFunctionResult` arm, which let nonsensical role combinations typecheck (a server render-function "returning" a renderer teardown, or a renderer "returning" a server-render hash). Renderer functions — the 3-argument form that owns its own DOM mount and may return a `{ teardown }` wrapper — should now be typed `RendererFunction`. `ReactComponentOrRenderFunction` already includes `RendererFunction`, so renderer-shaped functions remain registerable. The tighter type also drops the re-narrowing `as` casts the unified type forced in `createReactOutput` and the Pro tanstack-router render function. This is a compile-time-only change with no runtime behavior difference; only TypeScript consumers that annotated a 3-argument renderer as `RenderFunction` need to switch it to `RendererFunction`. Closes [Issue 3592](https://github.com/shakacode/react_on_rails/issues/3592). [PR 4096](https://github.com/shakacode/react_on_rails/pull/4096) by [justin808](https://github.com/justin808).
- **[Pro]** **Pinned `react-on-rails-rsc` to the stable `19.0.5` release**: The generator default, the root and Pro package manifests, the lockfile, and the Pro RSC install docs now pin the stable `react-on-rails-rsc@19.0.5` (previously the `19.0.5-rc.7` prerelease). The native RSC CSS FOUC fix requires `react-on-rails-rsc >= 19.0.5`. Closes [Issue 3634](https://github.com/shakacode/react_on_rails/issues/3634). [PR 4080](https://github.com/shakacode/react_on_rails/pull/4080) by [justin808](https://github.com/justin808).
- **[Pro]** **RSC peer-compatibility warn-tier floor raised to stable `19.0.5`**: The Pro node renderer's `recommendedMin` for `react-on-rails-rsc` is now the published stable `19.0.5` (previously the dormant `19.0.2`). Anyone still on an older 19.x build (`19.0.2`–`19.0.4`) now gets a loud startup warning that they are missing the coordinated RSC fixes shipped in `19.0.5` (FOUC stylesheet preloading, async manifest signatures); `19.0.5`+ no longer warns. Refs [Issue 3632](https://github.com/shakacode/react_on_rails/issues/3632). [PR 4078](https://github.com/shakacode/react_on_rails/pull/4078) by [justin808](https://github.com/justin808).
- **[Pro]** **RSC peer wildcard replaced with an explicit range**: The Pro npm package's optional `react-on-rails-rsc` peer dependency is now `^19.0.5` (`>= 19.0.5 < 20.0.0`) instead of `"*"`, so installs are floored at the RSC CSS FOUC fix release `19.0.5` and capped below the next major `20.0.0`, rather than `"*"` accepting any version including pre-FOUC builds and an unknown future major. Within the `19.x` line, per-version compatibility is enforced by the Pro node renderer's runtime version check (`rscPeerSupport.ts`), not by this advisory peer range. Fixes [Issue 3965](https://github.com/shakacode/react_on_rails/issues/3965). [PR 4082](https://github.com/shakacode/react_on_rails/pull/4082) by [justin808](https://github.com/justin808).

#### Fixed

- **Deferred hydration error reporting handles non-Error thrown values**: Delayed `hydrate_on` renders now normalize strings, `null`, and frozen `Error` instances before logging, so reporting the failure does not throw again or mutate user errors. [PR 4120](https://github.com/shakacode/react_on_rails/pull/4120) by [ihabadham](https://github.com/ihabadham).

- **Explicit Webpack installs now pass the resolved bundler to Shakapacker.** `rails generate react_on_rails:install --no-rspack` and `--webpack` now set `SHAKAPACKER_ASSETS_BUNDLER=webpack` before running `shakapacker:install`, so Shakapacker installs Webpack dependencies instead of falling back to its default bundler. Fixes [Issue 4108](https://github.com/shakacode/react_on_rails/issues/4108). [PR 4109](https://github.com/shakacode/react_on_rails/pull/4109) by [ihabadham](https://github.com/ihabadham).

- **Generated demo paths now honor custom Shakapacker source roots.** The install generator resolves demo components, entrypoints, stylesheets, TypeScript includes, Tailwind imports, and RSC hints from the app's Shakapacker `source_path` / `source_entry_path` settings, including slash entry roots, while wrapping long source hints in the generated demo views. Fixes [Issue 4062](https://github.com/shakacode/react_on_rails/issues/4062). [PR 4107](https://github.com/shakacode/react_on_rails/pull/4107) and [PR 4130](https://github.com/shakacode/react_on_rails/pull/4130) by [justin808](https://github.com/justin808).

- **RSC-safe generated i18n locale defaults**: The JavaScript locale compiler that generates `default.js` no longer imports `react-intl` or wraps messages in `defineMessages`; it now emits the message descriptor object directly. This lets the generated locale defaults be imported from React Server Component bundles without pulling in the client-oriented `react-intl` entrypoint, and without raising the minimum supported `react-intl` version. The exported `defaultMessages` shape is unchanged, and existing apps regenerate automatically because the compiler treats a `default.js` still using the old `defineMessages` template as stale. Fixes [Issue 4132](https://github.com/shakacode/react_on_rails/issues/4132). [PR 4146](https://github.com/shakacode/react_on_rails/pull/4146) by [justin808](https://github.com/justin808).

- **Abort the in-flight SSR render when the client disconnects (Pro streaming)**: Previously, when an HTTP client disconnected (or a request timed out) mid-stream, the Node renderer kept driving the React render to completion against a consumer that was already gone — wasting CPU and, for RSC/`cache()`-wrapped data fetches, continuing to hit the app's database/APIs. The Pro streaming layer now propagates the consumer-side teardown upstream into ReactDOM's `PipeableStream.abort()`: when the renderer worker detects the client disconnect it destroys the render's output stream, which aborts the in-flight render and releases the request's RSC payload streams. Normal completion is unaffected (the abort only fires when the output is destroyed before it ends, and never when a render error closes the stream). This also establishes the precondition for React 19.2's [`cacheSignal`](https://react.dev/reference/react/cacheSignal), which React settles automatically once a render is aborted (the `cacheSignal`-specific test and docs remain a follow-up). Part of [Issue 3885](https://github.com/shakacode/react_on_rails/issues/3885). [PR 4093](https://github.com/shakacode/react_on_rails/pull/4093) by [justin808](https://github.com/justin808).
- **[Pro]** **Bounded the RSCProvider RSC payload cache to prevent unbounded growth under high-cardinality props**: The provider-scoped promise cache (`fetchRSCPromisesRef`) and its companion bookkeeping (`lastSuccessfulRSCPromisesRef`, refetch versions, and the `versions`/`successfulVersions` state maps) are now backed by a bounded LRU (default cap 50 distinct RSC payload keys). High-cardinality `componentProps` (e.g. per-row or per-search-query routes) previously grew these maps without limit for the provider's entire lifetime — a latent memory leak. Eviction only affects cold, least-recently-used keys beyond the cap; same-key cache hits, refetch, `recoverOnError` restore, and version bumping are unchanged, and an in-flight refetch's key is pinned (with ref-counted pins, so overlapping same-key refetches stay protected until all of them settle) and cannot be evicted out from under its restore path. The per-key `useSyncExternalStore` subscription/fan-out optimization from the same issue is intentionally deferred pending profiling. Refs [Issue 3564](https://github.com/shakacode/react_on_rails/issues/3564). [PR 4097](https://github.com/shakacode/react_on_rails/pull/4097) by [justin808](https://github.com/justin808).

- **[Pro]** **Enrich deferred-render RSC errors with the bundle diagnostic**: When a Server Component failed during React's deferred render phase (a Suspense boundary resolving a lazy RSC element), the error surfaced through `renderToPipeableStream`'s `onError` as a generic React stream error — the original RSC bundle diagnostic (the real server-side error message and module path) was already out of scope and lost. The Pro streaming layer now threads the captured diagnostic through the request-scoped tracker and merges it into the surfaced error, so `ReactOnRails::PrerenderError` / `SmartError` output names the failing RSC component and module instead of a bare React message. Since React's `onError` carries no component key, attribution is conservative: one captured diagnostic is merged exactly, two or more produce a combined "one of these N RSC components failed" message (never a single false pinpoint), and each captured diagnostic is consumed on first use so an unrelated later failure in the same render is never mislabeled. Completes the deferred-render half of the bundle-diagnostic work (the fetch and preloaded-hydration halves shipped earlier). Closes [Issue 3475](https://github.com/shakacode/react_on_rails/issues/3475). [PR 4100](https://github.com/shakacode/react_on_rails/pull/4100) by [justin808](https://github.com/justin808).

### [17.0.0.rc.5] - 2026-06-16

#### Fixed

- **[Pro]** **RSC and client-only FOUC reveal gating**: Pro now waits for auto-loaded generated component stylesheets before mounting client-only roots and promotes streamed RSC client chunk stylesheet preloads to real stylesheet links before reveal, including when stream chunks split `<link>` tags. Shared generated CSS is matched through manifest-derived stylesheet href metadata, while app-authored preload links remain untouched. Fixes [Issue 4031](https://github.com/shakacode/react_on_rails/issues/4031), [Issue 4032](https://github.com/shakacode/react_on_rails/issues/4032). [PR 4047](https://github.com/shakacode/react_on_rails/pull/4047) by [justin808](https://github.com/justin808).

### [17.0.0.rc.4] - 2026-06-14

#### Added

- **[Pro]** **Tag-based cache revalidation (a Next.js `revalidateTag` analog)**: The fragment-caching helpers (`cached_react_component`, `cached_react_component_hash`, `cached_stream_react_component`, `cached_async_react_component`) now accept an optional `cache_tags:` option (String, Proc, any object responding to `cache_key` such as an ActiveRecord model, or an Array of any mix), and the new `ReactOnRailsPro.revalidate_tag(tag)` / `revalidate_tags(*tags)` API deletes every cached entry registered under a tag via a `Rails.cache`-backed tag->key index. A new `ReactOnRailsPro::Cache::Revalidates` ActiveRecord concern (`revalidates_react_cache`) drives revalidation from `after_commit`, so the model that owns the data also owns cache invalidation (and composes with `touch:`). Revalidation is best-effort with correctness bounded by `expires_in` (a development-mode warning fires when `cache_tags:` is used without it); index growth is bounded by the new `config.cache_tag_index_expires_in` (default 7 days) and `config.cache_tag_index_max_keys` (default 5,000) settings. Existing `cache_key:`-only behavior is unchanged. Closes [Issue 3871](https://github.com/shakacode/react_on_rails/issues/3871). [PR 3964](https://github.com/shakacode/react_on_rails/pull/3964) by [justin808](https://github.com/justin808).
- **React 19 root error callbacks**: `ReactOnRails.setOptions({ rootErrorHandlers: { onRecoverableError, onCaughtError, onUncaughtError } })` registers React's root error callbacks globally; React on Rails applies them to every `hydrateRoot`/`createRoot` call it makes and invokes them with an extra context argument whose `componentName` and `domNodeId` fields are optional. In development, recoverable hydration errors now log an actionable React on Rails message (component name, dom id, component stack, and a link to the new [Debugging Hydration Mismatches guide](https://reactonrails.com/docs/building-features/debugging-hydration-mismatches)) alongside React's default error reporting, which stays intact so window-'error'-based tooling keeps working. Partial `rootErrorHandlers` updates merge per key, so registering one callback later does not drop the others. On React <19 (and <18 for `onRecoverableError`), React on Rails retains registrations for future upgrades, but the current runtime cannot invoke unsupported callbacks and logs a one-time console warning. On React on Rails Pro RSC/streaming hydration paths, user callbacks chain with (never replace) Pro's internal recoverable-error handler. Addresses [Issue 3892](https://github.com/shakacode/react_on_rails/issues/3892). [PR 3933](https://github.com/shakacode/react_on_rails/pull/3933) by [justin808](https://github.com/justin808).
- **`useRailsForm` hook + `render_model_errors` controller concern (an Inertia `useForm`-style bridge to Rails controllers)**: New React hook `useRailsForm` (importable from `react-on-rails/useRailsForm`) makes posting a React form to a plain Rails controller turnkey: `data`/`setData`, per-field `errors`, `processing`, `wasSuccessful`, submit verbs (`post`/`put`/`patch`/`delete`/`submit`), `reset`/`clearErrors`/`setError`, automatic CSRF attachment from the Rails csrf-token meta tag, JSON request/response handling, and mapping of `422` + `{ errors: { field: ["message"] } }` responses onto per-field error state. Success results surface a `redirectTo` target (followed-redirect URL or JSON `redirect_to` hint) without navigating, forward-compatible with the client-routing work in [Issue 3873](https://github.com/shakacode/react_on_rails/issues/3873). The gem side adds the opt-in `ReactOnRails::Controller::FormResponders` concern whose `render_model_errors(record)` renders ActiveModel errors in exactly that shape, so validations stay in the model with no API layer and no client-side duplication. Includes a new [Forms and Mutations](docs/oss/building-features/forms.md) docs page (with an Inertia `useForm` mapping table and a Server Functions [Issue 3867](https://github.com/shakacode/react_on_rails/issues/3867) cross-link) and a runnable dummy-app example (`/rails_form`). v1 is fetch-only; `transform`, `recentlySuccessful`, and file-upload `progress` are deferred. Closes [Issue 3872](https://github.com/shakacode/react_on_rails/issues/3872). [PR 3942](https://github.com/shakacode/react_on_rails/pull/3942) by [justin808](https://github.com/justin808).
- **[Pro]** **Built-in node renderer `/health` and `/ready` probe endpoints**: The node renderer can now register first-class liveness (`GET /health` -> `200` with a status-only body) and readiness (`GET /ready` -> `503` until the answering worker is online and has at least one server bundle compiled, then `200`) endpoints, replacing the hand-rolled `configureFastify` health-check recipe for the common case. The endpoints are off by default and enabled with the new `enableHealthEndpoints` config option (or `RENDERER_ENABLE_HEALTH_ENDPOINTS=true`, `TRUE`, `yes`, `YES`, or `1`); they are unauthenticated like `/info` but expose no runtime version or path details. The `1` alias is scoped to `RENDERER_ENABLE_HEALTH_ENDPOINTS` so existing node-renderer boolean environment flags keep their previous parsing behavior. Includes a new [Health and Readiness Endpoints](docs/oss/building-features/node-renderer/health-checks.md) docs page with working Kubernetes (`tcpSocket` + `exec` with `curl --http2-prior-knowledge` -- the h2c listener cannot be probed with HTTP/1.1 `httpGet`), ECS, and Docker Compose probe examples. Closes [Issue 3880](https://github.com/shakacode/react_on_rails/issues/3880). [PR 3939](https://github.com/shakacode/react_on_rails/pull/3939) by [justin808](https://github.com/justin808).
- **[Pro]** **Source-mapped stack traces in the Node renderer**: SSR errors now point at the original TypeScript/JavaScript `file:line:column` instead of bundled positions. When the server bundle carries an inline source map (or a `.map` file is available next to the uploaded bundle), the renderer captures the map text for the VM's bundle generation and lazily parses it on the first error before remapping stack frames — both for exceptions returned to Rails as renderer errors and for stacks captured inside the bundle that surface through `ReactOnRails::PrerenderError`. Bundles are also now evaluated with their real file path, so even unmapped stacks name the bundle file rather than `evalmachine.<anonymous>`. No per-request overhead: map parsing and frame remapping happen only when an error's stack is accessed, and parsed maps are cached per bundle generation. Uses Node's built-in `module.SourceMap` (no new dependencies). Part of [Issue 3893](https://github.com/shakacode/react_on_rails/issues/3893). [PR 3940](https://github.com/shakacode/react_on_rails/pull/3940) by [justin808](https://github.com/justin808).

#### Changed

- **[Pro]** **RSC peer compatibility accepts the coordinated React 19.2 floor**: The Pro node renderer now allows React and React DOM `19.2.x` starting at `19.2.7`, matching the floor required by the `react-on-rails-rsc` 19.2 package line while preserving the existing React `19.0.x` support window. Refs [Issue 3865](https://github.com/shakacode/react_on_rails/issues/3865). [PR 4026](https://github.com/shakacode/react_on_rails/pull/4026) by [justin808](https://github.com/justin808).

#### Fixed

- **Rspack generated apps start in HMR mode**: Fresh `rails generate react_on_rails:install --rspack` and `create-react-on-rails-app` projects now install `@rspack/dev-server`, use the `ReactRefreshRspackPlugin` export, and keep `bin/switch-bundler rspack`'s dev dependencies complete so `bin/dev` can launch Rspack serve instead of crashing during dev-server startup. Fixes [Issue 3925](https://github.com/shakacode/react_on_rails/issues/3925). [PR 3926](https://github.com/shakacode/react_on_rails/pull/3926) by [AbanoubGhadban](https://github.com/AbanoubGhadban) and [ihabadham](https://github.com/ihabadham).

### [17.0.0.rc.3] - 2026-06-11

#### Added

- **Machine-readable doctor output (`FORMAT=json`)**: `bin/rails react_on_rails:doctor FORMAT=json` (and `ReactOnRails::Doctor.new(format: :json)`) now emits a stable, versioned JSON report — `schema_version`, `ror_version`, overall `status`, per-check entries with stable snake_case ids (`pass`/`warn`/`fail` status, most-severe `message`, full `details`), and a `summary` of check counts — so coding agents and tooling can consume diagnosis results without parsing the human-formatted text. Stray check output is routed to stderr so stdout stays valid JSON; the default human-readable output and exit-code semantics are unchanged. Split out from the MCP-server RFC in [Issue 3870](https://github.com/shakacode/react_on_rails/issues/3870). Closes [Issue 3943](https://github.com/shakacode/react_on_rails/issues/3943). [PR 3948](https://github.com/shakacode/react_on_rails/pull/3948) by [justin808](https://github.com/justin808).
- **Consumer-facing AI-agent guidance scaffolded into generated and installed apps**: `rails generate react_on_rails:install` (and therefore `create-react-on-rails-app`, which delegates to it) now writes a concise, app-scoped `AGENTS.md` plus thin editor-pointer files (`CLAUDE.md`, `.cursor/rules/react-on-rails.mdc`, `.github/copilot-instructions.md`) so an AI coding agent dropped into a fresh app already knows how to register a component, use the `react_component` view helper, choose `.client`/`.server` bundles, recover from the top runtime errors (sourced from `SmartError`), and run `bin/rails react_on_rails:doctor`. The errors section tracks the live `SmartError` messages, and the editor files are pointers (not copies). Emission is gated by `--agent-files`/`--no-agent-files` (default on) in both paths and never overwrites an existing file. Cross-links the eval-harness work in [Issue 3832](https://github.com/shakacode/react_on_rails/issues/3832). Closes [Issue 3868](https://github.com/shakacode/react_on_rails/issues/3868). [PR 3924](https://github.com/shakacode/react_on_rails/pull/3924) by [justin808](https://github.com/justin808).
- **First-party font optimization helper (a `next/font/local` analog)**: New `ReactOnRails::FontHelper#react_on_rails_font_face` view helper returns `<head>` markup for a committed, self-hosted `.woff2` font: a `<link rel="preload" as="font" type="font/woff2" crossorigin>`, an `@font-face` with `font-display: swap`, and an optional metric-matched fallback `@font-face` (`size-adjust` plus `ascent-override` / `descent-override` / `line-gap-override`) so the system fallback occupies the same space as the web font and the swap produces no layout shift (CLS). Self-hosting through the asset pipeline avoids any third-party font-host request. Includes a new [Font Optimization](docs/oss/building-features/fonts.md) docs page (self-hosting, preload, `font-display`, the `size-adjust` fallback technique with a worked Inter-over-Arial derivation, subsetting guidance, and a CLS note) and a runnable dummy-app example. v1 covers the `next/font/local` committed-file path and the non-streaming `react_component_hash` head-injection path. Closes [Issue 3875](https://github.com/shakacode/react_on_rails/issues/3875) (partial). Deferred sub-tasks tracked in [Issue 3921](https://github.com/shakacode/react_on_rails/issues/3921). [PR 3923](https://github.com/shakacode/react_on_rails/pull/3923) by [justin808](https://github.com/justin808).
- **Stable SmartError codes and generated error reference**: SmartError messages now include stable `ROR###` codes and canonical documentation URLs, and `docs/oss/reference/error-reference.md` is generated from the SmartError definitions with a drift check. Fixes [Issue 3894](https://github.com/shakacode/react_on_rails/issues/3894). [PR 3936](https://github.com/shakacode/react_on_rails/pull/3936) by [justin808](https://github.com/justin808).
- **Preload link helper for generated component packs**: Added `react_on_rails_preload_links` so layouts can emit preload, modulepreload, and stylesheet preload tags for auto-bundled component packs from the Shakapacker manifest. Fixes [Issue 3889](https://github.com/shakacode/react_on_rails/issues/3889). [PR 3935](https://github.com/shakacode/react_on_rails/pull/3935) by [justin808](https://github.com/justin808).
- **Tailwind CSS v4 generator option**: `rails generate react_on_rails:install --tailwind` and `create-react-on-rails-app --tailwind` now install Tailwind CSS v4, wire `@tailwindcss/postcss` for Webpack or Rspack, and style the generated server-rendered HelloWorld example with extracted component CSS support. Interactive `create-react-on-rails-app` runs recommend Tailwind by default while still allowing users to opt out. Fixes [Issue 3895](https://github.com/shakacode/react_on_rails/issues/3895). [PR 3937](https://github.com/shakacode/react_on_rails/pull/3937) by [justin808](https://github.com/justin808).

#### Fixed

- **[Pro]** **Node renderer drains workers on `SIGTERM`/`SIGINT` instead of orphaning them**: The Pro Node renderer master now installs `SIGTERM` and `SIGINT` handlers before forking workers, so supervisors (Foreman, local dev, process managers) that signal the master gracefully drain workers — sending the shutdown message, waiting a short grace period, calling `cluster.disconnect()`, then awaiting each worker's `exit` event — instead of killing only the master and leaving orphaned worker processes behind. Shutdown uses signal-style exit codes (`SIGINT` → 130, `SIGTERM` → 143), reuses a shutdown-time worker snapshot for the hard `SIGKILL` fallback so disconnected-but-still-running workers are not missed, and suppresses reforks while a shutdown is in progress. Fixes [Issue 3863](https://github.com/shakacode/react_on_rails/issues/3863). [PR 3882](https://github.com/shakacode/react_on_rails/pull/3882) by [justin808](https://github.com/justin808).

### [17.0.0.rc.2] - 2026-06-09

#### Added

- **[Pro]** **Route-loader RSC payload helper**: `react-on-rails-pro/rscPayloadNode` now exports `createRscPayloadNode(...)` so client routers and loaders can consume the Pro RSC payload route as React route data without reaching into private `RSCRoute` internals. The helper defaults to same-origin credentials, exposes a narrow set of fetch controls (`credentials`, `headers`, and `signal`), and keeps console replay metadata out of inline scripts for CSP-friendly loader usage. RSC payload fetches now URL-encode component names before requesting `/rsc_payload/:componentName`, which preserves standard Rails path-segment decoding while avoiding invalid path characters in the browser request URL. Fixes [Issue 3493](https://github.com/shakacode/react_on_rails/issues/3493). [PR 3783](https://github.com/shakacode/react_on_rails/pull/3783) by [justin808](https://github.com/justin808).
- **[Pro]** **RSC registration entry path override**: Generated RSC precompile hooks, discovery builds, and client-reference stale checks now honor `REACT_ON_RAILS_RSC_REGISTRATION_ENTRY_PATH` so apps that write `server-component-registration-entry.js` outside the default generated path can point React on Rails Pro at the exact entry while retaining the existing fallback scan and stale-manifest cleanup. Fixes [Issue 3621](https://github.com/shakacode/react_on_rails/issues/3621). [PR 3712](https://github.com/shakacode/react_on_rails/pull/3712) by [justin808](https://github.com/justin808).
- **[Pro]** **RSC `unstable_cache` with Redis L2 and tiered caching**: Added `unstable_cache` for RSC rendering with deterministic cache-key serialization (React flight protocol encoding with sorted object keys), a `RedisCacheHandler` for cross-worker L2 caching, a `TieredCacheHandler` for L1/L2 composition with configurable L1 TTL caps, and per-worker single-flight render coalescing. Resolves [Issue 3702](https://github.com/shakacode/react_on_rails/issues/3702). [PR 3705](https://github.com/shakacode/react_on_rails/pull/3705).
- **[Pro]** **RSC manifest client reference discovery during precompile**: Generated RSC Webpack configs now run `RSCReferenceDiscoveryPlugin` through the Shakapacker precompile hook to emit `rsc-client-references.json`, use that manifest for RSC client-reference bundling, and warn when the selected manifest is stale. The generator now pins `react-on-rails-rsc` to `19.0.5-rc.6`, the prerelease containing the discovery plugin export and RSC manifest CSS fixes, and the Pro peer range explicitly accepts that prerelease. [PR 3556](https://github.com/shakacode/react_on_rails/pull/3556) by [ihabadham](https://github.com/ihabadham).

#### Changed

- **[Pro]** **`<RSCRoute>` client-control refetch failures are recoverable in production**: `ref` and `useCurrentRSCRoute()` refetch failures now keep the last successful route content mounted in production, expose `refetchError`, `retry()`, and `clearRefetchError()` on `RSCRouteHandle`, and call the optional `onRefetchError` prop for parent/sibling reporting. Development still fails loudly through `ServerComponentFetchError` so component context and the original refetch error stay visible. Fixes [Issue 3565](https://github.com/shakacode/react_on_rails/issues/3565). [PR 3786](https://github.com/shakacode/react_on_rails/pull/3786) by [justin808](https://github.com/justin808).
- **[Pro]** **Updated the RSC rollout pin to `react-on-rails-rsc@19.0.5-rc.7`**: The generator default, package manifests, lockfile, and Pro RSC install docs now point at `19.0.5-rc.7`, which fixes the Webpack client manifest CSS collection to exclude runtime-chunk CSS (so shared runtime CSS no longer leaks into every client component's Flight stylesheet hints, while the server manifest still retains runtime-chunk CSS for SSR coverage) and to skip `.hot-update.css` HMR files. The temporary exact prerelease pin policy is unchanged until stable `19.0.5` ships. [PR 3857](https://github.com/shakacode/react_on_rails/pull/3857) by [justin808](https://github.com/justin808).
- **[Pro]** **Updated the RSC rollout pin to `react-on-rails-rsc@19.0.5-rc.6`**: Pro RSC install docs, generator defaults, package metadata, and example guidance now point at `19.0.5-rc.6` while keeping React on the supported `19.0.x` range and documenting the temporary exact prerelease pin. `19.0.5-rc.6` ships the client-manifest CSS collection fix (record `.css` siblings, `.mjs` chunk support, href normalization) upstream, so the temporary local pnpm patch (`patches/react-on-rails-rsc@19.0.5-rc.5.patch`) has been removed. [PR 3577](https://github.com/shakacode/react_on_rails/pull/3577) by [justin808](https://github.com/justin808).
- **Generator scaffolds the native `RSCRspackPlugin` for Rspack RSC projects**: `rails generate react_on_rails:install --rsc` on an Rspack app now wires up `react-on-rails-rsc/RspackPlugin` (`RSCRspackPlugin`) instead of the Webpack-compat `RSCWebpackPlugin`, which produced valid-looking manifests that still broke under Rspack. Re-running the generator on a legacy Rspack config migrates the old `RSCWebpackPlugin` import and invocation to the native plugin. The pinned `react-on-rails-rsc` dependency was bumped to `19.0.5-rc.6` (which still exports `WebpackPlugin`, so Webpack projects are unaffected). Resolves [Issue 3488](https://github.com/shakacode/react_on_rails/issues/3488). [PR 3590](https://github.com/shakacode/react_on_rails/pull/3590) by [justin808](https://github.com/justin808).
- **[Pro]** **Widened the `react-on-rails-rsc` peer-dependency range to the full React 19 line**: `react-on-rails-pro` now declares `react-on-rails-rsc` as `>= 19.0.2 < 20.0.0` (previously `>= 19.0.2 <= 19.2.3`), so future `react-on-rails-rsc` patch and minor releases on the React 19 line no longer trigger a peer-dependency warning. The `react` / `react-dom` peers stay at `>= 16`: React 18 support is retained, and the React-19-only RSC path is gated through the optional `react-on-rails-rsc` peer rather than by raising the React baseline. Resolves [Issue 3486](https://github.com/shakacode/react_on_rails/issues/3486). [PR 3580](https://github.com/shakacode/react_on_rails/pull/3580) by [justin808](https://github.com/justin808).

#### Improved

- **[Pro]** **Embedded RSC payloads no longer repeat full serialized props in the page HTML**: The embedded RSC payload cache key now uses a compact hash of the component props instead of the full `JSON.stringify(componentProps)`, so server-rendered pages with RSC components stop repeating large props JSON once per Flight chunk in render-blocking inline scripts (a 1KB props object across 10 chunks previously added ~12KB of repeated JSON; now ~120 bytes). The client-side `RSCProvider` in-memory promise cache still keys on full props, so payload deduplication behavior is unchanged. Fixes [Issue 3796](https://github.com/shakacode/react_on_rails/issues/3796). [PR 3800](https://github.com/shakacode/react_on_rails/pull/3800) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **RSC manifest setup avoids synchronous file-stat work on render**: Pro RSC rendering no longer relies on synchronous `fs.statSync` manifest signature checks during render-time setup, avoiding Node event-loop blocking on that path. The manifest-wide CSS/link cache path that used those signatures was later removed by [PR 3860](https://github.com/shakacode/react_on_rails/pull/3860). [PR 3595](https://github.com/shakacode/react_on_rails/pull/3595) by [justin808](https://github.com/justin808).
- **Server-bundle load failures are now classified separately from renderer-connection failures**: Bundle read/fetch failures raise the new `ReactOnRails::ServerBundleLoadError` instead of being grouped with renderer-connectivity errors, keeping the renderer-connection classification (see [PR 3614](https://github.com/shakacode/react_on_rails/pull/3614)) focused on render-origin connection failures, including wrapped `connect(2)` errors found through the exception cause chain. Fixes [Issue 3628](https://github.com/shakacode/react_on_rails/issues/3628). [PR 3724](https://github.com/shakacode/react_on_rails/pull/3724) by [justin808](https://github.com/justin808).
- **Renderer connection failures are no longer misreported as webpack/bundle errors**: When server rendering fails because Rails cannot reach the renderer process (for example a Pro Node renderer behind `REACT_RENDERER_URL` that refuses the connection — `ECONNREFUSED`, `EHOSTUNREACH`, `ETIMEDOUT`, or a sandboxed `Errno::EPERM` / `connect(2)` failure), React on Rails now raises a renderer-connectivity error that names the host/port it tried to reach and points at `REACT_RENDERER_URL` and renderer liveness, instead of the misleading "Error evaluating server bundle. Check your webpack configuration." The existing webpack/server-bundle troubleshooting is retained for genuine bundle evaluation errors. Fixes [Issue 3604](https://github.com/shakacode/react_on_rails/issues/3604). [PR 3614](https://github.com/shakacode/react_on_rails/pull/3614) by [justin808](https://github.com/justin808).

#### Fixed

- **[Pro]** **RSC `unstable_cache` no longer caches failed Flight renders**: React Flight render errors reported by `renderToPipeableStream` now skip the cache write, so later requests retry the render instead of replaying a failed RSC payload from cache. React's default error logging behavior is preserved. Fixes [Issue 3774](https://github.com/shakacode/react_on_rails/issues/3774). [PR 3775](https://github.com/shakacode/react_on_rails/pull/3775) by [ihabadham](https://github.com/ihabadham).
- **[Pro]** **Prerender cache no longer misses when only the random `domNodeId` changes**: Pro prerender cache digest normalization now strips `domNodeId` values emitted in JSON/double-quote form as well as the older single-quote form, so cached prerender results are reused across requests that differ only by the randomly generated DOM node id, while changed props still produce distinct digests. Fixes [Issue 3706](https://github.com/shakacode/react_on_rails/issues/3706). [PR 3707](https://github.com/shakacode/react_on_rails/pull/3707) by [ihabadham](https://github.com/ihabadham).
- **Auto-bundled snake_case component names now load their generated packs consistently**: Auto-bundled component pack loading is normalized through the same name resolution used for DOM/SSR lookup, so `react_component("component_name")` loads the `generated/ComponentName` pack, and public component names generated for files under the configured auto-bundling components subdirectory are camelized (server-bundle and store filename behavior is preserved, as is generated-pack conflict protection for names differing only by case). Fixes [Issue 3809](https://github.com/shakacode/react_on_rails/issues/3809). [PR 3818](https://github.com/shakacode/react_on_rails/pull/3818) by [justin808](https://github.com/justin808).
- **[Pro]** **A throwing React root unmount no longer aborts client teardown**: The Pro client renderer now guards the modern React root `unmount()` path, logging failures at `console.error` and always clearing the tracked root, so one failing root unmount cannot stop other components from unmounting or block later renders on the same DOM node. Fixes [Issue 3618](https://github.com/shakacode/react_on_rails/issues/3618). [PR 3716](https://github.com/shakacode/react_on_rails/pull/3716) by [justin808](https://github.com/justin808).
- **[Pro]** **Plain-object component registrations keep their type in the Pro `ComponentRegistry`**: Pro registry entries are now typed to cover plain object modules used by `server_render_js` (matching the core package types from [PR 3606](https://github.com/shakacode/react_on_rails/pull/3606)), `getOrWaitForComponent` aligns with the widened entry type, and the Pro client renderer now guards against invoking non-callable renderer entries. Fixes [Issue 3677](https://github.com/shakacode/react_on_rails/issues/3677). [PR 3719](https://github.com/shakacode/react_on_rails/pull/3719) by [justin808](https://github.com/justin808).
- **Server-component wrapper types reject non-component render functions at compile time**: The new `ReactComponentRenderFunction` type models render functions that must return a React component, and the Pro `wrapServerComponentRenderer` client/server inputs are narrowed to it, so registering a teardown-returning renderer function there is now a TypeScript compile-time error instead of relying only on the existing runtime guards (which are unchanged for JavaScript callers). Fixes [Issue 3589](https://github.com/shakacode/react_on_rails/issues/3589). [PR 3720](https://github.com/shakacode/react_on_rails/pull/3720) by [justin808](https://github.com/justin808).
- **[Pro]** **Incompatible `react-on-rails-rsc` / React versions now fail loudly instead of silently misbehaving**: the Pro node renderer checks the installed `react-on-rails-rsc`, `react`, and `react-dom` versions at boot and throws a clear error when `react-on-rails-rsc` is outside the supported `19.x` major or React/React DOM are outside the supported `19.0.x` patch range on the RSC path (and warns when `react-on-rails-rsc` is older than the recommended minimum). Because the peer dependency is declared `*` (so coordinated prereleases install cleanly, see [PR 3616](https://github.com/shakacode/react_on_rails/pull/3616)), this runtime check — not the peer range — is the real compatibility gate. Set `REACT_ON_RAILS_PRO_DISABLE_VERSION_CHECK=1` to downgrade the hard error to a warning. [PR 3831](https://github.com/shakacode/react_on_rails/pull/3831) by [justin808](https://github.com/justin808).
- **[Pro]** **RSC `React.cache()` request dedupe now works in generated configs**: Generated RSC webpack configs now canonicalize `react`, `react/jsx-runtime`, and `react/jsx-dev-runtime` resolution to one React server package instance, keeping React's RSC cache dispatcher shared between the renderer and app Server Components. This restores request-local `React.cache()` memoization for direct Server Component data loaders in generated RoRP RSC apps. Fixes [Issue 3812](https://github.com/shakacode/react_on_rails/issues/3812). [PR 3813](https://github.com/shakacode/react_on_rails/pull/3813) by [ihabadham](https://github.com/ihabadham).
- **[Pro]** **Preloaded RSC hydration errors preserve bundle diagnostics**: RSC payload injection now threads the server-side `renderingError` metadata to the browser so preloaded hydration failures can report the original RSC bundle error message and module path, matching the fetch path while avoiding unrelated stream metadata such as serialized props. Addresses the preloaded hydration portion of [Issue 3475](https://github.com/shakacode/react_on_rails/issues/3475). [PR 3766](https://github.com/shakacode/react_on_rails/pull/3766) by [justin808](https://github.com/justin808).
- **Auto-bundled component name conflicts now fail loudly**: React on Rails now raises an error when multiple auto-bundled component files resolve to the same public component name, listing the conflicting files instead of silently keeping whichever path overwrote the earlier mapping. Fixes [Issue 3708](https://github.com/shakacode/react_on_rails/issues/3708). [PR 3709](https://github.com/shakacode/react_on_rails/pull/3709) by [ihabadham](https://github.com/ihabadham).
- **[Pro]** **`react-on-rails-rsc` prerelease (RC) versions no longer mark the dependency tree invalid**: The `react-on-rails-pro` peer dependency on the optional `react-on-rails-rsc` is now `*`, so installing any coordinated `react-on-rails-rsc` build — including prereleases such as `react-on-rails-rsc@19.0.5-rc.6` — no longer makes `npm ls react-on-rails-rsc` fail with `ELSPROBLEMS`. npm's strict semver only lets a prerelease satisfy a comparator that shares its exact `major.minor.patch` tuple, so no bounded range — including the `>= 19.0.2 < 20.0.0` range introduced in [PR 3580](https://github.com/shakacode/react_on_rails/pull/3580) — can admit prereleases across the React 19 line (e.g. `19.0.5-rc.6`, `19.2.x-rc.*`) without enumerating every patch tuple. `react-on-rails-rsc` stays an optional peer that Pro resolves only on the React Server Components path; the supported pairing is React on Rails RSC on the React 19 line (currently `>= 19.0.2`), and a mismatched build is caught by the Pro node renderer's runtime version check rather than relying on the peer-range warning. Fixes [Issue 3609](https://github.com/shakacode/react_on_rails/issues/3609). [PR 3616](https://github.com/shakacode/react_on_rails/pull/3616) by [justin808](https://github.com/justin808).
- **TypeScript source server bundles work with auto-generated packs**: React on Rails now resolves the configured server bundle source entrypoint by extension, so apps can keep `config.server_bundle_js_file = "server-bundle.js"` as the compiled/runtime bundle name while using a TypeScript source entrypoint such as `packs/server-bundle.ts`. Public registration types also now cover plain object modules used by `server_render_js`, matching existing runtime behavior. Resolves [Issue 1583](https://github.com/shakacode/react_on_rails/issues/1583). [PR 3606](https://github.com/shakacode/react_on_rails/pull/3606) by [ihabadham](https://github.com/ihabadham).
- **[Pro]** **Client teardown failures are no longer hidden at `console.info`**: when `ComponentRenderer.unmount()` catches an error from `unmountComponentAtNode` (the React 16/17 legacy unmount path), it now logs at `console.error` instead of `console.info`. A caught error there means the component tree did not unmount cleanly — a teardown failure — and most log collectors and default browser-console filters drop `info`, so the failure was effectively silent. Addresses item 2 of [Issue 3592](https://github.com/shakacode/react_on_rails/issues/3592). [PR 3610](https://github.com/shakacode/react_on_rails/pull/3610) by [justin808](https://github.com/justin808).
- **Renderer functions no longer leak their mount on navigation/unmount**: Renderer functions (the 3-argument `(props, railsContext, domNodeId) => …` registration form) own their own React root, but React on Rails never tracked any cleanup state for them, so every renderer-function mount leaked on Turbo/Turbolinks navigation. Renderer functions may now optionally return a teardown wrapper (`{ teardown: () => void | Promise<void> }`, sync or async); returning nothing keeps the previous behavior, so existing renderers are unaffected. Both the core and Pro client renderers invoke the teardown on page unload and on same-id node replacement, and cleanup failures on same-id replacement are now logged to `console.error` instead of only being visible when tracing is enabled. The renderers differ only in the async race: if a navigation unmounts the mount while an async renderer is still resolving its teardown, Pro still runs the teardown once it resolves, whereas the core renderer is best-effort and may drop a still-pending async teardown while the renderer is awaiting dynamic imports, fetches, or other I/O on a fast navigation; active async renderer failures are logged and then untracked so a later load call can retry. The framework-shipped Pro `wrapServerComponentRenderer` now returns such a teardown wrapper, closing the leak automatically for every `registerServerComponent` user. TypeScript note: the exported `RendererFunction` type covers 3-argument renderers that return nothing or an optional teardown wrapper; `RenderFunction` keeps its existing component/server-result return contract, including legacy 3-argument renderers that returned a component only to satisfy the old type. Fixes [Issue 3209](https://github.com/shakacode/react_on_rails/issues/3209). [PR 3576](https://github.com/shakacode/react_on_rails/pull/3576) by [justin808](https://github.com/justin808).

#### Removed

- **[Pro]** **Removed the legacy license key-file migration warning**: The elapsed migration notices for the legacy `config/react_on_rails_pro_license.key` file path (the cleanup notice shown alongside a valid configured license, and the missing-license migration notice) are no longer emitted. The legacy file itself was already unread. Fixes [Issue 3624](https://github.com/shakacode/react_on_rails/issues/3624). [PR 3715](https://github.com/shakacode/react_on_rails/pull/3715) by [justin808](https://github.com/justin808).

### [17.0.0.rc.1] - 2026-06-02

#### Breaking Changes

- **Ruby 3.3+ is required for React on Rails v17**: The open-source gem now requires Ruby `>= 3.3.0`, aligning it with React on Rails Pro, `create-react-on-rails-app`, and the CI minimum matrix. React on Rails v16 remains the upgrade path for applications that must stay on Ruby 3.2 or older. [PR 3500](https://github.com/shakacode/react_on_rails/pull/3500) by [justin808](https://github.com/justin808).

#### Added

- **[Pro]** **Imperative refetch API for `<RSCRoute>`**: `<RSCRoute>` now accepts an optional `ref` typed as `RSCRouteHandle`, exposing `refetch()` so a parent or sibling can refetch a server component without knowing its `componentName` or `componentProps`. A new `useCurrentRSCRoute()` hook returns the same handle for client components rendered inside the RSC subtree (for example, an inline "Refresh" button rendered by the server component itself); calling it outside an `<RSCRoute>` ancestor throws `useCurrentRSCRoute must be used inside an <RSCRoute>`. Both APIs auto-update the rendered tree with no caller-side `setKey`/`useState` workaround and propagate to every `<RSCRoute>` instance bound to the same cache key. The internal cache invalidation runs inside a React transition, so old content stays visible while the new RSC payload streams in without a Suspense-fallback flash. The existing `useRSC().refetchComponent(name, props)` API and the `ServerComponentFetchError`-based retry flow are unchanged. Fixes [Issue 3106](https://github.com/shakacode/react_on_rails/issues/3106). [PR 3552](https://github.com/shakacode/react_on_rails/pull/3552) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **`<RSCRoute ssr={false}>` defers initial RSC payload generation**: `<RSCRoute>` now accepts `ssr={false}` to skip server-side RSC payload generation for that route — the server streams the nearest `<Suspense>` fallback and the client fetches the payload through the existing `RSCProvider` path (cache lookup, `/rsc_payload/:componentName` fetch, `ServerComponentFetchError`, and `useRSC().refetchComponent(...)` retry). `ssr` defaults to `true`, so existing routes are unchanged and a mixed page can server-render some routes while deferring others. Deferred roots that do not manually call `wrapServerComponentRenderer` are now supported automatically: RSC-enabled generated client packs register a default RSC provider (also exported as `react-on-rails-pro/registerDefaultRSCProvider/client` for manual entrypoints) that wraps auto-bundled `react_component(..., prerender: false)` and deferred-only `stream_react_component` roots. Completes [Issue 3101](https://github.com/shakacode/react_on_rails/issues/3101). [PR 3318](https://github.com/shakacode/react_on_rails/pull/3318), [PR 3394](https://github.com/shakacode/react_on_rails/pull/3394) by [ihabadham](https://github.com/ihabadham).
- **Ruby 4.0 CI support**: Updated OSS latest-runtime CI coverage, local CI switching guidance, and public compatibility docs to test Ruby 4.0 while keeping Ruby 3.3 as the minimum supported CI lane. [PR 3529](https://github.com/shakacode/react_on_rails/pull/3529) by [justin808](https://github.com/justin808).
- **[Pro]** **HTTP rolling-deploy endpoint auto-mount**: Configuring `config.rolling_deploy_adapter = ReactOnRailsPro::RollingDeployAdapters::Http` now automatically mounts `ReactOnRailsPro::RollingDeploy::BundlesController` at `config.rolling_deploy_mount_path` (default `/react_on_rails_pro/rolling_deploy`). Set the mount path to `nil` or blank to opt out and keep a manual `draw_routes` mount; apps that previously mounted the default route manually should remove that route or give secondary manual mounts a distinct `as_prefix:` to avoid duplicate named-route errors. Fixes [Issue 3476](https://github.com/shakacode/react_on_rails/issues/3476). [PR 3504](https://github.com/shakacode/react_on_rails/pull/3504) by [justin808](https://github.com/justin808).

#### Changed

- **Generator defaults to Rspack for fresh installs**: `rails generate react_on_rails:install` and `create-react-on-rails-app` now default to the Rspack bundler on fresh installs (significantly faster builds via SWC), instead of Webpack. Pass `--no-rspack` (or its alias `--webpack`) to use Webpack. This only affects fresh installs — existing apps that already declare an `assets_bundler` in `config/shakapacker.yml` are left unchanged, an explicit `--rspack`/`--no-rspack`/`--webpack` always wins, and the default falls back to Webpack on Shakapacker versions below 9.0 (where Rspack is unsupported). [PR 3484](https://github.com/shakacode/react_on_rails/pull/3484) by [justin808](https://github.com/justin808).

#### Improved

- **RSC setup verification warns on dynamic plugin options**: `react_on_rails:install --rsc` now warns when `new RSCWebpackPlugin(...)` uses computed options that cannot be statically verified, avoiding misleading missing-`clientReferences` reports for dynamic config. Fixes [Issue 3412](https://github.com/shakacode/react_on_rails/issues/3412). [PR 3505](https://github.com/shakacode/react_on_rails/pull/3505) by [justin808](https://github.com/justin808).
- **Rspack-aware diagnostics and dev-server help**: Doctor, system checker, and `bin/dev --help` output now label Rspack apps as Rspack instead of webpack while preserving webpack wording for default apps. Fixes [Issue 3388](https://github.com/shakacode/react_on_rails/issues/3388). [PR 3508](https://github.com/shakacode/react_on_rails/pull/3508) by [justin808](https://github.com/justin808).

#### Fixed

- **Shakapacker config warnings now report resolved relative paths**: When `SHAKAPACKER_CONFIG` is set to a relative missing path, the Rails boot warning now includes the Rails-root-resolved path that React on Rails actually checked. Fixes [Issue 3436](https://github.com/shakacode/react_on_rails/issues/3436). [PR 3441](https://github.com/shakacode/react_on_rails/pull/3441) by [justin808](https://github.com/justin808).
- **Base-port renderer URLs preserve localhost-equivalent hosts**: `bin/dev` base-port mode now keeps localhost-equivalent renderer hosts and schemes, such as `127.0.0.1` and `https://localhost`, when deriving `REACT_RENDERER_URL`; remote or invalid hosts still fall back to `http://localhost:<port>`. Fixes [Issue 3466](https://github.com/shakacode/react_on_rails/issues/3466). [PR 3506](https://github.com/shakacode/react_on_rails/pull/3506) by [justin808](https://github.com/justin808).
- **[Pro]** **Streamed RSC rendering now propagates CSP nonces**: React on Rails Pro now passes the Rails CSP nonce to React's streamed RSC renderer options so streamed script output can satisfy strict content security policies. Fixes [Issue 3491](https://github.com/shakacode/react_on_rails/issues/3491). [PR 3507](https://github.com/shakacode/react_on_rails/pull/3507) by [justin808](https://github.com/justin808).
- **[Pro]** **RSC stream parser tolerates blank separator lines**: `LengthPrefixedStreamParser` now skips blank separator lines (including a lone CR from a split CRLF) between length-prefixed records instead of treating them as malformed headers, matching the default Pro RSC payload template that inserts extra newlines between chunks. Malformed non-empty headers still raise as before, and a stream ending mid-`\r\n` no longer logs a spurious incomplete-stream warning. Fixes [Issue 3499](https://github.com/shakacode/react_on_rails/issues/3499). [PR 3515](https://github.com/shakacode/react_on_rails/pull/3515) by [justin808](https://github.com/justin808).
- **Generated build scripts run the auto-bundle hook before building bundles**: Newly generated apps now run the Shakapacker precompile (auto-bundle) hook before the generated `build`, `build:test`, scaffolded CI, and `build_test_command` bundle builds, so packs are regenerated before bundling. Apps with custom Shakapacker hooks keep them under Shakapacker's control so the hook does not double-run. [PR 3535](https://github.com/shakacode/react_on_rails/pull/3535) by [justin808](https://github.com/justin808).

### [17.0.0.rc.0] - 2026-05-30

#### Breaking Changes

- **[Pro]** **Node Renderer now requires Ruby 3.3+ for the async-http transport**: The `react-on-rails-pro` gem now requires Ruby `>= 3.3` (raised from `>= 3.0`) because `async-http` depends on Ruby 3.3 features. Upgrade Ruby before moving to this release. See `docs/pro/updating.md` for the full upgrade guide. [PR 3320](https://github.com/shakacode/react_on_rails/pull/3320) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **`config.renderer_http_pool_size` now limits async-http connections per renderer client**: Existing numeric values now cap concurrent async-http connections for each renderer client instead of sizing a persistent process-wide connection pool. HTTP/2 may multiplex request streams over those pooled connections. Setting `nil` keeps the default connection limit and does not make the async-http client unlimited. Persistent connection reuse is automatic when a long-lived `Fiber.scheduler` is present. See `docs/pro/updating.md` for the full upgrade guide. [PR 3320](https://github.com/shakacode/react_on_rails/pull/3320) by [AbanoubGhadban](https://github.com/AbanoubGhadban).

#### Added

- **[Pro]** **`unstable_cache` for React Server Component fragment caching**: New experimental `unstable_cache(fn, options)` wrapper memoizes a server component's serialized RSC payload — replaying the stored bytes on a cache hit and tee-ing output to both the response and the cache store on a miss. Ships with a `CacheHandler` interface and a default in-memory LRU handler (register custom backends via `registerCacheHandler`), plus tag-based invalidation through `unstable_revalidateTag(tag)` that broadcasts across all Node Renderer workers via a new `POST /cache/revalidate-tag` endpoint and a Ruby-side `ReactOnRailsPro::RSCCache.revalidate_tag(tag)`. Closes [Issue 3324](https://github.com/shakacode/react_on_rails/issues/3324). [PR 3325](https://github.com/shakacode/react_on_rails/pull/3325) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Node Renderer integration API now exposes lifecycle hooks**: `react-on-rails-pro-node-renderer/integrations/api` now exports the tracing reset, provider-state, Fastify lifecycle, and worker shutdown hooks needed by integrations such as OpenTelemetry, keeping integrations inside the supported public boundary. Fixes [Issue 3419](https://github.com/shakacode/react_on_rails/issues/3419). [PR 3456](https://github.com/shakacode/react_on_rails/pull/3456) by [justin808](https://github.com/justin808).
- **[Pro]** **Built-in HTTP rolling-deploy adapter (scaffold)**: New `ReactOnRailsPro::RollingDeployAdapters::Http` adapter pairs with a mountable `ReactOnRailsPro::RollingDeploy::BundlesController` so the currently-deployed Rails server can directly serve previously-deployed bundles to the next deploy's build CI — no S3 bucket, IAM, or extra gem required. The controller exposes authenticated `GET /manifest` and `GET /bundles/:hash` endpoints using bearer-token auth (constant-time compare, 32-byte minimum), and the adapter pulls bundle tarballs (stdlib-only gzip/tar compose-extract with path-traversal proofing, regular-files-only guards, and a 200 MB zip-bomb cap). Configure via `config.rolling_deploy_adapter = ReactOnRailsPro::RollingDeployAdapters::Http`, `config.rolling_deploy_token`, and `config.rolling_deploy_previous_url`. See `docs/pro/rolling-deploy-adapters.md` for setup. This is part 1 of a multi-PR series — a hard HTTPS gate, streaming download, and additional hardening land in follow-ups. [PR 3379](https://github.com/shakacode/react_on_rails/pull/3379) by [justin808](https://github.com/justin808).
- **[Pro]** **OpenTelemetry integration for the Node Renderer**: New optional integration at `react-on-rails-pro-node-renderer/integrations/opentelemetry` that adds distributed tracing via standard OpenTelemetry. Users enable it by installing the `@opentelemetry/*` and `@fastify/otel` packages (optional peer deps) and calling `init({ fastify: true, tracing: true })` from their renderer entrypoint, before `reactOnRailsProNodeRenderer()`. Provides auto-instrumented HTTP and Fastify spans, an SSR root span (`ror.ssr.request`), and render-path sub-spans (`ror.bundle.build_execution_context`, `ror.bundle.upload`, `ror.vm.execute`, `ror.result.prepare`, `ror.incremental.stream`, `ror.incremental.process_chunk`). Configuration follows standard OpenTelemetry env-var conventions (`OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_SERVICE_NAME`, `OTEL_RESOURCE_ATTRIBUTES`, etc.); defaults to `BatchSpanProcessor` in production and `SimpleSpanProcessor` otherwise. The integration is fully optional — users who do not enable it pay zero runtime cost, and the renderer has no direct dependency on OpenTelemetry. Closes [Issue 2156](https://github.com/shakacode/react_on_rails/issues/2156). [PR 3382](https://github.com/shakacode/react_on_rails/pull/3382) by [justin808](https://github.com/justin808).
- **[Pro]** **Richer Node Renderer span attributes**: `ror.bundle.upload` now records `bytes.total` (sum of bundle + asset upload source sizes); `ror.vm.execute` records `bundle.timestamp`; `ror.result.prepare` records `response.bytes` (UTF-8 byte length of the rendered response, omitted for streamed responses). Only byte counts and identifiers are recorded — request payloads and rendered HTML are never written into span attributes. The `subSpan` API now passes a `SubSpanController` to the wrapped function so integrations can attach attributes computed during the work; existing implementations must call `fn(controller)` (a no-op controller is fine when no span is created). Closes [Issue 3390](https://github.com/shakacode/react_on_rails/issues/3390). [PR 3422](https://github.com/shakacode/react_on_rails/pull/3422) by [justin808](https://github.com/justin808).
- **`react-on-rails/webpackHelpers` subpath export with `reactDomClientWarning`**: New webpack helper export so React 16/17 consumers can suppress the harmless `Module not found: Can't resolve 'react-dom/client'` warning with a one-liner instead of remembering a regex. The require inside `reactApis` is guarded by a runtime React-version check, so this warning never reflects a real failure, but webpack still emits it at build time because the static `require('react-dom/client')` cannot be tree-shaken without breaking React 18+. Pass `reactDomClientWarning` to `ignoreWarnings` (Webpack 5 / Shakapacker) or `stats.warningsFilter` (Webpack 4 / Webpacker 5). Fixes [Issue 3137](https://github.com/shakacode/react_on_rails/issues/3137). [PR 3358](https://github.com/shakacode/react_on_rails/pull/3358) by [justin808](https://github.com/justin808).
- **`bin/dev` deterministic port allocation via `REACT_ON_RAILS_BASE_PORT` (and `CONDUCTOR_PORT`)**: `bin/dev` now derives Rails / webpack-dev-server / node-renderer ports from a single base port when `REACT_ON_RAILS_BASE_PORT` (or `CONDUCTOR_PORT`, for [Conductor.build](https://conductor.build) workspaces) is set: Rails = `base + 0`, webpack = `base + 1`, renderer = `base + 2`. This makes parallel worktrees and coding-agent sandboxes collision-free without per-service env vars. The priority chain is base port → explicit per-service env vars (`PORT`, `SHAKAPACKER_DEV_SERVER_PORT`) → auto-detection. **Behavior note:** when base-port mode is active, any pre-set `PORT`, `SHAKAPACKER_DEV_SERVER_PORT`, `RENDERER_PORT`, or non-matching `REACT_RENDERER_URL` (and the legacy `RENDERER_URL`, when already set) is unconditionally overwritten with the derived value (a warning is printed before each override). This applies in all `bin/dev` modes including `bin/dev prod`, where `SHAKAPACKER_DEV_SERVER_PORT` is also derived/overwritten for tooling consistency even though the production-like mode does not run webpack-dev-server. **Sub-process env preservation:** to keep these derived values consistent across spawned processes, `bin/dev` now also preserves `RENDERER_PORT`, `REACT_RENDERER_URL`, and `SHAKAPACKER_SKIP_PRECOMPILE_HOOK` across Bundler's env reset (previously only `PORT` and `SHAKAPACKER_DEV_SERVER_PORT` were preserved); this prevents nested `shakapacker` commands from silently re-running the precompile hook or losing the renderer URL. [PR 3142](https://github.com/shakacode/react_on_rails/pull/3142) by [justin808](https://github.com/justin808).
- **[Pro] `bin/dev` auto-derives `REACT_RENDERER_URL` from `RENDERER_PORT`**: When only `RENDERER_PORT` is set, `bin/dev` now sets `REACT_RENDERER_URL=http://localhost:RENDERER_PORT` so Rails reaches the right port by default. Users running a remote or non-localhost node renderer (Docker service, remote host) should set `REACT_RENDERER_URL` explicitly so it is not replaced with the localhost default. [PR 3142](https://github.com/shakacode/react_on_rails/pull/3142) by [justin808](https://github.com/justin808).
- **[Pro]** **Pre-seed renderer cache for Docker builds**: New `react_on_rails_pro:pre_seed_renderer_cache` rake task copies compiled server bundles into the Node Renderer's bundle-hash cache directory structure during Docker image builds, eliminating the 410→retry cold-start latency (200ms–1s+) on the first SSR request after deployment. Supports `RENDERER_SERVER_BUNDLE_CACHE_PATH`, RSC bundles, and rolling-deploy guidance centered on current and previous bundle hashes. The legacy `pre_stage_bundle_for_node_renderer` task now stages the same cache layout via symlinks for same-filesystem workflows. **Note:** `RENDERER_BUNDLE_PATH` is now deprecated in favor of `RENDERER_SERVER_BUNDLE_CACHE_PATH` across both tasks. Existing users with `RENDERER_BUNDLE_PATH` set will see a deprecation warning on stderr. [PR 3124](https://github.com/shakacode/react_on_rails/pull/3124) by [justin808](https://github.com/justin808).
- **[Pro]** **Rolling-deploy adapter protocol**: New `config.rolling_deploy_adapter` pluggable module (protocol: `previous_bundle_hashes`, `fetch`, `upload`) that seeds previously-deployed bundle hashes into the Node Renderer cache, preventing 410→retry for draining-version requests during rolling deploys. `assets:precompile` auto-calls `upload` in production-like environments so the next deploy can fetch the just-built bundle. `PREVIOUS_BUNDLE_HASHES` env var overrides discovery for CI. `react_on_rails:doctor` probes the adapter and reports protocol conformance, discovery latency, and resolved cache dir. Each seeded hash carries its own `loadable-stats.json` / RSC manifests so client-side hydration stays consistent with the deployed asset pipeline for that hash. See `docs/pro/rolling-deploy-adapters.md` for the full protocol spec and reference implementations (S3, Control Plane, Filesystem). [PR 3173](https://github.com/shakacode/react_on_rails/pull/3173) by [justin808](https://github.com/justin808).
- **[Pro]** **Async props with incremental React Server Component rendering**: Added the `stream_react_component_with_async_props` and `rsc_payload_react_component_with_async_props` view helpers, which accept a block to declare props that are fetched concurrently and streamed to the rendering component as each value becomes available. The React component renders its shell immediately (with `<Suspense>` fallbacks) and progressively re-renders as async prop promises resolve, dramatically improving Time to First Byte for pages with slow data fetches. Components access async props through the `getReactOnRailsAsyncProp` function injected into props (typed via the new `WithAsyncProps` TypeScript helper). Requires `config.enable_rsc_support = true`. This is an additive feature — existing `stream_react_component` and `rsc_payload_react_component` calls are unaffected. [PR 2903](https://github.com/shakacode/react_on_rails/pull/2903) by [AbanoubGhadban](https://github.com/AbanoubGhadban).

#### Changed

- **[Pro]** **`RollingDeployCacheStager` now rejects bundle hashes that start with a hyphen**: The shared `ReactOnRailsPro::RollingDeploy::SAFE_HASH_PATTERN` constant (also used by the new HTTP rolling-deploy adapter) tightens the cache stager's old local pattern by additionally rejecting leading hyphens. Webpack content hashes never start with `-` in practice, so this is a no-op for default toolchains, but operators running a custom rolling-deploy adapter that emits hyphen-prefixed hashes will now see those hashes silently dropped from the staged set. If you depend on hyphen-prefixed hashes, rename them to start with an alphanumeric character or `_`. [PR 3379](https://github.com/shakacode/react_on_rails/pull/3379) by [justin808](https://github.com/justin808).
- **Upgrade contributor pnpm tooling to 10.33.4**: The monorepo now pins pnpm 10.33.4 with Corepack's hash-qualified `packageManager` format, keeps the install-generator CI fallback on the same pnpm version, and relies on the root workspace pin instead of duplicate workspace `packageManager` declarations. [PR 3400](https://github.com/shakacode/react_on_rails/pull/3400) by [alexeyr-ci2](https://github.com/alexeyr-ci2).
- **Allow trusted pnpm 10 build scripts in contributor installs**: The root workspace now allowlists required native dependency postinstall checks for `@swc/core` and `unrs-resolver`, so `pnpm install` under pnpm 10 no longer skips those trusted build hooks. [PR 3421](https://github.com/shakacode/react_on_rails/pull/3421) by [justin808](https://github.com/justin808).
- **Release publishing now checks `origin/main` CI status before shipping**: `rake release` now inspects GitHub Checks for `origin/main` before publishing, blocking stable releases on any visible failing or missing checks and prereleases on required checks, with an explicit override path for maintainers. [PR 3407](https://github.com/shakacode/react_on_rails/pull/3407) by [justin808](https://github.com/justin808).
- **[Pro]** **Updated Pino in the Node Renderer**: Raised the `react-on-rails-pro-node-renderer` `pino` dependency range to `^9.14.0 || ^10.1.0`, aligning with the current Fastify dependency. [PR 3401](https://github.com/shakacode/react_on_rails/pull/3401) by [alexeyr-ci2](https://github.com/alexeyr-ci2).
- **[Pro]** **Async Rails server deployments use scheduler-scoped renderer clients**: Falcon and async-rails deployments can use the async-http renderer client when a long-lived `Fiber.scheduler` is already running; renderer clients are reused within that scheduler. Standard Puma streaming uses a per-request scheduler and cleans up the client when the response ends. See `docs/pro/updating.md` for the full upgrade guide. [PR 3320](https://github.com/shakacode/react_on_rails/pull/3320) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Per-scheduler persistent HTTP connections for Node Renderer**: `RendererHttpClient` now reuses HTTP/2 connections across requests within the same Fiber scheduler (Falcon, async Puma), eliminating per-request TCP+TLS+HTTP/2 handshake overhead. Standalone requests (no outer scheduler) continue using ephemeral connections with guaranteed cleanup. The internal connection pool automatically recovers from broken connections without manual eviction. [PR 3428](https://github.com/shakacode/react_on_rails/pull/3428) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Migrated Node Renderer HTTP transport from HTTPX to `async-http`**: React on Rails Pro now uses `async-http` (`~> 0.95`) with `io-endpoint` (`~> 0.17`) for all Rails→Node Renderer requests (render, streaming render, asset upload), replacing the previous HTTPX adapter and the custom `httpx_stream_bidi_patch.rb`. The new `RendererHttpClient` is a request-scoped client (one client per Rails request — no persistent process-wide pool) and integrates with the length-prefixed wire protocol introduced in [PR 2903](https://github.com/shakacode/react_on_rails/pull/2903). HTTP/2 bidirectional streaming for async props is now provided by `post_bidi` on the new adapter. **Action required for upgraders:**
  - **`config.ssr_timeout`** is now a per-read socket timeout applied to each renderer socket read, rather than a task-level timeout wrapping the entire request.
  - **`config.renderer_http_pool_timeout`** is now the TCP connect timeout; post-connect reads are bounded by `ssr_timeout`.
  - **No implicit transport retry** for connection drops: drops surface immediately as `ReactOnRailsPro::Error`/connection failures. HTTPX previously performed one implicit transport retry; the new adapter uses `retries: 0` and leaves retry policy to the existing bundle-upload retry loop.

  See `docs/pro/updating.md` for the full upgrade guide. [PR 3320](https://github.com/shakacode/react_on_rails/pull/3320) by [AbanoubGhadban](https://github.com/AbanoubGhadban).

- **[Pro]** **`PreSeedRendererCache` and `PrepareNodeRenderBundles` now auto-stage `loadable-stats.json`**: `ReactOnRailsPro::RendererCacheHelpers.collect_assets` now appends `loadable-stats.json` whenever the file exists on disk, so every caller (rolling-deploy seeding, `pre_seed_renderer_cache`, `pre_stage_bundle_for_node_renderer`) stages it automatically. **Action required for upgraders:** if your `assets_to_copy` config explicitly listed `loadable-stats.json`, remove that entry — otherwise you'll see a "Duplicate asset basenames in assets_to_copy" warning on every stage. The duplicate is harmless (`stage_assets` keeps the last entry per basename), but the warning is noise. [PR 3173](https://github.com/shakacode/react_on_rails/pull/3173) by [justin808](https://github.com/justin808).
- **[Pro]** **Unified renderer cache staging**: `ReactOnRailsPro::PreSeedRendererCache.call(mode: :copy | :symlink)` is now the single entry point for staging the Node Renderer cache. Both modes produce the same `<cache>/<bundleHash>/<bundleHash>.js` layout. The `react_on_rails_pro:pre_seed_renderer_cache` rake task accepts `MODE=copy` (default; Docker/image builds) or `MODE=symlink` (same-filesystem). The auto-invocation at the end of `assets:precompile` defaults to `:symlink` (preserving prior behavior) and now honors `ASSETS_PRECOMPILE_RENDERER_CACHE_MODE=copy|symlink` so Docker builds that run `rake assets:precompile` as the final asset step can opt into copy mode without invoking the rake task separately. `MODE=copy` raises a clear error when neither `RENDERER_SERVER_BUNDLE_CACHE_PATH` nor `RENDERER_BUNDLE_PATH` is set in non-dev/test environments, because the Node renderer's default lookup can differ from the Ruby side and would silently drop pre-seeded bundles in the wrong directory. The legacy `react_on_rails_pro:pre_stage_bundle_for_node_renderer` task and `ReactOnRailsPro::PrepareNodeRenderBundles` class remain as deprecated shims that emit a once-per-process warning and delegate to `mode: :symlink`. `react_on_rails:doctor` flags deploy scripts that still reference the deprecated task. **Heads-up for custom scripts:** the previous flat layout wrote `$RENDERER_BUNDLE_PATH/<renderer_bundle_file_name>`; any external scripts (health checks, renderer launchers) that read that path directly must now read `$RENDERER_SERVER_BUNDLE_CACHE_PATH/<bundleHash>/<bundleHash>.js` instead. [PR 3124](https://github.com/shakacode/react_on_rails/pull/3124) by [justin808](https://github.com/justin808).
- **[Pro]** **Pro generator now creates the Node Renderer at `renderer/node-renderer.js`**: The canonical location for the Node Renderer entry point is now a dedicated top-level `renderer/` directory instead of `client/`, making it straightforward to exclude from production Docker builds that strip JS sources after bundling. Docs and Pro `spec/dummy` now use the new path consistently. Existing apps are unaffected — the generator skips files that already exist (including a legacy `client/node-renderer.js`). Fixes [Issue 3073](https://github.com/shakacode/react_on_rails/issues/3073). [PR 3165](https://github.com/shakacode/react_on_rails/pull/3165) by [justin808](https://github.com/justin808).
- **[Pro] Documentation standardized on `REACT_RENDERER_URL` env var name**: The configuration example in `docs/oss/configuration/configuration-pro.md` now shows `ENV["REACT_RENDERER_URL"]` instead of the older `ENV["RENDERER_URL"]`, aligning with the rest of the docs and the generator template. Existing apps that read `ENV["RENDERER_URL"]` in their initializer continue to work — the Pro `renderer_url` config is whichever env var the user reads in their initializer; no gem code reads either name directly. Rename the env var in your infrastructure configs (and update the initializer to match) if you want to align with the new convention. `bin/dev` now also warns when `RENDERER_URL` is set without `REACT_RENDERER_URL` so the rename doesn't silently fall back to the default renderer URL. [PR 3142](https://github.com/shakacode/react_on_rails/pull/3142) by [justin808](https://github.com/justin808).
- **Length-prefixed streaming wire protocol**: The internal protocol between the Rails gems and the Node renderer (and the in-process bundle for the OSS non-streaming path) now uses a length-prefixed framing — `<metadata JSON>\t<content byte length hex>\n<raw content bytes>` — instead of wrapping every HTML chunk in a JSON envelope, eliminating ~30% serialize/escape overhead on streamed HTML and correctly handling multibyte content and chunk boundaries. This is an internal transport detail: React on Rails always ships the `react_on_rails`/`react_on_rails_pro` gems, the `react-on-rails`/`react-on-rails-pro` npm packages, and the `react-on-rails-pro-node-renderer` as a matched version set, and the Ruby parser also auto-detects the legacy JSON format, so no application action is required when upgrading all artifacts together. [PR 2903](https://github.com/shakacode/react_on_rails/pull/2903) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **`react_on_rails:doctor` renderer-cache scan covers CI/CD manifests**: The deprecated-task scan that flags `react_on_rails_pro:pre_stage_bundle_for_node_renderer` now also checks `.circleci/config.yml`, `.gitlab-ci.yml`, `bitbucket-pipelines.yml`, every `.github/workflows/*.yml`/`.yaml`, and every `config/deploy/*.rb` stage file, on top of the existing Procfile/Dockerfile/Compose/Kamal/Capistrano/`bin/*`/`scripts/deploy.sh` paths. The scan stays bounded: per-file size cap, no `**` globs, a per-glob match cap, per-file rescue, and a separate per-glob rescue so a single unreadable workflow or stage file cannot abort the rest of the scan. Fixes [Issue 3247](https://github.com/shakacode/react_on_rails/issues/3247). [PR 3329](https://github.com/shakacode/react_on_rails/pull/3329) by [justin808](https://github.com/justin808).
- **Rspack install scaffolding now targets Rspack v2**: `react_on_rails:install --rspack` and `bin/switch-bundler` now generate the Rspack v2 package line (`@rspack/core@^2.0.0-0`, `@rspack/cli@^2.0.0-0`, `@rspack/plugin-react-refresh@^2.0.0`) while keeping `rspack-manifest-plugin@^5.0.0`, which is already compatible. Closes [Issue 3082](https://github.com/shakacode/react_on_rails/issues/3082). [PR 3084](https://github.com/shakacode/react_on_rails/pull/3084) by [justin808](https://github.com/justin808).

#### Improved

- **Resolved Shakapacker config path warnings now show the expanded path**: Missing `SHAKAPACKER_CONFIG` warnings now include the Rails-root-resolved path that was checked, making relative-path typos easier to diagnose. [PR 3444](https://github.com/shakacode/react_on_rails/pull/3444) by [justin808](https://github.com/justin808).

#### Fixed

- **[Pro]** **RSC client-hook runtime errors now explain the missing client boundary**: React on Rails Pro now rewrites RSC runtime hook failures such as `useState is not a function` with a diagnostic that names the registered component, points to the likely missing `"use client";` directive, and clarifies that `.client`/`.server` suffixes only control bundle placement. Fixes [Issue 3184](https://github.com/shakacode/react_on_rails/issues/3184). [PR 3461](https://github.com/shakacode/react_on_rails/pull/3461) by [justin808](https://github.com/justin808).
- **Test asset compiler output is now bundler-neutral**: Test asset compilation now prints "Building assets..." and "Completed building assets." instead of Webpack-specific wording, and failure guidance tells users to rerun their configured `build_test_command` instead of naming Shakapacker. Fixes [Issue 3455](https://github.com/shakacode/react_on_rails/issues/3455). [PR 3462](https://github.com/shakacode/react_on_rails/pull/3462) by [justin808](https://github.com/justin808).
- **Test helper dev-asset guidance is now bundler-neutral**: HMR warnings, missing generated-file guidance, and test-helper comments now refer to the configured bundler/dev server instead of Webpack or Shakapacker-specific commands while keeping the existing public `WebpackAssets*` API names. Fixes [Issue 3478](https://github.com/shakacode/react_on_rails/issues/3478). [PR 3513](https://github.com/shakacode/react_on_rails/pull/3513) by [justin808](https://github.com/justin808).
- **[Pro]** **RSC stream failures now surface original diagnostics**: RSC payload stream metadata now preserves the original RSC bundle exception message, stack, component name, and module path where available across server-bundle rendering, Rails `PrerenderError`, and browser fetch paths. Fixes [Issue 3182](https://github.com/shakacode/react_on_rails/issues/3182). [PR 3463](https://github.com/shakacode/react_on_rails/pull/3463) by [justin808](https://github.com/justin808).
- **[Pro]** **`react_on_rails:doctor` renderer-cache scan now covers Jenkinsfile**: The deprecated-task scan that flags `react_on_rails_pro:pre_stage_bundle_for_node_renderer` now also checks `Jenkinsfile`, alongside the existing CI/CD manifests and deploy scripts. Fixes [Issue 3269](https://github.com/shakacode/react_on_rails/issues/3269). [PR 3442](https://github.com/shakacode/react_on_rails/pull/3442) by [justin808](https://github.com/justin808).
- **Client-only Vite setups no longer fail Rails boot on Shakapacker's `packageManager` guard**: React on Rails now installs an engine initializer that runs before `shakapacker.manager_checker` and no-ops Shakapacker's `error_unless_package_manager_is_obvious!` when the host app has no Shakapacker config (`config/shakapacker.yml` or `SHAKAPACKER_CONFIG`). This unblocks apps that use the `react-on-rails/client` npm package from an existing Vite entrypoint and do not use the Ruby render helpers. The Ruby helpers that resolve bundle paths still require Shakapacker configuration. Apps with Shakapacker config keep Shakapacker's guard unchanged. Fixes [Issue 3145](https://github.com/shakacode/react_on_rails/issues/3145). [PR 3365](https://github.com/shakacode/react_on_rails/pull/3365) by [justin808](https://github.com/justin808).
- **[Pro]** **HTTP rolling-deploy bundle responses now include stronger no-cache headers**: The built-in rolling-deploy manifest and bundle endpoints now send `Pragma: no-cache` and `X-Content-Type-Options: nosniff` alongside `Cache-Control: no-store`, reducing the risk of legacy caching or MIME-sniffing mishandling authenticated bundle payloads. [PR 3439](https://github.com/shakacode/react_on_rails/pull/3439) by [justin808](https://github.com/justin808).
- **[Pro]** **OpenTelemetry shutdown timeout warning never logged**: `shutdownProviderWithTimeout` in the Node Renderer's OpenTelemetry integration was missing a `log.warn(` call, leaving a bare string literal that produced no diagnostic when `provider.shutdown()` exceeded its timeout (and broke the source file's compilation). The timeout message now logs correctly. Follow-up to [PR 3382](https://github.com/shakacode/react_on_rails/pull/3382). [PR 3420](https://github.com/shakacode/react_on_rails/pull/3420) by [justin808](https://github.com/justin808).
- **[Pro]** **HTTP rolling-deploy adapter now streams bundle downloads with a compressed-size cap**: `ReactOnRailsPro::RollingDeployAdapters::Http` writes `GET /bundles/:hash` success responses to a Tempfile with a 50 MB compressed-body limit before extraction, and drains non-success responses through the same cap so oversized error bodies cannot exhaust heap. The existing 200 MB uncompressed tarball cap remains in place. Fixes [Issue 3416](https://github.com/shakacode/react_on_rails/issues/3416). [PR 3435](https://github.com/shakacode/react_on_rails/pull/3435) by [justin808](https://github.com/justin808).
- **`bin/dev` and doctor now label live reload defaults correctly**: `bin/dev help` and `react_on_rails:doctor` now read `config/shakapacker.yml` before describing the default `Procfile.dev` mode, so apps using Shakapacker's live reload default are labeled as live reload instead of HMR. Doctor also treats Shakapacker's `hmr: only` mode as HMR when deciding whether to show HMR-specific warnings. Dev-server mode detection accepts both unquoted YAML booleans (`hmr: true`) and their quoted, case-insensitive equivalents (`hmr: "true"`, `hmr: "TRUE"`), so apps with the quoted-boolean YAML anti-pattern still get correct labels and HMR-specific doctor warnings. Other non-boolean values (integers, arbitrary strings besides `"only"`) and configs without an explicit `dev_server` block fall back to Shakapacker's live reload default for help text. Apps that keep HMR settings only under top-level `default.dev_server` should move them under `development.dev_server` or inherit them with a YAML anchor if they want HMR-specific doctor warnings. Custom `SHAKAPACKER_CONFIG` paths and symbol-valued YAML settings are respected during mode detection. Fixes [Issue 3374](https://github.com/shakacode/react_on_rails/issues/3374). [PR 3377](https://github.com/shakacode/react_on_rails/pull/3377) by [justin808](https://github.com/justin808).
- **[Pro]** Streaming server-render responses now raise `ReactOnRailsPro::Error` when the stream response status is unavailable or the renderer delivers a readable HTTP error status as a streaming body, instead of silently returning no chunks. This is a user-visible behavior change for callers that do not already rescue `ReactOnRailsPro::Error` from `each_chunk`. [PR 3383](https://github.com/shakacode/react_on_rails/pull/3383).
- **[Pro]** **TanStack Router hydration now supports the current router stores API**: `react-on-rails-pro/tanstack-router` client hydration now uses TanStack Router's current `router.stores.setMatches()` API when `router.__store.setState()` is unavailable, so SSR hydration works with newer `@tanstack/react-router` releases without app-level compatibility shims. Fixes [Issue 3375](https://github.com/shakacode/react_on_rails/issues/3375). [PR 3376](https://github.com/shakacode/react_on_rails/pull/3376) by [justin808](https://github.com/justin808).
- **[Pro]** **TanStack Router hydration no longer double-calls `loadRouteChunk` under React 18 StrictMode**: React 18's StrictMode double-renders components with fresh hook state on each pass, so the `routerRef.current === null` guard in `clientHydrate.ts` fired twice when `options.createRouter` returned the same router instance, re-running `loadRouteChunk`, `__store.setState`, and the user-defined `hydrate` callback. The render-phase init is now memoized via a module-level `WeakMap` keyed on the router instance, dedup'ing per-router side effects across mount cycles. Production behavior is unchanged because each mount creates a fresh router. Fixes [Issue 3405](https://github.com/shakacode/react_on_rails/issues/3405). [PR 3410](https://github.com/shakacode/react_on_rails/pull/3410) by [justin808](https://github.com/justin808).
- **[Pro]** **Benchmark CI starts the production dummy app on the expected port**: `react_on_rails_pro/spec/dummy/bin/prod` now sets `PORT=3001` by default before launching Foreman, preventing Foreman's default `PORT=5000` from making the Rails server miss the benchmark workflow readiness check on `localhost:3001`. Both `react_on_rails/spec/dummy/bin/prod` and `react_on_rails_pro/spec/dummy/bin/prod` respect `PORT` when it's set. [PR 3403](https://github.com/shakacode/react_on_rails/pull/3403) by [alexeyr-ci2](https://github.com/alexeyr-ci2).
- **CI fails on stale lockfiles outside minimum-dependency jobs**: GitHub Actions now runs Bundler with frozen lockfiles for standard integration, Pro, Playwright, lint, and precompile jobs, and no longer mutates lockfiles with `bundle lock --add-platform`. `pnpm install` is also frozen in Playwright. The intentionally mutable minimum-dependency jobs still use non-frozen installs after `script/convert`. [PR 3404](https://github.com/shakacode/react_on_rails/pull/3404), [PR 3430](https://github.com/shakacode/react_on_rails/pull/3430) by [alexeyr-ci2](https://github.com/alexeyr-ci2).
- **[Pro]** **Generated `bin/dev` Procfiles now start the Node Renderer**: Pro setup now appends a `node-renderer` process to `Procfile.dev`, `Procfile.dev-static-assets`, and `Procfile.dev-prod-assets` when those files exist, so SSR pages work in `bin/dev`, `bin/dev static`, and `bin/dev prod`. `react_on_rails:doctor` now warns when a Pro NodeRenderer app's launcher Procfiles can serve Rails pages but do not start a renderer on `RENDERER_PORT`. Fixes [Issue 3372](https://github.com/shakacode/react_on_rails/issues/3372). [PR 3381](https://github.com/shakacode/react_on_rails/pull/3381) by [justin808](https://github.com/justin808).
- **Prerelease changelog auto-versioning now warns for cross-channel reuse**: `bundle exec rake update_changelog[rc]` and `[beta]` now correctly warn when an active prerelease base exists only in a different prerelease channel, helping maintainers catch accidental channel switches before stamping a release header. [PR 3417](https://github.com/shakacode/react_on_rails/pull/3417) by [justin808](https://github.com/justin808).
- **Release pipeline verifies published npm packages and blocks `workspace:` dependency leaks**: `rake release:npm` now polls `npm view` after each `pnpm publish` and aborts when the published version is missing, mismatched, or when any install-time `dependencies`/`optionalDependencies`/`peerDependencies` still contains a `workspace:` protocol entry. Before publishing, package manifests are temporarily rewritten to replace `workspace:` ranges with publishable semver and restored afterward. The broken `16.7.0-rc.1` npm publish shipped `react-on-rails-pro@16.7.0-rc.1` with `react-on-rails: "workspace:*"` in its dependency metadata, which Yarn v1 cannot install from the registry; this safeguard prevents future releases from leaking the same protocol. [PR 3387](https://github.com/shakacode/react_on_rails/pull/3387) by [justin808](https://github.com/justin808).
- **Install generator preserves explicit version pins when package-manager install fails**: The install generator's `add_packages` path now writes versioned `name@version` specs directly into `package.json` (under `dependencies` or `devDependencies`) as a last-resort fallback when neither the primary nor fallback package manager install succeeds, so users can rerun their package manager manually without losing the pins. Specs without an explicit version are not written. [PR 3387](https://github.com/shakacode/react_on_rails/pull/3387) by [justin808](https://github.com/justin808).
- **[Pro]** **RSC client manifest restored when only `registerServerComponent/client` is in the pack graph**: `wrapServerComponentRenderer/client` now directly imports `react-on-rails-rsc/client.browser` as a side-effect import. Previously the client runtime was only reachable through a three-level transitive chain (`wrapServerComponentRenderer/client` → `getReactServerComponent.client` → `react-on-rails-rsc/client.browser`). Tooling that severed any link in that chain (tree-shaking, transpiler quirks, custom `NormalModuleReplacement`, externals) caused `RSCWebpackPlugin` to emit `Client runtime at react-on-rails-rsc/client was not found. React Server Components module map file react-client-manifest.json was not created.` and silently skip the manifest, breaking RSC hydration on the Pro Node Renderer. The direct import keeps the runtime resource in the module graph so the plugin always emits `react-client-manifest.json`. Fixes [#3366](https://github.com/shakacode/react_on_rails/issues/3366). [PR 3368](https://github.com/shakacode/react_on_rails/pull/3368) by [justin808](https://github.com/justin808).
- **[Pro]** **Updated Fastify in the Node Renderer for CVE-2026-33806**: Raised the direct `fastify` dependency to 5.8.5 so user-provided Fastify server options, including `trustProxy`, pick up the upstream security fix. [PR 3152](https://github.com/shakacode/react_on_rails/pull/3152) by [dependabot\[bot\]](https://github.com/apps/dependabot).
- **[Pro]** **TanStack Router hydration no longer bails to a full client re-render**: TanStack Router SSR pages no longer discard server-rendered HTML during hydration because the client tree now renders `RouterProvider` with the same shape as the server output. Post-hydration navigation still waits for matched lazy route chunks before `router.load()`. [PR 3213](https://github.com/shakacode/react_on_rails/pull/3213) by [Seifeldin7](https://github.com/Seifeldin7).
- **[Pro]** **Widened ruby-jwt support to `jwt >= 2.7`**: React on Rails Pro relaxes the previous `~> 2.7` cap to `jwt >= 2.7`, so applications can resolve the patched ruby-jwt 3.2.0+ release for the empty-key HMAC advisory while apps still on jwt 2.x remain compatible. [PR 3322](https://github.com/shakacode/react_on_rails/pull/3322), [PR 3344](https://github.com/shakacode/react_on_rails/pull/3344) by [ihabadham](https://github.com/ihabadham).
- **[Pro]** **Pro migration generator rewrites all base-package references and preserves Gemfile pins**: `rails generate react_on_rails:pro` now rewrites Jest/Vitest mock helpers (`jest.mock`, `vi.mock`, `requireActual`/`importActual`, and the rest) and TypeScript `declare module 'react-on-rails'` blocks alongside its existing `import`/`require`/dynamic-import handling, and the Gemfile swap now preserves the user's existing version pin (and other gem options) instead of overwriting them with the running gem's version. `react_on_rails:doctor` is widened to match: it also flags stale side-effect imports (`import 'react-on-rails';`), Jest/Vitest mock helpers, and `declare module` blocks, and the new side-effect-import pattern keeps the doctor a superset of the rewriter so anything the rewriter doesn't reach gets surfaced. Closes [Issue 3104](https://github.com/shakacode/react_on_rails/issues/3104). [PR 3232](https://github.com/shakacode/react_on_rails/pull/3232) by [justin808](https://github.com/justin808).
- **[Pro]** **Pro migration scans TypeScript 4.7 `.mts` and `.cts` modules**: `react_on_rails:doctor` and the Pro migration rewriter now include `.mts`/`.cts` source files (and their `.d.mts`/`.d.cts` declaration counterparts) when looking for stale `react-on-rails` references, matching the existing `.mjs`/`.cjs` coverage. Fixes [Issue 3250](https://github.com/shakacode/react_on_rails/issues/3250). [PR 3334](https://github.com/shakacode/react_on_rails/pull/3334) by [justin808](https://github.com/justin808).
- **Doctor now honors nested JavaScript package roots**: `react_on_rails:doctor` now checks package-manager lockfiles, `package.json`, and installed React from the configured `node_modules_location`, reducing false diagnostics for legacy apps that keep dependencies under `client/`. The Vite migration guide now documents the supported thin-wrapper pattern for those layouts. Note: a missing `package.json` at the configured `node_modules_location` now emits a warning instead of being silently skipped, so apps misconfigured against a nonexistent path will see new diagnostics on upgrade. Fixes [Issue 3205](https://github.com/shakacode/react_on_rails/issues/3205). [PR 3220](https://github.com/shakacode/react_on_rails/pull/3220) by [justin808](https://github.com/justin808).
- **Generated pack regeneration is now serialized**: `generate_packs_if_stale` now uses a Rails `tmp/` lock file, re-checks staleness after waiting, and avoids concurrent cleanup/regeneration races when multiple processes trigger auto-bundling at the same time. Fixes [Issue 1627](https://github.com/shakacode/react_on_rails/issues/1627). [PR 3231](https://github.com/shakacode/react_on_rails/pull/3231) by [justin808](https://github.com/justin808).
- **Install generator validates the selected JavaScript package manager**: The install generator now checks the manager selected from `REACT_ON_RAILS_PACKAGE_MANAGER`, the `packageManager` field in `package.json`, or a lockfile on disk — instead of passing when any JavaScript package manager is installed. When the selected command is missing, the error names the selected manager, the source that selected it, and the available alternatives. The generator also warns when `REACT_ON_RAILS_PACKAGE_MANAGER` is set to a value outside the supported set (`npm`, `pnpm`, `yarn`, `bun`). Addresses package manager validation from [Issue 1958](https://github.com/shakacode/react_on_rails/issues/1958). [PR 3229](https://github.com/shakacode/react_on_rails/pull/3229) by [justin808](https://github.com/justin808).
- **Server-render error wrapping preserves original causes**: When server rendering catches a non-`Error` thrown value, React on Rails now wraps it with the original value attached as `cause`, making downstream debugging preserve more context. Fixes [Issue 1746](https://github.com/shakacode/react_on_rails/issues/1746). [PR 3230](https://github.com/shakacode/react_on_rails/pull/3230) by [justin808](https://github.com/justin808).
- **`bin/dev` now cleans copied runtime files before startup**: When you duplicate an app directory to run another local dev stack, `bin/dev` now removes copied stale Overmind sockets and stale `tmp/pids/server.pid` files that point to a Puma process running from another app directory. This prevents false startup failures in copied workspaces while still preserving active local sockets and pid files for the current app. [PR 3142](https://github.com/shakacode/react_on_rails/pull/3142) by [justin808](https://github.com/justin808).
- **`bin/dev kill` is more thorough and Pro-aware under base-port mode**: `ServerManager.kill_processes` no longer short-circuits after the first successful step — pattern-based kills, port-based kills, and socket/pid cleanup all run unconditionally so a stale renderer port-binding or socket file cannot survive a `bin/dev kill`. In base-port mode, the derived renderer port (`base+2`) is now always included in port-based killing when `react_on_rails_pro` is loaded, even if `RENDERER_PORT` / `REACT_RENDERER_URL` are unset in the current shell (an informational message is printed so the wider scan is not silent). `ProcessManager` also now preserves the legacy `RENDERER_URL` env var alongside `REACT_RENDERER_URL` across Bundler's env reset so mid-migration users keep a consistent renderer URL in spawned subprocesses. [PR 3274](https://github.com/shakacode/react_on_rails/pull/3274) by [justin808](https://github.com/justin808).
- **CI change detection handles shallow clones with long-lived branches**: `script/ci-changes-detector` and `script/check-docs-sidebar` now resolve an actual merge base before diffing, deepening shallow `origin/main` and current-branch history as needed. `ci-changes-detector` now fails visibly when it cannot compute a safe diff instead of treating git failures as no changes. Fixes [Issue 3108](https://github.com/shakacode/react_on_rails/issues/3108). [PR 3224](https://github.com/shakacode/react_on_rails/pull/3224) by [justin808](https://github.com/justin808).
- **[Pro]** **RSC setup now scopes client-reference discovery to app source**: Generated RSC webpack configs now pass `clientReferences` based on Shakapacker's `source_path`, avoiding CI failures where the plugin could scan vendored gem templates under `vendor/bundle`. Fixes [Issue 3201](https://github.com/shakacode/react_on_rails/issues/3201). [PR 3219](https://github.com/shakacode/react_on_rails/pull/3219) by [justin808](https://github.com/justin808).
- **[Pro]** **Node renderer now exposes `performance` when `supportModules: true`**: React 19's development build of `React.lazy` calls `performance.now()`, which previously threw `ReferenceError: performance is not defined` inside the node renderer's VM context unless users manually added `performance` via `additionalContext`. `performance` is now included in the default globals alongside `Buffer`, `process`, etc. Fixes [Issue 3154](https://github.com/shakacode/react_on_rails/issues/3154). [PR 3158](https://github.com/shakacode/react_on_rails/pull/3158) by [justin808](https://github.com/justin808).
- **Scaffolded CI workflow pins a pnpm version when `packageManager` is absent**: The generated `.github/workflows/ci.yml` now emits `with: version:` for `pnpm/action-setup@v4` when pnpm is detected from `pnpm-lock.yaml` alone, preventing the setup step from failing before dependency install. When `packageManager` is declared in `package.json`, the version key is omitted so the action reads the pin from there. Note: `GeneratorMessages.detect_package_manager(package_json: nil)` now treats `nil` as "caller cached that the file is absent" and skips disk fallback, instead of re-reading `package.json`; the previous fallthrough behavior is now the default (omit the keyword) and is documented on `read_package_json`. Fixes [Issue 3172](https://github.com/shakacode/react_on_rails/issues/3172). [PR 3174](https://github.com/shakacode/react_on_rails/pull/3174) by [justin808](https://github.com/justin808).
- **Client startup now recovers if initialization begins during `interactive` after `DOMContentLoaded` already fired**: React on Rails now still initializes the page when the client bundle starts in the browser timing window after `DOMContentLoaded` but before the document reaches `complete`. Fixes [Issue 3150](https://github.com/shakacode/react_on_rails/issues/3150). [PR 3151](https://github.com/shakacode/react_on_rails/pull/3151) by [ihabadham](https://github.com/ihabadham).
- **Doctor accepts TypeScript server bundle entrypoints**: `react_on_rails:doctor` now resolves common source entrypoint suffixes (`.js`, `.jsx`, `.ts`, `.tsx`, `.mjs`, `.cjs`) before warning that the server bundle is missing, preventing false positives when apps use `server-bundle.ts`. [PR 3111](https://github.com/shakacode/react_on_rails/pull/3111) by [justin808](https://github.com/justin808).
- **Doctor no longer fails custom projects for a missing generated `bin/dev`**: `react_on_rails:doctor` now downgrades a missing official React on Rails `bin/dev` launcher from an error to a warning and adds explicit guidance when a custom `./dev` script is detected, so custom projects can pass diagnostics when their development setup is intentional. Fixes [Issue 3103](https://github.com/shakacode/react_on_rails/issues/3103). [PR 3117](https://github.com/shakacode/react_on_rails/pull/3117) by [justin808](https://github.com/justin808).
- **[Pro]** **Reduced `react-on-rails-pro-node-renderer` published package size**: added a `files` whitelist to `package.json` so `pnpm pack` no longer includes `src/`, `tests/` fixtures, `*.map`, and `lib/tsconfig.tsbuildinfo` — matching the convention used by the sibling packages. Also marked `react_on_rails_pro/spec/dummy` as `private` so it can never be accidentally published. [PR 3304](https://github.com/shakacode/react_on_rails/pull/3304) by [alexeyr-ci2](https://github.com/alexeyr-ci2).
- **[Pro]** **HTTPX bidirectional streaming reliability**: Fixed streaming request timeouts when using HTTPX with both the `:stream` and `:stream_bidi` plugins. The request now uses the `build_request` pattern with an explicit `request.close` so the HTTP/2 `END_STREAM` flag is sent, and a temporary monkey-patch (`httpx_stream_bidi_patch.rb`) works around an upstream `:stream_bidi` retry bug that left stale body callbacks registered and crashed retried requests with `protocol_error`. The patch is scoped and will be removed once fixed upstream. [PR 2903](https://github.com/shakacode/react_on_rails/pull/2903) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Progressive RSC streaming flush granularity**: RSC streaming now flushes on React's per-render-cycle `flush()` signal instead of `setTimeout(flush, 0)`, so the shell and each resolved `<Suspense>` boundary stream as separate chunks rather than being merged into one large first message. This restores progressive streaming (and fixes worse-than-SSR First Contentful Paint) on pages with fast queries, and eliminates partial-HTML-tag chunks. Fixes [Issue 3194](https://github.com/shakacode/react_on_rails/issues/3194). [PR 2903](https://github.com/shakacode/react_on_rails/pull/2903) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Node renderer graceful shutdown after stream timeouts**: Fixed workers taking 30+ seconds to shut down after a `StreamChunkTimeoutError` during streaming. `handleGracefulShutdown` now also decrements the active-request count on `onRequestAbort`/`onTimeout`, the `PassThrough` wrapper is destroyed when the source render stream errors, and the HTTP response is closed on chunk timeout so connections to Rails no longer hang. Fixes [Issue 2270](https://github.com/shakacode/react_on_rails/issues/2270) and [Issue 2308](https://github.com/shakacode/react_on_rails/issues/2308). [PR 2903](https://github.com/shakacode/react_on_rails/pull/2903) by [AbanoubGhadban](https://github.com/AbanoubGhadban).

#### Deprecated

- **[Pro]** **`config.renderer_http_keep_alive_timeout` is deprecated**: The setting now has no effect because async-http manages renderer client lifecycle through scheduler-scoped clients when a `Fiber.scheduler` is already running and per-request clients otherwise. Explicitly setting it to a non-`nil` value emits a deprecation warning; leaving it unset or setting it to `nil` is accepted silently. Remove non-`nil` configuration during upgrade. See `docs/pro/updating.md` for the full upgrade guide. [PR 3320](https://github.com/shakacode/react_on_rails/pull/3320) by [AbanoubGhadban](https://github.com/AbanoubGhadban).

#### Removed

- **[Pro]** **Removed HTTPX transport gem dependencies from the Node Renderer**: React on Rails Pro no longer depends on `httpx`, `http-2`, or `connection_pool` after migrating to `async-http`. Applications that directly pin or require those gems for renderer integration should remove that coupling or add their own explicit dependency. [PR 3320](https://github.com/shakacode/react_on_rails/pull/3320) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Removed the `--rsc-pro` install generator flag**: `--rsc` already implies Pro, so the separate mode was unnecessary. Behaviors previously gated on `--rsc-pro` (Pro verification checklist, prerelease install note, exact Pro gem pin on prereleases) now fire on `--rsc` installs. See also [Issue 3104](https://github.com/shakacode/react_on_rails/issues/3104), which tracks unrelated silent-failure bugs in the Pro upgrade automation. [PR 3105](https://github.com/shakacode/react_on_rails/pull/3105) by [ihabadham](https://github.com/ihabadham).

#### Security

- **[Pro]** **Hardened Node Renderer password lifecycle**: The protocol-mismatch (412) response no longer echoes the request body verbatim — only non-sensitive field names are returned, so a mismatched `password` is never reflected back. The Pro install generator now provisions a random 64-hex-character renderer password instead of the publicly-known `devPassword` default, and production startup now logs a non-blocking warning for known-weak or short (< 16 character) renderer passwords. Fixes [Issue 3397](https://github.com/shakacode/react_on_rails/issues/3397). [PR 3399](https://github.com/shakacode/react_on_rails/pull/3399) by [AbanoubGhadban](https://github.com/AbanoubGhadban).

### [16.6.0] - 2026-04-09

#### Removed

- **Removed `immediate_hydration` configuration and parameter**: The `immediate_hydration` config option, helper parameter, `data-immediate-hydration` HTML attribute, and `redux_store` `immediate_hydration:` keyword argument have been completely removed. Immediate hydration is now always enabled for React on Rails Pro users and disabled for non-Pro users, with no per-component override. Remove any `immediate_hydration` references from your initializer and helper calls. Passing `immediate_hydration:` to `react_component` / `react_component_hash` is now ignored, and passing it to `stream_react_component` logs a warning. This change also fixes HTML attribute escaping for redux store names to prevent attribute injection from unsafe store keys. Closes [Issue 2142](https://github.com/shakacode/react_on_rails/issues/2142).
  [PR 2834](https://github.com/shakacode/react_on_rails/pull/2834) by
  [justin808](https://github.com/justin808).

#### Added

- **[Pro]** **Auto-resolve renderer password from ENV**: `setup_renderer_password` now falls back to `ENV["RENDERER_PASSWORD"]` when neither `config.renderer_password` nor a URL-embedded password is set, aligning Rails-side behavior with the Node Renderer defaults. Blank values (`nil` or `""`) are treated identically and fall through the full resolution chain: config → URL → ENV. [PR 2921](https://github.com/shakacode/react_on_rails/pull/2921) by [justin808](https://github.com/justin808).
- **Interactive mode prompt for `create-react-on-rails-app`**: Running `npx create-react-on-rails-app` without `--pro` or `--rsc` now shows an interactive prompt to choose between Standard, Pro, and RSC modes (default: RSC recommended). Explicit flags skip the prompt, and non-interactive environments fall back to standard mode automatically. [PR 3063](https://github.com/shakacode/react_on_rails/pull/3063) by [justin808](https://github.com/justin808).
- **[Pro] Configurable HTTP keep-alive timeout for node renderer connections**: Added `renderer_http_keep_alive_timeout` configuration option (default: 30s) to control how long idle persistent HTTP/2 connections to the node renderer are kept alive, preventing SSR failures from stale connections. [PR 3069](https://github.com/shakacode/react_on_rails/pull/3069) by [justin808](https://github.com/justin808).
- **[Pro]** **`react_on_rails:pro` now automates Pro and RSC Pro upgrades**: Added first-class `--rsc-pro` install mode, automatic `react_on_rails` -> `react_on_rails_pro` Gemfile and package swaps, and frontend import rewrites to streamline existing app upgrades. [PR 2822](https://github.com/shakacode/react_on_rails/pull/2822) by [justin808](https://github.com/justin808).

#### Improved

- **[Pro]** **Clearer node renderer request context in exception messages**: Exception formatting now uses a generic `Request:` label instead of render-specific wording, so `/upload-assets` failures and other non-render paths report the actual request context more clearly. [PR 2877](https://github.com/shakacode/react_on_rails/pull/2877) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Cleaner node renderer diagnostic output**: Invalid render-request diagnostics no longer redundantly list `renderingRequest` in the `bodyKeys` output since it is already reported via the `Received type:` line, and `renderer_http_keep_alive_timeout` documentation now recommends setting it shorter than the node renderer's server-side idle timeout. [PR 3086](https://github.com/shakacode/react_on_rails/pull/3086) by [justin808](https://github.com/justin808).
- **Doctor enforces strict version constraints**: `react_on_rails:doctor` now escalates non-exact gem and npm version specs (`^`, `~`, `>=`) from warnings to errors, matching the runtime VersionChecker behavior. Wildcard checks now also cover Pro packages (`react-on-rails-pro`, `react_on_rails_pro`). [PR 3070](https://github.com/shakacode/react_on_rails/pull/3070) by [justin808](https://github.com/justin808).
- **Error messages recommend doctor**: Runtime version-check crashes, configuration validation errors, and autobundling errors now suggest running `bundle exec rake react_on_rails:doctor` for diagnostics and `bundle exec rake react_on_rails:sync_versions WRITE=true` to fix version mismatches. [PR 3070](https://github.com/shakacode/react_on_rails/pull/3070) by [justin808](https://github.com/justin808).
- **`sync_versions` handles range specs**: Version ranges like `^16.5.0`, `~16.5.0`, and `>=16.5.0` are now parsed and rewritten to the exact expected version instead of being skipped as unsupported. When `FIX=true` is set, doctor auto-runs `sync_versions` to fix detected mismatches. [PR 3070](https://github.com/shakacode/react_on_rails/pull/3070) by [justin808](https://github.com/justin808).
- **[Pro] Improved node renderer error messages for malformed render requests**: Added early validation for missing or invalid `renderingRequest` payloads on the render endpoint, returning actionable 400 messages that include received type, body keys, and likely causes (truncation, malformed multipart, content-length mismatch). [PR 3068](https://github.com/shakacode/react_on_rails/pull/3068) by [justin808](https://github.com/justin808).
- **`react_on_rails:doctor` now prefers runtime configuration**: Doctor now reads loaded `ReactOnRails.configuration` values before falling back to initializer parsing, improving diagnostics for customized SSR and NodeRenderer setups. [PR 2823](https://github.com/shakacode/react_on_rails/pull/2823) by [justin808](https://github.com/justin808).
- **Fresh app onboarding for `create-react-on-rails-app`**: New apps now land on a generated root page with links to the local demos, docs, OSS vs Pro guidance, the Pro quick start, and the marketplace RSC demo. `bin/dev` opens that page on first boot, `--rsc` scaffolds the same fresh-app experience, and the generated app records step-by-step educational git commits for each scaffold phase. [PR 2849](https://github.com/shakacode/react_on_rails/pull/2849) by [justin808](https://github.com/justin808).

#### Fixed

- **Pin third-party npm dependency versions in generator**: All third-party npm dependencies installed by the `react_on_rails:install` generator and `bin/switch-bundler` are now pinned to `^major.0.0` version ranges, preventing peer dependency conflicts from uncontrolled major version bumps. Fixes CI breakage caused by `@rspack/plugin-react-refresh@2.0.0` requiring `@rspack/core@^2.0.0-0` while `@rspack/core` latest was still `1.7.11`. SWC dependency pins match Shakapacker's own version constraints. Closes [Issue 3082](https://github.com/shakacode/react_on_rails/issues/3082). [PR 3083](https://github.com/shakacode/react_on_rails/pull/3083) by [ihabadham](https://github.com/ihabadham).
- **[Pro]** **Fixed TanStack Router SSR hydration mismatches in the async path**: Client hydration now restores server match data before first render, uses `RouterProvider` directly to match the server-rendered tree, and stops the post-hydration load when a custom `router.options.hydrate` callback fails instead of continuing with partially hydrated client state. [PR 2932](https://github.com/shakacode/react_on_rails/pull/2932) by [justin808](https://github.com/justin808).
- **[Pro] Fixed infinite fork loop when node renderer worker fails to bind port**: When a worker failed during `app.listen()` (e.g., `EADDRINUSE`), the master previously reforked unconditionally, causing an infinite fork/crash loop that consumed CPU and filled logs. Workers now send a `WORKER_STARTUP_FAILURE` IPC message to the master before exiting; the master sets an abort flag and exits with a clear error message instead of reforking. Scheduled restarts and runtime crashes continue to refork as before. [PR 2881](https://github.com/shakacode/react_on_rails/pull/2881) by [justin808](https://github.com/justin808).
- **[Pro] Fixed Pro generator multiline and template-literal rewrites**: The Pro install generator now correctly handles multiline non-parenthesized `gem "react_on_rails"` declarations while preserving trailing options, and correctly rewrites module specifiers around template literals by preserving escaped sequences and detecting multiline template-literal starts after a closed inline template. [PR 2918](https://github.com/shakacode/react_on_rails/pull/2918) by [justin808](https://github.com/justin808).
- **[Pro] Fixed SSR failures from stale persistent HTTP/2 connections to the node renderer**: When idle connections became stale (closed by the node renderer but still considered active by the Ruby side), render requests could be truncated mid-flight, producing confusing `FST_ERR_CTP_INVALID_CONTENT_LENGTH` and "INVALID NIL or NULL result for rendering" errors. The new `renderer_http_keep_alive_timeout` config (default: 30s) prevents this by closing idle connections before they go stale. Content-Length mismatches now produce specific diagnostic messages instead of generic errors, and sensitive field names are filtered from diagnostic output. Fixes [Issue 3071](https://github.com/shakacode/react_on_rails/issues/3071). [PR 3069](https://github.com/shakacode/react_on_rails/pull/3069) by [justin808](https://github.com/justin808).
- **Legacy Shakapacker migrations are more resilient**: `react_on_rails:install` now falls back cleanly when the `package_json` gem is unavailable, installs only missing JS packages through the detected package manager, and auto-switches legacy JSX-in-`.js` apps to Babel when needed. [PR 2901](https://github.com/shakacode/react_on_rails/pull/2901) by [justin808](https://github.com/justin808).
- **New-app root-route generation is more robust**: Generator root-route detection is now centralized, duplicate route insertion is avoided, and home-page generation warns instead of failing when `config/routes.rb` is missing or unexpected. [PR 2891](https://github.com/shakacode/react_on_rails/pull/2891) by [justin808](https://github.com/justin808).
- **`bin/dev` now exits quietly on Ctrl-C**: The process manager and generated Shakapacker watcher wrapper now treat interrupt-driven shutdown as a clean exit, avoiding Ruby backtraces during local development. [PR 2652](https://github.com/shakacode/react_on_rails/pull/2652) by [justin808](https://github.com/justin808).
- **`bin/dev` browser auto-open now waits for route readiness**: `--open-browser` and `--open-browser-once` now poll the target app route and open the browser only after receiving a success or redirect response, reducing premature opens during boot. [PR 2885](https://github.com/shakacode/react_on_rails/pull/2885) by [justin808](https://github.com/justin808).

### [16.5.1] - 2026-03-27

#### Fixed

- **[Pro]** **TanStack Router: removed dependency on internal `router.ssr` flag**: Server-side rendering no longer
  sets the internal `router.ssr` property (unnecessary since React effects don't run during `renderToString`).
  Client-side legacy hydration path now uses the correct `{ manifest: undefined }` shape matching TanStack Router's
  internal `$_TSR` contract instead of a bare `true` boolean, improving forward compatibility. The recommended
  `RouterClient`/`ssrRouter` hydration path was already free of this dependency.
  Fixes [Issue 2647](https://github.com/shakacode/react_on_rails/issues/2647). [PR 2833](https://github.com/shakacode/react_on_rails/pull/2833) by [justin808](https://github.com/justin808).
- **[Pro] Fixed missing rake tasks in published gem**: The Pro gemspec excluded `lib/tasks/` from packaged files, so all `react_on_rails_pro:*` rake tasks (`verify_license`, `pre_stage_bundle_for_node_renderer`, `copy_assets_to_remote_vm_renderer`, `process_v8_logs`) were unavailable after gem install. [PR 2872](https://github.com/shakacode/react_on_rails/pull/2872) by [justin808](https://github.com/justin808).
- **[Pro] Fixed bundle duplication in remote node renderer asset uploads**: When RSC support is enabled, running `rake react_on_rails_pro:copy_assets_to_remote_vm_renderer` no longer duplicates bundle JS files across bundle directories. Previously, both the server bundle and RSC bundle were copied into every target directory; now each bundle is placed only in its own directory while shared assets (manifests, stats) are correctly distributed to all. [PR 2768](https://github.com/shakacode/react_on_rails/pull/2768) by [AbanoubGhadban](https://github.com/AbanoubGhadban). Fixes [Issue 2766](https://github.com/shakacode/react_on_rails/issues/2766).

### [16.5.0] - 2026-03-25

#### Added

- **`create-react-on-rails-app --pro` support**: Added explicit `--pro` mode to the CLI, including `react_on_rails_pro` gem installation and generator wiring for Pro-only setup (without requiring `--rsc`). [PR 2818](https://github.com/shakacode/react_on_rails/pull/2818) by [justin808](https://github.com/justin808).
- **Global prerender env override**: Added `REACT_ON_RAILS_PRERENDER_OVERRIDE=true|false` to force prerender behavior globally (env > component option > initializer default), useful for CI/test environments without an SSR server. [PR 2816](https://github.com/shakacode/react_on_rails/pull/2816) by [justin808](https://github.com/justin808).
- **`react_on_rails:sync_versions` rake task**: Added a version synchronizer that aligns npm package versions (`react-on-rails`, `react-on-rails-pro`, `react-on-rails-pro-node-renderer`) with loaded gem versions. Runs in dry-run mode by default; use `WRITE=true` to apply changes. [PR 2797](https://github.com/shakacode/react_on_rails/pull/2797) by [justin808](https://github.com/justin808).
- **Pro/RSC setup checks in `react_on_rails:doctor`**: Extended doctor diagnostics with Pro Setup (initializer, renderer mode, base-package import scanning) and RSC checks (renderer mode, payload route, bundler config, React version, Procfile RSC watcher). Sections are skipped for OSS-only installs. [PR 2674](https://github.com/shakacode/react_on_rails/pull/2674) by [ihabadham](https://github.com/ihabadham).

#### Changed

- **[Pro]** **Canonical env var for worker count is now `RENDERER_WORKERS_COUNT`**. The previous `NODE_RENDERER_CONCURRENCY` is still supported as a fallback. Worker count validation now accepts explicit `0` for single-process mode and warns on invalid values. [PR 2611](https://github.com/shakacode/react_on_rails/pull/2611) by [justin808](https://github.com/justin808).
- **[Pro]** **Migrated from `Async::Variable` to `Async::Promise`**: The streaming helper internals now use `Async::Promise` for async v2.29+ compatibility while preserving pre-first-chunk error propagation behavior. [PR 2832](https://github.com/shakacode/react_on_rails/pull/2832) by [justin808](https://github.com/justin808). Fixes [Issue 2563](https://github.com/shakacode/react_on_rails/issues/2563).

#### Improved

- **Smoother `create-react-on-rails-app` and install generator flows**: Fresh app scaffolding now runs non-interactively with `--force`, preserves the selected package manager, normalizes pnpm projects, auto-replaces stock `bin/dev`, and warns (instead of failing) on dirty worktrees. Post-install output updated with `db:prepare` step and current docs URL. [PR 2650](https://github.com/shakacode/react_on_rails/pull/2650) by [justin808](https://github.com/justin808).
- **Pro upgrade hint after install**: Running `rails g react_on_rails:install` now prints a Pro upgrade hint with docs link. Suppressed when `--pro` or `--rsc` flags are used. [PR 2642](https://github.com/shakacode/react_on_rails/pull/2642) by [justin808](https://github.com/justin808).

#### Fixed

- **Preserve runtime env vars across `Bundler.with_unbundled_env`**: Fixed `PORT` and `SHAKAPACKER_DEV_SERVER_PORT` being lost when `ProcessManager` runs foreman/overmind inside `Bundler.with_unbundled_env`, breaking auto-detected ports from `PortSelector`. Env vars are now captured before the unbundled block and passed explicitly to `system()`. [PR 2836](https://github.com/shakacode/react_on_rails/pull/2836) by [ihabadham](https://github.com/ihabadham).
- **Fix doctor prerender check and ExecJS display for Pro/RSC apps**: `uses_prerender_in_views?` now detects Pro streaming helpers (`stream_react_component`, `cached_stream_react_component`, `rsc_payload_react_component`) that implicitly enable prerender. Server rendering engine display now correctly detects NodeRenderer configuration from the Pro initializer. [PR 2773](https://github.com/shakacode/react_on_rails/pull/2773) by [ihabadham](https://github.com/ihabadham).
- **Fix doctor false positives for custom layouts**: `react_on_rails:doctor` now resolves `package.json` from `node_modules_location` config (instead of assuming repo root) and discovers webpack/rspack configs across common custom locations. Missing bundler config downgraded from error to contextual warning. [PR 2612](https://github.com/shakacode/react_on_rails/pull/2612) by [justin808](https://github.com/justin808).
- **[Pro]** **Require `RENDERER_PASSWORD` in production-like Node Renderer environments**: The Pro Node Renderer now fails fast when started without a truthy `RENDERER_PASSWORD` outside development/test, masks module-load password defaults in diagnostic logs, warns when `buildConfig({ password: undefined })` preserves the env/default password, and clarifies the Ruby-side initializer requirement. [PR 2829](https://github.com/shakacode/react_on_rails/pull/2829) by [justin808](https://github.com/justin808).

#### Breaking Changes

- **[Pro]** **`RENDERER_PASSWORD` now required in production-like environments**: Existing staging/production deployments using NodeRenderer without a password will fail to start after upgrading. Set `RENDERER_PASSWORD` in the environment and configure `config.renderer_password = ENV.fetch("RENDERER_PASSWORD")` in your Rails initializer before upgrading. [PR 2829](https://github.com/shakacode/react_on_rails/pull/2829) by [justin808](https://github.com/justin808).
- **[Pro]** **Minimum `async` gem version bumped to 2.29**: The streaming helper now requires `async >= 2.29` (previously `>= 2.6`) due to the migration from `Async::Variable` to `Async::Promise`. If your Gemfile pins the `async` gem below 2.29, you will need to update it before upgrading React on Rails Pro. Run `bundle update async` to pick up the new minimum.
  [PR 2832](https://github.com/shakacode/react_on_rails/pull/2832) by [justin808](https://github.com/justin808).

### [16.4.0] - 2026-03-16

#### Fixed

- **Install generator now handles TypeScript and rspack bundler configs correctly**: Projects using Shakapacker 9.4+ with TypeScript configs (`.ts`) were incorrectly prompted to confirm config replacement during `rails generate react_on_rails:install`, because the installer didn't recognize the ESM-style stock configs. The installer and `react_on_rails:doctor` now detect all config variants (webpack/rspack, JS/TS), use the correct replacement template for each, and show accurate bundler-specific diagnostic messages. [PR 2567](https://github.com/shakacode/react_on_rails/pull/2567) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **Show incomplete install message after Shakapacker failure**: The `react_on_rails:install` generator now tracks when automatic Shakapacker setup fails and emits an explicit "installation incomplete" warning with manual recovery steps, instead of the misleading "Successfully Installed" banner. [PR 2613](https://github.com/shakacode/react_on_rails/pull/2613) by [justin808](https://github.com/justin808). Fixes [Issue 2600](https://github.com/shakacode/react_on_rails/issues/2600).
- **Ruby 3.4 compatibility for heredocs**: Replaced legacy `strip_heredoc` usage with native squiggly heredocs (`<<~`) and removed redundant chaining where indentation is already normalized by Ruby. [PR 2599](https://github.com/shakacode/react_on_rails/pull/2599) by [justin808](https://github.com/justin808).
- **Fix install generator load path for `ReactOnRails::GitUtils`**: Added an explicit `require "react_on_rails/git_utils"` so generator execution does not rely on broader app boot side effects for this constant to be available. [PR 2599](https://github.com/shakacode/react_on_rails/pull/2599) by [justin808](https://github.com/justin808).
- **`server_render_js` now handles non-Error throws safely**: Defensive error serialization now supports thrown primitives and `null` values without raising secondary `TypeError` exceptions while building SSR error payloads. [PR 2599](https://github.com/shakacode/react_on_rails/pull/2599) by [justin808](https://github.com/justin808).
- **Clean stale webpack config on `--rspack` install**: Running `rails g react_on_rails:install --rspack` now removes leftover `config/webpack/` files when switching from webpack to rspack, preventing Shakapacker deprecation warnings. Only known stock/generated webpack configs are removed; custom files are preserved with a warning. [PR 2597](https://github.com/shakacode/react_on_rails/pull/2597) by [justin808](https://github.com/justin808). Fixes [Issue 2549](https://github.com/shakacode/react_on_rails/issues/2549).
- **Fixed `bin/setup` failing on pnpm workspace member directories**: `bin/setup` now checks for the presence of `pnpm-lock.yaml` before running `pnpm install --frozen-lockfile`, preventing failures in workspace member directories (e.g., `spec/dummy`) where dependencies are managed by the workspace root. [PR 2477](https://github.com/shakacode/react_on_rails/pull/2477) by [justin808](https://github.com/justin808).
- **CSS module SSR fixes for rspack**: Fixed CSS module class name divergence between client and server bundles when using rspack. Server webpack config now filters rspack's `cssExtractLoader` in addition to `mini-css-extract-plugin`, uses spread syntax to preserve existing CSS module options when setting `exportOnlyLocals: true`, and adds null guards against undefined entries in `rule.use` arrays. Note: `exportOnlyLocals: true` is no longer applied when `cssLoader.options.modules` is falsy (disabled), which is the correct behavior but a change from prior versions. [PR 2489](https://github.com/shakacode/react_on_rails/pull/2489) by [justin808](https://github.com/justin808).
- **Fixed `private_output_path` not configured on fresh Shakapacker installs**: When running `rails g react_on_rails:install` without pre-existing Shakapacker configuration, `private_output_path: ssr-generated` was left commented out in the generated `config/shakapacker.yml`. The generator now detects whether Shakapacker was just installed and passes a `shakapacker_just_installed` flag to `BaseGenerator`, which uses `force: true` when copying the config template to ensure the RoR version replaces Shakapacker's default. [PR 2411](https://github.com/shakacode/react_on_rails/pull/2411) by [ihabadham](https://github.com/ihabadham).
- **Install generator `--pretend` now behaves as a safe dry run**: `react_on_rails:install` previously executed real Shakapacker setup commands (`bundle add`, `bundle install`, and `rails shakapacker:install`) and could crash on `File.chmod` because Thor pretend mode does not create files. `--pretend` now skips automatic Shakapacker installation and raw chmod calls so dry-run previews complete without side effects. [PR 2536](https://github.com/shakacode/react_on_rails/pull/2536) by [justin808](https://github.com/justin808).
- **Generator test defaults now consistently use `build_test_command` + TestHelper, with Minitest support**: Fresh installs now enable `config.build_test_command` and wire React on Rails TestHelper for RSpec and Minitest, while generated `config/shakapacker.yml` sets test `compile: false` to avoid mixed compilation strategies by default. Doctor now validates helper wiring per framework (including mixed RSpec+Minitest apps), detects separate vs shared test/development output-path workflows, and supports `FIX=true` auto-fixes for the recommended setup path. Added `bin/dev test-watch` with `auto|full|client-only` modes so test watching is easier to run consistently. `bin/dev help` and testing docs now explicitly document both the recommended separate-output workflow and the advanced static-only shared-output workflow, including migration from manual watcher commands. [PR 2513](https://github.com/shakacode/react_on_rails/pull/2513) by [justin808](https://github.com/justin808).
- **`bin/dev` hook script path resolution without Rails.root**: Fixed `resolve_hook_script_path` failing in early startup (before Rails is initialized) by adding a `project_root` helper that resolves the project root via `BUNDLE_GEMFILE` dirname or `Dir.pwd` when `Rails.root` is unavailable. [PR 2568](https://github.com/shakacode/react_on_rails/pull/2568) by [ihabadham](https://github.com/ihabadham). Fixes [Issue 2438](https://github.com/shakacode/react_on_rails/issues/2438).
- **Rspack generator config path**: Fixed `--rspack` generator placing config files under `config/webpack/` instead of `config/rspack/`, causing Shakapacker deprecation warnings. All config file destinations are now dynamically remapped based on the active bundler, and `using_rspack?` auto-detects rspack projects for standalone generators (`react_on_rails:rsc`, `react_on_rails:pro`). [PR 2417](https://github.com/shakacode/react_on_rails/pull/2417) by [justin808](https://github.com/justin808).
- **Precompile hook load-based execution path**: Fixed the precompile hook not executing its tasks when invoked via `load` (as used by `bin/dev`) instead of direct script execution. Added a shared `run_precompile_tasks` entry point that works regardless of invocation method. [PR 2419](https://github.com/shakacode/react_on_rails/pull/2419) by [justin808](https://github.com/justin808). Fixes [Issue 2195](https://github.com/shakacode/react_on_rails/issues/2195).
- **`create-react-on-rails-app` validation improvements**: Tightened CLI validation to enforce Rails 7+ and app-name leading-letter requirements, with clearer error messages for invalid names containing hyphens or underscores. [PR 2577](https://github.com/shakacode/react_on_rails/pull/2577) by [justin808](https://github.com/justin808).
- **Install `@babel/preset-react` for non-SWC generator installs**: The generator now installs `@babel/preset-react` as a dev dependency when the project uses Babel (not SWC) as the transpiler, fixing JSX compilation errors on fresh installs with older Shakapacker defaults. [PR 2421](https://github.com/shakacode/react_on_rails/pull/2421) by [justin808](https://github.com/justin808).
- **Fix `react_on_rails:doctor` false positives for Pro/SWC setups**: Doctor now recognizes `react-on-rails-pro` npm package for presence and version sync checks, skips `@babel/preset-react` check when SWC is the transpiler, and fixes a nil-safety bug where missing `"dependencies"` in package.json silently dropped devDependencies from checks. [PR 2581](https://github.com/shakacode/react_on_rails/pull/2581) by [ihabadham](https://github.com/ihabadham).
- **Fixed ScoutApm instrumentation depending on Gemfile ordering**. ScoutApm instrumentation for `react_component`, `react_component_hash`, and `exec_server_render_js` was previously installed at gem load time using `defined?(ScoutApm)` guards, which meant it was silently skipped if `scout_apm` appeared after `react_on_rails` in the Gemfile, and produced noisy INFO log messages if it appeared before (since ScoutApm wasn't yet initialized). Moved instrumentation into an initializer that runs after `scout_apm.start`, ensuring it works regardless of gem ordering and only after ScoutApm is fully configured. [PR 2442](https://github.com/shakacode/react_on_rails/pull/2442) by [tonyta](https://github.com/tonyta).
- **RSC WebpackLoader with SWC transpiler**: Fixed RSC WebpackLoader never being injected when using SWC (Shakapacker's default transpiler). The RSC config only handled array-based `rule.use` (Babel) but SWC uses a function-based `rule.use`, so `'use client'` files passed through untransformed into the RSC bundle. Now handles both array and function loader declarations. [PR 2476](https://github.com/shakacode/react_on_rails/pull/2476) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **RSC Generator Layout Wiring**: Fixed `MissingEntryError` on fresh RSC installs where `HelloServerController` fell back to Rails' `application.html.erb` (which uses `javascript_pack_tag "application"` that is not created by the RSC flow). The generator now always copies `hello_world.html.erb`, `HelloServerController` explicitly uses `layout "hello_world"`, and post-install output now shows `stream_react_component` for RSC installs. [PR 2429](https://github.com/shakacode/react_on_rails/pull/2429) by [justin808](https://github.com/justin808).
- **Fixed string values interpolated into generated JS code without proper escaping**. All string values (component names, DOM IDs, Redux store names) embedded in server-rendering JavaScript now use `.to_json` instead of unescaped single-quoted interpolation, preventing potential JS breakage from special characters. [PR 2440](https://github.com/shakacode/react_on_rails/pull/2440) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **Precompile Hook Detection**: Fixed `shakapacker_precompile_hook_configured?` always returning `false` for apps created with the React on Rails generator. The detection logic only matched the rake task pattern (`react_on_rails:generate_packs`) but the generator template uses the Ruby method (`generate_packs_if_stale`). Now correctly detects both patterns, including resolving script file contents. [PR 2282](https://github.com/shakacode/react_on_rails/pull/2282) by [ihabadham](https://github.com/ihabadham).
- **Precompile Hook Self-Guard for HMR**: Added self-guard to the generator template's `bin/shakapacker-precompile-hook` to prevent duplicate execution in HMR mode where two webpack processes (client dev-server + server watcher) each trigger the hook. The script now exits early when `SHAKAPACKER_SKIP_PRECOMPILE_HOOK=true` is set by `bin/dev`, regardless of Shakapacker version. The version warning is now smarter: it only warns for hooks that lack the self-guard or use direct commands. **Existing users**: add `exit 0 if ENV["SHAKAPACKER_SKIP_PRECOMPILE_HOOK"] == "true"` near the top of your `bin/shakapacker-precompile-hook` script. [PR 2388](https://github.com/shakacode/react_on_rails/pull/2388) by [justin808](https://github.com/justin808).
- **Fix generator inheriting BUNDLE_GEMFILE from parent process**: The `react_on_rails:install` generator now wraps bundler commands with `Bundler.with_unbundled_env` to prevent inheriting `BUNDLE_GEMFILE` from the parent process, which caused "injected gems" conflicts when running generators inside a bundled context. [PR 2288](https://github.com/shakacode/react_on_rails/pull/2288) by [ihabadham](https://github.com/ihabadham).
- **[Pro]** **Fix streaming deadlock, exception masking, and cache poisoning on client disconnect**: Fixed async streaming bugs where client disconnect could cause deadlocks, mask producer exceptions, or cache partial results. [PR 2562](https://github.com/shakacode/react_on_rails/pull/2562) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Handle HTTPX error responses when fetching dev-server bundle/assets for upload**: During development startup races, `get_form_body_for_file` could receive `HTTPX::ErrorResponse` and still call `response.body`, causing an unexpected crash path. The request layer now raises `ReactOnRailsPro::Error` with HTTPX error details before body access and includes regression tests for local path, HTTP success, and HTTP error cases. [PR 2532](https://github.com/shakacode/react_on_rails/pull/2532) by [justin808](https://github.com/justin808).
- **[Pro]** **Fix streaming SSR hangs and silent error absorption in RSC payload injection**: Fixed two related issues: (1) streaming SSR renders hanging forever when errors occur because Node.js `stream.pipe()` doesn't propagate errors or closure from source to destination, and (2) errors in the RSC payload injection pipeline being silently absorbed, preventing them from reaching error reporters like Sentry. Introduced a shared `safePipe` utility and used `'close'` events as reliable termination signals across the streaming pipeline (Node renderer, RSC payload injection, transform streams, and Ruby async task). Also added a Ruby safety net to prevent Rails request hangs when async rendering tasks raise before the first chunk. [PR 2407](https://github.com/shakacode/react_on_rails/pull/2407) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Node renderer duplicate error reports for render failures**: Fixed duplicate `errorReporter.message` notifications when unexpected exceptions occurred in `handleRenderRequest`. The handler now returns an error `ResponseResult` instead of rethrowing, so the same failure is not reported again by `worker.ts` while still returning a 400 response. [PR 2531](https://github.com/shakacode/react_on_rails/pull/2531) by [justin808](https://github.com/justin808).
- **[Pro]** **Fix RSC payload JSON corruption from Rails view annotations in development**: RSC payload responses were rendered through an HTML template, so when `annotate_rendered_view_with_filenames` was enabled, Rails wrapped NDJSON chunks with HTML comments and broke client-side `JSON.parse`. The payload endpoint now renders the template in text format and serves `application/x-ndjson`, and a request spec covers the annotated-view scenario. If you override `custom_rsc_payload_template`, ensure it resolves to a text or format-neutral template (for example, `.text.erb`) rather than `.html.erb`. When RSC support is enabled, startup now also warns if `Rack::Deflater` is present, because response-transforming middleware can interfere with `ActionController::Live` NDJSON streaming. [PR 2535](https://github.com/shakacode/react_on_rails/pull/2535) by [justin808](https://github.com/justin808).
- **[Pro]** **Fix StreamResponse status fallback for non-streaming errors**: Fixed `StreamRequest#process_response_chunks` not detecting error responses when `status` delegation raises `NoMethodError`, which masked the original HTTPX error path. [PR 2416](https://github.com/shakacode/react_on_rails/pull/2416) by [justin808](https://github.com/justin808).
- **[Pro]** **Fix empty-string license plan mismatch between Ruby and Node**: Aligned Node `checkPlan` with Ruby `check_plan` so `plan: ""` is treated as invalid in both runtimes. Previously, an empty-string plan passed validation in Node but failed in Ruby. [PR 2566](https://github.com/shakacode/react_on_rails/pull/2566) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Fixed buildVM promise cleanup ordering in the node renderer**. `buildVM()` cleanup now runs via promise chaining after `vmCreationPromises.set()`, preventing failed synchronous VM builds from leaving stale rejected promises that block retries for the same bundle path. [PR 2484](https://github.com/shakacode/react_on_rails/pull/2484) by [justin808](https://github.com/justin808).
- **[Pro]** **Boot failure when only `react_on_rails_pro` is listed in the Gemfile.** `react_on_rails_pro.rb` never explicitly required `react_on_rails`, relying on `Bundler.require` to auto-load it via the user's Gemfile. When installation docs were updated to direct users to only add `react_on_rails_pro`, two errors surfaced on boot: `NoMethodError: undefined method 'strip_heredoc'` (from `license_public_key.rb`) and `NoMethodError: undefined method 'configure' for module ReactOnRails` (from `config/initializers/react_on_rails.rb`). Fixed by explicitly requiring `react_on_rails` in `react_on_rails_pro.rb`, completing the same design the JS package split already established for npm. [PR 2492](https://github.com/shakacode/react_on_rails/pull/2492) by [ihabadham](https://github.com/ihabadham).
- **[Pro]** **Sentry SDK v9/v10 compatibility**: The node renderer Sentry integration now supports `@sentry/node` v9 and v10. Replaced `@sentry/types` import (no longer a transitive dependency in v9+) and widened peer dependency range from `<9.0.0` to `<11.0.0`. [PR 2434](https://github.com/shakacode/react_on_rails/pull/2434) by [alexeyr-ci2](https://github.com/alexeyr-ci2).
- **[Pro]** **Fixed node renderer upload race condition causing ENOENT errors and asset corruption during concurrent requests**. Concurrent multipart uploads (e.g., during pod rollovers) all wrote to a single shared path (`uploads/<filename>`), causing file overwrites, `ENOENT` errors, and cross-contamination between requests. Each request now gets its own isolated upload directory (`uploads/<uuid>/`), eliminating all shared-path collisions. [PR 2456](https://github.com/shakacode/react_on_rails/pull/2456) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Fixed node renderer race condition between `/upload-assets` and render requests writing to the same bundle directory**. The `/upload-assets` endpoint used a global lock while render requests used per-bundle locks, so both could write to the same bundle directory concurrently, risking asset corruption. Now both endpoints share the same per-bundle lock key. Also switched parallel bundle processing from `Promise.all` to `Promise.allSettled` to prevent the `onResponse` cleanup hook from deleting uploaded files while in-flight copies are still reading from them. [PR 2464](https://github.com/shakacode/react_on_rails/pull/2464) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Fixed TS2769 build error in node renderer `onFile` callback**. Removed explicit `this: FastifyRequest` annotation that was incompatible with `@fastify/multipart` type definitions, fixing `pnpm build` and `pnpm install` failures on fresh runners. [PR 2469](https://github.com/shakacode/react_on_rails/pull/2469) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Fixed RSC rendering corruption when props contain `$`-patterns**. Props containing `` $` `` (dollar-backtick), `$'`, or `$&` — common in markdown with bash variables — caused `String.prototype.replace()` to interpret these as special replacement patterns, corrupting the generated JavaScript and hanging the RSC payload stream. Fixed by using a function replacement callback which disables all `$`-pattern interpretation. [PR 2440](https://github.com/shakacode/react_on_rails/pull/2440) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Fixed RSC stream tee backpressure deadlock for large payloads**. Replaced `pipe()`-based stream teeing with manual `on('data')` + `push()` forwarding to prevent deadlocks when RSC payloads exceed the 32KB default highWaterMark buffer, which caused the stream to hang indefinitely. [PR 2444](https://github.com/shakacode/react_on_rails/pull/2444) by [AbanoubGhadban](https://github.com/AbanoubGhadban).

#### Improved

- **Auto-install `react_on_rails_pro` gem for `--rsc`/`--pro` generator flags**: Running `rails g react_on_rails:install --rsc` or `--pro` now automatically installs the `react_on_rails_pro` gem via `bundle add` instead of only printing an error, matching how Shakapacker is handled in the same generator. [PR 2439](https://github.com/shakacode/react_on_rails/pull/2439) by [justin808](https://github.com/justin808).
- **create-react-on-rails-app validation and test coverage**: Tightened app name validation (must start with a letter), added Rails 7.0+ prerequisite validation, and expanded validator/setup test coverage (including `validateAll` success path). [PR 2571](https://github.com/shakacode/react_on_rails/pull/2571) by [justin808](https://github.com/justin808).
- **Smarter duplicate registration warnings**: Component and store registration now only warns when a _different_ component or store is registered under an already-used name. Re-registering the same component (common with HMR) is silently accepted. [PR 2354](https://github.com/shakacode/react_on_rails/pull/2354) by [justin808](https://github.com/justin808).
- **[Pro]** **Better error messages when component is missing `'use client'` with RSC**. When RSC support is enabled, components without `'use client'` silently crash at runtime with confusing errors. Improved error messages at multiple layers: runtime server and client bundles now include the component name and suggest adding `'use client'`, build-time heuristic scans for client-only patterns and emits warnings, and generated server component pack files explain the classification. [PR 2403](https://github.com/shakacode/react_on_rails/pull/2403) by [AbanoubGhadban](https://github.com/AbanoubGhadban).

#### Changed

- **Generator layout renamed**: Fresh installs now generate `react_on_rails_default.html.erb` instead of `hello_world.html.erb`, and generated controllers declare `layout "react_on_rails_default"`. The layout exists only to provide empty `javascript_pack_tag` and `stylesheet_pack_tag` calls for React on Rails auto-registration — it has no connection to the HelloWorld demo. Standalone `react_on_rails:rsc` upgrades now reuse an existing compatible layout when possible and otherwise create a compatible new layout without renaming user files. [PR 2482](https://github.com/shakacode/react_on_rails/pull/2482) by [ihabadham](https://github.com/ihabadham).
- **Clarified Pro-installation signaling for immediate hydration warnings**: Updated Ruby/TypeScript warning text and related docs to state that `railsContext.rorPro` indicates Pro gem installation (not license validity), and renamed `immediate_hydration_pro_license_warning` to `immediate_hydration_pro_install_warning` (no backward-compatible alias needed since the method had no external callers). [PR 2590](https://github.com/shakacode/react_on_rails/pull/2590) by [justin808](https://github.com/justin808).
- **[Pro]** **Breaking: removed legacy key-file license fallback**: `config/react_on_rails_pro_license.key` is no longer read. Move your token to the `REACT_ON_RAILS_PRO_LICENSE` environment variable. A migration warning is logged at startup when the legacy file is detected and the environment variable is missing. [PR 2454](https://github.com/shakacode/react_on_rails/pull/2454) by [ihabadham](https://github.com/ihabadham).

#### Added

- **Automatic dev asset reuse for tests**: When `bin/dev static` is running, `bundle exec rspec` (and Minitest) now automatically detects and reuses the fresh development assets instead of running a separate `build_test_command`. The TestHelper reads `config/shakapacker.yml`, verifies the dev manifest is static-mode (not HMR) and fresh, then temporarily overrides Shakapacker's test config to point at the dev output. No environment variables or extra commands needed — tests "just work" with `bin/dev static`. HMR mode (`bin/dev`) continues to require separate test compilation via `build_test_command` or `bin/dev test-watch`. [PR 2570](https://github.com/shakacode/react_on_rails/pull/2570) by [justin808](https://github.com/justin808).
- **[Pro]** **TanStack Router SSR integration**: Added `createTanStackRouterRenderFunction` and `serverRenderTanStackAppAsync` via `react-on-rails-pro/tanstack-router` for TanStack Router SSR with the Pro Node Renderer. Uses TanStack Router's public `router.load()` API for reliable async SSR. Requires `rendering_returns_promises = true` in Pro config. [PR 2516](https://github.com/shakacode/react_on_rails/pull/2516) by [justin808](https://github.com/justin808).
- **`create-react-on-rails-app --rsc` flow**: Added `--rsc` support to `npx create-react-on-rails-app` so a single command can scaffold an RSC-ready app. The CLI now installs `react_on_rails_pro`, passes `--rsc` to `react_on_rails:install`, and points users to `/hello_server` after setup. [PR 2430](https://github.com/shakacode/react_on_rails/pull/2430) by [justin808](https://github.com/justin808).
- **Environment-variable-driven ports in Procfile templates**: Procfile templates now use `${PORT:-3000}` and `${SHAKAPACKER_DEV_SERVER_PORT:-3035}` instead of hardcoded ports, enabling multiple worktrees to run `bin/dev` concurrently without port conflicts. Includes a `PortSelector` that auto-detects free ports when defaults are occupied, plus a generated `.env.example` documenting manual overrides. [PR 2539](https://github.com/shakacode/react_on_rails/pull/2539) by [ihabadham](https://github.com/ihabadham).
- **CSP nonce support for RSC streaming and console replay scripts**: Added `cspNonce` to `rails_context` and threaded nonce values through Pro RSC streaming paths (server-side HTML stream injection and client-side console replay script insertion), with nonce sanitization. [PR 2418](https://github.com/shakacode/react_on_rails/pull/2418) by [justin808](https://github.com/justin808).
- **Pro and RSC generator flags**: Added `--pro` and `--rsc` flags to `rails g react_on_rails:install`, plus standalone `react_on_rails:pro` and `react_on_rails:rsc` generators for upgrading existing apps to Pro and React Server Components. Includes idempotent setup modules, webpack config transforms, prerequisite validation, and example components. [PR 2284](https://github.com/shakacode/react_on_rails/pull/2284) by [ihabadham](https://github.com/ihabadham).
- **create-react-on-rails-app CLI tool**: New `npx create-react-on-rails-app` command for single-command project setup. Phase 1 supports JavaScript and TypeScript templates with npm/pnpm, orchestrating `rails new` + `bundle add react_on_rails` + `rails generate react_on_rails:install` with prerequisite validation and progress output. [PR 2375](https://github.com/shakacode/react_on_rails/pull/2375) by [justin808](https://github.com/justin808).
- **Extensible bin/dev precompile pattern**: New alternative approach for handling precompile tasks directly in `bin/dev`, providing better support for projects with custom build steps (ReScript, TypeScript), direct Ruby API access via `ReactOnRails::Locales.compile`, and improved version manager compatibility. [PR 2349](https://github.com/shakacode/react_on_rails/pull/2349) by [justin808](https://github.com/justin808).
- **Database setup check in bin/dev**: The `bin/dev` command now checks database connectivity before starting the development server. This provides clear error messages when the database is missing or unavailable, instead of buried errors in the logs. Note: This adds ~1-2 seconds to startup time as it spawns a Rails runner process.

  **Opt-out options** (for apps without databases or when faster startup is needed):
  - CLI flag: `bin/dev --skip-database-check`
  - Environment variable: `SKIP_DATABASE_CHECK=true bin/dev`
  - Configuration: `config.check_database_on_dev_start = false` in `config/initializers/react_on_rails.rb`

  [PR 2340](https://github.com/shakacode/react_on_rails/pull/2340) by [justin808](https://github.com/justin808).

- **[Pro]** **Startup warning for unsafe compression middleware callbacks**: Added a startup guard that detects `Rack::Deflater` or `Rack::Brotli` middleware with `:if` callbacks that iterate the response body via `body.each`, which can break streaming SSR/RSC and deadlock `ActionController::Live`. The warning includes the middleware source location and remediation guidance. [PR 2554](https://github.com/shakacode/react_on_rails/pull/2554) by [justin808](https://github.com/justin808).
- **[Pro]** **Configurable host binding for Node Renderer Fastify worker**: Added a `host` setting (default: `process.env.RENDERER_HOST || 'localhost'`) to control the bind address for the Pro Node Renderer. Set it to `0.0.0.0` in containerized environments where external health checks need to reach the renderer. [PR 2585](https://github.com/shakacode/react_on_rails/pull/2585) by [justin808](https://github.com/justin808).
- **[Pro]** **CSP nonce for immediate hydration scripts**: The immediate hydration inline `<script>` tags now include the CSP nonce attribute, fixing browsers blocking them when strict Content Security Policy is enabled. [PR 2398](https://github.com/shakacode/react_on_rails/pull/2398) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **License verification rake task**: New `react_on_rails_pro:verify_license` rake task for checking license status with human-readable text and JSON output (`FORMAT=json`) for CI/CD integration. Includes exit codes, automatic renewal warnings for licenses expiring within 30 days, and a GitHub Actions workflow example. [PR 2385](https://github.com/shakacode/react_on_rails/pull/2385) by [justin808](https://github.com/justin808).
- **[Pro]** **Auto-registration for Redux stores**: Added `stores_subdirectory` configuration option (e.g., `"ror_stores"`) for automatic Redux store registration, following the same pattern as component auto-registration via `ror_components`. Store files placed in `ror_stores/` directories are automatically discovered, and packs are generated that call `ReactOnRails.registerStore()`, eliminating manual registration boilerplate. Includes `auto_load_bundle` parameter for the `redux_store` helper. [PR 2346](https://github.com/shakacode/react_on_rails/pull/2346) by [justin808](https://github.com/justin808).

### [16.3.0] - 2026-02-05

#### Changed

- **Simplified Shakapacker version handling**: Removed obsolete minimum version checks (6.5.1) and example generation pinning (8.2.0). The gemspec dependency `shakapacker >= 6.0` is now the only minimum version requirement, with autobundling requiring >= 7.0.0. [PR 2247](https://github.com/shakacode/react_on_rails/pull/2247) by [justin808](https://github.com/justin808).
- **[Pro]** **License-Optional Attribution Model**: React on Rails Pro now works without a license for evaluation, development, testing, and CI/CD. A paid license is only required for production deployments. Added `plan` field validation to both Ruby and Node.js license validators — only `"paid"` plan (or no plan field for backwards compatibility) is accepted. Old free licenses are now treated as invalid. Documentation overhauled across README and LICENSE_SETUP guides; removed CI_SETUP.md (CI needs no license configuration). [PR 2324](https://github.com/shakacode/react_on_rails/pull/2324) by [AbanoubGhadban](https://github.com/AbanoubGhadban).

#### Fixed

- **Rspack configuration not applying to all environments**. Fixed `bin/switch-bundler` crashing with `Psych::AliasesNotEnabled` on YAML files with anchors/aliases, and fixed the `--rspack` generator flag only updating the `default` section while leaving environment sections with `webpack`. Now uses regex replacement to update `assets_bundler` in all sections while preserving YAML structure. [PR 2275](https://github.com/shakacode/react_on_rails/pull/2275) by [ihabadham](https://github.com/ihabadham).
- **Precompile hook not configured when Shakapacker is pre-installed**. Fixed the install generator not configuring the `precompile_hook` when Shakapacker was already installed before running `rails generate react_on_rails:install`. This caused missing component bundles during `assets:precompile` in production deployments. [PR 2280](https://github.com/shakacode/react_on_rails/pull/2280) by [ihabadham](https://github.com/ihabadham).
- **`bin/dev` failing with `--route` flag**. Fixed `bin/dev` command failing with "Unknown argument" when the generator was run with a `--route` option. The generated script now correctly handles route arguments. [PR 2273](https://github.com/shakacode/react_on_rails/pull/2273) by [ihabadham](https://github.com/ihabadham).

#### Added

- **[Pro]** **Multiple License Plan Types**: License validation now supports multiple plan types beyond "paid": `startup`, `nonprofit`, `education`, `oss`, and `partner`. Non-paid plan types are displayed in the license validation success message (e.g., "License validated successfully (startup license)."). Includes thread-safe caching for plan type retrieval via `LicenseValidator.license_plan`. [PR 2334](https://github.com/shakacode/react_on_rails/pull/2334) by [justin808](https://github.com/justin808).
- **[Pro]** **Node Renderer Master/Worker Exports**: Added public `master` and `worker` exports to `react-on-rails-pro-node-renderer` package, allowing users to import from `react-on-rails-pro-node-renderer/master` and `react-on-rails-pro-node-renderer/worker`. [PR 2326](https://github.com/shakacode/react_on_rails/pull/2326) by [justin808](https://github.com/justin808).

### [16.2.1] - 2026-01-18

#### Fixed

- **bin/dev Route Argument Parsing**: Fixed `bin/dev` command failing with "Unknown argument: hello_world" when run without arguments. The `--route` argument format was changed from two separate arguments to a single combined argument (`--route=value`). [PR 2309](https://github.com/shakacode/react_on_rails/pull/2309) by [K4sku](https://github.com/K4sku).

#### Developer (Contributors Only)

- **Benchmarking in CI**: A benchmark workflow will now run on all pushes to master, as well as PRs with `benchmark` or `full-ci` labels. [PR 1868](https://github.com/shakacode/react_on_rails/pull/1868) by [alexeyr-ci2](https://github.com/alexeyr-ci2).

### [16.2.0] - 2026-01-14

_This release includes all features from the React on Rails Pro 4.0.0 release series (previously released as 4.0.0-rc.6 through 4.0.0-rc.15). Pro-specific entries are tagged with **[Pro]**. For pre-monorepo Pro history, see the [archived Pro CHANGELOG](https://github.com/shakacode/react_on_rails_pro/blob/4.0.0/CHANGELOG.md)._

#### Breaking Changes

- **`config.immediate_hydration` configuration removed**: The `config.immediate_hydration` setting in `config/initializers/react_on_rails.rb` has been removed. Immediate hydration is now automatically enabled for React on Rails Pro users and automatically disabled for non-Pro users.

  **Migration steps:**
  - Remove any `config.immediate_hydration = true` or `config.immediate_hydration = false` lines from your `config/initializers/react_on_rails.rb` file
  - Pro users: No action needed - immediate hydration is now enabled automatically for optimal performance
  - Non-Pro users: No action needed - standard hydration behavior continues to work as before
  - Component-level overrides: You can still override behavior per-component using `react_component("MyComponent", immediate_hydration: false)` or `redux_store("MyStore", immediate_hydration: true)`
  - If a non-Pro user explicitly sets `immediate_hydration: true` on a component or store, a warning will be logged and it will be enforced to fall back to standard hydration (the value will be overridden to `false`)

  [PR 1997](https://github.com/shakacode/react_on_rails/pull/1997) by [AbanoubGhadban](https://github.com/AbanoubGhadban).

- **React on Rails Core Package**: Several Pro-only methods have been removed from the core package and are now exclusively available in the `react-on-rails-pro` package. If you're using any of the following methods, you'll need to migrate to React on Rails Pro:
  - `getOrWaitForComponent()`
  - `getOrWaitForStore()`
  - `getOrWaitForStoreGenerator()`
  - `reactOnRailsStoreLoaded()`
  - `streamServerRenderedReactComponent()`
  - `serverRenderRSCReactComponent()`

**Migration Guide:**

To migrate to React on Rails Pro:

1. Install the Pro package:

   ```bash
   yarn add react-on-rails-pro
   # or
   npm install react-on-rails-pro
   ```

2. Update your imports from `react-on-rails` to `react-on-rails-pro`:

   ```javascript
   // Before
   import ReactOnRails from 'react-on-rails';

   // After
   import ReactOnRails from 'react-on-rails-pro';
   ```

3. For server-side rendering, update your import paths:

   ```javascript
   // Before
   import ReactOnRails from 'react-on-rails';

   // After
   import ReactOnRails from 'react-on-rails-pro';
   ```

4. Free or low-cost Pro licenses are available for startups, small companies, and qualifying organizations. Visit [React on Rails Pro](https://pro.reactonrails.com) to get started, or contact [justin@shakacode.com](mailto:justin@shakacode.com) for any questions.

**Note:** If you're not using any of the Pro-only methods listed above, no changes are required.

- **Pro-Specific Configurations Moved to Pro Gem**: The following React Server Components (RSC) configurations have been moved from `ReactOnRails.configure` to `ReactOnRailsPro.configure`:
  - `rsc_bundle_js_file` - Path to the RSC bundle file
  - `react_server_client_manifest_file` - Path to the React server client manifest
  - `react_client_manifest_file` - Path to the React client manifest

  **Migration:** If you're using RSC features, move these configurations from your `ReactOnRails.configure` block to `ReactOnRailsPro.configure`:

  ```ruby
  # Before
  ReactOnRails.configure do |config|
    config.rsc_bundle_js_file = "rsc-bundle.js"
    config.react_server_client_manifest_file = "react-server-client-manifest.json"
    config.react_client_manifest_file = "react-client-manifest.json"
  end

  # After
  ReactOnRailsPro.configure do |config|
    config.rsc_bundle_js_file = "rsc-bundle.js"
    config.react_server_client_manifest_file = "react-server-client-manifest.json"
    config.react_client_manifest_file = "react-client-manifest.json"
  end
  ```

  See the [React on Rails Pro Configuration docs](docs/oss/configuration/configuration-pro.md) for more details.

- **Streaming View Helpers Moved to Pro Gem**: The following view helpers have been removed from the open-source gem and are now only available in React on Rails Pro:
  - `stream_react_component` - Progressive SSR using React 18+ streaming
  - `rsc_payload_react_component` - RSC payload rendering

  These helpers are now defined exclusively in the `react-on-rails-pro` gem.

- **Strict Version Validation at Boot Time**: Applications now fail to boot (instead of logging warnings) when package.json is misconfigured with wrong versions, missing packages, or semver wildcards. Users must use exact versions in package.json (no ^, ~, >, <, \* operators). **Migration**: Update package.json to use exact versions matching installed gem (e.g., `"16.1.1"` not `"^16.1.1"`). [PR #1881](https://github.com/shakacode/react_on_rails/pull/1881) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Node Renderer Version Validation**: Remote node renderer now validates gem version at request time. Version mismatches in development return 412 Precondition Failed (production allows with warning). Ensure `react_on_rails_pro` gem and `@shakacode-tools/react-on-rails-pro-node-renderer` package versions match. [PR #1881](https://github.com/shakacode/react_on_rails/pull/1881) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Prerender caching for streaming**: `config.prerender_caching` now controls caching for both streamed and non-streamed components. To disable for individual renders, pass `internal_option(:skip_prerender_cache)`.
- **[Pro]** **`ReactOnRailsPro::Utils#copy_assets` return value**: Now returns `nil` instead of `Response` object, throwing an error on failure instead. [PR 422](https://github.com/shakacode/react_on_rails_pro/pull/422) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** Added `async` gem dependency (>= 2.6) for concurrent streaming.
- **[Pro]** Dropped support for EOL'd Ruby 2.7. [PR 365](https://github.com/shakacode/react_on_rails_pro/pull/365) by [ahangarha](https://github.com/ahangarha).
- **[Pro]** Dropped support for React on Rails below 14.0.4. [PR 415](https://github.com/shakacode/react_on_rails_pro/pull/415) by [rameziophobia](https://github.com/rameziophobia).

#### Added

- **Shakapacker 9.0+ Private Output Path Integration**: Added automatic detection and integration of Shakapacker 9.0+ `private_output_path` configuration. React on Rails now automatically reads `private_output_path` from `shakapacker.yml` and sets server bundle paths, eliminating manual configuration synchronization. Includes version-aware generator templates, enhanced doctor command diagnostics for configuration validation and upgrade recommendations, and improved security with `enforce_private_server_bundles` option. [PR 2028](https://github.com/shakacode/react_on_rails/pull/2028) by [justin808](https://github.com/justin808).

- **Rspack Support**: Added `--rspack` flag to `react_on_rails:install` generator for significantly faster builds (~20x improvement with SWC). Includes unified webpack/rspack configuration templates and `bin/switch-bundler` utility to switch between bundlers post-installation. [PR #1852](https://github.com/shakacode/react_on_rails/pull/1852) by [justin808](https://github.com/justin808).

- **Service Dependency Checking for bin/dev**: Added optional `.dev-services.yml` configuration to validate required external services (Redis, PostgreSQL, Elasticsearch, etc.) are running before `bin/dev` starts the development server. Provides clear error messages with start commands and install hints when services are missing. Zero impact if not configured - backwards compatible with all existing installations. [PR 2098](https://github.com/shakacode/react_on_rails/pull/2098) by [justin808](https://github.com/justin808).

- **CSP Nonce Support for Console Replay**: Added Content Security Policy (CSP) nonce support for the `consoleReplay` script generated during server-side rendering. When Rails CSP is configured, the console replay script will automatically include the nonce attribute, allowing it to execute under restrictive CSP policies like `script-src: 'self'`. The implementation includes cross-version Rails compatibility (5.2-7.x) and defense-in-depth nonce sanitization to prevent attribute injection attacks. [PR 2059](https://github.com/shakacode/react_on_rails/pull/2059) by [justin808](https://github.com/justin808).

- **Attribution Comment**: Added HTML comment attribution to Rails views containing React on Rails functionality. The comment automatically displays which version is in use (open source React on Rails or React on Rails Pro) and, for Pro users, shows the license status. This helps identify React on Rails usage across your application. [PR #1857](https://github.com/shakacode/react_on_rails/pull/1857) by [AbanoubGhadban](https://github.com/AbanoubGhadban).

- **Smart Error Messages with Actionable Solutions**: Added intelligent Ruby-side error handling with context-aware, actionable solutions for common issues. Features include fuzzy matching for component name typos, environment-specific debugging suggestions, color-coded error formatting, and detailed troubleshooting guides for component registration, auto-bundling, hydration mismatches, server rendering errors, and Redux store issues. [PR 1934](https://github.com/shakacode/react_on_rails/pull/1934) by [justin808](https://github.com/justin808).

- **Doctor Checks for :async Loading Strategy**: Added proactive diagnostic checks to the React on Rails doctor tool to detect usage of the `:async` loading strategy in projects without React on Rails Pro. The feature scans view files and initializer configuration, providing clear guidance to either upgrade to Pro or use alternative loading strategies like `:defer` or `:sync` to avoid component registration race conditions. [PR 2010](https://github.com/shakacode/react_on_rails/pull/2010) by [justin808](https://github.com/justin808).
- **[Pro]** **React Server Components Support**: Full RSC integration for Rails apps — reduce client bundle sizes and enable powerful data fetching patterns. [See the tutorial](https://reactonrails.com/docs/pro/react-server-components/tutorial). [PR 422](https://github.com/shakacode/react_on_rails_pro/pull/422) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Streaming Server Rendering**: `stream_view_containing_react_components` and `stream_react_component` helpers for progressive page loading. Includes console log replay, error handling during streaming (initial render and suspense boundaries), and `raise_non_shell_server_rendering_errors` configuration. [PR 407](https://github.com/shakacode/react_on_rails_pro/pull/407), [PR #429](https://github.com/shakacode/react_on_rails_pro/pull/429), [PR #432](https://github.com/shakacode/react_on_rails_pro/pull/432) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Async React Component Rendering**: `async_react_component` and `cached_async_react_component` helpers for concurrent component rendering. Multiple components execute HTTP requests to the Node renderer in parallel. Requires `ReactOnRailsPro::AsyncRendering` concern in controller. [PR 2139](https://github.com/shakacode/react_on_rails/pull/2139) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Concurrent Streaming Performance**: Concurrent draining of streamed React components using the async gem with producer-consumer pattern and bounded buffering. [PR 2015](https://github.com/shakacode/react_on_rails/pull/2015) by [ihabadham](https://github.com/ihabadham).
- **[Pro]** **License Validation System**: JWT-based license validation with offline verification using RSA-256 signatures. [PR #1857](https://github.com/shakacode/react_on_rails/pull/1857) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Improved RSC Payload Error Handling**: Errors during RSC payload generation are now transferred to Rails with error messages and stack traces. [PR #1888](https://github.com/shakacode/react_on_rails/pull/1888) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** `cached_stream_react_component` helper for cached streaming.
- **[Pro]** `config.concurrent_component_streaming_buffer_size` option (defaults to 64) for concurrent streaming memory buffer control.
- **[Pro]** `replayServerAsyncOperationLogs` configuration for capturing async operation console output during SSR. [PR 440](https://github.com/shakacode/react_on_rails_pro/pull/440) by [AbanoubGhadban](https://github.com/AbanoubGhadban).

#### Changed

- **Shakapacker 9.0.0 Upgrade**: Upgraded Shakapacker from 8.2.0 to 9.0.0 with Babel transpiler configuration for compatibility. Key changes include:
  - Configured `javascript_transpiler: babel` in shakapacker.yml (Shakapacker 9.0 defaults to SWC which has PropTypes handling issues)
  - Added precompile hook support via `bin/shakapacker-precompile-hook` for ReScript builds and pack generation
  - Configured CSS Modules to use default exports (`namedExport: false`) for backward compatibility with existing `import styles from` syntax
  - Fixed webpack configuration to process SCSS rules and CSS loaders in a single pass for better performance
    [PR 1904](https://github.com/shakacode/react_on_rails/pull/1904) by [justin808](https://github.com/justin808).

- **`generated_component_packs_loading_strategy` now defaults based on Pro license**: When using Shakapacker >= 8.2.0, the default loading strategy is now `:async` for Pro users and `:defer` for non-Pro users. This provides optimal performance for Pro users while maintaining compatibility for non-Pro users. You can still explicitly set the strategy in your configuration. [PR #1993](https://github.com/shakacode/react_on_rails/pull/1993) by [AbanoubGhadban](https://github.com/AbanoubGhadban).

- **Generator Configuration Modernization**: Updated the generator to enable recommended configurations by default for new applications. `config.build_test_command` is now uncommented and set to `"RAILS_ENV=test bin/shakapacker"` by default, enabling automatic asset building during tests for better integration test reliability. `config.auto_load_bundle = true` is now set by default, enabling automatic loading of component bundles. `config.components_subdirectory = "ror_components"` is now set by default, organizing React components in a dedicated subdirectory. **Note:** These changes only affect newly generated applications. Existing applications are unaffected and do not need to make any changes. If you want to adopt these settings in an existing app, you can manually add them to your `config/initializers/react_on_rails.rb` file. [PR 2039](https://github.com/shakacode/react_on_rails/pull/2039) by [justin808](https://github.com/justin808).

- **Removed Babel Dependency Installation**: The generator no longer installs `@babel/preset-react` or `@babel/preset-typescript` packages. Shakapacker handles JavaScript transpiler configuration (Babel, SWC, or esbuild) via the `javascript_transpiler` setting in `shakapacker.yml`. SWC is now the default transpiler and includes built-in support for React and TypeScript. Users who explicitly choose Babel will need to manually install and configure the required presets. This change reduces unnecessary dependencies and aligns with Shakapacker's modular transpiler approach. [PR 2051](https://github.com/shakacode/react_on_rails/pull/2051) by [justin808](https://github.com/justin808).
- **[Pro]** **`immediate_hydration` auto-enabled for Pro users**: The configuration option has been removed; immediate hydration is now automatically enabled for Pro users and disabled for non-Pro users. Component-level overrides still supported. [PR 1997](https://github.com/shakacode/react_on_rails/pull/1997) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **RSC rendering flow improvements**: Eliminated double rendering, reduced HTTP requests, added multi-bundle upload via communication protocol v2.0.0. [PR 515](https://github.com/shakacode/react_on_rails_pro/pull/515) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Node Renderer: Express to Fastify**: Converted worker from Express to Fastify. [PR 398](https://github.com/shakacode/react_on_rails_pro/pull/398) by [alexeyr-ci](https://github.com/alexeyr-ci).
- **[Pro]** **Fastify 5 upgrade**: Default with fallback to Fastify 4 on older Node versions. [PR 478](https://github.com/shakacode/react_on_rails_pro/pull/478) by [alexeyr-ci](https://github.com/alexeyr-ci).
- **[Pro]** **Pino logging**: Replaced Winston, aligning with Fastify. [PR 479](https://github.com/shakacode/react_on_rails_pro/pull/479) by [alexeyr-ci](https://github.com/alexeyr-ci).
- **[Pro]** **HTTP/2 Cleartext communication** with Node Renderer. [PR 392](https://github.com/shakacode/react_on_rails_pro/pull/392) by [alexeyr-ci](https://github.com/alexeyr-ci).
- **[Pro]** **HTTPX for Node renderer**: Converted from `Net::HTTP` to HTTPX. [PR 452](https://github.com/shakacode/react_on_rails_pro/pull/452) by [alexeyr-ci](https://github.com/alexeyr-ci). Upgraded to ~> 1.5. [PR 520](https://github.com/shakacode/react_on_rails_pro/pull/520) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Error reporting/tracing overhaul**: See [the docs](docs/oss/building-features/node-renderer/error-reporting-and-tracing.md). [PR 471](https://github.com/shakacode/react_on_rails_pro/pull/471) by [alexeyr-ci](https://github.com/alexeyr-ci).
- **[Pro]** Added `fastifyServerOptions` config and set `bodyLimit` to 100 MB by default. [PR 511](https://github.com/shakacode/react_on_rails_pro/pull/511) by [Romex91](https://github.com/Romex91).
- **[Pro]** Renamed `includeTimerPolyfills` to `stubTimers`. Fail immediately on obsolete config options. [PR 506](https://github.com/shakacode/react_on_rails_pro/pull/506) by [alexeyr-ci](https://github.com/alexeyr-ci).
- **[Pro]** Shakapacker 8.0.0 support (drops 6.x). [PR 415](https://github.com/shakacode/react_on_rails_pro/pull/415) by [rameziophobia](https://github.com/rameziophobia).

#### Improved

- **SWC Compiler Detection**: Added intelligent detection and automatic installation of SWC transpiler packages (`@swc/core` and `swc-loader`) when the generator detects SWC configuration. For Shakapacker 9.3.0+ (where SWC is the default transpiler), required packages are now installed automatically. Includes graceful error handling and YAML parsing security improvements. [PR 2135](https://github.com/shakacode/react_on_rails/pull/2135) by [justin808](https://github.com/justin808).

- **Enhanced bin/dev Error Messages**: Improved error messages when `bin/dev` fails by suggesting the `--verbose` flag for detailed debugging output. The verbose flag now properly cascades to child processes via the `REACT_ON_RAILS_VERBOSE` environment variable, making troubleshooting pack generation failures significantly easier. [PR 2083](https://github.com/shakacode/react_on_rails/pull/2083) by [justin808](https://github.com/justin808).

- **Automatic Precompile Hook Coordination in bin/dev**: The `bin/dev` command now automatically runs Shakapacker's `precompile_hook` once before starting development processes and sets `SHAKAPACKER_SKIP_PRECOMPILE_HOOK=true` to prevent duplicate execution in spawned webpack processes.
  - Eliminates the need for manual coordination, sleep hacks, and duplicate task calls in Procfile.dev
  - Users can configure expensive build tasks (like locale generation or ReScript compilation) once in `config/shakapacker.yml` and `bin/dev` handles coordination automatically
  - Includes warning for Shakapacker versions below 9.4.0 (the `SHAKAPACKER_SKIP_PRECOMPILE_HOOK` environment variable is only supported in 9.4.0+)
  - The `SHAKAPACKER_SKIP_PRECOMPILE_HOOK` environment variable is set for all spawned processes, making it available for custom scripts that need to detect when `bin/dev` is managing the precompile hook
  - Addresses [2091](https://github.com/shakacode/react_on_rails/issues/2091) by [justin808](https://github.com/justin808)

- **Idempotent Locale Generation**: The `react_on_rails:locale` rake task is now idempotent, automatically skipping generation when locale files are already up-to-date. This makes it safe to call multiple times (e.g., in Shakapacker's `precompile_hook`) without duplicate work. Added `force=true` option to override timestamp checking. [PR 2090](https://github.com/shakacode/react_on_rails/pull/2090) by [justin808](https://github.com/justin808).

- **Improved Error Messages**: Error messages for version mismatches and package configuration issues now include package-manager-specific installation commands (npm, yarn, pnpm, bun). [PR #1881](https://github.com/shakacode/react_on_rails/pull/1881) by [AbanoubGhadban](https://github.com/AbanoubGhadban).

#### Fixed

- **Component Registration**: Fixed "component not registered" error on core `react-on-rails` package that could occur when components were referenced before registration completed. [PR 2295](https://github.com/shakacode/react_on_rails/pull/2295) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **webpack-cli Compatibility**: Fixed compatibility issue with webpack-dev-server v5 by upgrading webpack-cli from v4 to v6.0.1 and removing the deprecated `@webpack-cli/serve` package. Also removed deprecated `https: false` configuration from shakapacker.yml. [PR 2291](https://github.com/shakacode/react_on_rails/pull/2291) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **Hydration Mismatch on Multiple `reactOnRailsPageLoaded()` Calls**: Fixed hydration errors that occurred when `reactOnRailsPageLoaded()` was invoked multiple times for asynchronously loaded content. The fix tracks rendered components and skips re-rendering already-tracked components, while intelligently handling DOM node replacements by detecting when a node with the same ID is swapped out. Addresses [issue 2210](https://github.com/shakacode/react_on_rails/issues/2210). [PR 2211](https://github.com/shakacode/react_on_rails/pull/2211) by [justin808](https://github.com/justin808).

- **TypeScript processPromise Return Type**: Fixed TypeScript compilation error in `serverRenderReactComponent.ts` where the type checker couldn't properly narrow the union type after the `isValidElement` check. Added explicit type assertion to `FinalHtmlResult` to resolve the issue. [PR 2204](https://github.com/shakacode/react_on_rails/pull/2204) by [justin808](https://github.com/justin808).

- **connection_pool 3.0+ Compatibility**: Fixed `ArgumentError: wrong number of arguments` when using `connection_pool` gem version 3.0 or later. The gem's API changed from accepting a positional hash to requiring keyword arguments. This fix ensures compatibility with both older and newer versions of `connection_pool`. Addresses [issue 2185](https://github.com/shakacode/react_on_rails/issues/2185). [PR 2125](https://github.com/shakacode/react_on_rails/pull/2125) by [justin808](https://github.com/justin808).

- **RSpec Helper Optimization with Private SSR Directories**: Fixed RSpec helper optimization bug that caused tests to run with stale server-side code when server bundles are stored in private `ssr-generated/` directories. The helper now automatically monitors server bundles and other critical files, ensuring proper rebuild detection even when assets are in separate directories from the manifest. [PR 1838](https://github.com/shakacode/react_on_rails/pull/1838) by [justin808](https://github.com/justin808).

- **Pack Generation in bin/dev from Bundler Context**: Fixed pack generation failing with "Could not find command 'react_on_rails:generate_packs'" when running `bin/dev` from within a Bundler context. The fix wraps the bundle exec call with `Bundler.with_unbundled_env` to prevent interception. [PR 2085](https://github.com/shakacode/react_on_rails/pull/2085) by [justin808](https://github.com/justin808).

- **bin/dev Process Manager Detection**: Fixed misleading "Process Manager Not Found" error when overmind is installed but exits with a non-zero code (e.g., when a Procfile process crashes). The error message now correctly distinguishes between a missing process manager and a process manager that ran but failed. [PR 2087](https://github.com/shakacode/react_on_rails/pull/2087) by [justin808](https://github.com/justin808).

- **Doctor Command Version Mismatch Detection**: Fixed false version mismatch warnings in `rake react_on_rails:doctor` when using beta/prerelease versions. The command now correctly recognizes that gem version `16.2.0.beta.10` matches npm version `16.2.0-beta.10` using proper semver conversion instead of string normalization that stripped prerelease identifiers. [PR 2064](https://github.com/shakacode/react_on_rails/pull/2064) by [ihabadham](https://github.com/ihabadham).

- **Rails 5.2-6.0 Compatibility**: Fixed compatibility with Rails 5.2-6.0 by adding polyfill for `compact_blank` method (introduced in Rails 6.1). Also refactored webpack asset handling to conditionally include React on Rails Pro files only when available, preventing NoMethodErrors in open-source installations. [PR 2058](https://github.com/shakacode/react_on_rails/pull/2058) by [justin808](https://github.com/justin808).

- **Duplicate Rake Task Execution**: Fixed rake tasks executing twice during asset precompilation and other rake operations. Rails Engine was loading task files twice: once via explicit `load` calls in the `rake_tasks` block (Railtie layer) and once via automatic file loading from `lib/tasks/` (Engine layer). This caused `react_on_rails:assets:webpack`, `react_on_rails:generate_packs`, and `react_on_rails:locale` tasks to run twice, significantly increasing build times. Removed explicit `load` calls and now rely on Rails Engine's standard auto-loading behavior. [PR 2052](https://github.com/shakacode/react_on_rails/pull/2052) by [justin808](https://github.com/justin808).
- **[Pro]** **Thread-Safe Connection Management**: Fixed race conditions in `ReactOnRailsPro::Request` using double-checked locking. [PR 2259](https://github.com/shakacode/react_on_rails/pull/2259) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **JSON Parse Race Condition in Immediate Hydration**: Fixed race condition where `immediate_hydration` could parse incomplete JSON during HTML streaming. Uses `nextSibling` check to verify props script completion. [PR 2290](https://github.com/shakacode/react_on_rails/pull/2290) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Legacy Module Resolver Compatibility**: Added `main` field to Pro package.json files for legacy module resolvers. [PR 2256](https://github.com/shakacode/react_on_rails/pull/2256) by [ihabadham](https://github.com/ihabadham).
- **[Pro]** **Client Disconnect Handling for Streaming**: Catches `IOError`/`Errno::EPIPE` on disconnect, stops barrier to cancel producer tasks. [PR 2137](https://github.com/shakacode/react_on_rails/pull/2137) by [justin808](https://github.com/justin808).
- **[Pro]** **Node Renderer Worker Restart**: Fixed "descriptor closed" error during restarts. Workers now perform graceful shutdowns with configurable `gracefulWorkerRestartTimeout`. [PR 1970](https://github.com/shakacode/react_on_rails/pull/1970) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **Body Duplication Bug On Streaming**: Fixed bug when node renderer connection closed after partial streaming. [PR 1995](https://github.com/shakacode/react_on_rails/pull/1995) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** Fixed compatibility with httpx 1.6.x by requiring http-2 >= 1.1.1. [PR 2141](https://github.com/shakacode/react_on_rails/pull/2141) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** Fixed unnecessary bundle requests when RSC is disabled. [PR 545](https://github.com/shakacode/react_on_rails_pro/pull/545) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** Made default bundle paths consistent between node-renderer and Rails. [PR 399](https://github.com/shakacode/react_on_rails_pro/pull/399) by [alexeyr-ci](https://github.com/alexeyr-ci).

#### Security

- **Development Dependencies Security**: Addressed 58 Dependabot vulnerabilities in dev/test dependencies including critical issues in webpack (DOM clobbering XSS), nokogiri (libxml2 CVEs), activestorage, rack (5 DoS vulnerabilities), and jws (HMAC signature bypass). These changes only affect development environments—production gem code is unchanged. [PR 2261](https://github.com/shakacode/react_on_rails/pull/2261) by [ihabadham](https://github.com/ihabadham).

- **Command Injection Protection**: Added security hardening to prevent potential command injection in package manager commands. [PR #1881](https://github.com/shakacode/react_on_rails/pull/1881) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **CVE-2025-55182 - React Server Components RCE**: Updated `react-on-rails-rsc` peer dependency to v19.0.3. [PR 2175](https://github.com/shakacode/react_on_rails/pull/2175) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
- **[Pro]** **CVE-2025-55183, CVE-2025-55184, CVE-2025-67779**: Upgraded React to v19.0.3 and react-on-rails-rsc to v19.0.4 fixing source code exposure and denial of service vulnerabilities. [PR 2233](https://github.com/shakacode/react_on_rails/pull/2233) by [AbanoubGhadban](https://github.com/AbanoubGhadban).

#### Deprecated

- **[Pro]** **Node Renderer `bundlePath`**: Renamed to `serverBundleCachePath`. Old option continues to work with deprecation warning. [PR 2008](https://github.com/shakacode/react_on_rails/pull/2008) by [justin808](https://github.com/justin808).

#### Documentation

- **Simplified Configuration Files**: Improved configuration documentation and generator template for better clarity and usability. Reduced generator template from 67 to 42 lines (37% reduction). Added comprehensive testing configuration guide. Reorganized configuration docs into Essential vs Advanced sections. Enhanced Doctor program with diagnostics for server rendering and test compilation consistency. [PR #2011](https://github.com/shakacode/react_on_rails/pull/2011) by [justin808](https://github.com/justin808).

#### Developer (Contributors Only)

- **Monorepo Structure Reorganization**: Restructured the monorepo to use two top-level product directories (`react_on_rails/` and `react_on_rails_pro/`) instead of mixing source files at the root level. This improves organization and clarity for contributors working on either the open-source or Pro versions. **Important for contributors**: If you have an existing clone of the repository, you may need to update your IDE exclusion patterns and paths. See the updated `CLAUDE.md` for current project structure. [PR 2114](https://github.com/shakacode/react_on_rails/pull/2114) by [justin808](https://github.com/justin808).

- **Package Manager Migration to pnpm**: Migrated the monorepo from Yarn Classic to pnpm for improved dependency management and faster installs. Contributors should reinstall dependencies with `pnpm install` after pulling this change. [PR 2121](https://github.com/shakacode/react_on_rails/pull/2121) by [justin808](https://github.com/justin808).

- **Bundle Size CI Monitoring**: Added automated bundle size tracking to CI using size-limit. Compares PR bundle sizes against the base branch and fails if any package increases by more than 0.5KB. Includes local comparison tool (`bin/compare-bundle-sizes`) and bypass mechanism (`bin/skip-bundle-size-check`) for intentional size increases. [PR 2149](https://github.com/shakacode/react_on_rails/pull/2149) by [AbanoubGhadban](https://github.com/AbanoubGhadban).

- **Download Time CI Monitoring**: Added automated download time tracking to CI using size-limit. Compares PR client import download times against the base branch and fails if any import increases by more than 10%. [PR 2160](https://github.com/shakacode/react_on_rails/pull/2160) by [AbanoubGhadban](https://github.com/AbanoubGhadban).

### [16.1.1] - 2025-09-24

#### Bug Fixes

- **React Server Components**: Fixed bug in resolving `react-server-client-manifest.json` file path. The manifest file path is now correctly resolved using `bundle_js_file_path` for improved configuration flexibility and consistency in bundle management. [PR 1818](https://github.com/shakacode/react_on_rails/pull/1818) by [AbanoubGhadban](https://github.com/AbanoubGhadban)

### [16.1.0] - 2025-09-23

#### New Features

- **Server Bundle Security**: Added new configuration options for enhanced server bundle security and organization:
  - `server_bundle_output_path`: Configurable directory (relative to the Rails root) for server bundle output (default: "ssr-generated"). If set to `nil`, the server bundle will be loaded from the same public directory as client bundles. [PR 1798](https://github.com/shakacode/react_on_rails/pull/1798) by [justin808](https://github.com/justin808)
  - `enforce_private_server_bundles`: When enabled, ensures server bundles are only loaded from private directories outside the public folder (default: false for backward compatibility) [PR 1798](https://github.com/shakacode/react_on_rails/pull/1798) by [justin808](https://github.com/justin808)

- **Improved Bundle Path Resolution**: Bundle path resolution for server bundles now works as follows:
  - If `server_bundle_output_path` is set, the server bundle is loaded from that directory.
  - If `server_bundle_output_path` is not set, the server bundle falls back to the client bundle directory (typically the public output path).
  - If `enforce_private_server_bundles` is enabled:
    - The server bundle will only be loaded from the private directory specified by `server_bundle_output_path`.
    - If the bundle is not found there, it will _not_ fall back to the public directory.
  - If `enforce_private_server_bundles` is not enabled and the bundle is not found in the private directory, it will fall back to the public directory.
  - This logic ensures that, when strict enforcement is enabled, server bundles are never loaded from public directories, improving security and clarity of bundle resolution. [PR 1798](https://github.com/shakacode/react_on_rails/pull/1798) by [justin808](https://github.com/justin808)

- **`react_on_rails:doctor` rake task**: New diagnostic command to validate React on Rails setup and identify configuration issues. Provides comprehensive checks for environment prerequisites, dependencies, Rails integration, and Webpack configuration. Use `rake react_on_rails:doctor` to diagnose your setup, with optional `VERBOSE=true` for detailed output. [PR 1791](https://github.com/shakacode/react_on_rails/pull/1791) by [AbanoubGhadban](https://github.com/AbanoubGhadban)

#### Deprecations

- **Deprecated `generated_assets_dirs` configuration**: The legacy `config.generated_assets_dirs` option is now deprecated and will show a deprecation warning if used. Since Shakapacker is now required, asset paths are automatically determined from `shakapacker.yml` configuration. Remove any `config.generated_assets_dirs` from your `config/initializers/react_on_rails.rb` file. Use `public_output_path` in `config/shakapacker.yml` to customize asset output location instead. [PR 1798](https://github.com/shakacode/react_on_rails/pull/1798) by [justin808](https://github.com/justin808)

#### API Improvements

- **Method Naming Clarification**: Added `public_bundles_full_path` method to clarify bundle path handling:
  - `public_bundles_full_path`: New method specifically for webpack bundles in public directories
  - `generated_assets_full_path`: Now deprecated (backwards-compatible alias)
  - This eliminates confusion between webpack bundles and general Rails public assets [PR 1798](https://github.com/shakacode/react_on_rails/pull/1798) by [justin808](https://github.com/justin808)

#### Security Enhancements

- **Private Server Bundle Enforcement**: When `enforce_private_server_bundles` is enabled, server bundles bypass public directory fallbacks and are only loaded from designated private locations [PR 1798](https://github.com/shakacode/react_on_rails/pull/1798) by [justin808](https://github.com/justin808)
- **Path Validation**: Added validation to ensure `server_bundle_output_path` points to private directories when enforcement is enabled [PR 1798](https://github.com/shakacode/react_on_rails/pull/1798) by [justin808](https://github.com/justin808)
- **Fixed command injection vulnerabilities**: Replaced unsafe string interpolation in generator package installation commands with secure array-based system calls [PR 1786](https://github.com/shakacode/react_on_rails/pull/1786) by [justin808](https://github.com/justin808)
- **Improved input validation**: Enhanced package manager validation and argument sanitization across all generators [PR 1786](https://github.com/shakacode/react_on_rails/pull/1786) by [justin808](https://github.com/justin808)
- **Hardened DOM selectors**: Using `CSS.escape()` and proper JavaScript escaping for XSS protection [PR 1791](https://github.com/shakacode/react_on_rails/pull/1791) by [AbanoubGhadban](https://github.com/AbanoubGhadban)

#### Added

- **[Pro]** **Core/Pro separation**: Moved Pro features into dedicated `lib/react_on_rails/pro/` and `node_package/src/pro/` directories with clear licensing boundaries (now separated into `packages/react-on-rails-pro/` package) [PR 1791](https://github.com/shakacode/react_on_rails/pull/1791) by [AbanoubGhadban](https://github.com/AbanoubGhadban)
- **[Pro]** **Runtime license validation**: Implemented Pro license gating with graceful fallback to core functionality when Pro license unavailable [PR 1791](https://github.com/shakacode/react_on_rails/pull/1791) by [AbanoubGhadban](https://github.com/AbanoubGhadban)
- **[Pro]** **Enhanced immediate hydration**: Improved immediate hydration functionality with Pro license validation and warning badges [PR 1791](https://github.com/shakacode/react_on_rails/pull/1791) by [AbanoubGhadban](https://github.com/AbanoubGhadban)
- **[Pro]** **License documentation**: Added NOTICE files in Pro directories referencing canonical `REACT-ON-RAILS-PRO-LICENSE.md` [PR 1791](https://github.com/shakacode/react_on_rails/pull/1791) by [AbanoubGhadban](https://github.com/AbanoubGhadban)

#### Generator Improvements

- **Modern TypeScript patterns**: Generators now produce more idiomatic TypeScript code with improved type inference instead of explicit type annotations [PR 1786](https://github.com/shakacode/react_on_rails/pull/1786) by [justin808](https://github.com/justin808)
- **Optimized tsconfig.json**: Updated compiler options to use `"moduleResolution": "bundler"` for better bundler compatibility [PR 1786](https://github.com/shakacode/react_on_rails/pull/1786) by [justin808](https://github.com/justin808)
- **Enhanced Redux TypeScript integration**: Improved type safety and modern React patterns (useMemo, type-only imports) [PR 1786](https://github.com/shakacode/react_on_rails/pull/1786) by [justin808](https://github.com/justin808)
- **Smart bin/dev defaults**: Generated `bin/dev` script now automatically navigates to `/hello_world` route for immediate component visibility [PR 1786](https://github.com/shakacode/react_on_rails/pull/1786) by [justin808](https://github.com/justin808)
- **Better component templates**: Removed unnecessary type annotations while maintaining type safety through TypeScript's inference [PR 1786](https://github.com/shakacode/react_on_rails/pull/1786) by [justin808](https://github.com/justin808)
- **Cleaner generated code**: Streamlined templates following modern React and TypeScript best practices [PR 1786](https://github.com/shakacode/react_on_rails/pull/1786) by [justin808](https://github.com/justin808)
- **Improved helper methods**: Added reusable `component_extension` helper for consistent file extension handling [PR 1786](https://github.com/shakacode/react_on_rails/pull/1786) by [justin808](https://github.com/justin808)

#### Bug Fixes

- **Doctor rake task**: Fixed LoadError in `rake react_on_rails:doctor` when using packaged gem. The task was trying to require excluded `rakelib/task_helpers` file. [PR 1795](https://github.com/shakacode/react_on_rails/pull/1795) by [justin808](https://github.com/justin808)
- **Packs generator**: Fixed error when `server_bundle_js_file` configuration is empty (default). Added safety check to prevent attempting operations on invalid file paths when server-side rendering is not configured. [PR 1802](https://github.com/shakacode/react_on_rails/pull/1802) by [justin808](https://github.com/justin808)
- **Non-Packer Environment Compatibility**: Fixed potential NoMethodError when using bundle path resolution in environments without Shakapacker [PR 1798](https://github.com/shakacode/react_on_rails/pull/1798) by [justin808](https://github.com/justin808)
- **Shakapacker version requirements**: Fixed inconsistent version requirements between basic pack generation (6.5.1+) and advanced auto-bundling features (7.0.0+). Added backward compatibility for users on Shakapacker 6.5.1-6.9.x while providing clear upgrade guidance for advanced features. Added new constants `MINIMUM_SHAKAPACKER_VERSION_FOR_AUTO_BUNDLING` and improved version checking performance with caching. [PR 1798](https://github.com/shakacode/react_on_rails/pull/1798) by [justin808](https://github.com/justin808)

#### Code Improvements

- **PackerUtils abstraction removal**: Removed unnecessary `PackerUtils.packer` abstraction method and replaced all calls with direct `::Shakapacker` usage. This simplifies the codebase by eliminating an abstraction layer that was originally created to support multiple webpack tools but is no longer needed since we only support Shakapacker. All tests updated accordingly. [PR 1798](https://github.com/shakacode/react_on_rails/pull/1798) by [claude-code](https://claude.ai/code)
- **Architecture refactoring**: Centralized Pro utilities and clean separation between core and Pro helper functionality [PR 1791](https://github.com/shakacode/react_on_rails/pull/1791) by [AbanoubGhadban](https://github.com/AbanoubGhadban)

### [16.0.0] - 2025-09-16

**React on Rails v16 is a major release that modernizes the library with ESM support, removes legacy Webpacker compatibility, and introduces significant performance improvements. This release builds on the foundation of v14 with enhanced RSC (React Server Components) support and streamlined configuration.**

See [Release Notes](docs/oss/upgrading/release-notes/16.0.0.md) for complete migration guide.

#### Major Enhancements

**🚀 React Server Components (RSC) -- Requires React on Rails Pro**

- **Enhanced RSC rendering flow**: Eliminated double rendering and reduced HTTP requests
- **`RSCRoute` component**: Seamless server-side rendering with automatic payload injection and hydration [PR 1696](https://github.com/shakacode/react_on_rails/pull/1696) by [AbanoubGhadban](https://github.com/AbanoubGhadban)
- **Optimized RSC payload injection**: Now injected after component HTML markup for better performance [PR 1738](https://github.com/shakacode/react_on_rails/pull/1738) by [AbanoubGhadban](https://github.com/AbanoubGhadban)
- **Communication protocol v2.0.0**: Supports uploading multiple bundles at once for improved efficiency

**⚡ Performance & Loading Strategy**

- **New `generated_component_packs_loading_strategy`**: Choose from `sync`, `async`, or `defer` strategies [PR 1712](https://github.com/shakacode/react_on_rails/pull/1712) by [AbanoubGhadban](https://github.com/AbanoubGhadban)
- **Async render function support**: Components can now return from async render functions [PR 1720](https://github.com/shakacode/react_on_rails/pull/1720) by [AbanoubGhadban](https://github.com/AbanoubGhadban)
- **Optimized client imports**: Generated packs now import from `react-on-rails/client` for better tree-shaking [PR 1706](https://github.com/shakacode/react_on_rails/pull/1706) by [alexeyr-ci](https://github.com/alexeyr-ci)

#### Developer Experience

- **Enhanced error messaging**: Clearer troubleshooting steps and prominent optimization warnings
- **Modern global access**: Using `globalThis` instead of window/global detection [PR 1727](https://github.com/shakacode/react_on_rails/pull/1727) by [alexeyr-ci2](https://github.com/alexeyr-ci2)
- **Simplified CI configuration**: Clear `minimum`/`latest` dependency naming instead of `oldest`/`newest`
- **ReactRefreshWebpackPlugin v0.6.0 support**: Added conditional logic for proper configuration [PR 1748](https://github.com/shakacode/react_on_rails/pull/1748) by [judahmeek](https://github.com/judahmeek)
- **Version validation improvements**: Fixed invalid warnings with pre-release versions [PR 1742](https://github.com/shakacode/react_on_rails/pull/1742) by [alexeyr-ci2](https://github.com/alexeyr-ci2)

#### Breaking Changes

**🔧 Webpacker Support Removed**

- **Complete removal of Webpacker support**. Shakapacker >= 6.0 is now required.
- Migration:
  - Remove `webpacker` gem from your Gemfile
  - Install `shakapacker` gem version 6.0+ (8.0+ recommended)
  - Replace `bin/webpacker` commands with `bin/shakapacker`
  - Update webpacker configuration files to shakapacker equivalents
- Removed files: `rakelib/webpacker_examples.rake`, `lib/generators/react_on_rails/adapt_for_older_shakapacker_generator.rb`

**📦 Package System Modernization**

- **ESM-only package**: CommonJS `require()` no longer supported
- Migration:
  - Replace `require('react-on-rails')` with `import ReactOnRails from 'react-on-rails'`
  - For Node.js < 20.19.0, upgrade or use dynamic imports
  - For TypeScript errors, upgrade to TypeScript 5.8+ and set `module: "nodenext"`

**⚡ Configuration API Changes**

- **`defer_generated_component_packs` deprecated** → use `generated_component_packs_loading_strategy`
- Migration:
  - `defer_generated_component_packs: true` → `generated_component_packs_loading_strategy: :defer`
  - `defer_generated_component_packs: false` → `generated_component_packs_loading_strategy: :sync`
  - Recommended: `generated_component_packs_loading_strategy: :async` for best performance

- **`force_load` renamed to `immediate_hydration`** for API clarity
- Migration:
  - `config.force_load = true` → `config.immediate_hydration = true`
  - `react_component(force_load: true)` → `react_component(immediate_hydration: true)`
  - `redux_store(force_load: true)` → `redux_store(immediate_hydration: true)`
- Note: `immediate_hydration` requires React on Rails Pro license

**🔄 Async API Changes**

- **`ReactOnRails.reactOnRailsPageLoaded()` is now async**
- Migration: Add `await` when calling: `await ReactOnRails.reactOnRailsPageLoaded()`

**🏗️ Runtime Suggested Versions**

- Ruby: 3.2 - 3.4 (was 3.0 - 3.3)
- Node.js: 20 - 22 (was 16 - 20)
- Note: These are CI-tested versions; older versions may work but aren't guaranteed

**🎯 Generator Improvements**

- Install generator now validates JavaScript package manager presence
- Improved error handling with `Thor::Error` instead of `exit(1)`
- Enhanced error messages with clearer troubleshooting steps

### [15.0.0] - 2025-08-28 - RETRACTED

**⚠️ This version has been retracted due to API design issues. Please upgrade directly to v16.0.0.**

The `force_load` feature was incorrectly available without a Pro license and has been renamed to `immediate_hydration` for better clarity. All features from v15 are available in v16 with the corrected API.

### [14.2.0] - 2025-03-03

#### Added

- Add export option 'react-on-rails/client' to avoid shipping server-rendering code to browsers (~5KB improvement) [PR 1697](https://github.com/shakacode/react_on_rails/pull/1697) by [Romex91](https://github.com/Romex91).

#### Fixed

- Fix obscure errors by introducing FULL_TEXT_ERRORS [PR 1695](https://github.com/shakacode/react_on_rails/pull/1695) by [Romex91](https://github.com/Romex91).
- Disable `esModuleInterop` to increase interoperability [PR 1699](https://github.com/shakacode/react_on_rails/pull/1699) by [alexeyr-ci](https://github.com/alexeyr-ci).
- Resolved 14.1.1 incompatibility with eslint & made sure that spec/dummy is linted by eslint. [PR 1693](https://github.com/shakacode/react_on_rails/pull/1693) by [judahmeek](https://github.com/judahmeek).

#### Changed

- More up-to-date TS config [PR 1700](https://github.com/shakacode/react_on_rails/pull/1700) by [alexeyr-ci](https://github.com/alexeyr-ci).

### [14.1.1] - 2025-01-15

#### Fixed

- Separated streamServerRenderedReactComponent from the ReactOnRails object in order to stop users from getting errors during Webpack compilation about needing the `stream-browserify` package. [PR 1680](https://github.com/shakacode/react_on_rails/pull/1680) by [judahmeek](https://github.com/judahmeek).
- Removed obsolete `js-yaml` peer dependency. [PR 1678](https://github.com/shakacode/react_on_rails/pull/1678) by [alexeyr-ci](https://github.com/alexeyr-ci).

### [14.1.0] - 2025-01-06

#### Fixed

- Incorrect type and confusing name for `ReactOnRails.registerStore`, use `registerStoreGenerators` instead. [PR 1651](https://github.com/shakacode/react_on_rails/pull/1651) by [alexeyr-ci](https://github.com/alexeyr-ci).
- Changed the ReactOnRails' version checker to use `ReactOnRails.configuration.node_modules_location` to determine the location of the package.json that the `react-on-rails` dependency is expected to be set by.
- Also, all errors that would be raised by the version checking have been converted to `Rails.Logger` warnings to avoid any breaking changes. [PR 1657](https://github.com/shakacode/react_on_rails/pull/1657) by [judahmeek](https://github.com/judahmeek).
- Enable use as a `git:` dependency. [PR 1664](https://github.com/shakacode/react_on_rails/pull/1664) by [alexeyr-ci](https://github.com/alexeyr-ci).

#### Added

- Added streaming server rendering support:
  - [PR #1633](https://github.com/shakacode/react_on_rails/pull/1633) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
    - New `stream_react_component` helper for adding streamed components to views
    - New `streamServerRenderedReactComponent` function in the react-on-rails package that uses React 18's `renderToPipeableStream` API
    - Enables progressive page loading and improved performance for server-rendered React components
  - Added support for replaying console logs that occur during server rendering of streamed React components. This enables debugging of server-side rendering issues by capturing and displaying console output on the client and on the server output. [PR #1647](https://github.com/shakacode/react_on_rails/pull/1647) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
  - Added support for handling errors happening during server rendering of streamed React components. It handles errors that happen during the initial render and errors that happen inside suspense boundaries. [PR #1648](https://github.com/shakacode/react_on_rails/pull/1648) by [AbanoubGhadban](https://github.com/AbanoubGhadban).
  - Added support for passing options to `YAML.safe_load` when loading locale files with `config.i18n_yml_safe_load_options`. [PR #1668](https://github.com/shakacode/react_on_rails/pull/1668) by [dzirtusss](https://github.com/dzirtusss).

#### Changed

- Console replay script generation now awaits the render request promise before generating, allowing it to capture console logs from asynchronous operations. This requires using a version of the Node renderer that supports replaying async console logs. [PR #1649](https://github.com/shakacode/react_on_rails/pull/1649) by [AbanoubGhadban](https://github.com/AbanoubGhadban).

### [14.0.5] - 2024-08-20

#### Fixed

- Should force load react-components which send over turbo-stream [PR #1620](https://github.com/shakacode/react_on_rails/pull/1620) by [theforestvn88](https://github.com/theforestvn88).

### [14.0.4] - 2024-07-02

#### Improved

- Improved dependency management by integrating package_json. [PR 1639](https://github.com/shakacode/react_on_rails/pull/1639) by [vaukalak](https://github.com/vaukalak).

#### Changed

- Update outdated GitHub Actions to use Node.js 20.0 versions instead [PR 1623](https://github.com/shakacode/react_on_rails/pull/1623) by [adriangohjw](https://github.com/adriangohjw).

### [14.0.3] - 2024-06-28

#### Fixed

- Fixed css-loader installation with [PR 1634](https://github.com/shakacode/react_on_rails/pull/1634) by [vaukalak](https://github.com/vaukalak).
- Address a number of typos and grammar mistakes [PR 1631](https://github.com/shakacode/react_on_rails/pull/1631) by [G-Rath](https://github.com/G-Rath).
- Adds an adapter module & improves test suite to support all versions of Shakapacker. [PR 1622](https://github.com/shakacode/react_on_rails/pull/1622) by [adriangohjw](https://github.com/adriangohjw) and [judahmeek](https://github.com/judahmeek).

### [14.0.2] - 2024-06-11

#### Fixed

- Generator errors with Shakapacker v8+ fixed [PR 1629](https://github.com/shakacode/react_on_rails/pull/1629) by [vaukalak](https://github.com/vaukalak)

### [14.0.1] - 2024-05-16

#### Fixed

- Pack Generation: Added functionality that will add an import statement, if missing, to the server bundle entry point even if the auto-bundle generated files still exist [PR 1610](https://github.com/shakacode/react_on_rails/pull/1610) by [judahmeek](https://github.com/judahmeek).

### [14.0.0] - 2024-04-03

_Major bump because dropping support for Ruby 2.7 and deprecated `webpackConfigLoader.js`._

#### Removed

- Dropped Ruby 2.7 support [PR 1595](https://github.com/shakacode/react_on_rails/pull/1595) by [ahangarha](https://github.com/ahangarha).
- Removed deprecated `webpackConfigLoader.js` [PR 1600](https://github.com/shakacode/react_on_rails/pull/1600) by [ahangarha](https://github.com/ahangarha).

#### Fixed

- Trimmed the Gem to remove package.json which could cause superflous security warnings. [PR 1605](https://github.com/shakacode/react_on_rails/pull/1605) by [justin808](https://github.com/justin808).
- Prevent displaying the deprecation message for using `webpacker_precompile?` method and `webpacker:clean` rake task when using Shakapacker v7+ [PR 1592](https://github.com/shakacode/react_on_rails/pull/1592) by [ahangarha](https://github.com/ahangarha).
- Fixed Typescript types for ServerRenderResult, ReactComponent, RenderFunction, and RailsContext interfaces. [PR 1582](https://github.com/shakacode/react_on_rails/pull/1582) & [PR 1585](https://github.com/shakacode/react_on_rails/pull/1585) by [kotarella1110](https://github.com/kotarella1110)
- Removed a workaround in `JsonOutput#escape` for an no-longer supported Rails version. Additionally, removed `Utils.rails_version_less_than_4_1_1`
  which was only used in the workaround. [PR 1580](https://github.com/shakacode/react_on_rails/pull/1580) by [wwahammy](https://github.com/wwahammy)

#### Added

- Exposed TypeScript all types [PR 1586](https://github.com/shakacode/react_on_rails/pull/1586) by [kotarella1110](https://github.com/kotarella1110)

### [13.4.0] - 2023-07-30

#### Fixed

- Fixed Pack Generation logic during `assets:precompile` if `auto_load_bundle` is `false` & `components_subdirectory` is not set. [PR 1567](https://github.com/shakacode/react_on_rails/pull/1545) by [blackjack26](https://github.com/blackjack26) & [judahmeek](https://github.com/judahmeek).

#### Improved

- Improved performance by removing an unnecessary JS eval from Ruby. [PR 1544](https://github.com/shakacode/react_on_rails/pull/1544) by [wyattades](https://github.com/wyattades).

#### Added

- Added support for Shakapacker 7 in install generator [PR 1548](https://github.com/shakacode/react_on_rails/pull/1548) by [ahangarha](https://github.com/ahangarha).

#### Changed

- Throw error when attempting to redefine ReactOnRails. [PR 1562](https://github.com/shakacode/react_on_rails/pull/1562) by [rubenochiavone](https://github.com/rubenochiavone).
- Prevent generating FS-based packs when `component_subdirectory` configuration is not present. [PR 1567](https://github.com/shakacode/react_on_rails/pull/1567) by [blackjack26](https://github.com/blackjack26).
- Removed a requirement for autoloaded pack files to be generated as part of CI or deployment separate from initial Shakapacker bundling. [PR 1545](https://github.com/shakacode/react_on_rails/pull/1545) by [judahmeek](https://github.com/judahmeek).

### [13.3.5] - 2023-05-31

#### Fixed

- Fixed race condition where a React component could attempt to initialize before it had been registered. [PR 1540](https://github.com/shakacode/react_on_rails/pull/1540) by [judahmeek](https://github.com/judahmeek).

### [13.3.4] - 2023-05-23

#### Added

- Improved functionality of Filesystem-based pack generation & auto-bundling. Added `make_generated_server_bundle_the_entrypoint` configuration key. [PR 1531](https://github.com/shakacode/react_on_rails/pull/1531) by [judahmeek](https://github.com/judahmeek).

#### Removed

- Removed unneeded `HMR=true` from `Procfile.dev` in install template [PR 1537](https://github.com/shakacode/react_on_rails/pull/1537) by [ahangarha](https://github.com/ahangarha).

### [13.3.3] - 2023-03-21

#### Fixed

- Fixed bug regarding loading FS-based packs. [PR 1527](https://github.com/shakacode/react_on_rails/pull/1527) by [judahmeek](https://github.com/judahmeek).

### [13.3.2] - 2023-02-24

#### Fixed

- Fixed the bug in `bin/dev` and `bin/dev-static` scripts by using `system` instead of `exec` and remove option to pass arguments [PR 1519](https://github.com/shakacode/react_on_rails/pull/1519) by [ahangarha](https://github.com/ahangarha).

### [13.3.1] - 2023-01-30

#### Added

- Optimized `ReactOnRails::TestHelper`'s RSpec integration using `when_first_matching_example_defined`. [PR 1496](https://github.com/shakacode/react_on_rails/pull/1496) by [mcls](https://github.com/mcls).

#### Fixed

- Fixed bug regarding FS-based packs generation. [PR 1515](https://github.com/shakacode/react_on_rails/pull/1515) by [pulkitkkr](https://github.com/pulkitkkr).

### [13.3.0] - 2023-01-29

#### Fixed

- Fixed pack not found warning while using `react_component` and `react_component_hash` helpers, even when corresponding chunks are present. [PR 1511](https://github.com/shakacode/react_on_rails/pull/1511) by [pulkitkkr](https://github.com/pulkitkkr).
- Fixed FS-based packs generation functionality to trigger pack generation on the creation of a new React component inside `components_subdirectory`. [PR 1506](https://github.com/shakacode/react_on_rails/pull/1506) by [pulkitkkr](https://github.com/pulkitkkr).
- Upgrade several JS dependencies to fix security issues. [PR 1514](https://github.com/shakacode/react_on_rails/pull/1514) by [ahangarha](https://github.com/ahangarha).

#### Added

- Added `./bin/dev` and `./bin/dev-static` executables to ease and standardize running the dev server. [PR 1491](https://github.com/shakacode/react_on_rails/pull/1491) by [ahangarha](https://github.com/ahangarha).

### [13.2.0] - 2022-12-23

#### Fixed

- Fix reactOnRailsPageUnloaded when there is no component on the page. Important for apps using both hotwire and react_on_rails. [PR 1498](https://github.com/shakacode/react_on_rails/pull/1498) by [NhanHo](https://github.com/NhanHo).
- Fixing wrong type. The throwIfMissing param of getStore should be optional as it defaults to true. [PR 1480](https://github.com/shakacode/react_on_rails/pull/1480) by [wouldntsavezion](https://github.com/wouldntsavezion).

#### Added

- Exposed `reactHydrateOrRender` utility via [PR 1481](https://github.com/shakacode/react_on_rails/pull/1481) by [vaukalak](https://github.com/vaukalak).

### [13.1.0] - 2022-08-20

#### Improved

- Removed addition of `mini_racer` gem by default. [PR 1453](https://github.com/shakacode/react_on_rails/pull/1453) by [vtamara](https://github.com/vtamara) and [tomdracz](https://github.com/tomdracz).

  Using `mini_racer` makes most sense when deploying or building in environments that do not have Javascript runtime present. Since `react_on_rails` requires Node.js, there's no reason to override `ExecJS` runtime with `mini_racer`.

  To migrate this change, remove `mini_racer` gem from your `Gemfile` and test your app for correct behaviour. You can continue using `mini_racer` and it will be still picked as the default `ExecJS` runtime, if present in your app `Gemfile`.

- Upgraded the example test app in `spec/dummy` to React 18. [PR 1463](https://github.com/shakacode/react_on_rails/pull/1463) by [alexeyr](https://github.com/alexeyr).

- Added file-system-based automatic bundle generation feature. [PR 1455](https://github.com/shakacode/react_on_rails/pull/1455) by [pulkitkkr](https://github.com/pulkitkkr).

#### Fixed

- Correctly unmount roots under React 18. [PR 1466](https://github.com/shakacode/react_on_rails/pull/1466) by [alexeyr](https://github.com/alexeyr).

- Fixed the `You are importing hydrateRoot from "react-dom" [...] You should instead import it from "react-dom/client"` warning under React 18 ([#1441](https://github.com/shakacode/react_on_rails/issues/1441)). [PR 1460](https://github.com/shakacode/react_on_rails/pull/1460) by [alexeyr](https://github.com/alexeyr).

  In exchange, you may see a warning like this when building using any version of React below 18:

  ```text
  WARNING in ./node_modules/react-on-rails/node_package/lib/reactHydrateOrRender.js19:25-52
  Module not found: Error: Can't resolve 'react-dom/client' in '/home/runner/work/react_on_rails/react_on_rails/spec/dummy/node_modules/react-on-rails/node_package/lib'
   @ ./node_modules/react-on-rails/node_package/lib/ReactOnRails.js 34:45-78
   @ ./client/app/packs/client-bundle.js 5:0-42 32:0-23 35:0-21 59:0-26
  ```

  _Note: The `node_package/lib/` path in these error examples is now `packages/react-on-rails/lib/` in the current structure._

  It can be safely [suppressed](https://webpack.js.org/configuration/other-options/#ignorewarnings) in your Webpack configuration.

### [13.0.2] - 2022-03-09

#### Fixed

- React 16 doesn't support version property, causing problems loading React on Rails. [PR 1435](https://github.com/shakacode/react_on_rails/pull/1435) by [justin808](https://github.com/justin808).

### [13.0.1] - 2022-02-09

#### Improved

- Updated the default generator. [PR 1431](https://github.com/shakacode/react_on_rails/pull/1431) by [justin808](https://github.com/justin808).

### [13.0.0] - 2022-02-08

#### Breaking

- Removed webpacker as a dependency. Add gem Shakapacker to your project, and update your package.json to also use shakapacker.

#### Fixed

- Proper throwing of exceptions.
- Default configuration better handles test env.

### [12.6.0] - 2022-01-22

#### Added

- A `rendering_props_extension` configuration which takes a module with an `adjust_props_for_client_side_hydration` method, which is used to process props differently for server/client if `prerender` is set to `true`. [PR 1413](https://github.com/shakacode/react_on_rails/pull/1413) by [gscarv13](https://github.com/gscarv13) & [judahmeek](https://github.com/judahmeek).

### [12.5.2] - 2021-12-29

#### Fixed

- Usage of config.build_production_command for custom command for production builds fixed. [PR 1415](https://github.com/shakacode/react_on_rails/pull/1415) by [judahmeek](https://github.com/judahmeek).

### [12.5.1] - 2021-12-27

#### Fixed

- A fatal server rendering error if running an ReactOnRails >=12.4.0 with ReactOnRails Pro <2.4.0. [PR 1412](https://github.com/shakacode/react_on_rails/pull/1412) by [judahmeek](https://github.com/judahmeek).

### [12.5.0] - 2021-12-26

#### Added

- Support for React 18, including the changed SSR API. [PR 1409](https://github.com/shakacode/react_on_rails/pull/1409) by [kylemellander](https://github.com/kylemellander).
- Added Webpack configuration files as part of the generator and updated webpacker to version 6. [PR 1404](https://github.com/shakacode/react_on_rails/pull/1404) by [gscarv13](https://github.com/gscarv13).
- Supports Rails 7.

#### Changed

- Changed logic of determining the usage of the default rails/webpacker Webpack config or a custom command to only check if the config.build_production_command is defined. [PR 1402](https://github.com/shakacode/react_on_rails/pull/1402) by [justin808](https://github.com/justin808) and [gscarv13](https://github.com/gscarv13).
- Minimum required Ruby is 2.7 to match latest rails/webpacker.

### [12.4.0] - 2021-09-22

#### Added

- ScoutAPM tracing support for server rendering [PR 1379](https://github.com/shakacode/react_on_rails/pull/1379) by [justin808](https://github.com/justin808).

- Ability to stop React on Rails from modifying or creating the `assets:precompile` task. [PR 1371](https://github.com/shakacode/react_on_rails/pull/1371) by [justin808](https://github.com/justin808). Thanks to [elstgav](https://github.com/elstgav) for [the suggestion](https://github.com/shakacode/react_on_rails/issues/1368)!

- Added the ability to have render functions return a promise to be awaited by React on Rails Pro Node Renderer. [PR 1380](https://github.com/shakacode/react_on_rails/pull/1380) by [judahmeek](https://github.com/judahmeek)

### [12.3.0] - 2021-07-26

#### Added

- Ability to use with Turbo (@hotwired/turbo), as Turbolinks gets obsolete. [PR 1374](https://github.com/shakacode/react_on_rails/pull/1374) by [pgruener](https://github.com/pgruener) and [PR 1377](https://github.com/shakacode/react_on_rails/pull/1377) by [mdesantis](https://github.com/mdesantis).

  To configure turbo the following option can be set:
  `ReactOnRails.setOptions({ turbo: true })`

### [12.2.0] - 2021-03-25

#### Added

- Ability to configure server React rendering to throw rather than just logging the error. Useful for
  React on Rails Pro Node rendering [PR 1365](https://github.com/shakacode/react_on_rails/pull/1365) by [justin808](https://github.com/justin808).

### [12.1.0] - 2021-03-23

#### Added

- Added the ability to assign a module with a `call` method to `config.build_production_command`. See [the configuration docs](https://reactonrails.com/docs/configuration/). [PR 1362: Accept custom module for config.build_production_command](https://github.com/shakacode/react_on_rails/pull/1362).

#### Fixed

- Stop setting NODE_ENV value during precompile, as it interfered with rails/webpacker's setting of NODE_ENV to production by default. Fixes [#1334](https://github.com/shakacode/react_on_rails/issues/1334). [PR 1356: Don't set NODE_ENV in assets.rake](https://github.com/shakacode/react_on_rails/pull/1356) by [alexrozanski](https://github.com/alexrozanski).

### [12.0.4] - 2020-11-14

#### Fixed

- Install generator now specifies the version. Fixes [React on Rails Generator installs the older npm package #1336](https://github.com/shakacode/react_on_rails/issues/1336). [PR 1338: Fix Generator to use Exact NPM Version](https://github.com/shakacode/react_on_rails/pull/1338) by [justin808](https://github.com/justin808).

### [12.0.3] - 2020-09-20

#### Fixed

- Async script loading optimizes page load speed. With this fix, a bundle
  can be loaded "async" and a handler function can determine when to hydrate.
  For an example of this, see the [docs for loadable-components SSR](https://loadable-components.com/docs/server-side-rendering/#4-add-loadableready-client-side).
  [PR 1327](https://github.com/shakacode/react_on_rails/pull/1327) by [justin808](https://github.com/justin808).
  Loadable-Components is supported by [React on Rails Pro](https://pro.reactonrails.com).

### [12.0.2] - 2020-07-09

#### Fixed

- Remove dependency upon Redux for Typescript types. [PR 1323](https://github.com/shakacode/react_on_rails/pull/1323) by [justin808](https://github.com/justin808).

### [12.0.1] - 2020-07-09

#### Fixed

- Changed invocation of webpacker:clean to use a very large number of versions so it does not accidentally delete the server-bundle.js. [PR 1306](https://github.com/shakacode/react_on_rails/pull/1306) by By [justin808](https://github.com/justin808).

### [12.0.0] - 2020-07-08

For upgrade instructions, see the [upgrading guide](https://reactonrails.com/docs/upgrading/upgrading-react-on-rails).

#### Major Improvements

1. **React Hooks Support** for top level components
2. **Typescript bindings**
3. **rails/webpacker** "just works" with React on Rails by default.
4. i18n support for generating a JSON file rather than a JS file.

#### BREAKING CHANGE

In order to solve the issues regarding React Hooks compatibility, the number of parameters
for functions is used to determine if you have a generator function that will get invoked to
return a React component, or you are registering a functional React component. Alternately, you can
set JavaScript property `renderFunction` on the function for which you want to return to be
invoked to return the React component. In that case, you won't need to pass any unused params.
[PR 1268](https://github.com/shakacode/react_on_rails/pull/1268) by [justin808](https://github.com/justin808)

See [docs/guides/upgrading-react-on-rails](https://reactonrails.com/docs/upgrading/upgrading-react-on-rails#upgrading-to-v12)
for details.

#### Other Updates

- `react_on_rails` fully supports `rails/webpacker`. The example test app in `spec/dummy` was recently converted over to use rails/webpacker v4+. It's a good example of how to leverage rails/webpacker's Webpack configuration for server-side rendering.
- Changed the precompile task to use the rails/webpacker one by default
- Updated generators to use React hooks
- Requires the use of rails/webpacker view helpers
- If the webpacker Webpack config files exist, then React on Rails will not override the default
  assets:precompile set up by rails/webpacker. If you are not using the rails/webpacker setup for Webpack,
  then be sure to remove the JS files inside of config/webpack, like `config/webpack/production.js.`
- Removed **env_javascript_include_tag** and **env_stylesheet_link_tag** as these are replaced by view helpers
  from rails/webpacker
- Removal of support for old Rubies and Rails.
- Removal of config.symlink_non_digested_assets_regex as it's no longer needed with rails/webpacker.
  If any business needs this, we can move the code to a separate gem.
- Added configuration option `same_bundle_for_client_and_server` with default `false` because
  1. Production applications would typically have a server bundle that differs from the client bundle
  2. This change only affects trying to use HMR with react_on_rails with rails/webpacker.

  The previous behavior was to always go to the webpack-dev-server for the server bundle if the
  webpack-dev-server was running _and_ the server bundle was found in the `manifest.json`.

  If you are using the **same bundle for client and server rendering**, then set this configuration option
  to `true`. By [justin808](https://github.com/shakacode/react_on_rails/pull/1240).

- Added support to export locales in JSON format. New option added `i18n_output_format` which allows to
  specify locales format either `JSON` or `JS`. **`JSON` format is now the default.**

  **Use this config setting to get the old behavior: config.i18n_output_format = 'js'**

  [PR 1271](https://github.com/shakacode/react_on_rails/pull/1271) by [ashgaliyev](https://github.com/ashgaliyev).

- Added Typescript definitions to the Node package. By [justin808](https://github.com/justin808) and [judahmeek](https://github.com/judahmeek) in [PR 1287](https://github.com/shakacode/react_on_rails/pull/1287).
- Removed restriction to keep the server bundle in the same directory with the client bundles. Rails/webpacker 4 has an advanced cleanup that will remove any files in the directory of other Webpack files. Removing this restriction allows the server bundle to be created in a sibling directory. By [justin808](https://github.com/shakacode/react_on_rails/pull/1240).

### [11.3.0] - 2019-05-24

#### Added

- Added method for retrieving any option from `render_options` [PR 1213](https://github.com/shakacode/react_on_rails/pull/1213)
  by [ashgaliyev](https://github.com/ashgaliyev).

- html_options has an option for 'tag' to set the html tag name like this: `html_options: { tag: "span" }`.
  [PR 1208](https://github.com/shakacode/react_on_rails/pull/1208) by [tahsin352](https://github.com/tahsin352).

### [11.2.2] - 2018-12-24

#### Improved

- rails_context can more easily be called from controller methods. The mandatory param of server_side has been made optional.

### [11.2.1] - 2018-12-06

## MIGRATION for v11.2

- If using **React on Rails Pro**, upgrade react_on_rails_pro to a version >= 1.3.

#### Improved

- To support React v16, updated API for manually calling `ReactOnRails.render(name, props, domNodeId, hydrate)`. Added 3rd @param hydrate Pass truthy to update server rendered html. Default is falsey Any truthy values calls hydrate rather than render. [PR 1159](https://github.com/shakacode/react_on_rails/pull/1159) by [justin808](https://github.com/justin808) and [coopersamuel](https://github.com/coopersamuel).

- Enabled the use of webpack-dev-server with Server-side rendering. [PR 1173](https://github.com/shakacode/react_on_rails/pull/1173) by [justin808](https://github.com/justin808) and [judahmeek](https://github.com/judahmeek).

#### Changed

- Changed the default for:

  ```rb
  config.raise_on_prerender_error = Rails.env.development?
  ```

  Thus, developers will need to fix server rendering errors before continuing.
  [PR 1145](https://github.com/shakacode/react_on_rails/pull/1145) by [justin808](https://github.com/justin808).

### 11.2.0 - 2018-12-06

Do not use. Unpublished. Caused by an issue with the release script.

### [11.1.8] - 2018-10-14

#### Improved

- Improved tutorial and support for HMR when using `rails/webpacker` for Webpack configuration. [PR 1156](https://github.com/shakacode/react_on_rails/pull/1156) by [justin808](https://github.com/justin808).

### [11.1.7] - 2018-10-10

#### Fixed

- Fixed bug where intl parsing would fail when trying to parse integers or blank entries. by [sepehr500](https://github.com/sepehr500)

### [11.1.6] - 2018-10-05

#### Fixed

- Fix client startup invoking render prematurely, **AGAIN**. Fix additional cases of client startup failing during interactive readyState". Closes [issue #1150](https://github.com/shakacode/react_on_rails/issues/1150). [PR 1152](https://github.com/shakacode/react_on_rails/pull/1152) by [rakelley](https://github.com/rakelley).

### [11.1.5] - 2018-10-03

#### Fixed

- Fix client startup invoking render prematurely. Closes [issue #1150](https://github.com/shakacode/react_on_rails/issues/1150). [PR 1151](https://github.com/shakacode/react_on_rails/pull/1151) by [rakelley](https://github.com/rakelley).

### [11.1.4] - 2018-09-12

#### Fixed

- Ignore Arrays in Rails i18n yml files. [PR 1129](https://github.com/shakacode/react_on_rails/pull/1129) by [vcarel](https://github.com/vcarel).
- Fix to apply transform-runtime. And work with Babel 6 and 7. (Include revert of [PR 1136](https://github.com/shakacode/react_on_rails/pull/1136)) [PR 1140](https://github.com/shakacode/react_on_rails/pull/1140) by [Ryunosuke Sato](https://github.com/tricknotes).
- Upgrade Babel version to 7 [PR 1141](https://github.com/shakacode/react_on_rails/pull/1141) by [Ryunosuke Sato](https://github.com/tricknotes).

### [11.1.3] - 2018-08-26

#### Fixed

- Don't apply babel-plugin-transform-runtime inside react-on-rails to work with babel 7. [PR 1136](https://github.com/shakacode/react_on_rails/pull/1136) by [Ryunosuke Sato](https://github.com/tricknotes).
- Add support for webpacker 4 prereleases. [PR 1134](https://github.com/shakacode/react_on_rails/pull/1134) by [Judahmeek](https://github.com/Judahmeek))

### [11.1.2] - 2018-08-18

#### Fixed

- Tests now properly exit if the config.build_test_command fails!
- Source path for project using Webpacker would default to "app/javascript" even if when the node_modules
  directory was set to "client". Fix now makes the configuration of this crystal clear.
- renamed method RenderOptions.has_random_dom_id? to RenderOptions.random_dom_id? for rubocop rule.
  [PR 1133](https://github.com/shakacode/react_on_rails/pull/1133) by [justin808](https://github.com/justin808)

### [11.1.1] - 2018-08-09

#### Fixed

- `TRUE` was deprecated in ruby 2.4, using `true` instead. [PR 1128](https://github.com/shakacode/react_on_rails/pull/1128) by [Aguardientico](https://github.com/Aguardientico).

### [11.1.0] - 2018-08-07

#### Added

- Add random dom id option. This new global and react_component helper option allows configuring whether or not React on Rails will automatically add a random id to the DOM node ID. [PR 1121](https://github.com/shakacode/react_on_rails/pull/1121) by [justin808](https://github.com/justin808)
  - Added configuration option random_dom_id
  - Added method RenderOptions has_random_dom_id?

#### Fixed

- Fix invalid warn directive. [PR 1123](https://github.com/shakacode/react_on_rails/pull/1123) by [mustangostang](https://github.com/mustangostang).

### [11.0.10] - 2018-07-22

#### Fixed

- Much better logging of rendering errors when there are lots of props. Only the a 1,000 chars are logged, and the center is indicated to be truncated. [PR 1117](https://github.com/shakacode/react_on_rails/pull/1117) and [PR 1118](https://github.com/shakacode/react_on_rails/pull/1118) by [justin808](https://github.com/justin808).
- Properly clearing hydrated stores when server rendering. [PR 1120](https://github.com/shakacode/react_on_rails/pull/1120) by [squadette](https://github.com/squadette).

### [11.0.9] - 2018-06-24

- Handle <script async> for Webpack bundle transparently. Closes [issue #290](https://github.com/shakacode/react_on_rails/issues/290) [PR 1099](https://github.com/shakacode/react_on_rails/pull/1099) by [squadette](https://github.com/squadette). Merged in [PR 1107](https://github.com/shakacode/react_on_rails/pull/1107).

### [11.0.8] - 2018-06-15

#### Fixed

- HashWithIndifferent access for props threw if used for props. [PR 1100](https://github.com/shakacode/react_on_rails/pull/1100) by [justin808](https://github.com/justin808).
- Test helper for detecting stale bundles did not properly handle the case of a server-bundle.js without a hash.[PR 1102](https://github.com/shakacode/react_on_rails/pull/1102) by [justin808](https://github.com/justin808).
- Fix test helper determination of stale assets. [PR 1093](https://github.com/shakacode/react_on_rails/pull/1093) by [justin808](https://github.com/justin808).

#### Changed

- Document how to manually rehydrate XHR-substituted components on client side. [PR 1095](https://github.com/shakacode/react_on_rails/pull/1095) by [hchevalier](https://github.com/hchevalier).

### [11.0.7] - 2018-05-16

#### Fixed

- Fix npm publishing. [PR 1090](https://github.com/shakacode/react_on_rails/pull/1090) by [justin808](https://github.com/justin808).

### [11.0.6] - 2018-05-15

#### Changed

- Even more detailed errors for Honeybadger and Sentry when there's a JSON parse error on server rendering. [PR 1086](https://github.com/shakacode/react_on_rails/pull/1086) by [justin808](https://github.com/justin808).

### [11.0.5] - 2018-05-11

#### Changed

- More detailed errors for Honeybadger and Sentry. [PR 1081](https://github.com/shakacode/react_on_rails/pull/1081) by [justin808](https://github.com/justin808).

### [11.0.4] - 2018-05-3

#### Changed

- Throw if configuration.generated_assets_dir specified, and using webpacker, and if that doesn't match the public_output_path. Otherwise, warn if generated_assets_dir is specified
- Fix the setup for tests for spec/dummy so they automatically rebuild by correctly setting the source_path in the webpacker.yml
- Updated documentation for the testing setup.
- Above in [PR 1072](https://github.com/shakacode/react_on_rails/pull/1072) by [justin808](https://github.com/justin808).
- `react_component_hash` has implicit `prerender: true` because it makes no sense to have react_component_hash not use prerrender. Improved docs on `react_component_hash`. Also, fixed issue where checking gem existence. [PR 1077](https://github.com/shakacode/react_on_rails/pull/1077) by [justin808](https://github.com/justin808).

### [11.0.3] - 2018-04-24

#### Fixed

- Fixed issue with component script initialization when using react_component_hash. [PR 1071](https://github.com/shakacode/react_on_rails/pull/1071) by [jblasco3](https://github.com/jblasco3).

### [11.0.2] - 2018-04-24

#### Fixed

- Server rendering error for React on Rails Pro. [PR 1069](https://github.com/shakacode/react_on_rails/pull/1069) by [justin808](https://github.com/justin808).

### [11.0.1] - 2018-04-23

#### Added

- `react_component` allows logging_on_server specified at the component level. [PR 1068](https://github.com/shakacode/react_on_rails/pull/1068) by [justin808](https://github.com/justin808).

#### Fixed

- Missing class when throwing some error messages. [PR 1068](https://github.com/shakacode/react_on_rails/pull/1068) by [justin808](https://github.com/justin808).

### [11.0.0] - 2018-04-21

## MIGRATION for v11

- Unused `server_render_method` was removed from the configuration. If you want to use a custom renderer, contact justin@shakacode.com. We have a custom node rendering solution in production for egghead.io.
- Removed ReactOnRails::Utils.server_bundle_file_name and ReactOnRails::Utils.bundle_file_name. These are part of the performance features of "React on Rails Pro".
- Removed ENV["TRACE_REACT_ON_RAILS"] usage and replacing it with config.trace.

#### Enhancements: Better Error Messages, Support for React on Rails Pro

- Tracing (debugging) options are simplified with a single `config.trace` setting that defaults to true for development and false otherwise.
- Calls to setTimeout, setInterval, clearTimeout will now always log some message if config.trace is true. Your JavaScript code should not be calling setTimout when server rendering.
- Errors raised are of type ReactOnRailsError, so you can see they came from React on Rails for debugging.
- Removed ReactOnRails::Utils.server_bundle_file_name and ReactOnRails::Utils.bundle_file_name.
- No longer logging the `railsContext` when server logging.
- Rails.env is provided in the default railsContext, as suggested in [issue #697](https://github.com/shakacode/react_on_rails/issues/697).
  [PR 1065](https://github.com/shakacode/react_on_rails/pull/1065) by [justin808](https://github.com/justin808).

#### Fixes

- More exact version checking. We keep the react_on_rails gem and the react-on-rails node package at
  the same exact versions so that we can be sure that the interaction between them is precise.
  This is so that if a bug is detected after some update, it's critical that
  both the gem and the node package get the updates. This change ensures that the package.json specification does not use a
  ~ or ^ as reported in [issue #1062](https://github.com/shakacode/react_on_rails/issues/1062). [PR 1063](https://github.com/shakacode/react_on_rails/pull/1063) by [justin808](https://github.com/justin808).
- Sprockets: Now use the most recent manifest when creating symlinks. See [issue #1023](https://github.com/shakacode/react_on_rails/issues/1023). [PR 1064](https://github.com/shakacode/react_on_rails/pull/1064) by [justin808](https://github.com/justin808).

### [10.1.4] - 2018-04-11

#### Fixed

- Changed i18n parsing to convert ruby i18n argument syntax into FormatJS argument syntax. [PR 1046](https://github.com/shakacode/react_on_rails/pull/1046) by [sepehr500](https://github.com/sepehr500).

- Fixed an issue where the spec compiler check would fail if the project path contained spaces. [PR 1045](https://github.com/shakacode/react_on_rails/pull/1045) by [andrewmarkle](https://github.com/andrewmarkle).

- Updated the default `build_production_command` that caused production assets to be built with development settings. [PR 1053](https://github.com/shakacode/react_on_rails/pull/1053) by [Roman Kushnir](https://github.com/RKushnir).

### [10.1.3] - 2018-02-28

#### Fixed

- Improved error reporting on version mismatches between Javascript and Ruby packages. [PR 1025](https://github.com/shakacode/react_on_rails/pull/1025) by [theJoeBiz](https://github.com/squadette).

### [10.1.2] - 2018-02-27

#### Fixed

- Use ReactDOM.hydrate() for hydrating a SSR component if available. ReactDOM.render() has been deprecated for use on SSR components in React 16 and this addresses the warning. [PR 1028](https://github.com/shakacode/react_on_rails/pull/1028) by [theJoeBiz](https://github.com/theJoeBiz).

### [10.1.1] - 2018-01-26

#### Fixed

- Fixed issue with server-rendering error handler: [PR 1020](https://github.com/shakacode/react_on_rails/pull/1020) by [jblasco3](https://github.com/jblasco3).

### [10.1.0] - 2018-01-23

#### Added

- Added 2 cache helpers: ReactOnRails::Utils.bundle_file_name(bundle_name) and ReactOnRails::Utils.server_bundle_file_name
  for easy access to the hashed filenames for use in cache keys. [PR 1018](https://github.com/shakacode/react_on_rails/pull/1018) by [justin808](https://github.com/justin808).

#### Fixed

- Use Redux component in the generated Redux Hello World example: [PR 1006](https://github.com/shakacode/react_on_rails/pull/1006) by [lewaabahmad](https://github.com/lewaabahmad).
- Fixed `Utils.bundle_js_file_path` generating the incorrect path for `manifest.json` in webpacker projects: [Issue #1011](https://github.com/shakacode/react_on_rails/issues/1011) by [elstgav](https://github.com/elstgav)

### [10.0.2] - 2017-11-10

#### Fixed

- Remove unnecessary dependencies from released NPM package: [PR 968](https://github.com/shakacode/react_on_rails/pull/968) by [tricknotes](https://github.com/tricknotes).

### [10.0.1] - 2017-10-28

#### Fixed

- Fixed `react_component_hash` functionality in cases of prerendering errors: [PR 960](https://github.com/shakacode/react_on_rails/pull/960) by [Judahmeek](https://github.com/Judahmeek).
- Fix to add missing dependency to run generator spec individually: [PR 962](https://github.com/shakacode/react_on_rails/pull/962) by [tricknotes](https://github.com/tricknotes).
- Fixes check for i18n_dir in LocalesToJs returning false when i18n_dir was set. [PR 899](https://github.com/shakacode/react_on_rails/pull/899) by [hakongit](https://github.com/hakongit).
- Fixed mistake in rubocop comments that led to errors when handling exceptions in ReactOnRails::ServerRendering::Exec [PR 963](https://github.com/shakacode/react_on_rails/pull/963) by [railsme](https://github.com/railsme).
- Fixed and improved I18n directories checks: [PR 967](https://github.com/shakacode/react_on_rails/pull/967) by [railsme](https://github.com/railsme)

### [10.0.0] - 2017-10-08

#### Created

- Created `react_component_hash` method for react_helmet support.

#### Deprecated

- Deprecated `react_component` functionality for react_helmet support.
  To clarify, the method itself is not deprecated, only certain functionality which has been moved to `react_component_hash`
  [PR 951](https://github.com/shakacode/react_on_rails/pull/951) by [Judahmeek](https://github.com/Judahmeek).

### [9.0.3] - 2017-09-20

#### Improved

- Improved comments in generated Procfile.dev-server. [PR 940](https://github.com/shakacode/react_on_rails/pull/940) by [justin808](https://github.com/justin808).

### [9.0.2] - 2017-09-10

#### Fixed

- Improved post install doc comments for generator. [PR 933](https://github.com/shakacode/react_on_rails/pull/933) by [justin808](https://github.com/justin808).

### [9.0.1] - 2017-09-10

#### Fixed

- Fixes Rails 3.2 compatability issues. [PR 926](https://github.com/shakacode/react_on_rails/pull/926) by [morozovm](https://github.com/morozovm).

### [9.0.0] - 2017-09-06

Updated React on Rails to depend on [rails/webpacker](https://github.com/rails/webpacker). [PR 908](https://github.com/shakacode/react_on_rails/pull/908) by [justin808](https://github.com/justin808).

#### 9.0 from 8.x. Upgrade Instructions

Moved to [our documentation](https://reactonrails.com/docs/upgrading/upgrading-react-on-rails#upgrading-to-version-9).

### [8.0.7] - 2017-08-16

#### Fixed

- Fixes generator bug by keeping blank line at top in case existing .gitignore does not end in a newline. [#916](https://github.com/shakacode/react_on_rails/pull/916) by [justin808](https://github.com/justin808).

### [8.0.6] - 2017-07-19

#### Fixed

- Fixes server rendering when using a CDN. Server rendering would try to fetch a file with the "asset_host". This change updates the webpacker_lite dependency to 2.1.0 which has a new helper `pack_path`. [#901](https://github.com/shakacode/react_on_rails/pull/901) by [justin808](https://github.com/justin808). Be sure to update webpacker_lite to 2.1.0.
- The package.json file created by the generator now creates minified javascript production builds by default. This was done by adding the -p flag to Webpack on the build:production script. [#895](https://github.com/shakacode/react_on_rails/pull/895) by [serodriguez68 ](https://github.com/serodriguez68)
- Fixes GitUtils.uncommitted_changes? throwing an error when called in an environment without Git, and allows install generator to be run successfully with `--ignore-warnings` [#878](https://github.com/shakacode/react_on_rails/pull/878) by [jasonblalock](https://github.com/jasonblalock).

## [8.0.5] - 2017-07-04

#### Fixed

- Corrects `devBuild` value for webpack production build from webpackConfigLoader. [#877](https://github.com/shakacode/react_on_rails/pull/877) by [chenqingspring](https://github.com/chenqingspring).
- Remove contentBase deprecation warning message. [#878](https://github.com/shakacode/react_on_rails/pull/878) by [ened ](https://github.com/ened).
- Removes invalid reference to \_railsContext in the generated files. [#886](https://github.com/shakacode/react_on_rails/pull/886) by [justin808](https://github.com/justin808).
- All tests run against Rails 5.1.2

_Note: 8.0.4 skipped._

## [8.0.3] - 2017-06-19

#### Fixed

- Ruby 2.1 issue due to `<<~` as reported in [issue #870](https://github.com/shakacode/react_on_rails/issues/870). [#867](https://github.com/shakacode/react_on_rails/pull/867) by [justin808](https://github.com/justin808)

## [8.0.2] - 2017-06-04

#### Fixed

- Any failure in webpack to build test files quits tests.
- Fixed a Ruby 2.4 potential crash which could cause a crash due to pathname change in Ruby 2.4.
- CI Improvements:
  - Switched to yarn link and removed relative path install of react-on-rails
  - Removed testing of Turbolinks 2
  - All tests run against Rails 5.1.1
  - Fixed test failures against Ruby 2.4
- [#862](https://github.com/shakacode/react_on_rails/pull/862) by [justin808](https://github.com/justin808)

## [8.0.1] - 2017-05-30

#### Fixed

- Generator no longer modifies `assets.rb`. [#859](https://github.com/shakacode/react_on_rails/pull/859) by [justin808](https://github.com/justin808)

## [8.0.0] - 2017-05-29

- Generators and full support for [webpacker_lite](https://github.com/shakacode/webpacker_lite)
- No breaking changes to move to 8.0.0 other than the default for this setting changed to nil. If you depended on the default of this setting and are using the asset pipeline (and not webpacker_lite), then add this to your `config/initializers/react_on_rails.rb`:
  ```ruby
  symlink_non_digested_assets_regex: /\.(png|jpg|jpeg|gif|tiff|woff|ttf|eot|svg|map)/,
  ```
- For an example of migration, see: [react-webpack-rails-tutorial PR #395](https://github.com/shakacode/react-webpack-rails-tutorial/pull/395)
- For a simple example of the webpacker_lite setup, run the basic generator.

### 8.0.0-beta.3 - 2017-05-27

#### Changed

- Major updates for WebpackerLite 2.0.2. [#844](https://github.com/shakacode/react_on_rails/pull/845) by [justin808](https://github.com/justin808) with help from [robwise](https://github.com/robwise)
- Logging no longer occurs when trace is turned to false. [#845](https://github.com/shakacode/react_on_rails/pull/845) by [conturbo](https://github.com/Conturbo)

### 8.0.0-beta.2 - 2017-05-08

#### Changed

Removed unnecessary values in default paths.yml files for generators. [#834](https://github.com/shakacode/react_on_rails/pull/834) by [justin808](https://github.com/justin808).

### 8.0.0-beta.1 - 2017-05-03

#### Added

Support for WebpackerLite in the generators. [#822](https://github.com/shakacode/react_on_rails/pull/822) by [kaizencodes](https://github.com/kaizencodes) and [justin808](https://github.com/justin808).

#### Changed

Breaking change is that the default value of symlink_non_digested_assets_regex has changed from this
old value to nil. This is a breaking change if you didn't have this value set in your
config/initializers/react_on_rails.rb file and you need this because you're using webpack's CSS
features and you have not switched to webpacker lite.

```ruby
symlink_non_digested_assets_regex: /\.(png|jpg|jpeg|gif|tiff|woff|ttf|eot|svg|map)/,
```

## [7.0.4] - 2017-04-27

- Return empty json when nil in json_safe_and_pretty [#824](https://github.com/shakacode/react_on_rails/pull/824) by [dzirtusss](https://github.com/dzirtusss)

## [7.0.3] - 2017-04-27

Same as 7.0.1.

## 7.0.2 - 2017-04-27

_Accidental release of beta gem here_

## [7.0.1] - 2017-04-27

#### Fixed

- Fix to handle nil values in json_safe_and_pretty [#823](https://github.com/shakacode/react_on_rails/pull/823) by [dzirtusss](https://github.com/dzirtusss)

## [7.0.0] - 2017-04-25

#### Changed

- Any version differences in gem and node package for React on Rails throw an error [#821](https://github.com/shakacode/react_on_rails/pull/821) by [justin808](https://github.com/justin808)

#### Fixed

- Fixes serious performance regression when using String props for rendering. [#821](https://github.com/shakacode/react_on_rails/pull/821) by [justin808](https://github.com/justin808)

## [6.10.1] - 2017-04-23

#### Fixed

- Improve json conversion with tests and support for older Rails 3.x. [#787](https://github.com/shakacode/react_on_rails/pull/787) by [cheremukhin23](https://github.com/cheremukhin23) and [Ynote](https://github.com/Ynote).

## [6.10.0] - 2017-04-13

#### Added

- Add an ability to return multiple HTML strings in a `Hash` as a result of `react_component` method call. Allows to build `<head>` contents with [React Helmet](https://github.com/nfl/react-helmet). [#800](https://github.com/shakacode/react_on_rails/pull/800) by [udovenko](https://github.com/udovenko).

#### Fixed

- Fix PropTypes, createClass deprecation warnings for React 15.5.x. [#804](https://github.com/shakacode/react_on_rails/pull/804) by [udovenko ](https://github.com/udovenko).

## [6.9.3] - 2017-04-03

#### Fixed

- Removed call of to_json on strings when formatting props. [#791](https://github.com/shakacode/react_on_rails/pull/791) by [justin808](https://github.com/justin808).

## [6.9.2] - 2017-04-02

#### Changed

- Update version_checker.rb to `logger.error` rather than `logger.warn` for gem/npm version mismatch. [#788](https://github.com/shakacode/react_on_rails/issues/788) by [justin808](https://github.com/justin808).

#### Fixed

- Remove pretty formatting of JSON in development. [#789](https://github.com/shakacode/react_on_rails/pull/789) by [justin808](https://github.com/justin808)
- Clear hydrated stores with each server rendered block. [#785](https://github.com/shakacode/react_on_rails/pull/785) by [udovenko](https://github.com/udovenko)

## [6.9.1] - 2017-03-30

#### Fixed

- Fixes Crash in Development for String Props. [#784](https://github.com/shakacode/react_on_rails/issues/784) by [justin808](https://github.com/justin808).

## [6.9.0] - 2017-03-29

#### Fixed

- Fixed error in the release script. [#767](https://github.com/shakacode/react_on_rails/issues/767) by [isolo](https://github.com/isolo).

#### Changed

- Use <script type="application/json"> for props and store instead of hidden div. [#775] (https://github.com/shakacode/react_on_rails/pull/775) by [cheremukhin23](https://github.com/cheremukhin23).

#### Added

- Add option to specify i18n_yml_dir in order to include only subset of locale files when generating translations.js & default.js for react-intl.
  [#777](https://github.com/shakacode/react_on_rails/pull/777) by [danijel](https://github.com/danijel).

## [6.8.2] - 2017-03-24

#### Fixed

- Change webpack output path to absolute and update webpack to version ^2.3.1. [#771](https://github.com/shakacode/react_on_rails/pull/771) by [cheremukhin23](https://github.com/cheremukhin23).

## [6.8.1] - 2017-03-21

#### Fixed

- Fixed error "The node you're attempting to unmount was rendered by another copy of React." [#706](https://github.com/shakacode/react_on_rails/issues/706) when navigating to cached page using Turbolinks [#763](https://github.com/shakacode/react_on_rails/pull/763) by [szyablitsky](https://github.com/szyablitsky).

## [6.8.0] - 2017-03-06

## Added

- Converted to Webpack v2 for generators, tests, and all example code. [#742](https://github.com/shakacode/react_on_rails/pull/742) by [justin808](https://github.com/justin808).

## [6.7.2] - 2017-03-05

#### Improved

- Improve i18n Integration with a better error message if the value of the i18n directory is invalid. [#748](https://github.com/shakacode/react_on_rails/pull/748) by [justin808](https://github.com/justin808).

## [6.7.1] - 2017-02-28

No changes other than a test fix.

## [6.7.0] - 2017-02-28

#### IMPORTANT

- If you installed 6.6.0, you will need to comment out the line matching i18n_dir unless you are using this feature. 6.7.1 will give you an error like:

```text
Errno::ENOENT: No such file or directory @ rb_sysopen - /tmp/build_1444a5bb9dd16ddb2561c7aff40f0fc7/my-app-816d31e9896edd90cecf1402acd002c724269333/client/app/libs/i18n/translations.js
```

Commenting out this line addresses the issue:

```ruby
config.i18n_dir = Rails.root.join("client", "app", "libs", "i18n")
```

#### Added

- Allow using rake task to generate javascript locale files. The test helper automatically creates the localization files when needed. [#717](https://github.com/shakacode/react_on_rails/pull/717) by [JasonYCHuang](https://github.com/JasonYCHuang).

#### Fixed

- Upgrade Rails to 4.2.8 to fix security vulnerabilities in 4.2.5. [#735](https://github.com/shakacode/react_on_rails/pull/735) by [hrishimittal](https://github.com/hrishimittal).
- Fix spec failing due to duplicate component. [#734](https://github.com/shakacode/react_on_rails/pull/734) by [hrishimittal](https://github.com/hrishimittal).

## [6.6.0] - 2017-02-18

#### Added

- Switched to yarn! [#715](https://github.com/shakacode/react_on_rails/pull/715) by [squadette](https://github.com/squadette).

## [6.5.1] - 2017-02-11

#### Fixed

- Allow using gem without sprockets. [#671](https://github.com/shakacode/react_on_rails/pull/671) by [fc-arny](https://github.com/fc-arny).
- Fixed issue [#706](https://github.com/shakacode/react_on_rails/issues/706) with "flickering" components when they are unmounted too early [#709](https://github.com/shakacode/react_on_rails/pull/709) by [szyablitsky](https://github.com/szyablitsky).
- Small formatting fix for errors [#703](https://github.com/shakacode/react_on_rails/pull/703) by [justin808](https://github.com/justin808).

## [6.5.0] - 2017-01-31

#### Added

- Allow generator function to return Object with property `renderedHtml` (already could return Object with props `redirectLocation, error`) rather than a React component or a function that returns a React component. One reason to use a generator function is that sometimes in server rendering, specifically with React Router v4, you need to return the result of calling ReactDOMServer.renderToString(element). [#689](https://github.com/shakacode/react_on_rails/issues/689) by [justin808](https://github.com/justin808).

#### Fixed

- Fix incorrect "this" references of Node.js SSR [#690](https://github.com/shakacode/react_on_rails/issues/689) by [nostophilia](https://github.com/nostophilia).

## [6.4.2] - 2017-01-17

#### Fixed

- Added OS detection for install generator, system call for Windows and unit-tests for it. [#666](https://github.com/shakacode/react_on_rails/pull/666) by [GeorgeGorbanev](https://github.com/GeorgeGorbanev).

## [6.4.1] - 2017-1-17

No changes.

## [6.4.0] - 2017-1-12

#### Possible Breaking Change

- Since foreman is no longer a dependency of the React on Rails gem, please run `gem install foreman`. If you are using rvm, you may wish to run `rvm @global do gem install foreman` to install foreman for all your gemsets.

#### Fixed

- Removed foreman as a dependency. [#678](https://github.com/shakacode/react_on_rails/pull/678) by [x2es](https://github.com/x2es).

#### Added

- Automatically generate **i18n** javascript files for `react-intl` when the serve starts up. [#642](https://github.com/shakacode/react_on_rails/pull/642) by [JasonYCHuang](https://github.com/JasonYCHuang).

## [6.3.5] - 2017-1-6

#### Fixed

- The Redux generator now creates a HelloWorld component that uses redux rather than local state. [#669](https://github.com/shakacode/react_on_rails/issues/669) by [justin808](https://github.com/justin808).

## [6.3.4] - 2016-12-25

##### Fixed

- Disable Turbolinks support when not supported. [#650](https://github.com/shakacode/react_on_rails/pull/650) by [ka2n](https://github.com/ka2n).

## [6.3.3] - 2016-12-25

##### Fixed

- By using the hook on `turbolinks:before-visit` to unmount the components, we can ensure that components are unmounted even when Turbolinks cache is disabled. Previously, we used `turbolinks:before-cache` event hook. [#644](https://github.com/shakacode/react_on_rails/pull/644) by [volkanunsal](https://github.com/volkanunsal).
- Added support for Ruby 2.0 [#651](https://github.com/shakacode/react_on_rails/pull/651) by [bbonamin](https://github.com/bbonamin).

## [6.3.2] - 2016-12-5

##### Fixed

- The `react_component` method was raising a `NameError` when `ReactOnRailsHelper` was included in a plain object. [#636](https://github.com/shakacode/react_on_rails/pull/636) by [jtibbertsma](https://github.com/jtibbertsma).
- "Node parse error" for node server rendering. [#641](https://github.com/shakacode/react_on_rails/pull/641) by [alleycat-at-git](https://github.com/alleycat-at-git) and [rocLv](https://github.com/rocLv)
- Better error handling when the react-on-rails node package entry is missing.[#602](https://github.com/shakacode/react_on_rails/pull/602) by [benjiwheeler](https://github.com/benjiwheeler).

## [6.3.1] - 2016-11-30

##### Changed

- Improved generator post-install help messages. [#631](https://github.com/shakacode/react_on_rails/pull/631) by [justin808](https://github.com/justin808).

## [6.3.0] - 2016-11-30

##### Changed

- Modified register API to allow registration of renderers, allowing a user to manually render their app to the DOM. This allows for code splitting and deferred loading. [#581](https://github.com/shakacode/react_on_rails/pull/581) by [jtibbertsma](https://github.com/jtibbertsma).

- Updated Basic Generator & Linters. Examples are simpler. [#624](https://github.com/shakacode/react_on_rails/pull/624) by [Judahmeek](https://github.com/Judahmeek).

- Slight improvement to the 'no hydrated stores' error. [#605](https://github.com/shakacode/react_on_rails/pull/605) by [cookiefission](https://github.com/cookiefission).

- Don't assume ActionMailer is available. [#608](https://github.com/shakacode/react_on_rails/pull/608) by [tuzz](https://github.com/tuzz).

## [6.2.1] - 2016-11-19

- Removed unnecessary passing of context in the HelloWorld Container example and basic generator. [#612](https://github.com/shakacode/react_on_rails/pull/612) by [justin808](https://github.com/justin808)

- Turbolinks 5 bugfix to use `before-cache`, not `before-render`. [#611](https://github.com/shakacode/react_on_rails/pull/611) by [volkanunsal](https://github.com/volkanunsal).

## [6.2.0] - 2016-11-19

##### Changed

- Updated the generator templates to reflect current best practices, especially for the Redux version. [#584](https://github.com/shakacode/react_on_rails/pull/584) by [nostophilia](https://github.com/nostophilia).

## [6.1.2] - 2016-10-24

##### Fixed

- Added compatibility with older manifest.yml files produced by Rails 3 Sprockets when symlinking digested assets during precompilation [#566](https://github.com/shakacode/react_on_rails/pull/566) by [etripier](https://github.com/etripier).

## [6.1.1] - 2016-09-09

##### Fixed

- React on Rails was incorrectly failing to create symlinks when a file existed in the location for the new symlink. [#491](https://github.com/shakacode/react_on_rails/pull/541) by [robwise ](https://github.com/robwise) and [justin808](https://github.com/justin808).

## [6.1.0] - 2016-08-21

##### Added

- Node option for installer added as alternative for server rendering [#469](https://github.com/shakacode/react_on_rails/pull/469) by [jbhatab](https://github.com/jbhatab).
- Server rendering now supports contexts outside of browser rendering, such as ActionMailer templates [#486](https://github.com/shakacode/react_on_rails/pull/486) by [eacaps](https://github.com/eacaps).
- Added authenticityToken() and authenticityHeaders() javascript helpers for easier use when working with CSRF protection tag generated by Rails [#517](https://github.com/shakacode/react_on_rails/pull/517) by [dzirtusss](https://github.com/dzirtusss).
- Updated JavaScript error handling on the client side. Errors in client rendering now pass through to the browser [#521](https://github.com/shakacode/react_on_rails/pull/521) by [dzirtusss](https://github.com/dzirtusss).

##### Fixed

- React on Rails now correctly parses single-digit version strings from package.json [#491](https://github.com/shakacode/react_on_rails/pull/491) by [samphilipd ](https://github.com/samphilipd).
- Fixed assets symlinking to correctly use filenames with spaces. Beginning in [#510](https://github.com/shakacode/react_on_rails/pull/510), ending in [#513](https://github.com/shakacode/react_on_rails/pull/513) by [dzirtusss](https://github.com/dzirtusss).
- Check encoding of request's original URL and force it to UTF-8 [#527](https://github.com/shakacode/react_on_rails/pull/527) by [lucke84](https://github.com/lucke84)

## [6.0.5] - 2016-07-11

##### Added

- Added better error messages to avoid issues with shared Redux stores [#470](https://github.com/shakacode/react_on_rails/pull/470) by [justin808](https://github.com/justin808).

## [6.0.4] - 2016-06-13

##### Fixed

- Added a polyfill for `clearTimeout` which is used by `babel-polyfill` [#451](https://github.com/shakacode/react_on_rails/pull/451) by [martyphee](https://github.com/martyphee)

## [6.0.3] - 2016-06-07

##### Fixed

- Added assets symlinking support on Heroku [#446](https://github.com/shakacode/react_on_rails/pull/446) by [Alexey Karasev](https://github.com/alleycat-at-git).

## [6.0.2] - 2016-06-06

##### Fixed

- Fix collisions in ids of DOM nodes generated by `react_component` by indexing in using a UUID rather than an auto-increment value. This means that it should be overridden using the `id` parameter of `react_component` if one wants to generate a predictable id (_e.g._ for testing purpose). See [Issue #437](https://github.com/shakacode/react_on_rails/issues/437). Fixed in [#438](https://github.com/shakacode/react_on_rails/pull/438) by [Michael Baudino](https://github.com/michaelbaudino).

## [6.0.1] - 2016-05-27

##### Fixed

- Allow for older version of manifest.json for older versions of sprockets. See [Issue #435](https://github.com/shakacode/react_on_rails/issues/435). Fixed in [#436](https://github.com/shakacode/react_on_rails/pull/436) by [alleycat-at-git](https://github.com/alleycat-at-git).

## [6.0.0] - 2016-05-25

##### Breaking Changes

- Added automatic compilation of assets at precompile is now done by ReactOnRails. Thus, you don't need to provide your own `assets.rake` file that does the precompilation.
  [#398](https://github.com/shakacode/react_on_rails/pull/398) by [robwise](https://github.com/robwise), [jbhatab](https://github.com/jbhatab), and [justin808](https://github.com/justin808).
- **Migration to v6**
  - Do not run the generator again if you've already run it.

  - See [shakacode/react-webpack-rails-tutorial/pull/287](https://github.com/shakacode/react-webpack-rails-tutorial/pull/287) for an example of upgrading from v5.

  - To configure the asset compilation you can either
    1. Specify a `config/react_on_rails` setting for `build_production_command` to be nil to turn this feature off.
    2. Specify the script command you want to run to build your production assets, and remove your `assets.rake` file.

  - If you are using the ReactOnRails test helper, then you will need to add the 'config.npm_build_test_command' to your config to tell react_on_rails what command to run when you run rspec.

- See [shakacode/react-webpack-rails-tutorial #287](https://github.com/shakacode/react-webpack-rails-tutorial/pull/287/files) for an upgrade example. The PR has a few comments on the upgrade.

Here is the addition to the generated config file:

```ruby
  # This configures the script to run to build the production assets by webpack. Set this to nil
  # if you don't want react_on_rails building this file for you.
  config.build_production_command = "npm run build:production"

  # If you are using the ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
  # with rspec then this controls what npm command is run
  # to automatically refresh your webpack assets on every test run.
  config.npm_build_test_command = "npm run build:test"
```

##### Fixed

- Fixed errors when server rendered props contain \u2028 or \u2029 characters [#375](https://github.com/shakacode/react_on_rails/pull/375) by [mariusandra](https://github.com/mariusandra)
- Fixed "too early unmount" which caused problems with Turbolinks 5 not updating the screen [#425](https://github.com/shakacode/react_on_rails/pull/425) by [szyablitsky](https://github.com/szyablitsky)

##### Added

- Experimental ability to use node.js process for server rendering. See [#380](https://github.com/shakacode/react_on_rails/pull/380) by [alleycat-at-git](https://github.com/alleycat-at-git).
- Non-digested version of assets in public folder [#413](https://github.com/shakacode/react_on_rails/pull/413) by [alleycat-at-git](https://github.com/alleycat-at-git).
- Cache client/node_modules directory to prevent Heroku from reinstalling all modules from scratch [#324](https://github.com/shakacode/react_on_rails/pull/324) by [modosc](https://github.com/modosc).
- ReactOnRails.reactOnRailsPageLoaded() is exposed in case one needs to call this manually and information on async script loading added. See [#315](https://github.com/shakacode/react_on_rails/pull/315) by [SqueezedLight](https://github.com/SqueezedLight).

##### Changed

- [#398](https://github.com/shakacode/react_on_rails/pull/398) by [robwise](https://github.com/robwise), [jbhatab](https://github.com/jbhatab), and [justin808](https://github.com/justin808) contains:
  - Only one webpack config is generated for server and client config. Package.json files were changed to reflect this.
  - Added npm_build_test_command to allow developers to change what npm command is automatically run from rspec.
- Replace URI with Addressable gem. See [#405](https://github.com/shakacode/react_on_rails/pull/405) by [lucke84](https://github.com/lucke84)

##### Removed

- [#398](https://github.com/shakacode/react_on_rails/pull/398) by [robwise](https://github.com/robwise), [jbhatab](https://github.com/jbhatab), and [justin808](https://github.com/justin808) contains:
  - Server rendering is no longer an option in the generator and is always accessible.
  - Removed lodash, jquery, and loggerMiddleware from the generated code.
  - Removed webpack watch check for test helper automatic compilation.

## [5.2.0] - 2016-04-08

##### Added

- Support for React 15.0 to react_on_rails. See [#379](https://github.com/shakacode/react_on_rails/pull/379) by [brucek](https://github.com/brucek).
- Support for Node.js server side rendering. See [#380](https://github.com/shakacode/react_on_rails/pull/380) by [alleycat](https://github.com/alleycat-at-git) and [doc](https://reactonrails.com/docs/pro#pro-integration-with-nodejs-for-server-rendering)

##### Removed

- Generator removals to simplify installer. See [#364](https://github.com/shakacode/react_on_rails/pull/364) by [jbhatab](https://github.com/jbhatab).
  - Removed options for heroku, boostrap, and the linters from generator.
  - Removed install for the Webpack Dev Server, as we can now do hot reloading with Rails, so the complexity of this feature is not justified. Nevertheless, the setup of React on Rails still supports this setup, just not with the generator.
  - Documentation added for removed installer options.

## [5.1.1] - 2016-04-04

##### Fixed

- Security Fixes: Address failure to sanitize console messages when server rendering and displaying in the browser console. See [#366](https://github.com/shakacode/react_on_rails/pull/366) and [#370](https://github.com/shakacode/react_on_rails/pull/370) by [justin808](https://github.com/justin808)

##### Added

- railsContext includes the port number and a boolean if the code is being run on the server or client.

## [5.1.0] - 2016-04-03

##### Added

All 5.1.0 changes can be found in [#362](https://github.com/shakacode/react_on_rails/pull/362) by [justin808](https://github.com/justin808).

- Generator enhancements
  - Generator adds line to spec/rails_helper.rb so that running specs will ensure assets are compiled.
  - Other small changes to the generator including adding necessary npm scripts to allow React on Rails to build assets.
  - Npm modules updated for generator.
  - Added babel-runtime in to the client/package.json created.
- Server rendering
  - Added more diagnostics for server rendering.
  - Calls to setTimeout and setInterval are not logged for server rendering unless env TRACE_REACT_ON_RAILS is set to YES.
- Updated all project npm dependencies to latest.
- Update to node 5.10.0 for CI.
- Added babel-runtime as a peer dependency for the npm module.

## [5.0.0] - 2016-04-01

##### Added

- Added `railsContext`, an object which gets passed always as the second parameter to both React component and Redux store generator functions, both for server and client rendering. This provides data like the current locale, the pathname, etc. The data values are customizable by a new configuration called `rendering_extension` where you can create a module with a method called `rendering_extension`. This allows you to add additional values to the Rails Context. Implement one static method called `custom_context(view_context)` and return a Hash. See [#345](https://github.com/shakacode/react_on_rails/pull/345) by [justin808](https://github.com/justin808)

##### Changed

- Previously, you could pass arbitrary additional HTML attributes to react_component. Now, you need to pass them in as a named parameter `html_options` to react_component.

##### Breaking Changes

- You must provide named attributes, including `props` for view helper `react_component`. See [this commit](https://github.com/shakacode/react-webpack-rails-tutorial/commit/a97fa90042cbe27be7fd7fa70b5622bfcf9c3673) for an example migration used for [reactrails.com](https://reactrails.com).

## [4.0.3] - 2016-03-17

##### Fixed

- `ReactOnRailsHelper#react_component`: Invalid deprecation message when called with only one parameter, the component name.

## [4.0.2] - 2016-03-17

##### Fixed

- `ReactOnRails::Controller#redux_store`: 2nd parameter changed to a named parameter `props` for consistency.

## [4.0.1] - 2016-03-16

##### Fixed

- Switched to `heroku buildpacks:set` syntax rather than using a `.buildpacks` file, which is deprecated. See [#319](https://github.com/shakacode/react_on_rails/pull/319) by [esauter5](https://github.com/esauter5). Includes both generator and doc updates.

## [4.0.0] - 2016-03-14

##### Added

- [react_on_rails/spec/dummy](react_on_rails/spec/dummy) is a full sample app of React on Rails techniques **including** the hot reloading of assets from Rails!
- Added helpers `env_stylesheet_link_tag` and `env_javascript_include_tag` to support hot reloading Rails. See the [README.md](./README.md) for more details and see the example application in `spec/dummy`. Also see how this is used in the [tutorial: application.html.erb](https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/app%2Fviews%2Flayouts%2Fapplication.html.erb#L6)
- Added optional parameter for ReactOnRails.getStore(name, throwIfMissing = true) so that you can check if a store is defined easily.
- Added controller `module ReactOnRails::Controller`. Adds method `redux_store` to set up Redux stores in the view.
- Added option `defer: true` for view helper `redux_store`. This allows the view helper to specify the props for store hydration, yet still render the props at the bottom of the view.
- Added view helper `redux_store_hydration_data` to render the props on the application's layout, near the bottom. This allows for the client hydration data to be parsed after the server rendering, which may result in a faster load time.
- The checker for outdated bundles before running tests will two configuration options: `generated_assets_dir` and `webpack_generated_files`.
- Better support for Turbolinks 5!
- Fixed generator check of uncommitted code for foreign languages. See [#303](https://github.com/shakacode/react_on_rails/pull/303) by [nmatyukov](https://github.com/nmatyukov).
- Added several parameters used for ensuring webpack assets are built for running tests:
  - `config.generated_assets_dir`: Directory where your generated webpack assets go. You can have only **one** directory for this.
  - `config.webpack_generated_files`: List of files that will get created in the `generated_assets_dir`. The test runner helper will ensure these generated files are newer than any of the files in the client directory.

##### Changed

- Generator default for webpack generated assets is now `app/assets/webpack` as we use this for both JavaScript and CSS generated assets.

##### Fixed

- The test runner "assets up to date checker" is greatly improved.
- Lots of doc updates!
- Improved the **spec/dummy** sample app so that it supports CSS modules, hot reloading, etc, and it can server as a template for a new ReactOnRails installation.

##### Breaking Changes

- Deprecated calling `redux_store(store_name, props)`. The API has changed. Use `redux_store(store_name, props: props, defer: false)` A new option called `defer` allows the rendering of store hydration at the bottom of the your layout. Place `redux_store_hydration_data` on your layout.
- `config.server_bundle_js_file` has changed. The default value is now blank, meaning no server rendering. Addtionally, if you specify the file name, you should not include the path, as that should be specified in the `config.generated_assets_dir`.
- `config.generated_assets_dirs` has been renamed to `config.generated_assets_dir` (singular) and it only takes one directory.

## [3.0.6] - 2016-03-01

##### Fixed

- Improved errors when registered store is not found. See [#301](https://github.com/shakacode/react_on_rails/pull/301) by [justin808](https://github.com/justin808).

## [3.0.5] - 2016-02-26

##### Fixed

- Fixed error in linters rake file for generator. See [#299](https://github.com/shakacode/react_on_rails/pull/299) by [mpugach](https://github.com/mpugach).

## [3.0.4] - 2016-02-25

##### Fixed

- Updated CHANGELOG.md to include contributors for each PR.
- Fixed config.server_bundle_js file value in generator to match generator setting of server rendering. See [#295](https://github.com/shakacode/react_on_rails/pull/295) by [aaronvb](https://github.com/aaronvb).

## [3.0.3] - 2016-02-21

##### Fixed

- Cleaned up code in `spec/dummy` to latest React and Redux APIs. See [#282](https://github.com/shakacode/react_on_rails/pull/282).
- Update generator messages with helpful information. See [#279](https://github.com/shakacode/react_on_rails/pull/279).
- Other small generated comment fixes and doc fixes.

## [3.0.2] - 2016-02-15

##### Fixed

- Fixed missing information in the helpful message after running the base install generator regarding how to run the node server with hot reloading support.

## [3.0.1] - 2016-02-15

##### Fixed

- Fixed several jscs linter issues.

## [3.0.0] - 2016-02-15

##### Fixed

- Fix Bootstrap Sass Append to Gemfile, missing new line. [#262](https://github.com/shakacode/react_on_rails/pull/262).

##### Added

- Added helper `redux_store` and associated JavaScript APIs that allow multiple React components to use the same store. Thus, you initialize the store, with props, separately from the components.
- Added forman to gemspec in case new dev does not have it globally installed. [#248](https://github.com/shakacode/react_on_rails/pull/248).
- Support for Turbolinks 5! [#270](https://github.com/shakacode/react_on_rails/pull/270).
- Added better error messages for `ReactOnRails.register()`. [#273](https://github.com/shakacode/react_on_rails/pull/273).

##### Breaking Change

- Calls to `react_component` should use a named argument of props. For example, change this:

  ```ruby
  <%= react_component("ReduxSharedStoreApp", {}, prerender: false, trace: true) %>
  ```

  to

  ```ruby
  <%= react_component("ReduxSharedStoreApp", props: {}, prerender: false, trace: true) %>
  ```

  You'll get a deprecation message to change this.

- Renamed `ReactOnRails.configure_rspec_to_compile_assets` to `ReactOnRails::TestHelper.configure_rspec_to_compile_assets`. The code has also been optimized to check for whether or not the compiled webpack bundles are up to date or not and will not run if not necessary. If you are using non-standard directories for your generated webpack assets (`app/assets/javascripts/generated` and `app/assets/stylesheets/generated`) or have additional directories you wish the helper to check, you need to update your ReactOnRails configuration accordingly. See [documentation](https://reactonrails.com/docs/building-features/testing-configuration) for how to do this. [#253](https://github.com/shakacode/react_on_rails/pull/253).
- You have to call `ReactOnRails.register` to register React components. This was deprecated in v2. [#273](https://github.com/shakacode/react_on_rails/pull/273).

##### Migration Steps v2 to v3

- See [these changes of spec/dummy/spec/rails_helper.rb](https://github.com/shakacode/react_on_rails/blob/master/react_on_rails/spec/dummy/spec/rails_helper.rb#L36..38) for an example. Add this line to your `rails_helper.rb`:

```ruby
RSpec.configure do |config|
  # Ensure that if we are running js tests, we are using latest webpack assets
  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
```

- Change view helper calls to react_component to use the named param of `props`. See forum post [Using Regexp to update to ReactOnRails v3](http://forum.shakacode.com/t/using-regexp-to-update-to-reactonrails-v3/481).

## [2.3.0] - 2016-02-01

##### Added

- Added polyfills for `setInterval` and `setTimeout` in case other libraries expect these to exist.
- Added much improved debugging for errors in the server JavaScript webpack file.
- See [#244](https://github.com/shakacode/react_on_rails/pull/244/) for these improvements.

## [2.2.0] - 2016-01-29

##### Added

- New JavaScript API for debugging TurboLinks issues. Be sure to see [turbolinks docs](https://reactonrails.com/docs/building-features/turbolinks). `ReactOnRails.setOptions({ traceTurbolinks: true });`. Removed the file `debug_turbolinks` added in 2.1.1. See [#243](https://github.com/shakacode/react_on_rails/pull/243).

## [2.1.1] - 2016-01-28

##### Fixed

- Fixed regression where apps that were not using Turbolinks would not render components on page load.

##### Added

- `ReactOnRails.render` returns a virtualDomElement Reference to your React component's backing instance. See [#234](https://github.com/shakacode/react_on_rails/pull/234).
- `debug_turbolinks` helper for debugging turbolinks issues. See [turbolinks](https://reactonrails.com/docs/building-features/turbolinks).
- Enhanced regression testing for non-turbolinks apps. Runs all tests for dummy app with turbolinks both disabled and enabled.

## [2.1.0] - 2016-01-26

##### Added

- Added EnsureAssetsCompiled feature so that you do not accidentally run tests without properly compiling the JavaScript bundles. Add a line to your `rails_helper.rb` file to check that the latest Webpack bundles have been generated prior to running tests that may depend on your client-side code. See [docs](https://reactonrails.com/docs/building-features/testing-configuration) for more detailed instructions. [#222](https://github.com/shakacode/react_on_rails/pull/222)
- Added [migration guide](https://reactonrails.com/docs/migrating/migrating-from-react-rails) for migrating from React-Rails. [#219](https://github.com/shakacode/react_on_rails/pull/219)
- Added [React on Rails Doctrine](https://reactonrails.com/docs/misc/doctrine) to docs. Discusses the project's motivations, conventions, and principles. [#220](https://github.com/shakacode/react_on_rails/pull/220)
- Added ability to skip `display:none` style in the generated content tag for a component. Some developers may want to disable inline styles for security reasons. See the `skip_display_none` configuration option. [#218](https://github.com/shakacode/react_on_rails/pull/218)

##### Changed

- Changed message when running the dev (a.k.a. "express" server). [#227](https://github.com/shakacode/react_on_rails/commit/543ae70254d0c7b477e2c92af86f40746e58a431)

##### Fixed

- Fixed handling of Turbolinks. Code was checking that Turbolinks was installed when it was not yet because some setups load Turbolinks after the bundles. The changes to the code will check if Turbolinks is installed after the page loaded event fires. Code was also added to allow easy debugging of Turbolinks, which should be useful when v5 of Turbolinks is released shortly. Details of how to configure Turbolinks with troubleshooting were added to `docs` directory. [#221](https://github.com/shakacode/react_on_rails/pull/221)
- Fixed issue with already initialized constant warning appearing when starting a Rails server [#226](https://github.com/shakacode/react_on_rails/pull/226)
- Fixed to make backwards compatible with Ruby v2.0 and updated all Ruby and Node dependencies.

---

## [2.0.2]

- Added better messages after generator runs. [#210](https://github.com/shakacode/react_on_rails/pull/210)

## [2.0.1]

- Fixed bug with version matching between gem and npm package.

## [2.0.0]

- Move JavaScript part of react_on_rails to npm package 'react-on-rails'.
- Converted JavaScript code to ES6! with tests!
- No global namespace pollution. ReactOnRails is the only global added.
- New API. Instead of placing React components on the global namespace, you instead call ReactOnRails.register, passing an object where keys are the names of your components:

<!-- prettier-ignore-start -->

```javascript
import ReactOnRails from 'react-on-rails';
ReactOnRails.register({name: component});
```

Best done with Object destructing:

```javascript
  import ReactOnRails from 'react-on-rails';
  ReactOnRails.register(
    {
      Component1,
      Component2
    }
  );
```

Previously, you used

```javascript
window.Component1 = Component1;
window.Component2 = Component2;
```

This would pollute the global namespace. See details in the README.md for more information.

- Your jade template for the WebpackDevServer setup should use the new API:

```javascript
  ReactOnRails.render(componentName, props, domNodeId);
```

such as:

```javascript
  ReactOnRails.render("HelloWorldApp", {name: "Stranger"}, 'app');
```

<!-- prettier-ignore-end -->

- All npm dependency libraries updated. Most notable is going to Babel 6.
- Dropped support for React 0.13.
- JS Linter uses ShakaCode JavaScript style: https://github.com/shakacode/style-guide-javascript
- Generators account for these differences.

##### Migration Steps v1 to v2

[Example of upgrading](https://github.com/shakacode/react-webpack-rails-tutorial/commit/5b1b8698e8daf0f0b94e987740bc85ee237ef608)

1. Update the `react_on_rails` gem.
2. Remove `//= require react_on_rails` from any files such as `app/assets/javascripts/application.js`. This file comes from npm now.
3. Search you app for 'generator_function' and remove lines in layouts and rb files that contain it. Determination of a generator function is handled automatically.
4. Find your files where you registered client and server globals, and use the new ReactOnRails.register syntax. Optionally rename the files `clientRegistration.jsx` and `serverRegistration.jsx` rather than `Globals`.
5. Update your index.jade to use the new API `ReactOnRails.render("MyApp", !{props}, 'app');`
6. Update your webpack files per the example commit. Remove globally exposing React and ReactDom, as well as their inclusion in the `entry` section. These are automatically included now.
7. Run `cd client && npm i --save react-on-rails` to get react-on-rails into your `client/package.json`.
8. You should also update any other dependencies if possible to match up with the [react-webpack-rails-tutorial](https://github.com/shakacode/react-webpack-rails-tutorial/). This includes updating to Babel 6.
9. If you want to stick with Babel 5 for a bit, see [Issue #238](https://github.com/shakacode/react_on_rails/issues/238).

---

## [1.2.2]

##### Fixed

- Missing Lodash from generated package.json [#175](https://github.com/shakacode/react_on_rails/pull/175)
- Rails 3.2 could not run generators [#182](https://github.com/shakacode/react_on_rails/pull/182)
- Better placement of jquery_ujs dependency [commit b168abd5](https://github.com/shakacode/react_on_rails/commit/b168abd5a55221006b2520fc75b41ea775fcd1c5)
- Add more detailed description when adding --help option to generator [commit a9b7d47d](https://github.com/shakacode/react_on_rails/commit/a9b7d47d0829a0b6ec6c28bfbbbb589a4149296f)
- Lots of better docs.

## [1.2.0]

##### Added

- Support `--skip-bootstrap` or `-b` option for generator.
- Create examples tasks to test generated example apps.

##### Fixed

- Fix non-server rendering configuration issues.
- Fix application.js incorrect overwritten issue.
- Fix Gemfile dependencies.
- Fix several generator issues.

##### Removed

- Removed templates/client folder.

---

## [1.1.1] - 2015-11-28

##### Added

- Support for React Router.
- Error and redirect handling.
- Turbolinks support.

##### Fixed

- Fix several generator-related issues.

[unreleased]: https://github.com/shakacode/react_on_rails/compare/v17.0.0.rc.6...main
[17.0.0.rc.6]: https://github.com/shakacode/react_on_rails/compare/v17.0.0.rc.5...v17.0.0.rc.6
[17.0.0.rc.5]: https://github.com/shakacode/react_on_rails/compare/v17.0.0.rc.4...v17.0.0.rc.5
[17.0.0.rc.4]: https://github.com/shakacode/react_on_rails/compare/v17.0.0.rc.3...v17.0.0.rc.4
[17.0.0.rc.3]: https://github.com/shakacode/react_on_rails/compare/v17.0.0.rc.2...v17.0.0.rc.3
[17.0.0.rc.2]: https://github.com/shakacode/react_on_rails/compare/v17.0.0.rc.1...v17.0.0.rc.2
[17.0.0.rc.1]: https://github.com/shakacode/react_on_rails/compare/v17.0.0.rc.0...v17.0.0.rc.1
[17.0.0.rc.0]: https://github.com/shakacode/react_on_rails/compare/v16.6.0...v17.0.0.rc.0
[16.6.0]: https://github.com/shakacode/react_on_rails/compare/v16.5.1...v16.6.0
[16.5.1]: https://github.com/shakacode/react_on_rails/compare/v16.5.0...v16.5.1
[16.5.0]: https://github.com/shakacode/react_on_rails/compare/v16.4.0...v16.5.0
[16.4.0]: https://github.com/shakacode/react_on_rails/compare/v16.3.0...v16.4.0
[16.3.0]: https://github.com/shakacode/react_on_rails/compare/v16.2.1...v16.3.0
[16.2.1]: https://github.com/shakacode/react_on_rails/compare/v16.2.0...v16.2.1
[16.2.0]: https://github.com/shakacode/react_on_rails/compare/16.1.1...v16.2.0
[16.1.1]: https://github.com/shakacode/react_on_rails/compare/16.1.0...16.1.1
[16.1.0]: https://github.com/shakacode/react_on_rails/compare/16.0.0...16.1.0
[16.0.0]: https://github.com/shakacode/react_on_rails/compare/14.2.0...16.0.0
[14.2.0]: https://github.com/shakacode/react_on_rails/compare/14.1.1...14.2.0
[14.1.1]: https://github.com/shakacode/react_on_rails/compare/14.1.0...14.1.1
[14.1.0]: https://github.com/shakacode/react_on_rails/compare/14.0.5...14.1.0
[14.0.5]: https://github.com/shakacode/react_on_rails/compare/14.0.4...14.0.5
[14.0.4]: https://github.com/shakacode/react_on_rails/compare/14.0.3...14.0.4
[14.0.3]: https://github.com/shakacode/react_on_rails/compare/14.0.2...14.0.3
[14.0.2]: https://github.com/shakacode/react_on_rails/compare/14.0.1...14.0.2
[14.0.1]: https://github.com/shakacode/react_on_rails/compare/14.0.0...14.0.1
[14.0.0]: https://github.com/shakacode/react_on_rails/compare/13.4.0...14.0.0
[13.4.0]: https://github.com/shakacode/react_on_rails/compare/13.3.5...13.4.0
[13.3.5]: https://github.com/shakacode/react_on_rails/compare/13.3.4...13.3.5
[13.3.4]: https://github.com/shakacode/react_on_rails/compare/13.3.3...13.3.4
[13.3.3]: https://github.com/shakacode/react_on_rails/compare/13.3.2...13.3.3
[13.3.2]: https://github.com/shakacode/react_on_rails/compare/13.3.1...13.3.2
[13.3.1]: https://github.com/shakacode/react_on_rails/compare/13.3.0...13.3.1
[13.3.0]: https://github.com/shakacode/react_on_rails/compare/13.2.0...13.3.0
[13.2.0]: https://github.com/shakacode/react_on_rails/compare/13.1.0...13.2.0
[13.1.0]: https://github.com/shakacode/react_on_rails/compare/13.0.2...13.1.0
[13.0.2]: https://github.com/shakacode/react_on_rails/compare/13.0.1...13.0.2
[13.0.1]: https://github.com/shakacode/react_on_rails/compare/13.0.0...13.0.1
[13.0.0]: https://github.com/shakacode/react_on_rails/compare/12.6.0...13.0.0
[12.6.0]: https://github.com/shakacode/react_on_rails/compare/12.5.2...12.6.0
[12.5.2]: https://github.com/shakacode/react_on_rails/compare/12.5.1...12.5.2
[12.5.1]: https://github.com/shakacode/react_on_rails/compare/12.5.0...12.5.1
[12.5.0]: https://github.com/shakacode/react_on_rails/compare/12.4.0...12.5.0
[12.4.0]: https://github.com/shakacode/react_on_rails/compare/12.3.0...12.4.0
[12.3.0]: https://github.com/shakacode/react_on_rails/compare/12.2.0...12.3.0
[12.2.0]: https://github.com/shakacode/react_on_rails/compare/12.1.0...12.2.0
[12.1.0]: https://github.com/shakacode/react_on_rails/compare/12.0.4...12.1.0
[12.0.4]: https://github.com/shakacode/react_on_rails/compare/12.0.3...12.0.4
[12.0.3]: https://github.com/shakacode/react_on_rails/compare/12.0.2...12.0.3
[12.0.2]: https://github.com/shakacode/react_on_rails/compare/12.0.1...12.0.2
[12.0.1]: https://github.com/shakacode/react_on_rails/compare/12.0.0...12.0.1
[12.0.0]: https://github.com/shakacode/react_on_rails/compare/11.3.0...12.0.0
[11.3.0]: https://github.com/shakacode/react_on_rails/compare/11.2.2...11.3.0
[11.2.2]: https://github.com/shakacode/react_on_rails/compare/11.2.1...11.2.2
[11.2.1]: https://github.com/shakacode/react_on_rails/compare/11.1.8...11.2.1
[11.1.8]: https://github.com/shakacode/react_on_rails/compare/11.1.7...11.1.8
[11.1.7]: https://github.com/shakacode/react_on_rails/compare/11.1.6...11.1.7
[11.1.6]: https://github.com/shakacode/react_on_rails/compare/11.1.5...11.1.6
[11.1.5]: https://github.com/shakacode/react_on_rails/compare/11.1.4...11.1.5
[11.1.4]: https://github.com/shakacode/react_on_rails/compare/11.1.3...11.1.4
[11.1.3]: https://github.com/shakacode/react_on_rails/compare/11.1.2...11.1.3
[11.1.2]: https://github.com/shakacode/react_on_rails/compare/11.1.1...11.1.2
[11.1.1]: https://github.com/shakacode/react_on_rails/compare/11.1.0...11.1.1
[11.1.0]: https://github.com/shakacode/react_on_rails/compare/11.0.10...11.1.0
[11.0.10]: https://github.com/shakacode/react_on_rails/compare/11.0.9...11.0.10
[11.0.9]: https://github.com/shakacode/react_on_rails/compare/11.0.8...11.0.9
[11.0.8]: https://github.com/shakacode/react_on_rails/compare/11.0.7...11.0.8
[11.0.7]: https://github.com/shakacode/react_on_rails/compare/11.0.6...11.0.7
[11.0.6]: https://github.com/shakacode/react_on_rails/compare/11.0.5...11.0.6
[11.0.5]: https://github.com/shakacode/react_on_rails/compare/11.0.4...11.0.5
[11.0.4]: https://github.com/shakacode/react_on_rails/compare/11.0.3...11.0.4
[11.0.3]: https://github.com/shakacode/react_on_rails/compare/11.0.2...11.0.3
[11.0.2]: https://github.com/shakacode/react_on_rails/compare/11.0.1...11.0.2
[11.0.1]: https://github.com/shakacode/react_on_rails/compare/11.0.0...11.0.1
[11.0.0]: https://github.com/shakacode/react_on_rails/compare/10.1.4...11.0.0
[10.1.4]: https://github.com/shakacode/react_on_rails/compare/10.1.3...10.1.4
[10.1.3]: https://github.com/shakacode/react_on_rails/compare/10.1.2...10.1.3
[10.1.2]: https://github.com/shakacode/react_on_rails/compare/10.1.1...10.1.2
[10.1.1]: https://github.com/shakacode/react_on_rails/compare/10.1.0...10.1.1
[10.1.0]: https://github.com/shakacode/react_on_rails/compare/10.0.2...10.1.0
[10.0.2]: https://github.com/shakacode/react_on_rails/compare/10.0.1...10.0.2
[10.0.1]: https://github.com/shakacode/react_on_rails/compare/10.0.0...10.0.1
[10.0.0]: https://github.com/shakacode/react_on_rails/compare/9.0.3...10.0.0
[9.0.3]: https://github.com/shakacode/react_on_rails/compare/9.0.2...9.0.3
[9.0.2]: https://github.com/shakacode/react_on_rails/compare/9.0.1...9.0.2
[9.0.1]: https://github.com/shakacode/react_on_rails/compare/9.0.0...9.0.1
[9.0.0]: https://github.com/shakacode/react_on_rails/compare/8.0.7...9.0.0
[8.0.7]: https://github.com/shakacode/react_on_rails/compare/8.0.6...8.0.7
[8.0.6]: https://github.com/shakacode/react_on_rails/compare/8.0.5...8.0.6
[8.0.5]: https://github.com/shakacode/react_on_rails/compare/8.0.3...8.0.5
[8.0.3]: https://github.com/shakacode/react_on_rails/compare/8.0.2...8.0.3
[8.0.2]: https://github.com/shakacode/react_on_rails/compare/8.0.1...8.0.2
[8.0.1]: https://github.com/shakacode/react_on_rails/compare/8.0.0...8.0.1
[8.0.0]: https://github.com/shakacode/react_on_rails/compare/7.0.4...8.0.0
[7.0.4]: https://github.com/shakacode/react_on_rails/compare/7.0.3...7.0.4
[7.0.3]: https://github.com/shakacode/react_on_rails/compare/7.0.1...7.0.3
[7.0.1]: https://github.com/shakacode/react_on_rails/compare/7.0.0...7.0.1
[7.0.0]: https://github.com/shakacode/react_on_rails/compare/6.10.1...7.0.0
[6.10.1]: https://github.com/shakacode/react_on_rails/compare/6.10.0...6.10.1
[6.10.0]: https://github.com/shakacode/react_on_rails/compare/6.9.3...6.10.0
[6.9.3]: https://github.com/shakacode/react_on_rails/compare/6.9.1...6.9.3
[6.9.2]: https://github.com/shakacode/react_on_rails/compare/6.9.1...6.9.2
[6.9.1]: https://github.com/shakacode/react_on_rails/compare/6.8.2...6.9.1
[6.9.0]: https://github.com/shakacode/react_on_rails/compare/6.8.2...6.9.0
[6.8.2]: https://github.com/shakacode/react_on_rails/compare/6.8.1...6.8.2
[6.8.1]: https://github.com/shakacode/react_on_rails/compare/6.8.0...6.8.1
[6.8.0]: https://github.com/shakacode/react_on_rails/compare/6.7.2...6.8.0
[6.7.2]: https://github.com/shakacode/react_on_rails/compare/6.7.1...6.7.2
[6.7.1]: https://github.com/shakacode/react_on_rails/compare/6.7.0...6.7.1
[6.7.0]: https://github.com/shakacode/react_on_rails/compare/6.6.0...6.7.0
[6.6.0]: https://github.com/shakacode/react_on_rails/compare/6.5.1...6.6.0
[6.5.1]: https://github.com/shakacode/react_on_rails/compare/6.5.0...6.5.1
[6.5.0]: https://github.com/shakacode/react_on_rails/compare/6.4.2...6.5.0
[6.4.2]: https://github.com/shakacode/react_on_rails/compare/6.4.1...6.4.2
[6.4.1]: https://github.com/shakacode/react_on_rails/compare/6.4.0...6.4.1
[6.4.0]: https://github.com/shakacode/react_on_rails/compare/6.3.5...6.4.0
[6.3.5]: https://github.com/shakacode/react_on_rails/compare/6.3.4...6.3.5
[6.3.4]: https://github.com/shakacode/react_on_rails/compare/6.3.3...6.3.4
[6.3.3]: https://github.com/shakacode/react_on_rails/compare/6.3.2...6.3.3
[6.3.2]: https://github.com/shakacode/react_on_rails/compare/6.3.1...6.3.2
[6.3.1]: https://github.com/shakacode/react_on_rails/compare/6.3.0...6.3.1
[6.3.0]: https://github.com/shakacode/react_on_rails/compare/6.2.1...6.3.0
[6.2.1]: https://github.com/shakacode/react_on_rails/compare/6.2.0...6.2.1
[6.2.0]: https://github.com/shakacode/react_on_rails/compare/6.1.2...6.2.0
[6.1.2]: https://github.com/shakacode/react_on_rails/compare/6.1.1...6.1.2
[6.1.1]: https://github.com/shakacode/react_on_rails/compare/6.1.0...6.1.1
[6.1.0]: https://github.com/shakacode/react_on_rails/compare/6.0.5...6.1.0
[6.0.5]: https://github.com/shakacode/react_on_rails/compare/6.0.4...6.0.5
[6.0.4]: https://github.com/shakacode/react_on_rails/compare/6.0.3...6.0.4
[6.0.3]: https://github.com/shakacode/react_on_rails/compare/6.0.2...6.0.3
[6.0.2]: https://github.com/shakacode/react_on_rails/compare/6.0.1...6.0.2
[6.0.1]: https://github.com/shakacode/react_on_rails/compare/6.0.0...6.0.1
[6.0.0]: https://github.com/shakacode/react_on_rails/compare/5.2.0...6.0.0
[5.2.0]: https://github.com/shakacode/react_on_rails/compare/5.1.1...5.2.0
[5.1.1]: https://github.com/shakacode/react_on_rails/compare/5.1.0...5.1.1
[5.1.0]: https://github.com/shakacode/react_on_rails/compare/5.0.0...5.1.0
[5.0.0]: https://github.com/shakacode/react_on_rails/compare/4.0.3...5.0.0
[4.0.3]: https://github.com/shakacode/react_on_rails/compare/4.0.2...4.0.3
[4.0.2]: https://github.com/shakacode/react_on_rails/compare/4.0.1...4.0.2
[4.0.1]: https://github.com/shakacode/react_on_rails/compare/4.0.0...4.0.1
[4.0.0]: https://github.com/shakacode/react_on_rails/compare/3.0.6...4.0.0
[3.0.6]: https://github.com/shakacode/react_on_rails/compare/3.0.5...3.0.6
[3.0.5]: https://github.com/shakacode/react_on_rails/compare/3.0.4...3.0.5
[3.0.4]: https://github.com/shakacode/react_on_rails/compare/3.0.3...3.0.4
[3.0.3]: https://github.com/shakacode/react_on_rails/compare/3.0.2...3.0.3
[3.0.2]: https://github.com/shakacode/react_on_rails/compare/3.0.1...3.0.2
[3.0.1]: https://github.com/shakacode/react_on_rails/compare/3.0.0...3.0.1
[3.0.0]: https://github.com/shakacode/react_on_rails/compare/2.3.0...3.0.0
[2.3.0]: https://github.com/shakacode/react_on_rails/compare/2.2.0...2.3.0
[2.2.0]: https://github.com/shakacode/react_on_rails/compare/2.1.1...2.2.0
[2.1.1]: https://github.com/shakacode/react_on_rails/compare/v2.1.0...2.1.1
[2.1.0]: https://github.com/shakacode/react_on_rails/compare/v2.0.2...v2.1.0
[2.0.2]: https://github.com/shakacode/react_on_rails/compare/v2.0.1...v2.0.2
[2.0.1]: https://github.com/shakacode/react_on_rails/compare/2.0.0...v2.0.1
[2.0.0]: https://github.com/shakacode/react_on_rails/compare/v1.2.2...2.0.0
[1.2.2]: https://github.com/shakacode/react_on_rails/compare/v1.2.0...v1.2.2
[1.2.0]: https://github.com/shakacode/react_on_rails/compare/v1.1.0...v1.2.0
[1.1.1]: https://github.com/shakacode/react_on_rails/compare/v1.1.1...v1.0.0

# React 19.2.x and Partial Pre-Rendering Plan

## Purpose

Track the work needed for [Issue 2182](https://github.com/shakacode/react_on_rails/issues/2182): verify React 19.2.x
support and decide how React on Rails should expose any partial pre-rendering workflow that becomes practical for Rails
apps.

This is a planning document. It does not change package versions, build configuration, or Pro package code.

**Status**: Draft | **Created**: 2026-04-30 | **Last updated**: 2026-06-02 | **Tracks**:
[Issue 2182](https://github.com/shakacode/react_on_rails/issues/2182) and
[Issue 3255](https://github.com/shakacode/react_on_rails/issues/3255)

## Current Repository Signal

The workspace package ranges already allow React 19.2.x through `^19.0.3` for `react` and `react-dom`, plus `^19.0.4`
for `react-on-rails-rsc` (the React on Rails RSC integration package, not a React-team package), in the root, dummy app,
and Pro dummy app package manifests. To see what versions are currently resolved, run
`pnpm list -r --depth=0 react react-dom` and
`pnpm --filter react-on-rails-pro list --depth=0 react-on-rails-rsc` from the repo root. Note:
`react_on_rails_pro/spec/execjs-compatible-dummy` is intentionally pinned to React 18 through pnpm overrides for `app>react`
and `app>react-dom`; verification should
confirm whether that workspace stays on React 18 during this work. That means the first implementation step is
verification, not necessarily a broad package-range change.

Note: `packages/react-on-rails-pro/package.json` already sets the `react-on-rails-rsc` peer dependency ceiling to
`>= 19.0.2 <= 19.2.3` (space means AND; both comparators must be satisfied). These 19.x version numbers apply to the
`react-on-rails-rsc` package, not to React itself: `react-on-rails-rsc`'s major and minor numbers track the React
release line it targets, so a constraint such as `<= 19.2.3` here is a constraint on the RSC integration package, not on
the React peer dependency. The `<= 19.2.3` upper bound is a precautionary
verified-patch ceiling from the current planning pass, not a recorded React API incompatibility. Verification should decide
whether this ceiling should be widened alongside any React 19.2.x range update. Because a hard upper bound would reject a
future `19.2.4` patch or `19.3.x` minor release, the decision must either widen the stable React 19 range to
`>= 19.0.2 < 20.0.0` or document the specific API risk that requires a tight pin. Pre-release React versions should remain
outside the recommended range unless the verification record explicitly tests them. If verification finds no specific API
risk, the default outcome is to widen the range to `>= 19.0.2 < 20.0.0`. The same decision must also audit the Pro package
`react` and `react-dom` peer dependency ranges, currently `>= 16`, so all three peer ranges stay aligned with the minimum
React version decision. **Owner**: @justin808 | **Target**: before any package-range change is merged (see Open Questions).

## React 19.2.x Verification Checklist

Use a dedicated branch for the actual version verification work:

- [ ] Review the React 19.2.x [changelog](https://github.com/facebook/react/blob/main/CHANGELOG.md) and
      [React 19 upgrade guide](https://react.dev/blog/2024/04/25/react-19-upgrade-guide) for breaking changes,
      deprecations, and new APIs that could affect React on Rails SSR, streaming, RSC, or hydration integration.
- [ ] Audit `renderToString` and `renderToStaticMarkup` call sites in React on Rails SSR paths; React 18+ renders Suspense
      fallbacks synchronously in `renderToString` instead of suspending, which can silently change output without an error.
      For each call site in `packages/react-on-rails/src/serverRenderReactComponent.ts`,
      `packages/react-on-rails/src/handleError.ts`, and any generated bundles found by
      `grep -rE "renderToString|renderToStaticMarkup" packages/ --include="*.js" --include="*.mjs" --include="*.cjs" --include="*.ts" --include="*.tsx" --include="*.cts" --include="*.mts"`
      run from the repo root,
      document whether a Suspense-containing tree could plausibly be passed by a user render function today, then either
      open a follow-up migration ticket or record why the current usage is acceptable.
- [ ] If the [Issue 3255](https://github.com/shakacode/react_on_rails/issues/3255) minimum-React-version decision drops React 16/17 support, remove
      `packages/react-on-rails/src/ReactDOMServer.cts`. Otherwise, confirm the file's existing removal comment remains the
      accepted exit criterion and close this task.
- [ ] Run `pnpm install` from a freshly cloned or freshly cleaned checkout with no existing `node_modules`, then confirm
      React, React DOM, and `react-on-rails-rsc` resolve to compatible versions. Capture the exact
      `pnpm list -r --depth=0 react react-dom` and
      `pnpm --filter react-on-rails-pro list --depth=0 react-on-rails-rsc` output in the verification record, such as a
      comment on Issue 3255, so the tested React 19.2.x patch version is auditable. Also verify that the resolved
      `react-on-rails-rsc` version satisfies both the root `^19.0.4` range and the
      `packages/react-on-rails-pro/package.json` peer dependency ceiling `>= 19.0.2 <= 19.2.3`; a mismatch means the ceiling
      must be widened before workspace installs stay consistent across OSS and Pro.
- [ ] Run package checks. Type checking catches breaking API changes — `@types/react` shifts such as removal of the
      implicit `children` prop from `React.FC` and a stricter `useRef` return type, plus `react-dom/server` changes such
      as `renderToPipeableStream` and `renderToReadableStream` through `@types/react-dom` — lint enforces package style,
      and tests exercise the runtime paths:
  - `pnpm run lint` from the repo root (ESLint only; per-package type-check and tests follow)
  - `pnpm --filter react-on-rails run type-check`
  - `pnpm --filter react-on-rails run test`
  - `pnpm --filter create-react-on-rails-app run type-check`
  - `pnpm --filter create-react-on-rails-app run test`
  - `pnpm --filter react-on-rails-pro run type-check` _(requires Pro runtime prerequisites such as license or env setup)_
  - `pnpm --filter react-on-rails-pro run test` _(requires Pro runtime prerequisites such as license or env setup)_
  - `pnpm --filter react-on-rails-pro-node-renderer run type-check` _(requires Pro runtime prerequisites such as license
    or env setup)_
  - `pnpm --filter react-on-rails-pro-node-renderer run test` _(requires Pro runtime prerequisites such as license or env
    setup)_
  - Confirm whether `react_on_rails_pro/spec/execjs-compatible-dummy` needs a dedicated React 18 test run as part of the
    acceptance criteria.
  - Confirm the resolved `@tanstack/react-router` version used by the Pro package still satisfies its React 19 compatibility
    matrix, and make the Pro `./tanstack-router` export part of the RSC boundary verification. If local Pro prerequisites
    are unavailable, record the PR's Pro CI result as the proxy and open a follow-up only if that CI does not cover the
    export.
  - Public contributors without Pro runtime prerequisites should rely on the PR's Pro CI checks as the proxy for these
    Pro verification steps.
- [ ] Run Ruby checks that exercise SSR and generated apps:
  - `bundle exec rubocop`
  - `bundle exec rake rbs:validate`
  - `cd react_on_rails && bundle exec rspec spec/react_on_rails/` for gem-side rendering, doctor, and generator coverage
  - `cd react_on_rails/spec/dummy && bundle exec rspec spec/requests spec/system spec/packs_generator_spec.rb` for dummy
    SSR and generator integration paths
  - Pro RSC and renderer paths _(requires Pro access and `react_on_rails_pro/` checked out)_:
    ```bash
    cd react_on_rails_pro/spec/dummy
    bundle exec rspec spec/requests/rsc_payload_spec.rb spec/requests/server_render_check_spec.rb spec/system/renderer_integration_spec.rb
    ```
  - See `.claude/docs/replicating-ci-failures.md` (Claude Code agent reference) when mapping a failed CI job back to a
    narrower local command; human contributors can also use the failing CI job name from the GitHub Actions log to scope
    the local repro.
- [ ] Ensure Playwright browsers are installed, then run E2E coverage:
  - `cd react_on_rails/spec/dummy && pnpm playwright install --with-deps`
  - `cd react_on_rails/spec/dummy && pnpm test:e2e` for OSS dummy SSR and hydration paths
  - `cd react_on_rails_pro/spec/dummy && pnpm playwright install --with-deps`
  - `cd react_on_rails_pro/spec/dummy && pnpm run e2e-test` for Pro `stream_react_component` and RSC payload paths
  - See `.claude/docs/playwright-e2e-testing.md` (Claude Code agent reference) for additional notes; the commands above
    are the canonical OSS dummy setup for human contributors.
- [ ] Run the generated-app suite. Prefer a fresh clone. If a fresh clone is not practical, use a disposable worktree so
      the current checkout and gitignored files are untouched:

  ```bash
  git worktree list                      # confirm no stale /tmp/ror-verify entry from a prior interrupted run
  git worktree add /tmp/ror-verify HEAD  # detached HEAD is intentional for read-only verification
  (cd /tmp/ror-verify && pnpm install)
  cd /tmp/ror-verify/react_on_rails && bundle exec rake run_rspec:shakapacker_examples   # full suite across all example apps (latest + all pinned React versions)
  ```

  After the suite runs, remove the worktree from the original checkout:

  ```bash
  git worktree remove /tmp/ror-verify
  ```

  If neither a fresh clone nor a disposable worktree is practical, use the repo root only after stashing or committing tracked
  and non-ignored in-progress work. Note: `git stash -u` saves untracked non-ignored files, but does not save gitignored
  files.

  > **Warning**: `git clean -fdx` deletes all untracked files, including gitignored files, and cannot be undone. Move or
  > back up gitignored files, such as `.env`, local credentials, or generated certs, before using the fallback below.

  ```bash
  git stash -u
  git clean -ndx   # dry run — review the printed list before running the destructive command below
  git clean -fdx
  pnpm install
  cd react_on_rails && bundle exec rake run_rspec:shakapacker_examples   # full suite across all example apps (latest + all pinned React versions)
  ```

  Note: `bundle exec rake shakapacker_examples:gen_all` only generates apps; a separate `run_rspec:*` task must run their
  tests.

- [ ] Confirm docs that mention explicit React versions are either updated or intentionally left on older minimum-version
      examples.
- [ ] Fill the secondary reviewer placeholders in the Open Questions section before opening the first implementation PR.

If any verification step fails, capture the exact command and failure in a comment on
[Issue 3255](https://github.com/shakacode/react_on_rails/issues/3255), then apply this default decision rule
(**Owner**: @justin808 for all blocking calls):

- Public API regression, such as broken SSR output, hydration mismatch, or a missing export: block the package-range work
  until resolved.
- Behavior change without breakage, such as a Suspense and `renderToString` semantic shift: open a migration ticket,
  document the change, and do not block the range work.
- Pro-only test failure: block the Pro ceiling change; the OSS range update may proceed independently if OSS tests pass.

## Partial Pre-Rendering Definition

Before implementation, define the feature in React on Rails terms instead of adopting another framework's terminology
too loosely:

- The Rails route still owns routing, authentication, headers, caching, and status codes.
- React on Rails owns React registration, SSR, streaming, and hydration boundaries.
- Streaming SSR means the Node Renderer starts work during the request and flushes chunks as Suspense boundaries and RSC
  payloads resolve, delivering content progressively without waiting for a full render.
- True partial pre-rendering would require a reusable static-shell, rendered ahead of dynamic data through an explicit
  cache warm-up request, an asset-pipeline precompile hook, or a cache layer such as Rails HTTP caching or a CDN, with
  dynamic holes filled by a later streaming pass.
- The feature must not require moving a Rails app into a frontend-framework routing model.

Note: React's official experimental PPR API in canary releases is not required for the patterns described here. This plan
targets approaches achievable with stable React 19.x unless a specific implementation step states otherwise.

## Candidate Implementation Shapes

Evaluate these in order:

1. **Documented pattern only**: show how to combine Rails fragment caching, `react_component` plus Suspense, and RSC
   boundaries to get a static-shell or streaming-SSR-style result without new OSS public APIs. The Pro version of the
   pattern can use `stream_react_component` for streaming delivery.
2. **Helper-level ergonomics**: add an option or wrapper around existing streaming helpers only if repeated app code
   emerges across examples.
3. **Renderer protocol support**: add Node Renderer request metadata only if the helper-level approach cannot express the
   needed static/dynamic boundary cleanly.
4. **Dummy-app example**: add a small route in the dummy app after the behavior is proven manually. Promote to a
   generated-app entry only if the pattern needs scaffolding coverage in `run_rspec:shakapacker_examples`.

## Acceptance Criteria

- React 19.2.x passes the same local verification suite as the currently supported React 19 line.
- Existing SSR, streaming SSR, RSC payload rendering, and client hydration tests stay green.
- The full generated-app suite (`bundle exec rake run_rspec:shakapacker_examples`) passes with React 19.2.x.
- Any public docs that cite an explicit React version are updated or explicitly annotated with a minimum-version note.
- Any partial pre-rendering proposal includes a same-route benchmark against traditional SSR or streaming SSR (see
  `internal/planning/library-benchmarking.md` for tooling guidance).
- The first public artifact is documentation or an example unless a missing library API is clearly demonstrated.
- The feature name and docs explain Rails ownership clearly so users do not expect Next.js-style file-system routing.
- The decision on the minimum supported React version, including whether React 18.x remains supported, is documented
  before any package-range change is merged.

## Resolved Decisions

The five questions below were resolved in
[Issue 3255](https://github.com/shakacode/react_on_rails/issues/3255) on 2026-06-02. The overarching frame: PPR splits
into two tracks, and the first example ships **Track A** — streaming SSR with Suspense and a fragment-cached shell, on
existing stable React 19 plus existing Pro helpers (`stream_react_component`, `cached_stream_react_component`). **Track B**
— RSC with `"use cache"`, per [`ppr-implementation-plan.md`](./ppr-implementation-plan.md) — is the longer-term path,
tracked in [Issue 3571](https://github.com/shakacode/react_on_rails/issues/3571).

**Secondary reviewer (SSR-vs-RSC)**: Abanoub Ghadban (fallback: @justin808)

**Backup reviewer (benchmarks)**: Abanoub Ghadban (fallback: @justin808)

1. **First example — SSR strategy (the prerequisite decision).** Use traditional **streaming SSR with Suspense** (Pro
   `stream_react_component`), not RSC and not both-in-one. RSC PPR becomes Example 2 under Track B
   ([Issue 3571](https://github.com/shakacode/react_on_rails/issues/3571)). Rationale: it ships on stable React 19 and
   existing Pro helpers as docs plus one dummy-app route, rather than blocking on the multi-month Track B toolchain.
2. **Static-shell caching layer.** Layered, defaulting to the **Rails fragment cache** for the first example via the
   existing `cached_stream_react_component` (`cache_key` + `expires_in`); dynamic holes stream per request and are never
   cached. Tier 2 (HTTP caching headers such as `Cache-Control: public, s-maxage, stale-while-revalidate`) applies only
   to fully static routes with no live holes. Tier 3 (CDN edge cache of shell + postponed state with an origin resume
   protocol) is split into [Issue 3572](https://github.com/shakacode/react_on_rails/issues/3572). Non-goal for v1:
   HTTP/CDN-caching a streamed response that still has live per-request holes.
3. **Who renders the shell vs. where it is cached.** Both, composed — these are orthogonal axes. The **Node Renderer
   renders** the shell via `stream_react_component`; the **Rails fragment cache stores** it via
   `cached_stream_react_component`, so the shell is rendered once and replayed without re-invoking the renderer. Track B
   uses the same composition with richer paired artifacts (HTML prelude + opaque `postponed` state).
4. **Streamed-failure status codes and error boundaries.** The HTTP status is committed at the shell boundary, before
   the first byte flushes: a pre-flush failure returns a real 4xx/5xx and the normal error page. After the first flush
   the response is irrevocably 200 — a failure inside a streamed hole is handled **in-band** by a React error boundary
   scoped to that hole, and reported **out-of-band** (existing Pro Sentry/Honeybadger hooks, plus an optional
   machine-readable in-stream marker so monitoring can distinguish a clean 200 from a degraded 200). Each dynamic hole
   gets its own error boundary so one failed region degrades only itself. A full mid-stream abort yields a truncated
   response; the React client runtime recovers un-flushed boundaries on hydration, falling back to client render where
   it cannot.
5. **Acceptance metrics.** Primary: **TTFB and LCP**. Secondary: response-end (full-stream complete) and total
   transferred bytes. **Client-JS reduction is a Track B (RSC) metric only** — it does not apply to the Track A example,
   which ships the same client bundle as normal SSR. Benchmark plan: a same-route **A/B** comparison (the identical page
   rendered as plain SSR vs. the PPR pattern), using the existing harness in
   [`library-benchmarking.md`](./library-benchmarking.md) — a max-rate run for capacity plus a fixed-rate run for
   meaningful TTFB/LCP latency comparison, with Bencher tracking regressions. Hold the delivery path
   (`ActionController::Live` vs. Node Renderer streaming) constant within an A/B pair and report which was used.

## Open Questions

These remain open after [Issue 3255](https://github.com/shakacode/react_on_rails/issues/3255); they were outside that
issue's five-question scope. Track each one to an explicit decision before the implementation step it gates.

- How does the static-shell or streaming-SSR pattern interact with Turbo Drive navigation, Turbo Frames, and Turbo Streams?
  Confirm whether Turbo page visits re-request the full response instead of reusing a cached shell, and whether
  `stream_react_component` can flush into a Turbo Stream frame.
  **Owner**: @justin808 | **Target**: before any implementation PR is opened
- Should the minimum supported React version retain React 18.x compatibility or move to React 19.x only?
  **Owner**: @justin808 | **Target**: before any package-range change is merged
- Should the `react-on-rails-pro` peer dependency ceiling for `react-on-rails-rsc` stay at `<= 19.2.3` or widen with the
  React 19.2.x verification work? If it stays tight, what specific API risk justifies rejecting future React 19.x patch
  or minor releases? Default to widening to `< 20.0.0` when verification finds no specific API risk.
  **Owner**: @justin808 | **Target**: before any package-range change is merged

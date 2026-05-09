# React 19.2.x and Partial Pre-Rendering Plan

## Purpose

Track the work needed for [Issue 2182](https://github.com/shakacode/react_on_rails/issues/2182): verify React 19.2.x
support and decide how React on Rails should expose any partial pre-rendering workflow that becomes practical for Rails
apps.

This is a planning document. It does not change package versions, build configuration, or Pro package code.

**Status**: Draft | **Created**: 2026-04 | **Last updated**: 2026-05-09 | **Tracks**:
[Issue 2182](https://github.com/shakacode/react_on_rails/issues/2182) and
[Issue 3255](https://github.com/shakacode/react_on_rails/issues/3255)

## Current Repository Signal

The workspace package ranges already allow React 19.2.x through `^19.0.3` for `react` and `react-dom`, plus `^19.0.4`
for `react-on-rails-rsc` (the React on Rails RSC integration package, not a React-team package), in the root, dummy app,
and Pro dummy app package manifests. To see what versions are currently resolved, run
`pnpm list react react-dom react-on-rails-rsc` from the repo root. Note: `react_on_rails_pro/spec/execjs-compatible-dummy`
is intentionally pinned to React 18 through pnpm overrides for `app>react` and `app>react-dom`; verification should
confirm whether that workspace stays on React 18 during this work. That means the first implementation step is
verification, not necessarily a broad package-range change.

Note: `react-on-rails-pro` currently pins `react-on-rails-rsc` as a peer dependency at `>= 19.0.2 <= 19.2.3`.
Verification should confirm whether this ceiling is intentional or should be widened alongside any React 19.2.x range
update.

## React 19.2.x Verification Checklist

Use a dedicated branch for the actual version verification work:

- [ ] Review the React 19.2.x changelog and release notes for breaking changes, deprecations, and new APIs that could
      affect React on Rails SSR, streaming, RSC, or hydration integration.
- [ ] Confirm the existing `renderToString` usages in `packages/react-on-rails/src/serverRenderReactComponent.ts` and
      `packages/react-on-rails/src/handleError.ts` are intentionally exempt from migration to `renderToPipeableStream`;
      React 19 soft-deprecates `renderToString`. Also grep `packages/react-on-rails-pro-node-renderer/` and related SSR
      integration paths for additional call sites, then document either a migration ticket or why current usage is
      acceptable.
- [ ] Run `pnpm install` from a clean checkout and confirm React, React DOM, and `react-on-rails-rsc` resolve to
      compatible versions.
- [ ] Run package checks. Type checking catches breaking `react-dom/server` API changes such as `renderToPipeableStream`
      and `renderToReadableStream` through `@types/react-dom`, lint enforces package style, and tests exercise the
      runtime paths:
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
  - See `.claude/docs/replicating-ci-failures.md` when mapping a failed CI job back to a narrower local command.
- [ ] Ensure Playwright browsers are installed, then run E2E coverage:
  - `cd react_on_rails/spec/dummy && pnpm playwright install --with-deps`
  - `cd react_on_rails/spec/dummy && pnpm test:e2e` for OSS dummy SSR and hydration paths
  - `cd react_on_rails_pro/spec/dummy && pnpm playwright install --with-deps`
  - `cd react_on_rails_pro/spec/dummy && pnpm run e2e-test` for Pro `stream_react_component` and RSC payload paths
  - See `.claude/docs/playwright-e2e-testing.md` for the OSS dummy setup.
- [ ] Run the generated-app suite from the repo root in a clean checkout:
      `bundle exec rake run_rspec:shakapacker_examples_latest` for the React 19 examples. Use
      `bundle exec rake run_rspec:shakapacker_examples` to run the full suite across pinned React versions when needed.
      `bundle exec rake shakapacker_examples:gen_all` only generates example apps; a separate `run_rspec:*` task must run
      their tests.
- [ ] Confirm docs that mention explicit React versions are either updated or intentionally left on older minimum-version
      examples.

If any verification step fails, capture the exact command and failure, then decide whether to pin the resolved React
version, open an upstream or compatibility issue, or block the package-range work until the regression has an owner.

## Partial Pre-Rendering Definition

Before implementation, define the feature in React on Rails terms instead of adopting another framework's terminology
too loosely:

- The Rails route still owns routing, authentication, headers, caching, and status codes.
- React on Rails owns React registration, SSR, streaming, and hydration boundaries.
- Streaming SSR means the Node Renderer starts work during the request and flushes chunks as Suspense boundaries and RSC
  payloads resolve, delivering content progressively without waiting for a full render.
- True partial pre-rendering would require a reusable static-shell, rendered ahead of dynamic data at build time or at a
  cache layer such as Rails HTTP caching or a CDN, with dynamic holes filled by a later streaming pass.
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
4. **Generated example**: add a small route in the dummy app after the behavior is proven manually.

## Acceptance Criteria

- React 19.2.x passes the same local verification suite as the currently supported React 19 line.
- Existing SSR, streaming SSR, RSC payload rendering, and client hydration tests stay green.
- The generated-app suite (`bundle exec rake run_rspec:shakapacker_examples_latest`) passes with React 19.2.x.
- Any public docs that cite an explicit React version are updated or explicitly annotated with a minimum-version note.
- Any partial pre-rendering proposal includes a same-route benchmark against traditional SSR or streaming SSR.
- The first public artifact is documentation or an example unless a missing library API is clearly demonstrated.
- The feature name and docs explain Rails ownership clearly so users do not expect Next.js-style file-system routing.
- The decision on the minimum supported React version, including whether React 18.x remains supported, is documented
  before any package-range change is merged.

## Open Questions

Track these in [Issue 3255](https://github.com/shakacode/react_on_rails/issues/3255) before implementation begins so
each decision has an owner, acceptance criteria, and a closure path.

The prerequisite decision is whether the first implementation should prove the pattern through traditional SSR with
Suspense, RSC, or both; answer that before settling caching, benchmarks, or streamed-error semantics.

Before implementation starts, assign a secondary reviewer for the prerequisite SSR-vs-RSC decision so the plan does not
stall if @justin808 is unavailable. Also assign a backup reviewer for benchmark metrics because that decision can be
validated independently from the rest of the implementation tree.

**Secondary reviewer (SSR-vs-RSC)**: _[name to be filled before first implementation PR]_

**Backup reviewer (benchmarks)**: _[name to be filled before first implementation PR]_

- Which Rails caching layer should be recommended for the static-shell: fragment cache, HTTP cache, CDN cache, or a
  combination?
  **Owner**: @justin808 | **Target**: before any implementation PR is opened
- Should the static-shell be rendered by the Node Renderer, cached as a Rails partial fragment, or selected per example?
  **Owner**: @justin808 | **Target**: before any implementation PR is opened
- Should the first example use traditional SSR with Suspense, RSC, or both?
  **Owner**: @justin808 | **Secondary reviewer**: React on Rails maintainer with Pro access | **Target**: prerequisite
  decision before any implementation PR is opened
- How should failures in the dynamic portion affect status codes and error boundaries after part of the response has
  streamed?
  **Owner**: @justin808 | **Target**: after the SSR-vs-RSC strategy decision, before public docs or examples
- What metrics matter most for acceptance: TTFB, LCP, response end, total bytes, or client JavaScript reduction, and how
  do Rails `ActionController::Live` and Node Renderer streaming paths affect those metrics differently?
  **Owner**: @justin808 | **Secondary reviewer**: React on Rails maintainer with Pro access | **Target**: after the
  SSR-vs-RSC strategy decision, before benchmark implementation

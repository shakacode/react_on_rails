# React 19.2.x and Partial Pre-Rendering Plan

## Purpose

Track the work needed for [Issue 2182](https://github.com/shakacode/react_on_rails/issues/2182): verify React 19.2.x
support and decide how React on Rails should expose any partial pre-rendering workflow that becomes practical for Rails
apps.

This is a planning document. It does not change package versions, build configuration, or Pro package code.

## Current Repository Signal

The workspace package ranges already allow React 19.2.x through `^19.0.3` in the root, dummy app, and Pro dummy app
package manifests. The current `pnpm-lock.yaml` resolves React and React DOM entries in the 19.2.x line for the main
workspace. That means the first implementation step is verification, not necessarily a broad package-range change.

## React 19.2.x Verification Checklist

Use a dedicated branch for the actual version verification work:

1. Run `pnpm install` from a clean checkout and confirm React, React DOM, and `react-on-rails-rsc` resolve to compatible
   versions.
2. Run package checks:
   - `pnpm run type-check`
   - `pnpm run lint`
   - `pnpm run test`
3. Run Ruby checks that exercise SSR and generated apps:
   - `bundle exec rubocop`
   - `bundle exec rake rbs:validate`
   - targeted RSpec for React rendering, doctor, generators, and dummy SSR paths
4. Run at least one generated-app path that installs dependencies from scratch.
5. Confirm docs that mention explicit React versions are either updated or intentionally left on older minimum-version
   examples.

## Partial Pre-Rendering Definition

Before implementation, define the feature in React on Rails terms instead of importing another framework's terminology
too loosely:

- The Rails route still owns routing, authentication, headers, caching, and status codes.
- React on Rails owns React registration, SSR, streaming, and hydration boundaries.
- The Node Renderer may render a stable shell while dynamic server data resolves later through streaming, RSC payloads,
  or Rails cache-backed fragments.
- The feature must not require moving a Rails app into a frontend-framework routing model.

## Candidate Implementation Shapes

Evaluate these in order:

1. **Documented pattern only**: show how to combine Rails fragment caching, `stream_react_component`, Suspense, and RSC
   boundaries to get a partial-pre-rendering style result without new public APIs.
2. **Helper-level ergonomics**: add an option or wrapper around existing streaming helpers only if repeated app code
   emerges across examples.
3. **Renderer protocol support**: add Node Renderer request metadata only if the helper-level approach cannot express the
   needed static/dynamic boundary cleanly.
4. **Generated example**: add a small route in the dummy app after the behavior is proven manually.

## Acceptance Criteria

- React 19.2.x passes the same local verification suite as the currently supported React 19 line.
- Existing SSR, streaming SSR, RSC payload rendering, and client hydration tests stay green.
- Any partial pre-rendering proposal includes a same-route benchmark against traditional SSR or streaming SSR.
- The first public artifact is documentation or an example unless a missing library API is clearly demonstrated.
- The feature name and docs explain Rails ownership clearly so users do not expect Next.js-style file-system routing.

## Open Questions

- Which Rails caching layer should be recommended for the static shell: fragment cache, HTTP cache, CDN cache, or a
  combination?
- Should the first example use traditional SSR with Suspense, RSC, or both?
- How should failures in the dynamic portion affect status codes and error boundaries after part of the response has
  streamed?
- What metrics matter most for acceptance: TTFB, LCP, response end, total bytes, or client JavaScript reduction?

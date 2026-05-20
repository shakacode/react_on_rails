# Plan: `RSCRoute ssr={false}`

Status: **implementation plan** for [issue #3101](https://github.com/shakacode/react_on_rails/issues/3101).
Phase 1 is implemented. This plan targets the full implementation for the issue. The phases describe
implementation modes and review boundaries, not optional roadmap items.

## Summary

Add an optional `ssr` prop to `RSCRoute`:

```tsx
<RSCRoute componentName="HeavyWidget" componentProps={{ userId }} ssr={false} />
```

`ssr` defaults to `true`, preserving current behavior. When `ssr={false}`, the route does not generate
or embed that instance's RSC payload during the initial Rails server render. Phase 1 resolves the same
server component after the React tree has mounted. Phase 2 resolves through React's Suspense retry path
while preserving the same payload-skipping invariant.

The feature gives applications a per-route way to defer lower-priority server component content. It reduces
initial server work and initial HTML size for those routes without changing server component registration,
error handling, retry behavior, or the existing provider cache model.

## Problem

`RSCRoute` currently enters the RSC provider path whenever it renders. During server rendering, that path
uses the server-side RSC implementation, which calls `railsContext.getRSCPayloadStream(...)`, renders the
server component into HTML, and tracks the payload so React on Rails Pro can embed it into the streamed
response as `window.REACT_ON_RAILS_RSC_PAYLOADS` chunks.

That behavior is correct for content needed in the initial HTML. It is wasteful for content that does
not contribute to the initial view or first interaction. This feature is for server component routes whose
work can move out of the critical render path: content hidden behind user interaction, content outside the
initial viewport, or secondary data that can load after the page becomes interactive.

`ssr={false}` lets the application opt a single `RSCRoute` out of that initial server work while preserving
the rest of the RSC runtime behavior once the browser takes over.

## Goals

- Add `ssr?: boolean` to `RSCRoute`, with `true` as the default.
- Preserve current behavior when `ssr` is omitted or set to `true`.
- For `ssr={false}`, avoid calling the server-side RSC payload path during the initial server render.
- Avoid embedding payload chunks for skipped server-rendered instances.
- Keep hydration consistent with the server output.
- Use the existing provider path for payload resolution, cache reuse, error wrapping, and retry. Phase 1 enters
  that path after mount; Phase 2 enters it through React's Suspense retry path.
- Support pages that mix immediately server-rendered `RSCRoute` instances with deferred instances.
- Document when to use the prop and the tradeoff it introduces.

## Non-goals

- Do not add a separate `fallback` prop to `RSCRoute`; users use React `Suspense` for loading UI.
- Do not add a new server component registration API.
- Do not add migration tooling for converting existing loadable/client-only components to RSC.
- Do not create a second `RSCRoute`-specific fetch/cache/error runtime.
- Do not change server renderer semantics outside the phase boundaries below.
- Do not automatically make all server component rendering work through non-streaming Rails helper paths.

## Proposed API

The prop name is `ssr`.

`ssr` is concise, uses common React terminology, and describes the behavior at the React component boundary:
whether this route participates in server-side rendering for the initial request. It also avoids overloading
the Rails helper term `prerender`, which already has broader meaning in React on Rails.

The default is `true` so existing applications keep the same behavior without code changes.

No new loading prop is needed. `Suspense` owns loading UI. `RSCRoute` owns payload timing. When users want
loading UI, they place the deferred route under a scoped `Suspense` boundary:

```tsx
<Suspense fallback={<Spinner />}>
  <RSCRoute componentName="HeavyWidget" componentProps={{ userId }} ssr={false} />
</Suspense>
```

Phase 1 preserves client-side loading UI after mount. Phase 2 renders that scoped Suspense fallback in the
server HTML.

## Behavioral contract

The table below describes the Phase 1 contract. Later phases preserve the same payload-skipping invariant and
add narrower behavior on top of it.

| Scenario      | Server render                    | First browser hydration render   | After mount                                | Embedded RSC payload                          |
| ------------- | -------------------------------- | -------------------------------- | ------------------------------------------ | --------------------------------------------- |
| `ssr` omitted | Current behavior                 | Current behavior                 | Current behavior                           | Current behavior                              |
| `ssr={true}`  | Current behavior                 | Current behavior                 | Current behavior                           | Current behavior                              |
| `ssr={false}` | Render no content for that route | Render no content for that route | Resolve through existing RSC provider path | No payload generated by that route during SSR |

The key invariant is narrow and intentional:

> An `ssr={false}` instance must not initiate server-side RSC payload generation during the initial server render.

That invariant does not require a duplicate browser HTTP request when an equivalent result already exists in
the provider cache. Phase 2 preserves this invariant while changing the server HTML when a scoped Suspense
boundary covers the deferred route: the route content is still skipped, but React can emit the boundary fallback.

## Existing source paths

The implementation reuses the current RSC runtime paths:

- `packages/react-on-rails-pro/src/RSCRoute.tsx` currently calls
  `useRSC().getComponent(componentName, componentProps)` during render and passes the returned promise to
  `PromiseWrapper`.
- `packages/react-on-rails-pro/src/RSCProvider.tsx` owns the provider-level promise cache. It exposes
  `getComponent` and `refetchComponent`, and its cache key is based on `componentName` and `componentProps`.
- `packages/react-on-rails-pro/src/getReactServerComponent.server.ts` is the server implementation that calls
  `railsContext.getRSCPayloadStream(...)`.
- `packages/react-on-rails-pro/src/RSCRequestTracker.ts` tracks generated payload streams for embedding.
- `packages/react-on-rails-pro/src/injectRSCPayload.ts` emits payload initialization and payload chunks into
  the HTML stream.
- `packages/react-on-rails-pro/src/getReactServerComponent.client.ts` first checks
  `window.REACT_ON_RAILS_RSC_PAYLOADS`; if there is no embedded payload, it fetches from the configured RSC
  payload endpoint.
- `RSCRouteErrorBoundary` converts errors surfaced from `PromiseWrapper` into `ServerComponentFetchError`,
  which preserves the retry pattern around `useRSC().refetchComponent(...)`.

The feature extends `RSCRoute`'s timing and keeps the existing provider/client/server implementations as the
main data path.

## Phase 1 render timing design

Phase 1 uses a mount-gated timing model. The route needs a server-and-hydration phase where
`ssr={false}` returns no content before provider-dependent work runs. It also needs a browser-mounted phase where
the existing RSC provider path is allowed to run.

React's [`hydrateRoot`](https://react.dev/reference/react-dom/client/hydrateRoot) documentation expects the
initial client output during hydration to match the server-rendered HTML. React also documents a two-pass
pattern for intentional client/server differences using state set in an
[`Effect`](https://react.dev/reference/react/useEffect). That pattern fits this feature:

1. Server render returns no content for `ssr={false}`.
2. First browser hydration render also returns no content for `ssr={false}`.
3. An Effect marks the route as mounted.
4. The next render enters the existing RSC provider path.

This avoids a hydration mismatch while still allowing the browser to fetch the deferred payload immediately
after mount.

Phase 2 keeps the same payload-skipping invariant but changes the timing model: server rendering uses a
classified Suspense bailout, and client rendering enters the provider path through React's Suspense retry path.

## Component structure

`RSCRoute` makes the skip decision before calling `useRSC()` or generating a provider cache key. The component
shape is:

```tsx
function RSCRoute(props) {
  // Track whether the browser has mounted.
  // If ssr={false} and the route has not mounted, return null.
  // Otherwise render the provider-dependent content component.
  return <RSCRouteContent {...props} />;
}

function RSCRouteContent(props) {
  // Use the existing RSC provider path.
  // getComponent(...), PromiseWrapper, and RSCRouteErrorBoundary stay here.
}
```

This shape matters for three reasons:

1. It avoids `useRSC()` before a skipped server render returns.
2. It keeps hook ordering valid by not conditionally calling hooks inside a single component body.
3. It creates a natural extension point for later root-provider work without adding a separate fetch path.

The error boundary continues to own conversion to `ServerComponentFetchError`. Place the boundary so it covers
the provider-dependent content render, not only the promise result, while preserving the documented retry
behavior.

## Provider and cache behavior

Provider cache reuse remains valid.

The provider cache currently deduplicates by `componentName` and `componentProps`. It does not include `ssr`,
and it does not include the DOM node id. This means two identical routes inside the same provider can share a
promise/result.

That is acceptable for this feature. The rule is not "`ssr={false}` always performs a unique HTTP request." The
rule is "`ssr={false}` does not cause server payload generation during SSR."

Important examples:

- Different components: an immediately rendered route can generate and embed its payload while a deferred route
  skips server payload generation and resolves later.
- Same component with different props: the keys differ, so only the immediately rendered props generate a server
  payload.
- Same component with equivalent props: the deferred route can reuse an equivalent provider result after mount
  if another route already populated the provider cache.

Tests assert the invariant and avoid over-specifying duplicate network requests.

## Error and retry behavior

The delayed route uses the same RSC provider path after mount. That preserves the existing failure shape:

1. The client RSC implementation resolves from embedded payloads when available or fetches from the RSC payload
   endpoint when needed.
2. Fetch or render failures surface through the promise consumed by `PromiseWrapper`.
3. `RSCRouteErrorBoundary` converts those failures into `ServerComponentFetchError`.
4. User error boundaries can inspect the component name and props and call `useRSC().refetchComponent(...)`.

The implementation avoids custom fetch/catch/retry logic inside `RSCRoute`. A custom route-local fetcher would
duplicate provider caching and make retry behavior diverge from existing client-side RSC navigation failures.

## Mixed-page behavior

Mixed pages work naturally when each route makes its own render-timing decision.

Example:

```tsx
<>
  <RSCRoute componentName="HeaderStats" componentProps={{ userId }} />
  <RSCRoute componentName="Recommendations" componentProps={{ userId }} ssr={false} />
</>
```

Phase 1 expected behavior:

- `HeaderStats` follows the current server-rendered path and can embed its payload.
- `Recommendations` returns no content during server render and first hydration render.
- After mount, `Recommendations` resolves through the existing provider path.
- The two routes do not require a separate global coordinator.

In Phase 2, a scoped `Suspense` boundary around `Recommendations` can render fallback HTML during server
rendering while preserving the same sibling shell and payload-skipping invariant.

## Suspense behavior

Phase 1 focuses on the core behavior: skip server payload generation, keep hydration stable, and use the
existing client RSC path after mount.

React supports server-rendering [`Suspense`](https://react.dev/reference/react/Suspense) fallback by treating a
server-side throw under `Suspense` as an intentional server bailout and retrying on the client. Phase 2 uses that
model for `RSCRoute ssr={false}` during streaming SSR.

In Phase 2, a deferred route throws a classified intentional bailout on the server before provider-dependent RSC
work runs. React emits the nearest Suspense fallback into the server HTML and retries the route on the client.
React on Rails Pro classifies only that intentional bailout as non-fatal in stream error handling; real render
failures keep the existing error behavior.

`RSCRoute` does not add a fallback prop and does not wrap itself in an internal `Suspense` boundary. The nearest
Suspense boundary controls loading UI. A scoped user boundary preserves the surrounding shell and renders the
intended fallback:

```tsx
<Header />
<Suspense fallback={<RecommendationsSkeleton />}>
  <RSCRoute componentName="Recommendations" componentProps={{ userId }} ssr={false} />
</Suspense>
<Footer />
```

If no nearer boundary exists in the supported wrapped streaming path, the existing root-level framework boundary
with `fallback={null}` is the nearest boundary and catches the bailout. That preserves payload skipping, but it
can hide the rendered root and provides no meaningful loading UI. The documented pattern is to place `Suspense`
close to each deferred route.

React reports this documented retry path through client `onRecoverableError`. Phase 2 does not broadly suppress
recoverable errors. The server stream path returns the intentional bailout digest, and the client suppresses only
recoverable errors carrying that digest.

## Support without manual RSC renderer wrapping

Phase 3 adds support for auto-bundled roots that only defer `RSCRoute` payloads with `ssr={false}` without
explicitly calling `wrapServerComponentRenderer`. This includes roots rendered through `react_component(...,
prerender: false)` and deferred-only roots rendered through `stream_react_component`.

The implementation reuses the existing provider machinery rather than adding a second route-local fetch runtime.
The provider must sit above the application subtree, not inside `RSCRoute`, so parent error-boundary fallback UIs
can still call `useRSC().refetchComponent(...)`. A provider nested inside `RSCRoute` disappears when a parent error
boundary replaces the failing route with its fallback UI.

The provider registration must also happen before the application root renders. Registering it as an `RSCRoute`
module side effect is too late for lazy-loaded routes, because the root can render before the chunk that imports
`RSCRoute` is evaluated. Phase 3 therefore registers the default provider from auto-bundled generated client packs
when RSC support is enabled. The generated pack imports the registration module before importing
`react-on-rails-pro/client` and registering the root component.

The client renderer then wraps ordinary non-renderer roots with the registered provider when the current
`railsContext` includes the RSC payload endpoint. Existing renderer roots still delegate to their renderer first,
so roots that already use `wrapServerComponentRenderer` are not double-wrapped.

Manual client entrypoints that bypass generated packs are outside this automatic path. They can import the same
registration module explicitly before registering their root. Making that path fully automatic would require a
broader safe client-entrypoint change, because importing client provider code from the wrong Pro entrypoint can
pollute the RSC build.

## Support inside non-streaming Rails helper paths

Issue #3101 also calls out components rendered through `react_component` rather than `stream_react_component`.
There are two separate cases.

When `react_component` is used with `prerender: false`, the root is already client-rendered. In that mode, no
server RSC payload is generated during the initial response. Phase 3 adds the automatic provider path for
auto-bundled roots that only defer `RSCRoute` payloads, so `RSCRoute ssr={false}` can resolve through the existing
provider runtime without a manual renderer wrapper.

When `react_component` is used with `prerender: true`, the current server-side RSC renderer helper validates
streaming capabilities before the child component tree renders. That means an `RSCRoute ssr={false}` cannot by
itself make this path work, because the outer renderer fails before `RSCRoute` gets a chance to return no
content.

Supporting that mode requires a contained change that delays the streaming-capability check until server RSC
payload generation is actually requested, while preserving the existing descriptive error for true
server-rendered RSC usage. That belongs to the non-streaming helper phase, not Phase 1.

## Implementation phases

The production work is split into phases so each behavior can be built, reviewed, and tested independently. All
phases are part of the target implementation for issue #3101. The phases identify implementation modes and
review boundaries; they do not mean every later phase is a small additive patch on the previous phase.

### Phase 1: core deferred-route behavior

#### `RSCRoute` API and timing

- Add `ssr?: boolean` to `RSCRouteProps`.
- Default `ssr` to `true`.
- Track mounted state on the client.
- Return no content before provider-dependent work when `ssr={false}` and the route has not mounted.
- Move provider-dependent work into a child component so hooks remain unconditional within each component.

#### Existing provider path after mount

- Keep using `useRSC().getComponent(componentName, componentProps)` after the route is allowed to render.
- Keep using `PromiseWrapper` to consume the RSC promise.
- Keep using `RSCRouteErrorBoundary` to preserve `ServerComponentFetchError` behavior.
- Avoid adding custom fetch/caching logic inside `RSCRoute`.

#### Tests

- Add focused unit coverage for the `RSCRoute` timing and provider behavior.
- Add integration coverage for embedded payload absence and eventual client render when appropriate.
- Assert behavior through injected provider/server-loader seams where possible instead of relying on brittle
  implementation details.

#### Documentation

- Update the Pro RSC documentation for the new prop, usage examples, tradeoffs, and retry behavior.

### Phase 2: server-rendered Suspense fallback HTML

- Add a classified server bailout path for `ssr={false}` during streaming SSR.
- Trigger the bailout before `useRSC()`, provider cache key generation, or server RSC payload generation.
- Render the nearest Suspense fallback HTML for deferred routes. Scoped user boundaries provide the intended UI.
- Do not add a `fallback` prop or an internal `Suspense` boundary to `RSCRoute`.
- Keep intentional fallback rendering separate from real SSR failures in stream error handling.
- Retry the deferred route on the client through the existing RSC provider path.

### Phase 3: automatic root-level RSC provider

- Make `RSCRoute ssr={false}` work in auto-bundled deferred-only roots that do not explicitly call
  `wrapServerComponentRenderer`.
- Add an internal default-provider registry that can wrap a root with the existing `RSCProvider` machinery.
- Apply the default provider in `ClientSideRenderer` only after renderer delegation fails, so manually wrapped
  renderer roots keep their current path and are not double-wrapped.
- Register the default provider from generated client component packs when RSC support is enabled. The generated
  import must run before `react-on-rails-pro/client` registers or renders the root.
- Export the registration module as `react-on-rails-pro/registerDefaultRSCProvider/client` so generated packs and
  manual entrypoints can use the same setup path.
- Lazy-import `getReactServerComponent.client` from the provider's `getServerComponent` function, so the browser
  RSC runtime is loaded only when a deferred route actually fetches payload data.
- Keep the provider above user error boundaries so retry UIs can call `useRSC().refetchComponent(...)`.
- Do not add a Suspense boundary only on the client, because that changes the hydration tree unless the server
  rendered the matching boundary.
- Treat fully manual client entrypoints that bypass generated packs as an explicit-import boundary for this phase.

### Phase 4: non-streaming Rails helper support

- Support the `react_component(..., prerender: true)` path for deferred-only RSC usage by delaying
  server-capability checks until server RSC payload generation is requested.
- Preserve the existing descriptive error when true server-rendered RSC usage requires streaming capabilities.
- Keep `react_component(..., prerender: false)` on the client-rendered path, where no server RSC payload is
  generated during the initial response.

## Test strategy

The tests prove behavior rather than exact implementation shape.

Phase 1 coverage:

1. `ssr={false}` renders no server output for that route and does not call the injected server component loader.
2. `ssr={false}` can return before RSC context is required during the skipped server render.
3. The initial hydration output matches the server output. The payload request is not started during server
   render or the initial hydration output; it starts once React has committed and Effects are allowed to run.
4. After mount, `ssr={false}` uses the existing provider path.
5. A rejected client payload still becomes `ServerComponentFetchError` so user error boundaries and retry flows
   continue to work.
6. Mixed pages work: a default route requests server payload during SSR while an `ssr={false}` route does not.
7. Omitting `ssr` preserves current SSR behavior.
8. A guard test confirms circular props do not break the skipped server render because the route exits before
   provider key generation.

Phase 2 adds focused streaming coverage:

1. A scoped Suspense boundary around `RSCRoute ssr={false}` renders its fallback in server HTML while preserving
   sibling shell content.
2. The intentional bailout does not call the server RSC payload generator and does not embed a deferred payload.
3. Stream metadata does not mark the classified bailout as a render error, including the `throwJsErrors` path.
4. Real render failures still set error metadata and emit errors according to the existing stream rules.
5. Client retry enters the existing provider path; recoverable hydration reporting is not broadly suppressed.

Phase 3 adds focused root-provider coverage:

1. Generated client component packs import the default provider registration module before `react-on-rails-pro/client`
   when RSC support is enabled.
2. Generated client component packs do not import the registration module when RSC support is disabled.
3. Ordinary non-renderer roots are wrapped with the default provider when the factory is registered and the current
   `railsContext` includes the RSC payload endpoint.
4. Renderer roots still delegate to their renderer and are not wrapped by the default provider path.
5. An auto-bundled `react_component(..., prerender: false)` root can render a lazy-loaded `RSCRoute ssr={false}`
   without a manual `wrapServerComponentRenderer` call.
6. An auto-bundled deferred-only `stream_react_component` root can stream the scoped `Suspense` fallback, avoid
   the deferred payload during SSR, and hydrate without logging the classified bailout as a recoverable error.
7. The no-manual-wrapper client path still uses the existing provider behavior for fetch failures and
   `useRSC().refetchComponent(...)` retry.
8. A normal page that does not render RSC content does not request `/rsc_payload/...` or load the client RSC fetch
   runtime.

Avoid tests that require a separate HTTP request when the provider cache already has an equivalent component
result. Cache reuse is part of the current provider behavior.

## Acceptance criteria mapping

| Issue requirement                          | Plan response                                                                        |
| ------------------------------------------ | ------------------------------------------------------------------------------------ |
| New `ssr` prop                             | Add `ssr?: boolean` to `RSCRouteProps`, defaulting to `true`.                        |
| `ssr={false}` skips SSR payload generation | Return before server-side provider work and assert no server loader call.            |
| Phase 1 client resolution                  | Use mounted state to enter the existing provider path after hydration.               |
| Phase 2 client resolution                  | Use React's Suspense retry path to enter the existing provider path.                 |
| No embedded payload for deferred route     | Avoid calling `railsContext.getRSCPayloadStream(...)` for that route during SSR.     |
| Default behavior unchanged                 | Treat omitted `ssr` and `ssr={true}` as current behavior.                            |
| Mixed pages                                | Make the decision per route instance and preserve provider cache semantics.          |
| Error boundary compatibility               | Keep the existing `PromiseWrapper` and `RSCRouteErrorBoundary` path.                 |
| Deferred-only auto-bundled roots           | Register a default provider from generated client packs and wrap non-renderer roots. |
| Docs update                                | Update `docs/pro/react-server-components/inside-client-components.md`.               |
| Suspense loading UI                        | Keep loading UI owned by scoped React `Suspense` boundaries; add no fallback prop.   |

## Documentation plan

Update `docs/pro/react-server-components/inside-client-components.md` with:

- The `ssr` prop API and default value.
- When to use `ssr={false}`: below-the-fold, collapsed, or lower-priority RSC content.
- The tradeoff: reduced initial server work and HTML payload size, plus a browser round trip before the component
  appears.
- A `Suspense` example for loading UI.
- Guidance to place `Suspense` close to the deferred route; broad boundaries produce broad fallback regions.
- A note that existing error boundary and retry patterns still apply when the route uses the existing RSC provider
  path.

## Phase boundaries

Phase 1 establishes the core contract: `RSCRoute ssr={false}` skips server payload generation, keeps hydration
stable, resolves through the existing provider path after mount, preserves error/retry behavior, and documents
the prop. Phase 2 keeps the provider path and changes the timing through React's Suspense retry path.

Phases 2-4 preserve the payload-skipping goal while changing or expanding specific mechanics:

- Phase 2 adds server-rendered Suspense fallback HTML through classified intentional server bailout handling,
  with loading UI controlled by the nearest scoped Suspense boundary.
- Phase 3 adds automatic root-level RSC provider setup for auto-bundled deferred-only roots that contain
  `RSCRoute ssr={false}` and do not explicitly call `wrapServerComponentRenderer`.
- Phase 4 adds non-streaming Rails helper support for server-rendered `react_component(..., prerender: true)`
  paths by delaying server-capability checks until server RSC payload generation is requested.

All phases are part of the target implementation for issue #3101. They are separated to keep the review and test
surface understandable while preserving a single end-to-end design.

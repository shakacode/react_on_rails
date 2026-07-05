# RSC prefetch is warm-cache-only, with no content-affecting fetch options

Status: accepted (2026-07-05, design session for #4460)

`prefetchServerComponent(componentName, componentProps, { signal? })` — the loader-time replacement for the removed `createRscPayloadNode` (#4439/#4440) — returns `Promise<void>` and only warms a module-level prefetch store that `RSCProvider` adopts from on first `getComponent`. It deliberately does **not** return a `Promise<ReactNode>` and does **not** accept `headers`/`credentials`, even though the removed helper offered all three.

## Why

- **No `ReactNode` return:** handing routers a renderable node recreates the forked rendering path #4440 removed — anyone who receives a node will render it, bypassing the provider's cache, refetch/versioning, and error flow. Rendering is exclusively `<RSCRoute />`'s job. (Same shape as TanStack Query's `prefetchQuery`.)
- **No `headers`/`credentials`:** the cache key is `componentName + serialized props` — fetch options are not part of it. Any per-call option that can change payload _content_ poisons the cache: an adopted prefetch entry would differ from what the canonical path fetches, and a later `refetchComponent` could return different content for the same key. Invariant: anything content-affecting must either be in the cache key or be identical across all fetch paths. Cross-cutting needs (e.g. a cross-origin payload host) belong in a global fetch config applying to every path — a separate feature, on customer demand.
- **`signal` stays:** it can only cancel work, never change content, and routers abort loaders on navigation.

## Consequences

- Prefetch has no CSP/console-replay surface of its own; it inherits the shared client-fetch path's policy. Adoption makes prefetched and render-fetched payloads interchangeable, so a per-path CSP fork would make inline-script emission timing-dependent.
- Failed or aborted prefetches self-evict from the store — a failed prefetch behaves as if it never happened.
- The server-side export is a resolving no-op (not a rejecting stub like `createRscPayloadNode.server.ts` was): loaders legitimately run during SSR, where the payload is guaranteed to be embedded anyway.

See `packages/react-on-rails-pro/CONTEXT.md` for the supporting vocabulary (Prefetch Store, Adoption, Self-eviction).

# React on Rails Pro — RSC

React Server Components support for Rails apps: server-side Flight payload generation, embedding into SSR HTML, client-side caching, and (planned, #4460) loader-time prefetch for client routers.

## Language

**RSC Payload**:
The Flight-serialized output of rendering a server component for a given `componentName + componentProps` pair.
_Avoid_: flight data, RSC chunk (chunk means one stream segment, not the whole payload)

**Provider Cache**:
The per-`RSCProvider`-instance cache of decoded payload promises (`Promise<ReactNode>`), keyed by `createRSCPayloadKey(componentName, componentProps)`; the source of truth once a component renders.
_Avoid_: RSC cache (ambiguous with the other stores)

**Embedded Payload Registry**:
The `window.REACT_ON_RAILS_RSC_PAYLOADS` global written during SSR streaming and consulted by the client before any HTTP fetch.
_Avoid_: preloaded payloads store

**Prefetch Store** (planned, #4460):
A module-level registry of decoded payload promises created by `prefetchServerComponent(...)` from outside React context (router loaders/preloads), awaiting adoption by a Provider Cache.

**Self-eviction** (planned, #4460):
A failed prefetch removes its own Prefetch Store entry, so the subsequent render fetches normally — a failed prefetch behaves as if it never happened.

**Adoption** (planned, #4460):
The act of a `RSCProvider` copying a Prefetch Store entry into its own Provider Cache on the first `getComponent` call for that key.

## Relationships

- Each root component wrapped by `wrapServerComponentRenderer/client` gets its own **RSCProvider**, hence its own **Provider Cache**.
- The **Prefetch Store** is shared across all providers on the page; a prefetched entry may be adopted by any number of Provider Caches (payloads for the same key are identical and immutable).
- The Prefetch Store holds **decoded** promises (`Promise<ReactNode>`), never raw fetch streams — a stream body is single-consumption, a decoded promise is not.
- `refetchComponent` bypasses the Prefetch Store entirely: refetch means "fresh data" and always goes to the network. The store is only consulted on first `getComponent` for a key.
- The Embedded Payload Registry outranks a network fetch; a prefetch for a key already embedded in the SSR HTML must be a no-op.
- `prefetchServerComponent` returns `Promise<void>` (warm-cache only, never a `ReactNode`): resolves once decoded into the Prefetch Store, rejects on failure (internally handled, so fire-and-forget produces no unhandled-rejection noise). Rendering payloads is exclusively `<RSCRoute />`'s job.
- Signature: `prefetchServerComponent(componentName, componentProps, { signal? })`. `headers`/`credentials` are intentionally absent: fetch options are not part of the cache key, so anything that could change payload content must be identical across all fetch paths (per-app needs belong in a global fetch config, not a per-prefetch parameter). An aborted prefetch self-evicts, same as a failed one.
- Prefetch has **no CSP/console-replay surface**: it calls the shared client-fetch path and inherits its policy. Because Adoption makes prefetched and render-fetched payloads interchangeable, a per-path CSP fork would make inline-script emission timing-dependent. The policy itself (default `replayConsoleScripts` off for client-navigation fetches) belongs to the shared path; as of the merged #4440 it still defaults to materializing an inline script (nonce-capable via `cspNonce`), so #4439 sign-off condition 1 is only partially met — tracked on #4460.
- During SSR, `prefetchServerComponent` is a **resolving no-op** (server conditional export): SSR guarantees the payload is embedded via `injectRSCPayload`, so this is the degenerate case of the "embedded payload ⇒ prefetch no-ops" rule. It must never reject — loaders legitimately run on the server.
- The Prefetch Store is **bounded** (mirror the Provider Cache's `BoundedLRU`): entries that are never adopted must not accumulate.

## Example dialogue

> **Dev:** "The router loader prefetched `Dashboard`, but there are two React roots on this page — which one gets the payload?"
> **Domain expert:** "Both can. The **Prefetch Store** is page-global; each **RSCProvider** performs **Adoption** into its own **Provider Cache** on first `getComponent`. One network fetch, any number of adopters."
> **Dev:** "And if the user hits refresh-data, do we reuse the prefetched entry?"
> **Domain expert:** "No — `refetchComponent` always bypasses the Prefetch Store."

## Flagged ambiguities

- (none yet)

# Cache RSC Fragments with `unstable_cache`

React on Rails Pro provides an experimental `unstable_cache` API for caching a React Server
Component's serialized Flight payload. Use it for server components whose output can be reused for
the same arguments.

`unstable_cache` is available only in the React server bundle. Import it from
`react-on-rails-pro/cache`:

```tsx
import { unstable_cache } from 'react-on-rails-pro/cache';

const ProductCard = unstable_cache(
  async ({ productId }: { productId: string }) => {
    const product = await loadProduct(productId);
    return <ProductCardView product={product} />;
  },
  {
    id: 'product-card',
    revalidate: 60,
  },
);
```

The example assumes the product output is shared across callers. A cache hit returns the stored
payload without running the callback, including `loadProduct`. Run authorization checks on every
request **before** invoking the cached function, not inside its callback. Derive tenant or user scope
from authenticated server context, and include any scope or personalization that changes the rendered
output in the function arguments. Cache-key scoping does not replace authorization.

The options are:

- `id` (required): a stable identifier that is unique to each cached function sharing a handler within
  a build. Two functions with the same ID and arguments produce the same cache key.
- `revalidate`: the entry lifetime in seconds. The default `0` means that the cache handler does not
  expire the entry by time.
- `kind`: the registered cache-handler name. The default is `default`, which uses an in-memory LRU
  cache in each Node Renderer worker.
- `tags`: invalidation labels stored on each entry, for use with
  [`unstable_revalidateTag`](#invalidate-by-tag-javascript). Pass a static array, or a function of the
  cached function's arguments — `tags: ({ productId }) => ['products', 'product-' + productId]` — when
  the tags depend on which entity is being rendered. Tags must be non-empty strings of at most 256
  characters, with at most 64 distinct tags per call (invalid or over-limit tags throw a `TypeError`
  before the render runs), and an invalidation matches a stored tag byte-for-byte: the string you
  invalidate must be exactly the string you stored.

The cache key includes the build ID, function ID, and function arguments. Arguments must use the
supported deterministic value types. Supported built-in instances include `Date`, `Map`, and `Set`.
Circular references, functions, symbols, and arbitrary custom class instances are not supported.

Entries are timestamped when their render **starts**, not when the finished payload is stored. For
handlers that enforce expiry from `entry.timestamp` (the default in-memory handler, and any custom
handler that does the same), the effective lifetime therefore shrinks by however long the render took.
`RedisCacheHandler` is unaffected: its Redis-side `EX` TTL starts when the entry is stored.

## Invalidate by Tag (JavaScript)

`unstable_revalidateTag(tags)` invalidates every cached entry that carries any of the given tags, on
every registered cache handler that supports invalidation:

```tsx
import { unstable_revalidateTag } from 'react-on-rails-pro/cache';

await unstable_revalidateTag('products'); // one tag, or an array of tags
```

Invalidation is **mark-stale**, not delete: handlers remember when each tag was last invalidated and
refuse any entry whose render started at or before that instant, so an invalidation that lands while a
render is in flight also covers the entry that render stores afterward. Like the entry's `tags`, the
call takes no timestamp — the invalidation time is always "now".

The call itself reaches only the process that makes it (the Node Renderer worker running your RSC
bundle), and only cache handlers that implement the optional `revalidateTag` method — the default
in-memory handler and `RedisCacheHandler`. With the in-memory handler the invalidation stays inside
that one process. With `RedisCacheHandler` the invalidation record lives in the shared Redis, so it
is visible to **every** worker and machine sharing that Redis on their next read — no broadcast is
involved (see [Tag Invalidation Through Redis](#tag-invalidation-through-redis)). Storing tagged
entries on a handler without `revalidateTag` logs a warning once per handler; the entries keep their
tags, so a handler upgrade honors them later.

## Use Shared Storage

The default cache is process-local. Separate Node Renderer workers do not share its entries. For a
shared cache, install the optional `ioredis` peer dependency and register `RedisCacheHandler`:

In this example, `REDIS_URL` must identify a Redis database or instance dedicated to this application
and environment. Cache keys do not include application or environment identifiers automatically.
If you share a Redis database, instead pass an `ioredis` `RedisOptions` object as `redisUrl`, with an
application-and-environment-specific `keyPrefix` alongside its connection settings.

```tsx
import { RedisCacheHandler, registerCacheHandler, unstable_cache } from 'react-on-rails-pro/cache';

registerCacheHandler('redis', new RedisCacheHandler({ redisUrl: process.env.REDIS_URL }));

const ProductCard = unstable_cache(renderProductCard, {
  id: 'product-card',
  kind: 'redis',
  revalidate: 60,
});
```

### Tag Invalidation Through Redis

`RedisCacheHandler` implements `revalidateTag`, and entries persist their `tags` through Redis, so
tag invalidation works across processes: one `unstable_revalidateTag` call from any worker is visible
to every worker and machine sharing that Redis on their next read. Nothing is broadcast — the
invalidation is a record in the shared storage that each `get` checks.

How it works, and what to configure:

- Each invalidated tag gets one small **stamp key**, `rorp:rsc-tag:<tag>`, holding the invalidation
  time. Stamp keys inherit the client's `keyPrefix` exactly like entry keys, are written
  monotonically (a racing older invalidation can never move a stamp backwards), and deliberately have
  **no TTL**: a stamp must outlive every entry it governs, and entry lifetimes are unbounded when
  `revalidate` is `0`.
- **Set a `volatile-*` eviction policy** (for example `volatile-lru`) on a Redis under memory
  pressure. Those policies evict only keys with a TTL, so finite-`revalidate` entry blobs remain
  evictable while stamp keys are never evicted. An `allkeys-*` policy can evict a stamp and silently
  resurrect entries it had invalidated; the handler probes `maxmemory-policy` on connect
  (best-effort — silent where `CONFIG` is disabled) and logs a warning when it detects one. Note that `revalidate: 0` entries also have no TTL, so under
  a `volatile-*` policy they are never evicted either: size Redis for the full working set of
  indefinite entries, or Redis at `maxmemory` will start rejecting writes (cache writes and stamp
  writes degrade to skip-and-warn; reads still work).
- Stamp keys grow by one small key per distinct invalidated tag (tag names are capped at 256
  characters). Deleting a stamp is safe **only when no entry it governs can still exist**: a deleted
  stamp refuses nothing, so a surviving tagged blob it had invalidated is served again on its next
  read — the same resurrection an `allkeys-*` eviction causes. If every tagged entry uses a finite
  `revalidate`, you can sweep stamps older than your longest `revalidate` interval (plus a generous
  margin for render duration and clock skew) with a prefix scan over `<keyPrefix>rorp:rsc-tag:*`. If
  any tagged entry uses `revalidate: 0`, do not delete stamps: those entries never expire, and entry
  keys are opaque hashes, so the blobs a stamp governs cannot be identified — sweep stamps only
  together with all of the deployment's entry keys, during a window with no tagged renders in flight
  (an in-flight render stores its entry after the sweep, with no stamp left to govern it).
- Invalidation times use the invalidating process's clock. Keep servers NTP-synced; a skewed clock
  shifts which in-flight renders an invalidation covers.
- A refused entry is also deleted from Redis opportunistically **on read** (guarded so it can never
  delete a fresher entry written concurrently), so tagged `revalidate: 0` entries that keep receiving
  reads do not linger as unreadable blobs. An invalidated entry that is never read again keeps its
  blob until a re-render overwrites its key or it is removed manually.
- Invalidation is best-effort and at-most-once: a stamp write that fails (for example during a
  failover) is logged with a warning and not retried. Entries with a finite `revalidate` fall back to
  their TTL; `revalidate: 0` entries keep serving until the tag is invalidated again, so re-run
  `unstable_revalidateTag` if Redis was unavailable when you invalidated.
- Untagged entries pay no extra Redis traffic; tagged entries pay one batched `MGET` of their tags'
  stamps per cache hit.
- Tags are stored inside the entry blob, so they count toward `maxEntryBytes`: an entry within a few
  hundred bytes of the cap may newly skip caching once it carries tags.
- Entries written by this version use a new storage format under a new key namespace: the cache key
  carries a storage-format generation segment (`rorp:rsc-cache:2:`), so old-format entries live under
  keys this version never reads — deliberately independent of the build ID, which a package upgrade
  does not always rotate (see above). Old-format entries are ignored by this version (readable only
  by a rolled-back older package) and expire via their own TTLs; see the migration note below for
  `revalidate: 0` leftovers.
- The handler builds a single-node client. Redis Cluster is not supported: the multi-key stamp
  lookup assumes one node.

You can also implement the exported `CacheHandler` interface and register it with
`registerCacheHandler(kind, handler)`. A handler implements asynchronous `get(key)` and
`set(key, entry)` methods. `TieredCacheHandler` composes handlers as L1 and L2 caches and forwards
`revalidateTag` to each layer that implements it, so an L1 in-memory + L2 Redis composition gets tag
invalidation in both layers. Two behaviors to know:

- **Tagged entries are never promoted from L2 into L1.** Promotion re-stamps the entry's `timestamp`
  to the promotion time, which would erase the render-start evidence tag invalidation is judged
  against (contract rule 5 below). Fresh renders still write both layers with the original
  timestamp; only the cross-worker L2-to-L1 warm-up is skipped for tagged entries.
- **A composition where neither layer implements `revalidateTag` does not claim to support it**, so
  storing tagged entries on it still logs the once-per-handler warning instead of silently
  swallowing invalidations.
- **In a mixed composition (exactly one layer implements `revalidateTag`), tagged entries are stored
  only in the layer that supports invalidation** — a layer that cannot refuse an invalidated entry
  must never hold one, or it would keep serving the stale copy forever. A once-per-instance warning
  logs when this skip first happens. Two corners: if the supporting layer is an L1 that
  `l1MaxTtlSeconds` has disabled, tagged entries are cached nowhere (correct, but uncacheable —
  implement `revalidateTag` on both layers instead); and tagged entries written into the
  non-supporting layer by versions before this rule remain servable there until they expire — after
  an upgrade they are normally unreachable anyway because the build ID in the cache key rotates with
  the bundle.
- **Invalidation reaches only the process that calls it, per layer.** With an in-memory L1 in several
  workers over a shared Redis L2, a worker that calls `unstable_revalidateTag` stamps its own L1 and
  the shared L2 — other workers' L1 copies are untouched and, with the default (uncapped)
  `l1MaxTtlSeconds`, a `revalidate: 0` tagged entry another worker cached before the invalidation
  stays servable there indefinitely. When you use tags with a multi-worker tiered setup, set
  `l1MaxTtlSeconds` to the cross-worker staleness you can tolerate; it is the bound until renderer
  cross-process invalidation ships.

Custom handlers must enforce the entry lifetime: return `null` from `get` for stale entries based on
`entry.timestamp` and `entry.revalidate`, or enforce expiry with the storage backend's TTL.
`unstable_cache` replays any non-null entry returned by `get`; it does not check expiry itself.

A custom handler may also implement the optional `revalidateTag(tag, invalidatedAt?)` method to
support tag invalidation. The contract:

1. An entry with no `tags` is never refused by a tag check.
2. An entry is refused if and only if any of its tags has a **recorded** invalidation with
   `invalidatedAt >= entry.timestamp` — a tag that was never invalidated refuses nothing, and ties
   refuse (an invalidation in the same millisecond as the render start refuses the entry).
3. `revalidateTag` keeps the **maximum** invalidation time seen per tag; it never moves a recorded
   time backwards, and it treats a non-finite `invalidatedAt` as now.
4. `revalidateTag` on a tag with no matching entries still records the invalidation time: a render
   for that tag may already be in flight, and the recorded time is what refuses the entry it stores.
5. A handler that copies or forwards entries (for example between cache tiers) must not move a
   tagged entry's `timestamp` forward in transit — the timestamp is what invalidation is judged
   against, so re-stamping lets the entry evade a recorded invalidation. Either preserve the
   original `timestamp`, or drop the `tags` field when re-stamping.

## Invalidation Limits

Tag-based invalidation currently works only from JavaScript: `unstable_revalidateTag` reaches the
cache handlers registered in the worker that calls it. There is no Node Renderer tag-invalidation
endpoint and no Ruby `ReactOnRailsPro::RSCCache` bridge yet, so a Rails-side write cannot invalidate
JavaScript `unstable_cache` entries. In a multi-worker deployment each worker's **in-memory** cache
is still invalidated independently; entries in a shared `RedisCacheHandler` are invalidated for every
worker sharing the Redis (see
[Tag Invalidation Through Redis](#tag-invalidation-through-redis)). The `CacheHandler` interface has
no delete method.

Use a finite `revalidate` interval when data can change. Include all data that distinguishes the
rendered result in the cached function arguments. The build ID comes from the RSC artifact ID
(`rscBundleHash`), which is derived from the RSC bundle and its companion files. Automatic
build-scoped cache separation occurs only when that artifact ID changes; rebuilding or deploying
with unchanged RSC artifacts does not rotate it. Changes to Rails code, data, or configuration still
need a finite lifetime or an explicit version in the function `id` or arguments to separate cached
results. Changing the namespace does not delete old entries from shared storage.

The default in-memory handler tracks at most 10,000 distinct invalidated tags per process
(constructor option `maxTrackedTags`). Past that bound it clears its **entire** entry cache and
starts over — a safety valve that trades a one-time cold cache for bounded memory, with a
`console.warn` when it trips. Avoid deriving tags from unbounded or request-controlled collections;
tags should name entities (`product-42-reviews`), not rows or visitors.

Entries written by package versions before tag support live under a different Redis key namespace
(the storage-format generation is part of the cache key). After upgrading, those old entries are
simply never read again: they expire via their own TTLs. If you used `revalidate: 0` (no TTL) with
shared storage, delete the leftovers manually — they match `rorp:rsc-cache:` WITHOUT the `2:`
generation segment (scan with your `keyPrefix` applied, for example
`SCAN 0 MATCH <keyPrefix>rorp:rsc-cache:[0-9a-f][0-9a-f]*` — the doubled hex class is what
excludes live keys: a current-generation key has `2:` there, and `:` fails the second class).

React on Rails Pro's Ruby fragment-caching helpers have a separate `cache_tags:` and
`ReactOnRailsPro.revalidate_tag` API. That API invalidates Rails fragment-cache entries; it does not
invalidate entries created by JavaScript `unstable_cache`.

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

The cache key includes the build ID, function ID, and function arguments. Arguments must use the
supported deterministic value types. Supported built-in instances include `Date`, `Map`, and `Set`.
Circular references, functions, symbols, and arbitrary custom class instances are not supported.

## Use Shared Storage

The default cache is process-local. Separate Node Renderer workers do not share its entries. For a
shared cache, install the optional `ioredis` peer dependency and register `RedisCacheHandler`:

```tsx
import { RedisCacheHandler, registerCacheHandler, unstable_cache } from 'react-on-rails-pro/cache';

registerCacheHandler('redis', new RedisCacheHandler({ redisUrl: process.env.REDIS_URL }));

const ProductCard = unstable_cache(renderProductCard, {
  id: 'product-card',
  kind: 'redis',
  revalidate: 60,
});
```

You can also implement the exported `CacheHandler` interface and register it with
`registerCacheHandler(kind, handler)`. A handler implements asynchronous `get(key)` and
`set(key, entry)` methods. `TieredCacheHandler` can compose handlers as L1 and L2 caches.

Custom handlers must enforce the entry lifetime: return `null` from `get` for stale entries based on
`entry.timestamp` and `entry.revalidate`, or enforce expiry with the storage backend's TTL.
`unstable_cache` replays any non-null entry returned by `get`; it does not check expiry itself.

## Invalidation Limits

The RSC cache API does not currently provide tag-based invalidation. In particular, it does not
export `unstable_revalidateTag`, expose a Node Renderer tag-invalidation endpoint, or provide a Ruby
`ReactOnRailsPro::RSCCache` bridge. The `CacheHandler` interface also has no delete method.

Use a finite `revalidate` interval when data can change. Include all data that distinguishes the
rendered result in the cached function arguments. A new application build uses a new build-scoped
cache key, but it does not invalidate entries within the running build.

React on Rails Pro's Ruby fragment-caching helpers have a separate `cache_tags:` and
`ReactOnRailsPro.revalidate_tag` API. That API invalidates Rails fragment-cache entries; it does not
invalidate entries created by JavaScript `unstable_cache`.

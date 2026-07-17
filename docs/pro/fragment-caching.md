# Fragment Caching

Fragment caching is a React on Rails Pro feature that caches the complete rendered output of a React component — including the cost of computing props from the database, serializing them to JSON, and evaluating JavaScript. On a cache hit, none of that work happens.

> **Route map**: Start at [React on Rails Pro](./react-on-rails-pro.md) if you're choosing a path. This page is the canonical fragment caching overview; for the lower-level cache settings and tradeoffs, see the [SSR caching guide](../oss/building-features/caching.md) and [Pro configuration docs](../oss/configuration/configuration-pro.md).

## Why Fragment Caching?

Every server-rendered React component involves multiple expensive steps:

1. **Database queries** to assemble the props
2. **JSON serialization** of the props hash
3. **JavaScript evaluation** to produce the rendered HTML
4. **HTML assembly** to combine the rendered output with hydration data

Fragment caching skips all four steps when the cache is warm. This is different from prerender caching, which only skips step 3.

## The Two Levels of SSR Caching

|                            | Prerender Caching                   | Fragment Caching                                                      |
| -------------------------- | ----------------------------------- | --------------------------------------------------------------------- |
| **What it caches**         | JavaScript evaluation result        | Everything: props assembly, serialization, JS evaluation, HTML output |
| **Setup effort**           | One config line                     | Choose cache keys, pass props as a block                              |
| **Skips prop evaluation?** | No                                  | Yes                                                                   |
| **Best for**               | Quick win with minimal code changes | Maximum performance on high-traffic pages                             |

**Recommendation**: Start with prerender caching (`config.prerender_caching = true`), then add fragment caching to your most expensive components.

Prerender caching does not apply to `stream_react_component_with_async_props` or other async-props renders. Those
renders can include per-request async output that is not represented in the prerender cache key, so React on Rails Pro
renders them uncached on that layer. For async-props pages, use fragment-caching helpers only around content with an
explicit cache key that is safe to share across requests, or leave the async stream uncached.

## Usage

Use `cached_react_component` instead of `react_component`. The key differences:

1. Props are passed as a **block** so they're only evaluated on cache miss
2. You provide a `cache_key` (same as Rails fragment caching)

```erb
<%= cached_react_component("App", cache_key: [@user, @post], prerender: true) do
  some_slow_method_that_returns_props
end %>
```

A `cached_react_component_hash` variant is also available for cases where you need to extract metadata (like `<title>`) from the rendered output.

### Additional Cached Helpers

React on Rails Pro provides additional cached helpers for streaming, async, and RSC rendering. All share the same caching options (`cache_key`, `cache_tags`, `cache_options`, `:if`/`:unless`) as `cached_react_component`:

| Helper                                   | Use case                                                                 | Prerequisites                                                        |
| ---------------------------------------- | ------------------------------------------------------------------------ | -------------------------------------------------------------------- |
| `cached_stream_react_component`          | Cache streamed React 18 components with Suspense                         | Requires `stream_view_containing_react_components`                   |
| `cached_buffered_stream_react_component` | Cache streamed output as buffered HTML (no streaming setup needed)       | —                                                                    |
| `cached_static_rsc_component`            | Cache static RSC pages with sidecar packs (strips RSC bootstrap scripts) | Requires `enable_rsc_support = true`                                 |
| `cached_async_react_component`           | Cache async-rendered components                                          | Requires `AsyncRendering` concern and `enable_async_react_rendering` |

```erb
<%# Streaming with caching %>
<%= cached_stream_react_component("StreamedApp", cache_key: [@user]) do
  { user: @user.to_props }
end %>

<%# Buffered streaming (no ActionController::Live needed) %>
<%= cached_buffered_stream_react_component("BufferedApp", cache_key: [@post]) do
  { post: @post.to_props }
end %>

<%# Static RSC (strips hydration scripts for fully static pages) %>
<%= cached_static_rsc_component("StaticPage", cache_key: [@page]) do
  { page: @page.to_props }
end %>

<%# Async rendering with caching (cache hits return immediately) %>
<% card = cached_async_react_component("ProductCard", cache_key: [@product]) { @product.to_props } %>
<%= card.value %>
```

### Rails Context And Render Order

Fragment-cached helpers cache the final rendered HTML. That HTML includes the Rails context tag only when the helper call that populated the cache was the first component render in that request. If the same cached fragment is later served in a different view order, the page can either miss the Rails context tag or include a duplicate one.

Keep a stable render order for pages that share a cached component key. If a component may be the only React root on some pages and not others, use distinct cache keys for those layouts or render an uncached React root first so the Rails context ownership is explicit.

## Tag-Based Revalidation

Cache keys handle "is this entry still current?" at read time. For the write side — "this record changed, bust every cached component that depends on it" — tag the entries and revalidate by tag (the React on Rails Pro analog of Next.js `revalidateTag`):

```erb
<%= cached_react_component("PostShow",
      cache_key: [@post, I18n.locale],
      cache_tags: [@post],
      cache_options: { expires_in: 12.hours }) do
      { post: @post.to_props }
    end %>
```

```ruby
ReactOnRailsPro.revalidate_tag(post) # deletes every entry tagged with post.cache_key
```

Or let the model own its invalidation via `after_commit`:

```ruby
class Post < ApplicationRecord
  include ReactOnRailsPro::Cache::Revalidates

  revalidates_react_cache # default tag: record.cache_key, e.g. "posts/42"
end
```

Tag revalidation is best-effort and bounded by `expires_in` — always set it on tagged entries, and use a shared cache store (Redis/Memcached) in production. If a cache store raises while deleting tagged entries, the tag index may already be cleared; any surviving entries can no longer be found by that tag and will only drain through their own expiry. See the [Tag-Based Revalidation section](../oss/building-features/caching.md#tag-based-revalidation) of the caching guide for the full contract, tag normalization rules, index configuration, and the Next.js `revalidateTag` mapping.

ActiveRecord-style tag objects normalize to `collection/id` (for example `posts/42`) before they are indexed. Pass an explicit String tag if a value object exposes `model_name` and `id` but should use a custom key.

## Cache Warming

Every deploy creates new cache keys for prerendered components (because the server bundle digest, and the RSC bundle digest when RSC support is enabled and the RSC bundle exists, are included in the cache key when `prerender: true`). For client-only cached components, version your own cache key to invalidate on deploy. To avoid a storm of cold-cache misses under live traffic, warm your highest-traffic pages in background jobs immediately after deploy.

See the [Cache Warming section](../oss/building-features/caching.md#cache-warming) in the caching guide for implementation patterns and real-world results.

## Further Reading

- [SSR Caching guide](../oss/building-features/caching.md) — Full API reference, cache key strategies, debugging, and cache warming
- [Configuration](../oss/configuration/configuration-pro.md) — Enable prerender caching and other Pro config options

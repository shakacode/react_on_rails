# Fragment Caching

Fragment caching is a React on Rails Pro feature that caches the complete rendered output of a React component — including the cost of computing props from the database, serializing them to JSON, and evaluating JavaScript. On a cache hit, none of that work happens.

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

## Cache Warming

Every deploy creates new cache keys for prerendered components (because the server bundle digest is included in the cache key when `prerender: true`). For client-only cached components, version your own cache key to invalidate on deploy. To avoid a storm of cold-cache misses under live traffic, warm your highest-traffic pages in background jobs immediately after deploy.

See the [Cache Warming section](../oss/building-features/caching.md#cache-warming) in the caching guide for implementation patterns and real-world results.

## Further Reading

- [SSR Caching guide](../oss/building-features/caching.md) — Full API reference, cache key strategies, debugging, and cache warming
- [Configuration](../oss/configuration/configuration-pro.md) — Enable prerender caching and other Pro config options

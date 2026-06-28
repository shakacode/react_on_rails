# Ruby API (Pro)

> **Pro Feature** — Available with [React on Rails Pro](../../pro/react-on-rails-pro.md).
> Free or very low cost for startups and small companies. [Upgrade or licensing details →](../../pro/upgrading-to-pro.md#try-pro-risk-free)

## View Helpers

These helpers are available in Rails views when `react_on_rails_pro` is installed. They extend the base `react_component` and `react_component_hash` helpers from the OSS gem.

### `cached_react_component(component_name, options = {}, &block)`

Fragment-cached version of `react_component`. Skips prop evaluation and rendering when the cache is hit.

**Key differences from `react_component`:**

1. Props must be passed as a block (so evaluation is deferred on cache hit)
2. `cache_key` option is required
3. Optional `cache_options` for Rails cache settings (`:expires_in`, `:compress`, `:race_condition_ttl`)
4. Optional `:if` / `:unless` for conditional caching

```ruby
<%= cached_react_component("App",
      cache_key: [@user, @post],
      prerender: true) do
  { user: @user.as_json, post: @post.as_json }
end %>
```

### `cached_react_component_hash(component_name, options = {}, &block)`

Fragment-cached version of `react_component_hash`. Automatically sets `prerender: true` (required because the hash return value splits server-rendered HTML from the console replay script). Returns a hash with `"html"` and `"consoleReplayScript"` keys.

Same caching options as `cached_react_component`.

```ruby
<% result = cached_react_component_hash("App",
              cache_key: [@user, @post]) do
  { user: @user.as_json }
end %>
<%= result["html"] %>
<%= content_for :script_tags, result["consoleReplayScript"] %>
```

### `stream_react_component(component_name, options = {})`

Streams a server-rendered React component using React 18's `renderToPipeableStream`. Enables progressive rendering with Suspense boundaries.

Requires the controller to use `stream_view_containing_react_components`.

`stream_react_component` forces `prerender: true`; passing `prerender: false` has no effect. Common options mirror `react_component`, including `props`, `id`, `html_options`, `trace`, and `raise_on_prerender_error`.

> **Note (Pro):** React on Rails Pro hydrates streamed components early (before `DOMContentLoaded`) automatically — no per-component toggle is exposed.

```ruby
<%= stream_react_component("App", props: { data: @data }) %>
```

### `buffered_stream_react_component(component_name, options = {})`

Renders through the same streaming/RSC renderer as `stream_react_component`, but buffers every chunk and returns the complete HTML string to Rails. Use this for public, static, or cacheable pages where all props are available before rendering and progressive flushing is not needed.

Unlike `stream_react_component`, this helper does not require the controller to use `stream_view_containing_react_components`.

`buffered_stream_react_component` forces `prerender: true`; passing `prerender: false` has no effect. Common options mirror `stream_react_component`, including `props`, `id`, `html_options`, `trace`, and `raise_on_prerender_error`.

```ruby
<%= buffered_stream_react_component("MarketingPage",
      props: @marketing_page_props,
      id: "marketing-page") %>
```

### `stream_react_component_with_async_props(component_name, options = {}, &block)`

Async-props variant of `stream_react_component`. Use this when the view has synchronous props plus slower values that should stream to React behind Suspense boundaries.

Use this helper for RSC Server Components with `config.enable_rsc_support = true`. For non-RSC streaming SSR, use `stream_react_component`.

Requires the controller to use `stream_view_containing_react_components`, same as `stream_react_component`.

This helper accepts the same options as `stream_react_component`, plus a block that receives an emitter. Call `emit.call(prop_name, value)` for each async prop as it becomes available. RSC Server Components read emitted values through the injected `getReactOnRailsAsyncProp` prop.

For the complete React component pattern using `WithAsyncProps` and `getReactOnRailsAsyncProp`, see [Data Fetching in React on Rails Pro](../migrating/rsc-data-fetching.md#data-fetching-in-react-on-rails-pro).

```ruby
<%= stream_react_component_with_async_props("ProductPage",
      props: { name: @product.name, price: @product.price }) do |emit|
  emit.call("reviews", @product.reviews.as_json(only: [:id, :text, :rating]))
end %>
```

> [!IMPORTANT]
> `stream_react_component_with_async_props` requires `config.enable_rsc_support = true` and always forces `prerender: true`; passing `prerender: false` has no effect. The emitter block runs normal Ruby code sequentially, so `emit.call` does **not** parallelize slow queries by itself. For independent slow data sources, start the work concurrently before emitting values; see [Avoiding Server-Side Waterfalls](../migrating/rsc-data-fetching.md#avoiding-server-side-waterfalls).

### `cached_stream_react_component(component_name, options = {}, &block)`

Fragment-cached version of `stream_react_component`. Cache hits replay stored chunks without re-rendering.

Same caching options as `cached_react_component`.

### `cached_buffered_stream_react_component(component_name, options = {}, &block)`

Fragment-cached version of `buffered_stream_react_component`. Cache hits return the complete buffered HTML string without evaluating the props block or re-rendering in Node.

Same caching options as `cached_react_component`.

```ruby
<%= cached_buffered_stream_react_component("MarketingPage",
      cache_key: ["marketing-page", I18n.locale],
      cache_tags: ["marketing-page"],
      cache_options: { expires_in: 30.minutes },
      id: "marketing-page") do
  @marketing_page_props
end %>
```

### `rsc_payload_react_component(component_name, options = {})`

Renders the React Server Component payload as NDJSON. Each line contains:

- `html` — the RSC payload
- `consoleReplayScript` — server-side console log replay
- `hasErrors` — boolean
- `isShellReady` — boolean

Requires `enable_rsc_support = true` in configuration. This helper is normally used by `rsc_payload_route`; call it directly only when you need custom RSC payload rendering.

Common options include `props`, `trace`, and `id`. The helper forces `prerender: true`; passing `prerender: false` has no effect.

```ruby
<%= rsc_payload_react_component("RSCPage", props: { id: @post.id }) %>
```

### `rsc_payload_react_component_with_async_props(component_name, options = {}, &block)`

Async-props variant of `rsc_payload_react_component`. Use this only when custom RSC payload rendering needs Rails-emitted async props, such as an overridden payload route or template. For standard streamed ERB views, use `stream_react_component_with_async_props`.

Requires `enable_rsc_support = true` in configuration, same as `rsc_payload_react_component`.

This helper accepts the same options as `rsc_payload_react_component`, plus a block that receives an emitter. Call `emit.call(prop_name, value)` for each async prop.

```ruby
<%= rsc_payload_react_component_with_async_props("ProductPage",
      props: { name: @product.name, price: @product.price }) do |emit|
  emit.call("reviews", @product.reviews.as_json(only: [:id, :text, :rating]))
end %>
```

> [!IMPORTANT]
> `rsc_payload_react_component_with_async_props` requires `config.enable_rsc_support = true` and always forces `prerender: true`; passing `prerender: false` has no effect. The emitter block runs normal Ruby code sequentially, so `emit.call` does **not** parallelize slow queries by itself. For independent slow data sources, start the work concurrently before emitting values; see [Avoiding Server-Side Waterfalls](../migrating/rsc-data-fetching.md#avoiding-server-side-waterfalls).

### `async_react_component(component_name, options = {})`

Renders a component asynchronously, returning an `AsyncValue`. Multiple calls execute concurrently.

Requires the controller to include `ReactOnRailsPro::AsyncRendering` and call `enable_async_react_rendering`.

```ruby
<% header = async_react_component("Header", props: @header_props) %>
<% sidebar = async_react_component("Sidebar", props: @sidebar_props) %>
<!-- Both render concurrently -->
<%= header.value %>
<%= sidebar.value %>
```

### `cached_async_react_component(component_name, options = {}, &block)`

Combines async rendering with fragment caching. Cache lookup is synchronous — hits return immediately, misses trigger async render and cache the result.

```ruby
<% card = cached_async_react_component("ProductCard",
            cache_key: @product) { @product.to_props } %>
<%= card.value %>
```

## Utility Methods

### `ReactOnRailsPro::Utils`

| Method                                   | Description                                                           |
| ---------------------------------------- | --------------------------------------------------------------------- |
| `rsc_bundle_js_file_path`                | Resolved path to the RSC bundle file                                  |
| `react_client_manifest_file_path`        | Resolved path to the React client manifest                            |
| `react_server_client_manifest_file_path` | Resolved path to the server-client manifest                           |
| `rsc_support_enabled?`                   | Whether RSC support is enabled in configuration                       |
| `license_status`                         | Current license status (`:valid`, `:expired`, `:invalid`, `:missing`) |
| `bundle_hash`                            | Cache-key component based on server bundle content                    |
| `rsc_bundle_hash`                        | Cache-key component based on RSC bundle content                       |
| `server_bundle_file_name`                | Hashed filename of the server bundle (for cache keys)                 |
| `digest_of_globs(globs)`                 | MD5 digest of files matching the given glob patterns                  |
| `copy_assets`                            | Copies configured `assets_to_copy` to the node renderer               |

## Source

- [View Helpers](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails_pro/app/helpers/react_on_rails_pro_helper.rb)
- [Utils](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails_pro/lib/react_on_rails_pro/utils.rb)

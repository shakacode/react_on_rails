# Ruby API (Pro)

> **Pro Feature** — Available with [React on Rails Pro](https://pro.reactrails.com).
> Free for evaluation and startups. [Get a license →](mailto:justin@shakacode.com)

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

Options: same as `react_component` plus:

- `:immediate_hydration` (default: `true`) — controls hydration timing

```ruby
<%= stream_react_component("App", props: { data: @data }) %>
```

### `cached_stream_react_component(component_name, options = {}, &block)`

Fragment-cached version of `stream_react_component`. Cache hits replay stored chunks without re-rendering.

Same caching options as `cached_react_component`.

### `rsc_payload_react_component(component_name, options = {})`

Renders the React Server Component payload as NDJSON. Each line contains:

- `html` — the RSC payload
- `consoleReplayScript` — server-side console log replay
- `hasErrors` — boolean
- `isShellReady` — boolean

Requires `enable_rsc_support = true` in configuration.

```ruby
<%= rsc_payload_react_component("RSCPage", props: { id: @post.id }) %>
```

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

- [View Helpers](https://github.com/shakacode/react_on_rails/blob/master/react_on_rails_pro/app/helpers/react_on_rails_pro_helper.rb)
- [Utils](https://github.com/shakacode/react_on_rails/blob/master/react_on_rails_pro/lib/react_on_rails_pro/utils.rb)

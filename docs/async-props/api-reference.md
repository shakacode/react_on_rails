# Async Props API Reference

Complete reference for the Async Props API.

## View Helpers

### `stream_react_component_with_async_props(component_name, options = {}, &props_block)`

Streams a React component and exposes async props to the component via `getReactOnRailsAsyncProp`.
The block should return a hash of async props to evaluate and stream.

```erb
<%= stream_react_component_with_async_props("Dashboard", props: { title: "Dashboard" }) do
  {
    users: User.active.limit(10),
    posts: Post.recent.limit(5)
  }
end %>
```

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `component_name` | String | Name of the registered React component |
| `options` | Hash | Same options as `stream_react_component` (for example `props`, `dom_id`, `html_options`, `trace`) |
| `props_block` | Proc | Returns a hash of async props to stream |

> **Status:** Per-prop `timeout:` and `on_error:` are not implemented in the current release. Handle those concerns inside the block or with the global `ssr_timeout`.

### `rsc_payload_react_component_with_async_props(component_name, options = {}, &props_block)`

Same async-prop block contract, but renders the RSC payload stream instead of the HTML stream.

```erb
<%= rsc_payload_react_component_with_async_props("Dashboard") do
  { users: User.active.limit(10) }
end %>
```

## React Component Props

### `getReactOnRailsAsyncProp`

Async prop accessor injected into components rendered through the async-props helpers. The function returns the same Promise on repeated calls for the same prop name.

```tsx
async function UsersList({ getReactOnRailsAsyncProp }) {
  const users = await getReactOnRailsAsyncProp<User[]>('users');

  return (
    <ul>
      {users.map((user) => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}
```

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `propName` | string | Name of the async prop to retrieve |

#### Returns

A Promise for the resolved value of the async prop. Repeated calls share the same underlying promise so React can suspend and resume consistently.

## Configuration

```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.server_renderer = "NodeRenderer"
  config.enable_rsc_support = true
  config.tracing = true
  config.ssr_timeout = 5
  config.renderer_http_pool_size = 10
  config.renderer_http_pool_timeout = 5
  config.renderer_http_pool_warn_timeout = 0.25
end
```

The following options are **not** part of the current release and should not be documented as active APIs: `node_renderer_timeout`, `async_props_default_timeout`, `async_props_parallel_limit`, and `trace_async_props`.

## NDJSON Protocol

The async-props pipeline uses NDJSON between Rails and the Node renderer.

### Request Flow (Rails → Node)

```json
{"renderingRequest": "{\"componentName\":\"App\",\"props\":{...}}"}
{"resolvedAsyncProp": {"propName": "users", "value": [{"id": 1, "name": "Alice"}]}}
{"resolvedAsyncProp": {"propName": "posts", "value": [{"id": 1, "title": "Hello"}]}}
{"requestEnded": true}
```

### Response Flow (Node → Rails)

```json
{"html": "<!DOCTYPE html><html>..."}
{"consoleReplayScript": "<script>..."}
{"renderingFinished": true}
```

## TypeScript Types

```ts
import type { WithAsyncProps } from 'react-on-rails';

type AsyncProps = {
  users: User[];
  posts: Post[];
};

type SyncProps = {
  title: string;
};

type Props = WithAsyncProps<AsyncProps, SyncProps>;
```

## Next Steps

- [Advanced Usage](./advanced-usage.md) - Error handling, caching, optimization
- [How It Works](./how-it-works.md) - Deep dive into the architecture

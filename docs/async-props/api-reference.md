# Async Props API Reference

Complete reference for the Async Props API.

## Controller Helpers

### `async_prop`

Wraps a block that will be evaluated asynchronously and streamed to the renderer.

```ruby
async_prop { expression }
async_prop(options) { expression }
```

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `block` | Block | The code to evaluate asynchronously |

> **Status:** Per-prop `:timeout` and `:on_error` are not implemented in the current release. Use this page as the contract for the async prop flow, not as a promise that those helper options already exist.

### `render_component`

Renders a React component with support for async props.

```ruby
render_component(component_name, props:, options = {})
```

#### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `component_name` | String | Name of the registered React component |
| `props` | Hash | Props to pass to the component (can include `async_prop` values) |
| `options` | Hash | Additional rendering options |

#### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:prerender` | Boolean | `true` | Enable server-side rendering |
| `:streaming` | Boolean | `true` | Enable streaming SSR (requires prerender) |
| `:trace` | Boolean | `false` | Enable performance tracing |

## React Component Props

### `getReactOnRailsAsyncProp`

Async prop accessor injected into Server Components by `addAsyncPropsCapabilityToComponentProps()`.
The function returns the same Promise on repeated calls for the same prop name.

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

The resolved value of the async prop. The promise is shared across repeated calls so React can suspend and resume consistently.

## Configuration

### Rails Configuration

```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  # Node renderer settings
  config.node_renderer_pool_size = 4
  config.node_renderer_timeout = 30

  # Async props settings
  config.async_props_default_timeout = 30
  config.async_props_parallel_limit = 10

  # Logging
  config.logging_level = :info  # :debug, :info, :warn, :error
end
```

### Node Renderer Configuration

```javascript
// config/react_on_rails_pro.js
module.exports = {
  // Streaming settings
  streamingSSR: true,
  shellTimeout: 5000,  // ms to wait for shell before fallback

  // AsyncPropsManager settings
  asyncPropsTimeout: 30000,  // ms per async prop

  // Error handling
  onRenderError: (error, componentName) => {
    console.error(`Render error in ${componentName}:`, error);
  }
};
```

## NDJSON Protocol

### Message Types

#### Render Request (Rails → Node)

```json
{
  "renderingRequest": "{\"componentName\":\"App\",\"props\":{...}}"
}
```

#### Resolved Async Prop (Rails → Node)

```json
{
  "resolvedAsyncProp": {
    "propName": "users",
    "value": [{"id": 1, "name": "Alice"}]
  }
}
```

#### Request Ended (Rails → Node)

```json
{
  "requestEnded": true
}
```

#### Request Closed Update (Rails → Node)

```json
{
  "onRequestClosedUpdateChunk": {
    "type": "error",
    "message": "Client disconnected"
  }
}
```

### Response Types

#### HTML Chunk (Node → Rails)

```json
{
  "html": "<div>...</div>"
}
```

#### Console Replay (Node → Rails)

```json
{
  "consoleReplayScript": "<script>console.log(...)</script>"
}
```

#### Render Complete (Node → Rails)

```json
{
  "renderingFinished": true
}
```

## TypeScript Types

```typescript
interface AsyncProp<T> {
  propName: string;
  promise: Promise<T>;
  resolved: boolean;
  value?: T;
}

interface AsyncPropsManagerOptions {
  timeout?: number;
  onError?: (error: Error, propName: string) => void;
}

interface RenderRequest {
  componentName: string;
  props: Record<string, unknown>;
  asyncProps: string[];  // Names of props that are async
}

interface UpdateChunk {
  type: 'resolvedAsyncProp' | 'error' | 'requestClosed';
  propName?: string;
  value?: unknown;
  message?: string;
}
```

## Error Codes

| Code | Description |
|------|-------------|
| `ASYNC_PROP_TIMEOUT` | Async prop did not resolve within timeout |
| `ASYNC_PROP_ERROR` | Error during async prop evaluation |
| `STREAM_CLOSED` | NDJSON stream closed unexpectedly |
| `RENDER_ERROR` | React rendering error |
| `HYDRATION_MISMATCH` | Server/client HTML mismatch |

## Next Steps

- [Advanced Usage](./advanced-usage.md) - Error boundaries, caching, optimization
- [How It Works](./how-it-works.md) - Deep dive into the architecture

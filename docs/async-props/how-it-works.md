# How Async Props Works

This document provides a deep dive into the streaming architecture that powers Async Props.

## The Streaming Pipeline

Async Props creates a bidirectional streaming connection between Rails and the Node renderer using NDJSON (Newline-Delimited JSON).

```
┌─────────────┐    NDJSON Stream    ┌─────────────┐    HTTP Stream    ┌─────────────┐
│   Rails     │ ←─────────────────→ │    Node     │ ───────────────→ │   Browser   │
│   Server    │                     │  Renderer   │                   │             │
└─────────────┘                     └─────────────┘                   └─────────────┘
```

### Phase 1: Request Initialization

When a request hits your Rails view:

1. **Rails view helper evaluates regular props** immediately
2. **Async props are wrapped** in the block passed to `stream_react_component_with_async_props` (not executed yet)
3. **NDJSON stream opens** to Node renderer
4. **Render request sent** with component name, sync props, and async prop definitions

```ruby
# In your view
<%= stream_react_component_with_async_props("Dashboard", props: {
  title: "Dashboard"           # Immediate: sent in initial request
}) do
  {
    users: User.active,        # Deferred: streamed when ready
    posts: Post.recent         # Deferred: streamed when ready
  }
end %>
```

### Phase 2: Shell Rendering

The Node renderer:

1. **Receives the render request** with prop definitions
2. **Creates React Suspense boundaries** for async props
3. **Renders the shell** using `renderToPipeableStream()`
4. **Sends shell HTML** to browser immediately

```jsx
// React component with Suspense
<Layout>
  <Header title={title} />
  <Suspense fallback={<Skeleton />}>
    <Users users={users} />  {/* Shows skeleton initially */}
  </Suspense>
</Layout>
```

### Phase 3: Parallel Data Fetching

Back on the Rails side:

1. **Async prop blocks execute** in parallel (not sequentially!)
2. **Each resolved value** is serialized and streamed
3. **NDJSON chunks** are sent to Node as they complete

```json
{"resolvedAsyncProp": {"propName": "users", "value": [...]}}
{"resolvedAsyncProp": {"propName": "posts", "value": [...]}}
```

### Phase 4: Progressive Hydration

As each async prop arrives:

1. **Node renderer receives** the resolved value
2. **Async prop state caches** the value
3. **React Suspense boundary** resolves
4. **HTML chunk streams** to browser
5. **React hydrates** the new content

## The NDJSON Protocol

NDJSON (Newline-Delimited JSON) enables bidirectional streaming:

### Request Flow (Rails → Node)

```json
{"renderingRequest": "{\"componentName\":\"Dashboard\",\"props\":{...}}"}
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

## Async Prop Resolution

Async prop resolution happens internally on the Node side. The public API exposed to components is the `getReactOnRailsAsyncProp` prop:

```tsx
async function Dashboard({ getReactOnRailsAsyncProp }) {
  const users = await getReactOnRailsAsyncProp('users');
  const posts = await getReactOnRailsAsyncProp('posts');
}
```

## Execution Context Isolation

Each HTTP request gets its own isolated execution context:

- **Separate VM context** for global isolation
- **Own internal async-props state**
- **Independent Suspense boundaries**
- **No cross-request data leakage**

## Error Handling

Errors are handled gracefully at each stage:

### Rails-side Errors

```ruby
<%= stream_react_component_with_async_props("Dashboard") do
  {
    users: begin
      User.active
    rescue => e
      { error: e.message }  # Streams error as resolved value
    end
  }
end %>
```

### Node-side Errors

- **Parse errors**: Logged and reported
- **Render errors**: Captured by error boundaries
- **Stream errors**: Connection closed gracefully

## Performance Characteristics

| Operation | Latency |
|-----------|---------|
| NDJSON stream setup | ~5ms |
| Shell render | ~20-50ms |
| Async prop serialization | ~1-5ms per prop |
| React hydration | ~10-50ms per boundary |

### Why Parallel is Faster

Traditional SSR:
```
Fetch Users (800ms) → Fetch Posts (600ms) → Render (200ms) = 1600ms total
```

Async Props:
```
Shell Render (50ms) ──────────────────────────────────────→ TTFB: 50ms
├── Fetch Users (800ms) ─→ Stream ─→ Hydrate
└── Fetch Posts (600ms) ─→ Stream ─→ Hydrate
                                      Total: 900ms (after TTFB)
```

## Debugging Tips

### Enable Verbose Logging

```ruby
# config/initializers/react_on_rails_pro.rb
ReactOnRailsPro.configure do |config|
  config.tracing = true
end
```

### Inspect NDJSON Stream

```bash
# In development, you can see the stream in your Rails logs
tail -f log/development.log | grep NDJSON
```

### React DevTools

Use React DevTools to see Suspense boundaries and their states during hydration.

## Next Steps

- [API Reference](./api-reference.md) - Complete configuration options
- [Advanced Usage](./advanced-usage.md) - Caching, timeouts, and optimization

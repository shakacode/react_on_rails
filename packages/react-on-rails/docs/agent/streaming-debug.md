# Streaming SSR debugging (Pro)

Streaming requires React on Rails Pro and the Node renderer. First determine whether the selected
helper is progressive or intentionally buffered.

## Debug in boundary order

1. Run `bin/rails react_on_rails:doctor FORMAT=json` and resolve configuration or dependency errors.
2. Identify the exact helper before applying streaming prerequisites.

## Progressive helpers

For `stream_react_component`, `cached_stream_react_component`, and
`stream_react_component_with_async_props`:

1. Confirm the controller includes `ReactOnRailsPro::Stream`, the action enters the view through
   `stream_view_containing_react_components` instead of ordinary `render`, and the Node renderer
   is reachable.
2. When Suspense content should reveal progressively, confirm the boundary's child actually suspends.
3. For `stream_react_component_with_async_props` only, confirm
   `ReactOnRailsPro.configuration.enable_rsc_support` is enabled by setting
   `config.enable_rsc_support = true` in the Pro initializer.
   This is not a prerequisite for `stream_react_component` or `cached_stream_react_component`.
4. For async props, start slow work inside the streaming block, emit only JSON-serializable values,
   and emit or reject every prop the renderer requests.

## Buffered helpers

For `buffered_stream_react_component`, `cached_buffered_stream_react_component`, and
`cached_static_rsc_component`:

1. Confirm the Node renderer is reachable and inspect the complete buffered result.
2. These helpers do not require the streaming controller wrapper: they do not require
   `ReactOnRailsPro::Stream`, `stream_view_containing_react_components`, or a suspending boundary.
3. Only `cached_static_rsc_component` requires `config.enable_rsc_support = true`.
   `buffered_stream_react_component` and `cached_buffered_stream_react_component` do not require this setting.
4. Expect the browser to receive the page only after the renderer has produced the complete result;
   early shell flush and progressive Suspense reveal are not buffered-helper behavior.

## Debug either path

Probe the origin with buffering disabled in the client, then compare the same route through each
reverse proxy or CDN. Inspect response headers, chunk arrival, compression, Rails logs, Node
renderer logs, and browser timing marks.

A useful transport probe is:

```bash
curl --no-buffer --dump-header - https://your-app.example/streaming-route
```

If the origin streams but the public route buffers, fix the proxy/CDN boundary. If neither streams,
reduce to one Suspense boundary and one known-slow value before changing application architecture.

Secondary reference: https://reactonrails.com/docs/pro/streaming-ssr.

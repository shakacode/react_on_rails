---
name: streaming-debug
description: >
  Use when a React on Rails Pro streaming SSR or async-props response buffers,
  stalls, fails to reveal Suspense content, or behaves differently behind a proxy.
---

# Debug streaming SSR (Pro)

Streaming SSR is a React on Rails Pro workflow. Read the
[version-matched package guide](../../docs/agent/streaming-debug.md) before changing code.

1. Run `bin/rails react_on_rails:doctor FORMAT=json` and fix setup errors first.
2. Identify the exact helper before applying streaming prerequisites.

## Progressive helpers

For `stream_react_component`, `cached_stream_react_component`, and
`stream_react_component_with_async_props`:

1. Confirm the controller includes `ReactOnRailsPro::Stream`, the action calls
   `stream_view_containing_react_components`, and the Node renderer is healthy.
2. When Suspense content should reveal progressively, confirm the boundary's child actually suspends.
3. For `stream_react_component_with_async_props` only, confirm
   `ReactOnRailsPro.configuration.enable_rsc_support` is enabled by setting
   `config.enable_rsc_support = true` in the Pro initializer.
   This is not a prerequisite for `stream_react_component` or `cached_stream_react_component`.
4. For async props, keep slow work inside the streaming block, emit JSON-serializable values,
   and ensure every requested prop is emitted or rejected.

## Buffered helpers

For `buffered_stream_react_component`, `cached_buffered_stream_react_component`, and
`cached_static_rsc_component`:

1. Confirm the Node renderer is healthy and inspect the complete buffered result.
2. These helpers do not require the streaming controller wrapper: they do not require
   `ReactOnRailsPro::Stream`, `stream_view_containing_react_components`, or a suspending boundary.
3. For `cached_static_rsc_component`, set `config.enable_rsc_support = true`; disabling RSC support
   omits the RSC payload generation that gives this helper its static-RSC behavior.
   This setting is not a prerequisite for `buffered_stream_react_component` or
   `cached_buffered_stream_react_component`.
4. Do not expect early shell flush or progressive Suspense reveal from a buffered helper.

## Debug either path

1. Observe the response with an unbuffered client and compare origin behavior with the proxy/CDN path.
   Check compression and buffering configuration before changing React code.
2. Correlate Rails logs, Node renderer logs, response chunks, and browser timing marks; fix one
   demonstrated boundary at a time and rerun the same probe.

Hosted streaming docs are a secondary reference:
https://reactonrails.com/docs/pro/streaming-ssr.

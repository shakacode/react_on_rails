# Streaming Server Rendering

:::tip Pro Feature
SSR works in the OSS version via ExecJS. Pro adds streaming SSR with `renderToPipeableStream` and Suspense for progressive rendering. See the [Streaming SSR guide](../../pro/streaming-ssr.md) or [upgrade to Pro →](../../pro/upgrading-to-pro.md)
:::

React on Rails Pro supports streaming server rendering using React 18/19's `renderToPipeableStream` API. Instead of waiting for the entire page to render before sending any HTML, streaming SSR sends HTML to the browser progressively as each part of the page becomes ready.

## Why Streaming SSR?

Traditional SSR renders the full page on the server, then sends the complete HTML in one response. This means the user sees nothing until the slowest component finishes rendering. Streaming SSR changes this:

- **Faster Time to First Byte (TTFB)** — The browser receives the page shell immediately
- **Progressive rendering** — Content appears as it becomes ready, not all at once
- **Suspense integration** — React's `<Suspense>` boundaries define which parts can stream independently
- **Selective Hydration** — Components become interactive as soon as their JavaScript loads, even while other parts are still streaming

## How It Works

1. Rails starts the response immediately, sending the HTML shell (layout, static content, loading placeholders)
2. The Node Renderer uses `renderToPipeableStream` to render React components
3. As each `<Suspense>` boundary resolves (e.g., an async data fetch completes), the rendered HTML chunk is streamed to the browser
4. The browser replaces placeholders with real content — no full-page reload needed

## Quick Example

```jsx
import React, { Suspense } from 'react';

const ProductPage = () => (
  <>
    <Suspense fallback={<div>Loading details...</div>}>
      <ProductDetails />
    </Suspense>
    <Suspense fallback={<div>Loading reviews...</div>}>
      <ProductReviews />
    </Suspense>
  </>
);
```

```ruby
class ProductsController < ApplicationController
  include ActionController::Live
  include ReactOnRails::Controller
  include ReactOnRailsPro::Stream

  def show
    stream_view_containing_react_components(template: 'products/show')
  end
end
```

```erb
<%= stream_react_component('ProductPage', props: { id: @product.id }) %>
```

## Full Guide

For implementation steps, compression middleware compatibility, script loading strategies, metadata handling, immediate hydration, and best practices, see the [Streaming SSR guide](../../pro/streaming-ssr.md).

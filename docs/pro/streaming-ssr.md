# Streaming Server-Side Rendering

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

### React Component

```jsx
import React, { Suspense } from 'react';

const ProductPage = () => (
  <>
    <header>
      <h1>Product Details</h1>
    </header>
    <Suspense fallback={<div>Loading details...</div>}>
      <ProductDetails />
    </Suspense>
    <Suspense fallback={<div>Loading reviews...</div>}>
      <ProductReviews />
    </Suspense>
  </>
);

const ProductDetails = async () => {
  const data = await fetchProductDetails();
  return (
    <div>
      {data.name} — ${data.price}
    </div>
  );
};

const ProductReviews = async () => {
  const reviews = await fetchReviews();
  return (
    <ul>
      {reviews.map((r) => (
        <li key={r.id}>{r.text}</li>
      ))}
    </ul>
  );
};
```

### Rails Controller

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

### Rails View

```erb
<%= stream_react_component('ProductPage', props: { id: @product.id }) %>
```

## Prerequisites

- React on Rails Pro v4.0.0.rc.5 or higher
- React 19
- React on Rails v16.0.0 or higher
- Node Renderer running (streaming requires Node.js, not ExecJS)

## Further Reading

- [Streaming SSR implementation guide](../oss/building-features/streaming-server-rendering.md) — Full setup steps, compression middleware compatibility, metadata handling, and best practices
- [Node Renderer](./node-renderer.md) — Required for streaming SSR
- [React Server Components](./react-server-components/tutorial.md) — RSC builds on streaming SSR for even more advanced rendering

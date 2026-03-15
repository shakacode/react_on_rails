# 🚀 Streaming Server Rendering with React 18

React on Rails Pro supports streaming server rendering using React 18's latest APIs, including `renderToPipeableStream` and Suspense. This guide explains how to implement and optimize streaming server rendering in your React on Rails application.

## Prerequisites

- React on Rails Pro subscription
- React 19
- React on Rails v16.4.0 or higher
- React on Rails Pro v16.4.0 or higher

> [!NOTE]
> Pro version numbering was realigned to the core 16.x scheme; older docs may reference pre-16 aliases such as `v4.x`.

## Benefits of Streaming Server Rendering

- Faster Time to First Byte (TTFB)
- Progressive page loading
- Improved user experience
- Better SEO performance
- Optimal handling of data fetching

## Implementation Steps

1. **Use React 19 Version**

First, ensure you're using React 19 in your package.json:

```json
"dependencies": {
  "react": "19.0.0",
  "react-dom": "19.0.0"
}
```

> Note: Check the React documentation for the latest release that supports streaming.

2. **Prepare Your React Components**

You can create async React components that return a promise. Then, you can use the `Suspense` component to render a fallback UI while the component is loading.

```jsx
// app/javascript/components/MyStreamingComponent.jsx
import React, { Suspense } from 'react';

const fetchData = async () => {
  // Simulate API call
  const response = await fetch('api/endpoint');
  return response.json();
};

const MyStreamingComponent = () => {
  return (
    <>
      <header>
        <h1>Streaming Server Rendering</h1>
      </header>
      <Suspense fallback={<div>Loading...</div>}>
        <SlowDataComponent />
      </Suspense>
    </>
  );
};

const SlowDataComponent = async () => {
  const data = await fetchData();
  return <div>{data}</div>;
};

export default MyStreamingComponent;
```

```jsx
// app/javascript/packs/registration.jsx
import MyStreamingComponent from '../components/MyStreamingComponent';

ReactOnRails.register({ MyStreamingComponent });
```

3. **Add The Component To Your Rails View**

```erb
<!-- app/views/example/show.html.erb -->

<%=
  stream_react_component(
    'MyStreamingComponent',
    props: { greeting: 'Hello, Streaming World!' },
    prerender: true
  )
%>

<footer>
  <p>Footer content</p>
</footer>
```

4. **Render The View Using The `stream_view_containing_react_components` Helper**

Ensure you have a controller that renders the view containing the React components. The controller must include the `ReactOnRails::Controller`, `ReactOnRailsPro::Stream` and `ActionController::Live` modules.

```ruby
# app/controllers/example_controller.rb

class ExampleController < ApplicationController
  include ReactOnRailsPro::Stream

  def show
    stream_view_containing_react_components(template: 'example/show')
  end
end
```

5. **Test Your Application**

You can test your application by running `rails server` and navigating to the appropriate route.

6. **What Happens During Streaming**

When a user visits the page, they'll experience the following sequence:

1. The initial HTML shell is sent immediately, including:
   - The page layout
   - Any static content (like the `<h1>` and footer)
   - Placeholder content for the React component (typically a loading state)

2. As the React component processes and suspense boundaries resolve:
   - HTML chunks are streamed to the browser progressively
   - Each chunk updates a specific part of the page
   - The browser renders these updates without a full page reload

For example, with our `MyStreamingComponent`, the sequence might be:

1. The initial HTML includes the header, footer, and loading state.

```html
<header>
  <h1>Streaming Server Rendering</h1>
</header>
<template id="s0">
  <div>Loading...</div>
</template>
<footer>
  <p>Footer content</p>
</footer>
```

2. As the component resolves, HTML chunks are streamed to the browser:

```html
<template hidden id="b0">
  <div>[Fetched data]</div>
</template>

<script>
  // This implementation is slightly simplified
  document.getElementById('s0').replaceChildren(document.getElementById('b0'));
</script>
```

## Compression Middleware Compatibility

Streaming responses use `ActionController::Live`, which writes chunks to a `SizedQueue` (a destructive, non-idempotent data structure). Standard Rack compression middleware (`Rack::Deflater`, `Rack::Brotli`) works correctly with streaming **by default** — each chunk is compressed and flushed immediately, preserving low TTFB.

However, if you pass an `:if` condition that calls `body.each` to check the response size, **streaming responses will deadlock**. The `:if` callback destructively consumes all chunks from the queue, leaving nothing for the compressor to read.

```ruby
# BAD — causes deadlocks with streaming responses
config.middleware.use Rack::Deflater, if: lambda { |*, body|
  sum = 0
  body.each { |i| sum += i.length }  # destructive — drains the queue
  sum > 512
}
```

The [Rack SPEC](https://github.com/rack/rack/blob/main/SPEC.rdoc) states that `each` must only be called once and middleware must not call `each` directly unless the body responds to `to_ary`. Streaming bodies explicitly do not support `to_ary`.

**Correct pattern** — check `to_ary` before iterating:

```ruby
config.middleware.use Rack::Deflater, if: lambda { |*, body|
  # Streaming bodies don't support to_ary — always compress them.
  # Rack::Deflater handles streaming correctly with sync flush per chunk.
  return true unless body.respond_to?(:to_ary)

  body.to_ary.sum(&:bytesize) > 512
}
```

The same applies to `Rack::Brotli` or any middleware that accepts an `:if` callback.

## When to Use Streaming

Streaming SSR is particularly valuable in specific scenarios. Here's when to consider it:

### Ideal Use Cases

1. **Data-Heavy Pages**
   - Pages that fetch data from multiple sources
   - Dashboard-style layouts where different sections can load independently
   - Content that requires heavy processing or computation

2. **Progressive Enhancement**
   - When you want users to see and interact with parts of the page while others load
   - For improving perceived performance on slower connections
   - When different parts of your page have different priority levels

3. **Large, Complex Applications**
   - Applications with multiple independent widgets or components
   - Pages where some content is critical and other content is supplementary
   - When you need to optimize Time to First Byte (TTFB)

### Best Practices for Streaming

1. **Component Structure**

   ```jsx
   // Good: Independent sections that can stream separately
   <Layout>
     <Suspense fallback={<HeaderSkeleton />}>
       <Header />
     </Suspense>
     <Suspense fallback={<MainContentSkeleton />}>
       <MainContent />
     </Suspense>
     <Suspense fallback={<SidebarSkeleton />}>
       <Sidebar />
     </Suspense>
   </Layout>

   // Bad: Everything wrapped in a single Suspense boundary
   <Suspense fallback={<FullPageSkeleton />}>
     <Header />
     <MainContent />
     <Sidebar />
   </Suspense>
   ```

2. **Data Loading Strategy**
   - Prioritize critical data that should be included in the initial HTML
   - Use streaming for supplementary data that can load progressively
   - Consider implementing a waterfall strategy for dependent data

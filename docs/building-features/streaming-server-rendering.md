# 🚀 Streaming Server Rendering with React 18

React on Rails Pro supports streaming server rendering using React 18's latest APIs, including `renderToPipeableStream` and Suspense. This guide explains how to implement and optimize streaming server rendering in your React on Rails application.

## Prerequisites

- React on Rails Pro subscription
- React 19
- React on Rails v16.0.0 or higher
- React on Rails Pro v4.0.0.rc.5 or higher

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
  include ActionController::Live
  include ReactOnRails::Controller
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

### Script Loading Strategy for Streaming

**IMPORTANT**: When using streaming server rendering, you should NOT use `defer: true` for your JavaScript pack tags. Here's why:

#### Understanding the Problem with Defer

Deferred scripts (`defer: true`) only execute after the entire HTML document has finished parsing and streaming. This defeats the key benefit of React 18's Selective Hydration feature, which allows streamed components to hydrate as soon as they arrive—even while other parts of the page are still streaming.

**Example Problem:**

```erb
<!-- ❌ BAD: This delays hydration for ALL streamed components -->
<%= javascript_pack_tag('client-bundle', defer: true) %>
```

With `defer: true`, your streamed components will:

1. Arrive progressively in the HTML stream
2. Be visible to users immediately
3. But remain non-interactive until the ENTIRE page finishes streaming
4. Only then will they hydrate

#### Recommended Approaches

**For Pages WITH Streaming Components:**

```erb
<!-- ✅ GOOD: No defer - allows Selective Hydration to work -->
<%= javascript_pack_tag('client-bundle', 'data-turbo-track': 'reload', defer: false) %>

<!-- ✅ BEST: Use async for even faster hydration (requires Shakapacker 8.2+) -->
<%= javascript_pack_tag('client-bundle', 'data-turbo-track': 'reload', async: true) %>
```

**For Pages WITHOUT Streaming Components:**

```erb
<!-- ✅ OK: defer is fine when not using streaming -->
<%= javascript_pack_tag('client-bundle', 'data-turbo-track': 'reload', defer: true) %>
```

#### Why Async is Better Than No Defer

With Shakapacker 8.2+, using `async: true` provides the best performance:

- **No defer/async**: Scripts block HTML parsing and streaming
- **defer: true**: Scripts wait for complete page load (defeats Selective Hydration)
- **async: true**: Scripts load in parallel and execute ASAP, enabling:
  - Selective Hydration to work immediately
  - Components to become interactive as they stream in
  - Optimal Time to Interactive (TTI)

#### Migration Timeline

1. **Before Shakapacker 8.2**: Use `defer: false` for streaming pages
2. **After Shakapacker 8.2**: Migrate to `async: true` for streaming pages
3. **Non-streaming pages**: Can continue using `defer: true` safely

# 🚀 Streaming Server Rendering with React 18

React on Rails Pro supports streaming server rendering using React 18's latest APIs, including `renderToPipeableStream` and Suspense. This guide explains how to implement and optimize streaming server rendering in your React on Rails application.

## Prerequisites

- React on Rails Pro subscription
- React 18 or higher (experimental version)
- React on Rails v15.0.0-alpha.0 or higher

## Benefits of Streaming Server Rendering

- Faster Time to First Byte (TTFB)
- Progressive page loading
- Improved user experience
- Better SEO performance
- Optimal handling of data fetching

## Implementation Steps

1. **Use Experimental React 18 Version**

First, ensure you're using React 18's experimental version in your package.json:

```json
"dependencies": {
  "react": "18.3.0-canary-670811593-20240322",
  "react-dom": "18.3.0-canary-670811593-20240322"
}
```

2. **Prepare Your React Components**

You can create async React components that return a promise. Then, you can use the `Suspense` component to render a fallback UI while the component is loading.

```jsx
// app/javascript/components/MyStreamingComponent.jsx

import React, { Suspense } from 'react';

const MyStreamingComponent = () => {
  return (
    <header>
      <h1>Streaming Server Rendering</h1>
    </header>
    <Suspense fallback={<div>Loading...</div>}>
      <SlowDataComponent />
    </Suspense>
  );
};

const SlowDataComponent = async () => {
  const data = await fetchData();
  return <div>{data}</div>;
};

export default MyStreamingComponent;

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
  document.getElementById('s0').replaceChildren(
    document.getElementById('b0')
  );
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

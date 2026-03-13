# SSR React Server Components

Before reading this document, please read:

1. [Create React Server Component without SSR](./create-without-ssr.md)
2. [Add Streaming and Interactivity to RSC Page](./add-streaming-and-interactivity.md)

These documents provide essential background on React Server Components and how they work without Server Side Rendering (SSR).

## Update the React Server Component Page

Let's make React on Rails server-side render the React Server Component Page we created in the previous articles.

Update the `react_server_component_without_ssr.html.erb` view to pass `prerender: true` to the `react_component` helper.

```erb
<%= react_component("ReactServerComponentPage",
    prerender: true,
    trace: true,
    id: "ReactServerComponentPage-react-component-0") %>
```

Now, when you visit the page, you should see part of the React Server Component page rendered in the browser. Then, we get the error:

```
The server did not finish this Suspense boundary: The server used "renderToString" which does not support Suspense. If you intended for this Suspense boundary to render the fallback content on the server consider throwing an Error somewhere within the Suspense boundary. If you intended to have the server wait for the suspended component please switch to "renderToPipeableStream" which supports Suspense on the server
```

This error occurs because the `react_component` helper uses React's `renderToString` function, which renders the React page synchronously in a single pass. This approach isn't suitable for React Server Components, which can contain asynchronous operations and need progressive streaming of content.

Instead, we need to use the streaming capabilities provided by React on Rails Pro, as detailed in the [streaming server rendering documentation](../streaming-server-rendering.md). These helpers internally use React's `renderToPipeableStream` API, which supports:

1. Server-side rendering of async components
2. Progressive streaming of HTML chunks to the client as components finish rendering
3. Incremental hydration, where each component can be hydrated independently as it loads, rather than waiting for the entire application

To enable streaming SSR for React Server Components, we need to:

1. Create a new view called `react_server_component_ssr.html.erb` with the following content:

   ```erb
   # app/views/pages/react_server_component_ssr.html.erb
   <%= stream_react_component("ReactServerComponentPage",
       id: "ReactServerComponentPage-react-component-0") %>

   <h1>React Server Component with SSR</h1>
   ```

2. Ensure our controller includes `ReactOnRailsPro::Stream` and use the `stream_view_containing_react_components` helper to render the view:

   ```ruby
   # app/controllers/pages_controller.rb
   class PagesController < ApplicationController
     include ReactOnRailsPro::Stream

     def react_server_component_ssr
       stream_view_containing_react_components(template: "pages/react_server_component_ssr")
     end
   end
   ```

3. Add the route to `config/routes.rb`:

   ```ruby
   # config/routes.rb
   get "/react_server_component_ssr", to: "pages#react_server_component_ssr"
   ```

Now, when you visit the page, you should see the entire React Server Component page rendered in the browser. And if you viewed the page source, you should see the HTML being streamed to the browser.

## Next Steps

Now that you understand how to enable server-side rendering (SSR) for your React Server Components, you can proceed to the next article: [Selective Hydration in Streamed Components](selective-hydration-in-streamed-components.md) to learn about React's selective hydration feature and how it improves page interactivity.

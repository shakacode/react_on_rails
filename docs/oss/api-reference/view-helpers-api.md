# View and Controller Helpers

## View Helpers API

Once the bundled files have been generated in your `app/assets/webpack` folder, and you have registered your components, you will want to render these components on your Rails views using the included helper method, [`react_component`](#react_component).

---

### react_component

```ruby
react_component(component_name,
                props: {},
                prerender: nil,
                hydrate_on: :immediate,
                html_options: {})
```

Uncommonly used options:

```ruby
  trace: nil,
  replay_console: nil,
  raise_on_prerender_error: nil,
  id: nil,
```

- **component_name:** Can be a React component, created using a React Function Component, an ES6 class or a Render-Function that returns a React component (or, only on the server side, an object with shape `{ renderedHtml, clientProps?, redirectLocation?, routeError? }`), or a "renderer function" that manually renders a React component to the DOM (client-side only). Note, a "renderer function" is a special type of "Render-Function." A "renderer function" takes a 3rd param of a DOM ID.

  > If your render function returns a hash with multiple HTML strings (e.g., `{ renderedHtml: { componentHtml, title, metaTags } }`), `react_component` raises a `ReactOnRails::Error` telling you to use [`react_component_hash`](#react_component_hash) instead. `react_component` is for rendering a single HTML result; `react_component_hash` is for rendering multiple HTML strings to place in different parts of the page.

  All options except `props, id, html_options` will inherit from your `react_on_rails.rb` initializer, as described in the [configuration documentation](../configuration/README.md).

- **general options:**
  - **props:** Ruby Hash which contains the properties to pass to the React object, or a JSON string. If you pass a string, we'll escape it for you.
  - **prerender:** enable server-side rendering of a component. Set to false when debugging!
    - **Environment override:** set `REACT_ON_RAILS_PRERENDER_OVERRIDE=true|false` to force prerendering on or off globally.
      Precedence is: `REACT_ON_RAILS_PRERENDER_OVERRIDE` > component option (`prerender:`) > initializer default (`config.prerender`).
  - **auto_load_bundle:** will automatically load the bundle for component by calling `append_javascript_pack_tag` and `append_stylesheet_pack_tag` under the hood.
  - **hydrate_on:** controls when React hydrates or client-renders this root. Supported OSS modes are `:immediate` (default), `:visible`, and `:idle`. See [Hydration Scheduling](../building-features/hydration-scheduling.md). `:interaction` is not supported. Deferred modes are OSS-only; React on Rails Pro currently accepts only `:immediate`.
  - **id:** Id for the div, will be used to attach the React component. This will get assigned automatically if you do not provide an id. Must be unique.
  - **html_options:** Any other HTML options get placed on the added div for the component. For example, you can set a class (or inline style) on the outer div so that it behaves like a span, with the styling of `display:inline-block`. You may also use an option of `tag: "span"` to replace the use of the default DIV tag to be a SPAN tag.
  - **trace:** set to true to print additional debugging information in the browser. Defaults to true for development, off otherwise. Only on the **client side** will you will see the `railsContext` and your props.
  - **random_dom_id:** True to automatically generate random dom ids when using multiple instances of the same React component on one Rails view.
- **options if prerender (server rendering) is true:**
  - **replay_console:** Default is true. False will disable echoing server-rendering logs to the browser. While this can make troubleshooting server rendering difficult, so long as you have the configuration of `logging_on_server` set to true, you'll still see the errors on the server.
  - **logging_on_server:** Default is true. True will log JS console messages and errors to the server.
  - **raise_on_prerender_error:** Default is `Rails.env.development?` (true in development, false in production). True will throw an error on server-side rendering. Your controller will have to handle the error.
  - **`clientProps` merge behavior:** If a prerender result includes `clientProps`, React on Rails merges them into the generated client hydration props payload (`props.merge(clientProps)`). The original `props:` value must be a Ruby Hash or a JSON string representing an object.

---

### react_on_rails_preload_links

```erb
<%= react_on_rails_preload_links("HelloWorld", "comments_list") %>
```

Use `react_on_rails_preload_links` in a layout or view `<head>` when you know which auto-bundled React components the page will render. The helper resolves each component to its generated Shakapacker pack (`generated/ComponentName`) and emits preload link tags for the manifest assets. Pass component names as PascalCase, camelCase, or snake_case strings; hyphenated names are rejected because they cannot be normalized reliably.

For JavaScript chunks, plain script assets render as `<link rel="preload" as="script">`. Module assets render as `<link rel="modulepreload">` when the manifest marks the asset as a module or the emitted file has an `.mjs` extension. CSS chunks render as `<link rel="preload" as="style">`. Component packs without CSS assets simply skip the stylesheet preload.

```erb
<head>
  <%= react_on_rails_preload_links("ProductPage") %>
  <%= stylesheet_pack_tag "application" %>
</head>
<body>
  <%= react_component("ProductPage", props: @product_props, auto_load_bundle: true) %>
  <%= javascript_pack_tag "application" %>
</body>
```

Because preload hints belong in `<head>`, pass component names that are known before the component renders.

This helper only emits HTML link tags. Keep the normal `stylesheet_pack_tag` and `javascript_pack_tag` calls in the layout so the browser still applies and executes the assets.

When using a CDN asset host, keep Shakapacker's Subresource Integrity and `crossorigin` settings consistent between preload tags and the final script/style tags so the browser can reuse the preloaded response.

---

### react_component_hash

> **React 19 Alternative:** For metadata use cases (page titles, meta tags, canonical URLs), consider using [React 19 Native Metadata](../building-features/react-19-native-metadata.md) with `react_component` or `stream_react_component` instead. React 19 natively hoists `<title>`, `<meta>`, and `<link>` tags to `<head>`, eliminating the need for a render-function and `react_component_hash`. See the [migration guide](../building-features/react-19-native-metadata.md#migration-guide) for step-by-step instructions.

`react_component_hash` is used to return multiple HTML strings for server rendering, such as for
adding meta-tags to a page. It is exactly like `react_component` except for the following:

1. **`prerender: true` is forced**, not defaulted. This helper always prerenders on the server — passing `prerender: false` has no effect. Client-only rendering is incompatible with the "return multiple HTML strings" use case, so the option cannot be disabled.
2. Your JavaScript Render-Function for server rendering must return an Object rather than a React Component. The object must have shape `{ renderedHtml: { componentHtml, ...otherKeys } }`, where:
   - **`componentHtml` is mandatory.** Missing it raises `ReactOnRails::Error` with a message pointing to this requirement. This key contains the main server-rendered HTML that gets placed where the helper is called.
   - All other keys are optional and are returned to your view as `html_safe` strings, ready to be inserted anywhere in the layout (meta tags in `<head>`, sidebars, etc.).
3. Your view code must expect an object and not a string. Access keys with `react_component_hash_result["componentHtml"]`, `["title"]`, etc.
4. If the render function returns a string instead of an object, the helper raises an error telling you to return a render function that produces a hash.

Here is an example of ERB view code:

```erb
  <% react_helmet_app = react_component_hash("ReactHelmetApp", prerender: true,
                                             props: { helloWorldData: { name: "Mr. Server Side Rendering"}},
                                             id: "react-helmet-0", trace: true) %>
  <% content_for :title do %>
    <%= react_helmet_app['title'] %>
  <% end %>
  <%= react_helmet_app["componentHtml"] %>
```

And here is the JavaScript code:

```js
export default (props, _railsContext) => {
  const componentHtml = renderToString(<ReactHelmet {...props} />);
  const helmet = Helmet.renderStatic();

  const renderedHtml = {
    componentHtml,
    title: helmet.title.toString(),
  };
  return { renderedHtml };
};
```

---

### rails_context

You can call `rails_context` or `rails_context(server_side: true|false)` from your controller or view to see what values are in the Rails Context. Pass true or false depending on whether you want to see the server-side or the client-side `rails_context`. Typically, for computing cache keys, you should leave `server_side` as the default true. When calling this from a controller method, use `helpers.rails_context`.

---

### Renderer Functions (function that will call ReactDOM.render or ReactDOM.hydrate)

A **renderer function** is a Render-Function that declares **three** parameters: `(props, railsContext, domNodeId) => { ... }`. React on Rails detects renderer functions purely by parameter count (`Function.length === 3`) — the names don't matter. Instead of returning a React component, a renderer function is responsible for mounting the React tree itself by calling `ReactDOM.hydrateRoot` (for SSR'd HTML) or `ReactDOM.createRoot(...).render(...)` (for empty containers) against the DOM node identified by `domNodeId`. The renderer function is invoked at the point where React on Rails would normally mount the component automatically.

Why would you want to take over mounting yourself? One use case is code splitting: you may want to defer mounting a component until its code chunk has loaded, or until the container scrolls into view, instead of mounting it eagerly on page load. For modern code splitting with server-side rendering, see the [React on Rails Pro loadable-components guide](../building-features/code-splitting.md).

> [!IMPORTANT]
> **Renderer functions are strictly client-only.** There is no DOM on the server, so a renderer function cannot produce SSR output. React on Rails detects renderer functions at registration time and will throw a descriptive error like `Detected a renderer while server rendering component 'X'. See https://reactonrails.com/docs/core-concepts/render-functions for more information.` if you attempt to use one with `react_component(... prerender: true)`, `react_component_hash` (which forces prerendering), or `stream_react_component` (which is server-streaming only). For rendering that needs to run on the server, use a regular render function instead.

#### Cleaning up on Turbo/Turbolinks navigation (optional teardown)

Because a renderer function owns the React root it creates, React on Rails cannot unmount that root for you the way it does for the components it mounts itself. With [Turbo](https://turbo.hotwired.dev/) or Turbolinks, the page swaps without a full reload, so a renderer that never unmounts leaks its root (and any subscriptions or timers it holds) on every navigation.

To opt in to cleanup, **return a teardown wrapper** — `{ teardown: () => void | Promise<void> }`, or a promise resolving to one — from the renderer. React on Rails stores it and runs it when the mount is torn down: on Turbo/Turbolinks navigation (when the framework swaps in the next page) or when the same `domNodeId` node is replaced. Returning nothing keeps the previous (leaky) behavior, so existing renderers are unaffected.

```jsx
import ReactDOMClient from 'react-dom/client';

// Renderer function: 3 params, mounts itself, returns a teardown wrapper.
const MyRenderer = (props, _railsContext, domNodeId) => {
  const domNode = document.getElementById(domNodeId);
  if (!domNode) {
    throw new Error(`Missing DOM element with id: ${domNodeId}`);
  }

  // This example always creates a fresh root. See the hydration note below if your renderer
  // needs to hydrate server-rendered markup.
  const root = ReactDOMClient.createRoot(domNode);
  root.render(<MyComponent {...props} />);

  // Unmounted automatically on the next Turbo navigation (or same-id node replacement).
  return { teardown: () => root.unmount() };
};
```

> [!NOTE]
> **Hydrating server-rendered markup?** `prerender` is not a prop React on Rails injects — the top-level `prerender:` render option only controls server rendering and is rejected for renderer functions (see the note above). If your client renderer also serves components that were rendered on the server through a separate server bundle (a server/client split), pass an application-level signal in the component's `props`, such as `serverRendered`, and branch on it. The in-repo dummy apps use their own fixture props for this decision; the custom flag here is just an example for renderers that need an explicit hydrate-vs-render signal. Remove that renderer-only flag before spreading props into your component: `const { serverRendered, ...componentProps } = props;`, then call `ReactDOMClient.hydrateRoot(domNode, <MyComponent {...componentProps} />)` when `serverRendered` is true.

Under the React 16/17 legacy API there is no root handle, so unmount by container node instead:

```jsx
import ReactDOM from 'react-dom';

const MyLegacyRenderer = (props, _railsContext, domNodeId) => {
  const { serverRendered, ...componentProps } = props;
  const domNode = document.getElementById(domNodeId);
  if (!domNode) {
    throw new Error(`Missing DOM element with id: ${domNodeId}`);
  }

  if (serverRendered) {
    ReactDOM.hydrate(<MyComponent {...componentProps} />, domNode);
  } else {
    ReactDOM.render(<MyComponent {...componentProps} />, domNode);
  }
  return { teardown: () => ReactDOM.unmountComponentAtNode(domNode) };
};
```

> [!NOTE]
> Synchronous teardowns are always honored. An **async** teardown is best-effort in the open-source package: if a navigation or node replacement happens before the renderer resolves its teardown, that still-pending teardown may be dropped. React on Rails logs a `console.error` when this happens — search for `resolved after its mount was removed` (the teardown was dropped) or `Error resolving renderer teardown` (the render promise rejected) — so the dropped teardown is diagnosable rather than silent. React on Rails Pro's client renderer awaits the renderer and handles this race reliably.

---

### React Router

[React Router](https://reactrouter.com/) is supported via manual integration, including server-side rendering. See:

1. [React on Rails docs for React Router](../building-features/react-router.md)
2. Examples in [spec/dummy/app/views/react_router](https://github.com/shakacode/react_on_rails/tree/main/react_on_rails/spec/dummy/app/views/react_router) and follow to the JavaScript code in the [spec/dummy/client/app/startup/RouterApp.server.tsx](../../../react_on_rails/spec/dummy/client/app/startup/RouterApp.server.tsx).
3. [React on Rails Pro loadable-components guide](../building-features/code-splitting.md) for modern code splitting with server-side rendering.

### TanStack Router

TanStack Router has a first-class SSR helper through `react-on-rails-pro/tanstack-router` (requires React on Rails Pro). See [TanStack Router guide](../building-features/tanstack-router.md).

---

## server_render_js

`server_render_js(js_expression, options = {})`

- js_expression, like 2 + 3, and not a block of js code. If you have more than one line that needs to be executed, wrap it in an [IIFE](https://en.wikipedia.org/wiki/Immediately-invoked_function_expression). JS exceptions will be caught, and console messages will be handled properly
- Currently, the only option you may pass is `replay_console` (boolean)

This is a helper method that takes any JavaScript expression and returns the output from evaluating it. If you have more than one line that needs to be executed, wrap it in an IIFE. JS exceptions will be caught and console messages handled properly.

---

## Pro-Only View Helpers

The following view helpers are available exclusively with [React on Rails Pro](../../pro/react-on-rails-pro.md). Install the Pro gem to use them. ShakaCode Trust-Based Commercial Licensing lets you evaluate Pro without a token in development, test, CI/CD, and staging; production deployments require a paid license from [Pro pricing and sign up](https://pro.reactonrails.com/).

### cached_react_component and cached_react_component_hash

Fragment caching helpers that cache React component rendering to improve performance. The API is the same as `react_component` and `react_component_hash`, but with these differences:

1. The `cache_key` takes the same parameters as any Rails `cache` view helper.
2. The **props** are passed via a block so that evaluation of the props is not done unless the cache is broken.

Example usage:

```erb
<%= cached_react_component("App", cache_key: [@user, @post], prerender: true) do
  some_slow_method_that_returns_props
end %>
```

### stream_react_component

Progressive server-side rendering using React 18+ streaming with `renderToPipeableStream`. This enables:

- Faster Time to First Byte (TTFB)
- Progressive page loading with Suspense boundaries
- Better perceived performance

See the [Streaming Server Rendering guide](../building-features/streaming-server-rendering.md) for usage details.

> [!IMPORTANT]
> `stream_react_component` always forces `prerender: true` — passing `prerender: false` has no effect. It only supports React components and render functions that return React components; render functions returning a `{ renderedHtml }` hash are incompatible (see [compatibility matrix](../core-concepts/render-functions.md#compatibility-matrix-component-types-and-ruby-helpers)).

### stream_react_component_with_async_props

Async-props variant of `stream_react_component`. Use it when Rails has synchronous props plus other props that should stream later through Suspense boundaries.

Use this helper for RSC Server Components with `config.enable_rsc_support = true`. For non-RSC streaming SSR, use `stream_react_component`.

It accepts the same options as `stream_react_component`, plus a block that receives an emitter. Call `emit.call(prop_name, value)` for each async prop:

```erb
<%= stream_react_component_with_async_props("ProductPage",
      props: { name: @product.name, price: @product.price }) do |emit|
  emit.call("reviews", @product.reviews.as_json(only: [:id, :text, :rating]))
end %>
```

RSC Server Components rendered this way receive `getReactOnRailsAsyncProp`, which returns a Promise for each emitted prop.

For the complete React component pattern using `WithAsyncProps` and `getReactOnRailsAsyncProp`, see [Data Fetching in React on Rails Pro](../migrating/rsc-data-fetching.md#data-fetching-in-react-on-rails-pro).

> [!IMPORTANT]
> `stream_react_component_with_async_props` requires `config.enable_rsc_support = true` and always forces `prerender: true` — passing `prerender: false` has no effect. It requires the same controller setup as `stream_react_component`: the controller must call `stream_view_containing_react_components`. Like `stream_react_component`, it only supports React components and render functions that return React components; render functions returning a `{ renderedHtml }` hash are incompatible (see [compatibility matrix](../core-concepts/render-functions.md#compatibility-matrix-component-types-and-ruby-helpers)).
>
> The emitter block runs normal Ruby code sequentially, so `emit.call` does **not** parallelize slow queries by itself. For independent slow data sources, start the work concurrently before emitting values; see [Avoiding Server-Side Waterfalls](../migrating/rsc-data-fetching.md#avoiding-server-side-waterfalls).

### rsc_payload_react_component

Renders React Server Component (RSC) payloads in NDJSON format for client-side consumption. Used in conjunction with RSC support to enable:

- Reduced JavaScript bundle sizes
- Server-side data fetching
- Selective client-side hydration

The mounted `rsc_payload_route` normally calls this helper for you. Call it directly only for custom RSC payload rendering.

See the [React on Rails Pro Configuration](../configuration/configuration-pro.md) for RSC setup.

### rsc_payload_react_component_with_async_props

Async-props variant of `rsc_payload_react_component`. Use it only when custom RSC payload rendering needs Rails-emitted async props, such as an overridden payload route or template. For standard streamed ERB views, use [`stream_react_component_with_async_props`](#stream_react_component_with_async_props).

Requires `enable_rsc_support = true` in configuration, same as `rsc_payload_react_component` — see [React on Rails Pro Configuration](../configuration/configuration-pro.md).

It accepts the same options as `rsc_payload_react_component`, plus a block that receives an emitter:

```erb
<%= rsc_payload_react_component_with_async_props("ProductPage",
      props: { name: @product.name, price: @product.price }) do |emit|
  emit.call("reviews", @product.reviews.as_json(only: [:id, :text, :rating]))
end %>
```

> [!IMPORTANT]
> `rsc_payload_react_component_with_async_props` requires `config.enable_rsc_support = true` and always forces `prerender: true` — passing `prerender: false` has no effect. Use this helper only for custom RSC payload rendering; standard streamed ERB views should use `stream_react_component_with_async_props`.
>
> The emitter block runs normal Ruby code sequentially, so `emit.call` does **not** parallelize slow queries by itself. For independent slow data sources, start the work concurrently before emitting values; see [Avoiding Server-Side Waterfalls](../migrating/rsc-data-fetching.md#avoiding-server-side-waterfalls).

---

## More details

See the [lib/react_on_rails/helper.rb](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails/lib/react_on_rails/helper.rb) source.

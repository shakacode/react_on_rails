# Redux Store API

> [!WARNING]
>
> This runtime API remains supported for existing apps and advanced shared-store use cases, but it is not recommended as the default state model for new React on Rails apps. Prefer the standard `react_component` view helper with props or a render-function unless multiple React islands must coordinate through one client store. Keeping one large shared store can also prevent dynamic code splitting for performance.

> [!IMPORTANT]
>
> **Script Loading Requirement:** If you use Redux shared stores with inline component registration (registering components in view templates with `<script>ReactOnRails.register({ MyComponent })</script>`), you **must use `defer: true`** in your `javascript_pack_tag` instead of `async: true`. With async loading, the bundle may execute before inline scripts, causing component registration failures. See the [auto-bundling layout integration](../core-concepts/auto-bundling-file-system-based-automated-bundle-generation.md#layout-integration-with-auto-loading) guidance for related script-ordering patterns.

You don't need to use the `redux_store` API to use Redux inside a single React root. This API was set up to support multiple calls to `react_component` on one page that all talk to the same Redux store.

If you are rendering one React component on a page, pass props to that component through `react_component` and keep local UI state inside that React tree. A render-function is also a better fit when you need `railsContext`, routing setup, or custom hydration behavior for one root.

Choose state ownership before reaching for `redux_store`:

- **Island-local state:** use React Hooks or React Context inside one `react_component` root.
- **Server state:** use Rails controller props for initial data, then Rails JSON endpoints, GraphQL, or a server-state cache such as [TanStack Query](../building-features/tanstack-query.md) for data that belongs on the server.
- **Multi-island shared client state:** use `redux_store` when separate React roots on one Rails page must read and update the same client-side state.

Consider using the `redux_store` helper for the following advanced use cases:

1. You want multiple React roots or islands to access the same store at once.
2. You want to place the props that hydrate client-side stores at the very end of your HTML, probably server-rendered, so that the browser can render all earlier HTML first. This is particularly useful if your props will be large. However, you're probably better off using [React on Rails Pro](../../pro/react-on-rails-pro.md) if you're at all concerned about performance.

## Multiple React Islands on a Page with One Store

You may wish to have two separate React roots share the same Redux store. For example, if your navbar is a React island, you may want it to use the same store as another island in the main area of the page. You may even want multiple React islands in the main area, which allows for greater modularity. Also, you may want this to work with Turbo or Turbolinks to minimize reloading the JavaScript.

A good example of this would be something like a notifications counter in a header. As each notification is read in the body of the page, you would like to update the header. If both the header and body share the same Redux store, then this is trivial. Otherwise, we have to rely on other solutions, such as the header polling the server to see how many unread notifications exist.

Suppose the Redux store is called `appStore`, and you have 3 React components that each needs to connect to a store: `NavbarApp`, `CommentsApp`, and `BlogsApp`. I named them with `App` to indicate that they are the registered components.

You will need to make a function that can create the store you will be using for all components and register it via the `registerStoreGenerators` method. Note: this is a **store generator**, meaning that it is a function that takes `(props, railsContext)` and returns a store:

```js
function appStore(props, railsContext) {
  // Create a hydrated redux store, using props and the railsContext (object with
  // Rails contextual information).
  return myAppStore;
}

ReactOnRails.registerStoreGenerators({
  appStore,
});
```

When registering your component with React on Rails, you can get the store via `ReactOnRails.getStore`:

```js
// getStore retrieves the store that React on Rails created and hydrated from the redux_store props
const appStore = ReactOnRails.getStore('appStore');
return (
  <Provider store={appStore}>
    <CommentsApp />
  </Provider>
);
```

From your Rails view, you can use the provided helper `redux_store(store_name, props: {})` to create a fresh version of the store (because it may already exist if you came from visiting a previous page). Note: for this example, since we're initializing this from the main layout, we're using a generic name of `@react_props`. In other words, the Rails controller would set `@react_props` to the properties to hydrate the Redux store.

**app/views/layouts/application.html.erb**

```erb
...
<%= redux_store("appStore", props: @react_props) %>;
<%= react_component("NavbarApp") %>
yield
...
```

Components should be created as [function components](https://react.dev/learn/your-first-component#defining-a-component). Since you can pass in initial props via the helper `redux_store`, you do not need to pass any props directly to the component. Instead, the component hydrates by connecting to the store.

**\_comments.html.erb**

```erb
<%= react_component("CommentsApp") %>
```

**\_blogs.html.erb**

```erb
<%= react_component("BlogsApp") %>
```

_Note:_ You will not be doing any partial updates to the Redux store when loading a new page. When the page content loads, React on Rails will rehydrate a new version of the store with whatever props are placed on the page.

## Controller Extension

Include the module `ReactOnRails::Controller` in your controller, probably in ApplicationController. This will provide the following controller method, which you can call in your controller actions:

`redux_store(store_name, props: {})`

- **store_name:** A name for the store. You'll refer to this name in 2 places in your JavaScript:
  1. You'll call `ReactOnRails.registerStoreGenerators({storeName})` in the same place that you register your components.
  2. In your component definition, you'll call `ReactOnRails.getStore('storeName')` to get the hydrated Redux store to attach to your components.
- **props:** Named parameter `props`. ReactOnRails takes care of setting up the hydration of your store with props from the view.

For an example, see [spec/dummy/app/controllers/pages_controller.rb](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails/spec/dummy/app/controllers/pages_controller.rb). Note: this is preferable to using the equivalent view_helper `redux_store` in that you can be assured that the store is initialized before your components.

## View Helper

`redux_store(store_name, props: {}, defer: false, auto_load_bundle: nil)`

The view helper accepts the controller extension arguments plus `defer:` and `auto_load_bundle:`. Use `defer: true` to render the store hydration data later through `redux_store_hydration_data`; use `auto_load_bundle:` to auto-load the generated store pack (defaults to `ReactOnRails.configuration.auto_load_bundle`). These two keywords are view-helper-only and are rejected by the controller extension. **HOWEVER**, we recommend the controller extension instead because the Rails executes the template code in the controller action's view file (`erb`, `haml`, `slim`, etc.) before the layout. So long as you call `redux_store` at the beginning of your action's view file, this will work. However, it's an easy mistake to put this call in the wrong place. Calling `redux_store` in the controller action ensures proper load order, regardless of where you call this in the controller action. Note: you won't know of this subtle ordering issue until you server render and you find that your store is not hydrated properly.

`redux_store_hydration_data`

Place this view helper (no parameters) at the end of your shared layout so ReactOnRails will render the redux store hydration data. Since we're going to be setting up the stores in the controllers, we need to know where on the view to put the client-side rendering of this hydration data, which is a hidden div with a matching class that contains a data props. For an example, see [spec/dummy/app/views/layouts/application.html.erb](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails/spec/dummy/app/views/layouts/application.html.erb).

## More Details

- [lib/react_on_rails/controller.rb](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails/lib/react_on_rails/controller.rb) source
- [lib/react_on_rails/helper.rb](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails/lib/react_on_rails/helper.rb) source

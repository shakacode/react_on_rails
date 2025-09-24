# Redux Store

> [!WARNING]
>
> This Redux API is no longer recommended as it prevents dynamic code splitting for performance. Instead, you should use the standard `react_component` view helper passing in a "Render-Function."

You don't need to use the `redux_store` api to use Redux. This API was set up to support multiple calls to `react_component` on one page that all talk to the same Redux store.

If you are only rendering one React component on a page, as is typical to do a "Single Page App" in React, then you should _probably_ pass the props to your React component in a "Render-Function."

Consider using the `redux_store` helper for the two following use cases:

1. You want to have multiple React components accessing the same store at once.
2. You want to place the props to hydrate the client side stores at the very end of your HTML, probably server rendered, so that the browser can render all earlier HTML first. This is particularly useful if your props will be large. However, you're probably better off using [React on Rails Pro](https://github.com/shakacode/react_on_rails/wiki) if you're at all concerned about performance.

## Multiple React Components on a Page with One Store

You may wish to have 2 React components share the same the Redux store. For example, if your navbar is a React component, you may want it to use the same store as your component in the main area of the page. You may even want multiple React components in the main area, which allows for greater modularity. Also, you may want this to work with Turbolinks to minimize reloading the JavaScript.

A good example of this would be something like a notifications counter in a header. As each notification is read in the body of the page, you would like to update the header. If both the header and body share the same Redux store, then this is trivial. Otherwise, we have to rely on other solutions, such as the header polling the server to see how many unread notifications exist.

Suppose the Redux store is called `appStore`, and you have 3 React components that each needs to connect to a store: `NavbarApp`, `CommentsApp`, and `BlogsApp`. I named them with `App` to indicate that they are the registered components.

You will need to make a function that can create the store you will be using for all components and register it via the `registerStore` method. Note: this is a **storeCreator**, meaning that it is a function that takes (props, location) and returns a store:

```js
function appStore(props, railsContext) {
  // Create a hydrated redux store, using props and the railsContext (object with
  // Rails contextual information).
  return myAppStore;
}

ReactOnRails.registerStore({
  appStore,
});
```

When registering your component with React on Rails, you can get the store via `ReactOnRails.getStore`:

```js
// getStore will initialize the store if not already initialized, so creates or retrieves store
const appStore = ReactOnRails.getStore('appStore');
return (
  <Provider store={appStore}>
    <CommentsApp />
  </Provider>
);
```

From your Rails view, you can use the provided helper `redux_store(store_name, props)` to create a fresh version of the store (because it may already exist if you came from visiting a previous page). Note: for this example, since we're initializing this from the main layout, we're using a generic name of `@react_props`. In other words, the Rails controller would set `@react_props` to the properties to hydrate the Redux store.

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
  1. You'll call `ReactOnRails.registerStore({storeName})` in the same place that you register your components.
  2. In your component definition, you'll call `ReactOnRails.getStore('storeName')` to get the hydrated Redux store to attach to your components.
- **props:** Named parameter `props`. ReactOnRails takes care of setting up the hydration of your store with props from the view.

For an example, see [spec/dummy/app/controllers/pages_controller.rb](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/app/controllers/pages_controller.rb). Note: this is preferable to using the equivalent view_helper `redux_store` in that you can be assured that the store is initialized before your components.

## View Helper

`redux_store(store_name, props: {})`

This method has the same API as the controller extension. **HOWEVER**, we recommend the controller extension instead because the Rails executes the template code in the controller action's view file (`erb`, `haml`, `slim`, etc.) before the layout. So long as you call `redux_store` at the beginning of your action's view file, this will work. However, it's an easy mistake to put this call in the wrong place. Calling `redux_store` in the controller action ensures proper load order, regardless of where you call this in the controller action. Note: you won't know of this subtle ordering issue until you server render and you find that your store is not hydrated properly.

`redux_store_hydration_data`

Place this view helper (no parameters) at the end of your shared layout so ReactOnRails will render the redux store hydration data. Since we're going to be setting up the stores in the controllers, we need to know where on the view to put the client-side rendering of this hydration data, which is a hidden div with a matching class that contains a data props. For an example, see [spec/dummy/app/views/layouts/application.html.erb](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/app/views/layouts/application.html.erb).

# More Details

- [lib/react_on_rails/controller.rb](https://github.com/shakacode/react_on_rails/tree/master/lib/react_on_rails/controller.rb) source
- [lib/react_on_rails/helper.rb](https://github.com/shakacode/react_on_rails/tree/master/lib/react_on_rails/helper.rb) source

# Redux



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
  appStore
});
```

When registering your component with React on Rails, you can get the store via `ReactOnRails.getStore`:

```js
// getStore will initialize the store if not already initialized, so creates or retrieves store
const appStore = ReactOnRails.getStore("appStore");
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

Components are created as [stateless function(al) components](https://facebook.github.io/react/docs/reusable-components.html#stateless-functions). Since you can pass in initial props via the helper `redux_store`, you do not need to pass any props directly to the component. Instead, the component hydrates by connecting to the store.

**_comments.html.erb**

```erb
<%= react_component("CommentsApp") %>
```

**_blogs.html.erb**

```erb
<%= react_component("BlogsApp") %>
```

*Note:* You will not be doing any partial updates to the Redux store when loading a new page. When the page content loads, React on Rails will rehydrate a new version of the store with whatever props are placed on the page.
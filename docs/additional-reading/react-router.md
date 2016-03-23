# Using React Router
React on Rails supports the use of React Router. Client-side code doesn't need any special configuration for the React on Rails gem. Implement React Router how you normally would.

However, when attempting to use server-rendering, it is necessary to take steps that prevent rendering when there is a router error or redirect. In these cases, the client code should return an object containing the `error` and a `redirectLocation` instead of the React component. The `react_component` helper method in your Rails view will automatically detect that there was an error/redirect and handle it accordingly.

If you are working with the HelloWorldApp created by the react_on_rails generator, then the code below corresponds to the module in `client/app/bundles/HelloWorld/startup/HelloWorldAppServer.jsx`.

```js
const RouterApp = (props, railsContext) => {
  let error;
  let redirectLocation;
  let routeProps;
  const { location } = railsContext;
  
  // create your hydrated store
  const store = createStore(props);

  // See https://github.com/reactjs/react-router/blob/master/docs/guides/advanced/ServerRendering.md
  match({ routes, location }, (_error, _redirectLocation, _routeProps) => {
    error = _error;
    redirectLocation = _redirectLocation;
    routeProps = _routeProps;
  });

  // This tell react_on_rails to skip server rendering any HTML. Note, client rendering
  // will handle the redirect. What's key is that we don't try to render.
  // Critical to return the Object properties to match this { error, redirectLocation }
  if (error || redirectLocation) {
    return { error, redirectLocation };
  }

  // Important that you don't do this if you are redirecting or have an error.
  return (
    <Provider store={store}>
      <RouterContext {...routeProps} />
    </Provider>
  );
};
```

For a fleshed out integration of react_on_rails with react-router, check out [React Webpack Rails Tutorial Code](https://github.com/shakacode/react-webpack-rails-tutorial), specifically the files:

* [react-webpack-rails-tutorial/client/app/bundles/comments/routes/routes.jsx](https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/client/app/bundles/comments/routes/routes.jsx)

* [react-webpack-rails-tutorial/client/app/bundles/comments/startup/ClientRouterApp.jsx](https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/client/app/bundles/comments/startup/ClientRouterApp.jsx)

* [react-webpack-rails-tutorial/client/app/bundles/comments/startup/ServerRouterApp.jsx](https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/client/app/bundles/comments/startup/ServerRouterApp.jsx)

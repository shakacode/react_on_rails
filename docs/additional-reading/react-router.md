# Using React Router

React on Rails supports the use of React Router. Client-side code doesn't need any special configuration for the React on Rails gem. Implement React Router how you normally would. Note, you might want to avoid using Turbolinks as both Turbolinks and React-Router will be trying to handle the back and forward buttons. If you get this figured out, please do share with the community! Otherwise, you might have to tweak the basic settings for Turbolinks, and this may or may not be worth the effort.

When attempting to use server-rendering, it is necessary to take steps that prevent rendering when there is a router error or redirect. In these cases, the client code should return an object containing the `error` and a `redirectLocation` instead of the React component. The `react_component` helper method in your Rails view will automatically detect that there was an error/redirect and handle it accordingly.

If you are working with the HelloWorldApp created by the react_on_rails generator, then the code below corresponds to the module in `client/app/bundles/HelloWorld/startup/HelloWorldApp.jsx`.

```js
const RouterApp = (props, railsContext) => {
  let error;
  let redirectLocation;
  let routeProps;
  const { location } = railsContext;
  
  // create your hydrated store
  const store = createStore(props);

  // See https://github.com/reactjs/react-router/blob/master/docs/guides/ServerRendering.md
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


# Server Rendering Using React Router V4

Your generator function may not return an object with the property `renderedHtml`. Thus, you call 
renderToString() and return an object with this property.

This example **only applies to server rendering** and should be only used in the server side bundle.

From the [original example in the ReactRouter docs](https://react-router.now.sh/ServerRouter)
 
```javascript
   import React from 'react'
   import { renderToString } from 'react-dom/server'
   import { ServerRouter, createServerRenderContext } from 'react-router'
   
   const ReactRouterComponent = (props, railsContext) => {
   
     // first create a context for <ServerRouter>, it's where we keep the
     // results of rendering for the second pass if necessary
     const context = createServerRenderContext()
     const { location } = railsContext;

     // render the first time
     let markup = renderToString(
       <ServerRouter
         location={location}
         context={context}
       >
         <App/>
       </ServerRouter>
     )
   
     // get the result
     const result = context.getResult()
   
     // the result will tell you if it redirected, if so, we ignore
     // the markup and send a proper redirect.
     if (result.redirect) {
       return { 
         redirectLocation: result.redirect.pathname 
       };
     } else {
   
       // the result will tell you if there were any misses, if so
       // we can send a 404 and then do a second render pass with
       // the context to clue the <Miss> components into rendering
       // this time (on the client they know from componentDidMount)
       if (result.missed) {
         // React on Rails does not support the 404 status code for the browser.  
         // res.writeHead(404)
         
         markup = renderToString(
           <ServerRouter
             location={location}
             context={context}
           >
             <App/>
           </ServerRouter>
         )
       }
       return { renderedHtml: markup };
     }
  }
```

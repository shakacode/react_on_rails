_This article needs updating for the latest version of React Router_

# Using React Router

React on Rails supports the use of React Router. Client-side code doesn't need any special configuration for the React on Rails gem. Implement React Router how you normally would. Note, you might want to avoid using Turbolinks as both Turbolinks and React Router will be trying to handle the back and forward buttons. If you get this figured out, please do share with the community! Otherwise, you might have to tweak the basic settings for Turbolinks, and this may or may not be worth the effort.

If you are working with the HelloWorldApp created by the react_on_rails generator, then the code below corresponds to the module in `client/app/bundles/HelloWorld/startup/HelloWorldApp.jsx`.

```js
import { BrowserRouter, Switch } from 'react-router-dom';
import routes from './routes.jsx';

const RouterApp = (props, railsContext) => {
  // create your hydrated store
  const store = createStore(props);

  return (
    <Provider store={store}>
      <BrowserRouter>
        <Switch>{routes}</Switch>
      </BrowserRouter>
    </Provider>
  );
};
```

For a fleshed out integration of React on Rails with React Router, check out [React Webpack Rails Tutorial Code](https://github.com/shakacode/react-webpack-rails-tutorial), specifically the files:

- [react-webpack-rails-tutorial/client/app/bundles/comments/routes/routes.jsx](https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/client/app/bundles/comments/routes/routes.jsx)

- [react-webpack-rails-tutorial/client/app/bundles/comments/startup/ClientRouterApp.jsx](https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/client/app/bundles/comments/startup/ClientRouterApp.jsx)

- [react-webpack-rails-tutorial/client/app/bundles/comments/startup/ServerRouterApp.jsx](https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/client/app/bundles/comments/startup/ServerRouterApp.jsx)

# Server Rendering Using React Router V4

Your Render-Function may not return an object with the property `renderedHtml`. Thus, you call
`renderToString()` and return an object with this property.

This example **only applies to server-side rendering** and should only be used in the server-side bundle.

From the [original example in the React Router docs](https://github.com/ReactTraining/react-router/blob/v4.3.1/packages/react-router-dom/docs/guides/server-rendering.md)

```javascript
import React from 'react';
import { renderToString } from 'react-dom/server';
import { StaticRouter } from 'react-router';
import { Provider } from 'react-redux';
import ReactOnRails from 'react-on-rails';

// App.jsx from src/client/App.jsx
import App from '../App';

const ReactServerRenderer = (props, railsContext) => {
  const context = {};

  // commentStore from src/server/store/commentStore
  const store = ReactOnRails.getStore('../store/commentStore');

  // Route Store generated from react-on-rails

  const { location } = railsContext;

  const html = renderToString(
    <Provider store={store}>
      <StaticRouter location={location} context={context} props={props}>
        <App />
      </StaticRouter>
    </Provider>,
  );

  if (context.url) {
    // Somewhere a `<Redirect>` was rendered
    redirect(301, context.url);
  } else {
    // we're good, send the response
    return { renderedHtml: html };
  }
};
```

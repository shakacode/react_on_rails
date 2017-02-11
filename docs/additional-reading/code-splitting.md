# Code Splitting

What is code splitting? From the webpack documentation:

> For big web apps it’s not efficient to put all code into a single file, especially if some blocks of code are only required under some circumstances. Webpack has a feature to split your codebase into “chunks” which are loaded on demand. Some other bundlers call them “layers”, “rollups”, or “fragments”. This feature is called “code splitting”.

## Server Rendering and Code Splitting

Let's say you're requesting a page that needs to fetch a code chunk from the server before it's able to render. If you do all your rendering on the client side, you don't have to do anything special. However, if the page is rendered on the server, you'll find that React will spit out the following error:

> Warning: React attempted to reuse markup in a container but the checksum was invalid. This generally means that you are using server rendering and the markup generated on the server was not what the client was expecting. React injected new markup to compensate which works but you have lost many of the benefits of server rendering. Instead, figure out why the markup being generated is different on the client or server:

> (client) <!-- react-empty: 1 -

> (server) <div data-reactroot="
<!--This comment is here because the comment beginning on line 13 messes up Sublime's markdown parsing-->

Different markup is generated on the client than on the server. Why does this happen? When you register a component or generator function with `ReactOnRails.register`, react on rails will render the component as soon as the page loads. However, react-router renders a comment while waiting for the code chunk to be fetched from the server. This means that react will tear all of the server rendered code out of the DOM, and then rerender it a moment later once the code chunk arrives from the server, defeating most of the purpose of server rendering.

### The solution

To prevent this, you have to wait until the code chunk is fetched before doing the initial render on the client side. To accomplish this, react on rails allows you to register a renderer. This works just like registering a generator function, except that the function you pass takes three arguments: `renderer(props, railsContext, domNodeId)`, and is responsible for calling `ReactDOM.render` to render the component to the DOM. React on rails will automatically detect when a generator function takes three arguments, and will not call `ReactDOM.render`, instead allowing you to control the initial render yourself.

Here's an example of how you might use this in practice:

#### page.html.erb
```erb
<%= react_component("NavigationApp", prerender: true) %>
<%= react_component("RouterApp", prerender: true) %>
<%= redux_store_hydration_data %>
```

#### clientRegistration.js
```js
import ReactOnRails from 'react-on-rails';
import NavigationApp from './NavigationApp';

// Note that we're importing a different RouterApp than in serverRegistration.js
// Renderer functions should not be used on the server, because there is no DOM.
import RouterApp from './RouterAppRenderer';
import applicationStore from '../store/applicationStore';

ReactOnRails.registerStore({applicationStore});
ReactOnRails.register({
  NavigationApp,
  RouterApp,
});
```

#### serverRegistration.js
```js
import ReactOnRails from 'react-on-rails';
import NavigationApp from './NavigationApp';

// Note that we're importing a different RouterApp than in clientRegistration.js
import RouterApp from './RouterAppServer';
import applicationStore from '../store/applicationStore';

ReactOnRails.registerStore({applicationStore});
ReactOnRails.register({
  NavigationApp,
  RouterApp,
});
```
Note that you should not register a renderer on the server, since there won't be a domNodeId when we're server rendering. Note that the `RouterApp` imported by `serverRegistration.js` is from a different file. For an example of how to set up an app for server rendering, see the [react router docs](react-router.md).

#### RouterAppRenderer.jsx
```jsx
import ReactOnRails from 'react-on-rails';
import React from 'react';
import ReactDOM from 'react-dom';
import Router from 'react-router/lib/Router';
import match from 'react-router/lib/match';
import browserHistory from 'react-router/lib/browserHistory';
import { Provider } from 'react-redux';

import routes from '../routes/routes';


const RouterAppRenderer = (props, railsContext, domNodeId) => {
  const store = ReactOnRails.getStore('applicationStore');
  const history = browserHistory;

  match({ history, routes }, (error, redirectionLocation, renderProps) => {
    if (error) {
      throw error;
    }

    const reactElement = (
      <Provider store={store}>
        <Router {...renderProps} />
      </Provider>
    );

    ReactDOM.render(reactElement, document.getElementById(domNodeId));
  });
};

export default RouterAppRenderer;
```

What's going on in this example is that we're putting the rendering code in the callback passed to `match`. The effect is that the client render doesn't happen until the code chunk gets fetched from the server, preventing the client/server checksum mismatch.

The idea is that match from react-router is async; it fetches the component using the getComponent method that you provide with the route definition, and then passes the props to the callback that are needed to do the complete render. Then we do the first render inside of the callback, so that the first render is the same as the server render.

The server render matches the deferred render because the server bundle is a single file, and so it doesn't need to wait for anything to be fetched.

### Working Example

There's an implemented example of code splitting in the `spec/dummy` folder of this repository.

See:

- [spec/dummy/client/app/startup/clientRegistration.jsx](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/client/app/startup/clientRegistration.jsx)
- [spec/dummy/client/app/startup/serverRegistration.jsx](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/client/app/startup/serverRegistration.jsx)
- [spec/dummy/client/app/startup/DeferredRenderAppRenderer.jsx](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/client/app/startup/DeferredRenderAppRenderer.jsx) <-- Code splitting implemented here
- [spec/dummy/client/app/startup/DeferredRenderAppServer.jsx](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/client/app/startup/DeferredRenderAppServer.jsx)
- [spec/dummy/client/app/components/DeferredRender.jsx](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/client/app/components/DeferredRender.jsx)
- [spec/dummy/client/app/components/DeferredRenderAsyncPage.jsx](https://github.com/shakacode/react_on_rails/tree/master/spec/dummy/client/app/components/DeferredRenderAsyncPage.jsx)

### Caveats

If you're going to try to do code splitting with server rendered routes, you'll probably need to use seperate route definitions for client and server to prevent code splitting from happening for the server bundle. The server bundle should be one file containing all the JavaScript code. This will require you to have seperate webpack configurations for client and server.

The reason is we do server rendering with ExecJS, which is not capable of doing anything asynchronous. It would be impossible to asyncronously fetch a code chunk while server rendering. See [this issue](https://github.com/shakacode/react_on_rails/issues/477) for a discussion.

Also, do not attempt to register a renderer on the server. Instead, register either a generator function or a component. If you register a renderer in the server bundle, you'll get an error when react on rails tries to server render the component.

## How does Webpack know where to find my code chunks?

Add the following to the output key of your webpack config:

```js
config = {
  output: {
    publicPath: '/assets/',
  }
};
```

This causes Webpack to prepend the code chunk filename with `/assets/` in the request url. The react on rails sets up the webpack config to put webpack bundles in `app/assets/javascripts/webpack`, and modifies `config/initializers/assets.rb` so that rails detects the bundles. This means that when we prepend the request url with `/assets/`, rails will know what webpack is asking for.

See [rails-assets.md](./rails-assets.md) to learn more about static assets.

If you forget to set the public path, webpack will request the code chunk at `/{filename}`. This will cause the request to be handled by the Rails router, which will send back a 404 response, assuming that you don't have a catch-all route. In your javascript console, you'll get the following error:

> GET http://localhost:3000/1.1-bundle.js

You'll also see the following in your Rails development log:

> Started GET "/1.1-bundle.js" for 127.0.0.1 at 2016-11-29 15:21:55 -0800
>
> ActionController::RoutingError (No route matches [GET] "/1.1-bundle.js")

It's worth mentioning that in Webpack v2, it's possible to register an error handler by calling `catch` on the promise returned by `System.import`, so if you want to do error handling, you should use v2. The [example](#working-example) in `spec/dummy` is currently using Webpack v1.

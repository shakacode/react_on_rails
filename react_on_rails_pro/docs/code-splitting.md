# Server-side rendering with code-splitting in React on Rails

by ShakaCode

_Last updated June 13, 2019_

# Deprecated

**Please, see [our new documentation on how to setup code splitting with loadable components](./code-splitting-loadable-components.md).**

# Introduction

Webpack has an interesting feature called dynamic code-splitting, which automatically breaks the bundle into parts where the `import ()` function is used.

For more convenient work with `import ()` there are libraries like react-loadable.
It provides a special function by which you can turn any react component into a dynamic component.

To use react-loadable in the react on rails project, you do not need to take any additional action until the server-side rendering is used.

If the project includes server rendering, then you need to exclude the use of dynamic imports on the server-rendering side. I.e. it needs to generate a server bundle in which contains statically imported components only. This is due to how the ExecJS renderer and the node-renderer cannot use promises.

# Dependencies

Install following libraries in client folder:

```
yarn add react-loadable webpack-conditional-loader
```

- [react-loadable](https://github.com/jamiebuilds/react-loadable) - take cares of loading and correctly displaying our dynamic components.
- [webpack-conditional-loader](https://www.npmjs.com/package/webpack-conditional-loader) - allow us conditionally extract parts of our code into different bundles.

Add `webpack-conditional-loader` to the loaders, like this:

```js
{
  test: /\.jsx?$/,
  use: {
  use: [{
    loader: 'babel-loader',
    options: {
      cacheDirectory: true,
    },
  },
  }, 'webpack-conditional-loader'],
  exclude: /node_modules/,
},
```

Optionally. Create alias for `DynamicImports.js` file in `resolve`:

```js
alias: {
  DynamicImports: path.resolve(__dirname, 'client', 'DynamicImports.js'),
}
```

# Simple example of using dynamic components

Consider the component that we want to convert to a dynamic:

```
components
  |_ Map
      |_Map.jsx
```

Let's create `index.jsx` in `Map` directory with the following contents:

```jsx
let Component = null;

/* 
  the comments `#if` that you see below is a C-like conditional directive
  used by webpack-conditional-loader. This condition tells webpack's loader
  to use only one specific code depends on existence of `IS_SSR` env variable
  So, when `IS_SSR` variable is present, webpack-conditional-loader comments out the
  code in `#if process.env.IS_SSR !== 'true' .... #end` clause before processing this
  file by babel-loader.
*/
// #if process.env.IS_SSR === 'true'
import StaticComponent from './Map';

Component = StaticComponent;
// #endif

// #if process.env.IS_SSR !== 'true'
import React from 'react';
import Loadable from 'react-loadable';

import Loading from '../Loading';

const load = (opts) =>
  Loadable({
    delay: 10000,
    loading: () => <Loading />,
    render(loaded, props) {
      const LoadedComponent = loaded.default;
      return <LoadedComponent {...props} />;
    },
    ...opts,
  });

/* Here we're wrapping our component in react-loadable HOC */
const DynamicComponent = load({
  /* 
    We need to specify these params: `webpackChunkName`, `modules` and `webpack`
    so react-loadable can load our chunk correctly
  */
  loader: () => import(/* webpackChunkName: "Map" */ './Map'),
  modules: ['./Map'],
  webpack: () => [require.resolveWeak('./Map')],
});

Component = DynamicComponent;
// #endif

/*
  When `IS_SSR` present, `Component` equals `StaticComponent`, otherwise `DynamicComponent`
*/
export default Component;
```

Now, if we want to use this component we should import it like this:

```jsx
import Map from './components/Map';
```

in this case, webpack will load `index.jsx` instead of `Map.jsx` if not some other special order specified.

Also, `IS_SSR=true` must added when creating server side bundle, like this:

```
NODE_ENV=production IS_SSR=true webpack --config webpack.config.ssr.prod.js
```

The new chunk `Map.chunk.js` will be automatically extracted due dynamic code-splitting feature.

With this configuration, server rendering will work with static components, and client with dynamic components.

## Flickering

On the client, we can periodically see `Loading ...` instead of the right components.  
This is due to the fact that react-loadable loads the module with the component only when it is mounted to the DOM.

React-loadable has the ability to preload the required component, for example, when we hover the cursor on the menu item. This will remove `Loading ...` in some situations.  
More details can be found in the documentation react-loadable.
[https://github.com/jamiebuilds/react-loadable#preloading](https://github.com/jamiebuilds/react-loadable#preloading)

But we can get rid of annoying flickering `Loading ...` the first time the page loads. The server renderer has already rendered the necessary components. Therefore, we can transfer this information from the server renderer to the client and preload the necessary modules.

Unfortunately, the way specified in the documentation `react-loadable` does not work for us.

Here is another similar method.

For this we use the function `registerDynamicComponentOnServer`. We will place it in the new file `DynamicImports.js`:

```javascript
export const registerDynamicComponentOnServer = (name) => {
  const serverSide = typeof window === 'undefined';

  if (serverSide) {
    if (typeof global.dynamicComponents === 'undefined') {
      global.dynamicComponents = [];
    }
    if (global.dynamicComponents.indexOf(name) === -1) {
      global.dynamicComponents.push(name);
    }
  }
};
```

As you can see from the function body, it runs only for server-side rendering.  
It simply adds the name of the component to the global array `dynamicComponents` which will be transferred to the client later.

It must be imported into the component that needs to be made dynamic and called in the render method of this component. For example:

components/Map/Map.jsx:

```javascript
...
import { registerDynamicComponentOnServer } from 'DynamicImports';

class Map extends React.Component {
  constructor(props) {
    super(props);
    ...
    registerDynamicComponentOnServer('Map');
  }
  ...
}
```

Then this global array must be passed to the client.
To do this, change server entry point as follows:

**ServerApp.js**:

```javascript
import React from 'react';
import ReactOnRails from 'react-on-rails';

import App from './App';

const ServerApp = (props, railsContext) => {
  const html = renderToString(<App {...props} components={{ MainPage, AboutPage }} />);

  return {
    html,
    dynamicComponents: JSON.stringify(global.dynamicComponents),
  };
};

ReactOnRails.register({ App: ServerApp });

export default ServerApp;
```

And add our array to view in rails, where our react_component is displayed

```slim
<% component = react_component("App", props: {}, prerender: true) %>

<%= component['html'] %>

<script>
window.dynamicComponents = '<%= component['dynamicComponents'] %>';
</script>
```

Note, the complexity of getting some data from the execution of JS during server rendering into some HTML script tags will eventually be made much simpler in React on Rails Pro.  
See [https://github.com/shakacode/react_on_rails_pro/issues/67](https://github.com/shakacode/react_on_rails_pro/issues/67) for details on how this work.

In this case, the array is transferred with the names of the dynamic components that were rendered on server-side.

Using this array, we can preload the dynamic components on the client before hydrate. This is critical in the case of when the user has bookmarked a dynamically loaded page.

To do this, we will create an object with the component names as the keys, and the values with functions that dynamically import the component data.

We will add it to `DynamicImports.js` and add a check for the presence of the registered component in this object in the function` registerDynamicComponentOnServer`:

**DynamicImports.js**

```javascript
const DynamicImports = {
  Map: () => import('./components/Map'),
};

export const registerDynamicComponentOnServer = (name) => {
  const serverSide = typeof window === 'undefined';

  if (serverSide) {
    if (typeof global.dynamicComponents === 'undefined') {
      global.dynamicComponents = [];
    }
    if (typeof DynamicImports[name] === 'undefined') {
      throw new Error(`Dynamic import not defined for ${name}`);
    }
    if (global.dynamicComponents.indexOf(name) === -1) {
      global.dynamicComponents.push(name);
    }
  }
};

export default DynamicImports;
```

Now we can load the component we need, knowing its name
For example:

```javascript
DynamicImports['Map']();
```

This function will return Promise, which can be used for client rendering.

Change the Client.js to add the preloading of the required components:

**Client.js**

```javascript
import React from 'react';
import { hydrateRoot } from 'react-dom/client';
import Loadable from 'react-loadable';

import App from './App';

import DynamicImports from 'DynamicImports';

const App = (props, railsContext, domNodeId) => {
  const dynamicComponents =
    typeof window.dynamicComponents !== 'undefined' ? JSON.parse(window.dynamicComponents) : [];

  const dynamicImports = [];
  dynamicComponents.map((name) => {
    const dynamicImportInvoked = DynamicImports[name]();
    dynamicImports.push(dynamicImportInvoked);
  });

  Promise.all(dynamicImports)
    .then(() => Loadable.preloadReady())
    .then(() => {
      hydrateRoot(
        <App {...props} components={{ MainPage, AboutPage }} />,
        document.getElementById(domNodeId),
      );
    });
};

export default App;
```

This code requires explanation.

The array with names of rendered components called `dynamicComponents` is used in the map function.  
In this function, the dynamic import invoked and the result (promise) is added to `dynamicImports` array.

```javascript
const dynamicImports = [];
dynamicComponents.map((name) => {
  const dynamicImportInvoked = DynamicImports[name]();
  dynamicImports.push(dynamicImportInvoked);
});
```

This array is used in the function `Promise.all`

```javascript
  Promise.all(dynamicImports).then(() => ...)
```

Then fires `Loadable.preloadReady()`

```javascript
.then(() => Loadable.preloadReady())
```

As in the doc:
Check for modules that are already loaded in the browser and call the matching LoadableComponent.preload methods.

We need to call this method to initialize already preloaded components.

In addition, note that in the creation of dynamic modules, the `modules` and` webpack` options are used, per the docs for react-loadable.

```javascript
  modules: ['./AboutPage'],
  webpack: () => [require.resolveWeak('./AboutPage')],
```

They are needed to make .preload method work properly

Thus, all dynamic modules will be loaded up to hydrate, and there will be no flicker.

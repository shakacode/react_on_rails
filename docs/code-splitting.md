# Server-side rendering with code-splitting in React on Rails
by ShakaCode

*Last updated August 9, 2018*

# Introduction

Webpack has an interesting feature called dynamic code-splitting, which automatically breaks the bundle into parts where the `import ()` function is used.

For more convenient work with `import ()` there are libraries like react-loadable.
It provides a special function by which you can turn any react component into a dynamic component.

To use react-loadable in the react on rails project, you do not need to take any additional action until the server-side rendering is used.

If the project includes server rendering, then you need to exclude the use of dynamic imports on the server-rendering side. I.e. it needs to generate a server bundle in which contains statically imported components only. This is due to how the ExecJS renderer and the vm-renderer cannot use promises.

# Simple example of using dynamic components

This code contains two entry points - for the server and for the client. In addition, there is a file called `DynamicImports`, which contains the necessary functions.


**Server.js**  
Here we explicitly import components that will eventually end up in a single bundle.

```javascript
import React from 'react';

import App from './App';

import MainPage from './MainPage';
import AboutPage from './AboutPage';

const App = (props, railsContext) => {

  return renderToString(
    <App
      {...props}
      components={{ MainPage, AboutPage }}
    />
  );
}

export default App
```



**Client.js**  

Note the use:  
- npm library react-loadable.  
- Some imports are defined in callbacks. These imports have special comments that tell Webpack what needs to be loaded.  
- The App component has 2 properties of functions for the MainPage and the AboutPage which leverage react-loadable. Compare that to the standard imports used for server rendering.

```javascript
import React from 'react';
import ReactDOM from 'react-dom';
import Loadable from 'react-loadable'

import App from './App';

const load = opts =>
  Loadable({
    loading() {
      return <div>Loading...</div>
    },
    ...opts,
  })

const MainPage = load({
  loader: () =>
    import(/* webpackChunkName: "MainPage" */ './MainPage'),
})

const MainPage = load({
  loader: () =>
    import(/* webpackChunkName: "AboutPage" */ './AboutPage'),
})

const App = (props, railsContext, domNodeId) => {
  return ReactDOM.hydrate(
    <App
      {...props}
      components={{ MainPage, AboutPage }}
    />,
   domNodeId
  )
}

export default App
```

The client bundle will be automatically split into several chunks which includes `MainPage.chunk.js` and `AboutPage.chunk.js` due dynamic code-splitting feature.

We use react-loadable function `Loadable` that returns wrapper which will load our component when it will be needed.

With this configuration, server rendering will work with static components, and client with dynamic components. This restriction is inconvenient because the components must be dragged from the top down. That is, we need to pass them as props to the root App component.

Side note, this may change once the vm-renderer can support promises.

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
export const registerDynamicComponentOnServer = name => {
  const serverSide = typeof window === 'undefined'

  if (serverSide) {
    if (typeof global.dynamicComponents === 'undefined') {
      global.dynamicComponents = []
    }
    if (global.dynamicComponents.indexOf(name) === -1) {
      global.dynamicComponents.push(name)
    }
  }
}
```
As you can see from the function body, it runs only for server-side rendering.  
It simply adds the name of the component to the global array `dynamicComponents` which will be transferred to the client later.

It must be imported into the component that needs to be made dynamic and called in the render method of this component. For example:

```javascript
...
import { registerDynamicComponentOnServer } from './DynamicImports';

class MainPage extends React.Component {
  render() {

    registerDynamicComponentOnServer('MainPage');

    return (
      <div>This is the main page</div>
    );
  }
}
```


Then this global array must be passed to the client.
To do this, change our ServerApp.js as follows:


**Server.js**:
```javascript
import React from 'react';

import App from './App';

import MainPage from './MainPage';
import AboutPage from './AboutPage';

const App = (props, railsContext) => {

  const html = renderToString(
    <App
      {...props}
      components={{ MainPage, AboutPage }}
    />
  );

  return {
    html,
    dynamicComponents: JSON.stringify(global.dynamicComponents),
  };
}

export default App
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
  HomeRoutes: () => import('./screens/Home/HomeRoutes'),
  BrowseRoutes: () => import('./screens/Browse/routes'),
}

export const registerDynamicComponentOnServer = name => {
  const serverSide = typeof window === 'undefined'

  if (serverSide) {
    if (typeof global.dynamicComponents === 'undefined') {
      global.dynamicComponents = []
    }
    if (typeof DynamicImports[name] === 'undefined') {
      throw new Error(`Dynamic import not defined for ${name}`)
    }
    if (global.dynamicComponents.indexOf(name) === -1) {
      global.dynamicComponents.push(name)
    }
  }
}

export default DynamicImports
```

Now we can load the component we need, knowing its name
For example:
```javascript
DynamicImports ['HomeRoutes'] ()
```
This function will return Promise, which can be used for client rendering.

Change the Client.js to add the preloading of the required components:


**Client.js**
```javascript
import React from 'react';
import ReactDOM from 'react-dom';
import Loadable from 'react-loadable'

import App from './App';

import DynamicImports from './DynamicImports'

const load = opts =>
  Loadable({
    loading() {
      return <div>Loading...</div>
    },
    ...opts,
  })

const MainPage = load({
  loader: () =>
    import(/* webpackChunkName: "MainPage" */ './MainPage'),
  modules: ['./MainPage'],
  webpack: () => [require.resolveWeak('./MainPage')],
})

const MainPage = load({
  loader: () =>
    import(/* webpackChunkName: "AboutPage" */ './AboutPage'),
  modules: ['./AboutPage'],
  webpack: () => [require.resolveWeak('./AboutPage')],
})

const App = (props, railsContext, domNodeId) => {

  const dynamicComponents =
    typeof window.dynamicComponents !== 'undefined'
      ? JSON.parse(window.dynamicComponents)
      : []


  const dynamicImports = []
  dynamicComponents.map(name => {
    const dynamicImportInvoked = DynamicImports[name]()
    dynamicImports.push(dynamicImportInvoked)
  })

  Promise.all(dynamicImports)
    .then(() => Loadable.preloadReady())
    .then(() => {
      ReactDOM.hydrate(
        <App
          {...props}
          components={{ MainPage, AboutPage }}
        />,
        document.getElementById(domNodeId),
      )
    })
}

export default App
```

This code requires explanation.

The array with names of rendered components called `dynamicComponents` is used in the map function.  
In this function, the dynamic import invoked and the result (promise) is added to `dynamicImports` array.
```javascript
  const dynamicImports = []
  dynamicComponents.map(name => {
    const dynamicImportInvoked = DynamicImports[name]()
    dynamicImports.push(dynamicImportInvoked)
  })
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

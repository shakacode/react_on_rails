# Using React Router

React on Rails supports React Router for client-side routing. This guide shows how to integrate React Router into your React on Rails application.

**Important:** The React on Rails generator does not install React Router. You'll need to add it to your project manually.

## Compatibility Note

If you're using Turbo (Rails 7+) or Turbolinks (Rails 6 and earlier), be aware that both React Router and Turbo/Turbolinks handle browser navigation and the back button. These two routing systems can conflict. Consider:

- Using one routing approach (either Turbo OR React Router, not both)
- Disabling Turbo for pages using React Router with `data-turbo="false"`
- Using code splitting instead of client-side routing for similar performance benefits

If you successfully integrate both, please share your solution with the community!

For more details, see [Turbo/Turbolinks Guide](./turbolinks.md).

## Installation

First, add React Router v6 to your project:

```bash
npm install react-router-dom@^6.0.0
# or
yarn add react-router-dom@^6.0.0
```

**Why React Router v6?** React Router v7 has merged with Remix and uses a different architecture that may not be fully compatible with React on Rails' server-side rendering approach. We recommend v6 for stable integration. If you need v7 features, please test thoroughly and share your findings with the community.

React Router v6 offers multiple routing approaches. For React on Rails, we recommend **Declarative Mode** (traditional component-based routing, covered in this guide).

**Note on Data Mode:** React Router's Data Mode (with loaders/actions) is designed for SPAs where the client handles data fetching. Since React on Rails uses Rails controllers to load data and pass it as props to React components, Data Mode would create duplicate data loading. Stick with Declarative Mode to leverage React on Rails' server-side data loading pattern.

## Basic Client-Side Setup with Redux

If you're using Redux (created with `rails generate react_on_rails:install --redux`), you can add React Router by wrapping your app:

**File: `app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.client.jsx`**

```jsx
import React from 'react';
import { Provider } from 'react-redux';
import { BrowserRouter, Routes, Route } from 'react-router-dom';

import configureStore from '../store/helloWorldStore';
import HelloWorldContainer from '../containers/HelloWorldContainer';
// Import other components for routing
// import About from '../components/About';
// import Contact from '../components/Contact';

const HelloWorldApp = (props) => {
  const store = configureStore(props);

  return (
    <Provider store={store}>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<HelloWorldContainer />} />
          {/* Add more routes here */}
          {/* <Route path="/about" element={<About />} /> */}
          {/* <Route path="/contact" element={<Contact />} /> */}
        </Routes>
      </BrowserRouter>
    </Provider>
  );
};

export default HelloWorldApp;
```

**Key points:**

- `<Provider>` wraps `<BrowserRouter>` so all routes have Redux access
- Use `<Routes>` and `<Route>` (not `<Switch>` from React Router v5)
- Use `element` prop to specify components (not `component` or `render` props from v5)
- Routes are automatically matched by best fit, not render order

## Server-Side Rendering with React Router

For server rendering, use `StaticRouter` instead of `BrowserRouter`.

**File: `app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.server.jsx`**

```jsx
import React from 'react';
import { renderToString } from 'react-dom/server';
import { StaticRouter } from 'react-router-dom/server';
import { Provider } from 'react-redux';
import { Routes, Route } from 'react-router-dom';

import configureStore from '../store/helloWorldStore';
import HelloWorldContainer from '../containers/HelloWorldContainer';
// Import other components for routing
// import About from '../components/About';
// import Contact from '../components/Contact';

const HelloWorldApp = (props, railsContext) => {
  const store = configureStore(props);
  const { location } = railsContext;

  const html = renderToString(
    <Provider store={store}>
      <StaticRouter location={location}>
        <Routes>
          <Route path="/" element={<HelloWorldContainer />} />
          {/* Add more routes here */}
          {/* <Route path="/about" element={<About />} /> */}
          {/* <Route path="/contact" element={<Contact />} /> */}
        </Routes>
      </StaticRouter>
    </Provider>,
  );

  return { renderedHtml: html };
};

export default HelloWorldApp;
```

**Important changes from React Router v5:**

- Import `StaticRouter` from `'react-router-dom/server'` (not `'react-router'`)
- Use `<Routes>` and `<Route>` with `element` prop
- `location` prop takes a string path from `railsContext`
- No need for `match()` or `RouterContext` - simplified API

## Rails Routes Configuration

**Critical Step:** To support direct URL visits, browser refresh, and server-side rendering, you must configure Rails to handle all React Router paths.

Add a wildcard route in your `config/routes.rb`:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Your main route
  get 'your_path', to: 'your_controller#index'

  # Wildcard catch-all for React Router sub-routes
  get 'your_path/*path', to: 'your_controller#index'
end
```

**Example:**

```ruby
# For a HelloWorld app with React Router
get 'hello_world', to: 'hello_world#index'
get 'hello_world/*path', to: 'hello_world#index'
```

This configuration ensures:

- `/hello_world` → Renders your React app
- `/hello_world/about` → Rails serves the same view, React Router handles routing
- `/hello_world/contact` → Rails serves the same view, React Router handles routing
- Browser refresh works on any route
- Direct URL visits work with server-side rendering

**Important:** Your React Router paths should match your Rails route structure. If Rails serves your app at `/hello_world`, your React Router routes should start with `/hello_world`:

```jsx
<Routes>
  <Route path="/hello_world" element={<Home />} />
  <Route path="/hello_world/about" element={<About />} />
  <Route path="/hello_world/contact" element={<Contact />} />
</Routes>
```

## Example Application

For a complete example of React on Rails with React Router, see the [React Webpack Rails Tutorial](https://github.com/shakacode/react-webpack-rails-tutorial).

For a practical example of route organization, see the [routes configuration file](https://github.com/shakacode/react-webpack-rails-tutorial/blob/master/client/app/bundles/comments/routes/routes.jsx) from the tutorial.

**Note:** This tutorial uses a legacy directory structure (`client/app/bundles`) from earlier React on Rails versions. Modern projects use `app/javascript/src/` structure as shown in this guide. The React Router integration patterns remain applicable.

## Additional Resources

- [React Router Official Documentation](https://reactrouter.com/)
- [React Router v6 Migration Guide](https://reactrouter.com/docs/en/v6/upgrading/v5) - If upgrading from v5
- [React on Rails Turbo/Turbolinks Guide](./turbolinks.md)

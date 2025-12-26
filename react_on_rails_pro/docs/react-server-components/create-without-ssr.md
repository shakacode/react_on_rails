# Create React Server Component without SSR

React Server Components are a new way to build web applications. It has many advantages you can see in the [React Server Components Glossary](./glossary.md). Also, we need to differentiate between Server Components and Server Side Rendering (SSR). You don't need to use SSR to use Server Components.

In this article, we will create a Server Component without SSR.

## Prepare RORP Project to use Server Components

To use Server Components in your React on Rails Pro project, you need to follow these steps:

1. Install the latest version of React on Rails and React on Rails Pro:

Note: These versions are not released yet, they are still in development. But they will have these versions when released.

```bash
yarn add react-on-rails@15.0.0-alpha.2 react-on-rails-pro@4.0.0
bundle add react_on_rails@15.0.0.alpha.2 react_on_rails_pro@4.0.0
```

Also, install version 19 of React, React DOM, and `react-on-rails-rsc`:

```bash
yarn add react@19.0.0 react-dom@19.0.0 react-on-rails-rsc@19.0.0
```

> [!NOTE]
> While React Server Components in React 19 are stable, the underlying APIs used to implement React Server Components bundlers may break between minor versions (19.x). According to the [React Documentation](https://react.dev/reference/rsc/server-components#how-do-i-build-support-for-server-components). React on Rails Pro currently only supports React 19.0.x.

2. Enable support for Server Components in React on Rails Pro configuration:

```ruby
# config/initializers/react_on_rails_pro.rb

ReactOnRailsPro.configure do |config|
  config.enable_rsc_support = true
end
```

> [!IMPORTANT]
> After enabling RSC support, you must add the `'use client';` directive at the top of your JavaScript entry points (packs) that are not yet migrated to support Server Components.
>
> This directive tells React that these files should be treated as client components. You don't need to add this directive to all JavaScript files - only the entry points. Any file imported by a file marked with `'use client';` will automatically be treated as a client component as well. Without this directive, React will assume these files contain Server Components, which will cause errors if the components use client-side features like:
>
> - `useState` or other state hooks
> - `useEffect` or other effect hooks
> - Event handlers (onClick, onChange, etc.)
> - Browser APIs

For example:

```js
// app/javascript/client/app/ror-auto-load-components/HomePage.jsx
'use client';

// ... existing code ...
```

3. Create a new Webpack configuration to generate React Server Components bundles (RSC bundles) (usually named `rsc-bundle.js`).

RSC bundle is a clone of the server bundle `server-bundle.js` but we just add the RSC loader `react-on-rails-rsc/WebpackLoader` to the used loaders.

You can check the [How React Server Components work](how-react-server-components-work.md) for more information about the RSC loader (It's better to read it after reading this article).

Create a new file `config/webpack/rscWebpackConfig.js`:

```js
// use the same config as serverWebpackConfig.js but add the RSC loader
const serverWebpackConfig = require('./serverWebpackConfig');

// Function that extracts a specific loader from a webpack rule
function extractLoader(rule, loaderName) {
  return rule.use.find((item) => {
    let testValue;

    if (typeof item === 'string') {
      testValue = item;
    } else if (typeof item.loader === 'string') {
      testValue = item.loader;
    }

    return testValue.includes(loaderName);
  });
}

const configureRsc = () => {
  const rscConfig = serverWebpackConfig();

  // Update the entry name to be `rsc-bundle` instead of `server-bundle`
  const rscEntry = {
    'rsc-bundle': rscConfig.entry['server-bundle'],
  };
  rscConfig.entry = rscEntry;

  // Add the RSC loader before the babel loader
  const rules = rscConfig.module.rules;
  rules.forEach((rule) => {
    if (Array.isArray(rule.use)) {
      // Ensure this loader runs before the JS loader (Babel loader in this case) to properly exclude client components from the RSC bundle.
      // If your project uses a different JS loader, insert it before that loader instead.
      const babelLoader = extractLoader(rule, 'babel-loader');
      if (babelLoader) {
        rule.use.push({
          loader: 'react-on-rails-rsc/WebpackLoader',
        });
      }
    }
  });

  // Add the `react-server` condition to the resolve config
  // This condition is used by React and React on Rails to know that this bundle is a React Server Component bundle
  // The `...` tells webpack to retain the default Webpack conditions (In this case will keep the `node` condition because the bundle targets node)
  rscConfig.resolve = {
    ...rscConfig.resolve,
    conditionNames: ['react-server', '...'],
  };

  // Update the output bundle name to be `rsc-bundle.js` instead of `server-bundle.js`
  rscConfig.output.filename = 'rsc-bundle.js';
  return rscConfig;
};

module.exports = configureRsc;
```

Add the new RSC Webpack configuration to the bundle configuration returned by `webpackConfig` function in `config/webpack/ServerClientOrBoth.js` file:

```js
// config/webpack/ServerClientOrBoth.js
const rscWebpackConfig = require('./rscWebpackConfig');
// existing code...

const webpackConfig = (envSpecific) => {
  const rscConfig = rscWebpackConfig();
  // existing code...
  } else if (process.env.RSC_BUNDLE_ONLY) {
    // eslint-disable-next-line no-console
    console.log('[React on Rails] Creating only the RSC bundle.');
    result = rscConfig;
  } else {
    // default is the standard client and server build
    // eslint-disable-next-line no-console
    console.log('[React on Rails] Creating both client and server bundles.');
    result = [clientConfig, serverConfig, rscConfig];
  }

  return result;
};
```

Finally, update `Procfile.dev` to generate the RSC bundle when running the development server:

```
# Procfile.dev
# existing code...

rails-rsc-assets: HMR=true RSC_BUNDLE_ONLY=yes bin/shakapacker --watch

```

This change will make the bundling process generate a new bundle named `rsc-bundle.js` in addition to the `server-bundle.js` and `client-bundle.js` bundles.

Then, we need to tell React on Rails to upload the `rsc-bundle.js` file to the renderer while uploading the server bundle.

```ruby
# config/initializers/react_on_rails.rb
ReactOnRailsPro.configure do |config|
  config.rsc_bundle_js_file = "rsc-bundle.js"
end
```

4. Make the client bundle use the React Server Components plugin `react-on-rails-rsc/WebpackPlugin`, for more information about this plugin, you can check the [How React Server Components work](how-react-server-components-work.md) (It's better to read it after reading this article).

```js
// config/webpack/clientWebpackConfig.js
const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
// existing code...

const configureClient = () => {
  // existing code...

  config.plugins.push(new RSCWebpackPlugin({ isServer: false }));

  return config;
};

module.exports = configureClient;
```

5. Make the server bundle use the React Server Components plugin `react-on-rails-rsc/WebpackPlugin`

```js
// config/webpack/serverWebpackConfig.js
const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
// existing code...

const configureServer = () => {
  // existing code...

  config.plugins.push(new RSCWebpackPlugin({ isServer: true }));

  return config;
};

module.exports = configureServer;
```

## Create a React Server Component

Create a new file `app/javascript/components/ReactServerComponent.js`:

```js
// app/javascript/components/ReactServerComponent.js
import React from 'react';

// Heavy libraries that won't be sent to the client
import moment from 'moment';
import lodash from 'lodash';

// Server components can use Node.js modules, access the server files, make database queries, etc.
import os from 'os';

// This async component demonstrates server-side functionality
async function ReactServerComponent() {
  console.log('Hello from ReactServerComponent');

  // Using moment.js for complex date calculations
  const now = moment();
  const nextWeek = moment().add(7, 'days');
  const formattedDateRange = `${now.format('MMMM Do YYYY')} to ${nextWeek.format('MMMM Do YYYY')}`;

  // Using lodash for data manipulation
  const sampleArray = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  const chunks = lodash.chunk(sampleArray, 3);

  // Getting system information using Node's os module
  const serverInfo = {
    platform: os.platform(),
    type: os.type(),
    release: os.release(),
    uptime: Math.floor(os.uptime() / 3600), // Convert to hours
    totalMemory: Math.floor(os.totalmem() / (1024 * 1024 * 1024)), // Convert to GB
    freeMemory: Math.floor(os.freemem() / (1024 * 1024 * 1024)), // Convert to GB
    cpus: os.cpus().length,
  };

  return (
    <div className="server-component-demo">
      <h2>React Server Component Demo</h2>

      <section>
        <h3>Date Calculations (using moment.js)</h3>
        <p>Date Range: {formattedDateRange}</p>
      </section>

      <section>
        <h3>Array Manipulation (using lodash)</h3>
        <div>
          {chunks.map((chunk, index) => (
            <div key={index}>
              Chunk {index + 1}: {chunk.join(', ')}
            </div>
          ))}
        </div>
      </section>

      <section>
        <h3>Server System Information (using Node.js os module)</h3>
        <ul>
          <li>Platform: {serverInfo.platform}</li>
          <li>OS Type: {serverInfo.type}</li>
          <li>OS Release: {serverInfo.release}</li>
          <li>Server Uptime: {serverInfo.uptime} hours</li>
          <li>Total Memory: {serverInfo.totalMemory} GB</li>
          <li>Free Memory: {serverInfo.freeMemory} GB</li>
          <li>CPU Cores: {serverInfo.cpus}</li>
        </ul>
      </section>

      <div className="note">
        <p>
          <strong>Note:</strong> The heavy libraries (moment.js, lodash) and Node.js modules (os) used in this
          component stay on the server and are not shipped to the client, reducing the client bundle size
          significantly.
        </p>
      </div>
    </div>
  );
}

export default ReactServerComponent;
```

## Create a React Server Component Page

Create a new file `app/javascript/packs/components/ReactServerComponentPage.jsx`:

```js
// app/javascript/packs/components/ReactServerComponentPage.jsx

import React from 'react';
import ReactServerComponent from '../../components/ReactServerComponent';

const ReactServerComponentPage = () => {
  return (
    <div>
      <ReactServerComponent />
    </div>
  );
};

export default ReactServerComponentPage;
```

## Register the React Server Component Page

If you enabled `auto_load_bundle` in your `config/initializers/react_on_rails.rb` file, you don't need to register the React Server Component Page. It will be registered automatically.

If you didn't enable `auto_load_bundle`, you need to register the React Server Component Page manually.

```js
// client/app/packs/server-bundle.js
import registerServerComponent from 'react-on-rails/registerServerComponent/server';
import ReactServerComponentPage from './components/ReactServerComponentPage';

registerServerComponent({
  ReactServerComponentPage,
});
```

```js
// client/app/packs/client-bundle.js
import registerServerComponent from 'react-on-rails/registerServerComponent/client';

registerServerComponent({ rscPayloadGenerationUrlPath: 'rsc_payload/' }, 'ReactServerComponentPage');
```

As you can see, server components are not registered using the `ReactOnRails.register` function. Instead, we use the `registerServerComponent` function to register the server component. Also, `registerServerComponent` has different options for the client bundle and the server bundle.

- For the server bundle, the component itself is passed to the `registerServerComponent` function, so the component is bundled into the server bundle.
- For the client bundle, we pass the component name as an argument to the `registerServerComponent` function, so the component is not bundled into the client bundle.

As you can see at [How React Server Components work](how-react-server-components-work.md):

- Server components are rendered on the client using the rsc payload not the component itself.

And as you can see at [React Server Components Rendering Flow](./rendering-flow.md):

- In the future, the server bundle will use the RSC payload to render the server component on the server side as well.

The `rscPayloadGenerationUrlPath` option will be explained in detail later in this document. For now, just know that it specifies the base URL path for React Server Component requests.

## Add the React Server Component Rendering URL Path to the Rails Routes

Add the following route to your `config/routes.rb` file:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  rsc_payload_route
end
```

This will add the `/rsc_payload` path to the routes. This is the base URL path that will receive requests from the client to render the React Server Components. `rsc_payload_route` is explained in the [How React Server Components work](how-react-server-components-work.md) document.

## Add Route to the React Server Component Page

Add the following route to the `config/routes.rb` file:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  get "react_server_component_without_ssr", to: "pages#react_server_component_without_ssr"
end
```

This route will be used to render the React Server Component Page.

## Create the React Server Component Page View

Create a new file `app/views/pages/react_server_component_without_ssr.html.erb`:

```erb
<%= react_component("ReactServerComponentPage",
    prerender: false,
    trace: true,
    id: "ReactServerComponentPage-react-component-0") %>

<h1>React Server Component without SSR</h1>
```

## Run the Development Server

Run the development server:

```bash
bin/dev
```

Navigate to the React Server Component Page:

```
http://localhost:3000/react_server_component_without_ssr
```

You should see the React Server Component Page rendered in the browser.

![image](https://github.com/user-attachments/assets/053466e2-6e59-4f41-9bda-f87d001a647a)

## Checking the React Server Component Page

Looking at the network tab in your browser's developer tools, you'll notice that the React Server Component Page bundle `ReactServerComponentPage.js` is only 1.4KB in size (note that this is in development mode, so the bundle is not minified). Examining the bundle's contents reveals that it doesn't include the actual `ReactServerComponent` component code or any of its dependencies like `lodash` or `moment` libraries. This small bundle size demonstrates one of the key benefits of React Server Components - the ability to keep client-side JavaScript bundles minimal by executing component code on the server.

![image](https://github.com/user-attachments/assets/d464f291-54e6-4d5f-b2e2-699292c26143)

Also, by looking at the console, we can see the log

```
[SERVER] Hello from ReactServerComponent
```

The `[SERVER]` prefix indicates that the component was executed on the server side. The absence of any client-side logs confirms that no client-side rendering or hydration occurred. This demonstrates a key characteristic of React Server Components - they run exclusively on the server without requiring any JavaScript execution in the browser, leading to improved performance and reduced client-side bundle sizes.

## How the React Server Component Page is Rendered on Browser?

We can get the answer from the network tab in the browser's developer tools. We can see there is a fetch request to the `/rsc_payload/ReactServerComponentPage` path. This is the `rsc_payload` route that we added to the routes in the previous steps and it accepts the component name `ReactServerComponentPage` as a parameter.

![image](https://github.com/user-attachments/assets/c0059975-206a-4699-9d4b-abf9799aa142)

If we click on the fetch request, we can see the response.

![image](https://github.com/user-attachments/assets/7ebcd16a-aa4e-47bf-ae9b-62e6c8103967)

The response contains two main parts:

1. The React Server Component (RSC) payload - This is a special format designed by React for serializing server components and transmitting them to the client. The RSC payload includes:
   - The component's rendered output
   - Any data props that were passed to the client components
   - References to client components that need to be hydrated

2. React on Rails metadata - Additional data needed by React on Rails for:
   - Replaying server-side console logs in the client
   - Error tracking and reporting

The RSC payload format and how React processes it is explained in detail in the [How React Server Components work](how-react-server-components-work.md) document.

## Next Steps

Now that you understand the basics of React Server Components, you can proceed to the next article: [Add Streaming and Interactivity to RSC Page](./add-streaming-and-interactivity.md) to learn how to enhance your RSC page with streaming capabilities and client-side interactivity.

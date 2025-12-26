# How React Server Components work

React Server Components (RSC) enable server-side component execution with client-side streaming. This document explains the underlying mechanisms and technical details of how RSC works under the hood.

## Bundling Process

We showed in the [Create a React Server Component without SSR](./create-without-ssr.md) article how to bundle React Server Components. During bundling, we used:

### RSC Webpack Loader

The `react-on-rails-rsc/WebpackLoader` is a custom loader that removes the client components and their dependencies from the RSC bundle and replace them with client references that tell the rsc runtime that there is a client component entry point in this place.

The RSC Webpack Loader works when it finds a file with the `'use client'` directive on top of it.

```js
// app/javascript/client/app/components/HomePage.jsx
'use client';

import Footer from './Footer';

export const Header = () => {
  return <div>Header</div>;
};

export default function HomePage() {
  return (
    <div>
      <Header />
      <div>Home Page</div>
      <Footer />
    </div>
  );
}
```

It replaces all exports of the file with the client references.

> [!NOTE]
> The code shown below represents internal implementation details of how React Server Components work under the hood. You don't need to understand these details to use React Server Components effectively in your application. This section is included for those interested in the technical implementation.

```js
import { registerClientReference } from 'react-server-dom-webpack/server';

export const Header = registerClientReference(
  function () {
    throw new Error(
      "Attempted to call Header() from the server but Header is on the client. It's not possible to invoke a client function from the server, it can only be rendered as a Component or passed to props of a Client Component.",
    );
  },
  'file:///path/to/src/HomePage.jsx',
  'Header',
);

export default registerClientReference(
  function () {
    throw new Error(
      "Attempted to call the default export of file:///path/to/src/HomePage.jsx from the serverbut it's on the client. It's not possible to invoke a client function from the server, it can only be rendered as a Component or passed to props of aClient Component.",
    );
  },
  'file:///path/to/src/HomePage.jsx',
  'default',
);
```

When a file is marked with `'use client'`, the RSC Webpack Loader replaces all component exports with `ClientReference` objects. The `registerClientReference` function takes three arguments:

1. A function that throws an error if someone tries to call the component function directly instead of rendering it as a component
2. A string representing the file path of the client component, which serves as part of its unique identifier
3. A string with the export name ("default" for default exports, or the named export identifier)

The second and third arguments are used to identify the client component when it needs to be hydrated in the browser.

Note that all imports from the original file are removed in the transformed code. This includes both the `Footer` component import and any other dependencies that the client components may have used. The client component implementations and their dependencies are removed from the RSC bundle.

### RSC Client Plugin

We also used `react-on-rails-rsc/WebpackPlugin` with the client bundle. It does the following:

1. Adds all files with the `'use client'` directive on top of it as entry points to the client bundle.
2. Creates the `react-client-manifest.json` file that contains the mapping of the client components files to their corresponding webpack chunk IDs.

Let's examine the `react-client-manifest.json` file.

> [!NOTE]
> The code shown below represents internal implementation details of how React Server Components work under the hood. You don't need to understand these details to use React Server Components effectively in your application. This section is included for those interested in the technical implementation.

First, you need to build the client bundle by running:

```bash
CLIENT_BUNDLE_ONLY=true bin/shakapacker
```

> [!NOTE]
> When you run `bin/dev`, the client bundle may not be written to the disk, it's served from the webpack-dev-server. That's why you need to run `CLIENT_BUNDLE_ONLY=true bin/shakapacker` to ensure the client bundle is built and written to the disk.

Then, you can find the `react-client-manifest.json` file in the `public/webpack/development` or `public/webpack/production` directory, depending on the environment you are building for.

Let's search for the client component `ToggleContainer` that we built before in [Add Streaming and Interactivity to RSC Page](./add-streaming-and-interactivity.md) article. You will find the following entry in the `react-client-manifest.json` file:

```json
"file:///path/to/app/javascript/components/ToggleContainer.jsx": {
    "id": "./app/javascript/components/ToggleContainer.jsx",
    "chunks": [
      "client25",
      "js/client25.js"
    ],
    "name": "*"
  },
```

This entry indicates that the `ToggleContainer` client component is included in the `client25` chunk. The `js/client25.js` file contains the client-side code for the `ToggleContainer` component. You can find the `client25` chunk in the `public/webpack/<environment>/js/client25.js` file. Also, the `id` field is the Webpack module ID for the `ToggleContainer` client component. It's used by react runtime to load and hydrate the component in the browser.

If you want to change the file name of the `react-client-manifest.json` file, you can do so by setting the `clientManifestFilename` option in the `react-on-rails-rsc/WebpackPlugin` plugin as follows:

```js
const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

config.plugins.push(
  new RSCWebpackPlugin({
    isServer: false,
    clientManifestFilename: 'client-components-webpack-manifest.json',
  }),
);
```

And because React on Rails Pro uploads the `react-client-manifest.json` file to the renderer while uploading the server bundle and it expects it to be named `react-client-manifest.json`, you need to tell React on Rails Pro that the name is changed to `client-components-webpack-manifest.json`.

```ruby
# config/initializers/react_on_rails.rb
ReactOnRails.configure do |config|
  config.react_client_manifest_file = "client-components-webpack-manifest.json"
end
```

## React Server Component Payload (RSC Payload)

The React Server Component Payload (RSC Payload) is a mechanism that allows you to pass the rendered server components from the server to the client. You can use the `rsc_payload_react_component` helper function to embed the RSC payload of any component in your Rails views. Let's try to embed the RSC payload of the `ReactServerComponentPage` component in the `app/views/pages/react_server_component_page_rsc_payload.html.erb` view.

```erb
<%= rsc_payload_react_component("ReactServerComponentPage") %>
```

Add the route to the `app/config/routes.rb` file.

```ruby
# config/routes.rb
get "/react_server_component_page_rsc_payload", to: "pages#react_server_component_page_rsc_payload"
```

And render the view using the `stream_view_containing_react_components` helper method.

```ruby
# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  include ReactOnRailsPro::Stream

  def react_server_component_page_rsc_payload
    stream_view_containing_react_components(template: "pages/react_server_component_page_rsc_payload")
  end
end
```

When you navigate to the `http://localhost:3000/react_server_component_page_rsc_payload` page, you will see the RSC payload of the `ReactServerComponentPage` component. You will find multiple JSON objects in the response body. Each represents a chunk of the RSC payload.

```json
{
  "html":"<RSC Payload>",
  "consoleReplayScript":"",
  "hasErrors":false,
  "isShellReady":true
}
{
  "html":"<RSC Payload>",
  "consoleReplayScript":"",
  "hasErrors":false,
  "isShellReady":true
}
```

The real RSC payload is embedded in the `html` field. Other fields are used by React on Rails Pro to ensure the RSC payload is rendered correctly and to replay the console logs in the browser.

> [!NOTE]
> using `html` field to refer to the RSC payload may be confusing. It will be changed later to `rscPayload`, but it's an implementation detail and you should not rely on it.

The RSC payload itself is an implementation detail, you don't need to understand it to use React Server Components. But we can notice that it contains the React render tree of the `ReactServerComponentPage` component. Like this:

```rsc
1:["$","div",null,{"className":"server-component-demo","children":[["$","h2",null,{"children":"React Server Component Demo"}],["$","section",null,{"children":[["$","h3",null,{"children":"Date Calculations (using moment.js)"}]]}]]}]
```

The interesting part is how the RSC payload references the client components. Let's take a look at how it references the `ToggleContainer` client component.

```rsc
7:I["./app/javascript/components/ToggleContainer.jsx",["client25","js/client25.js"],"default"]
```

The RSC payload references client components by including:

1. The webpack module ID of the client component (e.g. "./app/javascript/components/ToggleContainer.jsx")
2. The webpack chunk IDs that contain the component code (e.g. ["client25","js/client25.js"])
3. The export name being referenced (e.g. "default")

This information comes from the `react-client-manifest.json` file, which maps client component paths to their corresponding webpack module and chunk IDs. That's why we needed to upload the `react-client-manifest.json` file to the renderer as it's needed to generate the RSC payload.

## Automatically Generate the RSC Payload

Usually, you don't need to generate the RSC payload manually. You can use the `rsc_payload_route` helper method inside the `config/routes.rb` file to automatically add the rsc route that accepts the component name as a parameter and returns the RSC payload.

```ruby
# config/routes.rb
Rails.application.routes.draw do
  rsc_payload_route
end
```

You can change the path of the rsc route by passing the `path` option to the `rsc_payload_route` method.

```ruby
# config/routes.rb
Rails.application.routes.draw do
  rsc_payload_route path: "/flight-payload"
end
```

In this case, ensure you pass the correct path to `registerServerComponent` function in the client bundle.

```js
// client/app/packs/client-bundle.js
import registerServerComponent from 'react-on-rails/registerServerComponent/client';

registerServerComponent(
  {
    rscPayloadGenerationUrlPath: 'flight-payload',
  },
  'ReactServerComponentPage',
);
```

Or if you enabled the `auto_load_bundle` option to make React on Rails automatically register react components, you can pass the path to the `rsc_payload_generation_url_path` config in React on Rails Pro configuration.

```ruby
# config/initializers/react_on_rails.rb
ReactOnRailsPro.configure do |config|
  config.rsc_payload_generation_url_path = "flight-payload"
end
```

## Next Steps

To learn more about how React Server Components are rendered in React on Rails Pro, including the rendering flow, bundle types, and upcoming improvements, see [React Server Components Rendering Flow](./rendering-flow.md).

# Server-side rendering with code-splitting using Loadable/Components
by ShakaCode

*Last updated March 17, 2020*

## Introduction
The [React library recommends](https://loadable-components.com/docs/getting-started/) the use of React.lazy for code splitting with dynamic imports except
when using server-side rendering. In that case, as of February, 2020, they recommend [Loadable Components](https://loadable-components.com)
for server-side rendering with dynamic imports. 

Note, in 2019 and prior, the code-splitting feature was implemented using `react-loadable`. The React
team no longer recommends that library. The new way is far preferable.

## Installation

```
yarn add  @loadable/babel-plugin @loadable/component @loadable/server @loadable/webpack-plugin
```

### Summary
- [`@loadable/babel-plugin`](https://loadable-components.com/docs/getting-started/) - The plugin transforms your code to be ready for Server Side Rendering. 
- `@loadable/component` - Main library for creating loadable components.
- `@loadable/server` - Has functions for collecting chunks and provide style, script, link tags for the server.
- `@loadable/webpack-plugin` - The plugin to create a stats file with all chunks, assets information.

## Configuration

These instructions mainly repeat the [server-side rendering steps from the official documentation for Loadable Components](https://loadable-components.com/docs/server-side-rendering/), but with some additions specifically to react_on_rails_pro.

### Webpack

#### Server Bundle Configuration

See example of server configuration differences in the loadable-components [example of the webpack.config.babel.js
for server-side rendering](https://github.com/gregberge/loadable-components/blob/master/examples/server-side-rendering/webpack.config.babel.js)

You need to configure 3 things:
1. `target` 
  a. client-side: `web`
  b. server-side: `node`
2. `output.libraryTarget`
  a. client-side: `undefined`
  b. server-side: `commonjs2`
3. babel-loader options.caller = 'node' or 'web'   
3. `plugins`
  a. server-side:  `new webpack.optimize.LimitChunkCountPlugin({ maxChunks: 1 })`

```
{
  target: 'node',
  plugins: [
    ...,
    new webpack.optimize.LimitChunkCountPlugin({ maxChunks: 1 })
  ]
}
```

Explanation:

- `target: 'node'` is required to be able to run the server bundle with the dynamic import logic on nodejs.
If that is not done, webpack will add and invoke browser-specific functions to fetch the chunks into the bundle, which throws an error on server-rendering.

- `new webpack.optimize.LimitChunkCountPlugin({ maxChunks: 1 })`
The react_on_rails_pro vm-renderer expects only one single server-bundle. In other words, we cannot and do not want to split the server bundle.

#### Client config

For the client config we only need to add the plugin:
```
{
  plugins: [
    ...,
     new LoadablePlugin({ filename: 'loadable-stats.json' })
  ]
}
```
This plugin collects all the information about entrypoints, chunks, and files, that have these chunks and creates a stats file during client bundle build.
This stats file is used later to map rendered components to file assets. While you can use any filename, our documentation will use the default name.

### Babel

Per [the docs](https://loadable-components.com/docs/babel-plugin/#transformation):
> The plugin transforms your code to be ready for Server Side Rendering

Add this to `babel.config.js`:
```
{
  "plugins": ["@loadable/babel-plugin"]
}
```
https://loadable-components.com/docs/babel-plugin/


### Convert components into loadable components

Instead of importing the component directly, use a dynamic import:

```
import load from '@loadable/component'
const MyComponent = load(() => import('./MyComponent'))
```

**Please note that babel must not be configured to strip comments, since the chunk name is defined in a comment.**

### Server and client entries

#### Client

In the client bundle, we need to wrap the `hydrate` call into a `loadableReady` function.
So, hydration will be fired only after all necessary chunks preloads. In this example below,
`ClientApp` is registering as `App`. 

```js
import React from 'react';
import ReactOnRails from 'react-on-rails';
import { hydrate } from 'react-dom'
import { loadableReady } from '@loadable/component'
import App from './App';

const ClientApp = (props, railsContext, domId) => {
  loadableReady(() => {
    const root = document.getElementById(domId)
    hydrate(<App {...props} />, root)
  })
}

ReactOnRails.register({
  App: ClientApp,
});
```

#### Server

The purpose of the server function is to collect all rendered chunks and pass them as script, link, 
style tags to the Rails view. In this example below, `ServerApp` is registering as `App`. 

```js
import React from 'react';
import ReactOnRails from 'react-on-rails';
import { ChunkExtractor } from '@loadable/server'
import App from './App'
import path from 'path'

const ServerApp = (props, railsContext) => {
  // This loadable-stats file was generated by `LoadablePlugin` in client webpack config.
  // You must configure the path to resolve per your setup. If you are copying the file to
  // a remote server, the file should be a sibling of this file. 
  // __dirname is going to be the directory where the server-bundle.js exists
  // Note, React on Rails Pro automatically copies the loadable-stats.json to the same place as the
  // server-bundle.js. Thus, the __dirname of this code is where we can find loadable-stats.json.
  // Be sure to configure ReactOnRailsPro.config.assets_top_copy to this file.
  const statsFile = path.resolve(__dirname, 'loadable-stats.json');

  // This object is used to search filenames by corresponding chunk names.
  // See https://loadable-components.com/docs/api-loadable-server/#chunkextractor
  // for the entryPoints, pass an array of all your entryPoints using dynamic imports
  const extractor = new ChunkExtractor({ statsFile, entrypoints: ['client-bundle'] })

  // It creates the wrapper `ChunkExtractorManager` around `App` to collect chunk names of rendered components.
  const jsx = extractor.collectChunks(<App {...props} railsContext={railsContext} />)

  const componentHtml = renderToString(jsx);

  return {
    renderedHtml: {
      componentHtml,
      // Returns all the files with rendered chunks for furture insert into rails view.
      linkTags: extractor.getLinkTags(),
      styleTags: extractor.getStyleTags(),
      scriptTags: extractor.getScriptTags()
    }
  };
};

ReactOnRails.register({
  App: ServerApp,
});
```

## Configure react_on_rails_pro

### React on Rails Pro
You must sent `config.assets_top_copy` so that the vm-renderer will have access to the loadable-stats.json.

```ruby
  config.assets_to_copy = Rails.root.join("public", "webpack", Rails.env, "loadable-stats.json")
```

Your server rendering code, per the above, will find this file like this:

```js
  const statsFile = path.resolve(__dirname, 'loadable-stats.json');
``` 

Note, if `__dirname` is not working in your webpack build, that's because you didn't set `node: false`
in your webpack configuration. That turns off the polyfills for things like `__dirname`.


### VM Renderer
In your `vm-renderer.js` file which runs node renderer, you need to specify `supportModules` options as follows:
```js
const path = require('path');
const env = process.env;
const { reactOnRailsProVmRenderer } = require('react-on-rails-pro-vm-renderer');

const config = {
  ...
  supportModules: env.RENDERER_SUPPORT_MODULES || null,
};
...

reactOnRailsProVmRenderer(config);
```

## Rails View

```erb
<% res = react_component_hash("App", props: {}, prerender: true) %>
<%= content_for :link_tags, res['linkTags'] %>
<%= content_for :style_tags, res['styleTags'] %> 

<%= res['componentHtml'].html_safe %>

<%= content_for :script_tags, res['scriptTags'] %>
```

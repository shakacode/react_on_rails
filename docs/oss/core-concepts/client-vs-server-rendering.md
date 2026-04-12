# Client-Side Rendering vs. Server-Side Rendering

_Also, see [our React server-rendering documentation](../core-concepts/react-server-rendering.md)._

In most cases, you should use the `prerender: false` (default behavior) with the provided helper method to render the React component from your Rails views. In some cases, such as when SEO is vital, or many users will not have JavaScript enabled, you can enable server-rendering by passing `prerender: true` to your helper, or you can simply change the default in `config/initializers/react_on_rails`.

Now the server will interpret your JavaScript. The default is to use [ExecJS](https://github.com/rails/execjs) and pass the resulting HTML to the client. ExecJS auto-detects the best available runtime, preferring mini_racer and Bun over Node.js when installed. You can override the runtime with the `EXECJS_RUNTIME` environment variable. See the [ExecJS readme](https://github.com/rails/execjs/blob/master/README.md) for all available runtimes. For details on ExecJS constraints with timers, async, and browser APIs, see [ExecJS Limitations](./execjs-limitations.md).

> **Warning:** Since React DOM Server 18+ requires `TextEncoder` (which `mini_racer` does not provide), `mini_racer` is effectively unsupported for server rendering with modern React. Consider using the Node.js ExecJS runtime or upgrading to the [Node Renderer](./execjs-limitations.md#migrating-to-the-node-renderer). If you cannot switch runtimes immediately and need a temporary `TextEncoder` polyfill, see [this comment](https://github.com/shakacode/react_on_rails/issues/1457#issuecomment-1165026717).

## Polyfill Requirements for `target: 'web'` Server Bundles

When the server bundle is built with webpack `target: 'web'` (the default for the OSS configuration), webpack 5 does **not** auto-polyfill Node.js-specific globals such as `Buffer` (webpack 4 did this automatically; webpack 5 does not). Additionally, Web APIs like `TextEncoder` are absent in `mini_racer`'s bare V8 isolate regardless of webpack target. Note that while `process.env.NODE_ENV` is still substituted at build time via `DefinePlugin`, the full `process` object is not available. This means:

- **ExecJS with Node.js runtime**: Works because Node.js provides these globals natively, regardless of the webpack target.
- **ExecJS with `mini_racer`**: Runs in a bare V8 isolate with none of these globals. The bundle relies on polyfills or fallbacks for any Node.js APIs it uses.
- **`target: 'node'`**: When using the React on Rails Pro Node Renderer, set `target: 'node'` in your server webpack config. This tells webpack to treat Node.js built-ins as externals, resolving them at runtime from the Node.js process rather than attempting to bundle or polyfill them.

The React on Rails OSS package does not use `Buffer` in its ExecJS rendering path. If your own server-rendered code calls `Buffer` directly, you will need to supply a polyfill.

For the full list of ExecJS constraints, see [ExecJS Limitations](./execjs-limitations.md).

If you want to maximize the performance of your server rendering, then you want to use React on Rails Pro which uses NodeJS to do the server rendering. See the [docs for React on Rails Pro](../../pro/react-on-rails-pro.md).

If you open the HTML source of any web page using React on Rails, you'll see the 3 parts of React on Rails rendering:

1. A script tag containing the properties of the React component, such as the registered name and any props. A JavaScript function runs after the page loads, using this data to build and initialize your React components.
2. The wrapper div `<div id="HelloWorld-react-component-0">` specifies the div where to place the React rendering. It encloses the server-rendered HTML for the React component.
3. Additional JavaScript is placed to console-log any messages, such as server rendering errors. Note: these server side logs can be configured only to be sent to the server logs.

**Note**: If server rendering is not used (prerender: false), then the major difference is that the HTML rendered for the React component only contains the outer div: `<div id="HelloWorld-react-component-0"/>`. The first specification of the React component is just the same.

## Different Server-Side Rendering Code (and a Server-Specific Bundle)

You may want different code for your server-rendered components running server-side versus client-side. For example, if you have an animation that runs when a component is displayed, you might need to turn that off when server rendering. One way to handle this is conditional code like `if (window) { doClientOnlyCode() }`.

Another way is to use a separate Webpack configuration file that can use a different server-side entry file, like `serverRegistration.js` as opposed to `clientRegistration.js`. That would set up different code for server rendering.

For details on techniques to use different code for client and server rendering, see: [How to use different versions of a file for client and server rendering](https://forum.shakacode.com/t/how-to-use-different-versions-of-a-file-for-client-and-server-rendering/1352). _Requires creating a free account._

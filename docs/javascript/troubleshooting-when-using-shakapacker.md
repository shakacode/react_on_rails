# Client rendering crashes when configuring `optimization.runtimeChunk` to `multiple`

## Context

1. Ruby version: 3.1
2. Rails version: 7.0.6
3. Shakapacker version: 6.6.0
4. React on Rails version: 13.3.5

## The failure

Configuring Webpack to embed the runtime in each chunk and calling `react_component` twice in a Rails view/partial causes the client render to crash with the following error:

```
Could not find component registered with name XXX. Registered component names include [ YYY ]. Maybe you forgot to register the component?
```

```
VM4859 clientStartup.js:132 Uncaught Error: ReactOnRails encountered an error while rendering component: XXX. See above error message.
    at Object.get (ComponentRegistry.js:40:15)
    at Object.getComponent (ReactOnRails.js:211:44)
    at render (VM4859 clientStartup.js:103:53)
    at forEachReactOnRailsComponentRender (VM4859 clientStartup.js:138:9)
    at reactOnRailsPageLoaded (VM4859 clientStartup.js:164:5)
    at renderInit (VM4859 clientStartup.js:205:9)
    at onPageReady (VM4859 clientStartup.js:234:9)
    at HTMLDocument.onReadyStateChange (VM4859 clientStartup.js:238:13)
```

## Configs

### Webpack configuration

```js
optimization: {
  runtimeChunk: 'multiple'
},
```

### Rails view

```haml
= react_component("XXX", props: @props)
= yield
= react_component("YYY", props: @props)
```

## The problem

Configuring Webpack to embed the runtime in each chunk and calling `react_component` twice in a Rails view/partial causes the client render to crash.

Read more at https://github.com/shakacode/react_on_rails/issues/1558.

## Solution

To overcome this issue, we could use [shakapacker](https://github.com/shakacode/shakapacker)'s default optimization configuration (pseudo-code):

```js
const { webpackConfig: baseClientWebpackConfig } = require('shakapacker');

// ...

config.optimization = baseClientWebpackConfig.optimization;
```

As it set the `optimization.runtimeChunk` to `single`. [See its source](https://github.com/shakacode/shakapacker/blob/cdf32835d3e0949952b8b4b53063807f714f9b24/package/environments/base.js#L115-L119):

```js
  optimization: {
    splitChunks: { chunks: 'all' },

    runtimeChunk: 'single'
  },
```

Or set `optimization.runtimeChunk` to `single` directly.

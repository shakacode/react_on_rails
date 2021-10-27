[![CircleCI](https://circleci.com/gh/shakacode/react_on_rails_pro.svg?style=svg&circle-token=faed0841684a8e88fcf06945ef2b62ded3b124a8)](https://circleci.com/gh/shakacode/react_on_rails_pro)

_See the [CHANGELOG](./CHANGELOG.md) for release updates and **upgrade** details._

# React on Rails Pro

Node rendering and caching performance enhancements for [React on Rails](https://github.com/shakacode/react_on_rails).

## Getting Started
The best way to see how React on Rails Pro works is to install this repo locally and take a look at
the two example applications:

1. [spec/dummy](./spec/dummy/README.md)
   1. Uses a @rails/webpacker standard configuration.
   1. Has pages that demonstrate:
      1. caching
      2. loadable-components
   1. Has all the basic react_on_rails specs that run against the Node Renderer 
2. [spec/loadable](./spec/loadable/README.md): 
   1. Uses a custom webpack configuration.
   2. Demonstrates using HMR and loadable-components.
   3. Has almost same the example that is present in [loadable-components for SSR](https://github.com/gregberge/loadable-components/tree/main/examples/server-side-rendering)
   
See the README.md in those sample apps for more details.

## Features

### Caching
Caching of SSR is critical for achieving optimum performance.

* **Fragment Caching**: for `react_component` and `react_component_hash`, including lazy evaluation of props.
* **Prerender Caching**: Server rendering JavaScript evaluation is cached if `prerender_caching` is turned on in your Rails config. This applies to all JavaScript evaluation methods.

See [docs/caching](./docs/caching.md) for more details.

### Clearing of Global State
If you detect that some library used in server-rendering is leaking state between calls to server render, then you can set the `config.ssr_pre_hook_js` in your `config/initializers/react_on_rails_pro.rb` to run some JavaScript to clear the globally leaked state at the beginning of each call to server render.

For more details, see [Rails Configuration](./docs/configuration.md).

### React On Rails Pro Node Renderer
The "React on Rails Pro Node Renderer" provides more efficient server rendering on a standalone Node JS server.
See the [Node Renderer Docs](docs/node-renderer/basics.md).

### Bundle Caching
Don't wait for the same webpack bundles to built over and over. See the [bundle-caching docs](./docs/bundle-caching.md).

## Other Utility Methods
See the [Ruby API](docs/ruby-api.md).

## References

* [Installation](./docs/installation.md)
* [Caching](./docs/caching.md)
* [Rails Configuration](./docs/configuration.md)
* [Node Renderer Docs](./docs/node-renderer/basics.md)

## Contributing
Please see [CONTRIBUTING](CONTRIBUTING.md) for more details.

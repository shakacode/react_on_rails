[![CircleCI](https://circleci.com/gh/shakacode/react_on_rails_pro.svg?style=svg&circle-token=faed0841684a8e88fcf06945ef2b62ded3b124a8)](https://circleci.com/gh/shakacode/react_on_rails_pro)

_See the tags for the latest release. And the [CHANGELOG](./CHANGELOG.md) for upgrade details._

# React on Rails Pro

Node rendering and caching performance enhancements for [React on Rails](https://github.com/shakacode/react_on_rails).

# Features

## Caching

## Clearing of Global State
If you detect that some library used in server-rendering is leaking state between calls to server render, then you can set the `config.ssr_pre_hook_js` in your `config/initializers/react_on_rails_pro.rb` to run some JavaScript to clear the globally leaked state at the beginning of each call to server render.

For more details, see [Rails Configuration](./docs/configuration.md).

### Server Rendering
Server rendering JavaScript evaluation is cached if `prerender_caching` is turned on in your Rails config. This applies to all JavaScript evaluation methods.

### Fragment Caching View Helpers
* Fragment caching for `react_component` and `react_component_hash`, including lazy evaluation of props.
* See [Caching](./docs/caching.md) for details.

## React On Rails Pro Node Renderer
The "React on Rails Pro Node Renderer" provides more efficient server rendering on a standalone Node JS server.
See the [Node Renderer Docs](docs/node-renderer/basics.md).

## Other Utility Methods
See the [Ruby API](docs/ruby-api.md).

# References

* [Installation](./docs/installation.md)
* [Caching](./docs/caching.md)
* [Rails Configuration](./docs/configuration.md)
* [Node Renderer Docs](./docs/node-renderer/basics.md)
* [HTTP Caching](./docs/http-caching.md)

# Contributing
Please see [CONTRIBUTING](CONTRIBUTING.md) if you want to deploy and test this project locally.

[![CircleCI](https://circleci.com/gh/shakacode/react_on_rails_pro.svg?style=svg&circle-token=faed0841684a8e88fcf06945ef2b62ded3b124a8)](https://circleci.com/gh/shakacode/react_on_rails_pro)

# React on Rails Pro

Node rendering and caching performance enhancements for [React on Rails](https://github.com/shakacode/react_on_rails).

# Features

## Caching
See [Caching](./docs/caching.md) for details.

### Server Rendering
Server rendering JavaScript evaluation is cached if `prerender_caching` is turned on in your Rails config. This applies to all JavaScript evaluation methods.

### Fragment Caching View Helpers
* Fragment caching for `react_component` and `react_component_hash`, including lazy evaluation of props. 

## React On Rails Pro VM Render
The "React on Rails Pro VM Renderer" provides more efficient server rendering on a standalone Node JS server.
See the [VM Renderer Docs](docs/vm-renderer/basics.md).

## Other Utility Methods
See the [Ruby API](docs/ruby-api.md).

# References

* [Caching](./docs/caching.md)
* [Rails Configuration](./docs/configuration.md)
* [VM Renderer Docs](./docs/vm-renderer/basics.md)
* [HTTP Caching](./docs/http-caching.md)

# Contributing
Please see [CONTRIBUTING](CONTRIBUTING.md) if you want to deploy and test this project locally.

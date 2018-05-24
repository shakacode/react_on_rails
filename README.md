[![CircleCI](https://circleci.com/gh/shakacode/react_on_rails_pro.svg?style=svg&circle-token=faed0841684a8e88fcf06945ef2b62ded3b124a8)](https://circleci.com/gh/shakacode/react_on_rails_pro)

# React on Rails Pro

Node rendering and caching performance enhancements for React on Rails!

# Features

## Fragment Caching Helpers
* Fragment caching for react_component, including lazy evaluation of props. See 
[Caching](./docs/caching.md) for details.

## Node VM Render
More efficient server rendering:

1. Configuration option `prerender_caching` which will turn on caching of all requests to evaluation JavaScript code for server rendering.
2. NodeJS server rendering via a standalone Express server.
3. Other helpers related to caching in `lib/react_on_rails_pro/utils.rb`

See the [VM Renderer Docs](docs/vm-renderer/basics.md)

# References

* [Caching](./docs/caching.md)
* [Configuration](./docs/configuration.md)
* [VM Renderer](docs/vm-renderer/basics.md)
* [Using Varnish for HTTP Caching](docs/vm-renderer/configuring-varnish.md)
* [HTTP Caching](./docs/http-caching.md)

## Local deploy

Please see [CONTRIBUTING](CONTRIBUTING.md) if you want to deploy and test this project locally.

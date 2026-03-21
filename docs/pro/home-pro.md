# React on Rails Pro

Node rendering and caching performance enhancements for [React on Rails](https://github.com/shakacode/react_on_rails). Now supports React 18 with updates to React on Rails! Check the [React on Rails CHANGELOG.md](https://github.com/shakacode/react_on_rails/blob/main/CHANGELOG.md) for details and the updates to the [loadable-components instructions](../oss/building-features/code-splitting.md).

## Getting Started

The best way to see how React on Rails Pro works is to install this repo locally and take a look at
the example application:

[spec/dummy](https://github.com/shakacode/react_on_rails/blob/main/react_on_rails_pro/spec/dummy/README.md)

1. Uses a Shakapacker standard configuration.
1. Has pages that demonstrate:
   1. caching
   2. loadable-components
1. Has all the basic react_on_rails specs that run against the Node Renderer
1. Demonstrates using HMR and loadable-components with almost the same example that is present in [loadable-components for SSR](https://github.com/gregberge/loadable-components/tree/main/examples/server-side-rendering)

See the README.md in those sample apps for more details.

## Features

### Node Renderer

The Pro Node Renderer replaces ExecJS with a dedicated Node.js server for 10-100x faster SSR, proper Node.js tooling, and memory isolation from the Ruby process. See the [Node Renderer overview](./node-renderer.md).

### Streaming SSR

Stream HTML to the browser progressively using React 19's `renderToPipeableStream`, so users see content as it becomes ready instead of waiting for the slowest component. See the [Streaming SSR overview](./streaming-ssr.md).

### Fragment Caching

Cache the complete rendered output of a component — including props assembly, serialization, and JavaScript evaluation — so that on a cache hit, none of that work happens. See the [Fragment Caching overview](./fragment-caching.md).

### React Server Components

Full RSC support with Rails integration. Server Components run on the server and stream their output to the client, reducing bundle size and enabling server-only data access. See the [RSC tutorial](./react-server-components/tutorial.md).

### Prerender Caching

Cache JavaScript evaluation results with a single config line (`config.prerender_caching = true`). See the [Caching guide](../oss/building-features/caching.md#level-1-prerender-caching).

### Code Splitting

Route-based code splitting with Loadable Components and SSR support. See [Code Splitting](../oss/building-features/code-splitting.md).

### Bundle Caching

Skip redundant webpack builds across deployments. See the [Bundle Caching docs](../oss/building-features/bundle-caching.md).

### Clearing of Global State

Set `config.ssr_pre_hook_js` to run JavaScript that clears globally leaked state at the beginning of each server render call. See [Rails Configuration](../oss/configuration/README.md).

## Other Utility Methods

See the [Ruby API](../oss/api-reference/ruby-api-pro.md).

## References

- [Installation](./installation.md)
- [Upgrading from OSS to Pro](./upgrading-to-pro.md)
- [Node Renderer](./node-renderer.md)
- [Streaming SSR](./streaming-ssr.md)
- [Fragment Caching](./fragment-caching.md)
- [React Server Components](./react-server-components/tutorial.md)
- [Caching guide](../oss/building-features/caching.md)
- [Rails Configuration](../oss/configuration/configuration-pro.md)
- [Node Renderer technical docs](../oss/building-features/node-renderer/basics.md)

# Testimonials

"Do you want your app to randomly crash sometimes in hard to predict ways? Then ExecJS is perfect for you"
Anybody who regularly hits six-digit request numbers a day is going to be in for a bad time." Pete Keen, https://egghead.io

For details, see [Egghead React on Rails Pro Deployment Highlights](https://github.com/shakacode/react_on_rails/wiki/Egghead-React-on-Rails-Pro-Deployment-Highlights/).

# FAQ

## Why should I use React on Rails Pro if ExecJS seems to work?

Caching is extremely useful to any server rendering you're doing, with or without ExecJS.

React on Rails pro support caching at 2 levels:

1. Caching of rendering request to ExecJS (or the Node renderer). This avoids extra calls to ExecJS.
2. Fragment caching of server rendering. This avoids even the calculations of prop values from the database and the cost of converting the props to a string (lots of CPU there)

By doing such caching, you will take a CPU load off your Ruby server as well as improving response time. And this is with virtually no code changes on your part.

# Support React on Rails development

Support React on Rails development [by becoming a Github sponsor](https://github.com/sponsors/shakacode) and get these benefits:

1. 1-hour per month of support via Slack, PR reviews, and Zoom for React on Rails,
   React-Rails, Shakapacker, rails/webpacker, ReScript (ReasonML), TypeScript, Rust, etc.
2. React on Rails Pro Software that extends React on Rails with Node server rendering,
   fragment caching, code-splitting, and other performance enhancements for React on Rails.

For more info, email [justin@shakacode.com](mailto:justin@shakacode.com).


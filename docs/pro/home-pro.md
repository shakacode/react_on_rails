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

# Features

## Code Splitting

From [The Cost of JavaScript in 2018](https://medium.com/@addyosmani/the-cost-of-javascript-in-2018-7d8950fbb5d4):

> To stay fast, only load JavaScript needed for the current page. Prioritize what a user will need and lazy-load the rest with code-splitting. This gives you the best chance at loading and getting interactive fast. Stacks with route-based code-splitting by default are game-changers.

## Caching

### Server Rendering

Server rendering of JavaScript evaluation is cached if `prerender_caching` is turned on in your Rails config. This applies to all JavaScript evaluation methods, including ExecJS and the Node VM Renderer.

### Pro: Fragment Caching

Fragment caching is a [React on Rails Pro](https://pro.reactonrails.com/) feature. Fragment caching is a **HUGE** performance booster for your apps. Use the `cached_react_component` and `cached_react_component_hash`. The API is the same as `react_component` and `react_component_hash`, but for 2 differences:

1. The `cache_key` takes the same parameters as any Rails `cache` view helper.
1. The **props** are passed via a block so that evaluation of the props is not done unless the cache is broken. Suppose you put your props calculation into some method called `some_slow_method_that_returns_props`:

```ruby
<%= cached_react_component("App", cache_key: [@user, @post], prerender: true) do
  some_slow_method_that_returns_props
end %>
```

Such fragment caching saves CPU work for your web server and greatly reduces the request time. It completely skips the evaluation costs of:

1. Database calls to compute the props.
2. Serialization the props values hash into a JSON string for evaluating JavaScript to server render.
3. Costs associated with evaluating JavaScript from your Ruby code.
4. Creating the HTML string containing the props and the server-rendered JavaScript code.

Note, even without server rendering (without step 3 above), fragment caching is still effective.
See [Caching](../oss/building-features/caching.md) for more additional details.

## React On Rails Pro Node React Render

The "React on Rails Pro Node React Renderer" provides more efficient React Server Side Rendering on a standalone Node JS server.

### Overall Management Memory and CPU on both the Rendering and Ruby Servers

A separate Node rendering server is easier to manage in terms of monitoring memory and CPU performance, allocating dynos, etc. This also makes it easier to manage the ruby servers, as you no longer have to consider the impact of starting an embedded V8. Thus, you can never hang your Ruby servers due to JavaScript memory leaks.

### Proper Node Tooling

A disadvantage of Ruby embedded JavaScript (ExecJS) is that it precludes the use of standard Node tooling for doing things like profiling and tracking down memory leaks. With the renderer on a separate Node.js server, we were able to use node-memwatch (https://github.com/marcominetti/node-memwatch) to find few memory leaks in the Egghead React code.

### Caching of React Rendering

To limit the load on the renderer server or embedded ExecJS, caching of React rendering requests can be enabled by a config setting. Because current React rendering requests are idempotent (same value regardless of calls), caching should be feasible for all server rendering calls. The current renderer does not allow any asynchronous calls to fetch data. The rendering request includes all data for rendering.

### Rolling Restart of Node Workers

Due to poor performance and crashes due to memory leaks, the rolling restart of node workers was thus added as an option to the core rendering product. This option is cheap insurance against the renderer getting too slow from a memory leak due to a bug in some newly deployed JavaScript code.

### Docs

See the [Node React Render Docs](../oss/building-features/node-renderer/basics.md).

## Other Utility Methods

See the [Ruby API](../oss/api-reference/ruby-api-pro.md).

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

# References

- [Caching](../oss/building-features/caching.md)
- [Rails Configuration](../oss/configuration/configuration-pro.md)

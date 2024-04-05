*This wiki is used ONLY for React on Rails Pro, the paid, enhanced version of React on Rails.*

See [React on Rails Pro](https://www.shakacode.com/react-on-rails-pro) for the most recent updates.


# React on Rails Pro
## [Improve your server-response times up to 90% !](https://www.shakacode.com/react-on-rails-pro)
Performance enhancements and priority support for React on Rails.

[HVMN Testimonial, Written by Paul Benigeri, October 12, 2018](https://github.com/shakacode/react_on_rails/blob/master/docs/testimonials/hvmn.md)

> The price we paid for the consultation + the React on Rails pro license has already been made back a couple of times from hosting fees alone. The entire process was super hands-off, and our core team was able to focus on shipping new features during that sprint.


See [Egghead React on Rails Pro Deployment Highlights](https://github.com/shakacode/react_on_rails/wiki/Egghead-React-on-Rails-Pro-Deployment-Highlights/) for a case study of React on Rails Pro usage at [egghead.io](https://egghead.io).

# Features
## Code Splitting

From [The Cost of JavaScript in 2018](https://medium.com/@addyosmani/the-cost-of-javascript-in-2018-7d8950fbb5d4):

> To stay fast, only load JavaScript needed for the current page. Prioritize what a user will need and lazy-load the rest with code-splitting. This gives you the best chance at loading and getting interactive fast. Stacks with route-based code-splitting by default are game-changers.

We've got this already in production at https://egghead.io.

## Caching
### Server Rendering
Server rendering of JavaScript evaluation is cached if `prerender_caching` is turned on in your Rails config. This applies to all JavaScript evaluation methods, including ExecJS and the Node VM Renderer.

### Pro: Fragment Caching

Fragment caching is a [React on Rails Pro](https://www.shakacode.com/react-on-rails-pro/) feature. Fragment caching is a **HUGE** performance booster for your apps. Use the `cached_react_component` and `cached_react_component_hash`. The API is the same as `react_component` and `react_component_hash`, but for 2 differences:

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
See [Caching](https://www.shakacode.com/react-on-rails-pro/docs/caching/) for more additional details.

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
See the [Node React Render Docs](https://www.shakacode.com/react-on-rails-pro/docs/node-renderer/basics/).

## Other Utility Methods
See the [Ruby API](https://www.shakacode.com/react-on-rails-pro/docs/ruby-api/).

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

* [Caching](https://www.shakacode.com/react-on-rails-pro/docs/caching/)
* [Rails Configuration](https://www.shakacode.com/react-on-rails-pro/docs/configuration/)

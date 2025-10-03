## React on Rails Pro

Support React on Rails development [by becoming a Github sponsor](https://github.com/sponsors/shakacode) and get these benefits:

1. 1-hour per month of support via Slack, PR reviews, and Zoom for React on Rails,
   React-Rails, Shakapacker, rails/webpacker, ReScript (ReasonML), TypeScript, Rust, etc.
2. React on Rails Pro Software that extends React on Rails with Node server rendering,
   fragment caching, code-splitting, and other performance enhancements for React on Rails.

See the [React on Rails Pro Support Plan](https://www.shakacode.com/react-on-rails-pro/).

ShakaCode can also help you with your custom software development needs. We specialize in
marketplace and e-commerce applications that utilize both Rails and React.
Because we own [HiChee.com](https://hichee.com), we can leverage that code for your app!

Please email Justin Gordon [justin@shakacode.com](mailto:justin@shakacode.com), the
maintainer of React on Rails, for more information.

### Pro: Docs

See https://www.shakacode.com/react-on-rails-pro/docs/.

### Pro: React Server Components

See the [performance breakthroughs guide here](./major-performance-breakthroughs-upgrade-guide.md).

Yes! Big performance gains for the newest React features!

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

### Pro: Integration with Node.js for Server Rendering

Default server rendering is done by ExecJS. If you want to use a Node.js server for better performing server rendering, [email justin@shakacode.com](mailto:justin@shakacode.com). ShakaCode has built a premium Node rendering server that is part of [React on Rails Pro](https://www.shakacode.com/react-on-rails-pro).

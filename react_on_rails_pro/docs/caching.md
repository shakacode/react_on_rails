# Caching

Caching at the React on Rails level can greatly speed up your app and reduce the load on your servers, allowing more requests for a given level of hardware.

Consult the [Rails Guide on Caching](http://guides.rubyonrails.org/caching_with_rails.html#cache-stores) for details on:

- [Cache Stores and Configuration](http://guides.rubyonrails.org/caching_with_rails.html#cache-stores)
- [Determination of Cache Keys](http://guides.rubyonrails.org/caching_with_rails.html#cache-keys)
- [Caching in Development](http://guides.rubyonrails.org/caching_with_rails.html#caching-in-development): **To toggle caching in development**, run `rails dev:cache`.

See the [bottom note on confirming and debugging cache keys](#confirming-and-debugging-cache-keys).

## Overview

React on Rails Pro has caching at 2 levels:

1. "Fragment caching" view helpers, `cached_react_component` and `cached_react_component_hash`.
2. Caching of requests for server rendering.

### Tracing

If tracing is turned on in your config/initializers/react_on_rails_pro.rb, you'll see timing log messages that begin with `[ReactOnRailsPro:1234]: exec_server_render_js` where 1234 is the process id and `exec_server_render_js` could be a different method being traced.

- **exec_server_render_js**: Timing of server rendering, which may have the prerender_caching turned on.
- **cached_react_component** and **cached_react_component_hash**: Timing of the cached view helper which may be calling server rendering.

Here's a sample. Note the second request

```
Started GET "/server_side_redux_app_cached" for ::1 at 2018-05-24 22:40:13 -1000
[ReactOnRailsPro:63422] exec_server_render_js: ReduxApp, 230.7ms
[ReactOnRailsPro:63422] cached_react_component: ReduxApp, 2483.8ms
Completed 200 OK in 3613ms (Views: 3407.5ms | ActiveRecord: 0.0ms)


Started GET "/server_side_redux_app_cached" for ::1 at 2018-05-24 22:40:36 -1000
Processing by PagesController#server_side_redux_app_cached as HTML
  Rendering pages/server_side_redux_app_cached.html.erb within layouts/application
[ReactOnRailsPro:63422] cached_react_component: ReduxApp, 1.1ms
Completed 200 OK in 19ms (Views: 16.4ms | ActiveRecord: 0.0ms)
```

## Prerender (Server Side Rendering) Caching

### Why?

1. Server side rendering is typically done like a stateless functional component, meaning that the result should be idempotent from based on props passed in.
1. It's much easier than configuring fragment caching. So long as you have some space in your Rails cache, "it should just work."

### Why not?

If you're using regular caching for most components (cached_react_component_hash), and you don't want to use caching for other components, then having prerender caching still results in caching for all your rendering calls, increasing the likelihood of premature cache ejection.

In the future, React on Rails will allow stateful server rendering. Thus, your server side JavaScript depend on externalities, such as AJAX calls for
GraphQL. In that case, you will set this caching to false.

### When?

The largest percentage gains will come from saving the time of server rendering. However, even when not doing server rendering, caching can be effective as the caching will prevent the calculation of the props and the conversion to a string of the prop values.

### How?

To enable caching server rendering requests to the JavaScript calculation engine (ExecJS or Node Renderer), set this config
value in `config/initializers/react_on_rails_pro.rb` to true (default is false):

```ruby
  config.prerender_caching = true
```

Server rendering JavaScript evaluation requests are cached by a cache key that considers the following:

1. Hash of the server bundle.
2. The JavaScript code to evaluate.

### Diagnostics

if you're using `react_component_hash`, you'll get 2 extra keys returned:

1. RORP_CACHE_KEY: the prerender cache key
2. RORP_CACHE_HIT: whether or not there was a cache hit.

It can be useful to log these to the rendered HTML page to debug caching issues.

## React on Rails Fragment Caching

This is very similar to Rails fragment caching.

From the [Rails docs](http://guides.rubyonrails.org/caching_with_rails.html#fragment-caching):

> Fragment Caching allows a fragment of view logic to be wrapped in a cache block and served out of the cache store when the next request comes in.

It is similar in that the most important parts that you need to consider are:

1. Determining the optimal cache keys that minimize any cost such as database queries.
2. Clearing the Rails.cache on some deployments.

If you're already familiar with Rails fragment caching, the React on Rails implementation should feel familiar.

The reasons "why" and "why not" are the same as for basic Rails fragment caching:

### Why Use Fragment Caching?

1. Next to caching at the controller or HTTP level, this is the fastest type of caching.
2. The additional complexity to add this with React on Rails Pro is minimal.
3. The performance gains can be huge.
4. The load on your Rails server can be far lessened.

### Why Not Use Fragment Caching?

1. It's tricky to get all the right cache keys. You have to consider any values that can change and cause the rendering to change. See the [Rails docs for cache keys](http://guides.rubyonrails.org/caching_with_rails.html#cache-keys)
2. Testing is a bit tricky or just not done for fragment caching.
3. Some deployments require you to clear caches.

### Considerations for Determining Your Cache Key

1. Consult the [Rails docs for cache keys](http://guides.rubyonrails.org/caching_with_rails.html#cache-keys) for help with cache key definitions.
2. If your React code depends on any values from the [Rails Context](https://github.com/shakacode/react_on_rails/blob/master/docs/basics/generator-functions-and-railscontext.md#rails-context), such as the `locale` or the URL `location`, then be sure to include such values in your cache key. In other words, if you are using some JavaScript such as `react-router` that depends on your URL, or on a call to `toLocalString(locale)`, then be sure to include such values in your cache key. To find the values that React on Rails uses, use some code like this:

```ruby
the_rails_context = rails_context
i18nLocale = the_rails_context[:i18nLocale]
location = the_rails_context[:location]
```

If you are calling `rails_context` from your controller method, then prefix it like this: `helpers.rails_context` so long as you have react_on_rails > 11.2.2. If less than that, call `helpers.send(:rails_context, server_side: true)`

If performance is particulary sensitive, consult the view helper definition for `rails_context`. For example, you can save the cost of calculating the rails_context by directly getting a value:

```ruby
i18nLocale = I18n.locale
```

### How: API

Here is the doc for helpers `cached_react_component` and `cached_react_component_hash`. Consult the [docs in React on Rails](https://www.shakacode.com/react-on-rails/docs/api/view-helpers-api/) for the non-cached analogies `react_component` and `react_component_hash`. These docs only show the differences.

```ruby
  # Provide caching support for react_component in a manner akin to Rails fragment caching.
  # All the same options as react_component apply with the following difference:
  #
  # 1. You must pass the props as a block. This is so that the evaluation of the props is not done
  #    if the cache can be used.
  # 2. Provide the cache_key option
  #    cache_key: String or Array (or Proc returning a String or Array) containing your cache keys.
  #    If prerender is set to true, the server bundle digest will be included in the cache key.
  #    The cache_key value is the same as used for conventional Rails fragment caching.
  # 3. Optionally provide the `:cache_options` key with a value of a hash including as
  #    :compress, :expires_in, :race_condition_ttl as documented in the Rails Guides
  # 4. Provide boolean values for `:if` or `:unless` to conditionally use caching.
```

You can find the `:cache_options` documented in the [Rails docs for ActiveSupport cache store](https://guides.rubyonrails.org/caching_with_rails.html#activesupport-cache-store).

#### API Usage examples

The fragment caching for `react_component`:

```ruby
<%= cached_react_component("App", cache_key: [@user, @post], prerender: true) do
  some_slow_method_that_returns_props
end %>
```

Suppose you only want to cache when `current_user.nil?`. Use the `:if` option (`unless:` is analogous):

```ruby
<%= cached_react_component("App", cache_key: [@user, @post], prerender: true, if: current_user.nil?) do
  some_slow_method_that_returns_props
end %>
```

And a fragment caching version for the `react_component_hash`:

```ruby
<% result = cached_react_component_hash("ReactHelmetApp", cache_key: [@user, @post],
                                           id: "react-helmet-0") do
    some_slow_method_that_returns_props
   end %>

<% content_for :title do %>
  <%= react_helmet_app['title'] %>
<% end %>

<%= react_helmet_app["componentHtml"] %>

<% printable_cache_key = ReactOnRailsPro::Utils.printable_cache_key(result[:RORP_CACHE_KEY]) %>
<!-- <%= "CACHE_HIT: #{result[:RORP_CACHE_HIT]}, RORP_CACHE_KEY: #{printable_cache_key}" %> -->
```

Note in the above example, React on Rails Pro returns both the raw cache key and whether or not there was a cache hit.

### Your JavaScript Bundles and Cache Keys

When doing fragment caching of server rendering with React on Rails Pro, the cache key must reflect
your React. This is analogous to how Rails puts an MD5 hash of your views in
the cache key so that if the views change, then your cache is busted. In the case
of React code, if your React code changes, then your bundle name will
change if you are doing the inclusion of a hash in the name. However, if you are
using a separate webpack configuration to generate the server bundle file,
then you **must not** include the hash in the output filename or else you will
have a race condition overwriting your `manifest.json`. Regardless of which
case you have, React on Rails handles it.

# Confirming and Debugging Cache Keys

Cache key composition can be confirmed in development mode with the following steps. The goal is to confirm that some change that should trigger new cached data actually triggers a new cache key. For example, when the server bundle changes, does that trigger a new cache key for any server rendering?

1. Run `Rails.cache.clear` to clear the cache.
1. Run `rails dev:cache` to toggle caching in development mode.

You will see a message like:

> Development mode is now being cached.

You might need to check your `config/development.rb`contains the following:

```ruby
  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=172800"
    }

    # For Rails >= 5.1 determines whether to log fragment cache reads and writes in verbose format as follows:
    config.action_controller.enable_fragment_cache_logging
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end
```

3. Start your server in development mode. You should see cache entries in the console log. Fetch the page that uses the cache. Make a note of the cache key used for the cached component.

4. Suppose you want to confirm that updated JavaScript causes a cache key change. Make any change to the JavaScript that's server rendered or change the version of any package in the bundle.

5. Check the cache entry again. You should have noticed that it changed.

To avoid seeing the cache calls to the prerender_caching, you can temporarily set:

```
config.prerender_caching = false
```

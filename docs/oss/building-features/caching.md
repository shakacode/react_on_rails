# SSR Caching: Prerender Caching and Fragment Caching

> **Pro Feature** — Available with [React on Rails Pro](https://pro.reactrails.com).
> Free for evaluation and startups. [Get a license →](mailto:justin@shakacode.com)

Server-side rendering (SSR) is expensive. Every render evaluates JavaScript, assembles props from the database, serializes them to JSON, and produces HTML. React on Rails Pro provides two levels of caching that avoid repeating this work on every request. Both solve the same core problem — **eliminating redundant SSR** — but they operate at different layers and offer different tradeoffs.

|                            | Prerender Caching                                                                                            | Fragment Caching                                                                                      |
| -------------------------- | ------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| **What it caches**         | The JavaScript evaluation result (the SSR output for a given set of props)                                   | The entire rendered fragment including props assembly, serialization, and SSR                         |
| **Setup effort**           | One config line — `config.prerender_caching = true`                                                          | Requires choosing cache keys and passing props as a block                                             |
| **Cache key**              | Automatic: hash of server bundle + JavaScript code to evaluate                                               | You define it: any combination of ActiveRecord models, timestamps, locale, URL, etc.                  |
| **Skips prop evaluation?** | No — props are still computed, serialized, and sent to the JS engine; only the JS execution result is cached | Yes — when the cache hits, the props block is never called, saving database queries and serialization |
| **Best for**               | Quick win, especially when you want to avoid JS evaluation overhead without changing view code               | Maximum performance, especially for pages with expensive prop assembly (database queries, API calls)  |
| **Start here?**            | Yes — turn it on first and measure the impact                                                                | Add it next for your highest-traffic or most expensive components                                     |

**Recommendation**: Start with prerender caching (one line of config). Once you see the benefit, add fragment caching to your most expensive components for the biggest additional gains. Fragment caching subsumes prerender caching — when a fragment cache hits, prerender caching is never consulted because the entire rendered output is already stored.

Consult the [Rails Guide on Caching](http://guides.rubyonrails.org/caching_with_rails.html#cache-stores) for details on:

- [Cache Stores and Configuration](http://guides.rubyonrails.org/caching_with_rails.html#cache-stores)
- [Determination of Cache Keys](http://guides.rubyonrails.org/caching_with_rails.html#cache-keys)
- [Caching in Development](http://guides.rubyonrails.org/caching_with_rails.html#caching-in-development): **To toggle caching in development**, run `rails dev:cache`.

## Tracing

If tracing is turned on in your config/initializers/react_on_rails_pro.rb, you'll see timing log messages that begin with `[ReactOnRailsPro:1234]: exec_server_render_js` where 1234 is the process id and `exec_server_render_js` could be a different method being traced.

- **exec_server_render_js**: Timing of server rendering, which may have the prerender_caching turned on.
- **cached_react_component** and **cached_react_component_hash**: Timing of the cached view helper which may be calling server rendering.

Here's a sample. Note the second request:

```text
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

---

## Level 1: Prerender Caching

Prerender caching is the simplest way to speed up SSR. It caches the result of JavaScript evaluation so that identical rendering calls return instantly from the Rails cache instead of re-executing JavaScript.

### How it works

When a `react_component` call triggers SSR, React on Rails Pro computes a cache key from:

1. A hash of the server bundle
2. The JavaScript code to evaluate (which includes the serialized props)

If the cache contains an entry for that key, the cached HTML is returned without calling JavaScript. If not, the JS is evaluated, the result is cached, and then returned.

### Setup

One line in `config/initializers/react_on_rails_pro.rb`:

```ruby
config.prerender_caching = true
```

That's it. No view code changes required.

### When to use it

- As a quick first step — turn it on and measure the impact before investing in fragment caching
- When your components are stateless (same props always produce the same output)
- When you want to reduce load on the JavaScript evaluation engine (ExecJS or Node Renderer)

### When NOT to use it

- If you're already using fragment caching for most components, prerender caching adds cache entries without additional benefit for those components (increasing the likelihood of premature cache ejection)
- If your server-side JavaScript depends on external state (AJAX calls, GraphQL) that makes rendering non-idempotent

### Diagnostics

If you're using `react_component_hash`, you'll get 2 extra keys returned:

1. RORP_CACHE_KEY: the prerender cache key
2. RORP_CACHE_HIT: whether or not there was a cache hit.

It can be useful to log these to the rendered HTML page to debug caching issues.

---

## Level 2: Fragment Caching

Fragment caching is the advanced option that delivers the biggest performance gains. It caches the entire rendered output — including the cost of assembling props from the database — so that on a cache hit, no database queries, no JSON serialization, and no JavaScript evaluation occur.

This is very similar to [Rails fragment caching](http://guides.rubyonrails.org/caching_with_rails.html#fragment-caching):

> Fragment Caching allows a fragment of view logic to be wrapped in a cache block and served out of the cache store when the next request comes in.

If you're already familiar with Rails fragment caching, the React on Rails implementation should feel familiar. The most important parts to consider are:

1. Determining the optimal cache keys that minimize any cost such as database queries.
2. Clearing the Rails.cache on some deployments.

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
2. If your React code depends on any values from the [Rails Context](../core-concepts/render-functions-and-railscontext.md#rails-context), such as the `locale` or the URL `location`, then be sure to include such values in your cache key. In other words, if you are using some JavaScript such as `react-router` that depends on your URL, or on a call to `toLocaleString(locale)`, then be sure to include such values in your cache key. To find the values that React on Rails uses, use some code like this:

```ruby
the_rails_context = rails_context
i18nLocale = the_rails_context[:i18nLocale]
location = the_rails_context[:location]
```

If you are calling `rails_context` from your controller method, then prefix it like this: `helpers.rails_context` so long as you have react_on_rails > 11.2.2. If less than that, call `helpers.send(:rails_context, server_side: true)`

If performance is particularly sensitive, consult the view helper definition for `rails_context`. For example, you can save the cost of calculating the rails_context by directly getting a value:

```ruby
i18nLocale = I18n.locale
```

### How: API

Here is the doc for helpers `cached_react_component` and `cached_react_component_hash`. Consult the [view helpers API docs](../api-reference/view-helpers-api.md) for the non-cached analogies `react_component` and `react_component_hash`. These docs only show the differences.

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
  <%= result['title'] %>
<% end %>

<%= result["componentHtml"] %>

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

---

## Cache Warming

Fragment cache keys include the server bundle digest, which means every deploy creates new cache keys. This is correct — rendered output must match the current bundle — but it means every deploy starts with a cold cache. Under live traffic, this creates a synchronized storm of cache misses: every user request triggers full SSR, database queries for props assembly, and JS evaluation simultaneously.

The solution is **cache warming**: rendering your highest-traffic pages in the background immediately after deploy, before real users hit those pages.

### The pattern

1. Deploy new code
2. Identify the pages that matter most (by recent traffic)
3. Render those pages in background jobs through the normal view path
4. The existing `cached_react_component` helpers fill the cache naturally
5. Live traffic hits warm caches instead of triggering cold rebuilds

```ruby
# app/jobs/warm_page_job.rb
class WarmPageJob
  include Sidekiq::Job

  sidekiq_options queue: "cache_warming", retry: 3

  def perform(page_id, release_version)
    return unless ReleaseRegistry.current_version == release_version

    page = Page.includes(:restaurant, :menu).find(page_id)

    ApplicationController.renderer.render(
      template: "restaurants/show",
      assigns: { restaurant: page.restaurant, menu: page.menu }
    )
  end
end
```

The job does not write full-page HTML into a custom cache key. It simply runs the normal render path so the fragment caches embedded in the page are populated before real users arrive.

### Why warming matters

The real bottleneck during cold-cache rebuilds is often **database contention**, not app-server CPU. Many pages go cold simultaneously, each render triggers database queries, and concurrency spikes overwhelm the primary database. Extra app servers don't fix a saturated database.

Key techniques for production cache warming:

- **Prioritize by traffic**: Warm the top 5,000 most-visited pages first. A page with 10,000 daily visits matters more than one with 100.
- **Use read replicas**: Route warming queries to a replica to protect the primary database.
- **Rate limit**: Cap warming concurrency to what the database can handle. Sidekiq rate limiters prevent overwhelming the rendering system.
- **Stampede prevention**: Use Redis `SET NX` locks to ensure only one worker renders a given page at a time.
- **Jittered expiration**: Use `expires_in: 24.hours + rand(0..3600)` instead of fixed TTLs to prevent synchronized mass expiration.

### Real-world impact

At Popmenu (a ShakaCode client running React on Rails Pro), cache warming across 37 Sidekiq dynos processing 2,000–8,000 pages per minute produced:

- Average TTFB dropped from 320ms to 65ms (-80%)
- Server CPU during peak hours dropped 45%
- Database connections dropped 35% (fewer concurrent renders)

For more details on the full cache warming architecture including stampede prevention, event-driven warming, and monitoring, contact [ShakaCode](https://www.shakacode.com/react-on-rails-pro/) for consulting on production cache warming strategies.

---

## Confirming and Debugging Cache Keys

Cache key composition can be confirmed in development mode with the following steps. The goal is to confirm that some change that should trigger new cached data actually triggers a new cache key. For example, when the server bundle changes, does that trigger a new cache key for any server rendering?

1. Run `Rails.cache.clear` to clear the cache.
1. Run `rails dev:cache` to toggle caching in development mode.

You will see a message like:

> Development mode is now being cached.

You might need to check your `config/development.rb` contains the following:

```ruby
  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=172800"
    }

    # For Rails >= 5.1 determines whether to log fragment cache reads and writes in verbose format as follows:
    config.action_controller.enable_fragment_cache_logging = true
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end
```

3. Start your server in development mode. You should see cache entries in the console log. Fetch the page that uses the cache. Make a note of the cache key used for the cached component.

4. Suppose you want to confirm that updated JavaScript causes a cache key change. Make any change to the JavaScript that's server rendered or change the version of any package in the bundle.

5. Check the cache entry again. You should have noticed that it changed.

To avoid seeing the cache calls to the prerender_caching, you can temporarily set:

```ruby
config.prerender_caching = false
```

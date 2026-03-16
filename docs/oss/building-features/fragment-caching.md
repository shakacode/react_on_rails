# Fragment Caching and Bundle Caching

> **Pro Feature** — Available with [React on Rails Pro](../../pro/upgrading-to-pro.md).
> Free for evaluation and startups. [Get a license →](mailto:justin@shakacode.com)

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

1. Server-side rendering is typically done like a stateless functional component, meaning that the result should be idempotent based on props passed in.
1. It's much easier than configuring fragment caching. So long as you have some space in your Rails cache, "it should just work."

### Why not?

If you're using regular caching for most components (cached_react_component_hash), and you don't want to use caching for other components, then having prerender caching still results in caching for all your rendering calls, increasing the likelihood of premature cache ejection.

In the future, React on Rails will allow stateful server rendering. Thus, your server-side JavaScript depend on externalities, such as AJAX calls for
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

## Confirming and Debugging Cache Keys

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

## Bundle Caching

Bundle caching avoids redundant webpack builds by caching bundles based on a digest of source files.

### Why?

Building webpack bundles is often time-consuming, and the same bundles are built many times.
For example, you might build the production bundles during CI, then for a Review app, then
for Staging, and maybe even for Production. Or you might want to deploy a small Ruby-only
change to production, but you will have to wait minutes for your bundles to be built again.

### Solution

React on Rails 2.1.0 introduces bundle caching based on a digest of all the source files, defined
in the `config/shakapacker.yml` file, plus other files defined with `config.dependency_globs` and
excluding any files from `config.excluded_dependency_globs`. Creating this hash key takes at most a
few seconds for even large projects. Additionally, the cache key includes

1. NODE_ENV
2. Version of React on Rails Pro
3. Configurable additional env values by supplying an array in method cache_keys on the `remote_bundle_cache_adapter`. See examples below.

This cache key is used for saving files to some remote storage, typically S3.

### Bonus for local development with multiple directories building production builds

Bundle caching can help save time if you have multiple directories for the same repository.

The bundles are cached in `Rails.root.join('tmp', 'bundle_cache')`

So, if you have sibling directories for the same project, you can make a sym link so both directories use the same bundle cache directory.

```
cd my_project2/tmp
ln -s ../../my_project/tmp/bundle_cache
```

### Configuration

#### 1. React on Rails Configuration

First, we need to tell React on Rails to use a custom build module. In
`config/initializers/react_on_rails`, set this value:

```ruby
config.build_production_command = ReactOnRailsPro::AssetsPrecompile
```

Alternatively, if you need to run something after the files are built or extracted from the cache, you can do something like this:

```ruby
ReactOnRails.configure do |config|
  # This configures the script to run to build the production assets by webpack. Set this to nil
  # if you don't want react_on_rails building this file for you.
  config.build_production_command = CustomBuildCommand
end
```

And define it like this:

```ruby
module CustomBuildCommand
  def self.call
    ReactOnRailsPro::AssetsPrecompile.call
    Rake::Task['react_on_rails_pro:pre_stage_bundle_for_node_renderer'].invoke
  end
end
```

#### 2. React on Rails Pro Configuration

Next, we need to configure the `config/initializers/react_on_rails_pro.rb` with some module,
say called S3BundleCacheAdapter.

```
config.remote_bundle_cache_adapter = S3BundleCacheAdapter
```

This module needs four class methods: `cache_keys` (optional), `build`, `fetch`, `upload`. See two
examples of this below.

Also, add whatever file the remote_bundle_cache_adapter module is defined in to `config.dependency_globs`.

If there are any other files for which changes should bust the fragment cache for
cached_react_component and cached_react_component_hash, add those as well to `config.dependency_globs`. This should include any files used to generate the JSON props, webpack and/or Shakapacker configuration files, and package lockfiles.

To simplify your configuration, entire directories can be added to `config.dependency_globs` & then any irrelevant files or subdirectories can be added to `config.excluded_dependency_globs`

For example:

```ruby
  config.dependency_globs = [ File.join(Rails.root, "app", "views", "**", "*.jbuilder") ]
  config.excluded_dependency_globs = [ File.join(Rails.root, "app", "views", "**", "dont_hash_this.jbuilder") ]
```

will hash all files in `app/views` that have the `jbuilder` extension except for any file named `dont_hash_this.jbuilder`.

The goal is that Ruby only changes that don't affect your webpack bundles don't change the cache keys, and anything that could affect the bundles MUST change the cache keys!

#### 3. Remove any call to rake task `react_on_rails_pro:pre_stage_bundle_for_node_renderer`

This task is called automatically if you're using bundle caching.

```ruby
  Rake::Task['react_on_rails_pro:pre_stage_bundle_for_node_renderer'].invoke
```

##### Custom ENV cache keys

Check your webpack config for the webpack.DefinePlugin. That allows JS code to use
`process.env.MY_ENV_VAR` resulting in bundles that differ depending on the ENV value set.

Thus, if you access these `process.env.MY_ENV_VAR` in your JS code, then you need to include such
ENV vars in return value of the `cache keys` method.

A much better approach than accessing `process.env` is to use the
`config/initializers/react_on_rails.rb` setting for the`config.rendering_extension` to always
pass some values into the rendering props.

See [our railsContext docs](../core-concepts/render-functions-and-railscontext.md) for more details.

Also, if your webpack build process depends on any ENV values, then you will also need to add those
to return value of the `cache_keys` method.

Note, the NODE_ENV value is always included in the cache_keys.

Another use of the ENV values would be a cache version, so incrementing this ENV value
would force a new cache value.

### Disabling via an ENV value

Once configured for bundle caching, ReactOnRailsPro::AssetsPrecompile's caching functionality
can be disabled by setting ENV["DISABLE_PRECOMPILE_CACHE"] equal to "true"

### Examples of `remote_bundle_cache_adapter`:

#### S3BundleCacheAdapter

Example of a module for custom methods for the `remote_bundle_cache_adapter`.

Note, S3UploadService is your own code that fetches and uploads.

```ruby
class S3BundleCacheAdapter
  # Optional
  # return an Array of Strings that should get added to the cache key.
  # These are values to put in the cache key based on either using the webpack.DefinePlugin
  # or webpack compilation varying by the ENV values.
  # See the use of the webpack.DefinePlugin. That allows JS code to use
  # process.env.MY_ENV_VAR resulting in bundles that differ depending on the ENV value set
  # when building the bundles.
  # Note, NODE_ENV is automatically included in the default cache key.
  # Also, we can have an ENV value be a cache version, so incrementing this ENV value
  # would force a new cache value.
  def self.cache_keys
    [Rails.env, ENV['SOME_ENV_VALUE']]
  end

  # return value is unused
  # This command should build the bundles
  def self.build
    Rake.sh(ReactOnRails::Utils.prepend_cd_node_modules_directory('yarn start build.prod').to_s)
  end

  # parameter zipped_bundles_filename will be a string
  # should return the zipped file as a string if successful & nil if not
  def self.fetch(zipped_bundles_filename:)
    result = S3UploadService.new.fetch_object(zipped_bundles_filename)
    result.get.body.read if result
  end

  # Optional: method to return an array of extra files paths, that require caching.
  # These files get placed at the `extra_files` directory at the top of the zipfile
  # and are moved to the original places after unzipping the bundles.
  def self.extra_files_to_cache
      [ Rails.root.join("app", "javascript", "utils", "operationStore.json") ]
  end

  # parameter zipped_bundles_filepath will be a Pathname
  # return value is unused
  def self.upload(zipped_bundles_filepath:)
    return unless ENV['UPLOAD_BUNDLES_TO_S3'] == 'true'

    zipped_bundles_filename = zipped_bundles_filepath.basename.to_s
    puts "Bundles are being uploaded to s3 as #{zipped_bundles_filename}"
    starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    S3UploadService.new.upload_object(zipped_bundles_filename,
                                      File.read(zipped_bundles_filepath, mode: 'rb'),
                                      'application/zip', expiration_months: 12)
    ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    elapsed = (ending - starting).round(2)
    puts "Bundles uploaded to s3 as #{zipped_bundles_filename} in #{elapsed} seconds"
  end
end
```

#### LocalBundleCacheAdapter

Example of a module for custom methods for the `remote_bundle_cache_adapter` that does not save files
remotely. Only local files are used.

```ruby
class LocalBundleCacheAdapter
  def self.cache_keys
    # if no additional cache keys, return an empty array
    []
  end

  def self.build
    Rake.sh(ReactOnRails::Utils.prepend_cd_node_modules_directory('yarn start build.prod').to_s)
  end

  def self.fetch(zipped_bundles_filename:)
    # no-op
  end

  def self.upload(zipped_bundles_filepath:)
    # no-op
  end
end
```

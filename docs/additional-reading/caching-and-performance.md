# Caching and Performance


## Caching

### Fragment Caching

Fragment caching is awesome with React on Rails!

When doing fragment caching with React on Rails, the cache key must reflect
your React code. This is analogous to how Rails puts an MD5 hash of your views in
the cache key so that if the views change, then your cache is busted. In the case
of React code, if your React code changes, then your bundle name will
change if you are doing the inclusion of a hash in the name. However, if you are
using a separate webpack configuration to generate the server bundle file,
then you **must not** include the hash in the output filename or else you will
have a race condition overwriting your `manifiest.json`. Regardless of which
case you have React on Rails handles it.

Even if you are not using server rendering, you need to configure:

1. ReactOnRails.configuration.server_bundle_js_file
2. A bundle for this config value with all your JS code

#### Using the cache_key parameter in react_component or react_component_hash

```ruby

react_component("App", cache_key: [@user, @post], prerender: true) do
  some_slow_method_that_returns_props
end
```

#### If you wish to do this manually

```ruby
# Returns the hashed file name of the server bundle when using webpacker.
# Necessary fragment-caching keys.
<% cache_key = [ReactOnRails::Utils.bundle_hash, @some_active_record] %>
<% cache cache_key do %>
  <%= react_component("App", props: props)
<% end %>
```

### HTTP Caching with Webpacker

When creating a HTTP cache, you want the cache key to include the client bundle file
name which includes the hash from webpacker.

The hash is configured in your webpack config file or done automatically by your
webpacker configuration.

```javascript
  output: {
    filename: isHMR ? '[name]-[hash].js' : '[name]-[chunkhash].js',
```

See [webpack.client.rails.build.config.js](../spec/dummy/client/webpack.client.rails.build.config.js)
for a full example of setting the hash in the output filename.

Call this method to get the client bundle file name. Note, you have to pass which bundle name.

```ruby
# Returns the hashed file name when using webpacker. Useful for creating cache keys.
ReactOnRails::Utils.bundle_file_name(bundle_name)
```

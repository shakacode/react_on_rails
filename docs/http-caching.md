# HTTP Caching (with Webpacker)

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
ReactOnRailsPro::Utils.bundle_file_name(bundle_name)

```

TODO: Provide a more complete example of this type of caching.

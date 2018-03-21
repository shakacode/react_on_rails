# Caching and Performance


## Caching

If you want to cache your component, pass the `cached` option:

```ruby
react_component("App", cached: true)
```

### HTTP Caching

When creating a HTTP cache, you want the cache key to include your client bundle files.

Call this method to get the client bundle file name. Note, you have to pass which bundle name.

```ruby
# Returns the hashed file name when using webpacker. Useful for creating cache keys.
ReactOnRails::Utils.bundle_file_name(bundle_name)
```

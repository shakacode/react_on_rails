# Caching and Performance


## Caching

If you want to cache your component, pass the `cache_key` option containing your cache keys.
Also you should pass `props` as a block so you avoid generating them on each call:

```ruby
react_component("App", cache_key: "cache_key") do
  { prop1: "a", prop2: "b" }
end
```

If passing `prerender: true`, your server bundle digest will be include in the cache key
too. This will be done automatically for you:

```ruby
react_component("App", cache_key: "cache_key", prerender: true) do
  { prop1: "a", prop2: "b" }
end
```

### HTTP Caching

When creating a HTTP cache, you want the cache key to include your client bundle files.

Call this method to get the client bundle file name. Note, you have to pass which bundle name.

```ruby
# Returns the hashed file name when using webpacker. Useful for creating cache keys.
ReactOnRails::Utils.bundle_file_name(bundle_name)
```

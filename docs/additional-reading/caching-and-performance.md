# Caching and Performance


## Caching

### Fragment Caching

If you wish to do fragment caching that includes React on Rails rendered components, be sure to
include the bundle name of your server rendering bundle in your cache key. This is analogous to 
how Rails puts an MD5 hash of your views in the cache key so that if the views change, then your 
cache is busted. In the case of React code, if your React code changes, then your bundle name will
change due to the typical inclusion of a hash in the name.

Call this method to get the server bundle file name:

```ruby
# Returns the hashed file name of the server bundle when using webpacker.
# Nececessary fragment-caching keys.
ReactOnRails::Utils.server_bundle_file_name
```

### HTTP Caching

When creating a HTTP cache, you want the cache key to include your client bundle files.

Call this method to get the client bundle file name. Note, you have to pass which bundle name.

```ruby
# Returns the hashed file name when using webpacker. Useful for creating cache keys.
ReactOnRails::Utils..bundle_file_name(bundle_name)
```

# Caching

## Overview
React on Rails Pro has caching at 2 levels:

1. "Fragement caching" view helpers, `cached_react_component` and `cached_react_component_hash`.  
2. Caching of requests for server rendering. 

### Testing During Development
**To toggle caching in development**, as explained in [this article](http://guides.rubyonrails.org/caching_with_rails.html#caching-in-development)
`rails dev:cache`

## Prerender Caching

To enable caching server rendering requests to the JavaScript calculation engine, set this config
value in `config/initializers/react_on_rails_pro.rb` to true:

```rub
  config.prerender_caching = true
```

Server rendering JavaScript evaluation requests are cached by a cache key that considers the following:

1. Hash of the server bundle.
2. The JavaScript code to evaluate.

Note, if your server side JavaScript will be ever depend on externalities, such as AJAX calls for
GraphQL, then you should set this caching to false.

## Fragment Caching

### Your JavaScript Bundles and Cache Keys 
When doing fragment caching of server rendering with React on Rails Pro, the cache key must reflect
your React. This is analogous to how Rails puts an MD5 hash of your views in
the cache key so that if the views change, then your cache is busted. In the case
of React code, if your React code changes, then your bundle name will
change if you are doing the inclusion of a hash in the name. However, if you are
using a separate webpack configuration to generate the server bundle file,
then you **must not** include the hash in the output filename or else you will
have a race condition overwriting your `manifest.json`. Regardless of which
case you have React on Rails handles it.

Even when not doing server rendering, caching can be effective as the caching will prevent the
calculation of the props and the conversion to a string.

Here is the doc for helper cached_react_component.

```ruby
  # Provide caching support for react_component in a manner akin to Rails fragment caching.
  # All the same options as react_component apply with the following difference:
  #
  # 1. You must pass the props as a block. This is so that the evaluation of the props is not done
  #    if the cache can be used.
  # 2. Provide the cache_key option
  #
  # cache_key: String or Array containing your cache keys. If prerender is set to true, the server
  #   bundle digest will be included in the cache key. The cache_key value is the same as used for
  #   conventional Rails fragment caching.

```

Usage example:


```ruby
cached_react_component("App", cache_key: [@user, @post], prerender: true) do
  some_slow_method_that_returns_props
end
```

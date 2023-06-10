# frozen_string_literal: true

# NOTE: For any heredoc JS:
# 1. The white spacing in this file matters!
# 2. Keep all #{some_var} fully to the left so that all indentation is done evenly in that var

require "react_on_rails/helper"

module ReactOnRailsProHelper
  def fetch_react_component(component_name, options)
    if ReactOnRailsPro::Cache.use_cache?(options)
      cache_key = ReactOnRailsPro::Cache.react_component_cache_key(component_name, options)
      Rails.logger.debug { "React on Rails Pro cache_key is #{cache_key.inspect}" }
      cache_options = options[:cache_options]
      cache_hit = true
      result = Rails.cache.fetch(cache_key, cache_options) do
        cache_hit = false
        yield
      end
      load_pack_for_generated_component(component_name) if ReactOnRails.configuration.auto_load_bundle && cache_hit
      # Pass back the cache key in the results only if the result is a Hash
      if result.is_a?(Hash)
        result[:RORP_CACHE_KEY] = cache_key
        result[:RORP_CACHE_HIT] = cache_hit
      end
      result
    else
      yield
    end
  end

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
  def cached_react_component(component_name, raw_options = {}, &block)
    ReactOnRailsPro::Utils.with_trace(component_name) do
      check_caching_options!(raw_options, block)

      fetch_react_component(component_name, raw_options) do
        sanitized_options = raw_options
        sanitized_options[:props] = yield
        sanitized_options[:skip_prerender_cache] = true
        sanitized_options[:auto_load_bundle] =
          ReactOnRails.configuration.auto_load_bundle || raw_options[:auto_load_bundle]
        react_component(component_name, sanitized_options)
      end
    end
  end

  # Provide caching support for react_component_hash in a manner akin to Rails fragment caching.
  # All the same options as react_component_hash apply with the following difference:
  #
  # 1. You must pass the props as a block. This is so that the evaluation of the props is not done
  #    if the cache can be used.
  # 2. Provide the cache_key option
  #    cache_key: String or Array (or Proc returning a String or Array) containing your cache keys.
  #    Since prerender is automatically set to true, the server bundle digest will be included in the cache key.
  #    The cache_key value is the same as used for conventional Rails fragment caching.
  # 3. Optionally provide the `:cache_options` key with a value of a hash including as
  #    :compress, :expires_in, :race_condition_ttl as documented in the Rails Guides
  # 4. Provide boolean values for `:if` or `:unless` to conditionally use caching.
  def cached_react_component_hash(component_name, raw_options = {}, &block)
    raw_options[:prerender] = true

    ReactOnRailsPro::Utils.with_trace(component_name) do
      check_caching_options!(raw_options, block)

      fetch_react_component(component_name, raw_options) do
        sanitized_options = raw_options
        sanitized_options[:props] = yield
        sanitized_options[:skip_prerender_cache] = true
        sanitized_options[:auto_load_bundle] =
          ReactOnRails.configuration.auto_load_bundle || raw_options[:auto_load_bundle]
        react_component_hash(component_name, sanitized_options)
      end
    end
  end

  if defined?(ScoutApm)
    include ScoutApm::Tracer
    instrument_method :cached_react_component, type: "ReactOnRails", name: "cached_react_component"
    instrument_method :cached_react_component_hash, type: "ReactOnRails", name: "cached_react_component_hash"
  end

  private

  def check_caching_options!(raw_options, block)
    raise ReactOnRailsPro::Error, "Pass 'props' as a block if using caching" if raw_options.key?(:props) || block.nil?

    return if raw_options.key?(:cache_key)

    raise ReactOnRailsPro::Error, "Option 'cache_key' is required for React on Rails caching"
  end
end

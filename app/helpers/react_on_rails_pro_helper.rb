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
      if cache_hit
        render_options = ReactOnRails::ReactComponent::RenderOptions.new(
          react_component_name: component_name,
          options: options
        )
        load_pack_for_generated_component(component_name, render_options)
      end
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

  # Provide caching support for stream_react_component in a manner akin to Rails fragment caching.
  # All the same options as stream_react_component apply with the following differences:
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
  def cached_stream_react_component(component_name, raw_options = {}, &block)
    ReactOnRailsPro::Utils.with_trace(component_name) do
      check_caching_options!(raw_options, block)
      fetch_stream_react_component(component_name, raw_options, &block)
    end
  end

  if defined?(ScoutApm)
    include ScoutApm::Tracer
    instrument_method :cached_react_component, type: "ReactOnRails", name: "cached_react_component"
    instrument_method :cached_react_component_hash, type: "ReactOnRails", name: "cached_react_component_hash"
    instrument_method :cached_stream_react_component, type: "ReactOnRails", name: "cached_stream_react_component"
  end

  private

  def fetch_stream_react_component(component_name, raw_options, &block)
    auto_load_bundle = ReactOnRails.configuration.auto_load_bundle || raw_options[:auto_load_bundle]

    unless ReactOnRailsPro::Cache.use_cache?(raw_options)
      return render_stream_component_with_props(component_name, raw_options, auto_load_bundle, &block)
    end

    # Compose a cache key consistent with non-stream helper semantics.
    key_options = raw_options.merge(prerender: true)
    view_cache_key = ReactOnRailsPro::Cache.react_component_cache_key(component_name, key_options)

    # Attempt HIT without evaluating props block
    if (cached_chunks = Rails.cache.read(view_cache_key)).is_a?(Array)
      return handle_stream_cache_hit(component_name, raw_options, auto_load_bundle, cached_chunks)
    end

    # MISS: evaluate props lazily, stream live, and write-through to view-level cache
    handle_stream_cache_miss(component_name, raw_options, auto_load_bundle, view_cache_key, &block)
  end

  def handle_stream_cache_hit(component_name, raw_options, auto_load_bundle, cached_chunks)
    render_options = ReactOnRails::ReactComponent::RenderOptions.new(
      react_component_name: component_name,
      options: { auto_load_bundle: auto_load_bundle }.merge(raw_options)
    )
    load_pack_for_generated_component(component_name, render_options)

    initial_result, *rest_chunks = cached_chunks
    hit_fiber = Fiber.new do
      rest_chunks.each { |chunk| Fiber.yield(chunk) }
      nil
    end
    @rorp_rendering_fibers << hit_fiber
    initial_result
  end

  def handle_stream_cache_miss(component_name, raw_options, auto_load_bundle, view_cache_key, &block)
    # Kick off the normal streaming helper to get the initial result and the original fiber
    initial_result = render_stream_component_with_props(component_name, raw_options, auto_load_bundle, &block)
    original_fiber = @rorp_rendering_fibers.pop

    buffered_chunks = [initial_result]
    wrapper_fiber = Fiber.new do
      while (chunk = original_fiber.resume)
        buffered_chunks << chunk
        Fiber.yield(chunk)
      end
      Rails.cache.write(view_cache_key, buffered_chunks, raw_options[:cache_options] || {})
      nil
    end
    @rorp_rendering_fibers << wrapper_fiber
    initial_result
  end

  def render_stream_component_with_props(component_name, raw_options, auto_load_bundle)
    props = yield
    options = raw_options.merge(
      props: props,
      prerender: true,
      skip_prerender_cache: true,
      auto_load_bundle: auto_load_bundle
    )
    stream_react_component(component_name, options)
  end

  def check_caching_options!(raw_options, block)
    raise ReactOnRailsPro::Error, "Pass 'props' as a block if using caching" if raw_options.key?(:props) || block.nil?

    return if raw_options.key?(:cache_key)

    raise ReactOnRailsPro::Error, "Option 'cache_key' is required for React on Rails caching"
  end
end

# frozen_string_literal: true

# NOTE:
# For any heredoc JS:
# 1. The white spacing in this file matters!
# 2. Keep all #{some_var} fully to the left so that all indentation is done evenly in that var
# require "react_on_rails/prerender_error"
require "react_on_rails/react_on_rails_helper"

module ReactOnRailsProHelper
  # Provide caching support for react_component in a manner akin to Rails fragment caching.
  # All the same options as react_component apply with the following diffrence:
  #
  # 1. You must pass the props as a block. This is so that the evaluation of the props is not done
  #    if the cache can be used.
  # 2. Provide the cache_key option
  #
  # cache_key: String or Array containing your cache keys. If prerender is set to true, the server
  #   bundle digest will be included in the cache key. The cache_key value is the same as used for
  #   conventional Rails fragment caching.
  def cached_react_component(component_name, raw_options = {}, &block)
    check_caching_options!(raw_options, block)

    ReactOnRailsPro::ReactComponent::Cache.call(component_name, raw_options) do
      sanitized_options = raw_options
      sanitized_options[:props] = yield
      react_component(component_name, sanitized_options)
    end
  end

  # Provide caching support for react_component_hash in a manner akin to Rails fragment caching.
  # All the same options as react_component apply with the following diffrence:
  #
  # 1. You must pass the props as a block. This is so that the evaluation of the props is not done
  #    if the cache can be used.
  # 2. Provide the cache_key option
  #
  # cache_key: String or Array containing your cache keys. If prerender is set to true, the server
  #   bundle digest will be included in the cache key. The cache_key value is the same as used for
  #   conventional Rails fragment caching.
  def cached_react_component_hash(component_name, raw_options = {}, &block)
    check_caching_options!(raw_options, block)

    ReactOnRailsPro::ReactComponent::Cache.call(component_name, raw_options) do
      sanitized_options = raw_options
      sanitized_options[:props] = yield
      react_component_hash(component_name, sanitized_options)
    end
  end

  private

  def check_caching_options!(raw_options, block)
    raise ReactOnRailsPro::Error, "Pass 'props' as a block if using caching" if raw_options.key?(:props) || block.nil?

    return if raw_options.key?(:cache_key)

    raise ReactOnRailsPro::Error, "Option 'cache_key' is required for React on Rails caching"
  end
end

# frozen_string_literal: true

module ReactOnRailsPro
  # ImmediateAsyncValue is returned when a cached_async_react_component call
  # has a cache hit. It provides the same interface as AsyncValue but returns
  # the cached value immediately without any async operations.
  #
  class ImmediateAsyncValue
    def initialize(value)
      @value = value
    end

    attr_reader :value

    def resolved?
      true
    end

    def to_s
      @value.to_s
    end

    def html_safe
      @value.html_safe
    end
  end
end

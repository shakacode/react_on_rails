# frozen_string_literal: true

module ReactOnRailsPro
  # AsyncValue wraps an Async task to provide a simple interface for
  # retrieving the result of an async react_component render.
  #
  # @example
  #   async_value = async_react_component("MyComponent", props: { name: "World" })
  #   # ... do other work ...
  #   html = async_value.value  # blocks until result is ready
  #
  class AsyncValue
    def initialize(task:)
      @task = task
    end

    # Blocks until result is ready, returns HTML string.
    # If the async task raised an exception, it will be re-raised here.
    def value
      @task.wait
    end

    def resolved?
      @task.finished?
    end

    def to_s
      value.to_s
    end

    def html_safe
      value.html_safe
    end
  end
end

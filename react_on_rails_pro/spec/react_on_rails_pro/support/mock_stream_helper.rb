# frozen_string_literal: true

# MockStreamHelper provides mocking helpers for HTTP streaming tests.
# During migration from HTTPX to async-http, this supports both libraries.
module MockStreamHelper
  # HTTPX-based mocking (legacy, being phased out)
  if defined?(HTTPX::Plugins::MockStream)
    def mock_streaming_response(url, status = 200, count: 1, &block)
      HTTPX::Plugins::MockStream.mock_streaming_response(url, status, count: count, &block)
    end

    def clear_stream_mocks
      HTTPX::Plugins::MockStream.clear_mocks
    end
  else
    # Stub methods when HTTPX is not available
    def mock_streaming_response(_url, _status = 200, count: 1, &_block) # rubocop:disable Lint/UnusedMethodArgument
      raise "HTTPX mock_streaming_response is not available. Use async-http Mock::Endpoint instead."
    end

    def clear_stream_mocks
      # No-op when HTTPX is not available
    end
  end
end

RSpec.configure do |config|
  config.include MockStreamHelper

  config.before do
    # Only clear HTTPX mocks if available
    HTTPX::Plugins::MockStream.clear_mocks if defined?(HTTPX::Plugins::MockStream)
  end
end

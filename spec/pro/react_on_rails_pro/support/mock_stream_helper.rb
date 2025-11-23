# frozen_string_literal: true

module MockStreamHelper
  def mock_streaming_response(url, status = 200, count: 1, &block)
    HTTPX::Plugins::MockStream.mock_streaming_response(url, status, count: count, &block)
  end

  def clear_stream_mocks
    HTTPX::Plugins::MockStream.clear_mocks
  end
end

RSpec.configure do |config|
  config.include MockStreamHelper

  config.before do
    HTTPX::Plugins::MockStream.clear_mocks
  end
end

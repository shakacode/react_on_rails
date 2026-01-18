# frozen_string_literal: true

require "async"
require "async/http/mock"
require "protocol/http"
require "protocol/http/body/writable"

# Minimal async-http test helpers
# These provide simple utilities for mocking async-http responses in tests.
# We intentionally keep this minimal - use async-http's native Mock::Endpoint
# directly for complex test scenarios.
module AsyncHttpTestHelpers
  # Creates a streaming response body that yields chunks.
  # Usage:
  #   body = streaming_body do |b|
  #     b.write("chunk1\n")
  #     b.write("chunk2\n")
  #   end
  #   Protocol::HTTP::Response[200, {}, body]
  def streaming_body
    body = Protocol::HTTP::Body::Writable.new
    Async do
      yield(body)
      body.close_write
    end
    body
  end

  # Stubs ReactOnRailsPro::Request to use a mock endpoint.
  # Usage:
  #   endpoint = Async::HTTP::Mock::Endpoint.new
  #   stub_request_client_with(endpoint)
  def stub_request_client_with(endpoint)
    allow(ReactOnRailsPro::Request).to receive(:create_connection) do
      client = Async::HTTP::Client.new(endpoint)
      [client, endpoint]
    end
  end

  # Creates a mock async-http response for use with instance_double.
  # The response has .status and .body.each interface matching async-http.
  # Usage:
  #   response = mock_async_response(status: 200, chunks: ["chunk1\n", "chunk2\n"])
  def mock_async_response(status:, chunks: [])
    mock_body = instance_double(Protocol::HTTP::Body::Readable)
    allow(mock_body).to receive(:each) do |&block|
      chunks.each { |chunk| block.call(chunk) }
    end

    instance_double(Protocol::HTTP::Response, status: status, body: mock_body)
  end
end

RSpec.configure do |config|
  config.include AsyncHttpTestHelpers
end

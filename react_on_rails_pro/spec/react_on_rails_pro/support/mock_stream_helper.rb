# frozen_string_literal: true

require "json"
require "uri"

module MockStreamHelper
  class MockRequest
    attr_reader :url, :path, :form, :json, :stream

    def initialize(url:, path:, form:, json:, stream:)
      @url = url
      @path = path
      @form = form
      @json = json
      @stream = stream
    end

    def body
      if form
        URI.encode_www_form(flat_form)
      elsif json
        JSON.generate(json)
      else
        ""
      end
    end

    private

    def flat_form
      form.each_with_object([]) do |(key, value), pairs|
        next pairs << [key, "[file]"] if value.is_a?(Hash) && value.key?(:body)

        if value.is_a?(Array)
          value.each { |item| pairs << ["#{key}[]", item] }
        else
          pairs << [key, value]
        end
      end
    end
  end

  class MockClient
    def initialize(origin)
      @origin = origin
    end

    def post(path, form: nil, json: nil, stream: false)
      request = MockRequest.new(url: full_url(path), path: path, form: form, json: json, stream: stream)
      build_response(request)
    end

    def get(path)
      request = MockRequest.new(url: full_url(path), path: path, form: nil, json: nil, stream: false)
      build_response(request)
    end

    def post_bidi(_path, headers: [])
      raise NotImplementedError, "MockClient does not support post_bidi; use a real renderer for incremental tests"
    end

    def close; end

    private

    def full_url(path)
      "#{@origin}#{path}"
    end

    def build_response(request)
      status, block, request_data = MockStream.next_response(request.url)
      request_data[:request] = request

      if request.stream
        return ReactOnRailsPro::RendererHttpClient::Response.new(status: status) do |yielder, _status_assigner|
          # The mock pre-sets status above; pass the request so specs can assert on the captured payload.
          block.call(->(value) { yielder.call(value) }, request)
        end
      end

      chunks = []
      error = nil
      begin
        block.call(->(value) { chunks << value }, request)
      rescue StandardError => e
        error = e
      end

      ReactOnRailsPro::RendererHttpClient::Response.new(status: status, body: chunks, error: error)
    end
  end

  module MockStream
    class << self
      def mock_responses
        @mock_responses ||= {}
      end

      def clear_mocks
        @mock_responses = {}
      end

      def mock_streaming_response(url, status = 200, count: 1, &block)
        unless count == Float::INFINITY || (count.is_a?(Integer) && count.positive?)
          raise ArgumentError, "count must be a positive Integer or Float::INFINITY"
        end

        mock_responses[url] ||= []

        if mock_responses[url].any? { |mock| mock[:remaining] == Float::INFINITY }
          raise "Cannot add mock for #{url}: infinite mock already exists"
        end

        request_data = { request: nil }
        mock_responses[url] << {
          status: status,
          block: block,
          remaining: count,
          request_data: request_data
        }
        request_data
      end

      def next_response(url)
        pattern, responses = find_mock(url)
        raise "Unmocked request detected! URI: #{url}" unless responses

        response = responses.first
        update_mock_count(pattern, responses, response)
        [response.fetch(:status), response.fetch(:block), response.fetch(:request_data)]
      end

      private

      def find_mock(url)
        mock_responses.find do |pattern, _responses|
          case pattern
          when String
            pattern == url
          when Regexp
            pattern.match?(url)
          end
        end
      end

      def update_mock_count(pattern, responses, response)
        return if response[:remaining] == Float::INFINITY

        response[:remaining] -= 1
        responses.shift if response[:remaining].zero?
        mock_responses.delete(pattern) if responses.empty?
      end
    end
  end

  def mock_streaming_response(url, status = 200, count: 1, &block)
    MockStream.mock_streaming_response(url, status, count: count, &block)
  end

  def clear_stream_mocks
    MockStream.clear_mocks
  end

  def install_renderer_http_client_mock(origin)
    ReactOnRailsPro::Request.instance_variable_set(:@connection, nil)
    allow(ReactOnRailsPro::Request).to receive(:create_connection).and_return(MockClient.new(origin))
  end
end

RSpec.configure do |config|
  config.include MockStreamHelper

  config.before do
    MockStreamHelper::MockStream.clear_mocks
  end
end

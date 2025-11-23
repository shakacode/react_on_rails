# frozen_string_literal: true

module HTTPX
  module Plugins
    module MockStream
      module OptionsMethods
        def option_stream(stream)
          stream
        end
      end

      module ResponseMethods
        attr_accessor :mocked

        def initialize(*)
          super
          @mocked = false
        end
      end

      module ResponseBodyMethods
        def decode_chunk(chunk)
          return chunk if @response.mocked

          super
        end
      end

      module ConnectionMethods
        def initialize(*)
          super
          @mocked = true
        end

        def send(request)
          # Do not produce a new response if this request already finished.
          return if request.response&.finished?

          request_uri = request.uri.to_s
          mock = find_mock(request_uri)
          validate_mock!(request_uri, request.verb, mock)

          pattern, responses = mock
          handle_mock_response(request, pattern, responses)
        end

        def validate_mock!(request_uri, verb, mock)
          raise "Unmocked request detected! URI: #{request_uri}, Method: #{verb}" unless mock
        end

        def create_response(request, status)
          request.options.response_class.new(request, status, "2.0", {}).tap do |res|
            res.mocked = true
          end
        end

        def setup_response(request, status)
          response = create_response(request, status)
          request.response = response
          response
        end

        def handle_mock_response(request, pattern, responses)
          current_mock = responses.first
          status, mock_block, count, request_data = current_mock

          request_data[:request] = request
          response = setup_response(request, status)

          # For streaming responses, handle the chunks properly
          if request.stream
            # Stream the response chunks via the stream callback
            yielder = lambda { |value|
              # Call the stream's on_chunk method to deliver chunks
              request.stream.on_chunk(value)
            }
            mock_block.call(yielder, request)
          else
            # For non-streaming responses, collect all chunks and write them to response body
            chunks = []
            yielder = ->(value) { chunks << value }
            mock_block.call(yielder, request)

            # Write all chunks to the response body
            chunks.each { |chunk| response << chunk }
          end
          # Mark the response as finished after all chunks are yielded
          response.finish!
          request.emit(:response, response)

          update_mock_count(pattern, responses, current_mock, count)
        end

        def update_mock_count(pattern, responses, current_mock, count)
          return if count == Float::INFINITY

          count -= 1
          if count.zero?
            responses.shift
            MockStream.mock_responses.delete(pattern) if responses.empty?
          else
            current_mock[2] = count
          end
        end

        def find_mock(request_uri)
          MockStream.mock_responses.find do |pattern, _responses|
            case pattern
            when String
              pattern == request_uri
            when Regexp
              pattern.match?(request_uri)
            end
          end
        end

        def open?
          return true if @mocked

          super
        end

        def interests
          return if @mocked

          super
        end
      end

      class << self
        def mock_responses
          @mock_responses ||= {}
        end

        def clear_mocks
          @mock_responses = {}
        end
      end

      def self.mock_streaming_response(url, status = 200, count: 1, &block)
        MockStream.mock_responses[url] ||= []

        if mock_responses[url].any? { |m| m[2] == Float::INFINITY }
          raise "Cannot add mock for #{url}: infinite mock already exists"
        end

        request_data = { request: nil }
        mock_responses[url] << [status, block, count, request_data]
        request_data
      end
    end
    register_plugin :mock_stream, MockStream
  end
end

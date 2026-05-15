# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails_pro/stream_request"
require "async/barrier"
require "httpx"

HTTPX::Plugins.load_plugin(:stream)

RSpec.describe ReactOnRailsPro::StreamRequest do
  # Wraps a string in the length-prefixed wire format for mock streaming responses.
  def to_length_prefixed(html)
    metadata = { "consoleReplayScript" => "", "hasErrors" => false, "isShellReady" => true, "payloadType" => "string" }
    content_bytes = html.bytesize.to_s(16).rjust(8, "0")
    "#{metadata.to_json}\t#{content_bytes}\n#{html}"
  end

  describe ".create" do
    it "returns a StreamDecorator instance" do
      # Passed block is not called until #each_chunk is invoked, so we can just pass a no-op block here.
      # As it won't be called during this test
      result = described_class.create { nil }
      expect(result).to be_a(ReactOnRailsPro::StreamDecorator)
    end
  end

  describe "#process_response_chunks" do
    subject(:request) { described_class.send(:new) { nil } }

    let(:error_body) { +"" }

    it "treats responses without status delegation as error responses" do
      response = Class.new do
        def each
          yield "Failed request body"
        end

        def status
          raise NoMethodError, "undefined method `status`"
        end
      end.new

      yielded_chunks = []
      expect do
        request.send(:process_response_chunks, response, error_body) do |chunk|
          yielded_chunks << chunk
        end
      end.not_to raise_error

      expect(error_body).to eq("Failed request body")
      expect(yielded_chunks).to be_empty
    end
  end

  # Unverified doubles are required for streaming responses because:
  # 1. HTTP streaming responses don't have a dedicated class type in HTTPX
  # 2. The #each method for streaming is added dynamically at runtime
  # 3. The interface varies based on the streaming mode (HTTP/2, chunked, etc.)
  # rubocop:disable RSpec/VerifiedDoubles
  describe "#each_chunk with barrier" do
    it "passes barrier to request_executor block" do
      barrier_received = nil
      mock_response = double(HTTPX::StreamResponse, status: 200)
      allow(mock_response).to receive(:is_a?).with(HTTPX::ErrorResponse).and_return(false)
      allow(mock_response).to receive(:each).and_yield(to_length_prefixed("chunk"))

      stream = described_class.create do |_send_bundle, barrier|
        barrier_received = barrier
        mock_response
      end

      stream.each_chunk(&:itself)

      expect(barrier_received).to be_a(Async::Barrier)
    end

    it "calls barrier.wait after yielding chunks" do
      barrier = Async::Barrier.new
      allow(Async::Barrier).to receive(:new).and_return(barrier)
      expect(barrier).to receive(:wait)

      mock_response = double(HTTPX::StreamResponse, status: 200)
      allow(mock_response).to receive(:is_a?).with(HTTPX::ErrorResponse).and_return(false)
      allow(mock_response).to receive(:each).and_yield(to_length_prefixed("chunk"))

      stream = described_class.create do |_send_bundle, _barrier|
        mock_response
      end

      stream.each_chunk(&:itself)
    end
  end
  # rubocop:enable RSpec/VerifiedDoubles

  # rubocop:disable RSpec/VerifiedDoubles
  describe "error handling" do
    def build_http_error(status)
      response = double("response", status: status, headers: {}, body: "")
      HTTPX::HTTPError.new(response)
    end

    it "raises ReactOnRailsPro::Error on HTTPX::ReadTimeoutError" do
      mock_request = double("request")
      mock_response = double("response")
      timeout_error = HTTPX::ReadTimeoutError.new(mock_request, mock_response, 5)

      stream = described_class.create do |_send_bundle, _barrier|
        raise timeout_error
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(
        ReactOnRailsPro::Error,
        /Time out error while server side render streaming a component/
      )
    end

    it "raises ReactOnRailsPro::Error on HTTP 400 (bad request)" do
      stream = described_class.create do |_send_bundle, _barrier|
        raise build_http_error(400)
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(
        ReactOnRailsPro::Error,
        /Renderer rejected malformed request or hit an unhandled VM error/
      )
    end

    it "raises ReactOnRailsPro::Error on STATUS_INCOMPATIBLE (412)" do
      stream = described_class.create do |_send_bundle, _barrier|
        raise build_http_error(412)
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(ReactOnRailsPro::Error)
    end

    it "raises ReactOnRailsPro::Error on unexpected status codes" do
      stream = described_class.create do |_send_bundle, _barrier|
        raise build_http_error(503)
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(
        ReactOnRailsPro::Error,
        /Unexpected response code from renderer: 503/
      )
    end

    it "retries with bundle upload on HTTP 410 (send bundle)" do
      call_count = 0
      mock_response = double(HTTPX::StreamResponse, status: 200)
      allow(mock_response).to receive(:is_a?).with(HTTPX::ErrorResponse).and_return(false)
      allow(mock_response).to receive(:each).and_yield(to_length_prefixed("ok"))

      stream = described_class.create do |send_bundle, _barrier|
        call_count += 1
        raise build_http_error(410) if call_count == 1

        expect(send_bundle).to be true
        mock_response
      end

      chunks = []
      stream.each_chunk { |c| chunks << c }
      expect(call_count).to eq(2)
      expect(chunks.first).to include("html" => "ok")
    end

    it "prevents infinite loop on duplicate 410 responses" do
      stream = described_class.create do |_send_bundle, _barrier|
        raise build_http_error(410)
      end

      expect { stream.each_chunk(&:itself) }.to raise_error(ReactOnRailsPro::Error)
    end
  end
  # rubocop:enable RSpec/VerifiedDoubles
end

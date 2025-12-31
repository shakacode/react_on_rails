# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails_pro/stream_request"
require "async/barrier"
require "httpx"

HTTPX::Plugins.load_plugin(:stream)

RSpec.describe ReactOnRailsPro::StreamRequest do
  describe ".create" do
    it "returns a StreamDecorator instance" do
      result = described_class.create { mock_response }
      expect(result).to be_a(ReactOnRailsPro::StreamDecorator)
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
      allow(mock_response).to receive(:each).and_yield("chunk\n")

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
      allow(mock_response).to receive(:each).and_yield("chunk\n")

      stream = described_class.create do |_send_bundle, _barrier|
        mock_response
      end

      stream.each_chunk(&:itself)
    end
  end
  # rubocop:enable RSpec/VerifiedDoubles
end

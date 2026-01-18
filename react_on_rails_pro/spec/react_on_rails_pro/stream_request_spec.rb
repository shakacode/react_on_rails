# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails_pro/stream_request"
require "async/barrier"
require "protocol/http"

RSpec.describe ReactOnRailsPro::StreamRequest do
  describe ".create" do
    it "returns a StreamDecorator instance" do
      # Create a minimal mock response that satisfies the StreamRequest interface
      mock_body = instance_double(Protocol::HTTP::Body::Readable)
      allow(mock_body).to receive(:each) # No chunks yielded

      mock_response = instance_double(Protocol::HTTP::Response, status: 200, body: mock_body)

      result = described_class.create { |_send_bundle, _barrier| mock_response }
      expect(result).to be_a(ReactOnRailsPro::StreamDecorator)
    end
  end

  describe "#each_chunk with barrier" do
    it "passes barrier to request_executor block" do
      barrier_received = nil

      # Create mock response with async-http interface
      mock_body = instance_double(Protocol::HTTP::Body::Readable)
      allow(mock_body).to receive(:each).and_yield("chunk\n")

      mock_response = instance_double(Protocol::HTTP::Response, status: 200, body: mock_body)

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

      # Create mock response with async-http interface
      mock_body = instance_double(Protocol::HTTP::Body::Readable)
      allow(mock_body).to receive(:each).and_yield("chunk\n")

      mock_response = instance_double(Protocol::HTTP::Response, status: 200, body: mock_body)

      stream = described_class.create do |_send_bundle, _barrier|
        mock_response
      end

      stream.each_chunk(&:itself)
    end
  end
end

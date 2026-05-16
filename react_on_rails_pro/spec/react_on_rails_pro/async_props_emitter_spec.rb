# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails_pro/async_props_emitter"

RSpec.describe ReactOnRailsPro::AsyncPropsEmitter do
  let(:bundle_timestamp) { "bundle-12345" }
  # rubocop:disable RSpec/VerifiedDoubleReference
  let(:request_stream) { instance_double("RequestStream") }
  # rubocop:enable RSpec/VerifiedDoubleReference
  let(:emitter) { described_class.new(bundle_timestamp, request_stream) }

  describe "#call" do
    it "writes NDJSON update chunk with correct structure" do
      allow(request_stream).to receive(:<<)

      emitter.call("books", ["Book 1", "Book 2"])

      expect(request_stream).to have_received(:<<) do |output|
        expect(output).to end_with("\n")
        parsed = JSON.parse(output.chomp)
        expect(parsed["bundleTimestamp"]).to eq(bundle_timestamp)
        expected_js = "asyncPropsManager = ReactOnRails.getOrCreateAsyncPropsManager(sharedExecutionContext)"
        expect(parsed["updateChunk"]).to include(expected_js)
        expect(parsed["updateChunk"]).to include('asyncPropsManager.setProp("books", ["Book 1","Book 2"])')
      end
    end

    it "writes separate NDJSON lines for each prop" do
      outputs = []
      allow(request_stream).to receive(:<<) { |output| outputs << output }

      emitter.call("users", [{ "name" => "Alice" }])
      emitter.call("posts", ["Post 1"])

      expect(outputs.size).to eq(2)
      expect(outputs).to all(end_with("\n"))

      first = JSON.parse(outputs[0].chomp)
      expect(first["updateChunk"]).to include('setProp("users"')
      expect(first["updateChunk"]).to include('"name":"Alice"')

      second = JSON.parse(outputs[1].chomp)
      expect(second["updateChunk"]).to include('setProp("posts"')
      expect(second["updateChunk"]).to include('"Post 1"')
    end

    it "logs error and continues without raising when write fails" do
      mock_logger = instance_double(Logger)
      allow(Rails).to receive(:logger).and_return(mock_logger)
      allow(request_stream).to receive(:<<).and_raise(StandardError.new("Connection lost"))
      allow(mock_logger).to receive(:error)

      expect { emitter.call("books", []) }.not_to raise_error

      expect(mock_logger).to have_received(:error) do |&block|
        message = block.call
        expect(message).to include("Failed to send async prop 'books'")
        expect(message).to include("Connection lost")
      end
    end
  end

  describe "#end_stream_chunk" do
    it "returns a hash with bundleTimestamp and endStream JS" do
      chunk = emitter.end_stream_chunk

      expect(chunk[:bundleTimestamp]).to eq(bundle_timestamp)
      expect(chunk[:updateChunk]).to include("getOrCreateAsyncPropsManager(sharedExecutionContext)")
      expect(chunk[:updateChunk]).to include("asyncPropsManager.endStream()")
    end
  end
end

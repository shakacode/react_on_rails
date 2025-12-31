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
        expect(parsed["updateChunk"]).to include('sharedExecutionContext.get("asyncPropsManager")')
        expect(parsed["updateChunk"]).to include('asyncPropsManager.setProp("books", ["Book 1","Book 2"])')
      end
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
end

# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails_pro/stream_request"

RSpec.describe ReactOnRailsPro::StreamDecorator do
  subject(:stream_decorator) { described_class.new(mock_component) }

  let(:mock_component) { instance_double(ReactOnRailsPro::StreamRequest) }

  describe "chaining methods" do
    it "allows chaining of prepend, transform, and append" do
      result = stream_decorator.prepend { "start" }
                               .transform(&:upcase)
                               .append { "end" }
      expect(result).to eq(stream_decorator)
    end
  end

  describe "#each_chunk" do
    before do
      allow(mock_component).to receive(:each_chunk).and_yield("chunk1").and_yield("chunk2")
    end

    it "yields chunks from the component" do
      chunks = []
      stream_decorator.each_chunk { |chunk| chunks << chunk }
      expect(chunks).to eq(%w[chunk1 chunk2])
    end

    it "prepends content to the first chunk" do
      stream_decorator.prepend { "start-" }
      chunks = []
      stream_decorator.each_chunk { |chunk| chunks << chunk }
      expect(chunks.first).to start_with("start-")
    end

    it "transforms non-empty chunks" do
      stream_decorator.transform(&:upcase)
      chunks = []
      stream_decorator.each_chunk { |chunk| chunks << chunk }
      expect(chunks).to all(match(/^CHUNK\d$/))
    end

    it "appends content to the last chunk" do
      stream_decorator.append { "-end" }
      chunks = []
      stream_decorator.each_chunk { |chunk| chunks << chunk }
      expect(chunks.last).to end_with("-end")
    end

    it "combines prepend, transform, and append operations" do
      stream_decorator.prepend { "start-" }
                      .transform(&:upcase)
                      .append { "-end" }

      chunks = []
      stream_decorator.each_chunk { |chunk| chunks << chunk }

      expect(chunks.first).to start_with("START-")
      expect(chunks[1..-2]).to all(match(/^CHUNK\d$/))
      expect(chunks.last).to end_with("-end")
    end
  end
end

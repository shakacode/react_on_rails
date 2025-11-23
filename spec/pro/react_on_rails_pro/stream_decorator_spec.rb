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

  describe "#rescue" do
    it "catches the error happens inside the component" do
      allow(mock_component).to receive(:each_chunk).and_raise(StandardError.new("Fake Error"))
      mocked_block = mock_block

      stream_decorator.rescue(&mocked_block.block)
      chunks = []
      expect { stream_decorator.each_chunk { |chunk| chunks << chunk } }.not_to raise_error

      expect(mocked_block).to have_received(:call) do |error|
        expect(error).to be_a(StandardError)
        expect(error.message).to eq("Fake Error")
      end
      expect(chunks).to eq([])
    end

    it "catches the error happens inside subsequent component calls" do
      allow(mock_component).to receive(:each_chunk).and_yield("Chunk1").and_raise(ArgumentError.new("Fake Error"))
      mocked_block = mock_block

      stream_decorator.rescue(&mocked_block.block)
      chunks = []
      expect { stream_decorator.each_chunk { |chunk| chunks << chunk } }.not_to raise_error

      expect(mocked_block).to have_received(:call) do |error|
        expect(chunks).to eq(["Chunk1"])
        expect(error).to be_a(ArgumentError)
        expect(error.message).to eq("Fake Error")
      end
      expect(chunks).to eq(["Chunk1"])
    end

    it "can yield values to the stream" do
      allow(mock_component).to receive(:each_chunk).and_yield("Chunk1").and_raise(ArgumentError.new("Fake Error"))
      mocked_block = mock_block

      stream_decorator.rescue(&mocked_block.block)
      chunks = []
      expect { stream_decorator.each_chunk { |chunk| chunks << chunk } }.not_to raise_error

      expect(mocked_block).to have_received(:call) do |error, &inner_block|
        expect(chunks).to eq(["Chunk1"])
        expect(error).to be_a(ArgumentError)
        expect(error.message).to eq("Fake Error")

        inner_block.call "Chunk from rescue block"
        inner_block.call "Chunk2 from rescue block"
      end
      expect(chunks).to eq(["Chunk1", "Chunk from rescue block", "Chunk2 from rescue block"])
    end

    it "can convert the error into another error" do
      allow(mock_component).to receive(:each_chunk).and_raise(StandardError.new("Fake Error"))
      mocked_block = mock_block do |error|
        expect(error).to be_a(StandardError)
        expect(error.message).to eq("Fake Error")
        raise ArgumentError, "Another Error"
      end

      stream_decorator.rescue(&mocked_block.block)
      chunks = []
      expect { stream_decorator.each_chunk { |chunk| chunks << chunk } }.to raise_error(ArgumentError, "Another Error")
      expect(chunks).to eq([])
    end

    it "chains multiple rescue blocks" do
      allow(mock_component).to receive(:each_chunk).and_yield("Chunk1").and_raise(StandardError.new("Fake Error"))
      fist_rescue_block = mock_block do |error, &block|
        expect(error).to be_a(StandardError)
        expect(error.message).to eq("Fake Error")
        block.call "Chunk from first rescue block"
        raise ArgumentError, "Another Error"
      end

      second_rescue_block = mock_block do |error, &block|
        expect(error).to be_a(ArgumentError)
        expect(error.message).to eq("Another Error")
        block.call "Chunk from second rescue block"
      end

      stream_decorator.rescue(&fist_rescue_block.block)
      stream_decorator.rescue(&second_rescue_block.block)
      chunks = []
      expect { stream_decorator.each_chunk { |chunk| chunks << chunk } }.not_to raise_error

      expect(chunks).to eq(["Chunk1", "Chunk from first rescue block", "Chunk from second rescue block"])
    end
  end
end

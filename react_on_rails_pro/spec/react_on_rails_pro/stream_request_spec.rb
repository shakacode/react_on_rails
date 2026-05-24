# frozen_string_literal: true

require_relative "spec_helper"
require "react_on_rails_pro/stream_request"

RSpec.describe ReactOnRailsPro::StreamRequest do
  describe ".create" do
    it "returns a StreamDecorator instance" do
      # Block is not invoked until #each_chunk runs; this example only checks the return type.
      result = described_class.create { nil }
      expect(result).to be_a(ReactOnRailsPro::StreamDecorator)
    end
  end

  describe "#process_response_chunks" do
    subject(:request) { described_class.send(:new) { nil } }

    let(:error_body) { +"" }

    it "uses status as the fallback for non-Response adapters" do
      response = Class.new do
        def each
          yield "Failed request body"
        end

        def status
          500
        end
      end.new

      yielded_chunks = []

      request.send(:process_response_chunks, response, error_body) do |chunk|
        yielded_chunks << chunk
      end

      expect(error_body).to eq("Failed request body")
      expect(yielded_chunks).to be_empty
    end

    it "treats nil fallback status as not-yet-an-error" do
      lpp_chunk = "{}\t00000005\nFirst"
      response = Class.new do
        define_method(:each) { |&block| block.call(lpp_chunk) }

        def status
          nil
        end
      end.new

      yielded_chunks = []

      request.send(:process_response_chunks, response, error_body) do |chunk|
        yielded_chunks << chunk
      end

      expect(yielded_chunks).to eq([{ "html" => "First" }])
      expect(error_body).to eq("")
    end

    it "checks error status once after a lazy stream starts" do
      lpp_chunks = [
        "{}\t00000005\nFirst",
        "{}\t00000006\nSecond"
      ]
      response = Class.new do
        attr_reader :error_checks

        def initialize(chunks)
          @chunks = chunks
          @error_checks = 0
        end

        def each(&block)
          @chunks.each(&block)
        end

        def error?
          @error_checks += 1
          false
        end
      end.new(lpp_chunks)

      yielded_chunks = []
      request.send(:process_response_chunks, response, error_body) do |chunk|
        yielded_chunks << chunk
      end

      expect(response.error_checks).to eq(1)
      expect(yielded_chunks).to eq([{ "html" => "First" }, { "html" => "Second" }])
      expect(error_body).to eq("")
    end

    it "surfaces malformed fallback responses with a clear adapter error" do
      response = Class.new do
        def each
          yield "Failed request body"
        end
      end.new

      yielded_chunks = []
      expect do
        request.send(:process_response_chunks, response, error_body) do |chunk|
          yielded_chunks << chunk
        end
      end.to raise_error(NotImplementedError, /must implement #error\? or #status/)

      expect(error_body).to eq("")
      expect(yielded_chunks).to be_empty
    end

    it "propagates renderer errors that arrive mid-stream" do
      response_error = ReactOnRailsPro::RendererHttpClient::ConnectionError.new("renderer reset")
      response = Class.new do
        def initialize(error)
          @error = error
        end

        def each
          yield "partial"
          raise @error
        end

        def error?
          false
        end
      end.new(response_error)

      yielded_chunks = []
      expect do
        request.send(:process_response_chunks, response, error_body) { |chunk| yielded_chunks << chunk }
      end.to raise_error(ReactOnRailsPro::RendererHttpClient::ConnectionError, /renderer reset/)
      expect(yielded_chunks).to be_empty
    end
  end

  describe "#each_chunk" do
    it "does not carry error bodies across bundle-send retries" do
      responses = [
        ReactOnRailsPro::RendererHttpClient::Response.new(
          status: ReactOnRailsPro::STATUS_SEND_BUNDLE,
          body: ["bundle diagnostic"]
        ),
        ReactOnRailsPro::RendererHttpClient::Response.new(
          status: ReactOnRailsPro::STATUS_BAD_REQUEST,
          body: ["bad request body"]
        )
      ]
      request = described_class.send(:new) { responses.shift }
      yielded_chunks = []

      expect { request.each_chunk { |chunk| yielded_chunks << chunk } }.to raise_error(
        ReactOnRailsPro::Error,
        "Renderer rejected malformed request or hit an unhandled VM error: " \
        "#{ReactOnRailsPro::STATUS_BAD_REQUEST}:\nbad request body"
      )
      expect(yielded_chunks).to be_empty
    end
  end
end

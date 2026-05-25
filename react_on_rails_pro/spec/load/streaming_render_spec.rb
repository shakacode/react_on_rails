# frozen_string_literal: true

require_relative "spec_helper"
require "scenarios/streaming_render"

RSpec.describe RendererHarness::Scenarios::StreamingRender do
  def build_config(**overrides)
    Struct.new(:mix, keyword_init: true).new({ mix: "small" }.merge(overrides))
  end

  def build_stream(status:, chunks:)
    Struct.new(:status, :chunks) do
      def each_chunk(&block)
        chunks.each(&block)
      end
    end.new(status, chunks)
  end

  before do
    stub_const("ReactOnRailsPro", Module.new) unless defined?(ReactOnRailsPro)
    stub_const(
      "ReactOnRailsPro::Request",
      Class.new do
        def self.render_code_as_stream(*); end
      end
    )
    stub_const("ReactOnRailsPro::ServerRenderingPool", Module.new)
    stub_const(
      "ReactOnRailsPro::ServerRenderingPool::NodeRenderingPool",
      Class.new do
        def self.server_bundle_hash
          "bundle-hash"
        end
      end
    )
  end

  it "marks streaming HTTP error responses as failures" do
    stream = build_stream(status: 503, chunks: ["renderer unavailable"])
    allow(ReactOnRailsPro::Request).to receive(:render_code_as_stream).and_return(stream)

    result = described_class.new(build_config).perform_request

    expect(result.ok).to be(false)
    expect(result.http_status).to eq(503)
    expect(result.error).to eq("Renderer returned 503")
  end

  it "records successful streaming responses as successes" do
    stream = build_stream(status: 200, chunks: [{ "html" => "ok" }])
    allow(ReactOnRailsPro::Request).to receive(:render_code_as_stream).and_return(stream)

    result = described_class.new(build_config).perform_request

    expect(result.ok).to be(true)
    expect(result.http_status).to eq(200)
    expect(result.bytes_in).to eq(2)
  end

  it "marks streams with unavailable status as failures" do
    stream = build_stream(status: nil, chunks: [])
    allow(ReactOnRailsPro::Request).to receive(:render_code_as_stream).and_return(stream)

    result = described_class.new(build_config).perform_request

    expect(result.ok).to be(false)
    expect(result.http_status).to be_nil
    expect(result.error).to eq("Renderer stream status unavailable")
  end
end

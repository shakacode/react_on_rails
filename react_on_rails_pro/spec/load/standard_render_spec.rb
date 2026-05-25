# frozen_string_literal: true

require_relative "spec_helper"
require "scenarios/standard_render"

RSpec.describe RendererHarness::Scenarios::StandardRender do
  def build_config(**overrides)
    Struct.new(:mix, keyword_init: true).new({ mix: "small" }.merge(overrides))
  end

  before do
    stub_const("ReactOnRailsPro", Module.new) unless defined?(ReactOnRailsPro)
    stub_const(
      "ReactOnRailsPro::Request",
      Class.new do
        def self.render_code(*); end
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

  it "preserves HTTP status on renderer error responses" do
    response = Struct.new(:status, :body).new(503, "renderer unavailable")
    allow(ReactOnRailsPro::Request).to receive(:render_code).and_return(response)

    result = described_class.new(build_config).perform_request

    expect(result.ok).to be(false)
    expect(result.http_status).to eq(503)
    expect(result.error).to eq("Renderer returned 503: renderer unavailable")
  end
end

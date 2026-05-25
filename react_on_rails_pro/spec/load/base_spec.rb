# frozen_string_literal: true

require_relative "spec_helper"
require "scenarios/base"

RSpec.describe RendererHarness::Scenarios::Base do
  def build_config(**overrides)
    Struct.new(:mix, keyword_init: true).new({ mix: "small" }.merge(overrides))
  end

  it "converts acronym scenario class names to snake case" do
    scenario_class = Class.new(described_class)
    stub_const("RendererHarness::Scenarios::RSCRender", scenario_class)

    expect(scenario_class.new(build_config).name).to eq("rsc_render")
  end

  it "memoizes the generated scenario name" do
    scenario_class = Class.new(described_class)
    stub_const("RendererHarness::Scenarios::RSCRender", scenario_class)
    scenario = scenario_class.new(build_config)

    expect(scenario.name).to equal(scenario.name)
  end

  it "counts the full length-prefixed streamed frame" do
    scenario = described_class.new(build_config)
    chunk = {
      "html" => "ok",
      "consoleReplayScript" => "",
      "hasErrors" => false,
      "isShellReady" => true,
      "payloadType" => "string"
    }

    metadata_bytes = JSON.generate(chunk.except("html")).bytesize

    expect(scenario.send(:chunk_bytesize, chunk)).to eq(metadata_bytes + 1 + 8 + 1 + "ok".bytesize)
  end

  it "restores string payloadType when estimating parsed streamed frame bytes" do
    scenario = described_class.new(build_config)
    chunk = { "html" => "ok", "hasErrors" => false }
    metadata = { "hasErrors" => false, "payloadType" => "string" }

    expect(scenario.send(:chunk_bytesize, chunk)).to eq(JSON.generate(metadata).bytesize + 1 + 8 + 1 + 2)
  end
end

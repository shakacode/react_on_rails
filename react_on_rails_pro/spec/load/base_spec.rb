# frozen_string_literal: true

require_relative "spec_helper"
require "scenarios/base"

RSpec.describe RendererHarness::Scenarios::Base do
  it "converts acronym scenario class names to snake case" do
    scenario_class = Class.new(described_class)
    stub_const("RendererHarness::Scenarios::RSCRender", scenario_class)
    config = Struct.new(:mix, keyword_init: true).new(mix: "small")

    expect(scenario_class.new(config).name).to eq("rsc_render")
  end
end

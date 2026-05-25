# frozen_string_literal: true

require_relative "spec_helper"
require "harness"

RSpec.describe RendererHarness::Harness do
  def build_config(**overrides)
    Struct.new(:output_dir, :scenario, :concurrency, :mix, :warmup, keyword_init: true).new(
      { output_dir: "tmp/load-tests/spec", scenario: "standard_render", concurrency: 1, mix: "small", warmup: 1 }
        .merge(overrides)
    )
  end

  before do
    stub_const("ReactOnRailsPro", Module.new) unless defined?(ReactOnRailsPro)
    stub_const("ReactOnRailsPro::RENDERER_TRANSPORT_ENV", "RENDERER_TRANSPORT")
    stub_const("ReactOnRailsPro::DEFAULT_RENDERER_TRANSPORT", "http")
  end

  it "computes memory slope from the measured phase only" do
    harness = described_class.new(build_config)
    rows = [
      { t_seconds: 0.0, rails_rss_kb: 100_000 },
      { t_seconds: 1.0, rails_rss_kb: 200_000 },
      { t_seconds: 2.0, rails_rss_kb: 200_000 }
    ]

    summary = harness.send(:build_summary, [], rows, 1.0, 1.0)

    expect(summary[:memory][:rails_slope_mb_per_min]).to eq(0.0)
  end
end

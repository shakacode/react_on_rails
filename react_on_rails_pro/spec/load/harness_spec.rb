# frozen_string_literal: true

require_relative "spec_helper"
require "harness"

RSpec.describe RendererHarness::Harness do
  def build_config(**overrides)
    Struct.new(
      :output_dir,
      :scenario,
      :concurrency,
      :mix,
      :warmup,
      :start_gate_timeout,
      :renderer_pid,
      :mem_interval,
      keyword_init: true
    ).new(
      {
        output_dir: "tmp/load-tests/spec",
        scenario: "standard_render",
        concurrency: 1,
        mix: "small",
        warmup: 1,
        start_gate_timeout: 30.0,
        renderer_pid: nil,
        mem_interval: 1.0
      }
        .merge(overrides)
    )
  end

  before do
    stub_const("ReactOnRailsPro", Module.new) unless defined?(ReactOnRailsPro)
    stub_const("ReactOnRailsPro::Request", Class.new do
      def self.upload_assets; end
    end)
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

  it "defaults output under the Rails root" do
    rails = Class.new do
      def self.root
        "/app"
      end
    end
    stub_const("Rails", rails)
    allow(Time).to receive(:now).and_return(Time.utc(2026, 1, 2, 3, 4, 5))

    harness = described_class.new(build_config(output_dir: nil))

    expect(harness.send(:default_output_dir)).to eq("/app/tmp/load-tests/2026-01-02T03-04-05Z")
  end

  it "warns when an RSS sample is zero" do
    harness = described_class.new(build_config)
    rows = [{ t_seconds: 0.0, rails_rss_kb: 0 }]

    expect(harness).to receive(:warn).with(/1 Rails RSS samples were zero/)

    expect(harness.send(:build_rss_series, rows, :rails_rss_kb, "Rails")).to be_empty
  end

  it "raises a user error when bundle upload times out" do
    stub_const("RendererHarness::Harness::UPLOAD_ASSETS_TIMEOUT_SECONDS", 0.01)
    allow(ReactOnRailsPro::Request).to receive(:upload_assets) { sleep 1 }

    expect { described_class.new(build_config).send(:upload_assets!) }
      .to raise_error(RendererHarness::UserError, /bundle upload timed out/)
  end

  it "cleans up the scenario when bundle upload fails" do
    scenario = instance_double(RendererHarness::Scenarios::StandardRender, cleanup: nil)
    runner = instance_double(RendererHarness::Runner)
    sampler = instance_double(RendererHarness::MemorySampler, stop_background: nil)

    allow(RendererHarness::SCENARIO_REGISTRY.fetch("standard_render")).to receive(:new).and_return(scenario)
    allow(RendererHarness::MemorySampler).to receive(:new).and_return(sampler)
    allow(RendererHarness::Runner).to receive(:new).and_return(runner)
    allow(ReactOnRailsPro::Request).to receive(:upload_assets).and_raise(StandardError, "renderer down")

    expect(sampler).not_to receive(:start_background)

    expect { described_class.new(build_config).run }
      .to raise_error(RendererHarness::UserError, /bundle upload failed/)
    expect(scenario).to have_received(:cleanup)
  end

  it "cleans up the scenario when stopping the sampler fails" do
    scenario = instance_double(RendererHarness::Scenarios::StandardRender, cleanup: nil)
    runner = instance_double(RendererHarness::Runner, run: 0.1, results: [], measurement_started_at: nil)
    sampler = instance_double(RendererHarness::MemorySampler, rows: [])

    allow(RendererHarness::SCENARIO_REGISTRY.fetch("standard_render")).to receive(:new).and_return(scenario)
    allow(RendererHarness::MemorySampler).to receive(:new).and_return(sampler)
    allow(RendererHarness::Runner).to receive(:new).and_return(runner)
    allow(sampler).to receive(:start_background)
    allow(sampler).to receive(:stop_background).and_raise("sampler stuck")

    expect { described_class.new(build_config).run }.to raise_error(/sampler stuck/)
    expect(scenario).to have_received(:cleanup)
  end
end

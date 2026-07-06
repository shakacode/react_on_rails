# frozen_string_literal: true

require "tmpdir"

require_relative "../spec_helper"
require_relative "../../lib/local_benchmark_runner/comparison_summary"

RSpec.describe LocalBenchmarkRunner::ComparisonSummary do
  def write_benchmark_json(dir, name, routes)
    write_raw_benchmark_json(dir, name, routes.transform_keys { |route| "#{route}: Core" })
  end

  def write_raw_benchmark_json(dir, name, benchmarks)
    path = File.join(dir, "#{name}.json")
    payload = benchmarks.transform_values do |rps|
      {
        "rps" => { "value" => rps },
        "p50_latency" => { "value" => 10.0 },
        "p90_latency" => { "value" => 20.0 },
        "failed_pct" => { "value" => 0.0 }
      }
    end
    File.write(path, JSON.pretty_generate(payload))
    path
  end

  it "summarizes median RPS deltas across repeated A/B runs" do
    Dir.mktmpdir do |dir|
      runs = [
        described_class::Run.new(
          scenario: "main",
          repetition: 1,
          benchmark_json: write_benchmark_json(dir, "main-1", "/foo" => 12.0, "/main_only" => 1.0)
        ),
        described_class::Run.new(
          scenario: "main",
          repetition: 2,
          benchmark_json: write_benchmark_json(dir, "main-2", "/foo" => 14.0, "/main_only" => 2.0)
        ),
        described_class::Run.new(
          scenario: "rc5",
          repetition: 1,
          benchmark_json: write_benchmark_json(dir, "rc5-1", "/foo" => 10.0)
        ),
        described_class::Run.new(
          scenario: "rc5",
          repetition: 2,
          benchmark_json: write_benchmark_json(dir, "rc5-2", "/foo" => 12.0)
        )
      ]

      summary = described_class.new(runs:, baseline: "rc5", candidate: "main")

      route = summary.route_summaries.fetch("/foo")
      expect(route.baseline_median_rps).to eq(11.0)
      expect(route.candidate_median_rps).to eq(13.0)
      expect(route.rps_delta_percent).to be_within(0.01).of(18.18)
      expect(summary.only_candidate_routes).to eq(["/main_only"])
      expect(summary.only_baseline_routes).to eq([])
    end
  end

  it "reports scenario-level run counts and route coverage" do
    Dir.mktmpdir do |dir|
      runs = [
        described_class::Run.new(
          scenario: "a",
          repetition: 1,
          benchmark_json: write_benchmark_json(dir, "a-1", "/foo" => 10.0)
        ),
        described_class::Run.new(
          scenario: "b",
          repetition: 1,
          benchmark_json: write_benchmark_json(dir, "b-1", "/foo" => 11.0, "/bar" => 5.0)
        )
      ]

      summary = described_class.new(runs:, baseline: "a", candidate: "b")

      expect(summary.to_h).to include(
        baseline: "a",
        candidate: "b",
        common_route_count: 1,
        baseline_only_route_count: 0,
        candidate_only_route_count: 1,
        run_counts: { "a" => 1, "b" => 1 }
      )
    end
  end

  it "preserves non-route benchmark labels that contain colons" do
    Dir.mktmpdir do |dir|
      baseline_benchmarks = {
        "Pro Node Renderer: simple_eval (non-RSC)" => 20.0,
        "Pro Node Renderer: react_ssr (non-RSC)" => 10.0
      }
      candidate_benchmarks = {
        "Pro Node Renderer: simple_eval (non-RSC)" => 22.0,
        "Pro Node Renderer: react_ssr (non-RSC)" => 11.0
      }
      runs = [
        described_class::Run.new(
          scenario: "baseline",
          repetition: 1,
          benchmark_json: write_raw_benchmark_json(dir, "baseline-1", baseline_benchmarks)
        ),
        described_class::Run.new(
          scenario: "candidate",
          repetition: 1,
          benchmark_json: write_raw_benchmark_json(dir, "candidate-1", candidate_benchmarks)
        )
      ]

      summary = described_class.new(runs:, baseline: "baseline", candidate: "candidate")

      expect(summary.route_summaries.keys).to contain_exactly(
        "Pro Node Renderer: simple_eval (non-RSC)",
        "Pro Node Renderer: react_ssr (non-RSC)"
      )
    end
  end
end

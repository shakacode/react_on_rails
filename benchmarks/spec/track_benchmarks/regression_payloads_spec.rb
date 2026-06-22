# frozen_string_literal: true

require "tmpdir"
require_relative "../spec_helper"
require_relative "../../lib/track_benchmarks"

RSpec.describe TrackBenchmarks::RegressionPayloads do
  def report_with_alert
    BencherReport.parse(
      JSON.generate(
        "results" => [],
        "alerts" => [
          {
            "benchmark" => { "name" => "/posts: Pro" },
            "threshold" => { "measure" => { "slug" => "rps" } },
            "status" => "active"
          }
        ]
      )
    )
  end

  describe ".write_candidate" do
    it "writes the non-fatal first-run regression hand-off payload" do
      allow(Github).to receive(:run_url).and_return("https://github.test/run/1")

      Dir.mktmpdir do |dir|
        path = File.join(dir, "regression-candidate.json")
        ok = nil
        expect do
          ok = described_class.write_candidate(
            report_with_alert,
            "rendered summary",
            "Core shard 1",
            path:,
            env: { "BENCHMARK_SUITE_GROUP" => "Core", "BENCHMARK_SHARD_LABEL" => "1/2" }
          )
        end.to output(/::notice::Bencher flagged a Core shard 1 regression CANDIDATE/).to_stdout

        expect(ok).to be(true)
        payload = JSON.parse(File.read(path))
        expect(payload).to include(
          RegressionReport::SUITE_NAME => "Core",
          RegressionReport::SHARD_LABEL => "1/2",
          RegressionReport::SUMMARY => "rendered summary",
          RegressionReport::REGRESSED_BENCHMARKS => ["/posts: Pro"],
          RegressionReport::ALERTS => [{ "benchmark" => "/posts: Pro", "measure" => "rps" }]
        )
      end
    end
  end

  describe ".write_confirmed" do
    it "writes first-run and confirmation summaries with deduped benchmark names" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "regression-confirmed.json")
        alerts = [
          { "benchmark" => "/posts: Pro", "measure" => "rps" },
          { "benchmark" => "/posts: Pro", "measure" => "p50_latency" }
        ]

        expect(
          described_class.write_confirmed(
            alerts,
            "first run",
            "confirmation run",
            "Core",
            path:,
            env: {}
          )
        ).to be(true)

        payload = JSON.parse(File.read(path))
        expect(payload).to include(
          RegressionReport::SUITE_NAME => "Core",
          RegressionReport::SHARD_LABEL => "",
          RegressionReport::FIRST_RUN_SUMMARY => "first run",
          RegressionReport::CONFIRMATION_SUMMARY => "confirmation run",
          RegressionReport::ALERTS => alerts,
          RegressionReport::REGRESSED_BENCHMARKS => ["/posts: Pro"]
        )
      end
    end
  end
end

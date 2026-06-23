# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "../../lib/track_benchmarks"

RSpec.describe TrackBenchmarks::Cli do
  include BenchmarkEnvHelper

  describe "#run" do
    it "passes injected env through benchmark orchestration gates" do
      env = { "GITHUB_EVENT_NAME" => "push", "GITHUB_REF" => "refs/heads/main" }
      cli = described_class.new(suite_name: "Core", report_marker: "core", env:)
      runner = instance_double(BencherRunner)
      report = instance_double(BencherReport)
      result_type = Struct.new(:stderr, :exit_code, :report, keyword_init: true)
      result = result_type.new(stderr: "", exit_code: 1, report:)

      allow(BencherRunner).to receive(:new).with(
        benchmark_json: TrackBenchmarks::Config::BENCHMARK_JSON,
        report_json: TrackBenchmarks::Config::REPORT_JSON
      ).and_return(runner)
      allow(TrackBenchmarks::BranchArgs).to receive(:branch_and_start_point_args).with(env:).and_return(["main", []])
      allow(TrackBenchmarks::BencherRun).to receive(:run_bencher!).with(runner, "main", []).and_return(result)
      allow(TrackBenchmarks::BencherRun).to receive(:retry_without_start_point_hash?)
        .with("", 1, report)
        .and_return(false)
      allow(TrackBenchmarks::BencherRun).to receive(:normalized_exit_code).with(1, report).and_return(1)
      allow(TrackBenchmarks::Summary).to receive(:rendered_report)
        .with(report, "Core", TrackBenchmarks::Config::DISPLAY_JSON)
        .and_return("summary")
      expect(TrackBenchmarks::Summary).to receive(:post_report_to_summary).with("summary", "Core")
      allow(TrackBenchmarks::BranchArgs).to receive(:confirmation_mode?).with(env:).and_return(false)
      allow(TrackBenchmarks::RegressionPayloads).to receive(:main_push?).with(env:).and_return(true)
      expect(TrackBenchmarks::RegressionPayloads).to receive(:report_main_push_candidate)
        .with(report, "summary", 1, "Core")

      cli.run

      expect(TrackBenchmarks::BranchArgs).to have_received(:branch_and_start_point_args).with(env:)
      expect(TrackBenchmarks::BranchArgs).to have_received(:confirmation_mode?).with(env:)
      expect(TrackBenchmarks::RegressionPayloads).to have_received(:main_push?).with(env:)
    end
  end

  describe "PR event detection" do
    it "does not require a GitHub event env var outside pull requests" do
      cli = described_class.new(suite_name: "Core", report_marker: "core", env: {})
      expect(PrReportPoster).not_to receive(:from_env)

      expect { cli.send(:post_pull_request_report, nil, "summary") }.not_to raise_error
    end

    it "uses the injected event env when posting pull request reports" do
      cli = described_class.new(
        suite_name: "Core",
        report_marker: "core",
        env: { "GITHUB_EVENT_NAME" => "pull_request" }
      )
      report = instance_double(BencherReport)
      poster = instance_double(PrReportPoster)

      allow(TrackBenchmarks::Summary).to receive(:regression?).with(report).and_return(false)
      allow(PrReportPoster).to receive(:from_env).with(suite_name: "Core", marker: "core").and_return(poster)

      expect(poster).to receive(:replace).with("summary")

      cli.send(:post_pull_request_report, report, "summary")
    end
  end
end

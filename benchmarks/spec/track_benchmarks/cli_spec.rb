# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "../../lib/track_benchmarks"

RSpec.describe TrackBenchmarks::Cli do
  include BenchmarkEnvHelper

  describe "#run" do
    let(:result_type) { Struct.new(:stderr, :exit_code, :report, keyword_init: true) }

    def stub_runners(baseline_runner, head_runner)
      allow(BencherRunner).to receive(:new).with(
        benchmark_json: TrackBenchmarks::Config::BASELINE_BENCHMARK_JSON,
        report_json: TrackBenchmarks::Config::BASELINE_REPORT_JSON,
        mode: :relative_baseline
      ).and_return(baseline_runner)
      allow(BencherRunner).to receive(:new).with(
        benchmark_json: TrackBenchmarks::Config::BENCHMARK_JSON,
        report_json: TrackBenchmarks::Config::REPORT_JSON,
        mode: :relative_head
      ).and_return(head_runner)
    end

    it "submits the baseline then the head comparison and passes env through orchestration gates" do
      env = {
        "GITHUB_EVENT_NAME" => "push",
        "GITHUB_REF" => "refs/heads/main",
        "GITHUB_RUN_ID" => "42",
        "BENCHMARK_SUITE_NAME" => "Core"
      }
      cli = described_class.new(suite_name: "Core", report_marker: "core", env:)
      baseline_runner = instance_double(BencherRunner)
      head_runner = instance_double(BencherRunner)
      report = instance_double(BencherReport)
      baseline_result = result_type.new(stderr: "", exit_code: 0, report: nil)
      head_result = result_type.new(stderr: "", exit_code: 1, report:)

      stub_runners(baseline_runner, head_runner)
      allow(TrackBenchmarks::BencherRun).to receive(:run_bencher!)
        .with(baseline_runner, "base-42-core", ["--start-point-reset"])
        .and_return(baseline_result)
      allow(TrackBenchmarks::BencherRun).to receive(:run_bencher!)
        .with(head_runner, "main", %w[--start-point base-42-core --start-point-reset])
        .and_return(head_result)
      allow(TrackBenchmarks::BencherRun).to receive(:normalized_exit_code).with(1, report).and_return(1)
      allow(TrackBenchmarks::Summary).to receive(:samples_by_name).and_return({})
      allow(TrackBenchmarks::Summary).to receive(:rendered_report)
        .with(report, "Core", TrackBenchmarks::Config::DISPLAY_JSON)
        .and_return("summary")
      expect(TrackBenchmarks::Summary).to receive(:post_report_to_summary).with("summary", "Core")
      allow(TrackBenchmarks::RegressionPayloads).to receive(:main_push?).with(env:).and_return(true)
      expect(TrackBenchmarks::RegressionPayloads).to receive(:report_main_push_candidate)
        .with(report, "summary", 1, "Core")

      cli.run

      expect(TrackBenchmarks::BencherRun).to have_received(:run_bencher!).twice
      expect(TrackBenchmarks::RegressionPayloads).to have_received(:main_push?).with(env:)
    end

    it "applies sample confirmation from both sidecars before normalizing the exit code" do
      env = {
        "GITHUB_EVENT_NAME" => "push",
        "GITHUB_REF" => "refs/heads/main",
        "GITHUB_RUN_ID" => "42",
        "BENCHMARK_SUITE_NAME" => "Core"
      }
      cli = described_class.new(suite_name: "Core", report_marker: "core", env:)
      baseline_runner = instance_double(BencherRunner)
      head_runner = instance_double(BencherRunner)
      report = instance_double(BencherReport)
      head_samples = { "/x: Core" => { "rps" => [80.0, 99.0] } }
      base_samples = { "/x: Core" => { "rps" => [100.0, 98.0] } }
      unconfirmed = BencherReport::Alert.new(benchmark: "/x: Core", measure: "rps", limit: "lower")

      stub_runners(baseline_runner, head_runner)
      allow(TrackBenchmarks::BencherRun).to receive(:run_bencher!)
        .and_return(result_type.new(stderr: "", exit_code: 0, report: nil),
                    result_type.new(stderr: "", exit_code: 1, report:))
      allow(TrackBenchmarks::Summary).to receive(:samples_by_name)
        .with(TrackBenchmarks::Config::DISPLAY_JSON).and_return(head_samples)
      allow(TrackBenchmarks::Summary).to receive(:samples_by_name)
        .with(TrackBenchmarks::Config::BASELINE_DISPLAY_JSON).and_return(base_samples)
      allow(report).to receive_messages(unconfirmed_alert?: true, unconfirmed_alerts: [unconfirmed])
      allow(TrackBenchmarks::Summary).to receive(:rendered_report).and_return("summary")
      allow(TrackBenchmarks::Summary).to receive(:post_report_to_summary)
      allow(TrackBenchmarks::RegressionPayloads).to receive(:main_push?).and_return(false)

      # Confirmation must be applied to the report BEFORE the exit code is normalized:
      # normalization reads the post-confirmation alert state.
      expect(report).to receive(:apply_sample_confirmation!)
        .with(head_samples:, base_samples:).ordered
      expect(TrackBenchmarks::BencherRun).to receive(:normalized_exit_code).with(1, report).ordered.and_return(0)

      expect { cli.run }
        .to output(%r{::notice::Sample confirmation downgraded 1 Bencher alert\(s\).*/x: Core \(rps\)}).to_stdout
    end

    it "aborts before the head comparison when the baseline upload fails" do
      env = {
        "GITHUB_EVENT_NAME" => "push",
        "GITHUB_REF" => "refs/heads/main",
        "GITHUB_RUN_ID" => "42",
        "BENCHMARK_SUITE_NAME" => "Core"
      }
      cli = described_class.new(suite_name: "Core", report_marker: "core", env:)
      baseline_runner = instance_double(BencherRunner)
      head_runner = instance_double(BencherRunner)
      baseline_result = result_type.new(stderr: "auth failed", exit_code: 2, report: nil)

      stub_runners(baseline_runner, head_runner)
      allow(TrackBenchmarks::BencherRun).to receive(:run_bencher!)
        .with(baseline_runner, "base-42-core", ["--start-point-reset"])
        .and_return(baseline_result)

      expected_output = output(/::error::Bencher baseline upload for Core failed \(exit 2\)/).to_stderr
      expected_exit = raise_error(SystemExit) { |error| expect(error.status).to eq(2) }
      expect { cli.run }.to expected_output.and(expected_exit)

      expect(TrackBenchmarks::BencherRun).to have_received(:run_bencher!).once
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

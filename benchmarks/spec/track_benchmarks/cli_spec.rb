# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "../../lib/track_benchmarks"

RSpec.describe TrackBenchmarks::Cli do
  include BenchmarkEnvHelper

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

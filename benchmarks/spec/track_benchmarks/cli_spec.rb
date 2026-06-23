# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "../../lib/track_benchmarks"

RSpec.describe TrackBenchmarks::Cli do
  include BenchmarkEnvHelper

  describe "PR event detection" do
    it "does not require a GitHub event env var outside pull requests" do
      with_env("GITHUB_EVENT_NAME" => nil) do
        cli = described_class.new(suite_name: "Core", report_marker: "core")
        expect(PrReportPoster).not_to receive(:from_env)

        expect { cli.send(:post_pull_request_report, nil, "summary") }.not_to raise_error
      end
    end
  end
end

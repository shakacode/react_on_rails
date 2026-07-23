# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "../../lib/track_benchmarks"

RSpec.describe TrackBenchmarks::BranchArgs do
  describe ".run_plan" do
    it "targets main and a per-run baseline branch for push events" do
      plan = described_class.run_plan(
        env: {
          "GITHUB_EVENT_NAME" => "push",
          "GITHUB_RUN_ID" => "12345",
          "BENCHMARK_SUITE_NAME" => "Core"
        }
      )

      expect(plan.head_branch).to eq("main")
      expect(plan.baseline_branch).to eq("base-12345-core")
    end

    it "targets the pull request head branch and a per-run baseline branch" do
      plan = described_class.run_plan(
        env: {
          "GITHUB_EVENT_NAME" => "pull_request",
          "GITHUB_HEAD_REF" => "feature/benchmarks",
          "GITHUB_RUN_ID" => "12345",
          "BENCHMARK_SUITE_NAME" => "Pro (shard 1/2)"
        }
      )

      expect(plan.head_branch).to eq("feature/benchmarks")
      expect(plan.baseline_branch).to eq("base-12345-pro-shard-1-2")
    end

    it "targets the dispatched ref for workflow_dispatch events" do
      plan = described_class.run_plan(
        env: {
          "GITHUB_EVENT_NAME" => "workflow_dispatch",
          "GITHUB_REF_NAME" => "feature/benchmarks",
          "GITHUB_RUN_ID" => "12345",
          "BENCHMARK_SUITE_NAME" => "Core"
        }
      )

      expect(plan.head_branch).to eq("feature/benchmarks")
      expect(plan.baseline_branch).to eq("base-12345-core")
    end

    # Concurrent shards must never share a baseline branch: --start-point <branch>
    # clones the branch's CURRENT head, so a shared name could anchor one shard's
    # comparison to another shard's baseline data.
    it "gives concurrently-running shards distinct baseline branches" do
      plans = ["Pro (shard 1/2)", "Pro (shard 2/2)"].map do |suite_name|
        described_class.run_plan(
          env: {
            "GITHUB_EVENT_NAME" => "push",
            "GITHUB_RUN_ID" => "12345",
            "BENCHMARK_SUITE_NAME" => suite_name
          }
        )
      end

      expect(plans.map(&:baseline_branch).uniq.length).to eq(2)
    end

    it "fails loudly for unexpected event types" do
      expected_output = output(/Unexpected event type: schedule/).to_stderr
      expected_exit = raise_error(SystemExit) { |error| expect(error.status).to eq(1) }

      expect do
        described_class.run_plan(
          env: {
            "GITHUB_EVENT_NAME" => "schedule",
            "GITHUB_RUN_ID" => "12345",
            "BENCHMARK_SUITE_NAME" => "Core"
          }
        )
      end.to expected_output.and(expected_exit)
    end
  end

  describe ".baseline_start_point_args / .head_start_point_args" do
    it "starts the baseline as a fresh series" do
      expect(described_class.baseline_start_point_args).to eq(["--start-point-reset"])
    end

    it "anchors the head run to the just-recorded baseline branch, without cloned thresholds" do
      args = described_class.head_start_point_args("base-12345-core")

      expect(args).to eq(%w[--start-point base-12345-core --start-point-reset])
      # Relative thresholds are (re)stated per run by BencherRunner mode :relative_head,
      # so nothing may be cloned from the start point.
      expect(args).not_to include("--start-point-clone-thresholds")
    end
  end
end

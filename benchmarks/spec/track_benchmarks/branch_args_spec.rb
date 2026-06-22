# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "../../lib/track_benchmarks"

RSpec.describe TrackBenchmarks::BranchArgs do
  describe ".branch_and_start_point_args" do
    it "uses the pull request head branch and base SHA as the start point" do
      branch, start_point_args = described_class.branch_and_start_point_args(
        env: {
          "GITHUB_EVENT_NAME" => "pull_request",
          "GITHUB_HEAD_REF" => "feature/benchmarks",
          "GITHUB_BASE_REF" => "main",
          "GITHUB_BASE_SHA" => "abc123"
        }
      )

      expect(branch).to eq("feature/benchmarks")
      expect(start_point_args).to eq(
        %w[
          --start-point main
          --start-point-hash abc123
          --start-point-clone-thresholds
          --start-point-reset
        ]
      )
    end

    it "adds a workflow_dispatch merge-base hash when the GitHub API resolves one" do
      status = instance_double(Process::Status, success?: true)
      allow(GithubCli).to receive(:capture).with(
        "gh", "api", "repos/shakacode/react_on_rails/compare/main...feature/benchmarks",
        "--jq", ".merge_base_commit.sha",
        error_message: "Failed to resolve merge-base with main for feature/benchmarks"
      ).and_return(["merge-base-sha\n", status])

      branch = nil
      start_point_args = nil
      expect do
        branch, start_point_args = described_class.branch_and_start_point_args(
          env: {
            "GITHUB_EVENT_NAME" => "workflow_dispatch",
            "GITHUB_REF_NAME" => "feature/benchmarks",
            "GITHUB_REPOSITORY" => "shakacode/react_on_rails"
          }
        )
      end.to output(/Found merge-base via API: merge-base-sha/).to_stdout

      expect(branch).to eq("feature/benchmarks")
      expect(start_point_args).to eq(
        %w[
          --start-point main
          --start-point-hash merge-base-sha
          --start-point-clone-thresholds
          --start-point-reset
        ]
      )
    end

    it "falls back to the latest main baseline when workflow_dispatch merge-base lookup fails" do
      status = instance_double(Process::Status, success?: false)
      allow(GithubCli).to receive(:capture).and_return(["", status])

      branch = nil
      start_point_args = nil
      expect do
        branch, start_point_args = described_class.branch_and_start_point_args(
          env: {
            "GITHUB_EVENT_NAME" => "workflow_dispatch",
            "GITHUB_REF_NAME" => "feature/benchmarks",
            "GITHUB_REPOSITORY" => "shakacode/react_on_rails"
          }
        )
      end.to output(/Could not find merge-base with main via GitHub API/).to_stdout

      expect(branch).to eq("feature/benchmarks")
      expect(start_point_args).to eq(
        %w[--start-point main --start-point-clone-thresholds --start-point-reset]
      )
    end
  end
end

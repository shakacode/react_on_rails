# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../generate_matrix"

# These specs pin the gating/sharding/naming logic in generate_matrix.rb that
# decides which benchmark jobs run and how Bencher attributes their results. The
# script reads everything from ENV, so each example sets the env the workflow
# would pass (see .github/workflows/benchmark.yml "Set benchmark matrices") and
# asserts on the resulting matrix `include:` rows.
RSpec.describe "benchmark matrix generation" do
  include BenchmarkEnvHelper

  # Returns the matrix `include:` rows produced for the given ENV.
  def rows_for(env)
    with_env(env) { build_matrix }.fetch(:include)
  end

  def suite_ids_for(env)
    rows_for(env).map { |row| row.fetch(:suite_id) }
  end

  describe "the empty/skipped placeholder" do
    it "emits a single 'none' row when no suite is selected (fork PR)" do
      rows = rows_for(
        "BENCHMARK_EVENT_NAME" => "pull_request",
        "BENCHMARK_PULL_REQUEST_HEAD_REPO" => "contributor/react_on_rails",
        "GITHUB_REPOSITORY" => "shakacode/react_on_rails",
        "BENCHMARK_PULL_REQUEST_LABELS" => '["benchmark-pro"]'
      )

      expect(rows.size).to eq(1)
      expect(rows.first).to include(suite_id: "none", benchmark_tool: "none")
    end

    it "forces the placeholder for non-runtime-only changes regardless of other inputs" do
      expect(suite_ids_for(
               "BENCHMARK_EVENT_NAME" => "push",
               "BENCHMARK_NON_RUNTIME_ONLY" => "true"
             )).to eq(["none"])
    end
  end

  describe "event gating" do
    it "runs every suite on push (app_version 'both')" do
      expect(suite_ids_for(
               "BENCHMARK_EVENT_NAME" => "push",
               "BENCHMARK_APP_VERSION" => "both"
             )).to eq(%w[core pro pro pro-node-renderer])
    end

    it "honors a suite-specific run_output even without labels or push" do
      # RUN_PRO_BENCHMARKS gates only the Pro suite; core/node-renderer stay off.
      expect(suite_ids_for(
               "BENCHMARK_EVENT_NAME" => "pull_request",
               "BENCHMARK_PULL_REQUEST_HEAD_REPO" => "shakacode/react_on_rails",
               "GITHUB_REPOSITORY" => "shakacode/react_on_rails",
               "RUN_PRO_BENCHMARKS" => "true"
             )).to eq(%w[pro pro])
    end

    it "selects suites by label intersection on a same-repo PR" do
      # benchmark-pro is shared by Pro and Pro-Node-Renderer, but not Core.
      expect(suite_ids_for(
               "BENCHMARK_EVENT_NAME" => "pull_request",
               "BENCHMARK_PULL_REQUEST_HEAD_REPO" => "shakacode/react_on_rails",
               "GITHUB_REPOSITORY" => "shakacode/react_on_rails",
               "BENCHMARK_PULL_REQUEST_LABELS" => '["benchmark-pro"]'
             )).to eq(%w[pro pro pro-node-renderer])
    end

    it "ignores PR labels from a fork (fork-safety guard)" do
      expect(suite_ids_for(
               "BENCHMARK_EVENT_NAME" => "pull_request",
               "BENCHMARK_PULL_REQUEST_HEAD_REPO" => "contributor/react_on_rails",
               "GITHUB_REPOSITORY" => "shakacode/react_on_rails",
               "BENCHMARK_PULL_REQUEST_LABELS" => '["benchmark"]'
             )).to eq(["none"])
    end
  end

  describe "app_version input filtering" do
    it "restricts a workflow_dispatch to the node-renderer suite for pro_node_renderer_only" do
      expect(suite_ids_for(
               "BENCHMARK_EVENT_NAME" => "workflow_dispatch",
               "BENCHMARK_APP_VERSION" => "pro_node_renderer_only"
             )).to eq(%w[pro-node-renderer])
    end

    it "restricts to Core only for core_only" do
      expect(suite_ids_for(
               "BENCHMARK_EVENT_NAME" => "push",
               "BENCHMARK_APP_VERSION" => "core_only"
             )).to eq(%w[core])
    end
  end

  describe "sharding and naming" do
    it "expands the 2-shard Pro suite into per-shard rows" do
      # pro_rails_only is exclusive to the Pro suite; pro_only would also pull in
      # Pro-Node-Renderer (its app_versions include pro_only).
      rows = rows_for(
        "BENCHMARK_EVENT_NAME" => "push",
        "BENCHMARK_APP_VERSION" => "pro_rails_only"
      )

      expect(rows.map { |row| row.fetch(:shard_label) }).to eq(%w[1/2 2/2])
      expect(rows.map { |row| row.fetch(:job_name) }).to eq(
        ["Pro benchmarks (shard 1/2)", "Pro benchmarks (shard 2/2)"]
      )
      expect(rows.map { |row| row.fetch(:bencher_suite_name) }).to eq(
        ["Pro (shard 1/2)", "Pro (shard 2/2)"]
      )
      expect(rows.map { |row| row.fetch(:artifact_name_suffix) }).to eq(
        %w[-shard-1-of-2 -shard-2-of-2]
      )
      expect(rows.map { |row| row.fetch(:report_marker) }).to eq(
        ["<!-- BENCHER_REPORT_PRO_SHARD_1_OF_2 -->", "<!-- BENCHER_REPORT_PRO_SHARD_2_OF_2 -->"]
      )
    end

    it "drops the shard suffix and plural naming for a single-shard suite" do
      row = rows_for(
        "BENCHMARK_EVENT_NAME" => "push",
        "BENCHMARK_APP_VERSION" => "core_only"
      ).fetch(0)

      expect(row).to include(
        job_name: "Core benchmarks",
        bencher_suite_name: "Core",
        artifact_name_suffix: "",
        report_marker: "<!-- BENCHER_REPORT_CORE_SHARD_1_OF_1 -->"
      )
    end

    it "uses the explicit report_marker override when a suite defines one" do
      row = rows_for(
        "BENCHMARK_EVENT_NAME" => "push",
        "BENCHMARK_APP_VERSION" => "pro_node_renderer_only"
      ).fetch(0)

      expect(row.fetch(:report_marker)).to eq("<!-- BENCHER_REPORT_PRO_NODE_RENDERER -->")
    end
  end

  describe "input validation" do
    it "raises a descriptive error for malformed label JSON" do
      expect do
        rows_for(
          "BENCHMARK_EVENT_NAME" => "pull_request",
          "BENCHMARK_PULL_REQUEST_LABELS" => "not-json"
        )
      end.to raise_error(/BENCHMARK_PULL_REQUEST_LABELS must be JSON array/)
    end

    it "raises when a suite would produce a non-positive shard count" do
      with_env({}) do
        expect do
          suite_rows({ id: "fake", shard_total: 0 })
        end.to raise_error(/fake shard_total must be positive \(got 0\)/)
      end
    end
  end
end

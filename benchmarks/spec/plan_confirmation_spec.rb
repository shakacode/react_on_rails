# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../plan_confirmation"
require "stringio"
require "tmpdir"
require "fileutils"

# Pins the confirmation gate: which alerting suite/shard(s) get rerun on fresh runners,
# the IGNORED_REGRESSION_BENCHMARKS short-circuit (no rerun, no issue) that used to live
# in report_regressions.rb, and the operational-failure exits (corrupt / unmatched
# candidate) that fail the workflow without filing.
RSpec.describe "plan_confirmation" do
  include BenchmarkEnvHelper

  def candidate(suite, shard_label: "1/1", regressed: :unset)
    payload = { RegressionReport::SUITE_NAME => suite, RegressionReport::SHARD_LABEL => shard_label }
    payload[RegressionReport::REGRESSED_BENCHMARKS] = regressed unless regressed == :unset
    payload
  end

  def matrix_row(suite, shard_label: "1/1")
    {
      "suite_name" => suite,
      "shard_label" => shard_label,
      "bencher_suite_name" => shard_label == "1/1" ? suite : "#{suite} (shard #{shard_label})",
      "artifact_name_prefix" => "benchmark-#{suite.downcase}-results",
      "artifact_name_suffix" => shard_label == "1/1" ? "" : "-shard-#{shard_label.tr('/', '-of-')}"
    }
  end

  # The production list is empty (no active suppressions); stub a sample entry so these
  # examples keep pinning the ignore-list short-circuit machinery.
  let(:ignored) { "/ignored: Pro" }

  before { stub_const("RegressionReport::IGNORED_REGRESSION_BENCHMARKS", [ignored]) }

  describe ".fully_ignored?" do
    it "is true only when every named benchmark is ignored" do
      expect(fully_ignored?([ignored])).to be(true)
      expect(fully_ignored?([ignored, "/real: Pro"])).to be(false)
    end

    it "is false (fall through to confirm) when no benchmarks were named" do
      expect(fully_ignored?([])).to be(false)
      expect(fully_ignored?(nil)).to be(false)
    end
  end

  describe ".build_plan" do
    let(:matrix) { [matrix_row("Core"), matrix_row("Pro", shard_label: "1/2"), matrix_row("Pro", shard_label: "2/2")] }

    it "selects the matrix rows for candidates with at least one non-ignored benchmark" do
      payloads = [candidate("Core", regressed: ["/hello: Core"]),
                  candidate("Pro", shard_label: "1/2", regressed: ["/x: Pro"])]
      plan = build_plan(payloads, matrix)

      expect(plan[:confirm_rows].map { |row| row["bencher_suite_name"] }).to contain_exactly("Core", "Pro (shard 1/2)")
      expect(plan[:suppressed]).to be_empty
      expect(plan[:unmatched]).to be_empty
    end

    it "drops candidates whose only regressed benchmarks are ignored" do
      payloads = [candidate("Pro", shard_label: "1/2", regressed: [ignored])]
      plan = build_plan(payloads, matrix)

      expect(plan[:confirm_rows]).to be_empty
      expect(plan[:suppressed]).to eq([ignored])
    end

    it "confirms a candidate that omits the regressed list (fail-safe)" do
      plan = build_plan([candidate("Core")], matrix)
      expect(plan[:confirm_rows].map { |row| row["suite_name"] }).to eq(["Core"])
    end

    it "records candidates that match no matrix row as unmatched" do
      plan = build_plan([candidate("Ghost", regressed: ["/x: Ghost"])], matrix)
      expect(plan[:confirm_rows]).to be_empty
      expect(plan[:unmatched]).to eq([["Ghost", "1/1"]])
    end
  end

  describe "plan_confirmation (script function)" do
    def write_candidate(dir, artifact:, suite:, shard_label: "1/1", regressed: :unset, raw: nil)
      artifact_dir = File.join(dir, artifact)
      FileUtils.mkdir_p(artifact_dir)
      path = File.join(artifact_dir, RegressionReport::CANDIDATE_FILENAME)
      File.write(path, raw || JSON.generate(candidate(suite, shard_label:, regressed:)))
    end

    def capture_stdout
      original = $stdout
      $stdout = StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = original
    end

    def parse_outputs(path)
      File.readlines(path, chomp: true).reject(&:empty?).to_h { |line| line.split("=", 2) }
    end

    # Runs the script function with a matrix and a GITHUB_OUTPUT file, returning
    # [result_boolean, parsed_outputs_hash, captured_stdout].
    def run_plan(dir, matrix_rows)
      output_file = File.join(dir, "github-output")
      File.write(output_file, "")
      result = nil
      stdout = nil
      with_env(
        "BENCHMARK_MATRIX" => JSON.generate(include: matrix_rows),
        "GITHUB_OUTPUT" => output_file,
        "GITHUB_SERVER_URL" => "https://github.com",
        "GITHUB_REPOSITORY" => "shakacode/react_on_rails",
        "GITHUB_RUN_ID" => "999"
      ) do
        stdout = capture_stdout { result = plan_confirmation(dir) }
      end
      [result, parse_outputs(output_file), stdout]
    end

    let(:default_matrix) do
      [matrix_row("Core"), matrix_row("Pro", shard_label: "1/2"), matrix_row("Pro", shard_label: "2/2")]
    end

    it "emits no confirmations when there are no candidates" do
      Dir.mktmpdir do |dir|
        result, outputs, stdout = run_plan(dir, default_matrix)
        expect(result).to be(true)
        expect(outputs["has_confirmations"]).to eq("false")
        expect(JSON.parse(outputs["confirmation_matrix"]).fetch("include")).to be_empty
        expect(stdout).to match(/No benchmark regression candidates/)
      end
    end

    it "schedules a confirmation rerun for an alerting suite" do
      Dir.mktmpdir do |dir|
        write_candidate(dir, artifact: "regression-candidate-core", suite: "Core", regressed: ["/hello: Core"])
        result, outputs, _stdout = run_plan(dir, default_matrix)

        expect(result).to be(true)
        expect(outputs["has_confirmations"]).to eq("true")
        include_rows = JSON.parse(outputs["confirmation_matrix"]).fetch("include")
        expect(include_rows.map { |row| row["suite_name"] }).to eq(["Core"])
      end
    end

    it "short-circuits a fully-ignored candidate with a notice and no rerun" do
      Dir.mktmpdir do |dir|
        write_candidate(dir, artifact: "regression-candidate-pro", suite: "Pro", shard_label: "1/2",
                             regressed: [ignored])
        result, outputs, stdout = run_plan(dir, default_matrix)

        expect(result).to be(true)
        expect(outputs["has_confirmations"]).to eq("false")
        expect(stdout).to match(/Skipped confirmation for temporarily-ignored/)
        expect(stdout).to include(ignored)
      end
    end

    it "confirms the non-ignored suite while skipping a fully-ignored one" do
      Dir.mktmpdir do |dir|
        write_candidate(dir, artifact: "regression-candidate-pro", suite: "Pro", shard_label: "1/2",
                             regressed: [ignored])
        write_candidate(dir, artifact: "regression-candidate-core", suite: "Core", regressed: ["/hello: Core"])
        result, outputs, stdout = run_plan(dir, default_matrix)

        expect(result).to be(true)
        expect(outputs["has_confirmations"]).to eq("true")
        include_rows = JSON.parse(outputs["confirmation_matrix"]).fetch("include")
        expect(include_rows.map { |row| row["suite_name"] }).to eq(["Core"])
        expect(stdout).to match(/Skipped confirmation for temporarily-ignored/)
      end
    end

    it "fails (no confirmations) when a candidate is corrupt" do
      Dir.mktmpdir do |dir|
        write_candidate(dir, artifact: "regression-candidate-core", suite: "Core", raw: "{ not valid json")
        result, outputs, _stdout = run_plan(dir, default_matrix)

        expect(result).to be(false)
        expect(outputs["has_confirmations"]).to eq("false")
      end
    end

    it "fails (no confirmations) when a candidate has the wrong JSON shape" do
      Dir.mktmpdir do |dir|
        malformed_payload = JSON.generate(%w[not a hash])
        write_candidate(dir, artifact: "regression-candidate-core", suite: "Core", raw: malformed_payload)
        result, outputs, _stdout = run_plan(dir, default_matrix)

        expect(result).to be(false)
        expect(outputs["has_confirmations"]).to eq("false")
      end
    end

    it "fails when a candidate matches no benchmark matrix row" do
      Dir.mktmpdir do |dir|
        write_candidate(dir, artifact: "regression-candidate-ghost", suite: "Ghost", regressed: ["/x: Ghost"])
        result, outputs, _stdout = run_plan(dir, default_matrix)

        expect(result).to be(false)
        expect(outputs["has_confirmations"]).to eq("false")
      end
    end
  end
end

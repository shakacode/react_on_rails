# frozen_string_literal: true

require "optparse"

require_relative "spec_helper"
require_relative "../lib/bencher_runner"

RSpec.describe BencherRunner do
  subject(:runner) { described_class.new(benchmark_json: "bench.json", report_json: "report.json") }

  def runner_for(mode)
    described_class.new(benchmark_json: "bench.json", report_json: "report.json", mode:)
  end

  def capture_run_command(branch: "my-branch", start_point_args: [], runner: self.runner)
    status = instance_double(Process::Status, exitstatus: 0)
    report_json = JSON.generate("results" => [], "alerts" => [])
    captured_args = nil

    allow(Open3).to receive(:capture3) do |*args|
      captured_args = args
      [report_json, "", status]
    end
    allow(File).to receive(:write).with("report.json.tmp", report_json)
    allow(FileUtils).to receive(:mv).with("report.json.tmp", "report.json")
    allow(FileUtils).to receive(:rm_f).with("report.json.tmp")

    runner.run(branch:, start_point_args:)
    captured_args
  end

  describe "Bencher CLI arguments" do
    it "builds a JSON Bencher run command with the configured files and start point" do
      args = capture_run_command(branch: "feature-branch", start_point_args: ["--start-point", "main"])

      expect(args).to include("bencher", "run", "--branch", "feature-branch")
      expect(args.each_cons(2)).to include(["--file", "bench.json"])
      expect(args.each_cons(2)).to include(["--format", "json"])
      expect(args).to include("--start-point", "main")
    end

    it "reports to the github-actions testbed by default" do
      # Force the default path so the example is independent of any BENCHER_TESTBED exported in
      # the developer/CI shell (which the runner intentionally honors).
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("BENCHER_TESTBED", "github-actions").and_return("github-actions")

      args = capture_run_command

      expect(args.each_cons(2)).to include(["--testbed", "github-actions"])
    end

    it "reports to BENCHER_TESTBED when set (local benchmark runner override)" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("BENCHER_TESTBED", "github-actions").and_return("m1-bench")

      args = capture_run_command

      expect(args.each_cons(2)).to include(["--testbed", "m1-bench"])
      expect(args.each_cons(2)).not_to include(["--testbed", "github-actions"])
    end

    # Parse only the threshold tail: OptionParser raises InvalidOption on any flag it
    # doesn't declare, and the leading `bencher run` flags aren't declared here, so
    # drop everything before the first --threshold-measure.
    def parse_thresholds(argv)
      thresholds = []
      OptionParser.new do |opts|
        opts.on("--threshold-measure=MEASURE") { |measure| thresholds << { measure: } }
        opts.on("--threshold-lower-boundary=BOUNDARY") { |boundary| thresholds.last[:lower] = boundary }
        opts.on("--threshold-upper-boundary=BOUNDARY") { |boundary| thresholds.last[:upper] = boundary }
        opts.on("--threshold-test=TEST")
        opts.on("--threshold-max-sample-size=SIZE")
      end.parse(argv.drop_while { |arg| arg != "--threshold-measure" })
      thresholds
    end

    it "tracks exactly rps/p50_latency/failed_pct with their tuned boundaries and sides" do
      expect(parse_thresholds(capture_run_command)).to eq(
        [
          { measure: "rps", lower: "0.9995", upper: "_" },
          { measure: "p50_latency", lower: "_", upper: "0.9999" },
          { measure: "failed_pct", lower: "_", upper: "0.95" }
        ]
      )
    end

    it "uses the t-test with the tuned maximum sample size by default (statistical trend mode)" do
      args = capture_run_command

      expect(args.each_cons(2)).to include(["--threshold-test", "t_test"])
      expect(args.each_cons(2)).to include(["--threshold-max-sample-size", "64"])
      expect(args).to include("--err")
    end

    it "omits thresholds and --err for a relative baseline run (it must never gate the job)" do
      args = capture_run_command(runner: runner_for(:relative_baseline), start_point_args: ["--start-point-reset"])

      expect(args).not_to include("--err")
      expect(args).not_to include("--threshold-measure")
      expect(args).not_to include("--thresholds-reset")
      expect(args).to include("--start-point-reset")
    end

    it "compares a relative head run with percentage thresholds and resets stale threshold models" do
      args = capture_run_command(runner: runner_for(:relative_head))

      expect(args).to include("--err", "--thresholds-reset")
      expect(args.each_cons(2)).to include(["--threshold-test", "percentage"])
      expect(args.each_cons(2)).not_to include(["--threshold-test", "t_test"])
      # A percentage boundary is computed from the baseline directly; the sample-size
      # cap only applies to the t-test's history window.
      expect(args).not_to include("--threshold-max-sample-size")
      expect(parse_thresholds(args)).to eq(
        [
          { measure: "rps", lower: "0.25", upper: "_" },
          { measure: "p50_latency", lower: "_", upper: "0.25" },
          { measure: "failed_pct", lower: "_", upper: "0.25" }
        ]
      )
    end

    it "rejects unknown modes at construction time" do
      expect { described_class.new(benchmark_json: "b.json", report_json: "r.json", mode: :nope) }
        .to raise_error(ArgumentError, /unknown mode :nope/)
    end
  end

  describe "#run" do
    it "persists and parses the Bencher JSON report" do
      status = instance_double(Process::Status, exitstatus: 0)
      report_json = JSON.generate("results" => [], "alerts" => [])

      allow(Open3).to receive(:capture3).and_return([report_json, "", status])
      allow(File).to receive(:write).with("report.json.tmp", report_json)
      allow(FileUtils).to receive(:mv).with("report.json.tmp", "report.json")
      allow(FileUtils).to receive(:rm_f)

      result = runner.run(branch: "branch", start_point_args: [])

      expect(result.stderr).to eq("")
      expect(result.exit_code).to eq(0)
      expect(result.report).to be_a(BencherReport)
    end

    it "removes a stale report and returns nil when Bencher emits no JSON" do
      status = instance_double(Process::Status, exitstatus: 2)

      allow(Open3).to receive(:capture3).and_return(["", "auth failed", status])
      allow(FileUtils).to receive(:rm_f).with("report.json")

      result = nil
      expect { result = runner.run(branch: "branch", start_point_args: []) }
        .to output("auth failed\n").to_stderr

      expect(result.stderr).to eq("auth failed")
      expect(result.exit_code).to eq(2)
      expect(result.report).to be_nil
      expect(FileUtils).to have_received(:rm_f).with("report.json")
    end

    it "emits successful Bencher stderr so CI logs preserve Bencher warnings" do
      status = instance_double(Process::Status, exitstatus: 0)
      report_json = JSON.generate("results" => [], "alerts" => [])

      allow(Open3).to receive(:capture3).and_return([report_json, "informational stderr", status])
      allow(File).to receive(:write).with("report.json.tmp", report_json)
      allow(FileUtils).to receive(:mv).with("report.json.tmp", "report.json")
      allow(FileUtils).to receive(:rm_f)

      result = nil
      expect { result = runner.run(branch: "branch", start_point_args: []) }
        .to output("informational stderr\n").to_stderr
        .and output("").to_stdout

      expect(result.stderr).to eq("informational stderr")
      expect(result.exit_code).to eq(0)
      expect(result.report).to be_a(BencherReport)
    end

    it "raises a persistence error when stale report cleanup fails" do
      status = instance_double(Process::Status, exitstatus: 2)

      allow(Open3).to receive(:capture3).and_return(["", "auth failed", status])
      allow(FileUtils).to receive(:rm_f).with("report.json").and_raise(Errno::EACCES, "report.json")

      expect { runner.run(branch: "branch", start_point_args: []) }
        .to output("auth failed\n").to_stderr
        .and raise_error(
          BencherRunner::PersistenceError,
          /Bencher produced no output; see stderr above/
        )
    end

    it "emits the perf-link context warning to stdout so GitHub Actions annotates it" do
      status = instance_double(Process::Status, exitstatus: 0)
      report_json = JSON.generate(
        "results" => [[{
          "benchmark" => { "name" => "/foo", "uuid" => "bench-uuid" },
          "measures" => [{
            "measure" => { "slug" => "rps", "name" => "rps", "uuid" => "rps-uuid" },
            "metric" => { "value" => 1.0 }
          }]
        }]],
        "alerts" => []
      )

      allow(Open3).to receive(:capture3).and_return([report_json, "", status])
      allow(File).to receive(:write).with("report.json.tmp", report_json)
      allow(FileUtils).to receive(:mv).with("report.json.tmp", "report.json")
      allow(FileUtils).to receive(:rm_f)

      expect { runner.run(branch: "branch", start_point_args: []) }
        .to output(/::warning::Bencher report listed benchmarks but no perf-link context/).to_stdout
    end

    it "returns exit_code=1 and a non-regression filtered_alert? report as a retry precondition" do
      status = instance_double(Process::Status, exitstatus: 1)
      report_json = JSON.generate(
        "results" => [[{
          "benchmark" => { "name" => "/x" },
          "measures" => [{
            "measure" => { "slug" => "rps", "name" => "rps" },
            "metric" => { "value" => 95.0 },
            "boundary" => { "baseline" => 100.0, "lower_limit" => 90.0, "upper_limit" => nil }
          }]
        }]],
        "alerts" => [{
          "benchmark" => { "name" => "/x" },
          "threshold" => { "measure" => { "slug" => "rps" } },
          "metric" => { "value" => 1.0 },
          "limit" => "lower",
          "status" => "active"
        }]
      )

      allow(Open3).to receive(:capture3).and_return([report_json, "", status])
      allow(File).to receive(:write).with("report.json.tmp", report_json)
      allow(FileUtils).to receive(:mv).with("report.json.tmp", "report.json")
      allow(FileUtils).to receive(:rm_f)

      result = runner.run(branch: "branch", start_point_args: [])

      expect(result.exit_code).to eq(1)
      expect(result.report).not_to be_regression
      expect(result.report.filtered_alert?).to be(true)
    end

    it "raises a testable error when Bencher emits malformed JSON" do
      status = instance_double(Process::Status, exitstatus: 0)

      allow(Open3).to receive(:capture3).and_return(["{}", "", status])
      allow(File).to receive(:write).with("report.json.tmp", "{}")
      allow(FileUtils).to receive(:mv).with("report.json.tmp", "report.json")
      allow(FileUtils).to receive(:rm_f)

      expect do
        expect { runner.run(branch: "branch", start_point_args: []) }
          .to raise_error(BencherRunner::ReportParseError, /Bencher JSON report has an unexpected shape/)
      end.to output(/::debug::Malformed Bencher output/).to_stdout
      expect(FileUtils).to have_received(:rm_f).with("report.json")
    end

    it "preserves the parse error when malformed report cleanup fails" do
      status = instance_double(Process::Status, exitstatus: 0)

      allow(Open3).to receive(:capture3).and_return(["{}", "", status])
      allow(File).to receive(:write).with("report.json.tmp", "{}")
      allow(FileUtils).to receive(:mv).with("report.json.tmp", "report.json")
      allow(FileUtils).to receive(:rm_f).with("report.json.tmp")
      allow(FileUtils).to receive(:rm_f).with("report.json").and_raise(Errno::EACCES, "report.json")

      expect do
        expect { runner.run(branch: "branch", start_point_args: []) }
          .to raise_error(BencherRunner::ReportParseError, /Bencher JSON report has an unexpected shape/)
      end.to(
        output(/::debug::Malformed Bencher output.*::warning::Could not remove malformed Bencher report/m).to_stdout
      )
    end

    it "raises a testable error when Bencher emits non-JSON stdout" do
      status = instance_double(Process::Status, exitstatus: 0)

      allow(Open3).to receive(:capture3).and_return(["not json", "", status])
      allow(File).to receive(:write).with("report.json.tmp", "not json")
      allow(FileUtils).to receive(:mv).with("report.json.tmp", "report.json")
      allow(FileUtils).to receive(:rm_f)

      expect do
        expect { runner.run(branch: "branch", start_point_args: []) }
          .to raise_error(BencherRunner::ReportParseError, /Bencher JSON report has an unexpected shape/)
      end.to output(/::debug::Malformed Bencher output/).to_stdout
      expect(FileUtils).to have_received(:rm_f).with("report.json")
    end

    it "removes the temporary report but keeps the previous report when writing fails" do
      status = instance_double(Process::Status, exitstatus: 0)

      allow(Open3).to receive(:capture3).and_return([JSON.generate("results" => [], "alerts" => []), "", status])
      allow(File).to receive(:write).with("report.json.tmp", anything).and_raise(Errno::ENOSPC)
      allow(FileUtils).to receive(:rm_f)

      expect { runner.run(branch: "branch", start_point_args: []) }.to raise_error(BencherRunner::PersistenceError)
      expect(FileUtils).to have_received(:rm_f).with("report.json.tmp")
      expect(FileUtils).not_to have_received(:rm_f).with("report.json")
    end

    it "propagates unexpected write errors while cleaning up the temporary report" do
      status = instance_double(Process::Status, exitstatus: 0)

      allow(Open3).to receive(:capture3).and_return([JSON.generate("results" => [], "alerts" => []), "", status])
      allow(File).to receive(:write).with("report.json.tmp", anything).and_raise(RuntimeError, "disk layer failed")
      allow(FileUtils).to receive(:rm_f)

      expect { runner.run(branch: "branch", start_point_args: []) }.to raise_error(RuntimeError, "disk layer failed")
      expect(FileUtils).to have_received(:rm_f).with("report.json.tmp")
      expect(FileUtils).not_to have_received(:rm_f).with("report.json")
    end

    it "preserves the original persistence failure when temporary cleanup also fails" do
      status = instance_double(Process::Status, exitstatus: 0)

      allow(Open3).to receive(:capture3).and_return([JSON.generate("results" => [], "alerts" => []), "", status])
      allow(File).to receive(:write).with("report.json.tmp", anything).and_raise(Errno::ENOSPC, "report.json.tmp")
      allow(FileUtils).to receive(:rm_f).with("report.json.tmp").and_raise(Errno::EACCES, "report.json.tmp")

      expect do
        runner.run(branch: "branch", start_point_args: [])
      end.to(
        output(/::warning::Could not remove temporary Bencher report report\.json\.tmp/).to_stdout
          .and(raise_error(BencherRunner::PersistenceError))
      )
      expect(FileUtils).not_to have_received(:rm_f).with("report.json")
    end

    it "removes the temporary report but keeps the previous report when moving is interrupted" do
      status = instance_double(Process::Status, exitstatus: 0)

      allow(Open3).to receive(:capture3).and_return([JSON.generate("results" => [], "alerts" => []), "", status])
      allow(File).to receive(:write).with("report.json.tmp", anything)
      allow(FileUtils).to receive(:mv).with("report.json.tmp", "report.json").and_raise(Interrupt)
      allow(FileUtils).to receive(:rm_f)

      expect { runner.run(branch: "branch", start_point_args: []) }.to raise_error(Interrupt)
      expect(FileUtils).to have_received(:rm_f).with("report.json.tmp")
      expect(FileUtils).not_to have_received(:rm_f).with("report.json")
    end
  end
end

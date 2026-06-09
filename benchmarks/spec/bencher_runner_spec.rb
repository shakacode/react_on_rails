# frozen_string_literal: true

require "optparse"

require_relative "spec_helper"
require_relative "../lib/bencher_runner"

RSpec.describe BencherRunner do
  subject(:runner) { described_class.new(benchmark_json: "bench.json", report_json: "report.json") }

  def capture_run_command(branch: "my-branch", start_point_args: [])
    status = instance_double(Process::Status, exitstatus: 0)
    report_json = JSON.generate("results" => [], "alerts" => [])
    captured_args = nil

    allow(Open3).to receive(:capture3) do |*args|
      captured_args = args
      [report_json, "", status]
    end
    allow(File).to receive(:write).with("report.json.tmp", report_json)
    allow(FileUtils).to receive(:mv).with("report.json.tmp", "report.json")
    allow(FileUtils).to receive(:rm_f)

    runner.run(branch, start_point_args)
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
  end

  describe "#run" do
    it "persists and parses the Bencher JSON report" do
      status = instance_double(Process::Status, exitstatus: 0)
      report_json = JSON.generate("results" => [], "alerts" => [])

      allow(Open3).to receive(:capture3).and_return([report_json, "", status])
      allow(File).to receive(:write).with("report.json.tmp", report_json)
      allow(FileUtils).to receive(:mv).with("report.json.tmp", "report.json")
      allow(FileUtils).to receive(:rm_f)

      result = runner.run("branch", [])

      expect(result.stderr).to eq("")
      expect(result.exit_code).to eq(0)
      expect(result.report).to be_a(BencherReport)
    end

    it "removes a stale report and returns nil when Bencher emits no JSON" do
      status = instance_double(Process::Status, exitstatus: 2)

      allow(Open3).to receive(:capture3).and_return(["", "auth failed", status])
      allow(FileUtils).to receive(:rm_f).with("report.json")

      result = nil
      expect { result = runner.run("branch", []) }
        .to output("auth failed\n").to_stderr

      expect(result.stderr).to eq("auth failed")
      expect(result.exit_code).to eq(2)
      expect(result.report).to be_nil
      expect(FileUtils).to have_received(:rm_f).with("report.json")
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

      expect { runner.run("branch", []) }
        .to output(/::warning::Bencher report listed benchmarks but no perf-link context/).to_stdout
    end

    it "preserves stale active alerts as filtered so retry handling can run first" do
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

      result = runner.run("branch", [])

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

      expect { runner.run("branch", []) }
        .to raise_error(BencherRunner::ReportParseError, /Bencher JSON report has an unexpected shape/)
      expect(FileUtils).to have_received(:rm_f).with("report.json")
    end

    it "removes stale and temporary reports when writing the report fails" do
      status = instance_double(Process::Status, exitstatus: 0)

      allow(Open3).to receive(:capture3).and_return([JSON.generate("results" => [], "alerts" => []), "", status])
      allow(File).to receive(:write).with("report.json.tmp", anything).and_raise(Errno::ENOSPC)
      allow(FileUtils).to receive(:rm_f)

      expect { runner.run("branch", []) }.to raise_error(Errno::ENOSPC)
      expect(FileUtils).to have_received(:rm_f).with("report.json.tmp")
      expect(FileUtils).to have_received(:rm_f).with("report.json")
    end

    it "removes stale and temporary reports when writing raises a non-system error" do
      status = instance_double(Process::Status, exitstatus: 0)

      allow(Open3).to receive(:capture3).and_return([JSON.generate("results" => [], "alerts" => []), "", status])
      allow(File).to receive(:write).with("report.json.tmp", anything).and_raise(RuntimeError, "disk layer failed")
      allow(FileUtils).to receive(:rm_f)

      expect { runner.run("branch", []) }.to raise_error(RuntimeError, "disk layer failed")
      expect(FileUtils).to have_received(:rm_f).with("report.json.tmp")
      expect(FileUtils).to have_received(:rm_f).with("report.json")
    end

    it "removes the temporary and final reports when moving the report is interrupted" do
      status = instance_double(Process::Status, exitstatus: 0)

      allow(Open3).to receive(:capture3).and_return([JSON.generate("results" => [], "alerts" => []), "", status])
      allow(File).to receive(:write).with("report.json.tmp", anything)
      allow(FileUtils).to receive(:mv).with("report.json.tmp", "report.json").and_raise(Interrupt)
      allow(FileUtils).to receive(:rm_f)

      expect { runner.run("branch", []) }.to raise_error(Interrupt)
      expect(FileUtils).to have_received(:rm_f).with("report.json.tmp")
      expect(FileUtils).to have_received(:rm_f).with("report.json")
    end
  end
end

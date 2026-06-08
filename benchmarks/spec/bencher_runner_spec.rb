# frozen_string_literal: true

require "optparse"

require_relative "spec_helper"
require_relative "../lib/bencher_runner"

RSpec.describe BencherRunner do
  subject(:runner) { described_class.new(benchmark_json: "bench.json", report_json: "report.json") }

  describe "#threshold_args" do
    it "puts the boundary on the lower side for higher-is-better measures" do
      expect(runner.threshold_args("rps", :lower, "0.9995")).to eq(
        %w[--threshold-measure rps --threshold-test t_test
           --threshold-max-sample-size 64
           --threshold-lower-boundary 0.9995 --threshold-upper-boundary _]
      )
    end

    it "puts the boundary on the upper side for lower-is-better measures" do
      expect(runner.threshold_args("p50_latency", :upper, "0.9999")).to eq(
        %w[--threshold-measure p50_latency --threshold-test t_test
           --threshold-max-sample-size 64
           --threshold-lower-boundary _ --threshold-upper-boundary 0.9999]
      )
    end
  end

  describe "#args" do
    it "builds a JSON Bencher run command with the configured files and start point" do
      args = runner.args("feature-branch", ["--start-point", "main"])

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
      expect(parse_thresholds(runner.args("my-branch", []))).to eq(
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
      allow(File).to receive(:write).with("report.json", report_json)

      stderr, exit_code, report = runner.run("branch", [])

      expect(stderr).to eq("")
      expect(exit_code).to eq(0)
      expect(report).to be_a(BencherReport)
    end

    it "removes a stale report and returns nil when Bencher emits no JSON" do
      status = instance_double(Process::Status, exitstatus: 2)

      allow(Open3).to receive(:capture3).and_return(["", "auth failed", status])
      allow(FileUtils).to receive(:rm_f).with("report.json")

      stderr, exit_code, report = nil
      expect { stderr, exit_code, report = runner.run("branch", []) }
        .to output("auth failed\n").to_stderr

      expect(stderr).to eq("auth failed")
      expect(exit_code).to eq(2)
      expect(report).to be_nil
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
      allow(File).to receive(:write).with("report.json", report_json)

      expect { runner.run("branch", []) }
        .to output(/::warning::Bencher report listed benchmarks but no perf-link context/).to_stdout
    end

    it "raises a testable error when Bencher emits malformed JSON" do
      status = instance_double(Process::Status, exitstatus: 0)

      allow(Open3).to receive(:capture3).and_return(["{}", "", status])
      allow(File).to receive(:write).with("report.json", "{}")

      expect { runner.run("branch", []) }
        .to raise_error(BencherRunner::ReportParseError, /Bencher JSON report has an unexpected shape/)
    end
  end
end

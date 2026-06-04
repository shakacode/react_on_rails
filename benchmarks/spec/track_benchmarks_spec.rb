# frozen_string_literal: true

require "optparse"
require_relative "spec_helper"
require_relative "../track_benchmarks"
require_relative "../lib/bmf_helpers"

# track_benchmarks.rb runs its tracking flow only under `if __FILE__ == $PROGRAM_NAME`,
# so requiring it just loads the helpers. These pin the classification that decides
# whether a Bencher run is a real regression vs a missing-baseline retry — now read
# from the JSON report's alerts[] rather than by grepping stderr. The two are
# mutually exclusive by design: an alert must never trigger a start-point-hash retry,
# or a real regression would be silently re-measured against the wrong baseline.
RSpec.describe "track_benchmarks" do
  def report_with_alert
    BencherReport.parse(
      JSON.generate(
        "results" => [],
        "alerts" => [{
          "benchmark" => { "name" => "/x" },
          "threshold" => { "measure" => { "slug" => "rps" } },
          "metric" => { "value" => 1.0 },
          "limit" => "lower",
          "status" => "active"
        }]
      )
    )
  end

  def report_without_alert
    BencherReport.parse(JSON.generate("results" => [], "alerts" => []))
  end

  describe "#regression?" do
    it "is true when the report has an active alert" do
      expect(regression?(report_with_alert)).to be(true)
    end

    it "is false when the report has no active alert" do
      expect(regression?(report_without_alert)).to be(false)
    end

    it "is false when there is no report (operational failure, no stdout to parse)" do
      expect(regression?(nil)).to be(false)
    end
  end

  describe "#retry_without_start_point_hash?" do
    it "is true when the start-point head version is missing and there is no regression" do
      expect(retry_without_start_point_hash?("Head Version abc123 not found", 1, report_without_alert)).to be(true)
    end

    it "is true when the head version is missing and no report was produced" do
      expect(retry_without_start_point_hash?("Head Version abc123 not found", 1, nil)).to be(true)
    end

    it "is false when the report has an active alert (must not retry a real regression)" do
      report = report_with_alert
      expect(retry_without_start_point_hash?("Head Version abc123 not found", 1, report)).to be(false)
      expect(regression?(report)).to be(true)
    end

    it "is false on success and for unrelated non-zero failures" do
      expect(retry_without_start_point_hash?("Head Version abc123 not found", 0, report_without_alert)).to be(false)
      expect(retry_without_start_point_hash?("some other error", 1, report_without_alert)).to be(false)
    end
  end

  # On a main regression the rendered table feeds the report-regressions hand-off. If
  # the display sidecar was missing/corrupt the table is empty, and an empty-bodied
  # issue is useless — the hand-off must substitute a run-URL pointer instead.
  describe "#regression_handoff_summary" do
    it "returns the rendered table unchanged when it is non-empty" do
      expect(regression_handoff_summary("### Summary\n| a |")).to eq("### Summary\n| a |")
    end

    it "substitutes a run-URL pointer when the table is empty" do
      allow(Github).to receive(:run_url).and_return("https://github.test/run/1")
      summary = regression_handoff_summary("")
      expect(summary).not_to be_empty
      expect(summary).to include("https://github.test/run/1")
    end
  end

  # The boundary/side mapping is a silent safety control: a flipped side or wrong
  # value would stop regressions from alerting while CI stays green, so pin it.
  describe "#threshold_args" do
    it "puts the boundary on the lower side for higher-is-better measures" do
      expect(threshold_args("rps", :lower, "0.9995")).to eq(
        %w[--threshold-measure rps --threshold-test t_test
           --threshold-max-sample-size 64
           --threshold-lower-boundary 0.9995 --threshold-upper-boundary _]
      )
    end

    it "puts the boundary on the upper side for lower-is-better measures" do
      expect(threshold_args("p50_latency", :upper, "0.9999")).to eq(
        %w[--threshold-measure p50_latency --threshold-test t_test
           --threshold-max-sample-size 64
           --threshold-lower-boundary _ --threshold-upper-boundary 0.9999]
      )
    end
  end

  describe "#bencher_args" do
    it "requests the JSON report format (so the report can be parsed, not grepped)" do
      args = bencher_args("my-branch", [])
      expect(args.each_cons(2)).to include(%w[--format json])
      expect(args).not_to include("html")
    end

    # Parse only the threshold tail: OptionParser raises InvalidOption on any flag it
    # doesn't declare, and the leading `bencher run` flags aren't declared here, so
    # drop everything before the first --threshold-measure.
    def parse_thresholds(argv)
      thresholds = []
      OptionParser.new do |opts|
        opts.on("--threshold-measure=MEASURE") { |measure| thresholds << { measure: measure } }
        opts.on("--threshold-lower-boundary=BOUNDARY") { |boundary| thresholds.last[:lower] = boundary }
        opts.on("--threshold-upper-boundary=BOUNDARY") { |boundary| thresholds.last[:upper] = boundary }
        opts.on("--threshold-test=TEST")
        opts.on("--threshold-max-sample-size=SIZE")
      end.parse(argv.drop_while { |arg| arg != "--threshold-measure" })
      thresholds
    end

    it "tracks exactly rps/p50_latency/failed_pct with their tuned boundaries and sides" do
      expect(parse_thresholds(bencher_args("my-branch", []))).to eq(
        [
          { measure: "rps", lower: "0.9995", upper: "_" },
          { measure: "p50_latency", lower: "_", upper: "0.9999" },
          { measure: "failed_pct", lower: "_", upper: "0.95" }
        ]
      )
    end
  end

  # A threshold on a measure that no metric reports is a silent no-op, so the tracked
  # measures must match exactly what BmfCollector emits.
  describe "tracked measures" do
    it "match exactly the measures BmfCollector emits" do
      collector = BmfCollector.new
      collector.add(name: "x", rps: 1.0, p50: 1.0, status: "200=1")

      expect(collector.to_bmf.fetch("x").keys).to match_array(THRESHOLDS.map(&:first))
    end
  end

  # The summary table's highlightable columns must stay in lockstep with the tracked
  # measures/sides Bencher is configured with, or a column would either be silently
  # un-highlightable or highlighted with the wrong direction.
  describe "summary table highlight columns" do
    it "use measures and directions that exist in THRESHOLDS" do
      thresholds = THRESHOLDS.to_h { |measure, direction, _boundary| [measure, direction] }

      BenchmarkTable::COLUMNS.select { |col| col[:measure] }.each do |col|
        expect(thresholds).to include(col[:measure])
        expect(col[:direction]).to eq(thresholds[col[:measure]])
      end
    end
  end
end

# frozen_string_literal: true

require "optparse"
require_relative "spec_helper"
require_relative "../track_benchmarks"
require_relative "../lib/bmf_helpers"

# track_benchmarks.rb runs its tracking flow only under `if __FILE__ == $PROGRAM_NAME`,
# so requiring it just loads the helpers. These pin the stderr/exit-code
# classification that decides whether a Bencher run is a real regression (alert) vs
# a missing-baseline retry — the two are mutually exclusive by design: an alert must
# never trigger a start-point-hash retry, or a real regression would be silently
# re-measured against the wrong baseline.
RSpec.describe "track_benchmarks" do
  describe "#alert?" do
    it "is true for a non-zero exit whose stderr names an alert/violation" do
      [
        "Alert: rps boundary violation",
        "Threshold violation detected",
        "found a boundary violation on p90_latency"
      ].each do |stderr|
        expect(alert?(stderr, 1)).to be(true), "expected alert for: #{stderr}"
      end
    end

    it "is false on success even if the text mentions an alert" do
      expect(alert?("Alert: rps boundary violation", 0)).to be(false)
    end

    it "is false for a non-zero exit with no alert phrase (operational failure)" do
      expect(alert?("error: failed to authenticate with the API", 1)).to be(false)
    end
  end

  describe "#retry_without_start_point_hash?" do
    it "is true when the start-point head version is missing and there is no alert" do
      expect(retry_without_start_point_hash?("Head Version abc123 not found", 1)).to be(true)
    end

    it "is false when an alert is also present (must not retry a real regression)" do
      stderr = "Head Version abc123 not found\nAlert: rps boundary violation"
      expect(retry_without_start_point_hash?(stderr, 1)).to be(false)
      expect(alert?(stderr, 1)).to be(true)
    end

    it "is false on success and for unrelated non-zero failures" do
      expect(retry_without_start_point_hash?("Head Version abc123 not found", 0)).to be(false)
      expect(retry_without_start_point_hash?("some other error", 1)).to be(false)
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
end

# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../lib/regression_report"

# Pins the shared hand-off contract: how candidate alerts are matched against a
# confirmation run's alerts (the "same benchmark+measure re-alerted" rule, with the
# name-only fallback when a measure is absent) and the ignore-list filtering that
# short-circuits temporarily-suppressed benchmarks before a rerun.
RSpec.describe RegressionReport do
  def alert(benchmark, measure)
    described_class.alert(benchmark, measure)
  end

  describe ".normalize_measure" do
    it "folds dashes, spaces, and case so slug and name forms compare equal" do
      expect(described_class.normalize_measure("p50-latency")).to eq("p50_latency")
      expect(described_class.normalize_measure("P50 Latency")).to eq("p50_latency")
      expect(described_class.normalize_measure(nil)).to be_nil
    end
  end

  describe ".alerts_match?" do
    it "matches the same benchmark and measure" do
      expect(described_class.alerts_match?(alert("/x", "rps"), alert("/x", "rps"))).to be(true)
    end

    it "treats slug and name spellings of a measure as equal" do
      expect(described_class.alerts_match?(alert("/x", "p50-latency"), alert("/x", "p50_latency"))).to be(true)
    end

    it "does not match a different benchmark" do
      expect(described_class.alerts_match?(alert("/x", "rps"), alert("/y", "rps"))).to be(false)
    end

    it "does not match the same benchmark on a different measure" do
      expect(described_class.alerts_match?(alert("/x", "rps"), alert("/x", "p50_latency"))).to be(false)
    end

    it "falls back to benchmark-name-only when either measure is absent" do
      expect(described_class.alerts_match?(alert("/x", nil), alert("/x", "rps"))).to be(true)
      expect(described_class.alerts_match?(alert("/x", "rps"), alert("/x", nil))).to be(true)
      expect(described_class.alerts_match?(alert("/x", nil), alert("/y", "rps"))).to be(false)
    end
  end

  describe ".confirmed_alerts" do
    it "returns the candidate alerts that re-alerted on the same benchmark+measure" do
      candidate = [alert("/x", "rps"), alert("/x", "p50_latency"), alert("/y", "rps")]
      confirmation = [alert("/x", "rps"), alert("/y", "rps"), alert("/z", "rps")]

      expect(described_class.confirmed_alerts(candidate, confirmation))
        .to contain_exactly(alert("/x", "rps"), alert("/y", "rps"))
    end

    it "is empty when nothing re-alerted (the first run was noise)" do
      expect(described_class.confirmed_alerts([alert("/x", "rps")], [alert("/y", "rps")])).to eq([])
      expect(described_class.confirmed_alerts([alert("/x", "rps")], [])).to eq([])
    end
  end

  describe "the ignore-list helpers" do
    let(:ignored) { described_class::IGNORED_REGRESSION_BENCHMARKS.first }

    it "drops ignored benchmarks from alert pairs" do
      alerts = [alert(ignored, "rps"), alert("/real: Pro", "rps")]
      expect(described_class.actionable_alerts(alerts)).to eq([alert("/real: Pro", "rps")])
    end

    it "drops ignored benchmark names" do
      expect(described_class.actionable_benchmarks([ignored, "/real: Pro"])).to eq(["/real: Pro"])
      expect(described_class.actionable_benchmarks([ignored])).to eq([])
      expect(described_class.actionable_benchmarks(nil)).to eq([])
    end
  end
end

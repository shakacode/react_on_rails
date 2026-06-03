# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../lib/bencher_report"

# BencherReport parses `bencher run --format json` output. These pin the two
# load-bearing behaviors: deterministic regression classification from the
# `alerts[]` array (replacing stderr grepping), and two-directional significance
# vs the t-test prediction interval — including deriving the *improvement* side
# of a one-sided threshold by mirroring about the baseline. The report shape is
# not a documented contract, so malformed shapes must raise loudly.
RSpec.describe BencherReport do
  # Build one measure entry. boundary: nil omits the boundary object entirely.
  def measure_entry(slug:, name:, value:, baseline: nil, lower_limit: nil, upper_limit: nil, boundary: :auto)
    entry = { "measure" => { "slug" => slug, "name" => name }, "metric" => { "value" => value } }
    if boundary == :auto
      entry["boundary"] = { "baseline" => baseline, "lower_limit" => lower_limit, "upper_limit" => upper_limit }
    elsif !boundary.nil?
      entry["boundary"] = boundary
    end
    entry
  end

  def benchmark_result(name:, measures:)
    { "benchmark" => { "name" => name }, "measures" => measures }
  end

  def alert(benchmark:, measure_slug:, limit:, status: "active")
    {
      "benchmark" => { "name" => benchmark },
      "threshold" => { "measure" => { "slug" => measure_slug } },
      "metric" => { "value" => 1.0 },
      "limit" => limit,
      "status" => status
    }
  end

  def report_json(results: [], alerts: [])
    JSON.generate("results" => results, "alerts" => alerts)
  end

  describe ".parse / #regression?" do
    it "reports no regression when alerts is empty" do
      report = described_class.parse(report_json)
      expect(report.regression?).to be(false)
      expect(report.alerts).to be_empty
    end

    it "reports a regression and exposes the active alert's benchmark/measure/side" do
      report = described_class.parse(
        report_json(alerts: [alert(benchmark: "/foo: Core", measure_slug: "rps", limit: "lower")])
      )
      expect(report.regression?).to be(true)
      expect(report.alerts.size).to eq(1)
      expect(report.alerts.first.benchmark).to eq("/foo: Core")
      expect(report.alerts.first.measure).to eq("rps")
      expect(report.alerts.first.limit).to eq("lower")
    end

    it "ignores dismissed/silenced alerts (only active counts as a regression)" do
      report = described_class.parse(
        report_json(alerts: [
                      alert(benchmark: "/a", measure_slug: "rps", limit: "lower", status: "dismissed"),
                      alert(benchmark: "/b", measure_slug: "rps", limit: "lower", status: "silenced")
                    ])
      )
      expect(report.regression?).to be(false)
    end
  end

  describe "#boundary" do
    let(:report) do
      described_class.parse(
        report_json(results: [[benchmark_result(
          name: "/foo: Core",
          measures: [measure_entry(slug: "p50-latency", name: "p50_latency", value: 5.0,
                                   baseline: 4.0, lower_limit: 3.0, upper_limit: 5.0)]
        )]])
      )
    end

    it "matches a measure key regardless of - / _ / case differences" do
      %w[p50_latency p50-latency P50_LATENCY].each do |key|
        expect(report.boundary("/foo: Core", key).baseline).to eq(4.0)
      end
    end

    it "returns nil for an unknown benchmark or measure" do
      expect(report.boundary("/missing", "p50_latency")).to be_nil
      expect(report.boundary("/foo: Core", "rps")).to be_nil
    end
  end

  describe "#significance" do
    # rps: higher-is-better (:lower threshold side). Only lower_limit is configured;
    # the improvement (upper) side must be derived by mirroring about baseline.
    def rps_report(value:, baseline: 100.0, lower_limit: 90.0)
      described_class.parse(
        report_json(results: [[benchmark_result(
          name: "/r",
          measures: [measure_entry(slug: "rps", name: "rps", value: value,
                                   baseline: baseline, lower_limit: lower_limit, upper_limit: nil)]
        )]])
      )
    end

    it "flags an rps drop below the lower limit as a regression" do
      expect(rps_report(value: 80.0).significance("/r", "rps", :lower)).to eq(:regression)
    end

    it "flags an rps climb above the mirrored upper limit as an improvement" do
      # mirror = 2*100 - 90 = 110; 115 > 110 => improvement
      expect(rps_report(value: 115.0).significance("/r", "rps", :lower)).to eq(:improvement)
    end

    it "returns nil for an rps value within the interval" do
      expect(rps_report(value: 105.0).significance("/r", "rps", :lower)).to be_nil
    end

    # p50_latency: lower-is-better (:upper threshold side). Only upper_limit configured.
    def p50_report(value:, baseline: 5.0, upper_limit: 6.0)
      described_class.parse(
        report_json(results: [[benchmark_result(
          name: "/p",
          measures: [measure_entry(slug: "p50-latency", name: "p50_latency", value: value,
                                   baseline: baseline, lower_limit: nil, upper_limit: upper_limit)]
        )]])
      )
    end

    it "flags a p50 climb above the upper limit as a regression" do
      expect(p50_report(value: 7.0).significance("/p", "p50_latency", :upper)).to eq(:regression)
    end

    it "flags a p50 drop below the mirrored lower limit as an improvement" do
      # mirror = 2*5 - 6 = 4; 3.5 < 4 => improvement
      expect(p50_report(value: 3.5).significance("/p", "p50_latency", :upper)).to eq(:improvement)
    end

    it "returns nil when baseline is missing (no history yet)" do
      report = described_class.parse(
        report_json(results: [[benchmark_result(
          name: "/n",
          measures: [measure_entry(slug: "rps", name: "rps", value: 80.0,
                                   baseline: nil, lower_limit: nil, upper_limit: nil)]
        )]])
      )
      expect(report.significance("/n", "rps", :lower)).to be_nil
    end

    it "returns nil when the benchmark/measure is absent from the report" do
      expect(rps_report(value: 80.0).significance("/missing", "rps", :lower)).to be_nil
    end

    it "returns nil when the measure has no boundary object" do
      report = described_class.parse(
        report_json(results: [[benchmark_result(
          name: "/nb",
          measures: [measure_entry(slug: "rps", name: "rps", value: 80.0, boundary: nil)]
        )]])
      )
      expect(report.significance("/nb", "rps", :lower)).to be_nil
    end
  end

  describe "defensive parsing" do
    it "raises FormatError on invalid JSON" do
      expect { described_class.parse("{not json") }.to raise_error(BencherReport::FormatError, /not valid JSON/)
    end

    it "raises FormatError when the root is not an object" do
      expect { described_class.parse("[]") }.to raise_error(BencherReport::FormatError, /not a JSON object/)
    end

    it "raises FormatError when results is not an array" do
      expect { described_class.parse(JSON.generate("results" => {}, "alerts" => [])) }
        .to raise_error(BencherReport::FormatError, /results/)
    end

    it "raises FormatError when a results iteration is not an array" do
      expect { described_class.parse(JSON.generate("results" => [{}], "alerts" => [])) }
        .to raise_error(BencherReport::FormatError, /not an array/)
    end

    it "raises FormatError when a measure metric value is missing" do
      bad = [[{ "benchmark" => { "name" => "/x" },
                "measures" => [{ "measure" => { "slug" => "rps", "name" => "rps" }, "metric" => {} }] }]]
      expect { described_class.parse(JSON.generate("results" => bad, "alerts" => [])) }
        .to raise_error(BencherReport::FormatError, /value/)
    end

    it "raises FormatError when alerts is missing entirely" do
      expect { described_class.parse(JSON.generate("results" => [])) }
        .to raise_error(BencherReport::FormatError, /alerts/)
    end
  end
end

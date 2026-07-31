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

  def rps_regression_result(name: "/foo: Core", value: 80.0)
    benchmark_result(
      name:,
      measures: [measure_entry(slug: "rps", name: "rps", value:, baseline: 100.0,
                               lower_limit: 90.0, upper_limit: nil)]
    )
  end

  describe ".parse / #regression?" do
    it "reports no regression when alerts is empty" do
      report = described_class.parse(report_json)
      expect(report.regression?).to be(false)
      expect(report.alerts).to be_empty
    end

    it "reports a current regression and exposes the active alert's benchmark/measure/side" do
      report = described_class.parse(
        report_json(
          results: [[rps_regression_result]],
          alerts: [alert(benchmark: "/foo: Core", measure_slug: "rps", limit: "lower")]
        )
      )
      expect(report.regression?).to be(true)
      expect(report.alerts.size).to eq(1)
      expect(report.alerts.first.benchmark).to eq("/foo: Core")
      expect(report.alerts.first.measure).to eq("rps")
      expect(report.alerts.first.limit).to eq("lower")
    end

    it "ignores active alerts when the current metric is not a regression" do
      report = described_class.parse(
        report_json(
          results: [[rps_regression_result(value: 95.0)]],
          alerts: [alert(benchmark: "/foo: Core", measure_slug: "rps", limit: "lower")]
        )
      )

      expect(report.regression?).to be(false)
      expect(report.alerts).to be_empty
      expect(report.filtered_alert?).to be(true)
    end

    it "keeps active alerts with no benchmark name fail-safe" do
      malformed_alert = alert(benchmark: "/foo: Core", measure_slug: "rps", limit: "lower")
      malformed_alert.delete("benchmark")

      report = described_class.parse(report_json(alerts: [malformed_alert]))

      expect(report.regression?).to be(true)
      expect(report.alerts.first.benchmark).to be_nil
      expect(report.filtered_alert?).to be(false)
    end

    it "keeps active alerts with no matching boundary fail-safe" do
      report = described_class.parse(
        report_json(
          results: [[benchmark_result(
            name: "/foo: Core",
            measures: [measure_entry(slug: "rps", name: "rps", value: 95.0, boundary: nil)]
          )]],
          alerts: [alert(benchmark: "/foo: Core", measure_slug: "rps", limit: "lower")]
        )
      )

      expect(report.regression?).to be(true)
      expect(report.filtered_alert?).to be(false)
    end

    it "keeps measure-less active alerts fail-safe when no boundary exists on the alert side" do
      measureless_alert = alert(benchmark: "/foo: Core", measure_slug: "rps", limit: "lower")
      measureless_alert["threshold"] = {}

      report = described_class.parse(
        report_json(
          results: [[benchmark_result(
            name: "/foo: Core",
            measures: [measure_entry(slug: "p50-latency", name: "p50_latency", value: 5.5,
                                     baseline: 5.0, lower_limit: nil, upper_limit: 6.0)]
          )]],
          alerts: [measureless_alert]
        )
      )

      expect(report.regression?).to be(true)
      expect(report.filtered_alert?).to be(false)
    end

    it "keeps measure-less active alerts when the benchmark has a current regression on the alert side" do
      measureless_alert = alert(benchmark: "/foo: Core", measure_slug: "rps", limit: "lower")
      measureless_alert["threshold"] = {}

      report = described_class.parse(
        report_json(
          results: [[rps_regression_result]],
          alerts: [measureless_alert]
        )
      )

      expect(report.regression?).to be(true)
      expect(report.alerts.first.benchmark).to eq("/foo: Core")
      expect(report.alerts.first.measure).to be_nil
    end

    it "ignores measure-less active alerts when the benchmark has no current regression on the alert side" do
      measureless_alert = alert(benchmark: "/foo: Core", measure_slug: "rps", limit: "lower")
      measureless_alert["threshold"] = {}

      report = described_class.parse(
        report_json(
          results: [[rps_regression_result(value: 95.0)]],
          alerts: [measureless_alert]
        )
      )

      expect(report.regression?).to be(false)
      expect(report.alerts).to be_empty
    end

    it "ignores opposite-side improvements when matching measure-less active alerts" do
      measureless_alert = alert(benchmark: "/foo: Core", measure_slug: "rps", limit: "lower")
      measureless_alert["threshold"] = {}

      report = described_class.parse(
        report_json(
          results: [[benchmark_result(
            name: "/foo: Core",
            measures: [
              measure_entry(slug: "rps", name: "rps", value: 100.0,
                            baseline: 100.0, lower_limit: 90.0, upper_limit: nil),
              measure_entry(slug: "p50-latency", name: "p50_latency", value: 3.0,
                            baseline: 5.0, lower_limit: nil, upper_limit: 6.0)
            ]
          )]],
          alerts: [measureless_alert]
        )
      )

      expect(report.regression?).to be(false)
      expect(report.alerts).to be_empty
    end

    it "still reports hidden failed_pct regressions when the current value crosses its upper boundary" do
      report = described_class.parse(
        report_json(
          results: [[benchmark_result(
            name: "/foo: Core",
            measures: [measure_entry(slug: "failed-pct", name: "failed_pct", value: 2.0,
                                     baseline: 0.0, lower_limit: nil, upper_limit: 1.0)]
          )]],
          alerts: [alert(benchmark: "/foo: Core", measure_slug: "failed-pct", limit: "upper")]
        )
      )

      expect(report.regression?).to be(true)
      expect(report.alerts.first.measure).to eq("failed-pct")
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

  # An orphaned server-side threshold (e.g. p90_latency, which the code dropped from
  # THRESHOLDS but never deleted in Bencher) keeps firing alerts on a measure the code
  # no longer tracks. Those alerts are invisible in the summary table (the p90 column has
  # no :direction) yet would still file a regression issue. `tracked_measures` lets the
  # caller pass the measures it actually tracks so an alert on any other measure is treated
  # as filtered, not a regression. See the orphaned-p90-threshold investigation.
  describe "tracked-measure filtering" do
    def p90_report(tracked_measures: :unset)
      json = report_json(
        results: [[benchmark_result(
          name: "/foo: Core",
          measures: [measure_entry(slug: "p90-latency", name: "p90_latency", value: 24.2,
                                   baseline: 17.9, lower_limit: nil, upper_limit: 23.6)]
        )]],
        alerts: [alert(benchmark: "/foo: Core", measure_slug: "p90-latency", limit: "upper")]
      )
      tracked_measures == :unset ? described_class.parse(json) : described_class.parse(json, tracked_measures:)
    end

    it "filters an active alert on an untracked measure (orphaned p90 threshold)" do
      report = p90_report(tracked_measures: %w[rps p50_latency failed_pct])
      expect(report.regression?).to be(false)
      expect(report.alerts).to be_empty
      expect(report.filtered_alert?).to be(true)
    end

    it "still reports a regression on a tracked measure when tracked_measures is given" do
      report = described_class.parse(
        report_json(
          results: [[rps_regression_result]],
          alerts: [alert(benchmark: "/foo: Core", measure_slug: "rps", limit: "lower")]
        ),
        tracked_measures: %w[rps p50_latency failed_pct]
      )
      expect(report.regression?).to be(true)
      expect(report.alerts.first.measure).to eq("rps")
    end

    it "matches tracked measures regardless of - / _ / case (slug vs THRESHOLDS name)" do
      report = described_class.parse(
        report_json(
          results: [[benchmark_result(
            name: "/foo: Core",
            measures: [measure_entry(slug: "p50-latency", name: "p50_latency", value: 7.0,
                                     baseline: 5.0, lower_limit: nil, upper_limit: 6.0)]
          )]],
          alerts: [alert(benchmark: "/foo: Core", measure_slug: "p50-latency", limit: "upper")]
        ),
        tracked_measures: %w[rps p50_latency failed_pct]
      )
      expect(report.regression?).to be(true)
    end

    it "counts every measure when tracked_measures is not given (backward compatible)" do
      expect(p90_report.regression?).to be(true)
    end

    it "keeps a measure-less alert fail-safe even with tracked_measures set" do
      measureless_alert = alert(benchmark: "/foo: Core", measure_slug: "rps", limit: "lower")
      measureless_alert["threshold"] = {}
      report = described_class.parse(
        report_json(results: [[rps_regression_result]], alerts: [measureless_alert]),
        tracked_measures: %w[rps p50_latency failed_pct]
      )
      expect(report.regression?).to be(true)
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
          measures: [measure_entry(slug: "rps", name: "rps", value:,
                                   baseline:, lower_limit:, upper_limit: nil)]
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
          measures: [measure_entry(slug: "p50-latency", name: "p50_latency", value:,
                                   baseline:, lower_limit: nil, upper_limit:)]
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

    # Bencher configures only one threshold side per measure, so every test above
    # exercises the mirror branch. When BOTH limits are present (a two-sided
    # boundary) the parser must use the REAL limit on each side, not the mirror —
    # else the `lower_limit || mirror(upper_limit)` precedence could silently invert
    # and stay green. Asymmetric limits (90/120 about baseline 100) make real ≠ mirror.
    def two_sided_report(value:)
      described_class.parse(
        report_json(results: [[benchmark_result(
          name: "/b",
          measures: [measure_entry(slug: "rps", name: "rps", value:,
                                   baseline: 100.0, lower_limit: 90.0, upper_limit: 120.0)]
        )]])
      )
    end

    it "uses the real lower limit, not the mirror of the upper, when both are present" do
      # mirror of upper 120 about 100 = 80; 85 is below the real lower (90) but above
      # the mirror, so only the correct precedence flags it as a regression.
      expect(two_sided_report(value: 85.0).significance("/b", "rps", :lower)).to eq(:regression)
    end

    it "uses the real upper limit, not the mirror of the lower, when both are present" do
      # mirror of lower 90 about 100 = 110; 115 is above the mirror but below the real
      # upper (120), so the correct precedence leaves it un-flagged.
      expect(two_sided_report(value: 115.0).significance("/b", "rps", :lower)).to be_nil
    end
  end

  # Per-benchmark Bencher perf-plot URL (issue #3601 item 2). Built from the report's
  # branch/head/testbed UUIDs (top-level), the per-benchmark UUID and its measure UUIDs,
  # and the report UUID — matching the query shape Bencher's own PR-comment code emits
  # (lib/bencher_comment perf_url + JsonPerfQuery: branches/heads/testbeds/benchmarks/
  # measures comma-lists, then report=). These fields are NOT part of the documented
  # contract, so extraction is lenient: any missing piece yields nil and the caller
  # renders the benchmark name unlinked rather than failing the job.
  # Sample confirmation (#4580): repeated per-route samples act as built-in reruns.
  # Overlapping base/head sample ranges downgrade a boundary crossing (alerts move
  # out of #alerts; #significance reports :unconfirmed); disjoint ranges confirm it.
  describe "#apply_sample_confirmation!" do
    def alerting_report
      described_class.parse(
        report_json(
          results: [[rps_regression_result]],
          alerts: [alert(benchmark: "/foo: Core", measure_slug: "rps", limit: "lower")]
        )
      )
    end

    def confirmed(report, head:, base:)
      report.apply_sample_confirmation!(
        head_samples: { "/foo: Core" => { "rps" => head } },
        base_samples: { "/foo: Core" => { "rps" => base } }
      )
    end

    it "keeps a change whose sample ranges are disjoint (reproduced in every sample)" do
      report = confirmed(alerting_report, head: [80.0, 82.0, 79.0], base: [100.0, 98.0, 101.0])

      expect(report.regression?).to be(true)
      expect(report.unconfirmed_alert?).to be(false)
      expect(report.significance("/foo: Core", "rps", :lower)).to eq(:regression)
    end

    it "downgrades a change whose sample ranges overlap (did not reproduce)" do
      report = confirmed(alerting_report, head: [80.0, 99.5, 79.0], base: [99.0, 98.0, 101.0])

      expect(report.regression?).to be(false)
      expect(report.unconfirmed_alert?).to be(true)
      expect(report.unconfirmed_alerts.first.benchmark).to eq("/foo: Core")
      expect(report.significance("/foo: Core", "rps", :lower)).to eq(:unconfirmed)
    end

    it "downgrades an unreproduced improvement flag too" do
      report = described_class.parse(
        report_json(results: [[rps_regression_result(value: 115.0)]])
      )
      confirmed(report, head: [115.0, 99.0, 116.0], base: [100.0, 98.0, 101.0])

      expect(report.significance("/foo: Core", "rps", :lower)).to eq(:unconfirmed)
    end

    it "matches sample measure keys across slug/name normalization" do
      report = alerting_report
      report.apply_sample_confirmation!(
        head_samples: { "/foo: Core" => { "RPS" => [80.0, 99.5] } },
        base_samples: { "/foo: Core" => { "rps" => [99.0, 101.0] } }
      )

      expect(report.unconfirmed_alert?).to be(true)
    end

    it "fails open when either side lacks two numeric samples" do
      [
        { head: [80.0], base: [100.0, 101.0] },              # too few head samples
        { head: [80.0, "x"], base: [100.0, 101.0] },         # non-numeric head sample
        { head: [80.0, 99.5], base: nil },                   # base measure missing
        {}                                                   # no sample data at all
      ].each do |scenario|
        report = alerting_report
        if scenario.any?
          report.apply_sample_confirmation!(
            head_samples: { "/foo: Core" => { "rps" => scenario[:head] }.compact },
            base_samples: { "/foo: Core" => { "rps" => scenario[:base] }.compact }
          )
        else
          report.apply_sample_confirmation!(head_samples: {}, base_samples: {})
        end

        expect(report.regression?).to be(true), "expected fail-open for #{scenario.inspect}"
        expect(report.significance("/foo: Core", "rps", :lower)).to eq(:regression)
      end
    end

    it "leaves boundary-only significance untouched for pairs without an alert" do
      # rps at 95.0 sits inside its 90–110 interval, so no flag fires — confirmation
      # only downgrades measures whose boundary crossing fired; a non-flagged measure
      # stays nil/unchanged even when its sample ranges overlap.
      report = described_class.parse(report_json(results: [[rps_regression_result(value: 95.0)]]))
      confirmed(report, head: [95.0, 96.0], base: [100.0, 99.0])

      expect(report.significance("/foo: Core", "rps", :lower)).to be_nil
    end
  end

  describe "#perf_url" do
    def bench(name:, uuid:, measure_uuids:)
      measures = measure_uuids.each_with_index.map do |muuid, i|
        { "measure" => { "slug" => "m#{i}", "name" => "m#{i}", "uuid" => muuid }, "metric" => { "value" => 1.0 } }
      end
      { "benchmark" => { "name" => name, "uuid" => uuid }, "measures" => measures }
    end

    def report_with(results:, **ctx)
      head_uuid = ctx.fetch(:head_uuid, "H")
      branch = { "uuid" => ctx.fetch(:branch_uuid, "B") }
      branch["head"] = { "uuid" => head_uuid } if head_uuid
      raw = {
        "uuid" => ctx.fetch(:report_uuid, "R"),
        "project" => { "slug" => ctx.fetch(:project_slug, "P") },
        "branch" => branch,
        "testbed" => { "uuid" => ctx.fetch(:testbed_uuid, "T") },
        "results" => results, "alerts" => []
      }
      described_class.new(raw)
    end

    it "builds a per-benchmark perf URL from branch/head/testbed/benchmark/measures/report" do
      report = report_with(results: [[bench(name: "/foo: Core", uuid: "BM", measure_uuids: %w[M1 M2])]])
      expect(report.perf_url("/foo: Core")).to eq(
        "https://bencher.dev/perf/P?branches=B&heads=H&testbeds=T&benchmarks=BM&measures=M1,M2&report=R"
      )
    end

    it "returns nil for an unknown benchmark" do
      report = report_with(results: [[bench(name: "/foo", uuid: "BM", measure_uuids: %w[M1])]])
      expect(report.perf_url("/missing")).to be_nil
    end

    it "returns nil when a required id (testbed) is absent, so the name renders unlinked" do
      raw = { "uuid" => "R", "project" => { "slug" => "P" },
              "branch" => { "uuid" => "B", "head" => { "uuid" => "H" } },
              "results" => [[bench(name: "/foo", uuid: "BM", measure_uuids: %w[M1])]], "alerts" => [] }
      expect(described_class.new(raw).perf_url("/foo")).to be_nil
    end

    it "returns nil when the benchmark has no measure uuids" do
      report = report_with(results: [[bench(name: "/foo", uuid: "BM", measure_uuids: [])]])
      expect(report.perf_url("/foo")).to be_nil
    end

    it "omits the optional head param when the branch head uuid is absent" do
      report = report_with(results: [[bench(name: "/foo", uuid: "BM", measure_uuids: %w[M1])]], head_uuid: nil)
      expect(report.perf_url("/foo")).to eq(
        "https://bencher.dev/perf/P?branches=B&testbeds=T&benchmarks=BM&measures=M1&report=R"
      )
    end

    it "omits the optional report param when the report uuid is absent" do
      raw = { "project" => { "slug" => "P" },
              "branch" => { "uuid" => "B", "head" => { "uuid" => "H" } }, "testbed" => { "uuid" => "T" },
              "results" => [[bench(name: "/foo", uuid: "BM", measure_uuids: %w[M1])]], "alerts" => [] }
      expect(described_class.new(raw).perf_url("/foo")).to eq(
        "https://bencher.dev/perf/P?branches=B&heads=H&testbeds=T&benchmarks=BM&measures=M1"
      )
    end
  end

  # All perf links share one report-wide context (project/branch/testbed uuid). Losing it
  # silently unlinks EVERY benchmark name — a likely report-shape drift the caller surfaces
  # as a ::warning:: (never a FormatError, since links are cosmetic). The strict parse does
  # not read these fields, so a report can parse cleanly yet still have unusable perf links.
  describe "#perf_links_unavailable?" do
    def result_for(name)
      { "benchmark" => { "name" => name, "uuid" => "BM" },
        "measures" => [{ "measure" => { "slug" => "rps", "name" => "rps", "uuid" => "M1" },
                         "metric" => { "value" => 1.0 } }] }
    end

    it "is true when the report lists benchmarks but the shared perf context is absent" do
      raw = { "results" => [[result_for("/foo")]], "alerts" => [] }
      expect(described_class.new(raw).perf_links_unavailable?).to be(true)
    end

    it "is false when the shared perf context is present" do
      raw = { "project" => { "slug" => "P" }, "branch" => { "uuid" => "B" }, "testbed" => { "uuid" => "T" },
              "results" => [[result_for("/foo")]], "alerts" => [] }
      expect(described_class.new(raw).perf_links_unavailable?).to be(false)
    end

    it "is false when the report lists no benchmarks (nothing to link)" do
      expect(described_class.new({ "results" => [], "alerts" => [] }).perf_links_unavailable?).to be(false)
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

# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../lib/benchmark_table"
require_relative "../lib/bencher_report"

# BenchmarkTable renders a suite's display rows as a Markdown pipe table. Each tracked
# metric cell (RPS, p50, p90) shows the value, a ▲/▼ delta vs the Bencher baseline, and
# the baseline in parentheses; a value that crossed its t-test boundary is bolded with
# the arrow replaced by 🔴 (regression) / 🟢 (improvement). The benchmark name links to
# that benchmark's Bencher perf plot. All significance/baseline/url facts come from an
# injected report, so the renderer is tested in isolation against a verified
# BencherReport double looked up by (name, measure).
RSpec.describe BenchmarkTable do
  # A BencherReport stand-in. `verdicts` maps [name, measure] => :regression/:improvement;
  # `baselines` maps [name, measure] => Float (returned via a real Boundary so #baseline
  # behaves exactly like production); `urls` maps name => perf URL. Verified against the
  # real interface so it can't drift.
  def fake_report(verdicts: {}, baselines: {}, urls: {})
    instance_double(BencherReport).tap do |report|
      allow(report).to receive(:significance) { |name, measure, _direction| verdicts[[name, measure]] }
      allow(report).to receive(:boundary) do |name, measure|
        base = baselines[[name, measure]]
        base && BencherReport::Boundary.new(value: nil, baseline: base, lower_limit: nil, upper_limit: nil)
      end
      allow(report).to receive(:perf_url) { |name| urls[name] }
    end
  end

  def row(name:, rps:, p50:, p90:, status:)
    { "name" => name, "rps" => rps, "p50" => p50, "p90" => p90, "status" => status }
  end

  def render(rows:, report:)
    described_class.new(title: "Core Benchmark Summary", rows:, report:).to_markdown
  end

  it "renders title, header (no Fail% column), divider, one row per input, and a legend" do
    markdown = render(
      rows: [row(name: "/foo", rps: 100.0, p50: 5.0, p90: 6.0, status: "200=100")],
      report: fake_report
    )

    expect(markdown).to include("### Core Benchmark Summary")
    expect(markdown).to include("| Benchmark | RPS | p50(ms) | p90(ms) | Status |")
    expect(markdown).to include("| --- | --- | --- | --- | --- |")
    expect(markdown).to include("| /foo | 100.0 | 5.0 | 6.0 | 200=100 |")
    expect(markdown).not_to include("Fail%")
    expect(markdown).to include("▲/▼ non-zero change vs baseline")
    expect(markdown).to include("0.0% exact/near-zero match")
    expect(markdown).to include("🔴 significant regression")
    expect(markdown).to include("🟢 significant improvement")
  end

  it "shows a ▲/▼ delta and the baseline for a non-significant change" do
    report = fake_report(baselines: { ["/foo", "rps"] => 97.75, ["/foo", "p50_latency"] => 5.07 })
    markdown = render(
      rows: [row(name: "/foo", rps: 100.0, p50: 5.0, p90: 6.0, status: "200=100")],
      report:
    )

    # rps rose 2.3% above baseline (▲), p50 fell 1.4% below baseline (▼).
    expect(markdown).to include("| /foo | 100.0 ▲2.3% (97.75) | 5.0 ▼1.4% (5.07) | 6.0 | 200=100 |")
  end

  it "rounds the displayed baseline to two decimals" do
    # A high-precision Bencher baseline must not leak its full precision into the cell.
    report = fake_report(baselines: { ["/foo", "rps"] => 97.756 })
    markdown = render(
      rows: [row(name: "/foo", rps: 100.0, p50: 5.0, p90: 6.0, status: "200=100")],
      report:
    )

    # baseline 97.756 -> (97.76); proves format_number's round(2) actually rounds.
    expect(markdown).to include("100.0 ▲2.3% (97.76)")
  end

  it "rounds displayed metric values to the same precision as baselines" do
    report = fake_report(baselines: { ["/foo", "rps"] => 97.756 })
    markdown = render(
      rows: [row(name: "/foo", rps: 100.126, p50: 5.0, p90: 6.0, status: "200=100")],
      report:
    )

    expect(markdown).to include("100.13 ▲2.4% (97.76)")
  end

  it "bolds + tags a regressed RPS cell and an improved p50 cell, replacing the arrow with the emoji" do
    report = fake_report(
      verdicts: { ["/foo", "rps"] => :regression, ["/foo", "p50_latency"] => :improvement },
      baselines: { ["/foo", "rps"] => 100.0, ["/foo", "p50_latency"] => 5.0 }
    )
    markdown = render(
      rows: [row(name: "/foo", rps: 80.0, p50: 4.0, p90: 6.0, status: "200=100")],
      report:
    )

    expect(markdown).to include("| /foo | **80.0** 🔴 20.0% (100.0) | **4.0** 🟢 20.0% (5.0) | 6.0 | 200=100 |")
  end

  it "renders an unconfirmed crossing with ⚠️ plus the plain arrow, unbolded" do
    report = fake_report(
      verdicts: { ["/foo", "rps"] => :unconfirmed, ["/foo", "p50_latency"] => :unconfirmed },
      baselines: { ["/foo", "rps"] => 100.0, ["/foo", "p50_latency"] => 5.0 }
    )
    markdown = render(
      rows: [row(name: "/foo", rps: 80.0, p50: 7.0, p90: 6.0, status: "200=100")],
      report:
    )

    expect(markdown).to include("| /foo | 80.0 ⚠️ ▼20.0% (100.0) | 7.0 ⚠️ ▲40.0% (5.0) | 6.0 | 200=100 |")
    expect(markdown).to include("⚠️ crossed threshold but base/head samples overlap (unconfirmed)")
  end

  it "shows a p90 delta when a baseline exists but never marks it significant (p90 is untracked)" do
    # Even if the report somehow returned a verdict for p90, the p90 column has no
    # direction, so the renderer must not consult significance for it — only the baseline.
    report = fake_report(
      verdicts: { ["/foo", "p90_latency"] => :regression },
      baselines: { ["/foo", "p90_latency"] => 5.0 }
    )
    markdown = render(
      rows: [row(name: "/foo", rps: 100.0, p50: 5.0, p90: 6.0, status: "200=100")],
      report:
    )

    expect(markdown).to include("6.0 ▲20.0% (5.0)")
    expect(markdown).not_to include("**6.0**")
    expect(markdown).not_to include("🔴 20.0% (5.0)")
  end

  it "shows only the value (no delta) when the report has no baseline for a measure" do
    markdown = render(
      rows: [row(name: "/foo", rps: 100.0, p50: 5.0, p90: 6.0, status: "200=100")],
      report: fake_report
    )

    expect(markdown).to include("| /foo | 100.0 | 5.0 | 6.0 | 200=100 |")
  end

  it "shows only the value (no delta) when the baseline is zero, avoiding a divide-by-zero" do
    report = fake_report(baselines: { ["/foo", "rps"] => 0.0 })
    markdown = render(
      rows: [row(name: "/foo", rps: 100.0, p50: 5.0, p90: 6.0, status: "200=100")],
      report:
    )

    expect(markdown).to include("| /foo | 100.0 | 5.0 | 6.0 | 200=100 |")
  end

  it "shows an explicit 0.0% delta when the metric exactly equals its baseline" do
    report = fake_report(baselines: { ["/foo", "rps"] => 100.0 })
    markdown = render(
      rows: [row(name: "/foo", rps: 100.0, p50: 5.0, p90: 6.0, status: "200=100")],
      report:
    )

    expect(markdown).to include("| /foo | 100.0 0.0% (100.0) | 5.0 | 6.0 | 200=100 |")
  end

  it "shows 0.0% without an arrow when the rounded delta is zero" do
    report = fake_report(baselines: { ["/foo", "rps"] => 100.0 })
    markdown = render(
      rows: [row(name: "/foo", rps: 100.00001, p50: 5.0, p90: 6.0, status: "200=100")],
      report:
    )

    expect(markdown).to include("| /foo | 100.0 0.0% (100.0) | 5.0 | 6.0 | 200=100 |")
    expect(markdown).not_to include("▲0.0%")
    expect(markdown).not_to include("▼0.0%")
  end

  it "preserves significance markers when a significant delta rounds to zero" do
    report = fake_report(
      verdicts: { ["/foo", "rps"] => :regression, ["/foo", "p50_latency"] => :improvement },
      baselines: { ["/foo", "rps"] => 100.0, ["/foo", "p50_latency"] => 5.0 }
    )
    markdown = render(
      rows: [row(name: "/foo", rps: 99.999, p50: 4.999, p90: 6.0, status: "200=100")],
      report:
    )

    expect(markdown).to include(
      "| /foo | **100.0** 🔴 0.0% (100.0) | **5.0** 🟢 0.0% (5.0) | 6.0 | 200=100 |"
    )
    expect(markdown).not_to include("▲0.0%")
    expect(markdown).not_to include("▼0.0%")
  end

  it "links the benchmark name to its perf URL when the report provides one" do
    report = fake_report(urls: { "/foo" => "https://bencher.dev/perf/p?benchmarks=BM" })
    markdown = render(
      rows: [row(name: "/foo", rps: 100.0, p50: 5.0, p90: 6.0, status: "200=100")],
      report:
    )

    expect(markdown).to include("| [/foo](https://bencher.dev/perf/p?benchmarks=BM) | 100.0 |")
  end

  it "escapes brackets in a linked name so they can't prematurely close the link" do
    report = fake_report(urls: { "a[b]c" => "https://bencher.dev/perf/p?benchmarks=BM" })
    markdown = render(
      rows: [row(name: "a[b]c", rps: 100.0, p50: 5.0, p90: 6.0, status: "200=100")],
      report:
    )

    # Brackets are backslash-escaped inside the link text, so the link wraps the whole name.
    expect(markdown).to include('| [a\[b\]c](https://bencher.dev/perf/p?benchmarks=BM) | 100.0 |')
  end

  it "leaves the benchmark name unlinked when the report has no perf URL for it" do
    markdown = render(
      rows: [row(name: "/foo", rps: 100.0, p50: 5.0, p90: 6.0, status: "200=100")],
      report: fake_report
    )

    expect(markdown).to include("| /foo | 100.0 |")
    expect(markdown).not_to include("](")
  end

  it "renders a non-numeric rps token (FAILED/MISSING) as plain text without a delta" do
    report = fake_report(
      verdicts: { ["/broken", "rps"] => :regression },
      baselines: { ["/broken", "rps"] => 100.0 }
    )
    markdown = render(
      rows: [row(name: "/broken", rps: "FAILED", p50: nil, p90: nil, status: "Connection refused")],
      report:
    )

    expect(markdown).to include("| /broken | FAILED | — | — | Connection refused |")
    expect(markdown).not_to include("**FAILED**")
  end

  it "renders nil numeric cells as an em dash and never adds a delta to them" do
    report = fake_report(baselines: { ["/p", "p50_latency"] => 5.0 })
    markdown = render(
      rows: [row(name: "/p", rps: 100.0, p50: nil, p90: nil, status: "200=100")],
      report:
    )

    expect(markdown).to include("| /p | 100.0 | — | — | 200=100 |")
  end

  it "renders without a report (no links, no deltas) when report is nil" do
    markdown = render(
      rows: [row(name: "/foo", rps: 100.0, p50: 5.0, p90: 6.0, status: "200=100")],
      report: nil
    )

    expect(markdown).to include("| /foo | 100.0 | 5.0 | 6.0 | 200=100 |")
  end

  it "escapes emphasis/code metacharacters (_ * `) in names and status" do
    markdown = render(
      rows: [row(name: "a_b_c", rps: 1.0, p50: 2.0, p90: 3.0, status: "`x` *y*")],
      report: fake_report
    )

    expect(markdown).to include('a\_b\_c')
    expect(markdown).to include('\`x\` \*y\*')
  end

  it "escapes pipe and backslash characters in values" do
    markdown = render(
      rows: [row(name: "/a|b", rps: 1.0, p50: 2.0, p90: 3.0, status: "x\\|y")],
      report: fake_report
    )

    expect(markdown).to include('/a\|b')
    expect(markdown).to include('x\\\\\\|y')
  end

  it "shows a placeholder instead of an empty table when there are no rows" do
    markdown = render(rows: [], report: fake_report)

    expect(markdown).to include("_No benchmark results._")
    expect(markdown).not_to include("| Benchmark |")
  end
end

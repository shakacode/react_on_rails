# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../lib/benchmark_table"
require_relative "../lib/bencher_report"

# BenchmarkTable renders a suite's display rows as a Markdown pipe table, bolding
# and tagging tracked-measure cells (RPS, p50) that crossed their t-test boundary
# while leaving non-tracked columns (p90, Status) plain. The significance verdict
# comes from an injected report, so the renderer is tested in isolation against a
# verified BencherReport double whose verdicts are looked up by (name, measure).
RSpec.describe BenchmarkTable do
  # A BencherReport stand-in returning the verdict registered for a (name, measure)
  # pair, else nil. Verified against the real interface so it can't drift.
  def fake_report(verdicts = {})
    instance_double(BencherReport).tap do |report|
      allow(report).to receive(:significance) { |name, measure, _direction| verdicts[[name, measure]] }
    end
  end

  def row(name:, rps:, p50:, p90:, status:)
    { "name" => name, "rps" => rps, "p50" => p50, "p90" => p90, "status" => status }
  end

  def render(rows:, report:)
    described_class.new(title: "Core Benchmark Summary", rows: rows, report: report).to_markdown
  end

  it "renders a header, divider, the title, one row per input, and a legend" do
    markdown = render(
      rows: [row(name: "/foo", rps: 100.0, p50: 5.0, p90: 6.0, status: "200=100")],
      report: fake_report
    )

    expect(markdown).to include("### Core Benchmark Summary")
    expect(markdown).to include("| Benchmark | RPS | p50(ms) | p90(ms) | Status |")
    expect(markdown).to include("| --- | --- | --- | --- | --- |")
    expect(markdown).to include("| /foo | 100.0 | 5.0 | 6.0 | 200=100 |")
    expect(markdown).to include("🔴 significant regression")
    expect(markdown).to include("🟢 significant improvement")
  end

  it "bolds + tags a regressed RPS cell and an improved p50 cell" do
    report = fake_report(
      ["/foo", "rps"] => :regression,
      ["/foo", "p50_latency"] => :improvement
    )
    markdown = render(
      rows: [row(name: "/foo", rps: 80.0, p50: 4.0, p90: 6.0, status: "200=100")],
      report: report
    )

    expect(markdown).to include("| /foo | **80.0** 🔴 | **4.0** 🟢 | 6.0 | 200=100 |")
  end

  it "never highlights non-tracked columns (p90, Status) and leaves untouched rows plain" do
    # Even if the report had verdicts for these, the renderer must not consult it
    # for p90/Status — they are not in COLUMNS as highlightable.
    report = fake_report(["/foo", "p90"] => :regression, ["/foo", "status"] => :regression)
    markdown = render(
      rows: [row(name: "/foo", rps: 100.0, p50: 5.0, p90: 6.0, status: "200=100")],
      report: report
    )

    expect(markdown).to include("| /foo | 100.0 | 5.0 | 6.0 | 200=100 |")
    expect(markdown).not_to include("**6.0**")
  end

  it "renders nil numeric cells as an em dash and never highlights them" do
    report = fake_report(["/p", "p50_latency"] => :regression)
    markdown = render(
      rows: [row(name: "/p", rps: 100.0, p50: nil, p90: nil, status: "200=100")],
      report: report
    )

    expect(markdown).to include("| /p | 100.0 | — | — | 200=100 |")
  end

  it "escapes pipe characters in values" do
    markdown = render(
      rows: [row(name: "/a|b", rps: 1.0, p50: 2.0, p90: 3.0, status: "200=1")],
      report: fake_report
    )

    expect(markdown).to include('/a\|b')
  end

  it "escapes backslashes (so the escape char can't combine with following text)" do
    markdown = render(
      rows: [row(name: "/a\\b", rps: 1.0, p50: 2.0, p90: 3.0, status: "x\\|y")],
      report: fake_report
    )

    # "/a\b" -> "/a\\b"; "x\|y" -> "x\\\|y" (backslash escaped, then the pipe escaped).
    expect(markdown).to include('/a\\\\b')
    expect(markdown).to include('x\\\\\\|y')
  end

  it "renders a non-numeric rps token (FAILED/MISSING) as plain text without highlighting" do
    report = fake_report(["/broken", "rps"] => :regression)
    markdown = render(
      rows: [row(name: "/broken", rps: "FAILED", p50: nil, p90: nil, status: "Connection refused")],
      report: report
    )

    expect(markdown).to include("| /broken | FAILED | — | — | Connection refused |")
    expect(markdown).not_to include("**FAILED**")
  end

  it "renders without a report (no highlighting) when report is nil" do
    markdown = render(
      rows: [row(name: "/foo", rps: 100.0, p50: 5.0, p90: 6.0, status: "200=100")],
      report: nil
    )

    expect(markdown).to include("| /foo | 100.0 | 5.0 | 6.0 | 200=100 |")
  end

  it "shows a placeholder instead of an empty table when there are no rows" do
    markdown = render(rows: [], report: fake_report)

    expect(markdown).to include("_No benchmark results._")
    expect(markdown).not_to include("| Benchmark |")
  end
end

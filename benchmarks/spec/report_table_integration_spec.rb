# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../lib/bencher_report"
require_relative "../lib/benchmark_table"

# Integration: a REAL BencherReport (parsed from a fixture) feeding a REAL
# BenchmarkTable. The unit specs exercise each side in isolation (the table against a
# BencherReport double), so this is the only place that pins the actual seam — the
# canonical-name + slug/name join (`/heavy: Core`, `rps`, `p50_latency`) and the
# significance verdicts flowing through to bolded/tagged cells.
#
# The fixture is hand-authored to the `bencher run --format json` shape verified for
# CLI v0.6.2 (see benchmarks/lib/bencher_report.rb and .github/workflows/benchmark.yml).
# When bumping the CLI, re-verify it against a real payload — a value-level drift (e.g.
# the alert `status` vocabulary) would not be caught by the structural parser alone.
RSpec.describe "BencherReport + BenchmarkTable integration" do
  let(:report) do
    BencherReport.parse(File.read(File.join(__dir__, "fixtures", "bencher_report_sample.json")))
  end

  # Display rows as the bench scripts would emit them (BmfCollector#display_rows),
  # keyed by the same canonical name the fixture's report uses.
  let(:rows) do
    [{ "name" => "/heavy: Core", "rps" => 80.0, "p50" => 3.5, "p90" => 7.2, "status" => "200=900,5xx=10" }]
  end

  it "classifies the fixture as a regression and exposes the active alert" do
    expect(report.regression?).to be(true)
    expect(report.alerts.map(&:benchmark)).to eq(["/heavy: Core"])
    expect(report.alerts.first.measure).to eq("rps")
  end

  it "resolves significance through the real report for both tracked measures" do
    expect(report.significance("/heavy: Core", "rps", :lower)).to eq(:regression)
    # p50 dropped below the mirrored lower limit (2*5 - 6 = 4; 3.5 < 4) => improvement.
    expect(report.significance("/heavy: Core", "p50_latency", :upper)).to eq(:improvement)
  end

  it "renders the regressed RPS cell and improved p50 cell, leaving p90/Status plain" do
    markdown = BenchmarkTable.new(title: "Core Benchmark Summary", rows: rows, report: report).to_markdown

    expect(markdown).to include("| /heavy: Core | **80.0** 🔴 | **3.5** 🟢 | 7.2 | 200=900,5xx=10 |")
  end
end

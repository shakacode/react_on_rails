# frozen_string_literal: true

require "open3"
require "rbconfig"
require "stringio"

require_relative "spec_helper"

RSpec.describe "run-local-benchmark-comparison" do
  let(:script) { File.expand_path("../run-local-benchmark-comparison.rb", __dir__) }
  let(:script_source) { File.read(script) }

  def run_script(*args)
    Open3.capture3(RbConfig.ruby, script, "core", *args, "--dry-run")
  end

  def load_markdown_helpers(source)
    helpers = Object.new
    helper_source = [
      source[/^MAX_MARKDOWN_ROUTE_ROWS = .*/],
      source[/^def top_route_groups.*?^timestamp =/m].sub(/^timestamp =.*/m, "")
    ].join("\n")
    helpers.instance_eval(helper_source, script)
    helpers
  end

  it "copies direct benchmark helper dependencies into old-ref shims" do
    runner_shim_files = script_source.match(/RUNNER_SHIM_FILES = %w\[(.*?)\]/m).captures.fetch(0).split

    expect(runner_shim_files).to include(
      "benchmarks/k6.ts",
      "benchmarks/lib/benchmark_target_monitor.rb"
    )
  end

  it "shows when the markdown route summary is truncated" do
    helpers = load_markdown_helpers(script_source)
    route = Struct.new(
      :route,
      :rps_delta_percent,
      :baseline_median_rps,
      :candidate_median_rps,
      :baseline_cv_percent,
      :candidate_cv_percent
    ).new("/foo", -12.3, 10.0, 8.77, 1.2, 3.4)
    output = StringIO.new

    helpers.write_markdown_section(
      output,
      "Largest Candidate RPS Regressions",
      { rows: [route], total_count: 2 }
    )

    expect(output.string).to include(
      "_Showing 1 of 2 routes. Full data is in `comparison_summary.json`._"
    )
  end

  it "rejects A/B refs that sanitize to the same scenario name" do
    _stdout, stderr, status = run_script("--a-ref", "feature/foo", "--b-ref", "feature-foo")

    expect(status).not_to be_success
    expect(stderr).to include("A/B scenario names must be distinct")
  end

  it "rejects baselines and candidates that do not match a scenario name" do
    _stdout, stderr, status = run_script(
      "--a-ref", "main",
      "--b-ref", "v17.0.0.rc.5",
      "--baseline", "rc5",
      "--candidate", "main"
    )

    expect(status).not_to be_success
    expect(stderr).to include("--baseline and --candidate must match scenario names")
  end
end

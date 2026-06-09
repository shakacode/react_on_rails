# frozen_string_literal: true

require "fileutils"
require "open3"

require_relative "bencher_report"
require_relative "github"

# Builds and runs the Bencher CLI invocation for benchmark tracking.
class BencherRunner
  class ReportParseError < StandardError; end

  Result = Struct.new(:stderr, :exit_code, :report, keyword_init: true)

  # Bencher dashboard project for React on Rails benchmark runs.
  PROJECT_SLUG = "react-on-rails-t8a9ncxo"
  MAX_SAMPLE = "64"
  # Per-measure t-test boundaries (the confidence level Bencher uses for its
  # prediction interval). Tuned from a sweep of recent main-branch reports so fewer
  # than 1/20 commits raise a false regression across all benchmarks: rps and p50
  # individually need ~0.9995 / ~0.9999 to clear that bar. failed_pct stays at 0.95
  # because healthy runs sit at ~0 with near-zero variance, so its boundary rarely
  # matters.
  # Bencher's t-test threshold is a prediction interval, so each one-sided boundary B
  # gives a per-test false-positive rate of ~(1 - B):
  # https://bencher.dev/docs/explanation/thresholds/
  # Direction: :lower for "regression = drop" measures (rps), :upper for
  # "regression = climb" measures (latency, failure rate).
  # p90/p99/max are intentionally NOT tracked: their tail noise can't meet the 1/20
  # target at any usable boundary. p90 stays in the summary table for visibility only.
  THRESHOLDS = [
    ["rps", :lower, "0.9995"],
    ["p50_latency", :upper, "0.9999"],
    ["failed_pct", :upper, "0.95"]
  ].freeze

  def initialize(benchmark_json:, report_json:)
    @benchmark_json = benchmark_json
    @report_json = report_json
  end

  def run(branch, start_point_args)
    stdout, stderr, status = Open3.capture3(*args(branch, start_point_args))
    warn stderr unless stderr.empty?
    report = persist_report(stdout)
    warn_on_missing_perf_link_context(report) if report
    Result.new(stderr:, exit_code: status.exitstatus, report:)
  end

  private

  attr_reader :benchmark_json, :report_json

  def threshold_args(measure, direction, boundary)
    # "_" is Bencher's sentinel for "no boundary on this side".
    lower, upper = direction == :lower ? [boundary, "_"] : ["_", boundary]
    [
      "--threshold-measure", measure,
      "--threshold-test", "t_test",
      "--threshold-max-sample-size", MAX_SAMPLE,
      "--threshold-lower-boundary", lower,
      "--threshold-upper-boundary", upper
    ]
  end

  def args(branch, start_point_args)
    [
      "bencher", "run",
      "--project", PROJECT_SLUG,
      "--branch", branch,
      *start_point_args,
      "--testbed", "github-actions",
      "--adapter", "json",
      "--file", benchmark_json,
      "--err",
      "--quiet",
      "--format", "json",
      *THRESHOLDS.flat_map { |measure, direction, boundary| threshold_args(measure, direction, boundary) }
    ]
  end

  # Writes Bencher stdout to disk, parses it, and returns the parsed report.
  # Parse failures remove only a report this run placed on disk, so stale JSON
  # from a prior successful run is not deleted by a write or move failure.
  def persist_report(stdout)
    if stdout.empty?
      FileUtils.rm_f(report_json)
      return nil
    end

    tmp_report_json = "#{report_json}.tmp"
    moved = false
    report_verified = false
    begin
      File.write(tmp_report_json, stdout)
      FileUtils.mv(tmp_report_json, report_json)
      moved = true
      parse_report(stdout).tap { report_verified = true }
    ensure
      FileUtils.rm_f(tmp_report_json)
      FileUtils.rm_f(report_json) if moved && !report_verified
    end
  end

  def parse_report(stdout)
    BencherReport.parse(stdout, tracked_measures: THRESHOLDS.map(&:first))
  rescue BencherReport::FormatError => e
    raise ReportParseError,
          "Bencher JSON report has an unexpected shape — re-verify against " \
          "benchmarks/spec/bencher_report_spec.rb before bumping the CLI pin. #{e.message}"
  end

  def warn_on_missing_perf_link_context(report)
    return unless report.perf_links_unavailable?

    Github.warning(
      "Bencher report listed benchmarks but no perf-link context " \
      "(project/branch/testbed uuid); benchmark names will render unlinked. Re-verify the " \
      "report shape against benchmarks/spec/bencher_perf_url_spec.rb before bumping the CLI pin."
    )
  end
end

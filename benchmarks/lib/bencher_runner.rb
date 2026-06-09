# frozen_string_literal: true

require "fileutils"
require "open3"

require_relative "bencher_report"
require_relative "github"

# Builds and runs the Bencher CLI invocation for benchmark tracking.
class BencherRunner
  class ReportParseError < StandardError; end
  class PersistenceError < RuntimeError; end

  Result = Struct.new(:stderr, :exit_code, :report, keyword_init: true)
  private_constant :Result

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

  # Returns a Result with :stderr, :exit_code, and :report accessors. The
  # private constant keeps callers from depending on the struct class name.
  def run(branch:, start_point_args:)
    # This Bencher CLI call is not wrapped in Timeout.timeout because that can leak
    # child processes. In CI it is bounded by the GitHub Actions job timeout for
    # .github/workflows/benchmark-suite.yml; the benchmark execution step has its
    # own narrower timeout-minutes before this reporting step runs.
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

  # Writes Bencher stdout to disk atomically (tmp -> mv), then parses it.
  # On write/move failure the prior report at report_json is left untouched.
  # Empty Bencher stdout removes any stale prior report because there is no new output to preserve.
  # On parse failure the newly-written malformed report is removed so a future
  # retry starts clean rather than re-posting garbage.
  def persist_report(stdout)
    if stdout.empty?
      FileUtils.rm_f(report_json)
      return nil
    end

    tmp_report_json = "#{report_json}.tmp"
    begin
      File.write(tmp_report_json, stdout)
      FileUtils.mv(tmp_report_json, report_json)
    rescue SystemCallError, IOError, RuntimeError => e
      raise PersistenceError, e.message
    ensure
      # Always runs. After a successful mv the tmp file is already renamed, so
      # rm_f is a no-op; if write or mv raised it performs the cleanup.
      begin
        FileUtils.rm_f(tmp_report_json)
      rescue StandardError => e
        Github.warning("Could not remove temporary Bencher report #{tmp_report_json}: #{e.message}")
      end
    end

    begin
      parse_report(stdout)
    rescue ReportParseError
      warn "::debug::Malformed Bencher output (first 300 chars): #{stdout.slice(0, 300).inspect}"
      # Remove malformed output so a future retry starts clean; the raw debugging
      # artifact is lost, but a bad report file is worse than no report file.
      FileUtils.rm_f(report_json)
      raise
    end
  end

  def parse_report(stdout)
    BencherReport.parse(stdout, tracked_measures: THRESHOLDS.map(&:first))
  rescue BencherReport::FormatError, JSON::ParserError => e
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

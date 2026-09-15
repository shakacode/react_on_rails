# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"

require_relative "bencher_report"
require_relative "github"

# Builds and runs the Bencher CLI invocation for benchmark tracking.
class BencherRunner
  class ReportParseError < StandardError; end
  class PersistenceError < StandardError; end

  Result = Struct.new(:stderr, :exit_code, :report, keyword_init: true)
  private_constant :Result

  # Bencher dashboard project for React on Rails benchmark runs.
  PROJECT_SLUG = "react-on-rails-t8a9ncxo"
  private_constant :PROJECT_SLUG
  # Bencher testbed: the runner/hardware identity that segments a benchmark's baseline
  # series. GitHub-hosted shared runners are the default. The local benchmark runner
  # (benchmarks/run-local-benchmark.rb, #4073) overrides this via BENCHER_TESTBED so its
  # dedicated-hardware (arm64) numbers build their own baseline instead of being compared
  # against — and polluting — the shared-runner series, whose values are not comparable
  # across different hardware.
  DEFAULT_TESTBED = "github-actions"
  private_constant :DEFAULT_TESTBED
  MAX_SAMPLE = "64" # String because it is passed verbatim as a CLI argument.
  private_constant :MAX_SAMPLE

  # Per-measure t-test boundaries (the confidence level Bencher uses for its
  # prediction interval), used by MODE :statistical — the local dedicated-hardware
  # trend runs (benchmarks/run-local-benchmark.rb, #4073). Tuned from a sweep of recent
  # main-branch reports so fewer than 1/20 commits raise a false regression across all
  # benchmarks: rps and p50 individually need ~0.9995 / ~0.9999 to clear that bar.
  # failed_pct stays at 0.95 because healthy runs sit at ~0 with near-zero variance,
  # so its boundary rarely matters.
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

  # Per-measure percentage boundaries, used by MODE :relative_head — the CI relative
  # continuous benchmarking comparison (#3492,
  # https://bencher.dev/docs/how-to/track-benchmarks/#relative-continuous-benchmarking).
  # The baseline is the base ref's results measured moments earlier ON THE SAME RUNNER
  # (a single sample on a per-run throwaway branch), so the boundary is a plain
  # percentage of that run: limit = baseline * (1 -/+ boundary). 0.25 (25%) follows the
  # Bencher how-to's example and stays deliberately loose while shared GitHub-hosted
  # runners are the testbed — same-runner comparison removes cross-runner variance, but
  # CPU contention can still move throughput within a job. Tighten once real runs show
  # the same-runner spread. Directions match THRESHOLDS (pinned by a spec).
  # failed_pct's healthy baseline is ~0, which makes its upper limit ~0 — effectively
  # "any newly-failing request alerts", the same strictness the t-test gave it.
  RELATIVE_THRESHOLDS = [
    ["rps", :lower, "0.25"],
    ["p50_latency", :upper, "0.25"],
    ["failed_pct", :upper, "0.25"]
  ].freeze

  # How each mode runs Bencher:
  #   :statistical       — t-test thresholds vs the branch's own history + --err
  #                        (local dedicated-hardware trend tracking; the default so
  #                        run-local-benchmark.rb keeps its behavior).
  #   :relative_baseline — no thresholds, no --err: just records the base ref's results
  #                        as the fresh same-runner baseline series.
  #   :relative_head     — percentage thresholds vs that baseline + --thresholds-reset
  #                        (so stale server-side threshold models never alert) + --err.
  MODES = %i[statistical relative_baseline relative_head].freeze

  def initialize(benchmark_json:, report_json:, mode: :statistical)
    unless MODES.include?(mode)
      raise ArgumentError, "unknown mode #{mode.inspect} (expected one of #{MODES.join(', ')})"
    end

    @benchmark_json = benchmark_json
    @report_json = report_json
    @mode = mode
  end

  # Returns a Result with :stderr, :exit_code, and :report accessors. The
  # private constant keeps callers from depending on the struct class name.
  # Raises PersistenceError on I/O failure, ReportParseError on malformed JSON output.
  def run(branch:, start_point_args:)
    # This Bencher CLI call is not wrapped in Timeout.timeout because that can leak
    # child processes. In CI it is bounded by the GitHub Actions job timeout for
    # .github/workflows/benchmark-suite.yml; the benchmark execution step has its
    # own narrower timeout-minutes before this reporting step runs.
    stdout, stderr, status = Open3.capture3(*args(branch, start_point_args))
    emit_stderr(stderr)
    report = persist_report(stdout)
    warn_on_missing_perf_link_context(report) if report
    Result.new(stderr:, exit_code: status.exitstatus, report:)
  end

  private

  attr_reader :benchmark_json, :report_json, :mode

  def emit_stderr(stderr)
    return if stderr.empty?

    warn stderr
  end

  # The Bencher testbed to report under. BENCHER_TESTBED lets the local benchmark runner
  # (benchmarks/run-local-benchmark.rb, #4073) build its own baseline series; unset everywhere
  # else, so the GitHub-hosted runs keep reporting to the shared default testbed.
  def testbed
    ENV.fetch("BENCHER_TESTBED", DEFAULT_TESTBED)
  end

  def threshold_args(test, measure, direction, boundary)
    # "_" is Bencher's sentinel for "no boundary on this side".
    lower, upper = direction == :lower ? [boundary, "_"] : ["_", boundary]
    [
      "--threshold-measure", measure,
      "--threshold-test", test,
      # A percentage boundary is computed from the (single-sample) baseline directly,
      # so the sample-size cap only applies to the t-test's history window.
      *(test == "t_test" ? ["--threshold-max-sample-size", MAX_SAMPLE] : []),
      "--threshold-lower-boundary", lower,
      "--threshold-upper-boundary", upper
    ]
  end

  def mode_args
    case mode
    when :relative_baseline
      # The baseline run only records data; it must never gate the job, so no
      # thresholds and no --err (any non-zero exit is operational, handled by callers).
      []
    when :relative_head
      [
        "--err",
        # Deactivate any threshold not (re)specified here so an orphaned server-side
        # model (e.g. from the earlier statistical setup) can't raise a stray alert.
        "--thresholds-reset",
        *RELATIVE_THRESHOLDS.flat_map do |measure, direction, boundary|
          threshold_args("percentage", measure, direction, boundary)
        end
      ]
    else
      [
        "--err",
        *THRESHOLDS.flat_map { |measure, direction, boundary| threshold_args("t_test", measure, direction, boundary) }
      ]
    end
  end

  def args(branch, start_point_args)
    [
      "bencher", "run",
      "--project", PROJECT_SLUG,
      "--branch", branch,
      *start_point_args,
      "--testbed", testbed,
      "--adapter", "json",
      "--file", benchmark_json,
      "--quiet",
      "--format", "json",
      *mode_args
    ]
  end

  # Writes Bencher stdout to disk atomically (tmp -> mv), then parses it.
  # On write/move failure the prior report at report_json is left untouched.
  # Empty Bencher stdout removes any stale prior report because there is no new output to preserve.
  # On parse failure the newly-written malformed report is removed so a future
  # retry starts clean rather than re-posting garbage.
  def persist_report(stdout)
    if stdout.empty?
      begin
        FileUtils.rm_f(report_json)
      rescue SystemCallError, IOError => e
        raise PersistenceError,
              "#{e.message} (Bencher produced no output; see stderr above for the run failure)"
      end
      return nil
    end

    tmp_report_json = "#{report_json}.tmp"
    begin
      File.write(tmp_report_json, stdout)
      FileUtils.mv(tmp_report_json, report_json)
    rescue SystemCallError, IOError => e
      raise PersistenceError, e.message
    ensure
      # Always runs, including for exceptions that bypass the rescue block. After a successful mv the tmp
      # file no longer exists, so rm_f is a no-op; if write or mv raised it performs the cleanup.
      safe_remove_tmp(tmp_report_json)
    end

    parse_and_cleanup_report(stdout)
  end

  def parse_and_cleanup_report(stdout)
    parse_report(stdout)
  rescue ReportParseError
    Github.debug("Malformed Bencher output (first 300 chars): #{stdout.slice(0, 300).inspect}")
    # Only ReportParseError is cleaned up here. Unexpected parser bugs should propagate unchanged.
    # Remove malformed output so a future retry starts clean; the raw debugging
    # artifact is lost, but a bad report file is worse than no report file.
    begin
      FileUtils.rm_f(report_json)
    rescue StandardError => e
      Github.warning("Could not remove malformed Bencher report #{report_json}: #{e.message}")
    end
    raise
  end

  def parse_report(stdout)
    BencherReport.parse(stdout, tracked_measures:)
  rescue BencherReport::FormatError, JSON::ParserError => e
    raise ReportParseError,
          "Bencher JSON report has an unexpected shape — re-verify against " \
          "benchmarks/spec/bencher_report_spec.rb before bumping the CLI pin. #{e.message}"
  end

  # The measures this mode alerts on, for filtering orphaned server-side thresholds
  # out of regression detection. A baseline run configures no thresholds, so it can't
  # alert at all — nil (track everything) keeps its report parsing permissive.
  def tracked_measures
    case mode
    when :relative_baseline then nil
    when :relative_head then RELATIVE_THRESHOLDS.map(&:first)
    else THRESHOLDS.map(&:first)
    end
  end

  def safe_remove_tmp(path)
    FileUtils.rm_f(path)
  rescue StandardError => e
    # Cleanup failures are non-fatal, so keep this broader than the persistence rescue.
    Github.warning("Could not remove temporary Bencher report #{path}: #{e.message}")
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

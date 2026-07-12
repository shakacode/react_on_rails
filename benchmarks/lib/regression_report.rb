# frozen_string_literal: true

# Shared payload contract for regression hand-offs. Hosted automatic regression
# confirmation/reporting is intentionally disabled; these shapes remain covered so a
# future dedicated-runner confirmation path can reuse the same candidate/confirmed
# payloads without re-inventing the alert matching contract.
module RegressionReport
  module_function

  # Hand-off filenames. Distinct basenames (not just distinct artifact names) so a
  # confirmed glob can never accidentally pick up a candidate and vice versa.
  CANDIDATE_FILENAME = "regression-candidate.json"
  CONFIRMED_FILENAME = "regression-confirmed.json"

  # Payload keys shared by candidate and confirmed payloads.
  SUITE_NAME = "suite_name"
  SHARD_LABEL = "shard_label"
  # The benchmark names Bencher raised an active alert for, deduped. Drives the
  # IGNORED_REGRESSION_BENCHMARKS short-circuit (name-based) and is shown in the issue.
  REGRESSED_BENCHMARKS = "regressed_benchmarks"
  # Structured alert identifiers: an array of { ALERT_BENCHMARK, ALERT_MEASURE } so the
  # confirmation run can require the SAME benchmark+measure pair to re-alert, not just
  # any alert in the suite. measure may be null (Bencher omitted it); see #alerts_match?.
  ALERTS = "alerts"
  ALERT_BENCHMARK = "benchmark"
  ALERT_MEASURE = "measure"

  # Candidate-only: the first run's rendered summary table.
  SUMMARY = "summary"

  # Confirmed-only: the first-run table and the confirmation-run table, kept distinct so
  # the issue can show both numbers side by side (the comparison is the evidence).
  FIRST_RUN_SUMMARY = "first_run_summary"
  CONFIRMATION_SUMMARY = "confirmation_summary"

  # Benchmarks whose regressions must NOT open an issue, by the exact benchmark name
  # Bencher reports (the leading-slash name shown in the summary table, matched against
  # REGRESSED_BENCHMARKS in each suite's payload). Entries here are TEMPORARY
  # suppressions for any future confirmation/reporting path. Empty means no benchmark is
  # suppressed. Any entry added here must have a tracking issue stating the revert
  # criteria.
  IGNORED_REGRESSION_BENCHMARKS = [].freeze

  # Build a structured alert hash for the ALERTS payload key.
  def alert(benchmark, measure)
    { ALERT_BENCHMARK => benchmark, ALERT_MEASURE => measure }
  end

  # Normalize a measure key the same way BencherReport does (slug vs name, dashes vs
  # underscores, case) so "p50-latency" and "p50_latency" compare equal.
  def normalize_measure(measure)
    return nil if measure.nil?

    measure.to_s.downcase.gsub(/[-\s]+/, "_")
  end

  # Do two alerts identify the same regression? Same benchmark is required. Measures
  # must match when both are present; if EITHER side omitted the measure (Bencher's
  # alert payload is read leniently, so measure can be nil), fall back to matching on
  # the benchmark name alone — the explicitly-allowed fallback when measure-level alert
  # data is not available (see the issue's "Match the same benchmark+measure").
  def alerts_match?(left, right)
    return false unless left[ALERT_BENCHMARK] == right[ALERT_BENCHMARK]

    left_measure = normalize_measure(left[ALERT_MEASURE])
    right_measure = normalize_measure(right[ALERT_MEASURE])
    left_measure.nil? || right_measure.nil? || left_measure == right_measure
  end

  # The candidate alerts that re-alerted in the confirmation run (same benchmark+measure
  # pair). This is the set the confirmation publishes as confirmed.
  def confirmed_alerts(candidate_alerts, confirmation_alerts)
    candidate_alerts.select do |candidate|
      confirmation_alerts.any? { |confirmation| alerts_match?(candidate, confirmation) }
    end
  end

  def ignored_benchmark?(name)
    IGNORED_REGRESSION_BENCHMARKS.include?(name)
  end

  # Alerts whose benchmark is NOT temporarily ignored — the ones worth confirming and
  # reporting. An ignored benchmark never reaches a confirmation rerun or the issue.
  def actionable_alerts(alerts)
    alerts.reject { |entry| ignored_benchmark?(entry[ALERT_BENCHMARK]) }
  end

  # The regressed benchmark names not in the ignore-list. Empty => every regressed
  # benchmark is ignored, so the suite/shard short-circuits (no rerun, no issue).
  def actionable_benchmarks(regressed_benchmarks)
    Array(regressed_benchmarks).reject { |name| ignored_benchmark?(name) }
  end
end

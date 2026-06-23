# frozen_string_literal: true

module TrackBenchmarks
  # Writes the first-run candidate and confirmed-regression hand-off payloads.
  module RegressionPayloads
    module_function

    def main_push?(env: ENV)
      env.fetch("GITHUB_EVENT_NAME") == "push" && env.fetch("GITHUB_REF") == "refs/heads/main"
    end

    # A main-push Bencher alert is now a NON-FATAL candidate: the gate/confirmation jobs
    # rerun the alerting suite/shard on a fresh runner and only file the issue if the SAME
    # benchmark+measure re-alerts, so write the candidate hand-off and exit 0 — the
    # report-regressions job owns the final pass/fail. (A lost hand-off is the one case we
    # still fail the suite, rather than silently drop the regression.) A non-zero exit with
    # NO alert is an operational failure, not a regression, and still fails the suite.
    def report_main_push_candidate(report, report_markdown, bencher_exit_code, suite_name)
      if Summary.regression?(report)
        exit 1 unless write_candidate(report, report_markdown, suite_name)
      else
        warn "::error::Bencher exited #{bencher_exit_code} on main with no regression alert for " \
             "#{suite_name}; this indicates an operational failure (auth/API/network/CLI), not a " \
             "performance regression. Check the logs above."
        exit bencher_exit_code
      end
    end

    # Write the non-fatal first-run candidate for the gate/confirmation jobs. Records the
    # structured alert pairs so the confirmation rerun can require the SAME pair(s) to
    # re-alert, plus the un-sharded suite name (so a suite's shards combine downstream) and
    # the rendered summary. Returns true on success; false means the hand-off was lost, so
    # the caller fails the suite rather than silently dropping the regression.
    def write_candidate(report, report_markdown, suite_name, path: Config::CANDIDATE_REPORT_JSON, env: ENV)
      File.write(
        path,
        JSON.generate(
          RegressionReport::SUITE_NAME => env.fetch("BENCHMARK_SUITE_GROUP", suite_name),
          RegressionReport::SHARD_LABEL => env.fetch("BENCHMARK_SHARD_LABEL", ""),
          RegressionReport::SUMMARY => Summary.regression_handoff_summary(report_markdown),
          RegressionReport::REGRESSED_BENCHMARKS => Summary.regressed_benchmark_names(report),
          RegressionReport::ALERTS => Summary.regressed_alert_pairs(report)
        )
      )
      Github.notice(
        "Bencher flagged a #{suite_name} regression CANDIDATE on main. It is non-fatal until a " \
        "fresh-runner confirmation rerun re-alerts on the same benchmark+measure. " \
        "See the Bencher dashboard and the workflow run: #{Github.run_url}"
      )
      true
    rescue StandardError => e
      warn "::error::Bencher flagged a #{suite_name} regression candidate on main but its payload " \
           "could not be written (#{e.class}: #{e.message}); confirmation cannot run and the issue will " \
           "NOT be auto-filed — investigate using GitHub run logs: #{Github.run_url}"
      false
    end

    # Write the confirmed hand-off for report-regressions: the first run and confirmation
    # summaries side by side (the comparison is the evidence) and the confirmed alert pairs.
    def write_confirmed(confirmed_alerts, first_run_summary, confirmation_markdown, suite_name,
                        path: Config::CONFIRMED_REPORT_JSON, env: ENV)
      File.write(
        path,
        JSON.generate(
          RegressionReport::SUITE_NAME => env.fetch("BENCHMARK_SUITE_GROUP", suite_name),
          RegressionReport::SHARD_LABEL => env.fetch("BENCHMARK_SHARD_LABEL", ""),
          RegressionReport::FIRST_RUN_SUMMARY => first_run_summary,
          RegressionReport::CONFIRMATION_SUMMARY => confirmation_markdown,
          RegressionReport::ALERTS => confirmed_alerts,
          RegressionReport::REGRESSED_BENCHMARKS =>
            confirmed_alerts.filter_map { |alert| alert[RegressionReport::ALERT_BENCHMARK] }.uniq
        )
      )
      true
    rescue StandardError => e
      warn "::error::A #{suite_name} regression was confirmed on a fresh runner but its payload " \
           "could not be written (#{e.class}: #{e.message}); the issue will NOT be auto-filed — " \
           "investigate using GitHub run logs: #{Github.run_url}"
      false
    end
  end
end

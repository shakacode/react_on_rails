# frozen_string_literal: true

module TrackBenchmarks
  # Writes the first-run candidate and confirmed-regression hand-off payloads.
  module RegressionPayloads
    module_function

    def main_push?(env: ENV)
      env.fetch("GITHUB_EVENT_NAME") == "push" && env.fetch("GITHUB_REF") == "refs/heads/main"
    end

    # A main-push Bencher alert was treated as a non-fatal candidate by the retired hosted
    # confirmation pipeline. Keep the payload writer covered for a future dedicated-runner
    # confirmation path; a non-zero exit with no alert is still an operational failure.
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

    # Write the non-fatal first-run candidate. Records the structured alert pairs so a
    # future confirmation rerun can require the SAME pair(s) to re-alert, plus the
    # un-sharded suite name and rendered summary. Returns true on success; false means the
    # hand-off was lost.
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

    # Write the confirmed hand-off: the first run and confirmation summaries side by side
    # (the comparison is the evidence) and the confirmed alert pairs.
    def write_confirmed(confirmed_alerts, first_run_summary, confirmation_markdown, suite_name,
                        path: Config::CONFIRMED_REPORT_JSON, env: ENV)
      File.write(
        path,
        JSON.generate(
          RegressionReport::SUITE_NAME => env.fetch("BENCHMARK_SUITE_GROUP", suite_name),
          RegressionReport::SHARD_LABEL => env.fetch("BENCHMARK_SHARD_LABEL", ""),
          RegressionReport::FIRST_RUN_SUMMARY => first_run_summary,
          RegressionReport::CONFIRMATION_SUMMARY =>
            Summary.regression_handoff_summary(confirmation_markdown, failure_context: "during confirmation"),
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

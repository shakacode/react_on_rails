# frozen_string_literal: true

module TrackBenchmarks
  # Confirmation-rerun classification and hand-off.
  module Confirmation
    module_function

    # Read the downloaded first-run candidate (found by recursive glob under dir): its
    # structured alerts and rendered summary. Returns [nil, ""] when the payload is
    # missing/corrupt so the caller can treat the confirmation as inconclusive (an
    # operational failure) rather than silently clearing it.
    def load_candidate(dir)
      path = Dir.glob(File.join(dir, "**", RegressionReport::CANDIDATE_FILENAME)).first
      unless path
        warn "::error::No confirmation candidate (#{RegressionReport::CANDIDATE_FILENAME}) found under " \
             "#{dir}; treating the confirmation as inconclusive."
        return [nil, ""]
      end

      parsed = JSON.parse(File.read(path))
      unless parsed.is_a?(Hash)
        warn "::error::Confirmation candidate #{path} is not a JSON object (got #{parsed.class}); " \
             "treating the confirmation as inconclusive."
        return [nil, ""]
      end

      alerts = parsed[RegressionReport::ALERTS]
      unless alerts.is_a?(Array) && !alerts.empty?
        warn "::error::Confirmation candidate #{path} has empty or missing " \
             "#{RegressionReport::ALERTS}; treating the confirmation as inconclusive."
        return [nil, parsed[RegressionReport::SUMMARY].to_s]
      end

      [alerts, parsed[RegressionReport::SUMMARY].to_s]
    rescue StandardError => e
      warn "::error::Could not read confirmation candidate #{path} (#{e.class}: #{e.message}); " \
           "treating the confirmation as inconclusive."
      [nil, ""]
    end

    # Classify a confirmation rerun. Pure so it is unit-testable.
    #   :inconclusive — no parseable report, or a non-zero exit with no alert (operational
    #                   failure: auth/API/network/CLI). Must fail the workflow, file nothing.
    #   :cleared      — the report parsed but none of the candidate's (non-ignored) alerts
    #                   re-alerted. The first run was noise.
    #   :confirmed    — the same benchmark+measure pair(s) re-alerted; returns just those.
    # Ignored benchmarks are dropped from the candidate side first so a confirmation can
    # never be carried by a benchmark we would suppress anyway.
    def outcome(report, bencher_exit_code, candidate_alerts)
      return [:inconclusive, []] if report.nil?
      return [:inconclusive, []] if bencher_exit_code != 0 && !Summary.regression?(report)

      confirmed = RegressionReport.confirmed_alerts(
        RegressionReport.actionable_alerts(candidate_alerts),
        Summary.regressed_alert_pairs(report)
      )
      return [:cleared, []] if confirmed.empty?

      [:confirmed, confirmed]
    end

    # Human-readable "benchmark (measure)" for the workflow summary / logs.
    def describe_alert(alert)
      benchmark = alert[RegressionReport::ALERT_BENCHMARK]
      measure = alert[RegressionReport::ALERT_MEASURE]
      measure ? "#{benchmark} (#{measure})" : benchmark
    end

    # State the confirmation outcome in the workflow run summary (acceptance criterion:
    # every first-run alert is visibly confirmed, cleared as noise, or inconclusive).
    def append_summary(status, confirmed_alerts, suite_name)
      body =
        case status
        when :confirmed
          lines = confirmed_alerts.map { |alert| "- #{describe_alert(alert)}" }.join("\n")
          "## #{suite_name} confirmation: ✅ CONFIRMED\n\n" \
            "These first-run alerts re-alerted on a fresh runner (re-tested against main's " \
            "baseline) and will be reported:\n\n#{lines}\n\n"
        when :cleared
          "## #{suite_name} confirmation: 🟢 CLEARED (noise)\n\n" \
          "The first-run alert(s) did not re-alert on a fresh runner. No issue will be filed.\n\n"
        else
          "## #{suite_name} confirmation: ⚠️ INCONCLUSIVE\n\n" \
          "The confirmation rerun could not be evaluated (benchmark execution or Bencher " \
          "reporting failed). Treated as an operational failure; no issue will be filed.\n\n"
        end
      Summary.append_step_summary(body)
    end

    # The confirmation rerun (BENCHMARK_MODE=confirm). Owns its own exit code:
    #   confirmed   -> write the confirmed hand-off, exit 0 (report-regressions fails the run)
    #   cleared     -> exit 0 (the first-run alert was noise)
    #   inconclusive-> exit 1 (operational failure: fail the workflow, file nothing)
    def run(report, bencher_exit_code, confirmation_markdown, suite_name)
      candidate_alerts, first_run_summary = load_candidate(Config::CANDIDATE_INPUT_DIR)
      # A missing/corrupt candidate is an operational failure, not a cleared alert.
      return finish(:inconclusive, [], suite_name) if candidate_alerts.nil?

      status, confirmed_alerts = outcome(report, bencher_exit_code, candidate_alerts)
      if status == :confirmed &&
         !RegressionPayloads.write_confirmed(confirmed_alerts, first_run_summary, confirmation_markdown, suite_name)
        # The regression confirmed but its hand-off was lost: fail rather than drop it.
        return finish(:inconclusive, [], suite_name)
      end

      finish(status, confirmed_alerts, suite_name)
    end

    def finish(status, confirmed_alerts, suite_name)
      append_summary(status, confirmed_alerts, suite_name)
      case status
      when :confirmed
        Github.notice("Confirmed #{confirmed_alerts.size} #{suite_name} regression alert(s) on a fresh runner.")
        exit 0
      when :cleared
        Github.notice("Cleared #{suite_name} first-run alert(s) as noise; no re-alert on the fresh runner.")
        exit 0
      else
        warn "::error::#{suite_name} confirmation rerun was inconclusive (operational failure); " \
             "failing the workflow without filing an issue. Investigate: #{Github.run_url}"
        exit 1
      end
    end
  end
end

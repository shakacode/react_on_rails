# frozen_string_literal: true

module TrackBenchmarks
  # Bencher execution helpers and exit-code classification.
  module BencherRun
    module_function

    def run_bencher!(runner, branch, start_point_args)
      # The bang means this script helper exits the process on an untriageable
      # Bencher report shape, matching the surrounding top-level script helpers.
      runner.run(branch:, start_point_args:)
    rescue BencherRunner::ReportParseError => e
      warn "::error::#{e.message}"
      exit 1
    rescue BencherRunner::PersistenceError => e
      warn "::error::Benchmark report persistence failed: #{e.message}"
      exit 1
    end

    def normalized_exit_code(exit_code, report)
      return exit_code if exit_code.zero? || report.nil? || Summary.regression?(report)
      return exit_code unless report.filtered_alert? || report.unconfirmed_alert?

      Github.notice(
        "Bencher alert(s) were all stale or unconfirmed across samples; " \
        "no current boundary-backed regression remains."
      )
      0
    end
  end
end

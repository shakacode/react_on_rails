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
      return exit_code unless exit_code != 0 && report&.filtered_alert? && !Summary.regression?(report)

      Github.notice("Bencher reported only stale active alert(s); no current boundary-backed regression remains.")
      0
    end
  end
end

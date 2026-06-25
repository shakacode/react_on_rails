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

    # A missing start-point baseline (operational, not a regression): retrying without
    # the start-point hash falls back to the latest baseline. The no-regression guard is
    # load-bearing — a real regression must not be silently re-run against a different
    # baseline. The stderr match detects the operational error, not an alert.
    def retry_without_start_point_hash?(stderr, exit_code, report)
      exit_code != 0 &&
        stderr.match?(/Head Version.*not found/) &&
        !Summary.regression?(report)
    end

    def without_start_point_hash(start_point_args)
      retry_args = start_point_args.dup
      if (hash_arg_index = retry_args.index("--start-point-hash"))
        retry_args.slice!(hash_arg_index, 2)
      end
      retry_args
    end
  end
end

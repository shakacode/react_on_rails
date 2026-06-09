#!/usr/bin/env ruby
# frozen_string_literal: true

# The confirmation gate. Runs once after the initial benchmark matrix on a main push,
# reads every first-run regression CANDIDATE (see track_benchmarks.rb / regression_report.rb),
# and decides which suite/shard(s) to rerun on fresh runners before any issue is filed.
#
# It does two things:
#   1. Short-circuits the IGNORED_REGRESSION_BENCHMARKS list BEFORE spending a rerun: a
#      candidate whose only regressed benchmarks are ignored is dropped (no fresh-runner
#      rerun, no issue), surfaced as a workflow notice.
#   2. Emits a GitHub Actions matrix of just the alerting suite/shard rows (verbatim from
#      the original benchmark matrix, so the confirmation job can run them identically)
#      plus a has_confirmations flag the confirmation job gates on.
#
# A missing/corrupt candidate, or a candidate that matches no matrix row, is an
# operational failure: the gate exits non-zero (the workflow goes red) and emits no
# confirmations, so report-regressions files nothing. That matches the issue's
# "inconclusive confirmation fails the workflow without filing an issue."
#
# Usage: ruby benchmarks/plan_confirmation.rb <candidate-artifacts-dir>
#   env BENCHMARK_MATRIX = the benchmark matrix JSON ({ "include": [ ...rows... ] })

require "json"

require_relative "lib/github"
require_relative "lib/regression_report"

def candidate_payload_paths(artifacts_dir)
  Dir.glob(File.join(artifacts_dir, "**", RegressionReport::CANDIDATE_FILENAME))
end

def load_candidate_payload(path)
  parsed = JSON.parse(File.read(path))
  required_keys = [RegressionReport::SUITE_NAME, RegressionReport::SHARD_LABEL]
  unless parsed.is_a?(Hash) && required_keys.all? { |key| parsed.key?(key) }
    raise "expected a JSON object with #{required_keys.join(', ')}"
  end

  parsed
rescue StandardError => e
  warn "::error::Failed to read regression candidate #{path}: #{e.class}: #{e.message}"
  nil
end

# Every regressed benchmark this candidate named is ignored — drop it (no rerun, no
# issue). When the candidate named NO benchmarks (older writer / hand-off that couldn't
# name them) we cannot suppress what we cannot name, so fall through and confirm it.
def fully_ignored?(regressed_benchmarks)
  names = Array(regressed_benchmarks)
  !names.empty? && RegressionReport.actionable_benchmarks(names).empty?
end

def matrix_row_key(suite_name, shard_label)
  [suite_name.to_s, shard_label.to_s]
end

# Decide the confirmation plan from the candidate payloads and the benchmark matrix.
# Returns a hash:
#   confirm_rows: matrix rows (verbatim) to rerun on fresh runners
#   suppressed:   ignored benchmark names that short-circuited (for the notice)
#   unmatched:    [suite_name, shard_label] candidates with no matrix row (operational bug)
def build_plan(payloads, matrix_rows)
  rows_by_key = matrix_rows.each_with_object({}) do |row, index|
    index[matrix_row_key(row["suite_name"], row["shard_label"])] = row
  end

  confirm_rows = {}
  suppressed = []
  unmatched = []

  payloads.each do |payload|
    regressed = payload[RegressionReport::REGRESSED_BENCHMARKS]
    if fully_ignored?(regressed)
      suppressed.concat(Array(regressed) & RegressionReport::IGNORED_REGRESSION_BENCHMARKS)
      next
    end

    key = matrix_row_key(payload[RegressionReport::SUITE_NAME], payload[RegressionReport::SHARD_LABEL])
    row = rows_by_key[key]
    if row.nil?
      unmatched << key
    else
      confirm_rows[key] = row
    end
  end

  { confirm_rows: confirm_rows.values, suppressed: suppressed.uniq, unmatched: }
end

def benchmark_matrix_rows
  raw = ENV.fetch("BENCHMARK_MATRIX", "")
  return [] if raw.empty?

  parsed = JSON.parse(raw)
  rows = parsed.is_a?(Hash) ? parsed["include"] : nil
  rows.is_a?(Array) ? rows : []
rescue JSON::ParserError => e
  warn "::error::BENCHMARK_MATRIX is not valid JSON: #{e.message}"
  []
end

def set_output(name, value)
  path = ENV.fetch("GITHUB_OUTPUT", nil)
  File.write(path, "#{name}=#{value}\n", mode: "a") if path && !path.empty?
  puts "#{name}=#{value}"
end

def emit_no_confirmations
  set_output("has_confirmations", "false")
  set_output("confirmation_matrix", JSON.generate(include: []))
end

def emit_confirmations(rows)
  described = rows.map { |row| row["bencher_suite_name"] || row["suite_name"] }.join(", ")
  puts "Scheduling confirmation reruns for: #{described}"
  set_output("has_confirmations", "true")
  set_output("confirmation_matrix", JSON.generate(include: rows))
end

def announce_suppressed(suppressed)
  return if suppressed.empty?

  Github.notice(
    "Skipped confirmation for temporarily-ignored benchmark(s) (#{suppressed.join(', ')}); " \
    "no rerun and no issue. Remove IGNORED_REGRESSION_BENCHMARKS in benchmarks/lib/regression_report.rb " \
    "once their Bencher baseline recovers."
  )
end

def warn_unmatched(unmatched)
  described = unmatched.map { |suite, shard| "#{suite} (#{shard})" }.join(", ")
  warn "::error::Regression candidate(s) #{described} matched no benchmark matrix row, so they " \
       "cannot be rerun. Treating confirmation as inconclusive and failing the workflow without filing."
end

# Returns true on success (outputs emitted), false on an operational failure that must
# fail the workflow without filing anything.
def plan_confirmation(artifacts_dir)
  paths = candidate_payload_paths(artifacts_dir)
  if paths.empty?
    puts "No benchmark regression candidates were reported by any suite."
    emit_no_confirmations
    return true
  end

  payloads = paths.map { |path| load_candidate_payload(path) }
  if payloads.any?(&:nil?)
    warn "::error::One or more regression candidates were unreadable; treating confirmation as " \
         "inconclusive and failing the workflow without filing an issue."
    emit_no_confirmations
    return false
  end

  plan = build_plan(payloads, benchmark_matrix_rows)
  announce_suppressed(plan[:suppressed])

  # Confirmation is all-or-nothing: if any candidate cannot be mapped back to a
  # suite/shard, filing a partial issue could hide a real regression elsewhere.
  unless plan[:unmatched].empty?
    warn_unmatched(plan[:unmatched])
    emit_no_confirmations
    return false
  end

  if plan[:confirm_rows].empty?
    puts "All regression candidates were temporarily ignored; nothing to confirm."
    emit_no_confirmations
    return true
  end

  emit_confirmations(plan[:confirm_rows])
  true
end

if __FILE__ == $PROGRAM_NAME
  artifacts_dir = ARGV.fetch(0, "candidate-artifacts")
  exit 1 unless plan_confirmation(artifacts_dir)
end

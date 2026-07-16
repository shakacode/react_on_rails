#!/usr/bin/env ruby
# frozen_string_literal: true

# Emits the GitHub Actions matrix `include:` payload for benchmark suites.
# Stdlib-only so the workflow can invoke it with the runner's system Ruby — no
# Bundler, no Rails boot.

require "json"

MIN_ROUTES_FOR_SHARDING = 10

SUITES = [
  {
    id: "core",
    suite_name: "Core",
    suite_prefix: "CORE",
    shard_total: 1,
    app_versions: %w[both core_only],
    labels: %w[benchmark benchmark-core],
    app_directory: "react_on_rails/spec/dummy",
    artifact_name: "benchmark-core-results",
    benchmark_tool: "k6",
    benchmark_script: "benchmarks/bench.rb",
    benchmark_timeout_minutes: 120,
    pro_env: false,
    generate_packs: false,
    server_kind: "rails",
    summary_file: "bench_results/summary.txt",
    summary_title: "Summary"
  },
  {
    id: "pro",
    suite_name: "Pro",
    suite_prefix: "PRO",
    shard_total: 2,
    app_versions: %w[both pro_only pro_rails_only],
    labels: %w[benchmark benchmark-pro],
    app_directory: "react_on_rails_pro/spec/dummy",
    artifact_name: "benchmark-pro-results",
    benchmark_tool: "k6",
    benchmark_script: "benchmarks/bench.rb",
    benchmark_timeout_minutes: 120,
    pro_env: true,
    generate_packs: true,
    server_kind: "rails",
    summary_file: "bench_results/summary.txt",
    summary_title: "Rails Benchmark Summary"
  },
  {
    id: "pro-node-renderer",
    suite_name: "Pro Node Renderer",
    suite_prefix: "PRO_NODE_RENDERER",
    shard_total: 1,
    app_versions: %w[both pro_only pro_node_renderer_only],
    labels: %w[benchmark benchmark-pro benchmark-pro-node-renderer],
    app_directory: "react_on_rails_pro/spec/dummy",
    artifact_name: "benchmark-pro-node-renderer-results",
    benchmark_tool: "vegeta",
    report_marker: "<!-- BENCHER_REPORT_PRO_NODE_RENDERER -->",
    benchmark_script: "benchmarks/bench-node-renderer.rb",
    benchmark_timeout_minutes: 30,
    pro_env: false,
    generate_packs: true,
    server_kind: "node-renderer",
    summary_file: "bench_results/node_renderer_summary.txt",
    summary_title: "Node Renderer Benchmark Summary"
  }
].freeze

# Every app_version any suite accepts. The workflow_dispatch input is constrained
# to these, but validating guards against a typo or future rename silently
# selecting no suites (which would skip benchmarks while CI stays green).
VALID_APP_VERSIONS = SUITES.flat_map { |suite| suite.fetch(:app_versions) }.uniq.freeze

# A PR label that forces every benchmark suite OFF for this run, even when a
# suite-specific or broad `benchmark` label would otherwise select suites (PRs are
# already opt-in, so this is the override for an explicit benchmark label). This is
# the "hosted CI but skip benchmarks" escape hatch: use it on PRs that carry a
# benchmark label but cannot move runtime performance -- CI plumbing, lint/config,
# or tooling -- so Bencher does not record a meaningless run (the #3919 / #3855
# class of spurious runs). Honored from forks too: it only ever turns benchmarks
# off, so there is no fork-safety concern.
BENCHMARK_SUPPRESS_LABEL = "hosted-ci-no-benchmarks"

def truthy_env?(name)
  ENV.fetch(name, "false") == "true"
end

def pull_request_labels
  raw_labels = ENV.fetch("BENCHMARK_PULL_REQUEST_LABELS", "[]")
  return [] if raw_labels.empty?

  parsed = JSON.parse(raw_labels)
  parsed.is_a?(Array) ? parsed : []
rescue JSON::ParserError => e
  raise "BENCHMARK_PULL_REQUEST_LABELS must be JSON array: #{e.message}"
end

def suite_requested_by_event?(_suite, _labels)
  event_name = ENV.fetch("BENCHMARK_EVENT_NAME")

  return true if event_name == "workflow_dispatch"

  # Shared GitHub-hosted runners are too noisy for a trusted Bencher trend. The
  # automatic push/PR paths are intentionally disabled; dedicated local hardware
  # uploads the real trend via benchmarks/run-local-benchmark.rb. Keep workflow_dispatch
  # as an explicit hosted diagnostic escape hatch only.
  false
end

def suite_selected_by_input?(suite)
  app_version = ENV.fetch("BENCHMARK_APP_VERSION", "both")
  unless VALID_APP_VERSIONS.include?(app_version)
    raise "BENCHMARK_APP_VERSION must be one of #{VALID_APP_VERSIONS.join(', ')} (got #{app_version.inspect})"
  end

  suite.fetch(:app_versions).include?(app_version)
end

def suite_enabled?(suite, labels)
  suite_selected_by_input?(suite) && suite_requested_by_event?(suite, labels)
end

def explicit_routes
  ENV.fetch("BENCHMARK_ROUTES", "").split(",").map(&:strip).reject(&:empty?)
end

def shard_total_for_suite(suite)
  configured_shard_total = suite.fetch(:shard_total)
  explicit_route_count = explicit_routes.length

  return configured_shard_total if explicit_route_count.zero?
  return 1 if explicit_route_count < MIN_ROUTES_FOR_SHARDING

  [configured_shard_total, explicit_route_count].min
end

def suite_rows(suite)
  shard_total = shard_total_for_suite(suite)
  raise "#{suite.fetch(:id)} shard_total must be positive (got #{shard_total})" unless shard_total.positive?

  Array.new(shard_total) do |index|
    shard_number = index + 1
    shard_label = "#{shard_number}/#{shard_total}"
    shard_slug = "shard-#{shard_number}-of-#{shard_total}"
    suite_name = suite.fetch(:suite_name)
    suite_prefix = suite.fetch(:suite_prefix)

    suite_row(suite, suite_name,
              shard_index: index,
              shard_total:,
              shard_label:,
              report_marker: report_marker(suite, suite_prefix, shard_slug),
              artifact_name_suffix: artifact_name_suffix(shard_total, shard_slug))
  end
end

def suite_row(suite, suite_name, shard_index:, shard_total:, shard_label:, report_marker:, artifact_name_suffix:)
  {
    suite_id: suite.fetch(:id),
    suite_name:,
    job_name: benchmark_job_name(suite_name, shard_total, shard_label),
    shard_index:,
    shard_total:,
    shard_label:,
    bencher_suite_name: bencher_suite_name(suite_name, shard_total, shard_label),
    report_marker:,
    app_directory: suite.fetch(:app_directory),
    artifact_name_prefix: suite.fetch(:artifact_name),
    artifact_name_suffix:,
    benchmark_tool: suite.fetch(:benchmark_tool),
    benchmark_script: suite.fetch(:benchmark_script),
    benchmark_timeout_minutes: suite.fetch(:benchmark_timeout_minutes),
    pro_env: suite.fetch(:pro_env).to_s,
    generate_packs: suite.fetch(:generate_packs).to_s,
    server_kind: suite.fetch(:server_kind),
    summary_file: suite.fetch(:summary_file),
    summary_title: suite.fetch(:summary_title)
  }
end

def benchmark_job_name(suite_name, shard_total, shard_label)
  return "#{suite_name} benchmarks" if shard_total == 1

  "#{suite_name} benchmarks (shard #{shard_label})"
end

def bencher_suite_name(suite_name, shard_total, shard_label)
  return suite_name if shard_total == 1

  "#{suite_name} (shard #{shard_label})"
end

def artifact_name_suffix(shard_total, shard_slug)
  return "" if shard_total == 1

  "-#{shard_slug}"
end

def report_marker(suite, suite_prefix, shard_slug)
  suite[:report_marker] || "<!-- BENCHER_REPORT_#{suite_prefix}_#{shard_slug.upcase.tr('-', '_')} -->"
end

# No suite selected: emit one row so the matrix `include:` stays non-empty and all
# rows share keys. Built from a real suite (any will do — its job is gated off via
# run_benchmark_suites) with the "none" sentinel the gate keys on; the friendlier
# job_name is all that's user-visible, as the skipped job's label.
def empty_matrix_row
  suite_rows(SUITES.first).first.merge(suite_id: "none", job_name: "Benchmark suites skipped")
end

def build_matrix
  labels = pull_request_labels
  event_name = ENV.fetch("BENCHMARK_EVENT_NAME")
  rows = if event_name != "workflow_dispatch" &&
            (truthy_env?("BENCHMARK_NON_RUNTIME_ONLY") || labels.include?(BENCHMARK_SUPPRESS_LABEL))
           []
         else
           SUITES.select { |suite| suite_enabled?(suite, labels) }.flat_map { |suite| suite_rows(suite) }
         end

  { include: rows.empty? ? [empty_matrix_row] : rows }
end

# Only emit when run as a script; `require`-ing the file (e.g. from specs) just
# loads the helpers above without printing.
puts JSON.generate(build_matrix) if __FILE__ == $PROGRAM_NAME

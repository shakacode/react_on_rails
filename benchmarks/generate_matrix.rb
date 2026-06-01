#!/usr/bin/env ruby
# frozen_string_literal: true

# Emits the GitHub Actions matrix `include:` payload for benchmark suites.
# Stdlib-only so the workflow can invoke it with the runner's system Ruby — no
# Bundler, no Rails boot.

require "json"

SUITES = [
  {
    id: "core",
    suite_name: "Core",
    suite_prefix: "CORE",
    shard_total: 1,
    app_versions: %w[both core_only],
    run_output: "RUN_CORE_BENCHMARKS",
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
    run_output: "RUN_PRO_BENCHMARKS",
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
    run_output: "RUN_PRO_NODE_RENDERER_BENCHMARKS",
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

EMPTY_MATRIX_ROW = {
  suite_id: "none",
  suite_name: "No benchmark suite",
  job_name: "Benchmark suites skipped",
  shard_index: 0,
  shard_total: 1,
  shard_label: "1/1",
  shard_slug: "skipped",
  bencher_suite_name: "No benchmark suite",
  report_marker: "<!-- BENCHER_REPORT_SKIPPED -->",
  app_directory: ".",
  artifact_name_prefix: "benchmark-skipped",
  artifact_name_suffix: "",
  benchmark_tool: "none",
  benchmark_script: "",
  benchmark_timeout_minutes: 1,
  pro_env: false,
  generate_packs: false,
  server_kind: "none",
  summary_file: "",
  summary_title: ""
}.freeze

# Every app_version any suite accepts. The workflow_dispatch input is constrained
# to these, but validating guards against a typo or future rename silently
# selecting no suites (which would skip benchmarks while CI stays green).
VALID_APP_VERSIONS = SUITES.flat_map { |suite| suite.fetch(:app_versions) }.uniq.freeze

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

def suite_requested_by_event?(suite, labels)
  event_name = ENV.fetch("BENCHMARK_EVENT_NAME")

  return true if event_name == "push"
  return true if event_name == "workflow_dispatch"
  return false unless event_name == "pull_request"

  # Fork PRs never run: only honor the change-detection (run_output) or label
  # triggers when the PR's head repo is this repo. GITHUB_REPOSITORY is always set
  # by Actions, so a blank/forked head repo can't match it.
  return false unless ENV.fetch("BENCHMARK_PULL_REQUEST_HEAD_REPO", "") == ENV.fetch("GITHUB_REPOSITORY")

  truthy_env?(suite.fetch(:run_output)) || suite.fetch(:labels).intersect?(labels)
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

def suite_rows(suite)
  shard_total = suite.fetch(:shard_total)
  raise "#{suite.fetch(:id)} shard_total must be positive (got #{shard_total})" unless shard_total.positive?

  Array.new(shard_total) do |index|
    shard_number = index + 1
    shard_label = "#{shard_number}/#{shard_total}"
    shard_slug = "shard-#{shard_number}-of-#{shard_total}"
    suite_name = suite.fetch(:suite_name)
    suite_prefix = suite.fetch(:suite_prefix)

    suite_row(suite, suite_name, suite_prefix,
              shard_index: index,
              shard_total: shard_total,
              shard_label: shard_label,
              shard_slug: shard_slug)
  end
end

def suite_row(suite, suite_name, suite_prefix, shard_index:, shard_total:, shard_label:, shard_slug:)
  {
    suite_id: suite.fetch(:id),
    suite_name: suite_name,
    job_name: benchmark_job_name(suite_name, shard_total, shard_label),
    shard_index: shard_index,
    shard_total: shard_total,
    shard_label: shard_label,
    shard_slug: shard_slug,
    bencher_suite_name: bencher_suite_name(suite_name, shard_total, shard_label),
    report_marker: report_marker(suite, suite_prefix, shard_slug),
    app_directory: suite.fetch(:app_directory),
    artifact_name_prefix: suite.fetch(:artifact_name),
    artifact_name_suffix: artifact_name_suffix(shard_total, shard_slug),
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

labels = pull_request_labels
rows = if truthy_env?("BENCHMARK_NON_RUNTIME_ONLY")
         []
       else
         SUITES.select { |suite| suite_enabled?(suite, labels) }.flat_map { |suite| suite_rows(suite) }
       end

matrix = { include: rows.empty? ? [EMPTY_MATRIX_ROW] : rows }

puts JSON.generate(matrix)

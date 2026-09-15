#!/usr/bin/env ruby
# frozen_string_literal: true

require "shellwords"
require_relative "lib/benchmark_config"
require_relative "lib/benchmark_helpers"
require_relative "lib/benchmark_routes"
require_relative "lib/bmf_helpers"

# Script-specific parameters
PRO = ENV.fetch("PRO", "false") == "true"
APP_DIR = PRO ? "react_on_rails_pro/spec/dummy" : "react_on_rails/spec/dummy"
ROUTES = env_or_default("ROUTES", nil)
BASE_URL = env_or_default("BASE_URL", "localhost:3001")
SUMMARY_TXT = "#{OUTDIR}/summary.txt".freeze
BMF_SUFFIX = PRO ? ": Pro" : ": Core"
BENCHMARK_SHARD_INDEX = Integer(env_or_default("BENCHMARK_SHARD_INDEX", 0))
BENCHMARK_TOTAL_SHARDS = Integer(env_or_default("BENCHMARK_TOTAL_SHARDS", 1))
# Repeated k6 samples per route. Each sample is an independent k6 run; the median
# per metric is what ships to Bencher, and the per-sample values ride along in the
# display sidecar so the relative comparison can require a flagged change to
# reproduce across samples (#4580). Default 1 keeps the single-run behavior for
# local trend runs; CI sets 3.
BENCHMARK_SAMPLES = Integer(env_or_default("BENCHMARK_SAMPLES", 1))
# Per-sample k6 duration. Multi-sample runs default shorter so total sampling time
# stays comparable (3x12s vs the single 30s); an explicit DURATION always wins and
# is per sample.
K6_DURATION = env_or_default("DURATION", BENCHMARK_SAMPLES > 1 ? "12s" : "30s")

def add_to_summary(*parts)
  add_summary_line(SUMMARY_TXT, *parts)
end

def shard_benchmark_routes(routes, shard_index, total_shards)
  return routes if total_shards == 1

  routes.each_with_index.filter_map do |route, index|
    route if (index % total_shards) == shard_index
  end
end

# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

# Benchmark a single route with one k6 run (one sample). Returns
# [rps, p50, p90, status] on success and RAISES on any k6/parse failure so the
# suite can record the failure and exit non-zero instead of shipping fabricated
# metrics to Bencher.
def run_k6_benchmark(target, route_name, sample: 1)
  sample_label = BENCHMARK_SAMPLES > 1 ? " (sample #{sample}/#{BENCHMARK_SAMPLES})" : ""
  puts "\n===> k6: #{route_name}#{sample_label}"

  k6_script = File.expand_path("k6.ts", __dir__)
  # Single-sample runs keep the unsuffixed artifact names local tooling knows.
  file_suffix = BENCHMARK_SAMPLES > 1 ? "_s#{sample}" : ""
  k6_summary_json = "#{OUTDIR}/#{route_name}_k6_summary#{file_suffix}.json"
  k6_txt = "#{OUTDIR}/#{route_name}_k6#{file_suffix}.txt"

  # Drop any summary file left by a previous run for this route. k6 only writes
  # the export on a clean finish, so without this a crashed/killed k6 could
  # leave a stale file that parses into fabricated metrics even though this run
  # failed (the pipefail guard below catches the non-zero exit).
  FileUtils.rm_f(k6_summary_json)

  # Build k6 command with environment variables
  k6_env_vars = [
    "-e TARGET_URL=#{Shellwords.escape(target)}",
    "-e RATE=#{RATE}",
    "-e DURATION=#{K6_DURATION}",
    "-e CONNECTIONS=#{CONNECTIONS}",
    "-e MAX_CONNECTIONS=#{MAX_CONNECTIONS}",
    "-e REQUEST_TIMEOUT=#{REQUEST_TIMEOUT}"
  ].join(" ")

  k6_command = "k6 run #{k6_env_vars} --summary-export=#{Shellwords.escape(k6_summary_json)} " \
               "--summary-trend-stats 'med,p(90)' #{Shellwords.escape(k6_script)}"
  # Run through bash with pipefail so a non-zero k6 exit is not masked by tee's
  # (always-zero) exit status. The default /bin/sh on Linux CI is dash, which
  # has no `set -o pipefail`, so invoke bash explicitly. Without this a k6
  # failure would slip past the rescue and ship fabricated metrics to Bencher.
  unless system("bash", "-c", "set -o pipefail; #{k6_command} | tee #{Shellwords.escape(k6_txt)}")
    raise "k6 benchmark failed"
  end

  k6_data = parse_json_file(k6_summary_json, "k6")
  k6_rps = k6_data.dig("metrics", "iterations", "rate")&.round(2) || "MISSING"
  k6_p50 = k6_data.dig("metrics", "http_req_duration", "med")&.round(2) || "MISSING"
  k6_p90 = k6_data.dig("metrics", "http_req_duration", "p(90)")&.round(2) || "MISSING"

  # Status: extract counts from checks (status_200, status_3xx, status_4xx, status_5xx)
  k6_reqs_total = k6_data.dig("metrics", "http_reqs", "count") || 0
  k6_checks = k6_data.dig("root_group", "checks") || {}
  k6_known_count = 0
  k6_status_parts = k6_checks.filter_map do |name, check|
    passes = check["passes"] || 0
    k6_known_count += passes
    next if passes.zero?

    # Convert check names like "status_200" to "200", "status_4xx" to "4xx"
    status_label = name.sub(/^status_/, "")
    "#{status_label}=#{passes}"
  end
  k6_other = k6_reqs_total - k6_known_count
  k6_status_parts << "other=#{k6_other}" if k6_other.positive?
  k6_status = k6_status_parts.empty? ? "MISSING" : k6_status_parts.join(",")

  [k6_rps, k6_p50, k6_p90, k6_status]
end

# rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

# Median of a numeric array (mean of the middle two for even sizes).
def median(values)
  sorted = values.sort
  mid = sorted.length / 2
  sorted.length.odd? ? sorted[mid] : ((sorted[mid - 1] + sorted[mid]) / 2.0)
end

# Median across samples for one metric position, or "MISSING" if any sample
# failed to produce a number (mirrors the single-sample MISSING token).
def median_metric(sample_tuples, index)
  values = sample_tuples.map { |tuple| tuple[index] }
  return "MISSING" unless values.all?(Numeric)

  median(values).round(2)
end

# Status tokens that carry no per-code counts to merge.
COUNTLESS_STATUSES = %w[MISSING FAILED].freeze

# Sum per-code status counts across samples, e.g. ["200=100,3xx=2", "200=98"] ->
# "200=198,3xx=2" (first-appearance code order). Samples without parseable
# counts ("MISSING") are skipped; all-missing stays "MISSING".
def merge_statuses(statuses)
  counts = Hash.new(0)
  statuses.each do |status|
    next if status.nil? || COUNTLESS_STATUSES.include?(status)

    status.split(",").each do |part|
      code, count = part.split("=")
      counts[code] += count.to_i
    end
  end
  return "MISSING" if counts.empty?

  counts.map { |code, count| "#{code}=#{count}" }.join(",")
end

# Aggregate per-sample [rps, p50, p90, status] tuples into the route's reported
# result: medians per metric (robust to a one-off noisy sample), summed status
# counts, plus the raw per-sample values keyed by Bencher measure so the
# relative comparison can require a flagged change to reproduce across samples.
def aggregate_samples(sample_tuples)
  samples = nil
  if sample_tuples.length > 1
    samples = { "rps" => 0, "p50_latency" => 1, "p90_latency" => 2 }.filter_map do |measure, index|
      values = sample_tuples.map { |tuple| tuple[index] }
      [measure, values] if values.all?(Numeric)
    end.to_h
  end

  {
    rps: median_metric(sample_tuples, 0),
    p50: median_metric(sample_tuples, 1),
    p90: median_metric(sample_tuples, 2),
    status: merge_statuses(sample_tuples.map { |tuple| tuple[3] }),
    samples:
  }
end

# Benchmark a single route end-to-end (warm-up + BENCHMARK_SAMPLES k6 runs).
# Returns {rps:, p50:, p90:, status:, samples:} on success and RAISES on failure
# (delegated to run_k6_benchmark) so the suite can record it.
def benchmark_route(route)
  separator = "=" * 80
  puts "\n#{separator}"
  puts "Benchmarking route: #{route}"
  puts separator

  # Strip optional parameters from route for URL (e.g., "(/:locale)" -> "")
  target = URI.parse("http://#{BASE_URL}#{strip_optional_params(route)}")

  # Warm up this route before measuring: a few priming requests trigger
  # first-request compilation/cache population so they don't skew the run. Kept
  # small on purpose — at ~37 routes/shard the old 10×0.5s (5s/route) warm-up
  # dominated CI time (#4012); the k6 runs below are what actually load the
  # server, and they self-warm the remaining workers in their first fraction of
  # a second (with medians, any residual cold-start lands in sample 1 and is
  # discounted by the aggregation).
  puts "Warming up server for #{route} with 3 requests..."
  3.times do
    server_responding?(target)
    sleep 0.2
  end
  puts "Warm-up complete for #{route}"

  route_name = sanitize_route_name(route)
  tuples = (1..BENCHMARK_SAMPLES).map { |sample| run_k6_benchmark(target, route_name, sample:) }
  aggregate_samples(tuples)
end

# Run every route, collecting per-route failures instead of aborting the whole
# suite on the first one. A failed route is recorded as FAILED in the
# human-readable summary but is NOT added to the BMF collector, so fabricated
# metrics never ship to Bencher. Returns the routes that failed (caller exits
# non-zero when any failed). `runner` is injected so the failure-collection
# control flow can be unit-tested without a live server or k6.
def run_benchmark_suite(routes, bmf_collector, runner: method(:benchmark_route))
  failed_routes = []

  routes.each do |route|
    result = runner.call(route)
    add_to_summary(route, result[:rps], result[:p50], result[:p90], result[:status])
    # Add to BMF collector for Bencher output. p90 is sent to Bencher boundary-less
    # (recorded for a summary-table baseline but never thresholded) and also kept in the
    # display sidecar so the summary table can show it; see BmfCollector. samples: is
    # the per-sample raw values (multi-sample runs only), display-sidecar-bound.
    bmf_collector.add(name: route, **result.slice(:rps, :p50, :p90, :status, :samples))
  rescue StandardError => e
    # ::error:: must go to stdout — GitHub Actions only parses workflow commands
    # from stdout, not stderr, so writing here is what renders the UI annotation.
    # The rescue also covers warm-up failures (not just k6), so the label is
    # neutral, and newlines are collapsed so a multiline message can't truncate
    # the annotation (Actions treats a newline as the command terminator).
    $stdout.puts "::error::Benchmark failed for route #{route}: #{e.message.to_s.tr("\n", ' ')}"
    failed_routes << route
    add_to_summary(route, *failure_metrics(e))
  end

  failed_routes
end

if __FILE__ == $PROGRAM_NAME
  all_routes = benchmark_routes_for_app(APP_DIR, ROUTES)

  raise "No routes to benchmark" if all_routes.empty?

  validate_positive_integer(BENCHMARK_TOTAL_SHARDS, "BENCHMARK_TOTAL_SHARDS")
  unless BENCHMARK_SHARD_INDEX.between?(0, BENCHMARK_TOTAL_SHARDS - 1)
    raise "BENCHMARK_SHARD_INDEX must be between 0 and #{BENCHMARK_TOTAL_SHARDS - 1} " \
          "(got: #{BENCHMARK_SHARD_INDEX})"
  end

  routes = shard_benchmark_routes(all_routes, BENCHMARK_SHARD_INDEX, BENCHMARK_TOTAL_SHARDS)
  raise "No routes assigned to shard #{BENCHMARK_SHARD_INDEX + 1}/#{BENCHMARK_TOTAL_SHARDS}" if routes.empty?

  validate_benchmark_config!
  validate_positive_integer(BENCHMARK_SAMPLES, "BENCHMARK_SAMPLES")
  validate_duration(K6_DURATION, "DURATION")

  # Check required tools are installed
  check_required_tools(%w[k6 column tee bash])

  puts <<~PARAMS
    Benchmark parameters:
      - APP_DIR: #{APP_DIR}
      - ROUTES: #{ROUTES || 'auto-detect from Rails'}
      - BASE_URL: #{BASE_URL}
      - BENCHMARK_SHARD_INDEX: #{BENCHMARK_SHARD_INDEX}
      - BENCHMARK_TOTAL_SHARDS: #{BENCHMARK_TOTAL_SHARDS}
      - ROUTES_IN_SHARD: #{routes.length}/#{all_routes.length}
      - RATE: #{RATE}
      - BENCHMARK_SAMPLES: #{BENCHMARK_SAMPLES}
      - DURATION (per sample): #{K6_DURATION}
      - REQUEST_TIMEOUT: #{REQUEST_TIMEOUT}
      - CONNECTIONS: #{CONNECTIONS}
      - MAX_CONNECTIONS: #{MAX_CONNECTIONS}
      - WEB_CONCURRENCY: #{ENV['WEB_CONCURRENCY'] || 'unset'}
      - RAILS_MAX_THREADS: #{ENV['RAILS_MAX_THREADS'] || 'unset'}
      - RAILS_MIN_THREADS: #{ENV['RAILS_MIN_THREADS'] || 'unset'}
  PARAMS

  # Wait for the server to be ready
  test_uri = URI.parse("http://#{BASE_URL}#{routes.first}")
  wait_for_server(test_uri)
  puts "Server is ready!"

  FileUtils.mkdir_p(OUTDIR)
  target_monitor = BenchmarkTargetMonitor.from_env(output_dir: OUTDIR)
  target_monitor.start_measurement!

  # Initialize BMF collector for Bencher output (suffix used for Core/Pro distinction)
  bmf_collector = BmfCollector.new(suffix: BMF_SUFFIX)

  # Initialize summary file
  File.write(SUMMARY_TXT, "")
  add_to_summary("Route", "RPS", "p50(ms)", "p90(ms)", "Status")

  failed_routes = run_benchmark_suite(routes, bmf_collector)

  puts "\nSummary saved to #{SUMMARY_TXT}"
  system("column", "-t", "-s", "\t", SUMMARY_TXT)

  # Write the Bencher payload only on a fully green run against a healthy target.
  # Guarding the write here makes the "never upload partial metrics" invariant
  # self-enforcing instead of relying on later workflow steps to discard data.
  if failed_routes.empty?
    begin
      write_benchmark_payload(bmf_collector, target_monitor:)
    rescue BenchmarkTargetMonitor::MonitorFailure => e
      $stdout.puts "::error::#{e.message}"
      exit 1
    end
  else
    $stdout.puts "::error::#{failed_routes.length} of #{routes.length} benchmark route(s) failed: " \
                 "#{failed_routes.join(', ')}"
    exit 1
  end
end

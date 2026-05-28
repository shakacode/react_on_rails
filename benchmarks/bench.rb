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

def add_to_summary(*parts)
  add_summary_line(SUMMARY_TXT, *parts)
end

def shard_benchmark_routes(routes, shard_index, total_shards)
  return routes if total_shards == 1

  routes.each_with_index.filter_map do |route, index|
    route if (index % total_shards) == shard_index
  end
end

all_routes = benchmark_routes_for_app(APP_DIR, ROUTES)

raise "No routes to benchmark" if all_routes.empty?

validate_positive_integer(BENCHMARK_TOTAL_SHARDS, "BENCHMARK_TOTAL_SHARDS")
raise "BENCHMARK_SHARD_INDEX must be between 0 and #{BENCHMARK_TOTAL_SHARDS - 1} (got: #{BENCHMARK_SHARD_INDEX})" unless
  BENCHMARK_SHARD_INDEX.between?(0, BENCHMARK_TOTAL_SHARDS - 1)

routes = shard_benchmark_routes(all_routes, BENCHMARK_SHARD_INDEX, BENCHMARK_TOTAL_SHARDS)
raise "No routes assigned to shard #{BENCHMARK_SHARD_INDEX + 1}/#{BENCHMARK_TOTAL_SHARDS}" if routes.empty?

validate_benchmark_config!

# Check required tools are installed
check_required_tools(%w[k6 column tee])

puts <<~PARAMS
  Benchmark parameters:
    - APP_DIR: #{APP_DIR}
    - ROUTES: #{ROUTES || 'auto-detect from Rails'}
    - BASE_URL: #{BASE_URL}
    - BENCHMARK_SHARD_INDEX: #{BENCHMARK_SHARD_INDEX}
    - BENCHMARK_TOTAL_SHARDS: #{BENCHMARK_TOTAL_SHARDS}
    - ROUTES_IN_SHARD: #{routes.length}/#{all_routes.length}
    - RATE: #{RATE}
    - DURATION: #{DURATION}
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

# Initialize BMF collector for Bencher output (suffix used for Core/Pro distinction)
bmf_collector = BmfCollector.new(suffix: BMF_SUFFIX)

# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

# Benchmark a single route with k6
def run_k6_benchmark(target, route_name)
  puts "\n===> k6: #{route_name}"

  k6_script = File.expand_path("k6.ts", __dir__)
  k6_summary_json = "#{OUTDIR}/#{route_name}_k6_summary.json"
  k6_txt = "#{OUTDIR}/#{route_name}_k6.txt"

  # Build k6 command with environment variables
  k6_env_vars = [
    "-e TARGET_URL=#{Shellwords.escape(target)}",
    "-e RATE=#{RATE}",
    "-e DURATION=#{DURATION}",
    "-e CONNECTIONS=#{CONNECTIONS}",
    "-e MAX_CONNECTIONS=#{MAX_CONNECTIONS}",
    "-e REQUEST_TIMEOUT=#{REQUEST_TIMEOUT}"
  ].join(" ")

  k6_command = "k6 run #{k6_env_vars} --summary-export=#{Shellwords.escape(k6_summary_json)} " \
               "--summary-trend-stats 'med,max,p(90),p(99)' #{k6_script}"
  raise "k6 benchmark failed" unless system("#{k6_command} | tee #{Shellwords.escape(k6_txt)}")

  k6_data = parse_json_file(k6_summary_json, "k6")
  k6_rps = k6_data.dig("metrics", "iterations", "rate")&.round(2) || "MISSING"
  k6_p50 = k6_data.dig("metrics", "http_req_duration", "med")&.round(2) || "MISSING"
  k6_p90 = k6_data.dig("metrics", "http_req_duration", "p(90)")&.round(2) || "MISSING"
  k6_p99 = k6_data.dig("metrics", "http_req_duration", "p(99)")&.round(2) || "MISSING"
  k6_max = k6_data.dig("metrics", "http_req_duration", "max")&.round(2) || "MISSING"

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

  [k6_rps, k6_p50, k6_p90, k6_p99, k6_max, k6_status]
rescue StandardError => e
  puts "Error: #{e.message}"
  failure_metrics(e)
end

# rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

# Initialize summary file
File.write(SUMMARY_TXT, "")
add_to_summary("Route", "RPS", "p50(ms)", "p90(ms)", "p99(ms)", "max(ms)", "Status")

# Run benchmarks for each route
routes.each do |route|
  separator = "=" * 80
  puts "\n#{separator}"
  puts "Benchmarking route: #{route}"
  puts separator

  # Strip optional parameters from route for URL (e.g., "(/:locale)" -> "")
  target = URI.parse("http://#{BASE_URL}#{strip_optional_params(route)}")

  # Warm up server for this route
  puts "Warming up server for #{route} with 10 requests..."
  10.times do
    server_responding?(target)
    sleep 0.5
  end
  puts "Warm-up complete for #{route}"

  route_name = sanitize_route_name(route)
  rps, p50, p90, p99, max_latency, status = run_k6_benchmark(target, route_name)
  add_to_summary(route, rps, p50, p90, p99, max_latency, status)

  # Add to BMF collector for Bencher output
  bmf_collector.add(name: route, rps: rps, p50: p50, p90: p90, p99: p99, status: status)
end

puts "\nSummary saved to #{SUMMARY_TXT}"
system("column", "-t", "-s", "\t", SUMMARY_TXT)

bmf_collector.write_bmf_json(BENCHMARK_JSON)

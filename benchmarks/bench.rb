#!/usr/bin/env ruby
# frozen_string_literal: true

require "open3"
require "shellwords"
require_relative "lib/benchmark_config"
require_relative "lib/benchmark_helpers"
require_relative "lib/bmf_helpers"

# Script-specific parameters
PRO = ENV.fetch("PRO", "false") == "true"
APP_DIR = PRO ? "react_on_rails_pro/spec/dummy" : "react_on_rails/spec/dummy"
ROUTES = env_or_default("ROUTES", nil)
BASE_URL = env_or_default("BASE_URL", "localhost:3001")
SUMMARY_TXT = "#{OUTDIR}/summary.txt".freeze
BMF_SUFFIX = PRO ? ": Pro" : ": Core"

# Local wrapper for add_summary_line to use local constant
def add_to_summary(*parts)
  add_summary_line(SUMMARY_TXT, *parts)
end

# Check if a route has required parameters (e.g., /rsc_payload/:component_name)
# Required parameters are :param NOT inside parentheses
# Optional parameters are inside parentheses like (/:optional_param)
def route_has_required_params?(path)
  # Remove optional parameter sections (anything in parentheses)
  path_without_optional = path.gsub(/\([^)]*\)/, "")
  # Check if remaining path contains :param
  path_without_optional.include?(":")
end

# Strip optional parameters from route path for use in URLs
# e.g., "/route(/:optional)(.:format)" -> "/route"
def strip_optional_params(route)
  route.gsub(/\([^)]*\)/, "")
end

# Sanitize route name for use in filenames
# Removes characters that GitHub Actions disallows in artifacts and shell metacharacters
def sanitize_route_name(route)
  name = strip_optional_params(route).gsub(%r{^/}, "").tr("/", "_")
  name = "root" if name.empty?
  # Replace invalid characters: " : < > | * ? \r \n $ ` ; & ( ) [ ] { } ! #
  name.gsub(/[":.<>|*?\r\n$`;&#!()\[\]{}]+/, "_").squeeze("_").gsub(/^_|_$/, "")
end

# Get routes from the Rails app filtered by pages# and react_router# controllers
def get_benchmark_routes(app_dir)
  routes_output, status = Open3.capture2e("bundle", "exec", "rails", "routes", chdir: app_dir)
  raise "Failed to get routes from #{app_dir}" unless status.success?

  routes = []
  routes_output.each_line do |line|
    # Parse lines like: "server_side_hello_world GET  /server_side_hello_world(.:format)  pages#server_side_hello_world"
    # We want GET routes only (not POST, etc.) served by pages# or react_router# controllers
    # Capture path up to (.:format) part using [^(\s]+ (everything except '(' and whitespace)
    next unless (match = line.match(/GET\s+([^(\s]+).*(pages|react_router)#/))

    path = match[1]
    path = "/" if path.empty? # Handle root route

    # Skip routes with required parameters (e.g., /rsc_payload/:component_name)
    if route_has_required_params?(path)
      puts "Skipping route with required parameters: #{path}"
      next
    end

    # Skip "_for_testing" routes (test-only endpoints not meant for benchmarking)
    if path.include?("_for_testing")
      puts "Skipping test-only route: #{path}"
      next
    end

    routes << path
  end
  raise "No pages# or react_router# routes found in #{app_dir}" if routes.empty?

  routes
end

# Get all routes to benchmark
routes =
  if ROUTES
    ROUTES.split(",").map(&:strip).reject(&:empty?)
  else
    get_benchmark_routes(APP_DIR)
  end

raise "No routes to benchmark" if routes.empty?

validate_benchmark_config!

# Check required tools are installed
check_required_tools(%w[k6 column tee])

puts <<~PARAMS
  Benchmark parameters:
    - APP_DIR: #{APP_DIR}
    - ROUTES: #{ROUTES || 'auto-detect from Rails'}
    - BASE_URL: #{BASE_URL}
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

# Write BMF JSON for Bencher (append if Pro to combine with Core results)
bmf_collector.write_bmf_json(BENCHMARK_JSON, append: PRO)

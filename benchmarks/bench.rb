#!/usr/bin/env ruby
# frozen_string_literal: true

require "English"
require "json"
require "fileutils"
require "net/http"
require "uri"

# Helper to get env var with default,
# treating empty string and "0" as unset since they can come from the benchmark workflow.
def env_or_default(key, default)
  value = ENV[key].to_s
  value.empty? || value == "0" ? default : value
end

# Benchmark parameters
PRO = ENV.fetch("PRO", "false") == "true"
APP_DIR = PRO ? "react_on_rails_pro/spec/dummy" : "react_on_rails/spec/dummy"
ROUTES = env_or_default("ROUTES", nil)
BASE_URL = env_or_default("BASE_URL", "localhost:3001")
# requests per second; if "max" will get maximum number of queries instead of a fixed rate
RATE = env_or_default("RATE", "50")
# concurrent connections/virtual users
CONNECTIONS = env_or_default("CONNECTIONS", 10).to_i
# maximum connections/virtual users
MAX_CONNECTIONS = env_or_default("MAX_CONNECTIONS", CONNECTIONS).to_i
# benchmark duration (duration string like "30s", "1m", "90s")
DURATION = env_or_default("DURATION", "30s")
# request timeout (duration string as above)
REQUEST_TIMEOUT = env_or_default("REQUEST_TIMEOUT", "60s")
# Tools to run (comma-separated)
TOOLS = env_or_default("TOOLS", "fortio,vegeta,k6").split(",")

OUTDIR = "bench_results"
SUMMARY_TXT = "#{OUTDIR}/summary.txt".freeze

# Validate input parameters
def validate_rate(rate)
  return if rate == "max"

  return if rate.match?(/^\d+(\.\d+)?$/) && rate.to_f.positive?

  raise "RATE must be 'max' or a positive number (got: '#{rate}')"
end

def validate_positive_integer(value, name)
  return if value.is_a?(Integer) && value.positive?

  raise "#{name} must be a positive integer (got: '#{value}')"
end

def validate_duration(value, name)
  return if value.match?(/^(\d+(\.\d+)?[smh])+$/)

  raise "#{name} must be a duration like '10s', '1m', '1.5m' (got: '#{value}')"
end

def parse_json_file(file_path, tool_name)
  JSON.parse(File.read(file_path))
rescue Errno::ENOENT
  raise "#{tool_name} results file not found: #{file_path}"
rescue JSON::ParserError => e
  raise "Failed to parse #{tool_name} JSON: #{e.message}"
rescue StandardError => e
  raise "Failed to read #{tool_name} results: #{e.message}"
end

def failure_metrics(error)
  ["FAILED", "FAILED", "FAILED", "FAILED", error.message]
end

def add_summary_line(*parts)
  File.open(SUMMARY_TXT, "a") do |f|
    f.puts parts.join("\t")
  end
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

validate_rate(RATE)
validate_positive_integer(CONNECTIONS, "CONNECTIONS")
validate_positive_integer(MAX_CONNECTIONS, "MAX_CONNECTIONS")
validate_duration(DURATION, "DURATION")
validate_duration(REQUEST_TIMEOUT, "REQUEST_TIMEOUT")

raise "MAX_CONNECTIONS (#{MAX_CONNECTIONS}) must be >= CONNECTIONS (#{CONNECTIONS})" if MAX_CONNECTIONS < CONNECTIONS

# Check required tools are installed
required_tools = TOOLS + %w[column tee]
required_tools.each do |cmd|
  raise "required tool '#{cmd}' is not installed" unless system("command -v #{cmd} >/dev/null 2>&1")
end

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
    - TOOLS: #{TOOLS.join(', ')}
PARAMS

# Helper method to check if server is responding
def server_responding?(uri)
  response = Net::HTTP.get_response(uri)
  # Accept both success (2xx) and redirect (3xx) responses as "server is responding"
  success = response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPRedirection)
  info = "HTTP #{response.code} #{response.message}"
  info += " -> #{response['location']}" if response.is_a?(Net::HTTPRedirection) && response["location"]
  { success: success, info: info }
rescue StandardError => e
  { success: false, info: "#{e.class.name}: #{e.message}" }
end

# Wait for the server to be ready
TIMEOUT_SEC = 60
puts "Checking server availability at #{BASE_URL}..."
test_uri = URI.parse("http://#{BASE_URL}#{routes.first}")
start_time = Time.now
attempt_count = 0
loop do
  attempt_count += 1
  attempt_start = Time.now
  result = server_responding?(test_uri)
  attempt_duration = Time.now - attempt_start
  elapsed = Time.now - start_time

  # rubocop:disable Layout/LineLength
  if result[:success]
    puts "  ✅ Attempt #{attempt_count} at #{elapsed.round(2)}s: SUCCESS - #{result[:info]} (took #{attempt_duration.round(3)}s)"
    break
  else
    puts "  ❌ Attempt #{attempt_count} at #{elapsed.round(2)}s: FAILED - #{result[:info]} (took #{attempt_duration.round(3)}s)"
  end
  # rubocop:enable Layout/LineLength

  raise "Server at #{BASE_URL} not responding within #{TIMEOUT_SEC}s" if elapsed > TIMEOUT_SEC

  sleep 1
end
puts "Server is ready!"

FileUtils.mkdir_p(OUTDIR)

# Validate RATE=max constraint
IS_MAX_RATE = RATE == "max"
if IS_MAX_RATE && CONNECTIONS != MAX_CONNECTIONS
  raise "For RATE=max, CONNECTIONS must be equal to MAX_CONNECTIONS (got #{CONNECTIONS} and #{MAX_CONNECTIONS})"
end

# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength

# Benchmark a single route with Fortio
def run_fortio_benchmark(target, route_name)
  return nil unless TOOLS.include?("fortio")

  begin
    puts "===> Fortio: #{route_name}"

    fortio_json = "#{OUTDIR}/#{route_name}_fortio.json"
    fortio_txt = "#{OUTDIR}/#{route_name}_fortio.txt"

    # Configure Fortio arguments
    # See https://github.com/fortio/fortio/wiki/FAQ#i-want-to-get-the-best-results-what-flags-should-i-pass
    fortio_args =
      if IS_MAX_RATE
        ["-qps", 0, "-c", CONNECTIONS]
      else
        ["-qps", RATE, "-uniform", "-nocatchup", "-c", CONNECTIONS]
      end

    fortio_cmd = [
      "fortio", "load",
      *fortio_args,
      "-t", DURATION,
      "-timeout", REQUEST_TIMEOUT,
      # Allow redirects. Could use -L instead, but it uses the slower HTTP client.
      "-allow-initial-errors",
      "-json", fortio_json,
      target
    ].join(" ")
    raise "Fortio benchmark failed" unless system("#{fortio_cmd} | tee #{fortio_txt}")

    fortio_data = parse_json_file(fortio_json, "Fortio")
    fortio_rps = fortio_data["ActualQPS"]&.round(2) || "missing"

    percentiles = fortio_data.dig("DurationHistogram", "Percentiles") || []
    p50_data = percentiles.find { |p| p["Percentile"] == 50 }
    p90_data = percentiles.find { |p| p["Percentile"] == 90 }
    p99_data = percentiles.find { |p| p["Percentile"] == 99 }

    raise "Fortio results missing percentile data" unless p50_data && p90_data && p99_data

    fortio_p50 = (p50_data["Value"] * 1000).round(2)
    fortio_p90 = (p90_data["Value"] * 1000).round(2)
    fortio_p99 = (p99_data["Value"] * 1000).round(2)
    fortio_status = fortio_data["RetCodes"]&.map { |k, v| "#{k}=#{v}" }&.join(",") || "missing"

    [fortio_rps, fortio_p50, fortio_p90, fortio_p99, fortio_status]
  rescue StandardError => e
    puts "Error: #{e.message}"
    failure_metrics(e)
  end
end

# Benchmark a single route with Vegeta
def run_vegeta_benchmark(target, route_name)
  return nil unless TOOLS.include?("vegeta")

  begin
    puts "\n===> Vegeta: #{route_name}"

    vegeta_json = "#{OUTDIR}/#{route_name}_vegeta.json"
    vegeta_txt = "#{OUTDIR}/#{route_name}_vegeta.txt"

    # Configure Vegeta arguments
    vegeta_args =
      if IS_MAX_RATE
        ["-rate=0", "--workers=#{CONNECTIONS}", "--max-workers=#{CONNECTIONS}"]
      else
        ["-rate=#{RATE}", "--workers=#{CONNECTIONS}", "--max-workers=#{MAX_CONNECTIONS}"]
      end

    # Run vegeta attack and pipe to text report (displayed and saved)
    # Then generate JSON report by re-encoding from the text output isn't possible,
    # so we save to a temp .bin file, generate both reports, then delete it
    vegeta_bin = "#{OUTDIR}/#{route_name}_vegeta.bin"
    vegeta_cmd = [
      "echo 'GET #{target}' |",
      "vegeta", "attack",
      *vegeta_args,
      "-duration=#{DURATION}",
      "-timeout=#{REQUEST_TIMEOUT}",
      "-redirects=0",
      "> #{vegeta_bin}"
    ].join(" ")
    raise "Vegeta attack failed" unless system(vegeta_cmd)

    # Generate text report (display and save)
    raise "Vegeta text report failed" unless system("vegeta report #{vegeta_bin} | tee #{vegeta_txt}")

    # Generate JSON report
    raise "Vegeta JSON report failed" unless system("vegeta report -type=json #{vegeta_bin} > #{vegeta_json}")

    # Delete the large binary file to save disk space
    FileUtils.rm_f(vegeta_bin)

    vegeta_data = parse_json_file(vegeta_json, "Vegeta")
    vegeta_rps = vegeta_data["throughput"]&.round(2) || "missing"
    vegeta_p50 = vegeta_data.dig("latencies", "50th")&./(1_000_000.0)&.round(2) || "missing"
    vegeta_p90 = vegeta_data.dig("latencies", "90th")&./(1_000_000.0)&.round(2) || "missing"
    vegeta_p99 = vegeta_data.dig("latencies", "99th")&./(1_000_000.0)&.round(2) || "missing"
    vegeta_status = vegeta_data["status_codes"]&.map { |k, v| "#{k}=#{v}" }&.join(",") || "missing"

    [vegeta_rps, vegeta_p50, vegeta_p90, vegeta_p99, vegeta_status]
  rescue StandardError => e
    puts "Error: #{e.message}"
    failure_metrics(e)
  end
end

# Benchmark a single route with k6
def run_k6_benchmark(target, route_name)
  return nil unless TOOLS.include?("k6")

  begin
    puts "\n===> k6: #{route_name}"

    k6_script_file = "#{OUTDIR}/#{route_name}_k6_test.js"
    k6_summary_json = "#{OUTDIR}/#{route_name}_k6_summary.json"
    k6_txt = "#{OUTDIR}/#{route_name}_k6.txt"

    # Configure k6 scenarios
    k6_scenarios =
      if IS_MAX_RATE
        <<~JS.strip
          {
            max_rate: {
              executor: 'constant-vus',
              vus: #{CONNECTIONS},
              duration: '#{DURATION}'
            }
          }
        JS
      else
        <<~JS.strip
          {
            constant_rate: {
              executor: 'constant-arrival-rate',
              rate: #{RATE},
              timeUnit: '1s',
              duration: '#{DURATION}',
              preAllocatedVUs: #{CONNECTIONS},
              maxVUs: #{MAX_CONNECTIONS}
            }
          }
        JS
      end

    k6_script = <<~JS
      import http from 'k6/http';
      import { check } from 'k6';

      export const options = {
        scenarios: #{k6_scenarios},
      };

      export default function () {
        const response = http.get('#{target}', {
          timeout: '#{REQUEST_TIMEOUT}',
          redirects: 0,
        });
        check(response, {
          'status=200': r => r.status === 200,
        });
      }
    JS
    File.write(k6_script_file, k6_script)
    k6_command = "k6 run --summary-export=#{k6_summary_json} --summary-trend-stats 'min,avg,med,max,p(90),p(99)'"
    raise "k6 benchmark failed" unless system("#{k6_command} #{k6_script_file} | tee #{k6_txt}")

    k6_data = parse_json_file(k6_summary_json, "k6")
    k6_rps = k6_data.dig("metrics", "iterations", "rate")&.round(2) || "missing"
    k6_p50 = k6_data.dig("metrics", "http_req_duration", "med")&.round(2) || "missing"
    k6_p90 = k6_data.dig("metrics", "http_req_duration", "p(90)")&.round(2) || "missing"
    k6_p99 = k6_data.dig("metrics", "http_req_duration", "p(99)")&.round(2) || "missing"

    # Status: compute successful vs failed requests
    k6_reqs_total = k6_data.dig("metrics", "http_reqs", "count") || 0
    k6_checks = k6_data.dig("root_group", "checks") || {}
    k6_status_parts = k6_checks.map do |name, check|
      status_label = name.start_with?("status=") ? name.delete_prefix("status=") : name
      "#{status_label}=#{check['passes']}"
    end
    k6_reqs_known_status = k6_checks.values.sum { |check| check["passes"] || 0 }
    k6_reqs_other = k6_reqs_total - k6_reqs_known_status
    k6_status_parts << "other=#{k6_reqs_other}" if k6_reqs_other.positive?
    k6_status = k6_status_parts.empty? ? "missing" : k6_status_parts.join(",")

    [k6_rps, k6_p50, k6_p90, k6_p99, k6_status]
  rescue StandardError => e
    puts "Error: #{e.message}"
    failure_metrics(e)
  end
end

# rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength

# Initialize summary file
File.write(SUMMARY_TXT, "")
add_summary_line("Route", "Tool", "RPS", "p50(ms)", "p90(ms)", "p99(ms)", "Status")

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

  # Run each benchmark tool
  fortio_metrics = run_fortio_benchmark(target, route_name)
  add_summary_line(route, "Fortio", *fortio_metrics) if fortio_metrics

  vegeta_metrics = run_vegeta_benchmark(target, route_name)
  add_summary_line(route, "Vegeta", *vegeta_metrics) if vegeta_metrics

  k6_metrics = run_k6_benchmark(target, route_name)
  add_summary_line(route, "k6", *k6_metrics) if k6_metrics
end

puts "\nSummary saved to #{SUMMARY_TXT}"
system("column", "-t", "-s", "\t", SUMMARY_TXT)

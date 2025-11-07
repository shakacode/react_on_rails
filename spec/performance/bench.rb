#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "fileutils"
require "net/http"
require "uri"

# Benchmark parameters
BASE_URL = ENV.fetch("BASE_URL", "localhost:3001")
ROUTE = ENV.fetch("ROUTE", "server_side_hello_world_hooks")
TARGET = URI.parse("http://#{BASE_URL}/#{ROUTE}")
# requests per second; if "max" will get maximum number of queries instead of a fixed rate
RATE = ENV.fetch("RATE", "50")
# concurrent connections/virtual users
CONNECTIONS = ENV.fetch("CONNECTIONS", "10").to_i
# maximum connections/virtual users
MAX_CONNECTIONS = ENV.fetch("MAX_CONNECTIONS", CONNECTIONS).to_i
# benchmark duration (duration string like "30s", "1m", "90s")
DURATION = ENV.fetch("DURATION", "30s")
# request timeout (duration string as above)
REQUEST_TIMEOUT = ENV.fetch("REQUEST_TIMEOUT", "60s")
# Tools to run (comma-separated)
TOOLS = ENV.fetch("TOOLS", "fortio,vegeta,k6").split(",")

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
  response.is_a?(Net::HTTPSuccess)
rescue StandardError
  false
end

# Wait for the server to be ready
TIMEOUT_SEC = 60
start_time = Time.now
loop do
  break if server_responding?(TARGET)

  raise "Target #{TARGET} not responding within #{TIMEOUT_SEC}s" if Time.now - start_time > TIMEOUT_SEC

  sleep 1
end

# Warm up server
puts "Warming up server with 10 requests..."
10.times do
  server_responding?(TARGET)
  sleep 0.5
end
puts "Warm-up complete"

FileUtils.mkdir_p(OUTDIR)

# Validate RATE=max constraint
is_max_rate = RATE == "max"
if is_max_rate && CONNECTIONS != MAX_CONNECTIONS
  raise "For RATE=max, CONNECTIONS must be equal to MAX_CONNECTIONS (got #{CONNECTIONS} and #{MAX_CONNECTIONS})"
end

# Initialize summary file
File.write(SUMMARY_TXT, "Tool\tRPS\tp50(ms)\tp90(ms)\tp99(ms)\tStatus\n")

# Fortio
if TOOLS.include?("fortio")
  begin
    puts "===> Fortio"

    fortio_json = "#{OUTDIR}/fortio.json"
    fortio_txt = "#{OUTDIR}/fortio.txt"

    # Configure Fortio arguments
    # See https://github.com/fortio/fortio/wiki/FAQ#i-want-to-get-the-best-results-what-flags-should-i-pass
    fortio_args =
      if is_max_rate
        ["-qps", 0, "-c", CONNECTIONS]
      else
        ["-qps", RATE, "-uniform", "-nocatchup", "-c", CONNECTIONS]
      end

    fortio_cmd = [
      "fortio", "load",
      *fortio_args,
      "-t", DURATION,
      "-timeout", REQUEST_TIMEOUT,
      "-json", fortio_json,
      TARGET
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
    fortio_status = fortio_data["RetCodes"]&.map { |k, v| "#{k}=#{v}" }&.join(",") || "unknown"
    File.open(SUMMARY_TXT, "a") do |f|
      f.puts "Fortio\t#{fortio_rps}\t#{fortio_p50}\t#{fortio_p90}\t#{fortio_p99}\t#{fortio_status}"
    end
  rescue StandardError => e
    puts "Error: #{e.message}"
    File.open(SUMMARY_TXT, "a") do |f|
      f.puts "Fortio\tFAILED\tFAILED\tFAILED\tFAILED\t#{e.message}"
    end
  end
end

# Vegeta
if TOOLS.include?("vegeta")
  begin
    puts "\n===> Vegeta"

    vegeta_bin = "#{OUTDIR}/vegeta.bin"
    vegeta_json = "#{OUTDIR}/vegeta.json"
    vegeta_txt = "#{OUTDIR}/vegeta.txt"

    # Configure Vegeta arguments
    vegeta_args =
      if is_max_rate
        ["-rate=0", "--workers=#{CONNECTIONS}", "--max-workers=#{CONNECTIONS}"]
      else
        ["-rate=#{RATE}", "--workers=#{CONNECTIONS}", "--max-workers=#{MAX_CONNECTIONS}"]
      end

    vegeta_cmd = [
      "echo 'GET #{TARGET}' |",
      "vegeta", "attack",
      *vegeta_args,
      "-duration=#{DURATION}",
      "-timeout=#{REQUEST_TIMEOUT}"
    ].join(" ")
    raise "Vegeta attack failed" unless system("#{vegeta_cmd} | tee #{vegeta_bin} | vegeta report | tee #{vegeta_txt}")
    raise "Vegeta report generation failed" unless system("vegeta report -type=json #{vegeta_bin} > #{vegeta_json}")

    vegeta_data = parse_json_file(vegeta_json, "Vegeta")
    # .throughput is successful_reqs/total_period, .rate is all_requests/attack_period
    vegeta_rps = vegeta_data["throughput"]&.round(2) || "missing"
    vegeta_p50 = vegeta_data.dig("latencies", "50th")&./(1_000_000.0)&.round(2) || "missing"
    vegeta_p90 = vegeta_data.dig("latencies", "90th")&./(1_000_000.0)&.round(2) || "missing"
    vegeta_p99 = vegeta_data.dig("latencies", "99th")&./(1_000_000.0)&.round(2) || "missing"
    vegeta_status = vegeta_data["status_codes"]&.map { |k, v| "#{k}=#{v}" }&.join(",") || "unknown"
    vegeta_line = [
      "Vegeta", vegeta_rps, vegeta_p50, vegeta_p90, vegeta_p99, vegeta_status
    ].join("\t")
    File.open(SUMMARY_TXT, "a") do |f|
      f.puts vegeta_line
    end
  rescue StandardError => e
    puts "Error: #{e.message}"
    File.open(SUMMARY_TXT, "a") do |f|
      f.puts "Vegeta\tFAILED\tFAILED\tFAILED\tFAILED\t#{e.message}"
    end
  end
end

# k6
if TOOLS.include?("k6")
  begin
    puts "\n===> k6"

    k6_script_file = "#{OUTDIR}/k6_test.js"
    k6_summary_json = "#{OUTDIR}/k6_summary.json"
    k6_txt = "#{OUTDIR}/k6.txt"

    # Configure k6 scenarios
    k6_scenarios =
      if is_max_rate
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
        const response = http.get('#{TARGET}', { timeout: '#{REQUEST_TIMEOUT}' });
        check(response, {
          'status=200': r => r.status === 200,
          // you can add more if needed:
          // 'status=500': r => r.status === 500,
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
    # Extract status code from check name (e.g., "status=200" -> "200")
    # Handle both "status=XXX" format and other potential formats
    k6_status_parts = k6_checks.map do |name, check|
      status_label = name.start_with?("status=") ? name.delete_prefix("status=") : name
      "#{status_label}=#{check['passes']}"
    end
    k6_reqs_known_status = k6_checks.values.sum { |check| check["passes"] || 0 }
    k6_reqs_other = k6_reqs_total - k6_reqs_known_status
    k6_status_parts << "other=#{k6_reqs_other}" if k6_reqs_other.positive?
    k6_status = k6_status_parts.empty? ? "missing" : k6_status_parts.join(",")

    File.open(SUMMARY_TXT, "a") do |f|
      f.puts "k6\t#{k6_rps}\t#{k6_p50}\t#{k6_p90}\t#{k6_p99}\t#{k6_status}"
    end
  rescue StandardError => e
    puts "Error: #{e.message}"
    File.open(SUMMARY_TXT, "a") do |f|
      f.puts "k6\tFAILED\tFAILED\tFAILED\tFAILED\t#{e.message}"
    end
  end
end

puts "\nSummary saved to #{SUMMARY_TXT}"
system("column", "-t", "-s", "\t", SUMMARY_TXT)

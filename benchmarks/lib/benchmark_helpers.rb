# frozen_string_literal: true

require "json"
require "fileutils"
require "net/http"
require "uri"

# Shared utilities for benchmark scripts
# Note: env_or_default and validation helpers are in benchmark_config.rb

# JSON parsing with error handling
def parse_json_file(file_path, tool_name)
  JSON.parse(File.read(file_path))
rescue Errno::ENOENT
  raise "#{tool_name} results file not found: #{file_path}"
rescue JSON::ParserError => e
  raise "Failed to parse #{tool_name} JSON: #{e.message}"
rescue StandardError => e
  raise "Failed to read #{tool_name} results: #{e.message}"
end

# Create failure metrics array for summary
def failure_metrics(error)
  ["FAILED", "FAILED", "FAILED", "FAILED", "FAILED", error.message]
end

# Append a line to the summary file
def add_summary_line(summary_file, *parts)
  File.open(summary_file, "a") do |f|
    f.puts parts.join("\t")
  end
end

# HTTP server health check
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

# Wait for a server to be ready with timeout and retries
def wait_for_server(uri, timeout_sec: 60)
  puts "Checking server availability at #{uri.host}:#{uri.port}..."
  start_time = Time.now
  attempt_count = 0

  loop do
    attempt_count += 1
    attempt_start = Time.now
    result = server_responding?(uri)
    attempt_duration = Time.now - attempt_start
    elapsed = Time.now - start_time

    if result[:success]
      puts "  Attempt #{attempt_count} at #{elapsed.round(2)}s: SUCCESS - #{result[:info]} " \
           "(took #{attempt_duration.round(3)}s)"
      return true
    else
      puts "  Attempt #{attempt_count} at #{elapsed.round(2)}s: FAILED - #{result[:info]} " \
           "(took #{attempt_duration.round(3)}s)"
    end

    raise "Server at #{uri.host}:#{uri.port} not responding within #{timeout_sec}s" if elapsed > timeout_sec

    sleep 1
  end
end

# Check that required CLI tools are installed
def check_required_tools(tools)
  tools.each do |cmd|
    raise "required tool '#{cmd}' is not installed" unless system("command -v #{cmd} >/dev/null 2>&1")
  end
end

# Print a section separator
def print_separator(char = "=", width = 80)
  puts char * width
end

# Print benchmark parameters
def print_params(params)
  puts "Benchmark parameters:"
  params.each do |key, value|
    puts "  - #{key}: #{value}"
  end
end

# Display summary using column command
def display_summary(summary_file)
  puts "\nSummary saved to #{summary_file}"
  system("column", "-t", "-s", "\t", summary_file)
end

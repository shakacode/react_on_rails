# frozen_string_literal: true

# Shared benchmark configuration
# Common environment variables and validation used by all benchmark scripts

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

# Validation helpers
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

# Common benchmark parameters with defaults
OUTDIR = "bench_results"
BENCHMARK_JSON = "#{OUTDIR}/benchmark.json".freeze
RATE = env_or_default("RATE", "max")
CONNECTIONS = env_or_default("CONNECTIONS", 10).to_i
MAX_CONNECTIONS = env_or_default("MAX_CONNECTIONS", CONNECTIONS).to_i
DURATION = env_or_default("DURATION", "30s")
REQUEST_TIMEOUT = env_or_default("REQUEST_TIMEOUT", "60s")

# Validate all common parameters and raise if any validation fails
def validate_benchmark_config!
  validate_rate(RATE)
  validate_positive_integer(CONNECTIONS, "CONNECTIONS")
  validate_positive_integer(MAX_CONNECTIONS, "MAX_CONNECTIONS")
  validate_duration(DURATION, "DURATION")
  validate_duration(REQUEST_TIMEOUT, "REQUEST_TIMEOUT")

  return unless RATE == "max" && CONNECTIONS != MAX_CONNECTIONS

  raise "For RATE=max, CONNECTIONS must equal MAX_CONNECTIONS " \
        "(got #{CONNECTIONS} and #{MAX_CONNECTIONS})"
end

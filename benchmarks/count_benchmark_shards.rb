#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require_relative "lib/benchmark_config"
require_relative "lib/benchmark_routes"

PRO = ENV.fetch("PRO", "false") == "true"
APP_DIR = PRO ? "react_on_rails_pro/spec/dummy" : "react_on_rails/spec/dummy"
MAX_ROUTES_PER_SHARD = Integer(env_or_default("MAX_ROUTES_PER_SHARD", 60))
SUITE_NAME = ENV.fetch("BENCHMARK_SUITE_NAME")
SUITE_PREFIX = ENV.fetch("BENCHMARK_SUITE_PREFIX")
ROUTES = env_or_default("ROUTES", nil)

routes = benchmark_routes_for_app(APP_DIR, ROUTES)
raise "No routes to benchmark" if routes.empty?

validate_positive_integer(MAX_ROUTES_PER_SHARD, "MAX_ROUTES_PER_SHARD")

shard_total = [(routes.length.to_f / MAX_ROUTES_PER_SHARD).ceil, 1].max

matrix = {
  include: Array.new(shard_total) do |index|
    shard_number = index + 1
    shard_label = "#{shard_number}/#{shard_total}"
    shard_slug = "shard-#{shard_number}-of-#{shard_total}"

    {
      shard_index: index,
      shard_total: shard_total,
      shard_label: shard_label,
      shard_slug: shard_slug,
      suite_name: "#{SUITE_NAME} (shard #{shard_label})",
      report_marker: "<!-- BENCHER_REPORT_#{SUITE_PREFIX}_#{shard_slug.upcase.tr('-', '_')} -->"
    }
  end
}

puts JSON.generate(matrix)

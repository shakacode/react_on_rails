#!/usr/bin/env ruby
# frozen_string_literal: true

# Emits the GitHub Actions matrix `include:` payload for one benchmark suite.
# Stdlib-only so the workflow can invoke it with the runner's system Ruby — no
# Bundler, no Rails boot.

require "json"

SHARD_TOTAL = Integer(ENV.fetch("BENCHMARK_TOTAL_SHARDS"))
SUITE_NAME = ENV.fetch("BENCHMARK_SUITE_NAME")
SUITE_PREFIX = ENV.fetch("BENCHMARK_SUITE_PREFIX")

raise "BENCHMARK_TOTAL_SHARDS must be positive (got #{SHARD_TOTAL})" unless SHARD_TOTAL.positive?

matrix = {
  include: Array.new(SHARD_TOTAL) do |index|
    shard_number = index + 1
    shard_label = "#{shard_number}/#{SHARD_TOTAL}"
    shard_slug = "shard-#{shard_number}-of-#{SHARD_TOTAL}"

    {
      shard_index: index,
      shard_total: SHARD_TOTAL,
      shard_label: shard_label,
      shard_slug: shard_slug,
      suite_name: "#{SUITE_NAME} (shard #{shard_label})",
      report_marker: "<!-- BENCHER_REPORT_#{SUITE_PREFIX}_#{shard_slug.upcase.tr('-', '_')} -->"
    }
  end
}

puts JSON.generate(matrix)

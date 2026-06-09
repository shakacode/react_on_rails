#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("lib", __dir__))

require "transport_probe"

begin
  config = RendererHarness::TransportProbe::Config.parse(ARGV)
  summary = RendererHarness::TransportProbe::Runner.new(config).run
  failures = summary.fetch(:results).values.sum do |case_results|
    case_results.values.sum { |result| result.fetch(:failures) }
  end
  exit(failures.zero? ? 0 : 3)
rescue RendererHarness::TransportProbe::UserError,
       ArgumentError,
       OptionParser::ParseError => e
  warn "transport-probe: #{e.message}"
  exit 1
rescue StandardError => e
  warn "transport-probe: unexpected error - #{e.class}: #{e.message}"
  warn e.backtrace&.first(5)&.join("\n")
  exit 2
end

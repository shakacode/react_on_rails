# frozen_string_literal: true

# Invoked via:
#   cd react_on_rails_pro/spec/dummy
#   bin/renderer-harness [options]
# which runs `bin/rails runner` against this file.

$LOAD_PATH.unshift(File.expand_path("lib", __dir__))

require "config"
require "harness"

begin
  config = RendererHarness::Config.parse(ARGV)
  summary = RendererHarness::Harness.new(config).run
  exit(summary[:requests][:failures].zero? ? 0 : 1)
rescue RendererHarness::UserError, RendererHarness::Runner::MeasurementAborted,
       ArgumentError, OptionParser::ParseError => e
  warn "renderer-harness: #{e.message}"
  exit 1
rescue StandardError => e
  warn "renderer-harness: unexpected error - #{e.class}: #{e.message}"
  warn e.backtrace&.first(5)&.join("\n")
  exit 2
end

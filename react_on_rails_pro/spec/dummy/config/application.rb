# frozen_string_literal: true

require File.expand_path("boot", __dir__)

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Test middleware for reproducing JSON parse race condition
# See: https://github.com/shakacode/react_on_rails/issues/2283
require_relative "../lib/streaming_race_simulator"

module Dummy
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.load_defaults 7.0
    config.middleware.use Rack::Deflater

    # StreamingRaceSimulator must be added AFTER Rack::Deflater so it processes
    # the uncompressed response. Activated by adding ?simulate_race=true to URLs.
    config.middleware.use StreamingRaceSimulator
  end
end

# frozen_string_literal: true

# Load the Rails application.
require File.expand_path("application", __dir__)

# Initialize the Rails application.
# Rails.application.initialize!
require "rails3/before_action" if File.basename(ENV["BUNDLE_GEMFILE"] || "") == "Gemfile.rails32"

Dummy::Application.initialize!

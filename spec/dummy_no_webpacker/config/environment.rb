# frozen_string_literal: true

# Load the Rails application.
require File.expand_path("../application", __FILE__)

# Initialize the Rails application.
# Rails.application.initialize!
if File.basename(ENV["BUNDLE_GEMFILE"] || "") == "Gemfile.rails32"
  require "rails3/before_action"
end
Dummy::Application.initialize!

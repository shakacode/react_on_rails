# frozen_string_literal: true

# Rake will automatically load any *.rake files inside of the "rakelib" folder
# See rakelib/

require_relative "./spec/react_on_rails/support/rails32_helper"

tasks = %w[run_rspec lint]
prepare_for_ci = %w[node_package dummy_apps]

if ENV["USE_COVERALLS"] == "TRUE"
  require "coveralls/rake/task"
  Coveralls::RakeTask.new
  tasks << "coveralls:push"
end

if using_rails32?
  tasks = %w[run_rspec:gem_rails32 run_rspec:dummy_no_webpacker]
  prepare_for_ci = %w[node_package dummy_apps:dummy_no_webpacker]
end

desc "Run all tests and linting"
task default: tasks

desc "All actions but no examples, good for local developer run."
task all_but_examples: ["run_rspec:all_but_examples", "lint"]

desc "Prepare for ci, including node_package, dummy app, and generator examples"
task prepare_for_ci: prepare_for_ci

desc "Runs prepare_for_ci and tasks"
task ci: [:prepare_for_ci, *tasks]

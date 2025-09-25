# frozen_string_literal: true

# Rake will automatically load any *.rake files inside of the "rakelib" folder
# See rakelib/
tasks = %w[run_rspec lint]
if ENV["USE_COVERALLS"] == "TRUE"
  require "coveralls/rake/task"
  Coveralls::RakeTask.new
  tasks << "coveralls:push"
end

desc "Run all tests and linting"
task default: tasks

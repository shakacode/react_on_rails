# Rake will automatically load any *.rake files inside of the "rakelib" folder
# See rakelib/
require "coveralls/rake/task"
Coveralls::RakeTask.new

desc "Run all tests and linting"
task default: ["run_rspec", "lint", "coveralls:push"]

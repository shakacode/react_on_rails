# Rake will automatically load any *.rake files inside of the "rakelib" folder
# See rakelib/
require "coveralls/rake/task"
Coveralls::RakeTask.new

desc "Run all tests and linting"
task default: ["run_rspec", "lint", "coveralls:push"]

desc "All actions but no examples. Good for local developer run."
task all_but_examples: ["run_rspec:all_but_examples", "lint"]

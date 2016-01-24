require "coveralls/rake/task"
require "pathname"

require_relative "task_helpers"
require_relative "example_type"

include ReactOnRails::TaskHelpers

namespace :run_rspec do
  desc "Run RSpec for top level only"
  task :gem do
    run_tests_in("", rspec_args: File.join("spec", "react_on_rails"))
  end

  task dummy: ["dummy_apps:dummy_app"] do
    run_tests_in(File.join("spec", "dummy"), env_vars: "DRIVER=selenium_firefox")
  end

  # Dynamically define Rake tasks for each example app found in the examples directory
  ExampleType.all.each do |example_type|
    desc "Runs RSpec for #{example_type.name_pretty} only"
    task example_type.rspec_task_name_short => example_type.prepare_task_name do
      run_tests_in(File.join(examples_dir, example_type.name)) # have to use relative path
    end
  end

  desc "Runs Rspec for example apps only"
  task examples: "examples:prepare_all" do
    ExampleType.all.each { |example_type| Rake::Task[example_type.rspec_task_name].invoke }
  end

  desc "(HACK) Run RSpec on spec/empty_spec in order to have SimpleCov generate a coverage report from cache"
  task :empty do
    sh %(COVERAGE=true rspec spec/empty_spec.rb)
  end

  Coveralls::RakeTask.new

  desc "run all tests"
  task run_rspec: [:gem, :dummy, :examples, :empty, :js_tests] do
    puts "Completed all RSpec tests"
  end
end

desc "js tests (same as 'npm run test')"
task :js_tests do
  sh "npm run test"
end

desc "Runs all tests. Run `rake -D run_rspec` to see all available test options"
task run_rspec: ["run_rspec:run_rspec"]

private

# Runs rspec in the given directory.
# If string is passed and it's not absolute, it's converted relative to root of the gem.
# TEST_ENV_COMMAND_NAME is used to make SimpleCov.command_name unique in order to
# prevent a name collision. Defaults to the given directory's name.
def run_tests_in(dir, options = {})
  if dir.is_a?(String)
    path = if dir.start_with?(File::SEPARATOR)
             Pathname.new(dir)
           else
             Pathname.new(File.join(gem_root, dir))
           end
  else
    path = dir
  end

  command_name = options.fetch(:command_name, path.basename)
  rspec_args = options.fetch(:rspec_args, "")
  env_vars = %(#{options.fetch(env_vars, '')} COVERAGE=true TEST_ENV_COMMAND_NAME="#{command_name}")
  sh_in_dir(path.realpath, "#{env_vars} bundle exec rspec #{rspec_args}")
end

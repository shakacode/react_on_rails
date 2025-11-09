# frozen_string_literal: true

require "coveralls/rake/task" if ENV["USE_COVERALLS"] == "TRUE"

require "pathname"

require_relative "task_helpers"
require_relative "example_type"

# rubocop:disable Metrics/BlockLength
namespace :run_rspec do
  include ReactOnRails::TaskHelpers

  # Loads data from examples_config.yml and instantiates corresponding ExampleType objects
  examples_config_file = File.expand_path("examples_config.yml", __dir__)
  examples_config = symbolize_keys(YAML.safe_load_file(examples_config_file))
  examples_config[:example_type_data].each do |example_type_data|
    ExampleType.new(packer_type: "shakapacker_examples", **symbolize_keys(example_type_data))
  end

  spec_dummy_dir = File.join("spec", "dummy")

  desc "Run RSpec for top level only"
  task :gem do
    run_tests_in("",
                 rspec_args: File.join("spec", "react_on_rails"),
                 env_vars: "RBS_TEST_TARGET='ReactOnRails::*' RUBYOPT='-rrbs/test/setup'")
  end

  desc "Runs dummy rspec with turbolinks"
  task dummy: ["dummy_apps:dummy_app"] do
    run_tests_in(spec_dummy_dir)
  end

  desc "Runs dummy rspec without turbolinks"
  task dummy_no_turbolinks: ["dummy_apps:dummy_app"] do
    run_tests_in(spec_dummy_dir,
                 env_vars: "DISABLE_TURBOLINKS=TRUE",
                 command_name: "dummy_no_turbolinks")
  end

  # Dynamically define Rake tasks for each example app found in the examples directory
  ExampleType.all[:shakapacker_examples].each do |example_type|
    puts "Creating #{example_type.rspec_task_name} task"
    desc "Runs RSpec for #{example_type.name_pretty} only"
    task example_type.rspec_task_name_short => example_type.gen_task_name do
      run_tests_in(File.join(examples_dir, example_type.name)) # have to use relative path
    end
  end

  desc "Runs Rspec for shakapacker example apps only"
  task shakapacker_examples: "shakapacker_examples:gen_all" do
    ExampleType.all[:shakapacker_examples].each { |example_type| Rake::Task[example_type.rspec_task_name].invoke }
  end

  Coveralls::RakeTask.new if ENV["USE_COVERALLS"] == "TRUE"

  desc "run all tests no examples"
  task all_but_examples: %i[gem dummy_no_turbolinks dummy js_tests] do
    puts "Completed all RSpec tests"
  end

  desc "run all dummy tests"
  task all_dummy: %i[dummy_no_turbolinks dummy] do
    puts "Completed all RSpec tests"
  end

  desc "run all tests"
  task :run_rspec, [:packer] => ["all_but_examples"] do
    Rake::Task["run_rspec:#{packer}_examples"].invoke
    puts "Completed all RSpec tests"
  end
end
# rubocop:enable Metrics/BlockLength

desc "js tests (same as 'yarn run test')"
task :js_tests do
  sh "yarn run test"
end

msg = <<-DESC.strip_heredoc
  Runs all tests, run `rake -D run_rspec` to see all available test options.
  "rake run_rspec:example_basic" is a good way to run only one generator test.
DESC
desc msg
task run_rspec: ["run_rspec:run_rspec"]

def calc_path(dir)
  if dir.is_a?(String)
    if dir.start_with?(File::SEPARATOR)
      Pathname.new(dir)
    else
      Pathname.new(File.join(gem_root, dir))
    end
  else
    dir
  end
end

# Runs rspec in the given directory.
# If string is passed and it's not absolute, it's converted relative to root of the gem.
# TEST_ENV_COMMAND_NAME is used to make SimpleCov.command_name unique in order to
# prevent a name collision. Defaults to the given directory's name.
def run_tests_in(dir, options = {})
  path = calc_path(dir)

  command_name = options.fetch(:command_name, path.basename)
  rspec_args = options.fetch(:rspec_args, "")

  # Build environment variables as an array for proper spacing
  env_tokens = []
  env_tokens << options.fetch(:env_vars, "").strip unless options.fetch(:env_vars, "").strip.empty?
  env_tokens << "TEST_ENV_COMMAND_NAME=\"#{command_name}\""
  env_tokens << "COVERAGE=true" if ENV["USE_COVERALLS"]

  env_vars = env_tokens.join(" ")
  sh_in_dir(path.realpath, "#{env_vars} bundle exec rspec #{rspec_args}")
end

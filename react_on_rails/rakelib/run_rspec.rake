# frozen_string_literal: true

require "coveralls/rake/task" if ENV["USE_COVERALLS"] == "TRUE"

require "pathname"
require "yaml"

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

  spec_dummy_dir = File.join(gem_root, "spec", "dummy")

  # RBS Runtime Type Checking Configuration
  # ========================================
  # Runtime type checking is ENABLED BY DEFAULT when RBS gem is available
  # Use ENV["DISABLE_RBS_RUNTIME_CHECKING"] = "true" to disable
  #
  # Coverage Strategy:
  # - :gem task - Enables checking for ReactOnRails::* (direct gem unit tests)
  # - :dummy tasks - Enables checking (integration tests exercise gem code paths)
  # - :example tasks - No checking (examples are user-facing demo apps)
  #
  # Rationale per Evil Martians best practices:
  # Runtime checking catches type errors in actual execution paths that static
  # analysis might miss. Dummy/integration tests exercise more code paths than
  # unit tests alone, providing comprehensive type safety validation.
  def rbs_runtime_env_vars
    return "" if ENV["DISABLE_RBS_RUNTIME_CHECKING"] == "true"

    begin
      require "rbs"
      # Preserve existing RUBYOPT flags (e.g., --enable-yjit, --jit, warnings toggles)
      # by appending RBS runtime hook instead of replacing
      existing_rubyopt = ENV.fetch("RUBYOPT", nil)
      rubyopt_parts = ["-rrbs/test/setup", existing_rubyopt].compact.reject(&:empty?)
      "RBS_TEST_TARGET='ReactOnRails::*' RUBYOPT='#{rubyopt_parts.join(' ')}'"
    rescue LoadError
      # RBS not available - silently skip runtime checking
      # This is expected in environments without the rbs gem
      ""
    end
  end

  desc "Run RSpec for top level only"
  task :gem do
    run_tests_in("",
                 rspec_args: File.join("spec", "react_on_rails"),
                 env_vars: rbs_runtime_env_vars)
  end

  desc "Runs dummy rspec with turbolinks"
  task dummy: ["dummy_apps:dummy_app"] do
    run_tests_in(spec_dummy_dir,
                 env_vars: rbs_runtime_env_vars)
  end

  desc "Runs dummy rspec without turbolinks"
  task dummy_no_turbolinks: ["dummy_apps:dummy_app"] do
    # Build env vars array for robustness with complex environment variables
    env_vars_array = []
    env_vars_array << rbs_runtime_env_vars unless rbs_runtime_env_vars.empty?
    env_vars_array << "DISABLE_TURBOLINKS=TRUE"
    env_vars = env_vars_array.join(" ")
    run_tests_in(spec_dummy_dir,
                 env_vars: env_vars,
                 command_name: "dummy_no_turbolinks")
  end

  # Dynamically define Rake tasks for each example app found in the examples directory
  ExampleType.all[:shakapacker_examples].each do |example_type|
    puts "Creating #{example_type.rspec_task_name} task"
    desc "Runs RSpec for #{example_type.name_pretty} only"
    task example_type.rspec_task_name_short => example_type.gen_task_name do
      # Use unbundled mode for pinned React version examples to ensure the example app's
      # Gemfile and gem versions are used, not the parent workspace's bundle
      run_tests_in(File.join(examples_dir, example_type.name),
                   unbundled: example_type.pinned_react_version?)
    end
  end

  desc "Runs Rspec for shakapacker example apps only"
  task shakapacker_examples: "shakapacker_examples:gen_all" do
    ExampleType.all[:shakapacker_examples].each { |example_type| Rake::Task[example_type.rspec_task_name].invoke }
  end

  # Helper methods for filtering examples by React version
  def latest_examples
    ExampleType.all[:shakapacker_examples].reject(&:pinned_react_version?)
  end

  def react18_examples
    ExampleType.all[:shakapacker_examples].select { |e| e.react_version == "18" }
  end

  def react17_examples
    ExampleType.all[:shakapacker_examples].select { |e| e.react_version == "17" }
  end

  def pinned_version_examples
    ExampleType.all[:shakapacker_examples].select(&:pinned_react_version?)
  end

  desc "Runs Rspec for latest version example apps only (React 19, Shakapacker 9.x)"
  task shakapacker_examples_latest: latest_examples.map(&:gen_task_name) do
    latest_examples.each { |example_type| Rake::Task[example_type.rspec_task_name].invoke }
  end

  desc "Runs Rspec for React 18 example apps only (Shakapacker 8.2.0)"
  task shakapacker_examples_react18: react18_examples.map(&:gen_task_name) do
    react18_examples.each { |example_type| Rake::Task[example_type.rspec_task_name].invoke }
  end

  desc "Runs Rspec for React 17 example apps only (legacy render API)"
  task shakapacker_examples_react17: react17_examples.map(&:gen_task_name) do
    react17_examples.each { |example_type| Rake::Task[example_type.rspec_task_name].invoke }
  end

  desc "Runs Rspec for all pinned version example apps (React 17 and 18)"
  task shakapacker_examples_pinned: pinned_version_examples.map(&:gen_task_name) do
    pinned_version_examples.each { |example_type| Rake::Task[example_type.rspec_task_name].invoke }
  end

  # Legacy alias for backward compatibility
  desc "Runs Rspec for minimum version example apps only (React 18, Shakapacker 8.2.0)"
  task shakapacker_examples_minimum: react18_examples.map(&:gen_task_name) do
    react18_examples.each { |example_type| Rake::Task[example_type.rspec_task_name].invoke }
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

desc "js tests (same as 'pnpm run test')"
task :js_tests do
  sh "pnpm run test"
end

msg = <<~DESC
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
# Options:
#   :command_name - name for SimpleCov (default: dir basename)
#   :rspec_args - additional rspec arguments (default: "")
#   :env_vars - additional environment variables (default: "")
#   :unbundled - run with unbundled_sh_in_dir for Bundler isolation (default: false)
#                This is required for minimum version examples because they have different
#                gem versions (e.g., Shakapacker 8.2.0) pinned in their Gemfile than the
#                parent workspace (Shakapacker 9.x). Without bundle isolation, Bundler
#                would inherit the parent's gem resolution and use the wrong versions.
#                Latest version examples don't need this because they use the same versions
#                as the parent workspace.
def run_tests_in(dir, options = {})
  path = calc_path(dir)

  command_name = options.fetch(:command_name, path.basename)
  rspec_args = options.fetch(:rspec_args, "")
  unbundled = options.fetch(:unbundled, false)

  # Build environment variables as an array for proper spacing
  env_tokens = []
  env_tokens << options.fetch(:env_vars, "").strip unless options.fetch(:env_vars, "").strip.empty?
  env_tokens << "TEST_ENV_COMMAND_NAME=\"#{command_name}\""
  env_tokens << "COVERAGE=true" if ENV["USE_COVERALLS"]

  env_vars = env_tokens.join(" ")
  command = "#{env_vars} bundle exec rspec #{rspec_args}"

  if unbundled
    unbundled_sh_in_dir(path.realpath, command)
  else
    sh_in_dir(path.realpath, command)
  end
end

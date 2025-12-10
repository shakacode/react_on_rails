# frozen_string_literal: true

# TODO: This file is not used for CI
require "coveralls/rake/task" if ENV["USE_COVERALLS"] == "TRUE"

require "pathname"
require "active_support/core_ext/string"
require_relative "task_helpers"
namespace :run_rspec do
  include ReactOnRailsPro::TaskHelpers

  spec_dummy_dir = File.join("spec", "dummy")

  desc "Run RSpec for top level only"
  task :gem do
    run_tests_in("", rspec_args: File.join("spec", "react_on_rails_pro"))
  end

  desc "Runs dummy rspec"
  task dummy: ["dummy_app:dummy_app"] do
    clean_gen_assets(spec_dummy_dir)
    bundle_install_in(dummy_app_dir)
    run_tests_in(spec_dummy_dir)
  end

  desc "(HACK) Run RSpec on spec/empty_spec in order to have SimpleCov generate a coverage report from cache"
  task :empty do
    sh %(#{ENV['USE_COVERALLS'] ? 'COVERAGE=true' : ''} rspec spec/empty_spec.rb)
  end

  Coveralls::RakeTask.new if ENV["USE_COVERALLS"] == "TRUE"

  desc "run all tests"
  task run_rspec: %i[gem dummy empty js_tests] do
    puts "Completed all RSpec tests"
  end
end

desc "js tests (same as 'yarn run test')"
task :js_tests do
  sh "yarn run test"
end

msg = <<~DESC
  Runs all tests, run `rake -D run_rspec` to see all available test options.
DESC
desc msg
task run_rspec: ["run_rspec:run_rspec"]

private

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
  env_vars = +"#{options.fetch(:env_vars, '')} TEST_ENV_COMMAND_NAME=\"#{command_name}\""
  env_vars << "COVERAGE=true" if ENV["USE_COVERALLS"]
  sh_in_dir(path.realpath, "#{env_vars} bundle exec rspec #{rspec_args}")
end

def clean_gen_assets(dir)
  path = calc_path(dir)
  sh_in_dir(path.realpath, "yarn run build:clean")
end

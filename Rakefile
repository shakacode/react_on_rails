# frozen_string_literal: true

require "bundler"

# Root Rakefile for monorepo-level tasks
#
# Package-specific task implementations live in the package Rakefiles and run
# with that package's bundle. The root Rakefile keeps compatibility wrappers for
# common root commands without loading package dependencies into the root bundle.
#
# This keeps the root bundle focused on lint/tooling/release gems while Rake still
# auto-loads monorepo-level tasks from ./rakelib/.
#
# Note: This is for development only. When the gem is installed in a Rails app,
# Rails::Engine handles rake task loading automatically from lib/tasks/.

# Define gem_root helper for use by rake tasks
def gem_root
  File.expand_path("react_on_rails", __dir__)
end

def package_rake_task(task_name, *task_args)
  task_invocation = if task_args.empty?
                      task_name.to_s
                    else
                      "#{task_name}[#{task_args.join(',')}]"
                    end

  ensure_package_bundle

  Dir.chdir(gem_root) do
    Bundler.with_unbundled_env do
      sh "bundle", "exec", "rake", task_invocation
    end
  end
end

def ensure_package_bundle
  bundle_ready = Dir.chdir(gem_root) do
    Bundler.with_unbundled_env do
      system("bundle", "check")
    end
  end

  return if bundle_ready

  puts "Installing react_on_rails bundle before delegated rake task..."
  Dir.chdir(gem_root) do
    Bundler.with_unbundled_env do
      sh "bundle", "install"
    end
  end
end

def root_bundle_exec_in(directory, *command)
  Bundler.with_unbundled_env do
    Dir.chdir(directory) do
      sh({ "BUNDLE_GEMFILE" => File.expand_path("Gemfile", __dir__) }, "bundle", "exec", *command)
    end
  end
end

def define_package_task(task_name, *arg_names)
  desc "Delegates to react_on_rails #{task_name}"
  task task_name, arg_names do |_task, args|
    package_rake_task(task_name, *arg_names.filter_map { |arg_name| args[arg_name] })
  end
end

namespace :lint do
  desc "Run root-bundle RuboCop on the OSS package directory"
  task :rubocop do
    root_bundle_exec_in(gem_root, "rubocop", "--version")
    root_bundle_exec_in(gem_root, "rubocop", ".")
  end

  desc "Auto-fix root-bundle RuboCop violations in the OSS package directory"
  task :rubocop_autofix do
    root_bundle_exec_in(gem_root, "rubocop", "-A")
    puts "Completed root RuboCop auto-fix"
  end
end

# NOTE: When adding a new package task that should work from the monorepo root,
# add it here so `rake <task>` delegates into the react_on_rails bundle.
%w[
  all_but_examples
  ci
  default
  docker
  docker:eslint
  docker:lint
  docker:rubocop
  docker:scss
  dummy_apps
  js_tests
  lint:autofix
  lint:eslint
  lint:scss
  node_package
  prepare_for_ci
  rbs:all
  rbs:check
  rbs:list
  rbs:steep
  rbs:validate
  run_rspec
  run_rspec:all_but_examples
  run_rspec:all_dummy
  run_rspec:dummy
  run_rspec:dummy_no_turbolinks
  run_rspec:gem
  run_rspec:shakapacker_examples
  run_rspec:shakapacker_examples_basic
  run_rspec:shakapacker_examples_basic-react16
  run_rspec:shakapacker_examples_basic-react17
  run_rspec:shakapacker_examples_basic-react18
  run_rspec:shakapacker_examples_basic-server-rendering
  run_rspec:shakapacker_examples_basic-server-rendering-react16
  run_rspec:shakapacker_examples_basic-server-rendering-react17
  run_rspec:shakapacker_examples_basic-server-rendering-react18
  run_rspec:shakapacker_examples_latest
  run_rspec:shakapacker_examples_pinned
  run_rspec:shakapacker_examples_react16
  run_rspec:shakapacker_examples_react17
  run_rspec:shakapacker_examples_react18
  run_rspec:shakapacker_examples_redux
  run_rspec:shakapacker_examples_redux-server-rendering
  shakapacker_examples
  shakapacker_examples:clobber
  shakapacker_examples:clobber_basic
  shakapacker_examples:clobber_basic-react16
  shakapacker_examples:clobber_basic-react17
  shakapacker_examples:clobber_basic-react18
  shakapacker_examples:clobber_basic-server-rendering
  shakapacker_examples:clobber_basic-server-rendering-react16
  shakapacker_examples:clobber_basic-server-rendering-react17
  shakapacker_examples:clobber_basic-server-rendering-react18
  shakapacker_examples:clobber_redux
  shakapacker_examples:clobber_redux-server-rendering
  shakapacker_examples:gen_all
  shakapacker_examples:gen_basic
  shakapacker_examples:gen_basic-react16
  shakapacker_examples:gen_basic-react17
  shakapacker_examples:gen_basic-react18
  shakapacker_examples:gen_basic-server-rendering
  shakapacker_examples:gen_basic-server-rendering-react16
  shakapacker_examples:gen_basic-server-rendering-react17
  shakapacker_examples:gen_basic-server-rendering-react18
  shakapacker_examples:gen_redux
  shakapacker_examples:gen_redux-server-rendering
].each { |task_name| define_package_task(task_name) }

desc "Run root-bundle RuboCop on the OSS package directory"
task lint: ["lint:rubocop"]

desc "Auto-fix all linting violations via the package task"
task autofix: ["lint:autofix"]

define_package_task("run_rspec:run_rspec", :packer)
define_package_task("shakapacker:update_version", :version)
define_package_task("update_changelog", :mode_or_tag)

# NOTE: Monorepo-level rake tasks from ./rakelib/ are auto-loaded by Rake.
# Do NOT explicitly load them here, as that would cause tasks to be defined twice
# and their bodies would run twice (Rake appends duplicate task definitions).

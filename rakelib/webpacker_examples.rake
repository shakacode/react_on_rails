# frozen_string_literal: true

# Defines tasks related to generating example apps using the gem's generator.
# Allows us to create and test apps generated using a wide range of options.
#
# Also see example_type.rb

require "yaml"
require "rails/version"
require "pathname"

require_relative "example_type"
require_relative "task_helpers"

namespace :webpacker_examples do # rubocop:disable Metrics/BlockLength
  include ReactOnRails::TaskHelpers

  # Define tasks for each example type
  ExampleType.all[:webpacker_examples].each do |example_type|
    relative_gem_root = Pathname(gem_root).relative_path_from(Pathname(example_type.dir))
    # CLOBBER
    desc "Clobbers (deletes) #{example_type.name_pretty}"
    task example_type.clobber_task_name_short do
      rm_rf(example_type.dir)
    end

    # GENERATE
    desc "Generates #{example_type.name_pretty}"
    task example_type.gen_task_name_short => example_type.clobber_task_name do
      puts "Running webpacker_examples:#{example_type.gen_task_name_short}"
      mkdir_p(example_type.dir)
      example_type.rails_options += "--skip-javascript"
      sh_in_dir(examples_dir, "rails new #{example_type.name} #{example_type.rails_options}")
      sh_in_dir(example_type.dir, "touch .gitignore")
      sh_in_dir(example_type.dir,
                "echo \"gem 'react_on_rails', path: '#{relative_gem_root}'\" >> #{example_type.gemfile}")
      sh_in_dir(example_type.dir, "echo \"gem 'shakapacker', '>= 8.2.0'\" >> #{example_type.gemfile}")
      bundle_install_in(example_type.dir)
      sh_in_dir(example_type.dir, "rake shakapacker:install")
      shell_commands = []
      env = "PACKAGE_JSON_FALLBACK_MANAGER=yarn_classic"
      options = example_type.generator_options
      shell_commands << "#{env} rails generate react_on_rails:install #{options} --ignore-warnings --force"
      shell_commands << "#{env} rails generate react_on_rails:dev_tests #{options}"
      sh_in_dir(example_type.dir, "yarn")
    end
  end

  desc "Clobbers (deletes) all example apps"
  task :clobber do
    rm_rf(examples_dir)
  end

  desc "Generates all example apps"
  task gen_all: ExampleType.all[:webpacker_examples].map(&:gen_task_name)
end

desc "Generates all example apps. Run `rake -D examples` to see all available options"
task webpacker_examples: ["webpacker_examples:gen_all"]

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

namespace :shakapacker_examples do # rubocop:disable Metrics/BlockLength
  include ReactOnRails::TaskHelpers
  # Loads data from examples_config.yml and instantiates corresponding ExampleType objects
  examples_config_file = File.expand_path("examples_config.yml", __dir__)
  examples_config = symbolize_keys(YAML.safe_load_file(examples_config_file))
  examples_config[:example_type_data].each { |example_type_data| ExampleType.new(packer_type: "shakapacker_examples", **symbolize_keys(example_type_data)) }

  

  # Define tasks for each example type
  ExampleType.all.each do |example_type|
    relative_gem_root = Pathname(gem_root).relative_path_from(Pathname(example_type.dir))
    # CLOBBER
    desc "Clobbers (deletes) #{example_type.name_pretty}"
    task example_type.clobber_task_name_short do
      rm_rf(example_type.dir)
    end

    # GENERATE
    desc "Generates #{example_type.name_pretty}"
    task example_type.gen_task_name_short => example_type.clobber_task_name do
      puts "Running shakapacker_examples:#{example_type.gen_task_name_short}"
      mkdir_p(example_type.dir)
      example_type.rails_options += "--skip-javascript"
      sh_in_dir(examples_dir, "rails new #{example_type.name} #{example_type.rails_options}")
      sh_in_dir(example_type.dir, "touch .gitignore")
      sh_in_dir(example_type.dir, "echo \"gem 'react_on_rails', path: '#{relative_gem_root}'\" >> #{example_type.gemfile}")
      sh_in_dir(example_type.dir, "echo \"gem 'shakapacker', '~> 8.0.0'\" >> #{example_type.gemfile}")
      sh_in_dir(example_type.dir, "cat #{example_type.gemfile}")
      bundle_install_in(example_type.dir)
      sh_in_dir(example_type.dir, "rake shakapacker:install")
      sh_in_dir(example_type.dir, example_type.generator_shell_commands)
      sh_in_dir(example_type.dir, "yarn")
    end
  end

  desc "Clobbers (deletes) all example apps"
  task :clobber do
    rm_rf(examples_dir)
  end

  desc "Generates all example apps"
  task gen_all: ExampleType.all.map(&:gen_task_name)
end

desc "Generates all example apps. Run `rake -D examples` to see all available options"
task shakapacker_examples: ["shakapacker_examples:gen_all"]

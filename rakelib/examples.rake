# frozen_string_literal: true

# Defines tasks related to generating example apps using the gem's generator.
# Allows us to create and test apps generated using a wide range of options.
#
# Also see example_type.rb

require "yaml"
require_relative "example_type"
require_relative "task_helpers"

namespace :examples do # rubocop:disable Metrics/BlockLength
  include ReactOnRails::TaskHelpers
  # Loads data from examples_config.yml and instantiates corresponding ExampleType objects
  examples_config_file = File.expand_path("examples_config.yml", __dir__)
  examples_config = symbolize_keys(YAML.safe_load(File.read(examples_config_file)))
  examples_config[:example_type_data].each { |example_type_data| ExampleType.new(symbolize_keys(example_type_data)) }

  # Define tasks for each example type
  ExampleType.all.each do |example_type|
    # CLOBBER
    desc "Clobbers (deletes) #{example_type.name_pretty}"
    task example_type.clobber_task_name_short do
      rm_rf(example_type.dir)
    end

    # GENERATE
    desc "Generates #{example_type.name_pretty}"
    task example_type.gen_task_name_short => example_type.clobber_task_name do
      mkdir_p(example_type.dir)
      sh_in_dir(examples_dir, "rails new #{example_type.name} #{example_type.rails_options}")
      sh_in_dir(example_type.dir, "touch .gitignore")
      sh_in_dir(example_type.dir, "rake webpacker:install")
      sh_in_dir(example_type.dir, "bundle binstubs --path=#{example_type.dir}/bin webpacker")
      sh_in_dir(example_type.dir, "rake webpacker:install:react")
      append_to_gemfile(example_type.gemfile, example_type.required_gems)
      bundle_install_in(example_type.dir)
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
task examples: ["examples:gen_all"]

private

# Appends each string in an array as a new line of text in the given Gemfile.
# Automatically adds line returns.
def append_to_gemfile(gemfile, lines)
  old_text = File.read(gemfile)
  new_text = lines.reduce(old_text) { |a, e| a << "#{e}\n" }
  File.open(gemfile, "w") { |f| f.puts(new_text) }
end

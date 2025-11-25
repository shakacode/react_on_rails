# frozen_string_literal: true

# Defines tasks related to generating example apps using the gem's generator.
# Allows us to create and test apps generated using a wide range of options.
#
# Also see example_type.rb

require "yaml"
require "rails/version"
require "pathname"
require "json"

require_relative "example_type"
require_relative "task_helpers"

namespace :shakapacker_examples do # rubocop:disable Metrics/BlockLength
  include ReactOnRails::TaskHelpers

  # Updates package.json to use minimum supported versions for compatibility testing
  def apply_minimum_versions(dir) # rubocop:disable Metrics/CyclomaticComplexity
    package_json_path = File.join(dir, "package.json")
    return unless File.exist?(package_json_path)

    begin
      package_json = JSON.parse(File.read(package_json_path))
    rescue JSON::ParserError => e
      puts "  ERROR: Failed to parse package.json in #{dir}: #{e.message}"
      raise
    end

    # Update React versions to minimum supported
    if package_json["dependencies"]
      package_json["dependencies"]["react"] = ExampleType::MINIMUM_REACT_VERSION
      package_json["dependencies"]["react-dom"] = ExampleType::MINIMUM_REACT_VERSION
    end

    # Update Shakapacker to minimum supported version
    if package_json["devDependencies"]&.key?("shakapacker")
      package_json["devDependencies"]["shakapacker"] = ExampleType::MINIMUM_SHAKAPACKER_VERSION
    elsif package_json["dependencies"]&.key?("shakapacker")
      package_json["dependencies"]["shakapacker"] = ExampleType::MINIMUM_SHAKAPACKER_VERSION
    end

    File.write(package_json_path, "#{JSON.pretty_generate(package_json)}\n")
    puts "  Updated package.json with minimum versions:"
    puts "    React: #{ExampleType::MINIMUM_REACT_VERSION}"
    puts "    Shakapacker: #{ExampleType::MINIMUM_SHAKAPACKER_VERSION}"
  end

  # Define tasks for each example type
  ExampleType.all[:shakapacker_examples].each do |example_type|
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
      sh_in_dir(examples_dir, "rails new #{example_type.name} #{example_type.rails_options} --skip-javascript")
      sh_in_dir(example_type.dir, "touch .gitignore")
      sh_in_dir(example_type.dir,
                "echo \"gem 'react_on_rails', path: '#{relative_gem_root}'\" >> #{example_type.gemfile}")
      sh_in_dir(example_type.dir, "echo \"gem 'shakapacker', '>= 8.2.0'\" >> #{example_type.gemfile}")
      bundle_install_in(example_type.dir)
      sh_in_dir(example_type.dir, "rake shakapacker:install")
      # Skip validation when running generators on example apps during development.
      # The generator validates that certain config options exist in the initializer,
      # but during example generation, we're often testing against the current gem
      # codebase which may have new config options not yet in the released version.
      # This allows examples to be generated without validation errors while still
      # testing the generator functionality.
      generator_commands = example_type.generator_shell_commands.map do |cmd|
        "REACT_ON_RAILS_SKIP_VALIDATION=true #{cmd}"
      end
      sh_in_dir(example_type.dir, generator_commands)

      # Apply minimum versions for compatibility testing examples
      apply_minimum_versions(example_type.dir) if example_type.minimum_versions

      sh_in_dir(example_type.dir, "npm install")
      # Generate the component packs after running the generator to ensure all
      # auto-bundled components have corresponding pack files created
      sh_in_dir(example_type.dir, "bundle exec rake react_on_rails:generate_packs")
    end
  end

  desc "Clobbers (deletes) all example apps"
  task :clobber do
    rm_rf(examples_dir)
  end

  desc "Generates all example apps"
  task gen_all: ExampleType.all[:shakapacker_examples].map(&:gen_task_name)
end

desc "Generates all example apps. Run `rake -D examples` to see all available options"
task shakapacker_examples: ["shakapacker_examples:gen_all"]

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

  # Updates React-related dependencies to minimum supported versions
  def update_react_dependencies(deps)
    return unless deps

    deps["react"] = ExampleType::MINIMUM_REACT_VERSION
    deps["react-dom"] = ExampleType::MINIMUM_REACT_VERSION
    # Shakapacker 8.2.0 requires webpack-assets-manifest ^5.x
    deps["webpack-assets-manifest"] = "^5.0.6" if deps.key?("webpack-assets-manifest")
  end

  # Updates Shakapacker to minimum supported version in either dependencies or devDependencies
  def update_shakapacker_dependency(deps, dev_deps)
    if dev_deps&.key?("shakapacker")
      dev_deps["shakapacker"] = ExampleType::MINIMUM_SHAKAPACKER_VERSION
    elsif deps&.key?("shakapacker")
      deps["shakapacker"] = ExampleType::MINIMUM_SHAKAPACKER_VERSION
    end
  end

  # Updates dependencies in package.json to use minimum supported versions
  def update_package_json_versions(package_json_path)
    return unless File.exist?(package_json_path)

    begin
      package_json = JSON.parse(File.read(package_json_path))
    rescue JSON::ParserError => e
      puts "  ERROR: Failed to parse #{package_json_path}: #{e.message}"
      raise
    end

    deps = package_json["dependencies"]
    dev_deps = package_json["devDependencies"]

    update_react_dependencies(deps)
    # Shakapacker 8.2.0 requires webpack-assets-manifest ^5.x (check devDependencies too)
    dev_deps["webpack-assets-manifest"] = "^5.0.6" if dev_deps&.key?("webpack-assets-manifest")
    update_shakapacker_dependency(deps, dev_deps)

    File.write(package_json_path, "#{JSON.pretty_generate(package_json)}\n")
  end

  # Updates Gemfile to pin shakapacker to minimum version
  # (must match the npm package version exactly)
  def update_gemfile_versions(gemfile_path)
    return unless File.exist?(gemfile_path)

    gemfile_content = File.read(gemfile_path)
    # Replace any shakapacker gem line with exact version pin
    # Handle both single-line: gem 'shakapacker', '>= 8.2.0'
    # And multi-line declarations:
    #   gem 'shakapacker',
    #       '>= 8.2.0'
    gemfile_content = gemfile_content.gsub(
      /gem ['"]shakapacker['"][^\n]*(?:\n\s+[^g\n][^\n]*)*$/m,
      "gem 'shakapacker', '#{ExampleType::MINIMUM_SHAKAPACKER_VERSION}'"
    )
    File.write(gemfile_path, gemfile_content)
  end

  # Updates package.json and Gemfile to use minimum supported versions for compatibility testing
  def apply_minimum_versions(dir)
    update_package_json_versions(File.join(dir, "package.json"))
    update_gemfile_versions(File.join(dir, "Gemfile"))

    puts "  Updated package.json with minimum versions:"
    puts "    React: #{ExampleType::MINIMUM_REACT_VERSION}"
    puts "    Shakapacker: #{ExampleType::MINIMUM_SHAKAPACKER_VERSION}"
  end

  # Define tasks for each example type
  ExampleType.all[:shakapacker_examples].each do |example_type| # rubocop:disable Metrics/BlockLength
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
      # Re-run bundle install since dev_tests generator adds rspec-rails and coveralls to Gemfile
      bundle_install_in(example_type.dir)

      # Apply minimum versions for compatibility testing examples
      if example_type.minimum_versions
        apply_minimum_versions(example_type.dir)
        # Re-run bundle install since Gemfile was updated with pinned shakapacker version
        bundle_install_in(example_type.dir)
      end

      sh_in_dir(example_type.dir, "npm install")
      # Generate the component packs after running the generator to ensure all
      # auto-bundled components have corresponding pack files created.
      # Use unbundled_sh_in_dir to ensure we're using the generated app's Gemfile
      # and gem versions, not the parent workspace's bundle context.
      unbundled_sh_in_dir(example_type.dir, "bundle exec rake react_on_rails:generate_packs")
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

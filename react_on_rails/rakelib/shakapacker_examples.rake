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

  # Updates React-related dependencies to a specific version
  def update_react_dependencies(deps, react_version)
    return unless deps

    deps["react"] = react_version
    deps["react-dom"] = react_version
  end

  # Updates dependencies in package.json to use specific React version
  def update_package_json_for_react_version(package_json_path, react_version)
    return unless File.exist?(package_json_path)

    begin
      package_json = JSON.parse(File.read(package_json_path))
    rescue JSON::ParserError => e
      puts "  ERROR: Failed to parse #{package_json_path}: #{e.message}"
      raise
    end

    deps = package_json["dependencies"]
    dev_deps = package_json["devDependencies"]

    update_react_dependencies(deps, react_version)
    # Shakapacker 8.2.0 requires webpack-assets-manifest ^5.x (v6.x uses ESM and breaks)
    # Always add this explicitly since the transitive dependency from shakapacker may be v6.x
    dev_deps["webpack-assets-manifest"] = "^5.0.6" if dev_deps
    # Shakapacker 8.2.0 requires babel-loader to be explicitly installed as a devDependency
    # (in 9.x this requirement was relaxed or the package structure changed)
    dev_deps["babel-loader"] = "^9.1.3" if dev_deps
    # @babel/plugin-transform-runtime is required by the default babel config but not
    # automatically included as a dependency in older Shakapacker versions
    dev_deps["@babel/plugin-transform-runtime"] = "^7.24.0" if dev_deps

    # Add npm overrides to force specific React version, preventing
    # react-on-rails from pulling in React 19 as a transitive dependency
    package_json["overrides"] = {
      "react" => react_version,
      "react-dom" => react_version
    }

    File.write(package_json_path, "#{JSON.pretty_generate(package_json)}\n")
  end

  # Updates package.json and Gemfile to use specific React version for compatibility testing
  def apply_react_version(dir, react_version)
    update_package_json_for_react_version(File.join(dir, "package.json"), react_version)

    puts "  Updated package.json for compatibility testing:"
    puts "    React: #{react_version}"
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
      # Shakapacker is automatically included as a dependency via react_on_rails.gemspec (>= 6.0)
      bundle_install_in(example_type.dir)
      # Use unbundled_sh_in_dir to ensure we're using the generated app's Gemfile
      # and gem versions, not the parent workspace's bundle context.
      unbundled_sh_in_dir(example_type.dir, "bundle exec rake shakapacker:install")
      # Skip validation when running generators on example apps during development.
      # The generator validates that certain config options exist in the initializer,
      # but during example generation, we're often testing against the current gem
      # codebase which may have new config options not yet in the released version.
      # This allows examples to be generated without validation errors while still
      # testing the generator functionality.
      generator_commands = example_type.generator_shell_commands.map do |cmd|
        "REACT_ON_RAILS_SKIP_VALIDATION=true #{cmd}"
      end
      # Use unbundled_sh_in_dir to ensure the generator uses the example app's
      # gem versions, not the parent workspace's cached bundle context.
      unbundled_sh_in_dir(example_type.dir, generator_commands)
      # Re-run bundle install since dev_tests generator adds rspec-rails and coveralls to Gemfile
      bundle_install_in(example_type.dir)

      # Apply specific React version for compatibility testing examples
      if example_type.pinned_react_version?
        apply_react_version(example_type.dir, example_type.react_version_string)
        # Re-run bundle install to ensure dependencies are resolved correctly
        bundle_install_in(example_type.dir)
        # Run npm install BEFORE shakapacker:binstubs to ensure the npm shakapacker version
        # matches the gem version. The binstubs task loads the Rails environment which
        # validates version matching between gem and npm package.
        # Use --legacy-peer-deps to avoid peer dependency conflicts when
        # react-on-rails expects newer React versions
        # Use --install-links to copy file: dependencies instead of symlinking,
        # preventing duplicate React instances from webpack resolving through symlinks
        sh_in_dir(example_type.dir, "npm install --legacy-peer-deps --install-links")
        # Regenerate Shakapacker binstubs after downgrading from 9.x to 8.2.x
        # The binstub format may differ between major versions
        unbundled_sh_in_dir(example_type.dir, "bundle exec rake shakapacker:binstubs")
      else
        # Use --install-links to copy file: dependencies instead of symlinking,
        # preventing duplicate React instances from webpack resolving through symlinks
        sh_in_dir(example_type.dir, "npm install --install-links")
      end
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

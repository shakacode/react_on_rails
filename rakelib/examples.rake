# Defines tasks related to generating example apps using the gem's generator.
# Allows us to create and test apps generated using a wide range of options.
#
# Also see example_type.rb

require "yaml"
require_relative "example_type"
require_relative "task_helpers"
include ReactOnRails::TaskHelpers

namespace :examples do
  # Loads data from examples_config.yml and instantiates corresponding ExampleType objects
  examples_config_file = File.expand_path("../examples_config.yml", __FILE__)
  examples_config = symbolize_keys(YAML.load(File.read(examples_config_file)))
  examples_config[:example_type_data].each { |example_type_data| ExampleType.new(symbolize_keys(example_type_data)) }

  # Define tasks for each example type
  ExampleType.all.each do |example_type|
    # GENERATED FILES
    example_type.generated_files.each do |f|
      file f => example_type.source_files do
        Rake::Task[example_type.gen_task_name].invoke
      end
    end

    # GEMFILE.LOCK
    file example_type.gemfile_lock => example_type.gemfile do
      bundle_install_in(example_type.dir)
    end

    # WEBPACK BUNDLES
    example_type.webpack_bundles.each do |f|
      file f => example_type.generated_client_files do
        Rake::Task[example_type.build_webpack_bundles_task_name].invoke
      end
    end

    # BUILD WEBPACK BUNDLES
    task example_type.build_webpack_bundles_task_name_short => example_type.npm_install_task_name do
      sh_in_dir(example_type.client_dir, example_type.build_webpack_bundles_shell_commands)
    end

    # NPM INSTALL
    task example_type.npm_install_task_name_short => example_type.package_json do
      unless uptodate?(example_type.node_modules_dir, [example_type.source_package_json])
        sh_in_dir(example_type.client_dir, "yarn install --mutex network")
      end
    end

    # CLEAN
    desc "Cleans #{example_type.name_pretty}"
    task example_type.clean_task_name_short do
      example_type.clean_files.each { |f| rm_rf(f) }
    end

    # CLOBBER
    desc "Clobbers (deletes) #{example_type.name_pretty}"
    task example_type.clobber_task_name_short do
      rm_rf(example_type.dir)
    end

    # GENERATE
    desc "Generates #{example_type.name_pretty}"
    task example_type.gen_task_name_short => example_type.clean_task_name do
      mkdir_p(example_type.dir)
      sh_in_dir(examples_dir, "rails new #{example_type.name} #{example_type.rails_options}")
      sh_in_dir(example_type.dir, "touch .gitignore")
      append_to_gemfile(example_type.gemfile, example_type.required_gems)
      bundle_install_in(example_type.dir)
      sh_in_dir(example_type.dir, example_type.generator_shell_commands)
    end

    # PREPARE
    desc "Prepares #{example_type.name_pretty} (generates example, `yarn`s, and generates webpack bundles)"
    multitask example_type.prepare_task_name_short => example_type.prepared_files do
      Rake::Task["node_package"].invoke
    end
  end

  desc "Cleans all example apps"
  multitask clean: ExampleType.all.map(&:clean_task_name)

  desc "Clobbers (deletes) all example apps"
  task :clobber do
    rm_rf(examples_dir)
  end

  desc "Generates all example apps"
  multitask gen_all: ExampleType.all.map(&:gen_task_name)

  desc "Prepares all example apps"
  multitask prepare_all: ExampleType.all.map(&:prepare_task_name)
end

desc "Prepares all example apps. Run `rake -D examples` to see all available options"
multitask examples: ["examples:prepare_all"]

private

# Appends each string in an array as a new line of text in the given Gemfile.
# Automatically adds line returns.
def append_to_gemfile(gemfile, lines)
  old_text = File.read(gemfile)
  new_text = lines.reduce(old_text) { |a, e| a << "#{e}\n" }
  File.open(gemfile, "w") { |f| f.puts(new_text) }
end

# frozen_string_literal: true

require "rake"
require "pathname"

require_relative "task_helpers"

# Defines the ExampleType class, where each object represents a unique type of example
# app that we can generate.
module ReactOnRails
  module TaskHelpers
    class ExampleType
      def self.all
        @example_types ||= []
      end

      def self.namespace_name
        "examples"
      end

      attr_reader :name, :generator_options

      def initialize(name: nil, generator_options: nil)
        @name = name
        @generator_options = generator_options
        self.class.all << self
      end

      def name_pretty
        "#{@name} example app"
      end

      def dir
        File.join(examples_dir, name)
      end

      def dir_exist?
        Dir.exist?(dir)
      end

      def client_dir
        File.join(dir, "client")
      end

      def source_package_json
        File.join(gem_root, "lib/generators/react_on_rails/templates/base/base/client/package.json.tt")
      end

      def node_modules_dir
        File.join(client_dir, "node_modules")
      end

      def webpack_bundles_dir
        File.join(dir, "public", "webpack", "test")
      end

      def webpack_bundles
        bundles = []
        bundles << File.join(webpack_bundles_dir, "webpack-bundle.js")
      end

      def gemfile
        File.join(dir, "Gemfile")
      end

      def gemfile_lock
        "#{gemfile}.lock"
      end

      def package_json
        File.join(client_dir, "package.json")
      end

      # Gems we need to add to the Gemfile before bundle installing
      def required_gems
        relative_gem_root = Pathname(gem_root).relative_path_from(Pathname(dir))
        ["gem 'react_on_rails', path: '#{relative_gem_root}'"]
      end

      # Options we pass when running `rails new` from the command-line
      def rails_options
        "--skip-bundle --skip-spring --skip-git --skip-test-unit --skip-active-record"
      end

      %w[gen prepare clean clobber npm_install build_webpack_bundles].each do |task_type|
        method_name_normal = "#{task_type}_task_name"          # ex: `clean_task_name`
        method_name_short = "#{method_name_normal}_short"      # ex: `clean_task_name_short`

        define_method(method_name_normal) { "#{self.class.namespace_name}:#{task_type}_#{name}" }
        define_method(method_name_short) { "#{task_type}_#{name}" }
      end

      def rspec_task_name_short
        "example_#{name}"
      end

      def rspec_task_name
        "run_rspec:#{rspec_task_name_short}"
      end

      def source_files
        FileList.new(all_files_in_dir(generators_source_dir))
      end

      # Note: we need to explicitly declare a file we know is supposed to be there
      # to indicate that the example is in need of being rebuilt in the case of its absence.
      def generated_files
        FileList.new(all_files_in_dir(dir)) do |fl|
          fl.include(gemfile)                          # explicitly declared file (dependency of Gemfile.lock)
          fl.include(package_json)                     # explicitly declared file (dependency of NPM Install)
          fl.exclude(%r{client(/node_modules(.+)?)?$}) # leave node_modules folder
        end
      end

      def generated_client_files
        generated_files.exclude { |f| !f.start_with?(client_dir) }
      end

      # generated files plus explicitly included files resulting from running
      # bundle install, yarn, and generating the webpack bundles
      def prepared_files
        generated_files
          .include(webpack_bundles)
          .include(node_modules_dir)
          .include(gemfile_lock)
      end

      def clean_files
        generated_files
      end

      # Assumes we are inside client folder
      def build_webpack_bundles_shell_commands
        webpack_command = File.join("$(yarn bin)", "webpack")
        shell_commands = []
        shell_commands << "NODE_ENV=test #{webpack_command} --config webpack.config.js"
      end

      # Assumes we are inside a rails app's folder and necessary gems have been installed
      def generator_shell_commands
        shell_commands = []
        shell_commands << "rails generate react_on_rails:install #{generator_options} --ignore-warnings"
        shell_commands << "rails generate react_on_rails:dev_tests #{generator_options}"
      end

      private

      # Defines globs that scoop up all files (including dotfiles) in given directory
      def all_files_in_dir(p_dir)
        [File.join(p_dir, "**", "*"), File.join(p_dir, "**", ".*")]
      end
    end
  end
end

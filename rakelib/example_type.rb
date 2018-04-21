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
        @all ||= []
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

      def gemfile
        File.join(dir, "Gemfile")
      end

      # Gems we need to add to the Gemfile before bundle installing
      def required_gems
        relative_gem_root = Pathname(gem_root).relative_path_from(Pathname(dir))
        ["gem 'react_on_rails', path: '#{relative_gem_root}'"]
      end

      # Options we pass when running `rails new` from the command-line.
      def rails_options
        "--skip-bundle --skip-spring --skip-git --skip-test-unit --skip-active-record"
      end

      %w[gen clobber npm_install build_webpack_bundles].each do |task_type|
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

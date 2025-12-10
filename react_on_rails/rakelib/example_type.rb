# frozen_string_literal: true

require "rake"

require_relative "task_helpers"
require_relative File.join(__dir__, "..", "lib", "react_on_rails", "utils")

# Defines the ExampleType class, where each object represents a unique type of example
# app that we can generate.
module ReactOnRails
  module TaskHelpers
    class ExampleType
      def self.all
        @all ||= { shakapacker_examples: [] }
      end

      # Supported React versions for compatibility testing
      # Keys are major version strings, values are specific version to pin to (nil = latest)
      REACT_VERSIONS = {
        "16" => "16.14.0",
        "17" => "17.0.2",
        "18" => "18.0.0",
        "19" => nil # nil means use latest (default)
      }.freeze

      # Supported React major versions (we test with latest patch of each)
      MINIMUM_SUPPORTED_REACT_MAJOR_VERSION = "16"
      LATEST_REACT_MAJOR_VERSION = "19"

      # Minimum Shakapacker version for compatibility testing
      MINIMUM_SHAKAPACKER_VERSION = "8.2.0"

      attr_reader :packer_type, :name, :generator_options, :react_version

      # Returns true if this example uses a pinned (non-latest) React version
      def pinned_react_version?
        !react_version.nil?
      end

      # Returns the actual React version string to use
      def react_version_string
        return nil unless react_version

        REACT_VERSIONS[react_version.to_s] || react_version
      end

      def initialize(packer_type: nil, name: nil, generator_options: nil, react_version: nil)
        @packer_type = packer_type
        @name = name
        @generator_options = generator_options
        @react_version = react_version

        # Validate react_version is a known version to catch configuration errors early
        if @react_version && !REACT_VERSIONS.key?(@react_version.to_s)
          valid_versions = REACT_VERSIONS.keys.join(", ")
          raise ArgumentError, "Invalid react_version '#{@react_version}' for example '#{name}'. " \
                               "Valid versions: #{valid_versions}"
        end

        self.class.all[packer_type.to_sym] << self
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

      # Options we pass when running `rails new` from the command-line.
      attr_writer :rails_options

      def rails_options
        @rails_options ||= if ReactOnRails::Utils.rails_version_less_than("7.0")
                             "--skip-bundle --skip-spring --skip-git --skip-test-unit --skip-active-record -J"
                           else
                             "--skip-bundle --skip-spring --skip-git --skip-test-unit --skip-active-record -j webpack"
                           end
      end

      %w[gen clobber npm_install build_webpack_bundles].each do |task_type|
        method_name_normal = "#{task_type}_task_name"          # ex: `clean_task_name`
        method_name_short = "#{method_name_normal}_short"      # ex: `clean_task_name_short`

        define_method(method_name_normal) { "#{@packer_type}:#{task_type}_#{name}" }
        define_method(method_name_short) { "#{task_type}_#{name}" }
      end

      def rspec_task_name_short
        "#{packer_type}_#{name}"
      end

      def rspec_task_name
        "run_rspec:#{rspec_task_name_short}"
      end

      # Assumes we are inside a rails app's folder and necessary gems have been installed
      def generator_shell_commands
        shell_commands = []
        shell_commands << "rails generate react_on_rails:install #{generator_options} --ignore-warnings --force"
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

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

      attr_reader :packer_type, :name, :generator_options

      def initialize(packer_type: nil, name: nil, generator_options: nil)
        @packer_type = packer_type
        @name = name
        @generator_options = generator_options
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

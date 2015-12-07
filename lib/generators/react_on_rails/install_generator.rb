require "rails/generators"
require_relative "generator_helper"
require_relative "generator_messages"

module ReactOnRails
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include GeneratorHelper

      # fetch USAGE file for details generator description
      source_root(File.expand_path("../", __FILE__))

      # --redux
      class_option :redux,
                   type: :boolean,
                   default: false,
                   desc: "Install Redux gems and Redux version of Hello World Example. Default: false",
                   aliases: "-R"
      # --server-rendering
      class_option :server_rendering,
                   type: :boolean,
                   default: false,
                   desc: "Add necessary files and configurations for server-side rendering. Default: false",
                   aliases: "-S"
      # --skip-js-linters
      class_option :skip_js_linters,
                   type: :boolean,
                   default: false,
                   desc: "Skip installing JavaScript linting files. Default: false",
                   aliases: "-j"
      # --ruby-linters
      class_option :ruby_linters,
                   type: :boolean,
                   default: false,
                   desc: "Install ruby linting files, tasks, and configs. Default: false",
                   aliases: "-L"
      # --ruby-linters
      class_option :heroku_deployment,
                   type: :boolean,
                   default: false,
                   desc: "Install files necessary for deploying to Heroku. Default: false",
                   aliases: "-H"
      # --skip-bootstrap
      class_option :skip_bootstrap,
                   type: :boolean,
                   default: false,
                   desc: "Skip integrating Bootstrap and don't initialize files and regarding configs. Default: false",
                   aliases: "-b"

      # --ignore-warnings
      class_option :ignore_warnings,
                   type: :boolean,
                   default: false,
                   desc: "Skip warnings. Default: false"

      def run_generators
        if installation_prerequisites_met? || options.ignore_warnings?
          invoke_generators
        else
          error = "react_on_rails generator prerequisites not met!"
          GeneratorMessages.add_error(error)
          # fail("react_on_rails generator prerequisites not met!")
        end
      ensure
        print_errors
      end

      # Everything here is not run automatically b/c it's private

      private

      def print_errors
        GeneratorMessages.errors.each { |errors| puts errors }
      end

      def invoke_generators # rubocop:disable Metrics/CyclomaticComplexity
        invoke "react_on_rails:base"
        invoke "react_on_rails:react_no_redux" unless options.redux?
        invoke "react_on_rails:react_with_redux" if options.redux?
        invoke "react_on_rails:js_linters" unless options.skip_js_linters?
        invoke "react_on_rails:ruby_linters" if options.ruby_linters?
        invoke "react_on_rails:heroku_deployment" if options.heroku_deployment?
        invoke "react_on_rails:bootstrap" unless options.skip_bootstrap?
      end

      # NOTE: other requirements for existing files such as .gitignore or application.
      # js(.coffee) are not checked by this method, but instead produce warning messages
      # and allow the build to continue
      def installation_prerequisites_met?
        !(missing_node? || missing_npm? || uncommitted_changes?)
      end

      def missing_npm?
        return false unless `which npm`.blank?
        error = "npm is required. Please install it before continuing. "
        error << "https://www.npmjs.com/"
        GeneratorMessages.add_error(error)
        true
      end

      def missing_node?
        return false unless `which node`.blank?
        error = "** nodejs is required. Please install it before continuing. "
        error << "https://nodejs.org/en/"
        GeneratorMessages.add_error(error)
        true
      end

      def uncommitted_changes?
        return false if ENV["COVERAGE"]
        status = `git status`
        return false if status.include?("nothing to commit, working directory clean")
        error = "You have uncommitted code. Please commit or stash your changes before continuing"
        GeneratorMessages.add_error(error)
        true
      end
    end
  end
end

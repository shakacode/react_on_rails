# frozen_string_literal: true

require "rails/generators"
require_relative "generator_helper"
require_relative "generator_messages"

module ReactOnRails
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include GeneratorHelper

      # fetch USAGE file for details generator description
      source_root(File.expand_path(__dir__))

      # --redux
      class_option :redux,
                   type: :boolean,
                   default: false,
                   desc: "Install Redux gems and Redux version of Hello World Example. Default: false",
                   aliases: "-R"

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
        end
      ensure
        print_generator_messages
      end

      # Everything here is not run automatically b/c it's private

      private

      def print_generator_messages
        GeneratorMessages.messages.each { |message| puts message }
      end

      def invoke_generators
        invoke "react_on_rails:base"
        if options.redux?
          invoke "react_on_rails:react_with_redux"
        else
          invoke "react_on_rails:react_no_redux"
        end
      end

      # NOTE: other requirements for existing files such as .gitignore or application.
      # js(.coffee) are not checked by this method, but instead produce warning messages
      # and allow the build to continue
      def installation_prerequisites_met?
        !(missing_node? || missing_yarn? || ReactOnRails::GitUtils.uncommitted_changes?(GeneratorMessages))
      end

      def missing_yarn?
        return false unless ReactOnRails::Utils.running_on_windows? ? `where yarn`.blank? : `which yarn`.blank?
        error = "yarn is required. Please install it before continuing. https://yarnpkg.com/en/docs/install"
        GeneratorMessages.add_error(error)
        true
      end

      def missing_node?
        return false unless ReactOnRails::Utils.running_on_windows? ? `where node`.blank? : `which node`.blank?
        error = "** nodejs is required. Please install it before continuing. https://nodejs.org/en/"
        GeneratorMessages.add_error(error)
        true
      end
    end
  end
end

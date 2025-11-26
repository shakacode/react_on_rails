# frozen_string_literal: true

require "rails/generators"
require_relative "generator_helper"

module ReactOnRails
  module Generators
    class DevTestsGenerator < Rails::Generators::Base
      include GeneratorHelper

      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("templates/dev_tests", __dir__))

      # --example-server-rendering
      class_option :example_server_rendering,
                   type: :boolean,
                   default: false,
                   desc: "Setup prerender true for server rendered examples"

      def copy_rspec_files
        %w[.eslintrc
           spec/spec_helper.rb
           spec/rails_helper.rb
           spec/simplecov_helper.rb
           .rspec].each { |file| copy_file(file) }
      end

      def copy_tests
        %w[spec/system/hello_world_spec.rb].each { |file| copy_file(file) }
      end

      def add_test_related_gems_to_gemfile
        gem("rspec-rails", group: :test)
        # NOTE: chromedriver-helper was deprecated in 2019. Modern selenium-webdriver (4.x)
        # and GitHub Actions have built-in driver management, so no driver helper is needed.
        gem("coveralls", require: false)
      end

      def replace_prerender_if_server_rendering
        return unless options.example_server_rendering

        hello_world_index = File.join(destination_root, "app", "views", "hello_world", "index.html.erb")
        hello_world_contents = File.read(hello_world_index)
        new_hello_world_contents = hello_world_contents.gsub("prerender: false",
                                                             "prerender: true")

        File.open(hello_world_index, "w+") { |f| f.puts new_hello_world_contents }
      end

      def add_yarn_relative_install_script_in_package_json
        package_json = File.join(destination_root, "package.json")
        contents = JSON.parse(File.read(package_json))
        contents["scripts"] ||= {}
        contents["scripts"]["postinstall"] = "yalc link react-on-rails"
        File.open(package_json, "w+") { |f| f.puts JSON.pretty_generate(contents) }
      end
    end
  end
end

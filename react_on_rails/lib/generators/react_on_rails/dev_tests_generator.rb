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

      # --rsc
      class_option :rsc,
                   type: :boolean,
                   default: false,
                   desc: "Include React Server Components test (hello_server_spec.rb)"

      def copy_rspec_files
        %w[.eslintrc
           spec/spec_helper.rb
           spec/rails_helper.rb
           spec/simplecov_helper.rb
           .rspec].each { |file| copy_file(file) }
      end

      def copy_tests
        files = %w[spec/system/hello_world_spec.rb]
        files << "spec/system/hello_server_spec.rb" if options.rsc
        files.each { |file| copy_file(file) }
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

      def add_react_on_rails_as_file_dependency
        # Add react-on-rails as a file dependency pointing to the local package
        # This allows testing with the local npm package without needing yalc
        package_json = File.join(destination_root, "package.json")
        contents = JSON.parse(File.read(package_json))
        contents["dependencies"] ||= {}

        # Calculate relative path from the generated example to the npm package
        # Generated examples are in gen-examples/examples/<name>/
        # The npm package is in packages/react-on-rails/
        contents["dependencies"]["react-on-rails"] = "file:../../../packages/react-on-rails"

        File.open(package_json, "w+") { |f| f.puts JSON.pretty_generate(contents) }
      end
    end
  end
end

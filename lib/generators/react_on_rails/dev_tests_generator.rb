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
        %w[spec/features/hello_world_spec.rb].each { |file| copy_file(file) }
      end

      def add_test_related_gems_to_gemfile
        gem("rspec-rails", group: :test)
        gem("chromedriver-helper", group: :test)
        gem("coveralls", require: false)
      end

      def replace_prerender_if_server_rendering
        return unless options.example_server_rendering
        hello_world_index = File.join(destination_root, "app", "views", "hello_world", "index.html.erb")
        hello_world_contents = File.read(hello_world_index)
        new_hello_world_contents = hello_world_contents.gsub(/prerender: false/,
                                                             "prerender: true")

        File.open(hello_world_index, "w+") { |f| f.puts new_hello_world_contents }
      end

      def add_yarn_relative_install_script_in_package_json
        package_json = File.join(destination_root, "package.json")
        contents = File.read(package_json)
        replacement_value = <<-STRING
  "scripts": {
    "postinstall": "yarn link react-on-rails",
STRING
        new_client_package_json_contents = contents.gsub(/ {2}"scripts": {/,
                                                         replacement_value)
        File.open(package_json, "w+") { |f| f.puts new_client_package_json_contents }
      end
    end
  end
end

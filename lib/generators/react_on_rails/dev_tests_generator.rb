# frozen_string_literal: true

require "rails/generators"
require_relative "generator_helper"

module ReactOnRails
  module Generators
    FALLBACK_OPTION_FOR_NODE_MODULES = <<-TEXT
    // This fixes an issue with resolving 'react' when using a local symlinked version
    // of the node_package folder
    modules: [
      path.join(__dirname, 'node_modules'),
      'node_modules',
    ],
  },
  plugins: [
    TEXT

    class DevTestsGenerator < Rails::Generators::Base
      include GeneratorHelper
      include OptionHelper
      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("../templates/dev_tests", __FILE__))

      define_name_option

      # --example-server-rendering
      class_option :example_server_rendering,
                   type: :boolean,
                   default: false,
                   desc: "Setup prerender true for server rendered examples"

      def copy_rspec_files
        %w[spec/spec_helper.rb
           spec/rails_helper.rb
           spec/simplecov_helper.rb
           .rspec].each { |file| copy_file(file) }
      end

      def copy_tests
        %w[spec/features/hello_world_spec.rb].each do |file|
          template("#{file}.tt", convert_filename_to_use_example_page_name(file))
        end
      end

      def add_test_related_gems_to_gemfile
        gem("rspec-rails", group: :test)
        gem("poltergeist", group: :test)
        gem("coveralls", require: false)
      end

      def replace_prerender_if_server_rendering
        return unless options.example_server_rendering

        example_page_index = File.join(destination_root, "app", "views",
                                       example_page_path, "index.html.erb")
        example_page_contents = File.read(example_page_index)
        new_example_page_contents = \
          example_page_contents.gsub(/prerender: false/, "prerender: true")

        File.open(example_page_index, "w+") do |f|
          f.puts new_example_page_contents
        end
      end

      def add_yarn_relative_install_script_in_client_package_json
        client_package_json = File.join(destination_root, "client", "package.json")
        contents = File.read(client_package_json)
        replacement_value = <<-STRING
  "scripts": {
    "postinstall": "yarn link react-on-rails",
STRING
        new_client_package_json_contents = contents.gsub(/ {2}"scripts": {/,
                                                         replacement_value)
        File.open(client_package_json, "w+") { |f| f.puts new_client_package_json_contents }
      end
    end
  end
end

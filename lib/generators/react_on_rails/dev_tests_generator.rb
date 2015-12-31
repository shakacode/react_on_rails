require "rails/generators"
require_relative "generator_helper"
include GeneratorHelper

module ReactOnRails
  module Generators
    class DevTestsGenerator < Rails::Generators::Base
      hide!
      source_root(File.expand_path("../templates/dev_tests", __FILE__))

      def copy_rspec_files
        %w(spec/spec_helper.rb
           spec/rails_helper.rb
           spec/simplecov_helper.rb
           .rspec).each { |file| copy_file(file) }
      end

      def copy_tests
        %w(spec/features/hello_world_spec.rb).each { |file| copy_file(file) }
      end

      # We want to use the node module in the local build, not the one published to NPM
      def change_package_json_to_use_local_react_on_rails_module
        package_json = File.join(destination_root, "client", "package.json")
        old_contents = File.read(package_json)
        new_contents = old_contents.gsub('"react-on-rails": "ReactOnRails::VERSION"') do |match|
          '"react-on-rails": "../../.."'
        end
        File.open(package_json, "w+") { |f| f.puts new_contents }
      end

      def add_test_related_gems_to_gemfile
        gem("rspec-rails", group: :test)
        gem("capybara", group: :test)
        gem("selenium-webdriver", group: :test)
        gem("coveralls", require: false)
      end
    end
  end
end

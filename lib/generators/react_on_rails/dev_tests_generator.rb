require "rails/generators"
require_relative "generator_helper"

module ReactOnRails
  module Generators
    class DevTestsGenerator < Rails::Generators::Base
      include GeneratorHelper
      Rails::Generators.hide_namespace(namespace)
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
        new_contents = old_contents.gsub(/"react-on-rails": ".+",/,
                                         '"react-on-rails": "../../..",')
        File.open(package_json, "w+") { |f| f.puts new_contents }
      end

      def change_webpack_client_base_config_to_include_fallback
        text = <<-TEXT
  },

  // This fixes an issue with resolving 'react' when using a local symlinked version
  // of the node_package folder
  resolveLoader: {
    fallback: [path.join(__dirname, 'node_modules')],
  },
  plugins: [
TEXT
        sentinel = /^\s\s},\n\s\splugins: \[\n/
        config = File.join(destination_root, "client", "webpack.client.base.config.js")
        old_contents = File.read(config)
        new_contents = old_contents.gsub(sentinel, text)
        File.open(config, "w+") { |f| f.puts new_contents }
      end

      def add_test_related_gems_to_gemfile
        gem("rspec-rails", group: :test)
        gem("capybara", group: :test)
        gem("selenium-webdriver", group: :test)
        gem("coveralls", require: false)
        gem("poltergeist")
      end
    end
  end
end

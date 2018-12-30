# frozen_string_literal: true

require "rails/generators"
require_relative "generator_helper"

module ReactOnRails
  module Generators
    class ReactNoReduxGenerator < Rails::Generators::Base
      include GeneratorHelper
      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("templates", __dir__))

      def copy_base_files
        base_js_path = "base/base/#{CLIENT_BASE_PATH}"
        base_files = %w[bundles/HelloWorld/components/HelloWorld.jsx]
        base_files.each { |file| copy_file("#{base_js_path}/#{file}", "#{CLIENT_BASE_PATH}/#{file}") }
      end

      def create_appropriate_templates
        base_path = "base/base"
        config = {
          component_name: "HelloWorld",
          app_relative_path: "../bundles/HelloWorld/components/HelloWorld"
        }

        template("#{base_path}/#{CLIENT_BASE_PATH}/packs/registration.js.tt",
                 "#{CLIENT_BASE_PATH}/packs/hello-world-bundle.js", config)
        template("#{base_path}/app/views/hello_world/index.html.erb.tt",
                 "app/views/hello_world/index.html.erb", config)
      end
    end
  end
end

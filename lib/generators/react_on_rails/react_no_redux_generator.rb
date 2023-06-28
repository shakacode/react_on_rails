# frozen_string_literal: true

require "rails/generators"
require_relative "generator_helper"

module ReactOnRails
  module Generators
    class ReactNoReduxGenerator < Rails::Generators::Base
      include GeneratorHelper
      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("templates", __dir__))

      BASE_PATH = "base/base"

      def copy_base_files
        base_files = %w[app/javascript/bundles/HelloWorld/components/HelloWorld.jsx]
        base_files.each { |file| copy_file("#{BASE_PATH}/#{file}", file) }
      end

      def create_appropriate_templates
        config = {
          component_name: "HelloWorld",
          app_relative_path: "../bundles/HelloWorld/components/HelloWorld"
        }

        template("#{BASE_PATH}/app/javascript/packs/registration.js.tt",
                 "app/javascript/packs/hello-world-bundle.js", config)
        template("#{BASE_PATH}/app/views/hello_world/index.html.erb.tt",
                 "app/views/hello_world/index.html.erb", config)
      end
    end
  end
end

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
        base_js_path = "base/base"
        base_files = %w[app/javascript/src/HelloWorld/ror_components/HelloWorld.client.jsx
                        app/javascript/src/HelloWorld/ror_components/HelloWorld.server.jsx
                        app/javascript/src/HelloWorld/ror_components/HelloWorld.module.css]
        base_files.each { |file| copy_file("#{base_js_path}/#{file}", file) }
      end

      def create_appropriate_templates
        base_path = "base/base"
        config = {
          component_name: "HelloWorld"
        }

        # Only create the view template - no manual bundle needed for auto registration
        template("#{base_path}/app/views/hello_world/index.html.erb.tt",
                 "app/views/hello_world/index.html.erb", config)
      end
    end
  end
end

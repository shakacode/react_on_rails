# frozen_string_literal: true

require "rails/generators"
require_relative "generator_helper"
require_relative "demo_page_config"

module ReactOnRails
  module Generators
    class ReactNoReduxGenerator < Rails::Generators::Base
      include GeneratorHelper
      include DemoPageConfig

      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("templates", __dir__))

      class_option :typescript,
                   type: :boolean,
                   default: false,
                   desc: "Generate TypeScript files"

      class_option :new_app,
                   type: :boolean,
                   default: false,
                   hide: true

      def copy_base_files
        base_js_path = "base/base"

        # Determine which component files to copy based on TypeScript option
        component_files = [
          "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.#{component_extension(options)}",
          "app/javascript/src/HelloWorld/ror_components/HelloWorld.server.#{component_extension(options)}",
          "app/javascript/src/HelloWorld/ror_components/HelloWorld.module.css"
        ]

        component_files.each do |file|
          copy_file("#{base_js_path}/#{file}", file)
        end
      end

      def create_appropriate_templates
        base_path = "base/base"

        # Only create the view template - no manual bundle needed for auto-bundling
        template("#{base_path}/app/views/hello_world/index.html.erb.tt",
                 "app/views/hello_world/index.html.erb",
                 build_hello_world_view_config(
                   component_name: "HelloWorld",
                   source_path: "app/javascript/src/HelloWorld/",
                   landing_page: new_app_landing_page_available?,
                   redux: false,
                   rsc_demo: false
                 ))
      end

      private

      def new_app_landing_page_available?
        return false unless options[:new_app]

        routes_path = File.join(destination_root, "config/routes.rb")
        return false unless File.file?(routes_path)

        File.foreach(routes_path).any? do |line|
          !line.match?(/^\s*#/) && line.match?(/^\s*root\b/)
        end
      end
    end
  end
end

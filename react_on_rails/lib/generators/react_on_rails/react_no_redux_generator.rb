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

      class_option :tailwind,
                   type: :boolean,
                   default: false,
                   desc: "Style the generated HelloWorld example with Tailwind CSS v4"

      class_option :new_app,
                   type: :boolean,
                   default: false,
                   hide: true

      def copy_base_files
        base_js_path = "base/base"
        tailwind_js_path = "base/tailwind"
        ext = component_extension(options)
        component_dir = example_component_source_directory("HelloWorld")

        # Determine which component files to copy based on TypeScript option
        client_component =
          "#{component_dir}/ror_components/HelloWorld.client.#{ext}"
        server_component =
          "#{component_dir}/ror_components/HelloWorld.server.#{ext}"

        # Source paths are relative to this generator's templates; only
        # destinations vary with the app's Shakapacker config.
        if use_tailwind?
          copy_file("#{tailwind_js_path}/app/javascript/src/HelloWorld/ror_components/HelloWorld.client.#{ext}",
                    client_component)
        else
          copy_file("#{base_js_path}/app/javascript/src/HelloWorld/ror_components/HelloWorld.client.#{ext}",
                    client_component)
          copy_file("#{base_js_path}/app/javascript/src/HelloWorld/ror_components/HelloWorld.module.css",
                    "#{component_dir}/ror_components/HelloWorld.module.css")
        end

        copy_file("#{base_js_path}/app/javascript/src/HelloWorld/ror_components/HelloWorld.server.#{ext}",
                  server_component)
      end

      def create_appropriate_templates
        base_path = "base/base"

        # Only create the view template - no manual bundle needed for auto-bundling
        template("#{base_path}/app/views/hello_world/index.html.erb.tt",
                 "app/views/hello_world/index.html.erb",
                 build_hello_world_view_config(
                   component_name: "HelloWorld",
                   source_path: example_component_source_path("HelloWorld"),
                   landing_page: new_app_landing_page_available?,
                   redux: false,
                   rsc_demo: false
                 ))
      end
    end
  end
end

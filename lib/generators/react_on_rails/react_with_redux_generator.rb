# frozen_string_literal: true

require "rails/generators"

module ReactOnRails
  module Generators
    class ReactWithReduxGenerator < Rails::Generators::Base
      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("templates", __dir__))

      class_option :typescript,
                   type: :boolean,
                   default: false,
                   desc: "Generate TypeScript files"

      def create_redux_directories
        # Create auto-registration directory structure for Redux
        empty_directory("app/javascript/src/HelloWorldApp/ror_components")

        # Create Redux support directories within the component directory
        dirs = %w[actions constants containers reducers store components]
        dirs.each { |name| empty_directory("app/javascript/src/HelloWorldApp/#{name}") }
      end

      def copy_base_files
        base_js_path = "redux/base"
        extension = options.typescript? ? "tsx" : "jsx"

        # Copy Redux-connected component to auto-registration structure
        copy_file("#{base_js_path}/app/javascript/bundles/HelloWorld/startup/HelloWorldApp.client.#{extension}",
                  "app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.client.#{extension}")
        copy_file("#{base_js_path}/app/javascript/bundles/HelloWorld/startup/HelloWorldApp.server.#{extension}",
                  "app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.server.#{extension}")
        copy_file("#{base_js_path}/app/javascript/bundles/HelloWorld/components/HelloWorld.module.css",
                  "app/javascript/src/HelloWorldApp/components/HelloWorld.module.css")

        # Update import paths in client component
        ror_client_file = "app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.client.#{extension}"
        gsub_file(ror_client_file, "../store/helloWorldStore", "../store/helloWorldStore")
        gsub_file(ror_client_file, "../containers/HelloWorldContainer",
                  "../containers/HelloWorldContainer")
      end

      def copy_base_redux_files
        base_hello_world_path = "redux/base/app/javascript/bundles/HelloWorld"
        component_extension = options.typescript? ? "tsx" : "jsx"

        # Copy non-component files (keep as .js for now)
        %w[actions/helloWorldActionCreators.js
           containers/HelloWorldContainer.js
           constants/helloWorldConstants.js
           reducers/helloWorldReducer.js
           store/helloWorldStore.js].each do |file|
             copy_file("#{base_hello_world_path}/#{file}",
                       "app/javascript/src/HelloWorldApp/#{file}")
           end

        # Copy component file with appropriate extension
        copy_file("#{base_hello_world_path}/components/HelloWorld.#{component_extension}",
                  "app/javascript/src/HelloWorldApp/components/HelloWorld.#{component_extension}")
      end

      def create_appropriate_templates
        base_path = "base/base"
        config = {
          component_name: "HelloWorldApp"
        }

        # Only create the view template - no manual bundle needed for auto registration
        template("#{base_path}/app/views/hello_world/index.html.erb.tt",
                 "app/views/hello_world/index.html.erb", config)
      end

      def add_redux_npm_dependencies
        if options.typescript?
          run "npm install redux react-redux @types/react-redux"
        else
          run "npm install redux react-redux"
        end
      end

      def add_redux_specific_messages
        # Override the generic messages with Redux-specific instructions
        require_relative "generator_messages"
        GeneratorMessages.output.clear
        GeneratorMessages.add_info(
          GeneratorMessages.helpful_message_after_installation(component_name: "HelloWorldApp")
        )
      end
    end
  end
end

# frozen_string_literal: true

require "rails/generators"

module ReactOnRails
  module Generators
    class ReactWithReduxGenerator < Rails::Generators::Base
      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("templates", __dir__))

      def create_redux_directories
        dirs = %w[actions constants containers reducers store startup]
        dirs.each { |name| empty_directory("app/javascript/bundles/HelloWorld/#{name}") }
      end

      def copy_base_files
        base_js_path = "redux/base"
        base_files = %w[app/javascript/bundles/HelloWorld/components/HelloWorld.jsx
                        app/javascript/bundles/HelloWorld/components/HelloWorld.module.css]
        base_files.each { |file| copy_file("#{base_js_path}/#{file}", file) }

        # Also copy Redux-connected component to auto-registration structure
        copy_file("#{base_js_path}/app/javascript/bundles/HelloWorld/startup/HelloWorldApp.jsx",
                  "app/javascript/src/HelloWorld/ror_components/HelloWorld.jsx")
        copy_file("#{base_js_path}/app/javascript/bundles/HelloWorld/components/HelloWorld.module.css",
                  "app/javascript/src/HelloWorld/HelloWorld.module.css")
        
        ror_component_file = "app/javascript/src/HelloWorld/ror_components/HelloWorld.jsx"
        gsub_file(ror_component_file, "../store/helloWorldStore", "../../../bundles/HelloWorld/store/helloWorldStore")
        gsub_file(ror_component_file, "../containers/HelloWorldContainer", "../../../bundles/HelloWorld/containers/HelloWorldContainer")
      end

      def copy_base_redux_files
        base_hello_world_path = "redux/base/app/javascript/bundles/HelloWorld"
        %w[actions/helloWorldActionCreators.js
           containers/HelloWorldContainer.js
           constants/helloWorldConstants.js
           reducers/helloWorldReducer.js
           store/helloWorldStore.js
           startup/HelloWorldApp.jsx].each do |file|
             copy_file("#{base_hello_world_path}/#{file}",
                       "app/javascript/bundles/HelloWorld/#{file}")
           end
      end

      def create_appropriate_templates
        base_path = "base/base"
        base_js_path = "#{base_path}/app/javascript"
        config = {
          component_name: "HelloWorld",
          app_relative_path: "../bundles/HelloWorld/startup/HelloWorldApp"
        }

        template("#{base_js_path}/packs/registration.js.tt", "app/javascript/packs/hello-world-bundle.js", config)
        template("#{base_path}/app/views/hello_world/index.html.erb.tt", "app/views/hello_world/index.html.erb", config)
      end

      def add_redux_yarn_dependencies
        run "yarn add redux react-redux"
      end
    end
  end
end

require "rails/generators"

module ReactOnRails
  module Generators
    class ReactWithReduxGenerator < Rails::Generators::Base
      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("../templates", __FILE__))

      def create_redux_directories
        dirs = %w(actions constants reducers store)
        dirs.each { |name| empty_directory("client/app/bundles/HelloWorld/#{name}") }
      end

      def copy_base_redux_files
        base_path = "redux/base/"
        %w(client/app/bundles/HelloWorld/actions/helloWorldActionCreators.jsx
           client/app/bundles/HelloWorld/containers/HelloWorldContainer.jsx
           client/app/bundles/HelloWorld/constants/helloWorldConstants.jsx
           client/app/bundles/HelloWorld/reducers/helloWorldReducer.jsx
           client/app/bundles/HelloWorld/store/helloWorldStore.jsx
           client/app/bundles/HelloWorld/startup/HelloWorldApp.jsx).each do |file|
             copy_file(base_path + file, file)
           end
      end

      def create_appropriate_templates
        base_path = "base/base/"
        destination = "client/app/bundles/HelloWorld/"
        config = {
          class_name: "HelloWorld",
          app_relative_path: "./HelloWorldApp"
        }
        %w(/startup/registration.jsx
           /components/HelloWorld.jsx).each do |file|
             template(base_path + destination + file + ".tt", destination + file, config)
           end
      end
    end
  end
end

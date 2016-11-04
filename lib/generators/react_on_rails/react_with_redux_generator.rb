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
           client/app/bundles/HelloWorld/store/helloWorldStore.jsx).each do |file|
             copy_file(base_path + file, file)
           end
      end

      def template_appropriate_version_of_hello_world_app
        filename = "HelloWorldApp.jsx"
        location = "client/app/bundles/HelloWorld/startup"
        template("redux/base/#{location}/HelloWorldApp.jsx.tt", "#{location}/#{filename}")
      end
    end
  end
end

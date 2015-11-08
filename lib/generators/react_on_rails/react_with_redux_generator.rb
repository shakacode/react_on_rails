require "rails/generators"

module ReactOnRails
  module Generators
    class ReactWithReduxGenerator < Rails::Generators::Base
      hide!
      source_root(File.expand_path("../templates", __FILE__))

      # --server-rendering
      class_option :server_rendering,
                   type: :boolean,
                   default: false,
                   desc: "Configure for server-side rendering of webpack JavaScript",
                   aliases: "-S"

      def create_redux_directories
        dirs = %w(actions constants reducers store)
        dirs.each { |name| empty_directory("client/app/bundles/HelloWorld/#{name}") }

        empty_directory("client/app/lib/middlewares")
      end

      def copy_base_redux_files
        base_path = "redux/base/"
        %w(client/app/bundles/HelloWorld/actions/helloWorldActionCreators.jsx
           client/app/bundles/HelloWorld/components/HelloWorldWidget.jsx
           client/app/bundles/HelloWorld/containers/HelloWorld.jsx
           client/app/bundles/HelloWorld/constants/helloWorldConstants.jsx
           client/app/bundles/HelloWorld/reducers/helloWorldReducer.jsx
           client/app/bundles/HelloWorld/reducers/index.jsx
           client/app/bundles/HelloWorld/store/helloWorldStore.jsx
           client/app/lib/middlewares/loggerMiddleware.js).each do |file|
             copy_file(base_path + file, file)
           end
      end

      def copy_server_rendering_redux_files
        return unless options.server_rendering?
        base_path = "redux/server_rendering/"
        %w(client/app/bundles/HelloWorld/startup/HelloWorldAppServer.jsx).each do |file|
          copy_file(base_path + file, file)
        end
      end

      def template_appropriate_version_of_hello_world_app_client
        filename = options.server_rendering? ? "HelloWorldAppClient.jsx" : "HelloWorldApp.jsx"
        location = "client/app/bundles/HelloWorld/startup"
        template("redux/base/#{location}/HelloWorldAppClient.jsx.tt", "#{location}/#{filename}")
      end
    end
  end
end

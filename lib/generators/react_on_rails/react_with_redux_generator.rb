require "rails/generators"

module ReactOnRails
  module Generators
    class ReactWithReduxGenerator < Rails::Generators::Base
      Rails::Generators.hide_namespace(namespace)
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
        file = "client/app/bundles/HelloWorld/startup/HelloWorldAppServer.jsx"
        copy_file(base_path + file, file)
      end

      def template_appropriate_version_of_hello_world_app_client
        filename = "HelloWorldAppClient.jsx"
        location = "client/app/bundles/HelloWorld/startup"
        template("redux/base/#{location}/HelloWorldAppClient.jsx.tt", "#{location}/#{filename}")
      end

      def print_helpful_message
        message = <<-MSG
  - Run the npm express-server command to load the node server with hot reloading support.

      npm run express-server

  - Visit http://localhost:4000 and see your React On Rails app running using the Webpack Dev server.
        MSG
        GeneratorMessages.add_info(message)
      end
    end
  end
end

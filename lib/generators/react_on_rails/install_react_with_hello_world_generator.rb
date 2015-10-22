# Hello World Install Generator
# This will install the the base react setup with a Hello World Example.
# The Hello World example can be viewed at localhost:3000/hello_world and
# at localhost:4000
require "rails/generators"

module ReactOnRails
  module Generators
    class InstallReactWithHelloWorldGenerator < Rails::Generators::Base
      hide!
      source_root File.expand_path("../templates", __FILE__)
      class_option :with_server_rendering,
                   type: :boolean,
                   default: false,
                   description: "Include server rendering support"

      def run_generators
        invoke "react_on_rails:react"
        invoke "react_on_rails:setup_files"
        invoke "react_on_rails:setup_tasks"
      end

      def copy_files
        copy_file "client/README.md", "client/README.md"
        copy_file "client/.eslintrc", "client/.eslintrc"
        copy_file "client/.eslintignore", "client/.eslintignore"
        copy_file "client/.jscsrc", "client/.jscsrc"
        copy_file "client/server.js", "client/server.js"
        copy_file "client/.babelrc", "client/.babelrc"
        copy_file "client/webpack.client.base.config.js",
                  "client/webpack.client.base.config.js"
        copy_file "client/webpack.client.hot.config.js",
                  "client/webpack.client.hot.config.js"
        copy_file "client/webpack.client.rails.config.js",
                  "client/webpack.client.rails.config.js"
        if options.with_server_rendering?
          copy_file "client/webpack.server.rails.config.js",
                    "client/webpack.server.rails.config.js"
          # copy hello world example files for server render
          directory "hello_world/server_render/app", "app"
          directory "hello_world/server_render/client", "client"
          copy_file "Procfile.dev.server", "Procfile.dev"
        else
          # copy hello world example files for client render
          directory "hello_world/client_render/app", "app"
          directory "hello_world/client_render/client", "client"
          copy_file "Procfile.dev.client", "Procfile.dev"
        end
        copy_file "hello_world/index.jade", "client/index.jade"

        # add the /hello_world route
        route "get 'hello_world', to: 'pages#index'"
        run "cd client && npm install"
        readme "README_HELLO_WORLD"
      end
    end
  end
end

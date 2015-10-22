# React Install Generator
# This will install the the base react setup.
require "rails/generators"

module ReactOnRails
  module Generators
    class InstallReactGenerator < Rails::Generators::Base
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
        copy_file "client/app/startup/clientGlobals.jsx",
                  "client/app/startup/clientGlobals.jsx"
        copy_file "client/index.jade", "client/index.jade"
        if options.with_server_rendering?
          copy_file "client/webpack.server.rails.config.js",
                    "client/webpack.server.rails.config.js"
          copy_file "client/app/startup/serverGlobals.jsx",
                    "client/app/startup/serverGlobals.jsx"
          copy_file "Procfile.dev.server", "Procfile.dev"
        else
          copy_file "Procfile.dev.client", "Procfile.dev"
        end
        run "cd client && npm install"
        readme "README"
      end
    end
  end
end

require "rails/generators"
require_relative "generator_helper"

module ReactOnRails
  module Generators
    class ReactNoReduxGenerator < Rails::Generators::Base
      include GeneratorHelper
      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("../templates", __FILE__))

      # --server-rendering
      class_option :server_rendering,
                   type: :boolean,
                   default: false,
                   desc: "Configure for server-side rendering of webpack JavaScript",
                   aliases: "-S"

      def copy_base_files
        base_path = "no_redux/base/"
        file = "client/app/bundles/HelloWorld/containers/HelloWorld.jsx"
        copy_file(base_path + file, file)
      end

      def copy_server_rendering_files_if_appropriate
        return unless options.server_rendering?
        base_path = "no_redux/server_rendering/"
        file = "client/app/bundles/HelloWorld/startup/HelloWorldAppServer.jsx"
        copy_file(base_path + file, file)
      end

      def template_appropriate_version_of_hello_world_app_client
        filename = "HelloWorldAppClient.jsx"
        location = "client/app/bundles/HelloWorld/startup"
        template("no_redux/base/#{location}/HelloWorldAppClient.jsx.tt", "#{location}/#{filename}")
      end
    end
  end
end

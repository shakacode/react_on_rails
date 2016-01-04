require "rails/generators"
require File.expand_path("../generator_helper", __FILE__)
include GeneratorHelper

module ReactOnRails
  module Generators
    class ReactNoReduxGenerator < Rails::Generators::Base
      Rails::Generators.hide_namespace(self.namespace)
      source_root(File.expand_path("../templates", __FILE__))

      # --server-rendering
      class_option :server_rendering,
                   type: :boolean,
                   default: false,
                   desc: "Configure for server-side rendering of webpack JavaScript",
                   aliases: "-S"

      def copy_base_files
        base_path = "no_redux/base/"
        %w(client/app/bundles/HelloWorld/components/HelloWorldWidget.jsx
           client/app/bundles/HelloWorld/containers/HelloWorld.jsx).each do |file|
             copy_file(base_path + file, file)
           end
      end

      def copy_server_rendering_files_if_appropriate
        return unless options.server_rendering?
        base_path = "no_redux/server_rendering/"
        %w(client/app/bundles/HelloWorld/startup/HelloWorldAppServer.jsx).each do |file|
          copy_file(base_path + file, file)
        end
      end

      def template_appropriate_version_of_hello_world_app_client
        filename = options.server_rendering? ? "HelloWorldAppClient.jsx" : "HelloWorldApp.jsx"
        location = "client/app/bundles/HelloWorld/startup"
        template("no_redux/base/#{location}/HelloWorldAppClient.jsx.tt", "#{location}/#{filename}")
      end
    end
  end
end

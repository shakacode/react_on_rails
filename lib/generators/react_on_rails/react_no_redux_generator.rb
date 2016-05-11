require "rails/generators"
require_relative "generator_helper"

module ReactOnRails
  module Generators
    class ReactNoReduxGenerator < Rails::Generators::Base
      include GeneratorHelper
      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("../templates", __FILE__))

      def copy_base_files
        base_path = "no_redux/base/"
        file = "client/app/bundles/HelloWorld/containers/HelloWorld.jsx"
        copy_file(base_path + file, file)
      end

      def template_appropriate_version_of_hello_world_app
        filename = "HelloWorldApp.jsx"
        location = "client/app/bundles/HelloWorld/startup"
        template("no_redux/base/#{location}/HelloWorldApp.jsx.tt", "#{location}/#{filename}")
      end
    end
  end
end

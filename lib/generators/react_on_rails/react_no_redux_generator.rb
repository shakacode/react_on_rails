require "rails/generators"
require_relative "generator_helper"

module ReactOnRails
  module Generators
    class ReactNoReduxGenerator < Rails::Generators::Base
      include GeneratorHelper
      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("../templates", __FILE__))
      
      def template_appropriate_version_of_hello_world_app
        filename = "registration.jsx"
        location = "client/app/bundles/HelloWorld/startup"
        template("no_redux/base/#{location}/registration.jsx.tt", "#{location}/#{filename}")
      end
    end
  end
end

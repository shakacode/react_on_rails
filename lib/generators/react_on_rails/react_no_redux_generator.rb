require "rails/generators"
require_relative "generator_helper"

module ReactOnRails
  module Generators
    class ReactNoReduxGenerator < Rails::Generators::Base
      include GeneratorHelper
      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("../templates", __FILE__))

      def create_appropriate_templates
        base_path = "base/base/"
        location = "client/app/bundles/HelloWorld/"
        source = base_path + location
        config = {
          class_name: "HelloWorldApp",
          app_relative_path: "../components/HelloWorldApp"
        }
        template(source + "/startup/registration.jsx" + ".tt", location + "/startup/registration.jsx", config)
        template(source + "/components/HelloWorld.jsx" + ".tt", location + "/components/HelloWorldApp.jsx", config)
      end
    end
  end
end

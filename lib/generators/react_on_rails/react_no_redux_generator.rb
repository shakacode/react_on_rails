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
          component_name: "HelloWorld",
          app_relative_path: "../components/HelloWorld"
        }
        template("#{source}/startup/registration.jsx.tt", "#{location}/startup/registration.jsx", config)
        template("#{base_path}app/views/hello_world/index.html.erb.tt", "app/views/hello_world/index.html.erb", config)
      end
    end
  end
end

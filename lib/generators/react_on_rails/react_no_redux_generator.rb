# frozen_string_literal: true

require "rails/generators"
require_relative "generator_helper"

module ReactOnRails
  module Generators
    class ReactNoReduxGenerator < Rails::Generators::Base
      include GeneratorHelper
      include OptionHelper
      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("../templates", __FILE__))
      define_name_option

      def copy_base_files
        base_path = "base/base/"
        base_files = %w[client/app/bundles/HelloWorld/components/HelloWorld.jsx]
        base_files.each do |file|
          copy_or_template(base_path + file, convert_filename_to_use_example_page_name(file))
        end
      end

      def create_appropriate_templates
        base_path = "base/base/"
        location = "client/app/bundles/HelloWorld/"
        source = base_path + location
        config = {
          component_name: example_page_name,
          app_relative_path: "../components/#{example_page_name}"
        }
        template("#{source}/startup/registration.jsx.tt",
                 convert_filename_to_use_example_page_name("#{location}/startup/registration.jsx"), config)
        template("#{base_path}app/views/hello_world/index.html.erb.tt",
                 convert_filename_to_use_example_page_name("app/views/hello_world/index.html.erb"), config)
      end
    end
  end
end

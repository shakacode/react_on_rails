# frozen_string_literal: true

require "rails/generators"
require_relative "generator_helper"

module ReactOnRails
  module Generators
    class ReactWithReduxGenerator < Rails::Generators::Base
      include GeneratorHelper
      include OptionHelper
      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("../templates", __FILE__))
      define_name_option

      def create_redux_directories
        create_client_directories "actions", "constants", "reducers", "store"
      end

      def copy_base_redux_files
        base_path = "redux/base/"
        %w[client/app/bundles/HelloWorld/components/HelloWorld.jsx
           client/app/bundles/HelloWorld/actions/helloWorldActionCreators.jsx
           client/app/bundles/HelloWorld/containers/HelloWorldContainer.jsx
           client/app/bundles/HelloWorld/constants/helloWorldConstants.jsx
           client/app/bundles/HelloWorld/reducers/helloWorldReducer.jsx
           client/app/bundles/HelloWorld/store/helloWorldStore.jsx
           client/app/bundles/HelloWorld/startup/HelloWorldApp.jsx].each do |file|
             copy_or_template(base_path + file, convert_filename_to_use_example_page_name(file))
           end
      end

      def create_appropriate_templates
        base_path = "base/base/"
        location = "client/app/bundles/HelloWorld/"
        source = base_path + location
        config = {
          component_name: "#{example_page_name}App",
          app_relative_path: "./#{example_page_name}App"
        }
        template("#{source}/startup/registration.jsx.tt",
                 convert_filename_to_use_example_page_name("#{location}/startup/registration.jsx"), config)
        template("#{base_path}app/views/hello_world/index.html.erb.tt",
                 convert_filename_to_use_example_page_name("app/views/hello_world/index.html.erb"), config)
      end
    end
  end
end

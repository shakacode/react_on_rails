require "rails/generators"
require_relative "generator_helper"

module ReactOnRails
  module Generators
    class ReactNoReduxGenerator < Rails::Generators::Base
      include GeneratorHelper
      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("../templates", __FILE__))

      def copy_react_files
        base_path = "no_redux/base/"
        %w(client/app/bundles/HelloWorld/components/HelloWorldApp.jsx
           client/app/bundles/HelloWorld/startup/registration.jsx).each do |file|
             copy_file(base_path + file, file)
           end
      end
    end
  end
end

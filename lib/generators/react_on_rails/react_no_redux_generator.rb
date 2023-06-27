# frozen_string_literal: true

require "rails/generators"
require_relative "generator_helper"

module ReactOnRails
  module Generators
    class ReactNoReduxGenerator < Rails::Generators::Base
      include GeneratorHelper
      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("templates", __dir__))

      def copy_base_files
        base_files = %w[app/javascript/bundles/HelloWorld/components/HelloWorld.jsx]
        base_files.each { |file| copy_file("#{base_path}/#{file}", file) }
      end

      def create_appropriate_templates
        config = {
          component_name: "HelloWorld",
          app_relative_path: "../bundles/HelloWorld/components/HelloWorld"
        }

        template("#{base_path}/app/javascript/packs/registration.js.tt",
                 "app/javascript/packs/hello-world-bundle.js", config)
        template("#{base_path}/app/views/hello_world/index.html.erb.tt",
                 "app/views/hello_world/index.html.erb", config)
      end

      private

      def base_path
        @base_path ||= using_shakapacker_7? ? "base/shakapacker7_base/" : "base/webpacker_base/"
      end

      def using_shakapacker_7?
        shakapacker_gem = Gem::Specification.find_by_name("shakapacker")
        shakapacker_gem.version.segments.first == 7
      rescue Gem::MissingSpecError
        # In case using Webpacker
        false
      end
    end
  end
end

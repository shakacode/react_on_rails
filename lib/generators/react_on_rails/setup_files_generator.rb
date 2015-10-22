require "rails/generators"

module ReactOnRails
  module Generators
    class SetupFilesGenerator < Rails::Generators::Base
      hide!
      source_root File.expand_path("../templates", __FILE__)

      def create_assets
        empty_directory "client/assets/stylesheets"
        create_link "client/assets/fonts", "../../app/assets/fonts" if Dir.exist?("app/assets/fonts")
        create_link "client/assets/images", "../../app/assets/images" if
        Dir.exist?("app/assets/images")
      end

      def update_git_ignore
        append_to_file ".gitignore" do
          "# React on Rails\nnpm-debug.log\nnode_modules\n\n# Generated js bundles\n/app/assets/javascripts/generated/*"
        end
      end

      def update_application_js
        data = ""
        data << "// It is important that generated/vendor-bundle must be before"
        data << " bootstrap since it is exposing jQuery and jQuery-ujs\n"
        data << "//= require generated/vendor-bundle\n"
        data << "//= require generated/app-bundle\n"
        data << "//= require react_on_rails\n\n"
        if File.exist?("app/assets/javascripts/application.js")
          prepend_to_file "app/assets/javascripts/application.js", data
        elsif File.exist?("app/assets/javascripts/application.js.coffee")
          prepend_to_file "app/assets/javascripts/application.js.coffee", data
        else
          msg = ""
          msg << "** app/assets/javascripts/application.js was not found.\n"
          msg << "Please add the following content to your main javascript "
          msg << "file:\n\n#{data}\n\n"
          puts msg
        end
      end

      def copy_config
        template "react_on_rails.rb", "config/initializers/react_on_rails.rb"
      end

      def add_gems
        gem_group :development do
          gem "rubocop"
          gem "scss_lint"
          gem "ruby-lint"
        end
      end
    end
  end
end

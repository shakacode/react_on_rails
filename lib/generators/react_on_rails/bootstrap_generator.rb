require "rails/generators"
require File.expand_path("../generator_helper", __FILE__)
require File.expand_path("../generator_errors", __FILE__)
include GeneratorHelper
include GeneratorErrors

module ReactOnRails
  module Generators
    class BootstrapGenerator < Rails::Generators::Base
      Rails::Generators.hide_namespace(namespace)
      source_root(File.expand_path("../templates", __FILE__))

      def copy_bootstrap_files
        base_path = "bootstrap/"
        %w(app/assets/stylesheets/_bootstrap-custom.scss
           client/assets/stylesheets/_post-bootstrap.scss
           client/assets/stylesheets/_pre-bootstrap.scss
           client/assets/stylesheets/_react-on-rails-sass-helper.scss
           client/bootstrap-sass.config.js).each { |file| copy_file(base_path + file, file) }
      end

      # if there still is not application.scss, just create one
      def create_application_scss_if_necessary
        path = File.join(destination_root, "app/assets/stylesheets/application.scss")
        return if File.exist?(path)
        File.open(path, "w") { |f| f.puts "// Created by React on Rails gem\n\n" }
      end

      def prepend_to_application_scss
        data = <<-DATA.strip_heredoc
          // DO NOT REQUIRE TREE! It will interfere with load order!

          // Account for differences between Rails and Webpack Sass code.
          $rails: true;

          // Included from bootstrap-sprockets gem and loaded in app/assets/javascripts/application.rb
          @import 'bootstrap-sprockets';

          // Customizations - needs to be imported after bootstrap-sprocket but before bootstrap-custom!
          // The _pre-bootstrap.scss file is located under
          // client/assets/stylesheets, which has been added to the Rails asset
          // pipeline search path. See config/application.rb.
          @import 'pre-bootstrap';

          // These scss files are located under client/assets/stylesheets
          // (which has been added to the Rails asset pipeline search path in config/application.rb).
          @import 'bootstrap-custom';

          // This must come after all the boostrap styles are loaded so that these styles can override those.
          @import 'post-bootstrap';

        DATA

        application_scss = File.join(destination_root, "app/assets/stylesheets/application.scss")

        append_to_file(application_scss, data)
      end

      def strip_application_scss_of_incompatible_sprockets_statements
        application_scss = File.join(destination_root, "app/assets/stylesheets/application.scss")
        gsub_file(application_scss, "*= require_tree .", "")
        gsub_file(application_scss, "*= require_self", "")
      end

      def add_bootstrap_sprockets_to_gemfile
        append_to_file("Gemfile", "gem 'bootstrap-sass'\n")
      end

      def add_bootstrap_sprockets_to_application_js
        data = <<-DATA.strip_heredoc

          // bootstrap-sprockets depends on generated/vendor-bundle for jQuery.
          //= require bootstrap-sprockets

        DATA

        app_js_path = "app/assets/javascripts/application.js"
        found_app_js = dest_file_exists?(app_js_path) || dest_file_exists?(app_js_path + ".coffee")
        if found_app_js
          append_to_file(found_app_js, data)
        else
          create_file(app_js_path, data)
        end
      end
    end
  end
end

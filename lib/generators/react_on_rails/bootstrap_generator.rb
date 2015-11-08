require "rails/generators"
require File.expand_path("../generator_helper", __FILE__)
include GeneratorHelper

module ReactOnRails
  module Generators
    class BootstrapGenerator < Rails::Generators::Base
      hide!
      source_root(File.expand_path("../templates", __FILE__))

      def append_to_assets_initializer
        data = <<-DATA.strip_heredoc
          # Add client/assets/ folders to asset pipeline's search path.
          # If you do not want to move existing images and fonts from your Rails app
          # you could also consider creating symlinks there that point to the original
          # rails directories. In that case, you would not add these paths here.
          Rails.application.config.assets.paths << Rails.root.join("client", "assets", "stylesheets")
          Rails.application.config.assets.paths << Rails.root.join("client", "assets", "images")
          Rails.application.config.assets.paths << Rails.root.join("client", "assets", "fonts")

          Rails.application.config.assets.precompile += %w( generated/server-bundle.js )
        DATA
        append_to_file("config/initializers/assets.rb", data)
      end

      def copy_bootstrap_files
        base_path = "bootstrap/"
        %w(app/assets/stylesheets/_bootstrap-custom.scss
           client/assets/stylesheets/_post-bootstrap.scss
           client/assets/stylesheets/_pre-bootstrap.scss
           client/assets/stylesheets/_react-on-rails-sass-helper.scss
           client/bootstrap-sass.config.js).each { |file| copy_file(base_path + file, file) }
      end

      # rename to application.scss from application.css or application.css.scss
      def force_application_scss_naming_if_necessary
        base_path = "app/assets/stylesheets/"
        application_css = "#{base_path}application.css"
        application_css_scss = "#{base_path}application.css.scss"

        bad_name = dest_file_exists?(application_css) || dest_file_exists?(application_css_scss)
        return unless bad_name

        new_name = File.join(destination_root, "#{base_path}application.scss")
        File.rename(bad_name, new_name)
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

        if File.exist?(application_scss)
          append_to_file(application_scss, data)
        else
          puts_setup_file_error(application_scss, data)
        end
      end

      def strip_application_scss_of_incompatible_sprockets_statements
        application_scss = File.join(destination_root, "app/assets/stylesheets/application.scss")
        gsub_file(application_scss, "*= require_tree .", "")
        gsub_file(application_scss, "*= require_self", "")
      end

      def add_bootstrap_sprockets_to_gemfile
        gem("bootstrap-sass")
      end

      def add_bootstrap_sprockets_to_application_js
        # see base_generator.rb this is done there
      end
    end
  end
end

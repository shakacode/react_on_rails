require "rails/generators"
require File.expand_path("../generator_helper", __FILE__)
include GeneratorHelper

module ReactOnRails
  module Generators
    class HerokuDeploymentGenerator < Rails::Generators::Base
      Rails::Generators.hide_namespace self.namespace
      source_root(File.expand_path("../templates", __FILE__))

      def copy_heroku_deployment_files
        base_path = "heroku_deployment"
        %w(.buildpacks
           Procfile
           config/puma.rb).each { |file| copy_file("#{base_path}/#{file}", file) }
      end

      def add_heroku_production_gems
        gem_text = <<-GEMS.strip_heredoc

          # For Heroku deployment
          gem 'rails_12factor', group: :production
          gem 'puma', group: :production

        GEMS
        append_to_file("Gemfile", gem_text)
      end
    end
  end
end

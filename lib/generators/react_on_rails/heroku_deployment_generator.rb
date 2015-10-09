require "rails/generators"
require File.expand_path("../generator_helper", __FILE__)
include GeneratorHelper

module ReactOnRails
  module Generators
    class HerokuDeploymentGenerator < Rails::Generators::Base
      hide!
      source_root(File.expand_path("../templates", __FILE__))

      def copy_heroku_deployment_files
        base_path = "heroku_deployment"
        %w(.buildpacks Procfile).each { |file| copy_file("#{base_path}/#{file}", file) }
      end

      def add_heroku_production_gems
        production_gems = "# For Heroku deployment\ngem 'rails_12factor', group: :production\n"
        append_to_file("Gemfile", production_gems)
      end
    end
  end
end

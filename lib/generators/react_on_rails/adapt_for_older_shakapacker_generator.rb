# frozen_string_literal: true

require "rails/generators"
require_relative "generator_helper"

module ReactOnRails
  module Generators
    class AdaptForOlderShakapackerGenerator < Rails::Generators::Base
      include GeneratorHelper

      Rails::Generators.hide_namespace(namespace)

      def change_spelling_to_webpacker
        puts "Change spelling to webpacker v7"
        files = %w[
          Procfile.dev
          Procfile.dev-static-assets
          Procfile.dev-prod-assets
          config/shakapacker.yml
          config/initializers/react_on_rails.rb
        ]
        files.each { |file| gsub_file(file, "shakapacker", "webpacker") if File.exist?(file) }
      end

      def rename_config_file
        if File.exist?("config/shakapacker.yml")
          puts "Rename to config/webpacker.yml"
          puts "Renaming shakapacker.yml into webpacker.yml"
          FileUtils.mv("config/shakapacker.yml", "config/webpacker.yml")
        end
      end

      def modify_requiring_webpack_config_in_js
        file = "config/webpack/commonWebpackConfig.js"
        if File.exist?(file)
          puts "Update commonWebpackConfig.js to follow the Shakapacker v6 interface"
          gsub_file(file, "const baseClientWebpackConfig = generateWebpackConfig();\n\n", "")
          gsub_file(
            file,
            "const { generateWebpackConfig, merge } = require('shakapacker');",
            "const { webpackConfig: baseClientWebpackConfig, merge } = require('shakapacker');"
          )
        end
      end
    end
  end
end

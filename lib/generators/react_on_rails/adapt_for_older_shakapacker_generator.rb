# frozen_string_literal: true

require "rails/generators"
require_relative "generator_helper"

module ReactOnRails
  module Generators
    class AdaptForOlderShakapackerGenerator < Rails::Generators::Base
      include GeneratorHelper
      Rails::Generators.hide_namespace(namespace)
      # source_root(File.expand_path("templates", __dir__))

      def change_spelling_to_webpacker
        files = %w[
          Procfile.dev
          Procfile.dev-static
          config/shakapacker.yml
          config/initializers/react_on_rails.rb
        ]
        files.each { |file| gsub_file(file, "shakapacker", "webpacker") }
      end

      def rename_config_file
        FileUtils.mv("config/shakapacker.yml", "config/webpacker.yml")
      end

      def modify_requiring_webpack_config_in_js
        file = "config/webpack/commonWebpackConfig.js"
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

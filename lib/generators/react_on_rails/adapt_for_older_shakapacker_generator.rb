# frozen_string_literal: true
# Copyright (c) 2015–2025 ShakaCode, LLC
# SPDX-License-Identifier: MIT


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
          Procfile.dev-static
          config/shakapacker.yml
          config/initializers/react_on_rails.rb
        ]
        files.each { |file| gsub_file(file, "shakapacker", "webpacker") }
      end

      def rename_config_file
        puts "Rename to config/webpacker.yml"
        puts "Renaming shakapacker.yml into webpacker.yml"
        FileUtils.mv("config/shakapacker.yml", "config/webpacker.yml")
      end

      def modify_requiring_webpack_config_in_js
        puts "Update commonWebpackConfig.js to follow the Shakapacker v6 interface"
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
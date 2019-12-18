# frozen_string_literal: true

require File.expand_path("boot", __dir__)

require "rails/all"

Bundler.require(*Rails.groups(assets: %w[development test]))

if File.basename(ENV["BUNDLE_GEMFILE"] || "") == "Gemfile.rails32"
  module Dummy
    class Application < Rails::Application
      config.encoding = "utf-8"
      config.filter_parameters += [:password]
      config.active_support.escape_html_entities_in_json = true
      config.active_record.whitelist_attributes = true
      config.assets.enabled = true
      config.assets.version = "1.0"
    end
  end
else
  module Dummy
    class Application < Rails::Application
      config.active_record.sqlite3.represent_boolean_as_integer = true
    end
  end
end

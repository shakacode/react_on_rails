# frozen_string_literal: true

require "react_on_rails/locales/base"
require "react_on_rails/locales/to_js"
require "react_on_rails/locales/to_json"

namespace :react_on_rails do
  desc <<~DESC
    Generate i18n javascript files
    This task generates javascript locale files: `translations.js` & `default.js` and places them in
    the "ReactOnRails.configuration.i18n_dir".

    Options:
      force=true - Force regeneration even if files are up to date
                   Example: rake react_on_rails:locale force=true
  DESC
  task locale: :environment do
    force = ENV["force"] == "true"
    ReactOnRails::Locales.compile(force: force)
  end
end

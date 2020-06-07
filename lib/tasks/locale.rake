# frozen_string_literal: true

require "react_on_rails/locales/base"
require "react_on_rails/locales/to_js"
require "react_on_rails/locales/to_json"
require "active_support"

namespace :react_on_rails do
  desc <<-DESC.strip_heredoc
    Generate i18n javascript files
    This task generates javascript locale files: `translations.js` & `default.js` and places them in
    the "ReactOnRails.configuration.i18n_dir".
  DESC
  task locale: :environment do
    if ReactOnRails.configuration.i18n_output_format.downcase == 'js'
      ReactOnRails::Locales::ToJs.new
    else
      ReactOnRails::Locales::ToJson.new
    end
  end
end

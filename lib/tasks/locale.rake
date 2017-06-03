# frozen_string_literal: true

require "react_on_rails/locales_to_js"
require "active_support"

namespace :react_on_rails do
  desc <<-DESC.strip_heredoc
    Generate i18n javascript files
    This task generates javascript locale files: `translations.js` & `default.js` and places them in
    the "ReactOnRails.configuration.i18n_dir".
  DESC
  task locale: :environment do
    ReactOnRails::LocalesToJs.new
  end
end

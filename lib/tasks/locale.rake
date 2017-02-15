require "react_on_rails/locales_to_js"

namespace :react_on_rails do
  desc <<-DESC
Generate i18n javascript files
This task generates javascript locale files: `translations.js` & `default.js` and places them in
the "ReactOnRails.configuration.i18n_dir".
  DESC
  task locale: :environment do
    if ReactOnRails.configuration.i18n_dir.present?
      ReactOnRails::LocalesToJs.new
    end
  end
end

require_relative "spec_helper"
require "tmpdir"

module ReactOnRails
  RSpec.describe LocalesToJs do
    let(:i18n_dir) { Pathname.new(Dir.mktmpdir) }
    let(:locale_dir) { File.expand_path("../../dummy/config/locales/", __FILE__) }

    it "generates translations.js & default.js" do
      ReactOnRails.configure do |config|
        config.i18n_dir = i18n_dir
        config.default_locale = "en"
        config.rails_locales_path = Dir["#{locale_dir}/*"]
      end

      ReactOnRails::LocalesToJs.new.convert

      files = Dir["#{i18n_dir.to_path}/*"].map { |p| Pathname.new(p).basename.to_s }
      expect(files).to include("translations.js", "default.js")
    end
  end
end

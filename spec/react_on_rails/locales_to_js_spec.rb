require_relative "spec_helper"
require "tmpdir"

module ReactOnRails
  RSpec.describe LocalesToJs do
    let(:i18n_dir) { Pathname.new(Dir.mktmpdir) }
    let(:locale_dir) { File.expand_path("../fixtures/i18n/locales", __FILE__) }

    before do
      ReactOnRails::LocalesToJs.any_instance.stub(:locale_files).and_return(Dir["#{locale_dir}/*"])
      ReactOnRails.configure do |config|
        config.i18n_dir = i18n_dir
      end
    end

    it "generates translations.js & default.js" do
      ReactOnRails::LocalesToJs.new

      files = Dir["#{i18n_dir.to_path}/*"].map { |p| Pathname.new(p).basename.to_s }
      expect(files).to include("translations.js", "default.js")

      result_translations = File.read("#{i18n_dir.to_path}/translations.js")
      result_default = File.read("#{i18n_dir.to_path}/default.js")
      expect(result_translations).to include("{\"hello\":\"Hello world\"")
      expect(result_translations).to include("{\"hello\":\"Hallo welt\"")
      expect(result_default).to include("const defaultLocale = 'en';")
      expect(result_default).to include("{\"hello\":{\"id\":\"hello\",\"defaultMessage\":\"Hello world\"}}")
    end
  end
end

# frozen_string_literal: true

require_relative "spec_helper"
require "tmpdir"

module ReactOnRails
  RSpec.describe Locales::ToJs do
    let(:i18n_dir) { Pathname.new(Dir.mktmpdir) }
    let(:translations_path) { "#{i18n_dir}/translations.js" }
    let(:default_path) { "#{i18n_dir}/default.js" }

    before do
      allow(ReactOnRails::WebpackerUtils).to receive(:using_webpacker?).and_return(false)
    end

    shared_examples "locale to js" do
      context "with obsolete js files" do
        before do
          FileUtils.touch(translations_path, mtime: Time.current - 1.year)
          FileUtils.touch(en_path, mtime: Time.current - 1.month)
        end

        it "updates files" do
          described_class.new

          translations = File.read(translations_path)
          default = File.read(default_path)
          expect(translations).to include('{"hello":"Hello world"')
          expect(translations).to include('{"hello":"Hallo welt"')
          expect(default).to include("const defaultLocale = 'en';")
          expect(default).to include('{"hello":{"id":"hello","defaultMessage":"Hello world"}')
          expect(default).to include('"argument":{"id":"argument","defaultMessage":"I am {age} years old."}')
          expect(default).to include('"blank":{"id":"blank","defaultMessage":null}')
          expect(default).to include("number")
          expect(default).to include("bool")
          expect(default).to include("float")
          expect(default).not_to include("day_names:")

          expect(File.mtime(translations_path)).to be >= File.mtime(en_path)
        end
      end

      context "with up-to-date js files" do
        before do
          described_class.new
        end

        it "doesn't update files" do
          ref_time = Time.current - 1.minute
          FileUtils.touch(translations_path, mtime: ref_time)

          update_time = Time.current
          described_class.new
          expect(update_time).to be > File.mtime(translations_path)
        end
      end
    end

    describe "without i18n_yml_dir" do
      let(:locale_dir) { File.expand_path("fixtures/i18n/locales", __dir__) }
      let(:en_path) { "#{locale_dir}/en.yml" }

      before do
        allow_any_instance_of(described_class).to receive(:locale_files).and_return(Dir["#{locale_dir}/*"])
        ReactOnRails.configure do |config|
          config.i18n_dir = i18n_dir
        end
      end

      after do
        ReactOnRails.configure do |config|
          config.i18n_dir = nil
        end
      end

      it_behaves_like "locale to js"
    end

    describe "with i18n_yml_dir" do
      let(:locale_dir) { File.expand_path("fixtures/i18n/locales", __dir__) }
      let(:en_path) { "#{locale_dir}/en.yml" }

      before do
        ReactOnRails.configure do |config|
          config.i18n_dir = i18n_dir
          config.i18n_yml_dir = locale_dir
        end
      end

      after do
        ReactOnRails.configure do |config|
          config.i18n_dir = nil
          config.i18n_yml_dir = nil
        end
      end

      it_behaves_like "locale to js"
    end
  end
end

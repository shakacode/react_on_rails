# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRails
  RSpec.describe Configuration do
    let(:existing_path) { Pathname.new(Dir.mktmpdir) }
    let(:not_existing_path) { "/path/to/#{SecureRandom.hex(4)}" }

    describe ".i18n_dir" do
      let(:i18n_dir) { existing_path }

      after do
        ReactOnRails.configure { |config| config.i18n_dir = nil }
      end

      it "passes if directory exists" do
        expect do
          ReactOnRails.configure do |config|
            config.i18n_dir = i18n_dir
          end
        end.not_to raise_error
      end

      it "fails with empty string value" do
        expect do
          ReactOnRails.configure do |config|
            config.i18n_dir = ""
          end
        end.to raise_error(RuntimeError, /invalid value for `config\.i18n_dir`/)
      end

      it "fails with not existing directory" do
        expect do
          ReactOnRails.configure do |config|
            config.i18n_dir = not_existing_path
          end
        end.to raise_error(RuntimeError, /invalid value for `config\.i18n_dir`/)
      end
    end

    describe ".i18n_yml_dir" do
      let(:i18n_yml_dir) { existing_path }

      after do
        ReactOnRails.configure { |config| config.i18n_yml_dir = nil }
      end

      it "passes if directory exists" do
        expect do
          ReactOnRails.configure do |config|
            config.i18n_yml_dir = i18n_yml_dir
          end
        end.not_to raise_error
      end

      it "fails with empty string value" do
        expect do
          ReactOnRails.configure do |config|
            config.i18n_yml_dir = ""
          end
        end.to raise_error(RuntimeError, /invalid value for `config\.i18n_yml_dir`/)
      end

      it "fails with not existing directory" do
        expect do
          ReactOnRails.configure do |config|
            config.i18n_yml_dir = not_existing_path
          end
        end.to raise_error(RuntimeError, /invalid value for `config\.i18n_yml_dir`/)
      end
    end

    it "be able to config default configuration of the gem" do
      ReactOnRails.configure do |config|
        config.server_bundle_js_file = "server.js"
        config.prerender = false
      end

      expect(ReactOnRails.configuration.server_bundle_js_file).to eq("server.js")
      expect(ReactOnRails.configuration.prerender).to eq(false)
    end

    it "be able to config default configuration of the gem" do
      ReactOnRails.configure do |config|
        config.server_bundle_js_file = "something.js"
        config.prerender = true
      end

      expect(ReactOnRails.configuration.server_bundle_js_file).to eq("something.js")
      expect(ReactOnRails.configuration.prerender).to eq(true)
    end
  end
end

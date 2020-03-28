# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRails
  RSpec.describe Configuration do
    let(:existing_path) { Pathname.new(Dir.mktmpdir) }
    let(:not_existing_path) { "/path/to/#{SecureRandom.hex(4)}" }
    let(:using_webpacker) { false }

    before do
      allow(ReactOnRails::WebpackerUtils).to receive(:using_webpacker?).and_return(using_webpacker)
      ReactOnRails.instance_variable_set(:@configuration, nil)
    end

    after do
      ReactOnRails.instance_variable_set(:@configuration, nil)
    end

    describe "generated_assets_dir" do
      let(:using_webpacker) { true }
      let(:webpacker_public_output_path) do
        File.expand_path(File.join(Rails.root, "public/webpack/dev"))
      end
      before do
        allow(Rails).to receive(:root).and_return(File.expand_path("."))
        allow(Webpacker).to receive_message_chain("config.public_output_path")
          .and_return(webpacker_public_output_path)
      end

      it "does not throw if the generated assets dir is blank with webpacker" do
        expect do
          ReactOnRails.configure do |config|
            config.generated_assets_dir = ""
          end
        end.not_to raise_error
      end

      it "does not throw if the webpacker_public_output_path does match the generated assets dir" do
        expect do
          ReactOnRails.configure do |config|
            config.generated_assets_dir = "public/webpack/dev"
          end
        end.not_to raise_error
      end

      it "does throw if the webpacker_public_output_path does not match the generated assets dir" do
        expect do
          ReactOnRails.configure do |config|
            config.generated_assets_dir = "public/webpack/other"
          end
        end.to raise_error(ReactOnRails::Error, /does not match the value for public_output_path/)
      end
    end

    describe ".server_render_method" do
      it "does not throw if the server render method is blank" do
        expect do
          ReactOnRails.configure do |config|
            config.server_render_method = ""
          end
        end.not_to raise_error
      end

      it "throws if the server render method is node" do
        expect do
          ReactOnRails.configure do |config|
            config.server_render_method = "node"
          end
        end.to raise_error(ReactOnRails::Error, /invalid value for `config.server_render_method`/)
      end
    end

    describe ".i18n_dir" do
      let(:i18n_dir) { existing_path }

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
        end.to raise_error(ReactOnRails::Error, /invalid value for `config\.i18n_dir`/)
      end

      it "fails with not existing directory" do
        expect do
          ReactOnRails.configure do |config|
            config.i18n_dir = not_existing_path
          end
        end.to raise_error(ReactOnRails::Error, /invalid value for `config\.i18n_dir`/)
      end
    end

    describe ".i18n_yml_dir" do
      let(:i18n_yml_dir) { existing_path }

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
        end.to raise_error(ReactOnRails::Error, /invalid value for `config\.i18n_yml_dir`/)
      end

      it "fails with not existing directory" do
        expect do
          ReactOnRails.configure do |config|
            config.i18n_yml_dir = not_existing_path
          end
        end.to raise_error(ReactOnRails::Error, /invalid value for `config\.i18n_yml_dir`/)
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
        config.random_dom_id = false
      end

      expect(ReactOnRails.configuration.server_bundle_js_file).to eq("something.js")
      expect(ReactOnRails.configuration.prerender).to eq(true)
      expect(ReactOnRails.configuration.random_dom_id).to eq(false)
    end

    it "has a default configuration of the gem" do
      ReactOnRails.configure do |_config|
      end

      expect(ReactOnRails.configuration.random_dom_id).to eq(true)
    end
  end
end

require_relative "spec_helper"

module ReactOnRails
  RSpec.describe Configuration do
    it "raises if the i18n directory does not exist" do
      junk_name = "/XXXX/junkXXXX"
      expect do
        ReactOnRails.configure do |config|
          config.i18n_dir = junk_name
        end
      end.to raise_error(/#{junk_name}/)
    end

    it "does not raises if the i18n directory does exist" do
      dir = File.expand_path(File.dirname(__FILE__))
      expect do
        ReactOnRails.configure do |config|
          config.i18n_dir = dir
        end
      end.to_not raise_error
      expect(ReactOnRails.configuration.i18n_dir).to eq(dir)
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

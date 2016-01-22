require_relative "spec_helper"

module ReactOnRails
  RSpec.describe Configuration do
    it "be able to config default configuration of the gem" do
      ReactOnRails.configure do |config|
        config.server_bundle_js_file = "client/dist/server.js"
        config.prerender = false
      end

      expect(ReactOnRails.configuration.server_bundle_js_file).to eq("client/dist/server.js")
      expect(ReactOnRails.configuration.prerender).to eq(false)
    end

    it "be able to config default configuration of the gem" do
      ReactOnRails.configure do |config|
        config.server_bundle_js_file = "client/dist/something.js"
        config.prerender = true
      end

      expect(ReactOnRails.configuration.server_bundle_js_file).to eq("client/dist/something.js")
      expect(ReactOnRails.configuration.prerender).to eq(true)
    end

    context "skip display: none" do
      it "will default false" do
        expect(ReactOnRails.configuration.skip_display_none).to eq(false)
      end

      it "will be true if set to true" do
        ReactOnRails.configure do |config|
          config.skip_display_none = true
        end
        expect(ReactOnRails.configuration.skip_display_none).to eq(true)
      end
    end
  end
end

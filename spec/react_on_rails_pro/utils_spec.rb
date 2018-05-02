# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRailsPro
  RSpec.describe Utils do
    describe "cache helpers .bundle_hash and .bundle_file_name" do
      context "and file in manifest", :webpacker do
        before do
          allow(Rails).to receive(:root).and_return(Pathname.new("."))
          allow(ReactOnRails).to receive_message_chain("configuration.generated_assets_dir")
            .and_return("public/webpack/production")
          allow(Webpacker).to receive_message_chain("config.public_output_path")
            .and_return("public/webpack/production")
          allow(ReactOnRails::WebpackerUtils).to receive(:using_webpacker?).and_return(true)
        end
        describe ".bundle_file_name" do
          before do
            allow(Webpacker).to receive_message_chain("manifest.lookup!")
              .with("client-bundle.js")
              .and_return("/webpack/production/client-bundle-0123456789abcdef.js")
          end
          subject do
            Utils.bundle_file_name("client-bundle.js")
          end
          it { expect(subject).to eq("client-bundle-0123456789abcdef.js") }
        end

        describe ".bundle_hash" do
          context "server bundle with hash in webpack output filename" do
            it "returns path for server bundle file name " do
              allow(Webpacker).to receive_message_chain("manifest.lookup!")
                .and_return("/webpack/production/webpack-bundle-0123456789abcdef.js")
              allow(ReactOnRails.configuration)
                .to receive(:server_bundle_js_file).and_return("webpack-bundle.js")

              result = Utils.bundle_hash

              expect(result).to eq("webpack-bundle-0123456789abcdef.js")
            end
          end

          context "server bundle without hash in webpack output filename" do
            it "returns MD5 for server bundle file name" do
              server_bundle_js_file = "webpack/production/webpack-bundle.js"
              allow(Webpacker).to receive_message_chain("manifest.lookup!")
                .and_return(server_bundle_js_file)
              allow(ReactOnRails.configuration)
                .to receive(:server_bundle_js_file).and_return("webpack-bundle.js")
              allow(Digest::MD5).to receive(:file)
                .with(File.expand_path("./public/#{server_bundle_js_file}"))
                .and_return("foobarfoobar")

              result = Utils.bundle_hash

              expect(result).to eq("foobarfoobar")
            end
          end
        end
      end
    end
  end
end

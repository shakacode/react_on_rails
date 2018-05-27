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
              server_bundle_js_file = "/webpack/production/webpack-bundle-0123456789abcdef.js"
              server_bundle_js_file_path = File.expand_path("./public/#{server_bundle_js_file}")
              allow(Webpacker).to receive_message_chain("manifest.lookup!")
                .and_return(server_bundle_js_file)
              allow(ReactOnRails::Utils).to receive(:server_bundle_js_file_path)
                .and_return(server_bundle_js_file_path)
              allow(ReactOnRails.configuration)
                .to receive(:server_bundle_js_file).and_return("webpack-bundle.js")
              allow(File).to receive(:mtime).with(server_bundle_js_file_path).and_return(123)

              result = Utils.bundle_hash

              expect(result).to eq("webpack-bundle-0123456789abcdef.js")
            end
          end

          context "server bundle without hash in webpack output filename" do
            it "returns MD5 for server bundle file name" do
              server_bundle_js_file = "webpack/production/webpack-bundle.js"
              server_bundle_js_file_path = File.expand_path("./public/#{server_bundle_js_file}")
              allow(Webpacker).to receive_message_chain("manifest.lookup!")
                .and_return(server_bundle_js_file)
              allow(ReactOnRails::Utils).to receive(:server_bundle_js_file_path)
                .and_return(server_bundle_js_file_path)
              allow(ReactOnRails.configuration)
                .to receive(:server_bundle_js_file).and_return("webpack-bundle.js")
              allow(Digest::MD5).to receive(:file)
                .with(server_bundle_js_file_path)
                .and_return("foobarfoobar")
              allow(File).to receive(:mtime).with(server_bundle_js_file_path).and_return(345)

              result = Utils.bundle_hash

              expect(result).to eq("foobarfoobar")
            end
          end
        end
      end
    end

    describe ".with_trace" do
      let(:logger_mock) { double("Rails.logger").as_null_object }
      context "tracing on" do
        before do
          allow(ReactOnRailsPro.configuration)
            .to receive(:tracing).and_return(true)
          Rails.stub(:logger).and_return(logger_mock)
        end

        it "logs the time for the method execution" do
          msg = "Something"
          expect(logger_mock).to receive(:info)

          result = ReactOnRailsPro::Utils.with_trace(msg) do
            1 + 2
          end

          expect(result).to eq(3)
        end
      end

      context "tracing off" do
        before do
          allow(ReactOnRailsPro.configuration)
            .to receive(:tracing).and_return(false)
          Rails.stub(:logger).and_return(logger_mock)
        end

        it "does not log the time for the method execution" do
          msg = "Something"
          expect(logger_mock).not_to receive(:info)

          result = ReactOnRailsPro::Utils.with_trace(msg) do
            1 + 2
          end

          expect(result).to eq(3)
        end
      end
    end
  end
end

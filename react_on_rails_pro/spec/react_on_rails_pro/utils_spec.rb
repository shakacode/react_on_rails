# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRailsPro
  RSpec.describe Utils do
    describe "cache helpers .bundle_hash and .bundle_file_name" do
      context "with file in manifest", :webpacker do
        before do
          allow(Rails).to receive(:root).and_return(Pathname.new("."))
          allow(ReactOnRails).to receive_message_chain("configuration.generated_assets_dir")
            .and_return("public/webpack/production")
          allow(Shakapacker).to receive_message_chain("config.public_output_path")
            .and_return("public/webpack/production")
        end

        describe ".bundle_file_name" do
          subject do
            described_class.bundle_file_name("client-bundle.js")
          end

          before do
            allow(ReactOnRails.configuration)
              .to receive_messages(server_bundle_js_file: nil, rsc_bundle_js_file: nil)
            allow(Shakapacker).to receive_message_chain("manifest.lookup!")
              .with("client-bundle.js")
              .and_return("/webpack/production/client-bundle-0123456789abcdef.js")
          end

          it { is_expected.to eq("client-bundle-0123456789abcdef.js") }
        end

        describe ".bundle_hash" do
          context "with server bundle with hash in webpack output filename" do
            it "returns path for server bundle file name" do
              server_bundle_js_file = "/webpack/production/webpack-bundle-0123456789abcdef.js"
              server_bundle_js_file_path = File.expand_path("./public/#{server_bundle_js_file}")
              allow(Shakapacker).to receive_message_chain("manifest.lookup!")
                .and_return(server_bundle_js_file)
              allow(ReactOnRails::Utils).to receive(:server_bundle_js_file_path)
                .and_return(server_bundle_js_file_path)
              allow(ReactOnRails.configuration)
                .to receive_messages(server_bundle_js_file: "webpack-bundle.js",
                                     rsc_bundle_js_file: "rsc-webpack-bundle.js")
              allow(File).to receive(:mtime).with(server_bundle_js_file_path).and_return(123)

              result = described_class.bundle_hash

              expect(result).to eq("webpack-bundle-0123456789abcdef.js")
            end
          end

          context "with server bundle without hash in webpack output filename" do
            it "returns MD5 hash plus environment string for server bundle file name" do
              server_bundle_js_file = "webpack/production/webpack-bundle.js"
              server_bundle_js_file_path = File.expand_path("./public/#{server_bundle_js_file}")
              allow(Shakapacker).to receive_message_chain("manifest.lookup!")
                .and_return(server_bundle_js_file)
              allow(ReactOnRails::Utils).to receive(:server_bundle_js_file_path)
                .and_return(server_bundle_js_file_path)
              allow(ReactOnRails.configuration)
                .to receive(:server_bundle_js_file).and_return("webpack-bundle.js")
              allow(Digest::MD5).to receive(:file)
                .with(server_bundle_js_file_path)
                .and_return("foobarfoobar")
              allow(File).to receive(:mtime).with(server_bundle_js_file_path).and_return(345)

              result = described_class.bundle_hash

              expect(result).to eq("foobarfoobar-development")
            end
          end

          context "with rsc bundle without hash in webpack output filename" do
            it "returns MD5 for rsc bundle file name" do
              rsc_bundle_js_file = "webpack/production/rsc-webpack-bundle.js"
              rsc_bundle_js_file_path = File.expand_path("./public/#{rsc_bundle_js_file}")
              allow(Shakapacker).to receive_message_chain("manifest.lookup!")
                .and_return(rsc_bundle_js_file)
              allow(ReactOnRails::Utils).to receive_messages(
                server_bundle_js_file_path: rsc_bundle_js_file_path.gsub("rsc-",
                                                                         ""), rsc_bundle_js_file_path: rsc_bundle_js_file_path
              )
              allow(ReactOnRails.configuration)
                .to receive_messages(server_bundle_js_file: "webpack-bundle.js",
                                     rsc_bundle_js_file: "rsc-webpack-bundle.js")
              allow(Digest::MD5).to receive(:file)
                .with(rsc_bundle_js_file_path)
                .and_return("barfoobarfoo")
              allow(File).to receive(:mtime).with(rsc_bundle_js_file_path).and_return(345)

              result = described_class.rsc_bundle_hash

              expect(result).to eq("barfoobarfoo-development")
            end
          end
        end
      end
    end

    describe ".digest_of_globs" do
      let(:md5_instance) { instance_double(Digest::MD5) }

      it "returns an MD5 based on the files" do
        allow(Digest::MD5).to receive(:new).and_return(md5_instance)
        allow(md5_instance).to receive(:file)
        allow(md5_instance).to receive(:hexdigest).and_return("eb3dc8ec96886ec81203c9e13f0277a7")

        expect(md5_instance).to receive(:file).exactly(3).times

        result = described_class.digest_of_globs(File.join(FixturesHelper.fixtures_dir, "app", "views", "**",
                                                           "*.jbuilder")).hexdigest

        expect(result).to eq("eb3dc8ec96886ec81203c9e13f0277a7")
      end

      it "excludes excluded_dependency_globs" do
        excluded_dependency_glob = File.join(FixturesHelper.fixtures_dir, "app", "views", "**", "index.json.jbuilder")
        allow(ReactOnRailsPro.configuration).to receive(:excluded_dependency_globs).and_return(excluded_dependency_glob)
        allow(Digest::MD5).to receive(:new).and_return(md5_instance)
        allow(md5_instance).to receive(:file)
        allow(md5_instance).to receive(:hexdigest).and_return("eb3dc8ec96886ec81203c9e13f0277a7")

        expect(md5_instance).to receive(:file).twice

        dependency_glob = File.join(FixturesHelper.fixtures_dir, "app", "views", "**", "*.jbuilder")
        result = described_class.digest_of_globs(dependency_glob).hexdigest

        expect(result).to eq("eb3dc8ec96886ec81203c9e13f0277a7")
      end
    end

    describe ".with_trace" do
      let(:logger_mock) { instance_double(ActiveSupport::Logger).as_null_object }

      context "with tracing on" do
        before do
          allow(ReactOnRailsPro.configuration).to receive(:tracing).and_return(true)
          allow(Rails).to receive(:logger).and_return(logger_mock)
        end

        it "logs the time for the method execution" do
          msg = "Something"
          expect(logger_mock).to receive(:info)

          result = described_class.with_trace(msg) do
            1 + 2
          end

          expect(result).to eq(3)
        end
      end

      context "with tracing off" do
        before do
          allow(ReactOnRailsPro.configuration)
            .to receive(:tracing).and_return(false)
          allow(Rails).to receive(:logger).and_return(logger_mock)
        end

        it "does not log the time for the method execution" do
          msg = "Something"
          expect(logger_mock).not_to receive(:info)

          result = described_class.with_trace(msg) do
            1 + 2
          end

          expect(result).to eq(3)
        end
      end
    end

    describe ".mine_type_from_file_name" do
      context "when extension is known" do
        describe "json" do
          subject do
            described_class.mine_type_from_file_name("loadable-stats.json")
          end

          it { is_expected.to eq("application/json") }
        end

        describe "JSON" do
          subject do
            described_class.mine_type_from_file_name("LOADABLE-STATS.JSON")
          end

          it { is_expected.to eq("application/json") }
        end

        describe "js" do
          subject do
            described_class.mine_type_from_file_name("loadable-stats.js")
          end

          it { is_expected.to eq("text/javascript") }
        end
      end

      context "when extension is unknown" do
        describe "foo" do
          subject do
            described_class.mine_type_from_file_name("loadable-stats.foo")
          end

          it { is_expected.to eq("application/octet-stream") }
        end
      end
    end

    describe ".printable_cache_key" do
      subject(:printable_cache_key) do
        cache_key = [1, 2, [3, 4, 5]]
        described_class.printable_cache_key(cache_key)
      end

      it { expect(printable_cache_key).to eq("1_2_3_4_5") }
    end
  end
end

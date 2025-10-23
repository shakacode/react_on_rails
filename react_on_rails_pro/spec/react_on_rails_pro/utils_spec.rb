# frozen_string_literal: true

require_relative "spec_helper"

# rubocop:disable Metrics/ModuleLength
module ReactOnRailsPro
  RSpec.describe Utils do
    before do
      allow(LicenseValidator).to receive(:validated_license_data!).and_return({})
    end

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
              allow(ReactOnRails::Utils).to receive(:server_bundle_js_file_path)
                .and_return(rsc_bundle_js_file_path.gsub("rsc-", ""))
              allow(described_class).to receive(:rsc_bundle_js_file_path)
                .and_return(rsc_bundle_js_file_path)
              allow(ReactOnRails.configuration)
                .to receive(:server_bundle_js_file)
                .and_return("webpack-bundle.js")
              allow(ReactOnRailsPro.configuration)
                .to receive(:rsc_bundle_js_file)
                .and_return("rsc-webpack-bundle.js")
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

    describe ".rsc_support_enabled?" do
      context "when RSC support is enabled" do
        before do
          allow(ReactOnRailsPro.configuration).to receive(:enable_rsc_support).and_return(true)
        end

        it "returns true" do
          expect(described_class.rsc_support_enabled?).to be(true)
        end
      end

      context "when RSC support is disabled" do
        before do
          allow(ReactOnRailsPro.configuration).to receive(:enable_rsc_support).and_return(false)
        end

        it "returns false" do
          expect(described_class.rsc_support_enabled?).to be(false)
        end
      end
    end

    describe ".rsc_bundle_js_file_path" do
      before do
        described_class.instance_variable_set(:@rsc_bundle_path, nil)
        allow(ReactOnRailsPro.configuration).to receive(:rsc_bundle_js_file).and_return("rsc-bundle.js")
      end

      after do
        described_class.instance_variable_set(:@rsc_bundle_path, nil)
      end

      it "calls bundle_js_file_path with the rsc_bundle_js_file name" do
        allow(ReactOnRails::Utils).to receive(:bundle_js_file_path).with("rsc-bundle.js")
                                                                   .and_return("/some/path/rsc-bundle.js")

        result = described_class.rsc_bundle_js_file_path

        expect(ReactOnRails::Utils).to have_received(:bundle_js_file_path).with("rsc-bundle.js")
        expect(result).to eq("/some/path/rsc-bundle.js")
      end

      it "caches the path when not in development" do
        allow(Rails.env).to receive(:development?).and_return(false)
        allow(ReactOnRails::Utils).to receive(:bundle_js_file_path).with("rsc-bundle.js")
                                                                   .and_return("/some/path/rsc-bundle.js")

        result1 = described_class.rsc_bundle_js_file_path
        result2 = described_class.rsc_bundle_js_file_path

        expect(ReactOnRails::Utils).to have_received(:bundle_js_file_path).once.with("rsc-bundle.js")
        expect(result1).to eq("/some/path/rsc-bundle.js")
        expect(result2).to eq("/some/path/rsc-bundle.js")
      end

      it "does not cache the path in development" do
        allow(Rails.env).to receive(:development?).and_return(true)
        allow(ReactOnRails::Utils).to receive(:bundle_js_file_path).with("rsc-bundle.js")
                                                                   .and_return("/some/path/rsc-bundle.js")

        result1 = described_class.rsc_bundle_js_file_path
        result2 = described_class.rsc_bundle_js_file_path

        expect(ReactOnRails::Utils).to have_received(:bundle_js_file_path).twice.with("rsc-bundle.js")
        expect(result1).to eq("/some/path/rsc-bundle.js")
        expect(result2).to eq("/some/path/rsc-bundle.js")
      end
    end

    describe ".react_client_manifest_file_path" do
      before do
        described_class.instance_variable_set(:@react_client_manifest_path, nil)
        allow(ReactOnRailsPro.configuration).to receive(:react_client_manifest_file)
          .and_return("react-client-manifest.json")
      end

      after do
        described_class.instance_variable_set(:@react_client_manifest_path, nil)
      end

      context "when using packer" do
        let(:public_output_path) { "/path/to/public/webpack/dev" }

        before do
          allow(::Shakapacker).to receive_message_chain("config.public_output_path")
            .and_return(Pathname.new(public_output_path))
          allow(::Shakapacker).to receive_message_chain("config.public_path")
            .and_return(Pathname.new("/path/to/public"))
        end

        context "when dev server is running" do
          before do
            allow(::Shakapacker).to receive(:dev_server).and_return(
              instance_double(
                ::Shakapacker::DevServer,
                running?: true,
                protocol: "http",
                host_with_port: "localhost:3035"
              )
            )
          end

          it "returns manifest URL with dev server path" do
            expected_url = "http://localhost:3035/webpack/dev/react-client-manifest.json"
            expect(described_class.react_client_manifest_file_path).to eq(expected_url)
          end
        end

        context "when dev server is not running" do
          before do
            allow(::Shakapacker).to receive_message_chain("dev_server.running?")
              .and_return(false)
          end

          it "returns file path to the manifest" do
            expected_path = File.join(public_output_path, "react-client-manifest.json")
            expect(described_class.react_client_manifest_file_path).to eq(expected_path)
          end
        end
      end

      it "caches the path when not in development" do
        allow(Rails.env).to receive(:development?).and_return(false)
        allow(ReactOnRails::PackerUtils).to receive(:asset_uri_from_packer)
          .with("react-client-manifest.json")
          .and_return("/some/path/react-client-manifest.json")

        result1 = described_class.react_client_manifest_file_path
        result2 = described_class.react_client_manifest_file_path

        expect(ReactOnRails::PackerUtils).to have_received(:asset_uri_from_packer).once
        expect(result1).to eq("/some/path/react-client-manifest.json")
        expect(result2).to eq("/some/path/react-client-manifest.json")
      end

      it "does not cache the path in development" do
        allow(Rails.env).to receive(:development?).and_return(true)
        allow(ReactOnRails::PackerUtils).to receive(:asset_uri_from_packer)
          .with("react-client-manifest.json")
          .and_return("/some/path/react-client-manifest.json")

        result1 = described_class.react_client_manifest_file_path
        result2 = described_class.react_client_manifest_file_path

        expect(ReactOnRails::PackerUtils).to have_received(:asset_uri_from_packer).twice
        expect(result1).to eq("/some/path/react-client-manifest.json")
        expect(result2).to eq("/some/path/react-client-manifest.json")
      end
    end

    describe ".react_server_client_manifest_file_path" do
      let(:asset_name) { "react-server-client-manifest.json" }

      before do
        described_class.instance_variable_set(:@react_server_manifest_path, nil)
        allow(ReactOnRailsPro.configuration).to receive(:react_server_client_manifest_file).and_return(asset_name)
        allow(Rails.env).to receive(:development?).and_return(false)
      end

      after do
        described_class.instance_variable_set(:@react_server_manifest_path, nil)
      end

      it "calls bundle_js_file_path with the correct asset name and returns its value" do
        allow(ReactOnRails::Utils).to receive(:bundle_js_file_path).with(asset_name)
                                                                   .and_return("/some/path/#{asset_name}")

        result = described_class.react_server_client_manifest_file_path

        expect(ReactOnRails::Utils).to have_received(:bundle_js_file_path).with(asset_name)
        expect(result).to eq("/some/path/#{asset_name}")
      end

      it "caches the path when not in development" do
        allow(ReactOnRails::Utils).to receive(:bundle_js_file_path).with(asset_name)
                                                                   .and_return("/some/path/#{asset_name}")

        result1 = described_class.react_server_client_manifest_file_path
        result2 = described_class.react_server_client_manifest_file_path

        expect(ReactOnRails::Utils).to have_received(:bundle_js_file_path).once.with(asset_name)
        expect(result1).to eq("/some/path/#{asset_name}")
        expect(result2).to eq("/some/path/#{asset_name}")
      end

      it "does not cache the path in development" do
        allow(Rails.env).to receive(:development?).and_return(true)
        allow(ReactOnRails::Utils).to receive(:bundle_js_file_path).with(asset_name)
                                                                   .and_return("/some/path/#{asset_name}")

        result1 = described_class.react_server_client_manifest_file_path
        result2 = described_class.react_server_client_manifest_file_path

        expect(ReactOnRails::Utils).to have_received(:bundle_js_file_path).twice.with(asset_name)
        expect(result1).to eq("/some/path/#{asset_name}")
        expect(result2).to eq("/some/path/#{asset_name}")
      end

      context "when manifest file name is nil" do
        before do
          allow(ReactOnRailsPro.configuration).to receive(:react_server_client_manifest_file).and_return(nil)
        end

        it "raises an error" do
          expect { described_class.react_server_client_manifest_file_path }
            .to raise_error(ReactOnRailsPro::Error, /react_server_client_manifest_file is nil/)
        end
      end
    end

    describe ".pro_attribution_comment" do
      context "when license is valid and not in grace period" do
        before do
          allow(ReactOnRailsPro::LicenseValidator).to receive_messages(grace_days_remaining: nil, evaluation?: false)
        end

        it "returns the standard licensed attribution comment" do
          result = described_class.pro_attribution_comment
          expect(result).to eq("<!-- Powered by React on Rails Pro (c) ShakaCode | Licensed -->")
        end
      end

      context "when license is in grace period" do
        before do
          allow(ReactOnRailsPro::LicenseValidator).to receive(:grace_days_remaining).and_return(15)
        end

        it "returns attribution comment with grace period information" do
          result = described_class.pro_attribution_comment
          expected = "<!-- Powered by React on Rails Pro (c) ShakaCode | " \
                     "Licensed (Expired - Grace Period: 15 day(s) remaining) -->"
          expect(result).to eq(expected)
        end
      end

      context "when license is in grace period with 1 day remaining" do
        before do
          allow(ReactOnRailsPro::LicenseValidator).to receive(:grace_days_remaining).and_return(1)
        end

        it "returns attribution comment with singular day" do
          result = described_class.pro_attribution_comment
          expected = "<!-- Powered by React on Rails Pro (c) ShakaCode | " \
                     "Licensed (Expired - Grace Period: 1 day(s) remaining) -->"
          expect(result).to eq(expected)
        end
      end

      context "when using evaluation license" do
        before do
          allow(ReactOnRailsPro::LicenseValidator).to receive_messages(grace_days_remaining: nil, evaluation?: true)
        end

        it "returns evaluation license attribution comment" do
          result = described_class.pro_attribution_comment
          expect(result).to eq("<!-- Powered by React on Rails Pro (c) ShakaCode | Evaluation License -->")
        end
      end

      context "when grace_days_remaining returns 0" do
        before do
          allow(ReactOnRailsPro::LicenseValidator).to receive(:grace_days_remaining).and_return(0)
        end

        it "returns attribution comment with grace period information" do
          result = described_class.pro_attribution_comment
          expected = "<!-- Powered by React on Rails Pro (c) ShakaCode | " \
                     "Licensed (Expired - Grace Period: 0 day(s) remaining) -->"
          expect(result).to eq(expected)
        end
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength

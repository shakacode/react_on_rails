# frozen_string_literal: true

require_relative "spec_helper"
require "shakapacker"

# rubocop:disable Metrics/ModuleLength, Metrics/BlockLength
module ReactOnRails
  RSpec.describe Utils do
    # Since React on Rails v15+ requires ::Shakapacker as an explicit dependency,
    # we only test with ::Shakapacker
    packers_to_test = ["shakapacker"]

    shared_context "with packer enabled" do
      let(:mock_packer) { instance_double(::Shakapacker::Instance) }
      let(:mock_config) { instance_double(::Shakapacker::Configuration) }
      let(:mock_dev_server) { instance_double(::Shakapacker::DevServer) }

      before do
        allow(ReactOnRails).to receive_message_chain(:configuration, :generated_assets_dir)
          .and_return("")
        allow(::Shakapacker).to receive_messages(dev_server: mock_dev_server, config: mock_config)
        allow(mock_dev_server).to receive(:running?).and_return(false)
        allow(mock_config).to receive(:public_output_path).and_return(packer_public_output_path)
      end
    end

    shared_context "with shakapacker enabled" do
      include_context "with packer enabled"

      # We don't need to mock anything here because the shakapacker gem is already installed and will be used by default
      it "uses shakapacker" do
        # PackerUtils now uses ::Shakapacker directly
        expect(::Shakapacker).to be_present
      end
    end

    def mock_bundle_in_manifest(bundle_name, hashed_bundle)
      mock_manifest = instance_double(::Shakapacker::Manifest)
      allow(mock_manifest).to receive(:lookup!)
        .with(bundle_name)
        .and_return(hashed_bundle)

      allow(::Shakapacker).to receive(:manifest).and_return(mock_manifest)
    end

    def mock_missing_manifest_entry(bundle_name)
      allow(::Shakapacker).to receive_message_chain("manifest.lookup!")
        .with(bundle_name)
        .and_raise(::Shakapacker::Manifest::MissingEntryError)
    end

    def random_bundle_name
      "webpack-bundle-#{SecureRandom.hex(4)}.js"
    end

    # If bundle names are not provided, random unique names will be used for each bundle.
    # This ensures that if server_bundle and rsc_bundle are accidentally swapped in the code,
    # the tests will fail since each bundle has a distinct random name that won't match if used incorrectly.
    def mock_bundle_configs(server_bundle_name: random_bundle_name, rsc_bundle_name: random_bundle_name)
      allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_js_file")
        .and_return(server_bundle_name)
      allow(ReactOnRails).to receive_message_chain("configuration.rsc_bundle_js_file")
        .and_return(rsc_bundle_name)
      allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_output_path")
        .and_return("ssr-generated")
    end

    def mock_dev_server_running
      allow(::Shakapacker).to receive_message_chain("dev_server.running?")
        .and_return(true)
      allow(::Shakapacker).to receive_message_chain("dev_server.protocol")
        .and_return("http")
      allow(::Shakapacker).to receive_message_chain("dev_server.host_with_port")
        .and_return("localhost:3035")
    end

    context "when server_bundle_path cleared" do
      before do
        allow(Rails).to receive(:root).and_return(File.expand_path("."))
        described_class.instance_variable_set(:@server_bundle_path, nil)
        described_class.instance_variable_set(:@rsc_bundle_path, nil)
        ReactOnRails::PackerUtils.instance_variables.each do |instance_variable|
          ReactOnRails::PackerUtils.remove_instance_variable(instance_variable)
        end
      end

      after do
        described_class.instance_variable_set(:@server_bundle_path, nil)
        described_class.instance_variable_set(:@rsc_bundle_path, nil)
      end

      describe ".bundle_js_file_path" do
        before do
          # Mock configuration calls to avoid server bundle detection for regular client bundles
          allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_js_file")
            .and_return("server-bundle.js")
          allow(ReactOnRails).to receive_message_chain("configuration.rsc_bundle_js_file")
            .and_return("rsc-bundle.js")
        end

        subject do
          described_class.bundle_js_file_path("webpack-bundle.js")
        end

        packers_to_test.each do |packer_type|
          context "with #{packer_type} enabled", packer_type.to_sym do
            include_context "with #{packer_type} enabled"

            let(:packer_public_output_path) do
              File.expand_path(File.join(Rails.root, "public/webpack/dev"))
            end

            context "when file in manifest", :shakapacker do
              before do
                mock_bundle_in_manifest("webpack-bundle.js", "/webpack/dev/webpack-bundle-0123456789abcdef.js")

                mock_bundle_configs(server_bundle_name: "server-bundle.js")
              end

              it { is_expected.to eq("#{packer_public_output_path}/webpack-bundle-0123456789abcdef.js") }
            end

            context "with manifest.json" do
              subject do
                described_class.bundle_js_file_path("manifest.json")
              end

              it { is_expected.to eq("#{packer_public_output_path}/manifest.json") }
            end

            context "when file not in manifest" do
              before do
                mock_missing_manifest_entry("webpack-bundle.js")
              end

              let(:env_specific_path) { File.join(packer_public_output_path, "webpack-bundle.js") }

              it "returns environment-specific path" do
                result = described_class.bundle_js_file_path("webpack-bundle.js")
                expect(result).to eq(File.expand_path(env_specific_path))
              end
            end

            context "with server bundle (SSR/RSC) file not in manifest" do
              let(:server_bundle_name) { "server-bundle.js" }
              let(:ssr_generated_path) { File.expand_path(File.join("ssr-generated", server_bundle_name)) }

              context "with server_bundle_output_path configured" do
                before do
                  mock_missing_manifest_entry(server_bundle_name)
                  allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_js_file")
                    .and_return(server_bundle_name)
                  allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_output_path")
                    .and_return("ssr-generated")
                end

                it "tries configured location first for server bundles" do
                  allow(File).to receive(:exist?).and_call_original
                  allow(File).to receive(:exist?).with(ssr_generated_path).and_return(true)

                  result = described_class.bundle_js_file_path(server_bundle_name)
                  expect(result).to eq(ssr_generated_path)
                end

                it "falls back to configured path when no bundle exists" do
                  allow(File).to receive(:exist?).and_call_original
                  allow(File).to receive(:exist?).and_return(false)

                  result = described_class.bundle_js_file_path(server_bundle_name)
                  expect(result).to eq(ssr_generated_path)
                end
              end

              context "without server_bundle_output_path configured" do
                before do
                  mock_missing_manifest_entry(server_bundle_name)
                  allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_js_file")
                    .and_return(server_bundle_name)
                  allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_output_path")
                    .and_return(nil)
                end

                it "uses packer public output path" do
                  result = described_class.bundle_js_file_path(server_bundle_name)
                  expect(result).to eq(File.expand_path(File.join(packer_public_output_path, server_bundle_name)))
                end
              end
            end

            context "with RSC bundle file not in manifest" do
              let(:rsc_bundle_name) { "rsc-bundle.js" }
              let(:ssr_generated_path) { File.expand_path(File.join("ssr-generated", rsc_bundle_name)) }

              before do
                mock_missing_manifest_entry(rsc_bundle_name)
                allow(ReactOnRails).to receive_message_chain("configuration.rsc_bundle_js_file")
                  .and_return(rsc_bundle_name)
                allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_output_path")
                  .and_return("ssr-generated")
              end

              it "treats RSC bundles as server bundles and tries configured location first" do
                allow(File).to receive(:exist?).and_call_original
                allow(File).to receive(:exist?).with(ssr_generated_path).and_return(true)

                result = described_class.bundle_js_file_path(rsc_bundle_name)
                expect(result).to eq(ssr_generated_path)
              end
            end
          end
        end
      end

      describe ".source_path_is_not_defined_and_custom_node_modules?" do
        it "returns false if node_modules is blank" do
          allow(ReactOnRails).to receive_message_chain("configuration.node_modules_location")
            .and_return("")
          allow(::Shakapacker).to receive_message_chain("config.send").with(:data)
                                                                      .and_return({})

          expect(described_class.using_packer_source_path_is_not_defined_and_custom_node_modules?).to be(false)
        end

        it "returns false if source_path is defined in the config/webpacker.yml and node_modules defined" do
          allow(ReactOnRails).to receive_message_chain("configuration.node_modules_location")
            .and_return("client")
          allow(::Shakapacker).to receive_message_chain("config.send")
            .with(:data).and_return(source_path: "client/app")

          expect(described_class.using_packer_source_path_is_not_defined_and_custom_node_modules?).to be(false)
        end

        it "returns true if node_modules is not blank and the source_path is not defined in config/webpacker.yml" do
          allow(ReactOnRails).to receive_message_chain("configuration.node_modules_location")
            .and_return("node_modules")
          allow(::Shakapacker).to receive_message_chain("config.send").with(:data)
                                                                      .and_return({})

          expect(described_class.using_packer_source_path_is_not_defined_and_custom_node_modules?).to be(true)
        end
      end

      packers_to_test.each do |packer_type|
        describe ".server_bundle_js_file_path with #{packer_type} enabled" do
          let(:packer_public_output_path) { Pathname.new("public/webpack/development") }

          include_context "with #{packer_type} enabled"

          context "with server file not in manifest", packer_type.to_sym do
            it "returns the secure ssr-generated path for server bundles" do
              server_bundle_name = "server-bundle.js"
              mock_bundle_configs(server_bundle_name: server_bundle_name)
              mock_missing_manifest_entry(server_bundle_name)

              path = described_class.server_bundle_js_file_path

              expect(path).to end_with("ssr-generated/#{server_bundle_name}")
            end

            context "with bundle file existing in ssr-generated location" do
              it "returns the ssr-generated location path" do
                server_bundle_name = "server-bundle.js"
                mock_bundle_configs(server_bundle_name: server_bundle_name)
                mock_missing_manifest_entry(server_bundle_name)

                # Mock File.exist? to return true for ssr-generated path
                ssr_generated_path = File.expand_path(File.join("ssr-generated", server_bundle_name))

                allow(File).to receive(:exist?).and_call_original
                allow(File).to receive(:exist?).with(ssr_generated_path).and_return(true)

                path = described_class.server_bundle_js_file_path

                expect(path).to eq(ssr_generated_path)
              end
            end

            context "with bundle file not existing in any fallback location" do
              it "returns the secure ssr-generated path as final fallback for server bundles" do
                server_bundle_name = "server-bundle.js"
                mock_bundle_configs(server_bundle_name: server_bundle_name)
                mock_missing_manifest_entry(server_bundle_name)

                # Mock File.exist? to return false for all paths
                allow(File).to receive(:exist?).and_call_original
                allow(File).to receive(:exist?).and_return(false)

                path = described_class.server_bundle_js_file_path

                expect(path).to end_with("ssr-generated/#{server_bundle_name}")
              end
            end
          end

          context "with server file in the manifest, used for client", packer_type.to_sym do
            it "returns the correct path hashed server path" do
              packer = ::Shakapacker
              mock_bundle_configs(server_bundle_name: "webpack-bundle.js")
              allow(ReactOnRails).to receive_message_chain("configuration.same_bundle_for_client_and_server")
                .and_return(true)
              mock_bundle_in_manifest("webpack-bundle.js", "webpack/development/webpack-bundle-123456.js")
              allow(packer).to receive_message_chain("dev_server.running?")
                .and_return(false)

              path = described_class.server_bundle_js_file_path
              expect(path).to end_with("public/webpack/development/webpack-bundle-123456.js")
              expect(path).to start_with("/")
            end

            context "with webpack-dev-server running, and same file used for server and client" do
              it "returns the correct path hashed server path" do
                mock_bundle_configs(server_bundle_name: "webpack-bundle.js")
                allow(ReactOnRails).to receive_message_chain("configuration.same_bundle_for_client_and_server")
                  .and_return(true)
                mock_dev_server_running
                mock_bundle_in_manifest("webpack-bundle.js", "/webpack/development/webpack-bundle-123456.js")

                path = described_class.server_bundle_js_file_path

                expect(path).to eq("http://localhost:3035/webpack/development/webpack-bundle-123456.js")
              end
            end
          end

          context "with dev-server running, and server file in the manifest, and separate client/server files",
                  packer_type.to_sym do
            it "returns the correct path hashed server path" do
              mock_bundle_configs(server_bundle_name: "server-bundle.js")
              allow(ReactOnRails).to receive_message_chain("configuration.same_bundle_for_client_and_server")
                .and_return(false)
              mock_bundle_in_manifest("server-bundle.js", "webpack/development/server-bundle-123456.js")
              mock_dev_server_running

              path = described_class.server_bundle_js_file_path

              expect(path).to end_with("/public/webpack/development/server-bundle-123456.js")
            end
          end
        end

        describe ".rsc_bundle_js_file_path with #{packer_type} enabled" do
          let(:packer_public_output_path) { Pathname.new("public/webpack/development") }

          include_context "with #{packer_type} enabled"

          context "with server file not in manifest", packer_type.to_sym do
            it "returns the secure ssr-generated path for RSC bundles" do
              server_bundle_name = "rsc-bundle.js"
              mock_bundle_configs(rsc_bundle_name: server_bundle_name)
              mock_missing_manifest_entry(server_bundle_name)

              path = described_class.rsc_bundle_js_file_path

              expect(path).to end_with("ssr-generated/#{server_bundle_name}")
            end
          end

          context "with server file in the manifest, used for client", packer_type.to_sym do
            it "returns the correct path hashed server path" do
              packer = ::Shakapacker
              mock_bundle_configs(rsc_bundle_name: "webpack-bundle.js")
              allow(ReactOnRails).to receive_message_chain("configuration.same_bundle_for_client_and_server")
                .and_return(true)
              mock_bundle_in_manifest("webpack-bundle.js", "webpack/development/webpack-bundle-123456.js")
              allow(packer).to receive_message_chain("dev_server.running?")
                .and_return(false)

              path = described_class.rsc_bundle_js_file_path
              expect(path).to end_with("public/webpack/development/webpack-bundle-123456.js")
              expect(path).to start_with("/")
            end

            context "with webpack-dev-server running, and same file used for server and client" do
              it "returns the correct path hashed server path" do
                mock_bundle_configs(rsc_bundle_name: "webpack-bundle.js")
                allow(ReactOnRails).to receive_message_chain("configuration.same_bundle_for_client_and_server")
                  .and_return(true)
                mock_dev_server_running
                mock_bundle_in_manifest("webpack-bundle.js", "/webpack/development/webpack-bundle-123456.js")

                path = described_class.rsc_bundle_js_file_path

                expect(path).to eq("http://localhost:3035/webpack/development/webpack-bundle-123456.js")
              end
            end
          end

          context "with dev-server running, and server file in the manifest, and separate client/server files",
                  packer_type.to_sym do
            it "returns the correct path hashed server path" do
              mock_bundle_configs(rsc_bundle_name: "rsc-bundle.js")
              allow(ReactOnRails).to receive_message_chain("configuration.same_bundle_for_client_and_server")
                .and_return(false)
              mock_bundle_in_manifest("rsc-bundle.js", "webpack/development/server-bundle-123456.js")
              mock_dev_server_running

              path = described_class.rsc_bundle_js_file_path

              expect(path).to end_with("/public/webpack/development/server-bundle-123456.js")
            end
          end
        end
      end

      describe ".wrap_message" do
        subject(:stripped_heredoc) do
          <<-MSG.strip_heredoc
          Something to wrap
          with 2 lines
          MSG
        end

        let(:expected) do
          msg = <<-MSG.strip_heredoc
          ================================================================================
          Something to wrap
          with 2 lines
          ================================================================================
          MSG
          Rainbow(msg).red
        end

        it "outputs the correct text" do
          expect(described_class.wrap_message(stripped_heredoc)).to eq(expected)
        end
      end

      describe ".truthy_presence" do
        context "with non-empty string" do
          subject(:simple_string) { "foobar" }

          it "returns subject (same value as presence) for a non-empty string" do
            expect(described_class.truthy_presence(simple_string)).to eq(simple_string.presence)

            # Blank strings are nil for presence
            expect(described_class.truthy_presence(simple_string)).to eq(simple_string)
          end
        end

        context "with empty string" do
          it "returns \"\" for an empty string" do
            expect(described_class.truthy_presence("")).to eq("")
          end
        end

        context "with nil object" do
          it "returns nil (same value as presence)" do
            expect(described_class.truthy_presence(nil)).to eq(nil.presence)

            # Blank strings are nil for presence
            expect(described_class.truthy_presence(nil)).to be_nil
          end
        end

        context "with pathname pointing to empty dir (obj.empty? is true)" do
          subject(:empty_dir) { Pathname.new(Dir.mktmpdir) }

          it "returns Pathname object" do
            # Blank strings are nil for presence
            expect(described_class.truthy_presence(empty_dir)).to eq(empty_dir)
          end
        end

        context "with pathname pointing to empty file" do
          subject(:empty_file) do
            File.basename(Tempfile.new("tempfile",
                                       empty_dir))
          end

          let(:empty_dir) { Pathname.new(Dir.mktmpdir) }

          it "returns Pathname object" do
            expect(described_class.truthy_presence(empty_file)).to eq(empty_file)
          end
        end
      end

      describe ".rails_version_less_than" do
        subject { described_class.rails_version_less_than("4") }

        describe ".rails_version_less_than" do
          before { described_class.instance_variable_set :@rails_version_less_than, nil }

          context "with Rails 3" do
            before { allow(Rails).to receive(:version).and_return("3") }

            it { is_expected.to be(true) }
          end

          context "with Rails 3.2" do
            before { allow(Rails).to receive(:version).and_return("3.2") }

            it { is_expected.to be(true) }
          end

          context "with Rails 4" do
            before { allow(Rails).to receive(:version).and_return("4") }

            it { is_expected.to be(false) }
          end

          context "with Rails 4.2" do
            before { allow(Rails).to receive(:version).and_return("4.2") }

            it { is_expected.to be(false) }
          end

          context "with Rails 10.0" do
            before { allow(Rails).to receive(:version).and_return("10.0") }

            it { is_expected.to be(false) }
          end

          context "when called twice" do
            before do
              allow(Rails).to receive(:version).and_return("4.2")
            end

            it "memoizes the result" do
              2.times { described_class.rails_version_less_than("4") }

              expect(Rails).to have_received(:version).once
            end
          end
        end
      end

      describe ".smart_trim" do
        let(:long_string) { "1234567890" }

        context "when FULL_TEXT_ERRORS is true" do
          before { ENV["FULL_TEXT_ERRORS"] = "true" }
          after { ENV["FULL_TEXT_ERRORS"] = nil }

          it "returns the full string regardless of length" do
            expect(described_class.smart_trim(long_string, 5)).to eq(long_string)
          end

          it "handles a hash without trimming" do
            hash = { a: long_string }
            expect(described_class.smart_trim(hash, 5)).to eq(hash.to_s)
          end
        end

        context "when FULL_TEXT_ERRORS is not set" do
          before { ENV["FULL_TEXT_ERRORS"] = nil }

          it "trims smartly" do
            expect(described_class.smart_trim(long_string, -1)).to eq("1234567890")
            expect(described_class.smart_trim(long_string, 0)).to eq("1234567890")
            expect(described_class.smart_trim(long_string, 1)).to eq("1#{Utils::TRUNCATION_FILLER}")
            expect(described_class.smart_trim(long_string, 2)).to eq("1#{Utils::TRUNCATION_FILLER}0")
            expect(described_class.smart_trim(long_string, 3)).to eq("1#{Utils::TRUNCATION_FILLER}90")
            expect(described_class.smart_trim(long_string, 4)).to eq("12#{Utils::TRUNCATION_FILLER}90")
            expect(described_class.smart_trim(long_string, 5)).to eq("12#{Utils::TRUNCATION_FILLER}890")
            expect(described_class.smart_trim(long_string, 6)).to eq("123#{Utils::TRUNCATION_FILLER}890")
            expect(described_class.smart_trim(long_string, 7)).to eq("123#{Utils::TRUNCATION_FILLER}7890")
            expect(described_class.smart_trim(long_string, 8)).to eq("1234#{Utils::TRUNCATION_FILLER}7890")
            expect(described_class.smart_trim(long_string, 9)).to eq("1234#{Utils::TRUNCATION_FILLER}67890")
            expect(described_class.smart_trim(long_string, 10)).to eq("1234567890")
            expect(described_class.smart_trim(long_string, 11)).to eq("1234567890")
          end

          it "trims handles a hash" do
            s = { a: "1234567890" }
            result = described_class.smart_trim(s, 9)
            # Ruby version compatibility: handle different hash syntax and trimming results
            expect(result).to match(/\{(:a=|a: ")#{Regexp.escape(Utils::TRUNCATION_FILLER)}\d+"\}/o)
          end
        end
      end

      describe ".react_on_rails_pro?" do
        subject { described_class.react_on_rails_pro? }

        it { is_expected.to(be(false)) }
      end

      describe ".react_on_rails_pro_version?" do
        subject { described_class.react_on_rails_pro_version }

        it { is_expected.to eq("") }
      end

      describe ".gem_available?" do
        it "calls Gem.loaded_specs" do
          expect(Gem).to receive(:loaded_specs)
          described_class.gem_available?("nonexistent_gem")
        end
      end
    end

    describe ".react_client_manifest_file_path" do
      before do
        described_class.instance_variable_set(:@react_client_manifest_path, nil)
        allow(ReactOnRails.configuration).to receive(:react_client_manifest_file)
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
    end

    describe ".react_server_client_manifest_file_path" do
      before do
        described_class.instance_variable_set(:@react_server_manifest_path, nil)
        allow(ReactOnRails.configuration).to receive(:react_server_client_manifest_file)
          .and_return("react-server-client-manifest.json")
        allow(Rails.env).to receive(:development?).and_return(false)
      end

      after do
        described_class.instance_variable_set(:@react_server_manifest_path, nil)
      end

      context "when in development environment" do
        before do
          allow(Rails.env).to receive(:development?).and_return(true)
          allow(described_class).to receive(:generated_assets_full_path)
            .and_return("/path/to/generated/assets")
        end

        it "does not use cached path" do
          # Call once to potentially set the cached path
          described_class.react_server_client_manifest_file_path

          # Change the configuration value
          allow(ReactOnRails.configuration).to receive(:react_server_client_manifest_file)
            .and_return("changed-manifest.json")

          # Should use the new value
          expect(described_class.react_server_client_manifest_file_path)
            .to eq("/path/to/generated/assets/changed-manifest.json")
        end
      end

      context "when not in development environment" do
        before do
          allow(described_class).to receive(:generated_assets_full_path)
            .and_return("/path/to/generated/assets")
        end

        it "caches the path" do
          # Call once to set the cached path
          expected_path = "/path/to/generated/assets/react-server-client-manifest.json"
          expect(described_class.react_server_client_manifest_file_path).to eq(expected_path)

          # Change the configuration value
          allow(ReactOnRails.configuration).to receive(:react_server_client_manifest_file)
            .and_return("changed-manifest.json")

          # Should still use the cached path
          expect(described_class.react_server_client_manifest_file_path).to eq(expected_path)
        end
      end

      context "with different manifest file names" do
        before do
          allow(described_class).to receive(:generated_assets_full_path)
            .and_return("/path/to/generated/assets")
        end

        it "returns the correct path for default manifest name" do
          allow(ReactOnRails.configuration).to receive(:react_server_client_manifest_file)
            .and_return("react-server-client-manifest.json")

          expect(described_class.react_server_client_manifest_file_path)
            .to eq("/path/to/generated/assets/react-server-client-manifest.json")
        end

        it "returns the correct path for custom manifest name" do
          allow(ReactOnRails.configuration).to receive(:react_server_client_manifest_file)
            .and_return("custom-server-client-manifest.json")

          expect(described_class.react_server_client_manifest_file_path)
            .to eq("/path/to/generated/assets/custom-server-client-manifest.json")
        end
      end

      context "with nil manifest file name" do
        before do
          allow(ReactOnRails.configuration).to receive(:react_server_client_manifest_file)
            .and_return(nil)
          allow(described_class).to receive(:generated_assets_full_path)
            .and_return("/path/to/generated/assets")
        end

        it "raises an error when the manifest file name is nil" do
          expect { described_class.react_server_client_manifest_file_path }
            .to raise_error(ReactOnRails::Error, /react_server_client_manifest_file is nil/)
        end
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength, Metrics/BlockLength

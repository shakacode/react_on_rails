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
      allow(ReactOnRails).to receive_message_chain("configuration.enforce_private_server_bundles")
        .and_return(false)
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
          allow(ReactOnRails).to receive_message_chain("configuration.react_server_client_manifest_file")
            .and_return("react-server-client-manifest.json")
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
              let(:public_path) { File.expand_path(File.join(packer_public_output_path, server_bundle_name)) }

              context "with server_bundle_output_path configured and enforce_private_server_bundles=false" do
                before do
                  mock_missing_manifest_entry(server_bundle_name)
                  allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_js_file")
                    .and_return(server_bundle_name)
                  allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_output_path")
                    .and_return("ssr-generated")
                  allow(ReactOnRails).to receive_message_chain("configuration.enforce_private_server_bundles")
                    .and_return(false)
                end

                it "returns private path when it exists even if public path also exists" do
                  allow(File).to receive(:exist?).with(ssr_generated_path).and_return(true)
                  allow(File).to receive(:exist?).with(public_path).and_return(true)

                  result = described_class.bundle_js_file_path(server_bundle_name)
                  expect(result).to eq(ssr_generated_path)
                end

                it "returns public path when private path does not exist and public path exists" do
                  allow(File).to receive(:exist?).with(ssr_generated_path).and_return(false)
                  allow(File).to receive(:exist?).with(public_path).and_return(true)

                  result = described_class.bundle_js_file_path(server_bundle_name)
                  expect(result).to eq(public_path)
                end

                it "returns configured path if both private and public paths do not exist" do
                  allow(File).to receive(:exist?).with(ssr_generated_path).and_return(false)
                  allow(File).to receive(:exist?).with(public_path).and_return(false)

                  result = described_class.bundle_js_file_path(server_bundle_name)
                  expect(result).to eq(ssr_generated_path)
                end
              end

              context "with server_bundle_output_path configured and enforce_private_server_bundles=true" do
                before do
                  mock_missing_manifest_entry(server_bundle_name)
                  allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_js_file")
                    .and_return(server_bundle_name)
                  allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_output_path")
                    .and_return("ssr-generated")
                  allow(ReactOnRails).to receive_message_chain("configuration.enforce_private_server_bundles")
                    .and_return(true)
                end

                # It should always return the ssr_generated_path, regardless of which files exist
                file_states_combinations = [
                  { ssr_exists: true, public_exists: true },
                  { ssr_exists: true, public_exists: false },
                  { ssr_exists: false, public_exists: true },
                  { ssr_exists: false, public_exists: false }
                ]
                file_states_combinations.each do |file_states|
                  it "returns private path when enforce_private_server_bundles=true " \
                     "(ssr_exists=#{file_states[:ssr_exists]}, " \
                     "public_exists=#{file_states[:public_exists]})" do
                    allow(File).to receive(:exist?)
                      .with(ssr_generated_path)
                      .and_return(file_states[:ssr_exists])
                    allow(File).to receive(:exist?)
                      .with(public_path)
                      .and_return(file_states[:public_exists])

                    result = described_class.bundle_js_file_path(server_bundle_name)
                    expect(result).to eq(ssr_generated_path)
                  end
                end
              end

              context "without server_bundle_output_path configured" do
                before do
                  mock_missing_manifest_entry(server_bundle_name)
                  allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_js_file")
                    .and_return(server_bundle_name)
                  allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_output_path")
                    .and_return(nil)
                  allow(ReactOnRails).to receive_message_chain("configuration.enforce_private_server_bundles")
                    .and_return(false)
                end

                it "uses packer public output path" do
                  result = described_class.bundle_js_file_path(server_bundle_name)
                  expect(result).to eq(File.expand_path(File.join(packer_public_output_path, server_bundle_name)))
                end
              end
            end

            context "with RSC bundle file not in manifest" do
              let(:rsc_bundle_name) { "rsc-bundle.js" }
              let(:public_path) { File.expand_path(File.join(packer_public_output_path, rsc_bundle_name)) }
              let(:ssr_generated_path) { File.expand_path(File.join("ssr-generated", rsc_bundle_name)) }

              before do
                # Mock Pro gem being available
                allow(described_class).to receive(:react_on_rails_pro?).and_return(true)

                # Create a mock Pro module with configuration method
                pro_module = Module.new do
                  def self.configuration
                    @configuration
                  end

                  def self.configuration=(config)
                    @configuration = config
                  end
                end
                stub_const("ReactOnRailsPro", pro_module)

                pro_config = double("ProConfiguration") # rubocop:disable RSpec/VerifiedDoubles
                allow(pro_config).to receive_messages(rsc_bundle_js_file: rsc_bundle_name,
                                                      react_server_client_manifest_file: nil)
                ReactOnRailsPro.configuration = pro_config
              end

              context "with enforce_private_server_bundles=false" do
                before do
                  mock_missing_manifest_entry(rsc_bundle_name)
                  allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_output_path")
                    .and_return("ssr-generated")
                  allow(ReactOnRails).to receive_message_chain("configuration.enforce_private_server_bundles")
                    .and_return(false)
                end

                it "returns private path when it exists even if public path also exists" do
                  allow(File).to receive(:exist?).with(ssr_generated_path).and_return(true)
                  expect(File).not_to receive(:exist?).with(public_path)

                  result = described_class.bundle_js_file_path(rsc_bundle_name)
                  expect(result).to eq(ssr_generated_path)
                end

                it "fallbacks to public path when private path does not exist and public path exists" do
                  allow(File).to receive(:exist?).with(ssr_generated_path).and_return(false)
                  allow(File).to receive(:exist?).with(public_path).and_return(true)

                  result = described_class.bundle_js_file_path(rsc_bundle_name)
                  expect(result).to eq(public_path)
                end

                it "returns configured path if both private and public paths do not exist" do
                  allow(File).to receive(:exist?).with(ssr_generated_path).and_return(false)
                  allow(File).to receive(:exist?).with(public_path).and_return(false)

                  result = described_class.bundle_js_file_path(rsc_bundle_name)
                  expect(result).to eq(ssr_generated_path)
                end
              end

              context "with enforce_private_server_bundles=true" do
                before do
                  mock_missing_manifest_entry(rsc_bundle_name)
                  allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_output_path")
                    .and_return("ssr-generated")
                  allow(ReactOnRails).to receive_message_chain("configuration.enforce_private_server_bundles")
                    .and_return(true)
                end

                it "enforces private RSC bundles and never checks public directory" do
                  public_path = File.expand_path(File.join(packer_public_output_path, rsc_bundle_name))

                  # Should not check public path when enforcement is enabled
                  expect(File).not_to receive(:exist?).with(public_path)

                  result = described_class.bundle_js_file_path(rsc_bundle_name)
                  expect(result).to eq(ssr_generated_path)
                end
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
            it "returns the private ssr-generated path for server bundles" do
              server_bundle_name = "server-bundle.js"
              mock_bundle_configs(server_bundle_name: server_bundle_name)
              mock_missing_manifest_entry(server_bundle_name)

              path = described_class.server_bundle_js_file_path

              expect(path).to end_with("ssr-generated/#{server_bundle_name}")
            end

            context "with server_bundle_output_path configured and enforce_private_server_bundles=false" do
              it "returns the configured path directly without checking file existence" do
                server_bundle_name = "server-bundle.js"
                mock_bundle_configs(server_bundle_name: server_bundle_name)
                mock_missing_manifest_entry(server_bundle_name)
                # NOTE: mock_bundle_configs sets enforce_private_server_bundles to false

                # Since server_bundle_output_path is configured, it will try manifest lookup first,
                # then fall back to candidate paths. With enforce_private_server_bundles=false,
                # it will check File.exist? for both private and public paths
                ssr_generated_path = File.expand_path(File.join("ssr-generated", server_bundle_name))
                public_path = File.expand_path(File.join(packer_public_output_path, server_bundle_name))
                allow(File).to receive(:exist?).with(ssr_generated_path).and_return(false)
                allow(File).to receive(:exist?).with(public_path).and_return(false)

                path = described_class.server_bundle_js_file_path

                expect(path).to end_with("ssr-generated/#{server_bundle_name}")
              end
            end

            context "with server_bundle_output_path configured and enforce_private_server_bundles=true" do
              it "returns the private path without checking public directories" do
                server_bundle_name = "server-bundle.js"
                mock_missing_manifest_entry(server_bundle_name)
                allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_js_file")
                  .and_return(server_bundle_name)
                allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_output_path")
                  .and_return("ssr-generated")
                allow(ReactOnRails).to receive_message_chain("configuration.enforce_private_server_bundles")
                  .and_return(true)

                # Should not check public paths when enforcement is enabled
                public_path = File.expand_path(File.join(packer_public_output_path, server_bundle_name))
                expect(File).not_to receive(:exist?).with(public_path)

                path = described_class.server_bundle_js_file_path
                expect(path).to end_with("ssr-generated/#{server_bundle_name}")
              end
            end
          end

          context "with server file in the manifest, used for client", packer_type.to_sym do
            it "returns the correct path hashed server path" do
              # Use Shakapacker directly instead of packer method
              mock_bundle_configs(server_bundle_name: "webpack-bundle.js")
              # Clear server_bundle_output_path to test manifest behavior
              allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_output_path")
                .and_return(nil)
              allow(ReactOnRails).to receive_message_chain("configuration.same_bundle_for_client_and_server")
                .and_return(true)
              mock_bundle_in_manifest("webpack-bundle.js", "webpack/development/webpack-bundle-123456.js")
              allow(Shakapacker).to receive_message_chain("dev_server.running?")
                .and_return(false)

              path = described_class.server_bundle_js_file_path
              expect(path).to end_with("public/webpack/development/webpack-bundle-123456.js")
              expect(path).to start_with("/")
            end

            context "with webpack-dev-server running, and same file used for server and client" do
              it "returns the correct path hashed server path" do
                mock_bundle_configs(server_bundle_name: "webpack-bundle.js")
                # Clear server_bundle_output_path to test manifest behavior
                allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_output_path")
                  .and_return(nil)
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
              # Clear server_bundle_output_path to test manifest behavior
              allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_output_path")
                .and_return(nil)
              allow(ReactOnRails).to receive_message_chain("configuration.same_bundle_for_client_and_server")
                .and_return(false)
              mock_bundle_in_manifest("server-bundle.js", "webpack/development/server-bundle-123456.js")
              mock_dev_server_running

              path = described_class.server_bundle_js_file_path

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

      describe ".detect_package_manager" do
        let(:package_json_path) { File.join(Rails.root, "client", "package.json") }

        before do
          allow(ReactOnRails).to receive_message_chain("configuration.node_modules_location")
            .and_return("client")
          allow(Rails).to receive(:root).and_return(Rails.root)
        end

        context "when packageManager field exists in package.json" do
          it "returns :yarn for yarn@3.6.0" do
            allow(File).to receive(:exist?).with(package_json_path).and_return(true)
            allow(File).to receive(:read).with(package_json_path)
                                         .and_return('{"packageManager": "yarn@3.6.0"}')

            expect(described_class.detect_package_manager).to eq(:yarn)
          end

          it "returns :pnpm for pnpm@8.0.0" do
            allow(File).to receive(:exist?).with(package_json_path).and_return(true)
            allow(File).to receive(:read).with(package_json_path)
                                         .and_return('{"packageManager": "pnpm@8.0.0"}')

            expect(described_class.detect_package_manager).to eq(:pnpm)
          end

          it "returns :bun for bun@1.0.0" do
            allow(File).to receive(:exist?).with(package_json_path).and_return(true)
            allow(File).to receive(:read).with(package_json_path)
                                         .and_return('{"packageManager": "bun@1.0.0"}')

            expect(described_class.detect_package_manager).to eq(:bun)
          end

          it "returns :npm for npm@9.0.0" do
            allow(File).to receive(:exist?).with(package_json_path).and_return(true)
            allow(File).to receive(:read).with(package_json_path)
                                         .and_return('{"packageManager": "npm@9.0.0"}')

            expect(described_class.detect_package_manager).to eq(:npm)
          end

          it "falls back to lock file detection for unknown manager" do
            allow(File).to receive(:exist?).and_call_original
            allow(File).to receive(:exist?).with(package_json_path).and_return(true)
            allow(File).to receive(:read).with(package_json_path)
                                         .and_return('{"packageManager": "unknown@1.0.0"}')
            allow(File).to receive(:exist?).with(File.join(Rails.root, "yarn.lock")).and_return(true)

            expect(described_class.detect_package_manager).to eq(:yarn)
          end
        end

        context "when packageManager field does not exist" do
          before do
            allow(File).to receive(:exist?).with(package_json_path).and_return(true)
            allow(File).to receive(:read).with(package_json_path)
                                         .and_return('{"name": "my-app"}')
          end

          it "returns :yarn when yarn.lock exists" do
            allow(File).to receive(:exist?).and_call_original
            allow(File).to receive(:exist?).with(package_json_path).and_return(true)
            allow(File).to receive(:exist?).with(File.join(Rails.root, "yarn.lock")).and_return(true)

            expect(described_class.detect_package_manager).to eq(:yarn)
          end

          it "returns :pnpm when pnpm-lock.yaml exists" do
            allow(File).to receive(:exist?).and_call_original
            allow(File).to receive(:exist?).with(package_json_path).and_return(true)
            allow(File).to receive(:exist?).with(File.join(Rails.root, "yarn.lock")).and_return(false)
            allow(File).to receive(:exist?).with(File.join(Rails.root, "pnpm-lock.yaml")).and_return(true)

            expect(described_class.detect_package_manager).to eq(:pnpm)
          end

          it "returns :bun when bun.lockb exists" do
            allow(File).to receive(:exist?).and_call_original
            allow(File).to receive(:exist?).with(package_json_path).and_return(true)
            allow(File).to receive(:exist?).with(File.join(Rails.root, "yarn.lock")).and_return(false)
            allow(File).to receive(:exist?).with(File.join(Rails.root, "pnpm-lock.yaml")).and_return(false)
            allow(File).to receive(:exist?).with(File.join(Rails.root, "bun.lockb")).and_return(true)

            expect(described_class.detect_package_manager).to eq(:bun)
          end

          it "returns :npm when package-lock.json exists" do
            allow(File).to receive(:exist?).and_call_original
            allow(File).to receive(:exist?).with(package_json_path).and_return(true)
            allow(File).to receive(:exist?).with(File.join(Rails.root, "yarn.lock")).and_return(false)
            allow(File).to receive(:exist?).with(File.join(Rails.root, "pnpm-lock.yaml")).and_return(false)
            allow(File).to receive(:exist?).with(File.join(Rails.root, "bun.lockb")).and_return(false)
            allow(File).to receive(:exist?).with(File.join(Rails.root, "package-lock.json")).and_return(true)

            expect(described_class.detect_package_manager).to eq(:npm)
          end

          it "defaults to :yarn when no lock files exist" do
            allow(File).to receive(:exist?).and_call_original
            allow(File).to receive(:exist?).with(package_json_path).and_return(true)
            allow(File).to receive(:exist?).with(File.join(Rails.root, "yarn.lock")).and_return(false)
            allow(File).to receive(:exist?).with(File.join(Rails.root, "pnpm-lock.yaml")).and_return(false)
            allow(File).to receive(:exist?).with(File.join(Rails.root, "bun.lockb")).and_return(false)
            allow(File).to receive(:exist?).with(File.join(Rails.root, "package-lock.json")).and_return(false)

            expect(described_class.detect_package_manager).to eq(:yarn)
          end
        end

        context "when package.json cannot be parsed" do
          before do
            allow(File).to receive(:exist?).and_call_original
            allow(File).to receive(:exist?).with(package_json_path).and_return(true)
            allow(File).to receive(:read).with(package_json_path).and_return("invalid json")
          end

          it "falls back to lock file detection" do
            allow(File).to receive(:exist?).with(File.join(Rails.root, "yarn.lock")).and_return(true)

            expect(described_class.detect_package_manager).to eq(:yarn)
          end
        end

        context "when package.json does not exist" do
          before do
            allow(File).to receive(:exist?).and_call_original
            allow(File).to receive(:exist?).with(package_json_path).and_return(false)
          end

          it "falls back to lock file detection" do
            allow(File).to receive(:exist?).with(File.join(Rails.root, "yarn.lock")).and_return(false)
            allow(File).to receive(:exist?).with(File.join(Rails.root, "pnpm-lock.yaml")).and_return(true)

            expect(described_class.detect_package_manager).to eq(:pnpm)
          end
        end
      end

      describe ".package_manager_install_exact_command" do
        before do
          allow(described_class).to receive(:detect_package_manager).and_return(package_manager)
        end

        context "when using yarn" do
          let(:package_manager) { :yarn }

          it "returns yarn add command with --exact flag" do
            expect(described_class.package_manager_install_exact_command("react-on-rails", "16.0.0"))
              .to eq("yarn add react-on-rails@16.0.0 --exact")
          end
        end

        context "when using pnpm" do
          let(:package_manager) { :pnpm }

          it "returns pnpm add command with --save-exact flag" do
            expect(described_class.package_manager_install_exact_command("react-on-rails", "16.0.0"))
              .to eq("pnpm add react-on-rails@16.0.0 --save-exact")
          end
        end

        context "when using bun" do
          let(:package_manager) { :bun }

          it "returns bun add command with --exact flag" do
            expect(described_class.package_manager_install_exact_command("react-on-rails", "16.0.0"))
              .to eq("bun add react-on-rails@16.0.0 --exact")
          end
        end

        context "when using npm" do
          let(:package_manager) { :npm }

          it "returns npm install command with --save-exact flag" do
            expect(described_class.package_manager_install_exact_command("react-on-rails", "16.0.0"))
              .to eq("npm install react-on-rails@16.0.0 --save-exact")
          end
        end

        context "when package manager is unknown" do
          let(:package_manager) { :unknown }

          it "defaults to yarn add command" do
            expect(described_class.package_manager_install_exact_command("react-on-rails", "16.0.0"))
              .to eq("yarn add react-on-rails@16.0.0 --exact")
          end
        end
      end

      describe ".package_manager_remove_command" do
        before do
          allow(described_class).to receive(:detect_package_manager).and_return(package_manager)
        end

        context "when using yarn" do
          let(:package_manager) { :yarn }

          it "returns yarn remove command" do
            expect(described_class.package_manager_remove_command("react-on-rails"))
              .to eq("yarn remove react-on-rails")
          end
        end

        context "when using pnpm" do
          let(:package_manager) { :pnpm }

          it "returns pnpm remove command" do
            expect(described_class.package_manager_remove_command("react-on-rails"))
              .to eq("pnpm remove react-on-rails")
          end
        end

        context "when using bun" do
          let(:package_manager) { :bun }

          it "returns bun remove command" do
            expect(described_class.package_manager_remove_command("react-on-rails"))
              .to eq("bun remove react-on-rails")
          end
        end

        context "when using npm" do
          let(:package_manager) { :npm }

          it "returns npm uninstall command" do
            expect(described_class.package_manager_remove_command("react-on-rails"))
              .to eq("npm uninstall react-on-rails")
          end
        end

        context "when package manager is unknown" do
          let(:package_manager) { :unknown }

          it "defaults to yarn remove command" do
            expect(described_class.package_manager_remove_command("react-on-rails"))
              .to eq("yarn remove react-on-rails")
          end
        end
      end
    end

    # RSC utility method tests moved to react_on_rails_pro/spec/react_on_rails_pro/utils_spec.rb

    describe ".normalize_to_relative_path" do
      let(:rails_root) { "/app" }

      before do
        allow(Rails).to receive(:root).and_return(Pathname.new(rails_root))
      end

      context "with absolute path containing Rails.root" do
        it "removes Rails.root prefix" do
          expect(described_class.normalize_to_relative_path("/app/ssr-generated"))
            .to eq("ssr-generated")
        end

        it "handles paths with trailing slash in Rails.root" do
          expect(described_class.normalize_to_relative_path("/app/ssr-generated/nested"))
            .to eq("ssr-generated/nested")
        end

        it "removes leading slash after Rails.root" do
          allow(Rails).to receive(:root).and_return(Pathname.new("/app/"))
          expect(described_class.normalize_to_relative_path("/app/ssr-generated"))
            .to eq("ssr-generated")
        end
      end

      context "with Pathname object" do
        it "converts Pathname to relative string" do
          path = Pathname.new("/app/ssr-generated")
          expect(described_class.normalize_to_relative_path(path))
            .to eq("ssr-generated")
        end

        it "handles already relative Pathname" do
          path = Pathname.new("ssr-generated")
          expect(described_class.normalize_to_relative_path(path))
            .to eq("ssr-generated")
        end
      end

      context "with already relative path" do
        it "returns the path unchanged" do
          expect(described_class.normalize_to_relative_path("ssr-generated"))
            .to eq("ssr-generated")
        end

        it "handles nested relative paths" do
          expect(described_class.normalize_to_relative_path("config/ssr-generated"))
            .to eq("config/ssr-generated")
        end

        it "handles paths with . prefix" do
          expect(described_class.normalize_to_relative_path("./ssr-generated"))
            .to eq("./ssr-generated")
        end
      end

      context "with nil path" do
        it "returns nil" do
          expect(described_class.normalize_to_relative_path(nil)).to be_nil
        end
      end

      context "with absolute path not containing Rails.root" do
        it "returns path unchanged" do
          expect(described_class.normalize_to_relative_path("/other/path/ssr-generated"))
            .to eq("/other/path/ssr-generated")
        end

        it "logs warning for absolute path outside Rails.root" do
          expect(Rails.logger).to receive(:warn).with(
            %r{ReactOnRails: Detected absolute path outside Rails\.root: '/other/path/ssr-generated'}
          )
          described_class.normalize_to_relative_path("/other/path/ssr-generated")
        end

        it "does not warn for relative paths" do
          expect(Rails.logger).not_to receive(:warn)
          described_class.normalize_to_relative_path("ssr-generated")
        end
      end

      context "with path containing Rails.root as substring" do
        it "only removes Rails.root prefix, not substring matches" do
          allow(Rails).to receive(:root).and_return(Pathname.new("/app"))
          # Path contains "/app" but not as prefix
          expect(described_class.normalize_to_relative_path("/myapp/ssr-generated"))
            .to eq("/myapp/ssr-generated")
        end
      end

      context "with complex Rails.root paths" do
        it "handles Rails.root with special characters" do
          allow(Rails).to receive(:root).and_return(Pathname.new("/home/user/my-app"))
          expect(described_class.normalize_to_relative_path("/home/user/my-app/ssr-generated"))
            .to eq("ssr-generated")
        end

        it "handles Rails.root with spaces" do
          allow(Rails).to receive(:root).and_return(Pathname.new("/home/user/my app"))
          expect(described_class.normalize_to_relative_path("/home/user/my app/ssr-generated"))
            .to eq("ssr-generated")
        end

        it "handles Rails.root with dots" do
          allow(Rails).to receive(:root).and_return(Pathname.new("/home/user/app.v2"))
          expect(described_class.normalize_to_relative_path("/home/user/app.v2/ssr-generated"))
            .to eq("ssr-generated")
        end
      end
    end

    describe ".normalize_immediate_hydration" do
      context "with Pro license" do
        before do
          allow(described_class).to receive(:react_on_rails_pro?).and_return(true)
        end

        it "returns true when value is explicitly true" do
          result = described_class.normalize_immediate_hydration(true, "TestComponent", "Component")
          expect(result).to be true
        end

        it "returns false when value is explicitly false" do
          result = described_class.normalize_immediate_hydration(false, "TestComponent", "Component")
          expect(result).to be false
        end

        it "returns true when value is nil (Pro default)" do
          result = described_class.normalize_immediate_hydration(nil, "TestComponent", "Component")
          expect(result).to be true
        end

        it "does not log a warning for any valid value" do
          expect(Rails.logger).not_to receive(:warn)

          described_class.normalize_immediate_hydration(true, "TestComponent", "Component")
          described_class.normalize_immediate_hydration(false, "TestComponent", "Component")
          described_class.normalize_immediate_hydration(nil, "TestComponent", "Component")
        end
      end

      context "without Pro license" do
        before do
          allow(described_class).to receive(:react_on_rails_pro?).and_return(false)
        end

        it "returns false and logs warning when value is explicitly true" do
          expect(Rails.logger).to receive(:warn)
            .with(/immediate_hydration: true requires a React on Rails Pro license/)

          result = described_class.normalize_immediate_hydration(true, "TestComponent", "Component")
          expect(result).to be false
        end

        it "returns false when value is explicitly false" do
          expect(Rails.logger).not_to receive(:warn)

          result = described_class.normalize_immediate_hydration(false, "TestComponent", "Component")
          expect(result).to be false
        end

        it "returns false when value is nil (non-Pro default)" do
          expect(Rails.logger).not_to receive(:warn)

          result = described_class.normalize_immediate_hydration(nil, "TestComponent", "Component")
          expect(result).to be false
        end

        it "includes component name and type in warning message" do
          expect(Rails.logger).to receive(:warn) do |message|
            expect(message).to include("TestStore")
            expect(message).to include("Store")
          end

          described_class.normalize_immediate_hydration(true, "TestStore", "Store")
        end
      end

      context "with invalid values" do
        it "raises ArgumentError for string values" do
          expect do
            described_class.normalize_immediate_hydration("yes", "TestComponent", "Component")
          end.to raise_error(ArgumentError, /immediate_hydration must be true, false, or nil/)
        end

        it "raises ArgumentError for numeric values" do
          expect do
            described_class.normalize_immediate_hydration(1, "TestComponent", "Component")
          end.to raise_error(ArgumentError, /immediate_hydration must be true, false, or nil/)
        end

        it "raises ArgumentError for hash values" do
          expect do
            described_class.normalize_immediate_hydration({}, "TestComponent", "Component")
          end.to raise_error(ArgumentError, /immediate_hydration must be true, false, or nil/)
        end

        it "includes the invalid value in error message" do
          expect do
            described_class.normalize_immediate_hydration("invalid", "TestComponent", "Component")
          end.to raise_error(ArgumentError, /Got: "invalid" \(String\)/)
        end
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength, Metrics/BlockLength

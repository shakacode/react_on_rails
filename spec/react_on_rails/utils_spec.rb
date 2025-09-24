# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength, Metrics/BlockLength
module ReactOnRails
  RSpec.describe Utils do
    describe ".bundle_js_file_path" do
      include_context "with shakapacker enabled"

      # Context for testing server_bundle? and .bundle_js_file_path with various configurations.
      packers_to_test = %i[shakapacker]

      def mock_shakapacker_implementation
        allow(::Shakapacker).to receive(:instance).and_return(double("Shakapacker Instance"))
        allow(::Shakapacker).to receive(:manifest).and_return(double("Manifest", config: double("Config")))
        allow(::Shakapacker.instance).to receive(:root_path).and_return(Rails.root)
        allow(::Shakapacker.manifest.config).to receive(:public_output_path)
          .and_return(::Pathname.new("public/webpack/dev"))
      end

      def mock_bundle_in_manifest(bundle_name, manifest_path)
        manifest = double("Manifest")
        allow(manifest).to receive(:lookup!).with(bundle_name).and_return(manifest_path)
        allow(Shakapacker).to receive(:manifest).and_return(manifest)
      end

      def mock_missing_manifest_entry(bundle_name)
        manifest = double("Manifest")
        allow(manifest).to receive(:lookup!).with(bundle_name)
          .and_raise(Shakapacker::Manifest::MissingEntryError, "Entry #{bundle_name} not found")
        allow(Shakapacker).to receive(:manifest).and_return(manifest)
      end

      # Generate random unique bundle names to prevent accidental test passes
      # if server_bundle and rsc_bundle get swapped in the code
      def random_bundle_name
        "bundle-#{SecureRandom.hex(8)}.js"
      end

      # Helper to create a double for ReactOnRails.configuration with all server bundle settings
      # This double includes the new server_bundle_output_path for configuring the private directory
      # and the new enforce_private_server_bundles setting for controlling public/private fallback behavior
      def make_config_double(
        server_bundle_js_file: "server-bundle.js",
        rsc_bundle_js_file: "rsc-bundle.js",
        server_bundle_output_path: "ssr-generated",
        enforce_private_server_bundles: false,
        same_bundle_for_client_and_server: false
      )
        double("Configuration",
               server_bundle_js_file: server_bundle_js_file,
               rsc_bundle_js_file: rsc_bundle_js_file,
               server_bundle_output_path: server_bundle_output_path,
               enforce_private_server_bundles: enforce_private_server_bundles,
               same_bundle_for_client_and_server: same_bundle_for_client_and_server)
      end

      # If bundle names are not provided, random unique names will be used for each bundle.
      # This ensures that if server_bundle and rsc_bundle are accidentally swapped in the code,
      # the tests will fail since each bundle has a distinct random name that won't match if used incorrectly.
      def mock_bundle_configs(server_bundle_name: random_bundle_name, rsc_bundle_name: random_bundle_name,
                              react_server_client_manifest_file: nil)
        allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_js_file")
          .and_return(server_bundle_name)
        allow(ReactOnRails).to receive_message_chain("configuration.rsc_bundle_js_file")
          .and_return(rsc_bundle_name)
        allow(ReactOnRails).to receive_message_chain("configuration.react_server_client_manifest_file")
          .and_return(react_server_client_manifest_file)
        allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_output_path")
          .and_return("ssr-generated")
        allow(ReactOnRails).to receive_message_chain("configuration.enforce_private_server_bundles")
          .and_return(false)
      end

      def mock_dev_server_running
        allow(::Shakapacker).to receive_message_chain("dev_server.running?")
          .and_return(true)
        allow(::Shakapacker.dev_server).to receive(:host_with_port)
          .and_return("localhost:3035")
        allow(::Shakapacker.dev_server).to receive(:protocol)
          .and_return("http")
      end

      context "with Shakapacker enabled", :shakapacker do
        before do
          mock_shakapacker_implementation
        end

        context "when server_bundle_path set and server bundle file" do
          before do
            allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_js_file")
              .and_return("server-bundle.js")
            allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_output_path")
              .and_return("ssr-generated")
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
                let(:public_path) { File.expand_path(File.join(packer_public_output_path, server_bundle_name)) }

                before do
                  mock_bundle_configs(server_bundle_name: server_bundle_name)
                  mock_missing_manifest_entry(server_bundle_name)
                end

                context "with server_bundle_output_path configured" do
                  context "when enforce_private_server_bundles=false" do
                    before do
                      # NOTE: mock_bundle_configs sets enforce_private_server_bundles to false
                      allow(File).to receive(:exist?).with(ssr_generated_path).and_return(true)
                    end

                    it "returns the private ssr-generated path when file exists" do
                      path = described_class.bundle_js_file_path(server_bundle_name)
                      expect(path).to eq(ssr_generated_path)
                    end

                    context "when private file doesn't exist" do
                      before do
                        allow(File).to receive(:exist?).with(ssr_generated_path).and_return(false)
                        allow(File).to receive(:exist?).with(public_path).and_return(false)
                      end

                      it "returns the public path as fallback" do
                        path = described_class.bundle_js_file_path(server_bundle_name)
                        expect(path).to eq(public_path)
                      end
                    end
                  end

                  context "when enforce_private_server_bundles=true" do
                    before do
                      allow(ReactOnRails).to receive_message_chain("configuration.enforce_private_server_bundles")
                        .and_return(true)
                    end

                    it "returns the private ssr-generated path without checking public paths" do
                      # Should not check File.exist? for public paths
                      expect(File).not_to receive(:exist?).with(public_path)

                      path = described_class.bundle_js_file_path(server_bundle_name)
                      expect(path).to eq(ssr_generated_path)
                    end
                  end
                end

                context "without server_bundle_output_path configured" do
                  before do
                    allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_output_path")
                      .and_return(nil)
                  end

                  it "returns the public path directly" do
                    path = described_class.bundle_js_file_path(server_bundle_name)
                    expect(path).to eq(public_path)
                  end
                end
              end

              context "with server bundle (SSR) file in manifest" do
                let(:server_bundle_name) { "server-bundle.js" }
                let(:manifest_path) { "/webpack/dev/server-bundle-abc123.js" }
                let(:expected_path) do
                  File.expand_path(File.join(packer_public_output_path, "server-bundle-abc123.js"))
                end

                before do
                  mock_bundle_configs(server_bundle_name: server_bundle_name)
                  mock_bundle_in_manifest(server_bundle_name, manifest_path)
                end

                context "with server_bundle_output_path configured" do
                  it "returns manifest path (ignores server_bundle_output_path when in manifest)" do
                    path = described_class.bundle_js_file_path(server_bundle_name)
                    expect(path).to eq(expected_path)
                  end
                end

                context "without server_bundle_output_path configured" do
                  before do
                    allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_output_path")
                      .and_return(nil)
                  end

                  it "returns manifest path directly" do
                    path = described_class.bundle_js_file_path(server_bundle_name)
                    expect(path).to eq(expected_path)
                  end
                end
              end

              context "with RSC bundle file not in manifest" do
                let(:rsc_bundle_name) { "rsc-bundle.js" }
                let(:ssr_generated_path) { File.expand_path(File.join("ssr-generated", rsc_bundle_name)) }
                let(:public_path) { File.expand_path(File.join(packer_public_output_path, rsc_bundle_name)) }

                before do
                  mock_bundle_configs(rsc_bundle_name: rsc_bundle_name)
                  mock_missing_manifest_entry(rsc_bundle_name)
                end

                context "with server_bundle_output_path configured and enforce_private_server_bundles=false" do
                  before do
                    # NOTE: mock_bundle_configs sets enforce_private_server_bundles to false
                    allow(File).to receive(:exist?).with(ssr_generated_path).and_return(true)
                  end

                  it "returns the private ssr-generated path when file exists" do
                    path = described_class.bundle_js_file_path(rsc_bundle_name)
                    expect(path).to eq(ssr_generated_path)
                  end
                end

                context "with enforce_private_server_bundles=true" do
                  before do
                    allow(ReactOnRails).to receive_message_chain("configuration.enforce_private_server_bundles")
                      .and_return(true)
                  end

                  it "returns the private ssr-generated path without checking public paths" do
                    # Should not check File.exist? for public paths
                    expect(File).not_to receive(:exist?).with(public_path)

                    path = described_class.bundle_js_file_path(rsc_bundle_name)
                    expect(path).to eq(ssr_generated_path)
                  end
                end
              end

              context "with RSC bundle file in manifest" do
                let(:rsc_bundle_name) { "rsc-bundle.js" }
                let(:manifest_path) { "/webpack/dev/rsc-bundle-xyz789.js" }
                let(:expected_path) do
                  File.expand_path(File.join(packer_public_output_path, "rsc-bundle-xyz789.js"))
                end

                before do
                  mock_bundle_configs(rsc_bundle_name: rsc_bundle_name)
                  mock_bundle_in_manifest(rsc_bundle_name, manifest_path)
                end

                it "returns manifest path" do
                  path = described_class.bundle_js_file_path(rsc_bundle_name)
                  expect(path).to eq(expected_path)
                end
              end
            end
          end
        end

        context "when server_bundle_path cleared" do
          before do
            allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_output_path")
              .and_return(nil)
            allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_js_file")
              .and_return("server-bundle.js")
            allow(ReactOnRails).to receive_message_chain("configuration.rsc_bundle_js_file")
              .and_return("rsc-bundle.js")
          end

          context ".server_bundle_js_file_path" do
            context "with server_bundle_output_path configured" do
              # This context block tests the behavior when a dedicated server bundle output path is configured.
              # The server_bundle_output_path option allows placing server bundles (SSR/RSC) in a separate
              # private directory outside the public assets folder for enhanced security.
              # When this path is set, server bundles will be resolved from this directory rather than
              # the public webpack output path.
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

                  # Should return public path as final fallback
                  expect(path).to eq(public_path)
                end
              end

              context "with enforce_private_server_bundles=true" do
                it "returns the private ssr-generated path without checking public paths" do
                  server_bundle_name = "server-bundle.js"
                  allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_js_file")
                    .and_return(server_bundle_name)
                  allow(ReactOnRails).to receive_message_chain("configuration.rsc_bundle_js_file")
                    .and_return("rsc-bundle.js")
                  allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_output_path")
                    .and_return("ssr-generated")
                  allow(ReactOnRails).to receive_message_chain("configuration.enforce_private_server_bundles")
                    .and_return(true)
                  mock_missing_manifest_entry(server_bundle_name)

                  # Should not check File.exist? at all when enforce_private_server_bundles is true
                  expect(File).not_to receive(:exist?)

                  path = described_class.server_bundle_js_file_path

                  expect(path).to end_with("ssr-generated/#{server_bundle_name}")
                end
              end
            end

            context "with shakapacker and same file used by server and client", :shakapacker do
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

                expect(path).to include("webpack-bundle-123456.js")
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

              context "with webpack-dev-server running, and server file separate from client files",
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

                  expect(path).to include("server-bundle-123456.js")
                end
              end
            end
          end

          context ".rsc_bundle_js_file_path" do
            context "with server_bundle_output_path configured" do
              # This context block tests the behavior when a dedicated server bundle output path is configured.
              # The server_bundle_output_path option allows placing server bundles (SSR/RSC) in a separate
              # private directory outside the public assets folder for enhanced security.
              # When this path is set, RSC bundles will be resolved from this directory rather than
              # the public webpack output path.
              it "returns the private ssr-generated path for RSC bundles" do
                server_bundle_name = "rsc-bundle.js"
                mock_bundle_configs(rsc_bundle_name: server_bundle_name)
                mock_missing_manifest_entry(server_bundle_name)

                path = described_class.rsc_bundle_js_file_path

                expect(path).to end_with("ssr-generated/#{server_bundle_name}")
              end
            end

            context "with enforce_private_server_bundles=true" do
              it "returns the private ssr-generated path for RSC bundles without checking public paths" do
                rsc_bundle_name = "rsc-bundle.js"
                allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_js_file")
                  .and_return("server-bundle.js")
                allow(ReactOnRails).to receive_message_chain("configuration.rsc_bundle_js_file")
                  .and_return(rsc_bundle_name)
                allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_output_path")
                  .and_return("ssr-generated")
                allow(ReactOnRails).to receive_message_chain("configuration.enforce_private_server_bundles")
                  .and_return(true)
                mock_missing_manifest_entry(rsc_bundle_name)

                # Should not check File.exist? at all when enforce_private_server_bundles is true
                expect(File).not_to receive(:exist?)

                path = described_class.rsc_bundle_js_file_path

                expect(path).to end_with("ssr-generated/#{rsc_bundle_name}")
              end
            end

            context "with shakapacker and same file used by server and client", :shakapacker do
              it "returns the correct path hashed server path" do
                # Use Shakapacker directly instead of packer method
                mock_bundle_configs(rsc_bundle_name: "webpack-bundle.js")
                # Clear server_bundle_output_path to test manifest behavior
                allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_output_path")
                  .and_return(nil)
                allow(ReactOnRails).to receive_message_chain("configuration.same_bundle_for_client_and_server")
                  .and_return(true)
                mock_bundle_in_manifest("webpack-bundle.js", "webpack/development/webpack-bundle-123456.js")
                allow(Shakapacker).to receive_message_chain("dev_server.running?")
                  .and_return(false)

                path = described_class.rsc_bundle_js_file_path

                expect(path).to include("webpack-bundle-123456.js")
              end

              context "with webpack-dev-server running, and same file used for server and client" do
                it "returns the correct path hashed server path" do
                  mock_bundle_configs(rsc_bundle_name: "webpack-bundle.js")
                  # Clear server_bundle_output_path to test manifest behavior
                  allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_output_path")
                    .and_return(nil)
                  allow(ReactOnRails).to receive_message_chain("configuration.same_bundle_for_client_and_server")
                    .and_return(true)
                  mock_dev_server_running
                  mock_bundle_in_manifest("webpack-bundle.js", "/webpack/development/webpack-bundle-123456.js")

                  path = described_class.rsc_bundle_js_file_path

                  expect(path).to eq("http://localhost:3035/webpack/development/webpack-bundle-123456.js")
                end
              end

              context "with webpack-dev-server running, and server file separate from client files",
                      packer_type.to_sym do
                it "returns the correct path hashed server path" do
                  mock_bundle_configs(rsc_bundle_name: "rsc-bundle.js")
                  # Clear server_bundle_output_path to test manifest behavior
                  allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_output_path")
                    .and_return(nil)
                  allow(ReactOnRails).to receive_message_chain("configuration.same_bundle_for_client_and_server")
                    .and_return(false)
                  mock_bundle_in_manifest("rsc-bundle.js", "webpack/development/server-bundle-123456.js")
                  mock_dev_server_running

                  path = described_class.rsc_bundle_js_file_path

                  expect(path).to include("server-bundle-123456.js")
                end
              end
            end
          end
        end
      end
    end

    describe ".truthy_presence" do
      context "when string empty" do
        it "returns nil" do
          expect(described_class.truthy_presence("")).to eq nil
        end
      end

      context "when string is yes" do
        it "returns true" do
          expect(described_class.truthy_presence("yes")).to eq true
        end
      end

      context "when string is true" do
        it "returns true" do
          expect(described_class.truthy_presence("true")).to eq true
        end
      end
    end

    describe ".object_to_boolean" do
      [nil, false, "false", "no", "n"].each do |value|
        it "returns false when #{value.inspect} (#{value.class})" do
          expect(described_class.object_to_boolean(value)).to eq(false)
        end
      end

      [true, "true", "yes", "y", 1, "1", "anything else", Object.new].each do |value|
        it "returns true when #{value.inspect} (#{value.class})" do
          expect(described_class.object_to_boolean(value)).to eq(true)
        end
      end
    end

    describe ".running_on_windows?" do
      before do
        stub_const("RUBY_PLATFORM", ruby_platform)
      end

      context "when platform is 32 bit Windows" do
        let(:ruby_platform) { "i386-mingw32" }

        it "returns true" do
          expect(described_class.running_on_windows?).to eq true
        end
      end

      context "when platform is 64 bit Windows" do
        let(:ruby_platform) { "x64-mingw32" }

        it "returns true" do
          expect(described_class.running_on_windows?).to eq true
        end
      end

      context "when platform is not Windows" do
        let(:ruby_platform) { "x86_64-darwin14" }

        it "returns false" do
          expect(described_class.running_on_windows?).to eq false
        end
      end
    end

    describe ".rails_version_less_than" do
      before do
        allow(Rails).to receive(:version).and_return(Gem::Version.create(rails_version))
      end

      describe "when Rails version is 3.1.2" do
        let(:rails_version) { "3.1.2" }

        it "returns false for 3.1.0" do
          expect(described_class.rails_version_less_than("3.1.0")).to eq false
        end

        it "returns false for 3.1.1" do
          expect(described_class.rails_version_less_than("3.1.1")).to eq false
        end

        it "returns false for 3.1.2" do
          expect(described_class.rails_version_less_than("3.1.2")).to eq false
        end

        it "returns true for 3.1.3" do
          expect(described_class.rails_version_less_than("3.1.3")).to eq true
        end

        it "returns true for 3.2" do
          expect(described_class.rails_version_less_than("3.2")).to eq true
        end
      end
    end

    describe ".rails_version_less_than_4_1_1" do
      describe "when rails version is 4.1.0" do
        before { allow(Rails).to receive(:version).and_return(Gem::Version.create("4.1.0")) }

        it "returns true" do
          expect(described_class.rails_version_less_than_4_1_1).to eq true
        end
      end

      describe "when rails version is 4.1.1" do
        before { allow(Rails).to receive(:version).and_return(Gem::Version.create("4.1.1")) }

        it "returns false" do
          expect(described_class.rails_version_less_than_4_1_1).to eq false
        end
      end
    end

    describe ".server_bundle_js_file_path" do
      include_context "with shakapacker enabled"

      # Calls the bundle_js_file_path method from ReactOnRails::Utils
      # to retrieve the file path for the server bundle configured
      # in ReactOnRails.
      it "delegates call to bundle_js_file_path with server bundle name" do
        # The configuration holds the name of the server bundle file
        server_bundle_js_file = "server.js"

        # Setup mock configuration with specific server bundle name
        allow(ReactOnRails).to receive_message_chain("configuration.server_bundle_js_file")
          .and_return(server_bundle_js_file)

        # Mock the bundle_js_file_path method to verify it's being called correctly
        allow(described_class).to receive(:bundle_js_file_path).with(server_bundle_js_file).and_return("/path/to/server.js")

        # Call the method under test
        result = described_class.server_bundle_js_file_path

        # Verify the delegation occurs correctly
        expect(described_class).to have_received(:bundle_js_file_path).with(server_bundle_js_file)
        expect(result).to eq("/path/to/server.js")
      end
    end

    describe ".rsc_bundle_js_file_path" do
      include_context "with shakapacker enabled"

      # Calls the bundle_js_file_path method from ReactOnRails::Utils
      # to retrieve the file path for the RSC bundle configured in ReactOnRails.
      it "delegates call to bundle_js_file_path with RSC bundle name" do
        # The configuration holds the name of the RSC bundle file
        rsc_bundle_js_file = "rsc-client-bundle.js"

        # Setup mock configuration with specific RSC bundle name
        allow(ReactOnRails).to receive_message_chain("configuration.rsc_bundle_js_file")
          .and_return(rsc_bundle_js_file)

        # Mock the bundle_js_file_path method to verify it's being called correctly
        allow(described_class).to receive(:bundle_js_file_path).with(rsc_bundle_js_file).and_return("/path/to/rsc-client-bundle.js")

        # Call the method under test
        result = described_class.rsc_bundle_js_file_path

        # Verify the delegation occurs correctly
        expect(described_class).to have_received(:bundle_js_file_path).with(rsc_bundle_js_file)
        expect(result).to eq("/path/to/rsc-client-bundle.js")
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
          allow(described_class).to receive(:bundle_js_file_path)
            .with("react-server-client-manifest.json")
            .and_return("/path/to/generated/assets/react-server-client-manifest.json")
        end

        it "does not use cached path" do
          # Call once to potentially set the cached path
          described_class.react_server_client_manifest_file_path

          # Change the configuration value and mock
          allow(ReactOnRails.configuration).to receive(:react_server_client_manifest_file)
            .and_return("changed-manifest.json")
          allow(described_class).to receive(:bundle_js_file_path)
            .with("changed-manifest.json")
            .and_return("/path/to/generated/assets/changed-manifest.json")

          # Should use the new value
          expect(described_class.react_server_client_manifest_file_path)
            .to eq("/path/to/generated/assets/changed-manifest.json")
        end
      end

      context "when not in development environment" do
        before do
          allow(described_class).to receive(:bundle_js_file_path)
            .with("react-server-client-manifest.json")
            .and_return("/path/to/generated/assets/react-server-client-manifest.json")
        end

        it "caches the path" do
          # Call once to set the cached path
          expected_path = "/path/to/generated/assets/react-server-client-manifest.json"
          expect(described_class.react_server_client_manifest_file_path).to eq(expected_path)

          # Change the configuration value
          allow(ReactOnRails.configuration).to receive(:react_server_client_manifest_file)
            .and_return("changed-manifest.json")

          # Should still use the cached path (not calling bundle_js_file_path again)
          expect(described_class.react_server_client_manifest_file_path).to eq(expected_path)
        end
      end

      context "with different manifest file names" do
        before do
          allow(described_class).to receive(:bundle_js_file_path)
            .with("react-server-client-manifest.json")
            .and_return("/path/to/generated/assets/react-server-client-manifest.json")
          allow(described_class).to receive(:bundle_js_file_path)
            .with("custom-server-client-manifest.json")
            .and_return("/path/to/generated/assets/custom-server-client-manifest.json")
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

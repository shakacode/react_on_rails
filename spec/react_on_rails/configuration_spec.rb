# frozen_string_literal: true

require_relative "spec_helper"
require "shakapacker"

# rubocop:disable Metrics/ModuleLength

module ReactOnRails
  RSpec.describe Configuration do
    let(:existing_path) { Pathname.new(Dir.mktmpdir) }
    let(:not_existing_path) { "/path/to/#{SecureRandom.hex(4)}" }

    before do
      ReactOnRails.instance_variable_set(:@configuration, nil)
      # Mock PackerUtils to avoid Shakapacker dependency in tests
      allow(Rails).to receive(:root).and_return(Pathname.new("/fake/rails/root")) unless Rails.root
      allow(ReactOnRails::PackerUtils).to receive(:packer_public_output_path)
        .and_return(File.expand_path(File.join(Rails.root, "public/packs")))
    end

    after do
      ReactOnRails.instance_variable_set(:@configuration, nil)
    end

    describe "generated_assets_dir" do
      let(:using_packer) { true }
      let(:packer_public_output_path) do
        File.expand_path(File.join(Rails.root, "public/packs"))
      end

      before do
        allow(Rails).to receive(:root).and_return(File.expand_path("."))
        allow(::Shakapacker).to receive_message_chain("config.public_output_path")
          .and_return(Pathname.new(packer_public_output_path))
        allow(ReactOnRails::PackerUtils).to receive(:packer_public_output_path)
          .and_return(packer_public_output_path)
      end

      it "does not throw if the generated assets dir is blank with shakapacker" do
        expect do
          ReactOnRails.configure do |config|
            config.generated_assets_dir = ""
          end
        end.not_to raise_error
      end

      it "does not throw if the packer_public_output_path does match the generated assets dir" do
        expect do
          ReactOnRails.configure do |config|
            config.generated_assets_dir = "public/packs"
          end
        end.not_to raise_error
      end

      it "does throw if the packer_public_output_path does not match the generated assets dir" do
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

    describe ".build_production_command" do
      context "when using Shakapacker 8" do
        it "fails when \"shakapacker_precompile\" is truly and \"build_production_command\" is truly" do
          allow(Shakapacker).to receive_message_chain("config.shakapacker_precompile?")
            .and_return(true)
          expect do
            ReactOnRails.configure do |config|
              config.build_production_command = "RAILS_ENV=production NODE_ENV=production bin/shakapacker"
            end
          end.to raise_error(ReactOnRails::Error, /shakapacker_precompile: false/)
        end

        it "doesn't fail when \"shakapacker_precompile\" is falsy and \"build_production_command\" is truly" do
          allow(Shakapacker).to receive_message_chain("config.shakapacker_precompile?")
            .and_return(false)
          expect do
            ReactOnRails.configure do |config|
              config.build_production_command = "RAILS_ENV=production NODE_ENV=production bin/shakapacker"
            end
          end.not_to raise_error
        end

        it "doesn't fail when \"shakapacker_precompile\" is truly and \"build_production_command\" is falsy" do
          allow(Shakapacker).to receive_message_chain("config.shakapacker_precompile?")
            .and_return(true)
          expect do
            ReactOnRails.configure {} # rubocop:disable-line Lint/EmptyBlock
          end.not_to raise_error
        end

        it "doesn't fail when \"shakapacker_precompile\" is falsy and \"build_production_command\" is falsy" do
          allow(Shakapacker).to receive_message_chain("config.shakapacker_precompile?")
            .and_return(false)
          expect do
            ReactOnRails.configure {} # rubocop:disable-line Lint/EmptyBlock
          end.not_to raise_error
        end
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
        end.not_to raise_error
        expect do
          ReactOnRails::Locales.compile
        end.to raise_error(ReactOnRails::Error, /invalid value for `config\.i18n_dir`/)
      end

      it "fails with not existing directory" do
        expect do
          ReactOnRails.configure do |config|
            config.i18n_dir = not_existing_path
          end
        end.not_to raise_error
        expect do
          ReactOnRails::Locales.compile
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
        expect do
          ReactOnRails::Locales.compile
        end.not_to raise_error
      end

      it "fails with empty string value" do
        expect do
          ReactOnRails.configure do |config|
            config.i18n_yml_dir = ""
          end
        end.not_to raise_error
        expect do
          ReactOnRails::Locales.compile
        end.to raise_error(ReactOnRails::Error, /invalid value for `config\.i18n_yml_dir`/)
      end

      it "fails with not existing directory" do
        expect do
          ReactOnRails.configure do |config|
            config.i18n_yml_dir = not_existing_path
          end
        end.not_to raise_error
        expect do
          ReactOnRails::Locales.compile
        end.to raise_error(ReactOnRails::Error, /invalid value for `config\.i18n_yml_dir`/)
      end
    end

    describe "RSC configuration options" do
      before do
        allow(ReactOnRails::PackerUtils).to receive_messages(
          supports_autobundling?: true,
          nested_entries?: true
        )
      end

      it "has default values for RSC-related configuration options" do
        ReactOnRails.configure {} # rubocop:disable Lint/EmptyBlock

        expect(ReactOnRails.configuration.rsc_bundle_js_file).to eq("")
        expect(ReactOnRails.configuration.react_client_manifest_file).to eq("react-client-manifest.json")
        expect(ReactOnRails.configuration.react_server_client_manifest_file).to eq("react-server-client-manifest.json")
      end

      it "allows setting rsc_bundle_js_file" do
        ReactOnRails.configure do |config|
          config.rsc_bundle_js_file = "custom-rsc-bundle.js"
        end

        expect(ReactOnRails.configuration.rsc_bundle_js_file).to eq("custom-rsc-bundle.js")
      end

      it "allows setting react_client_manifest_file" do
        ReactOnRails.configure do |config|
          config.react_client_manifest_file = "custom-client-manifest.json"
        end

        expect(ReactOnRails.configuration.react_client_manifest_file).to eq("custom-client-manifest.json")
      end

      it "allows setting react_server_client_manifest_file" do
        ReactOnRails.configure do |config|
          config.react_server_client_manifest_file = "custom-server-client-manifest.json"
        end

        expect(ReactOnRails.configuration.react_server_client_manifest_file).to eq("custom-server-client-manifest.json")
      end

      it "includes rsc files in webpack_generated_files when not blank" do
        ReactOnRails.configure do |config|
          config.rsc_bundle_js_file = "rsc-bundle.js"
          config.webpack_generated_files = []
        end

        expect(ReactOnRails.configuration.webpack_generated_files).to include("rsc-bundle.js")
      end

      it "includes client manifest in webpack_generated_files" do
        ReactOnRails.configure do |config|
          config.react_client_manifest_file = "custom-client-manifest.json"
          config.webpack_generated_files = []
        end

        expect(ReactOnRails.configuration.webpack_generated_files).to include("custom-client-manifest.json")
      end

      it "includes server-client manifest in webpack_generated_files" do
        ReactOnRails.configure do |config|
          config.react_server_client_manifest_file = "custom-server-client-manifest.json"
          config.webpack_generated_files = []
        end

        expect(ReactOnRails.configuration.webpack_generated_files).to include("custom-server-client-manifest.json")
      end

      it "configures all RSC options together for a typical RSC setup" do
        ReactOnRails.configure do |config|
          config.rsc_bundle_js_file = "rsc-bundle.js"
          config.react_client_manifest_file = "client-manifest.json"
          config.react_server_client_manifest_file = "server-client-manifest.json"
          config.webpack_generated_files = []
        end

        expect(ReactOnRails.configuration.rsc_bundle_js_file).to eq("rsc-bundle.js")
        expect(ReactOnRails.configuration.react_client_manifest_file).to eq("client-manifest.json")
        expect(ReactOnRails.configuration.react_server_client_manifest_file).to eq("server-client-manifest.json")

        # All RSC files should be included in webpack_generated_files
        expect(ReactOnRails.configuration.webpack_generated_files).to include("rsc-bundle.js")
        expect(ReactOnRails.configuration.webpack_generated_files).to include("client-manifest.json")
        expect(ReactOnRails.configuration.webpack_generated_files).to include("server-client-manifest.json")
      end

      it "allows nil values for RSC configuration options" do
        ReactOnRails.configure do |config|
          config.rsc_bundle_js_file = nil
          config.react_client_manifest_file = nil
          config.react_server_client_manifest_file = nil
          config.webpack_generated_files = []
        end

        expect(ReactOnRails.configuration.rsc_bundle_js_file).to be_nil
        expect(ReactOnRails.configuration.react_client_manifest_file).to be_nil
        expect(ReactOnRails.configuration.react_server_client_manifest_file).to be_nil

        # Nil values should not be included in webpack_generated_files
        expect(ReactOnRails.configuration.webpack_generated_files).not_to include(nil)
        # Only manifest.json should be in the list by default
        expect(ReactOnRails.configuration.webpack_generated_files).to eq(["manifest.json"])
      end
    end

    it "changes the configuration of the gem, such as setting the prerender option to false" do
      test_path = File.expand_path("public/webpack/test")
      allow(::Shakapacker).to receive_message_chain("config.public_output_path")
        .and_return(Pathname.new(test_path))
      allow(ReactOnRails::PackerUtils).to receive(:packer_public_output_path)
        .and_return(test_path)

      ReactOnRails.configure do |config|
        config.generated_assets_dir = test_path
        config.server_bundle_js_file = "server.js"
        config.prerender = false
      end

      expect(ReactOnRails.configuration.server_bundle_js_file).to eq("server.js")
      expect(ReactOnRails.configuration.prerender).to be(false)
    end

    it "changes the configuration of the gem, such as setting the prerender option to true" do
      test_path = File.expand_path("public/webpack/test")
      allow(::Shakapacker).to receive_message_chain("config.public_output_path")
        .and_return(Pathname.new(test_path))
      allow(ReactOnRails::PackerUtils).to receive(:packer_public_output_path)
        .and_return(test_path)

      ReactOnRails.configure do |config|
        config.generated_assets_dir = test_path
        config.server_bundle_js_file = "something.js"
        config.prerender = true
        config.random_dom_id = false
      end

      expect(ReactOnRails.configuration.server_bundle_js_file).to eq("something.js")
      expect(ReactOnRails.configuration.prerender).to be(true)
      expect(ReactOnRails.configuration.random_dom_id).to be(false)
    end

    it "works without specifying generated_assets_dir when using Shakapacker" do
      allow(::Shakapacker).to receive_message_chain("config.public_output_path")
        .and_return(Pathname.new("/tmp/public/packs"))

      expect do
        ReactOnRails.configure do |config|
          config.server_bundle_js_file = "server.js"
        end
      end.not_to raise_error

      expect(ReactOnRails.configuration.generated_assets_dir).to be_blank
    end

    it "calls raise_missing_components_subdirectory if auto_load_bundle = true & components_subdirectory is not set" do
      allow(ReactOnRails::PackerUtils).to receive_messages(
        supports_autobundling?: true,
        nested_entries?: true
      )

      expect do
        ReactOnRails.configure do |config|
          config.auto_load_bundle = true
        end
      end.to raise_error(ReactOnRails::Error, /components_subdirectory is not configured/)
    end

    it "checks that autobundling requirements are met if configuration options for autobundling are set" do
      allow(ReactOnRails::PackerUtils).to receive_messages(
        shakapacker_version_requirement_met?: true,
        nested_entries?: true,
        supports_autobundling?: true
      )

      ReactOnRails.configure do |config|
        config.auto_load_bundle = true
        config.components_subdirectory = "something"
      end

      expect(ReactOnRails::PackerUtils).to have_received(:supports_autobundling?)
      expect(ReactOnRails::PackerUtils).to have_received(:nested_entries?)
    end

    it "has a default configuration of the gem" do
      # rubocop:disable Lint/EmptyBlock
      ReactOnRails.configure do |_config|
      end
      # rubocop:enable Lint/EmptyBlock

      expect(ReactOnRails.configuration.random_dom_id).to be(true)
    end

    describe ".generated_component_packs_loading_strategy" do
      context "when using Shakapacker >= 8.2.0" do
        before do
          allow(ReactOnRails::PackerUtils).to receive(:shakapacker_version_requirement_met?)
            .with("8.2.0").and_return(true)
        end

        it "defaults to :async" do
          ReactOnRails.configure {} # rubocop:disable Lint/EmptyBlock
          expect(ReactOnRails.configuration.generated_component_packs_loading_strategy).to eq(:async)
        end

        it "accepts :async value" do
          expect do
            ReactOnRails.configure do |config|
              config.generated_component_packs_loading_strategy = :async
            end
          end.not_to raise_error
          expect(ReactOnRails.configuration.generated_component_packs_loading_strategy).to eq(:async)
        end

        it "accepts :defer value" do
          expect do
            ReactOnRails.configure do |config|
              config.generated_component_packs_loading_strategy = :defer
            end
          end.not_to raise_error
          expect(ReactOnRails.configuration.generated_component_packs_loading_strategy).to eq(:defer)
        end

        it "accepts :sync value" do
          expect do
            ReactOnRails.configure do |config|
              config.generated_component_packs_loading_strategy = :sync
            end
          end.not_to raise_error
          expect(ReactOnRails.configuration.generated_component_packs_loading_strategy).to eq(:sync)
        end

        it "raises error for invalid values" do
          expect do
            ReactOnRails.configure do |config|
              config.generated_component_packs_loading_strategy = :invalid
            end
          end.to raise_error(ReactOnRails::Error, /must be either :async, :defer, or :sync/)
        end
      end

      context "when using Shakapacker < 8.2.0" do
        before do
          allow(ReactOnRails::PackerUtils).to receive(:shakapacker_version_requirement_met?)
            .with("8.2.0").and_return(false)
          allow(Rails.logger).to receive(:warn)
        end

        it "defaults to :sync and logs a warning" do
          ReactOnRails.configure {} # rubocop:disable Lint/EmptyBlock
          expect(ReactOnRails.configuration.generated_component_packs_loading_strategy).to eq(:sync)
          expect(Rails.logger).to have_received(:warn).with(/does not support async script loading/)
        end

        it "accepts :defer value" do
          expect do
            ReactOnRails.configure do |config|
              config.generated_component_packs_loading_strategy = :defer
            end
          end.not_to raise_error
          expect(ReactOnRails.configuration.generated_component_packs_loading_strategy).to eq(:defer)
        end

        it "accepts :sync value" do
          expect do
            ReactOnRails.configure do |config|
              config.generated_component_packs_loading_strategy = :sync
            end
          end.not_to raise_error
          expect(ReactOnRails.configuration.generated_component_packs_loading_strategy).to eq(:sync)
        end

        it "raises error for :async value" do
          expect do
            ReactOnRails.configure do |config|
              config.generated_component_packs_loading_strategy = :async
            end
          end.to raise_error(ReactOnRails::Error, /does not support async script loading/)
        end
      end
    end

    describe "enforce_private_server_bundles validation" do
      context "when enforce_private_server_bundles is true" do
        before do
          # Mock Rails.root for tests that need path validation
          allow(Rails).to receive(:root).and_return(Pathname.new("/test/app"))
        end

        it "raises error when server_bundle_output_path is nil" do
          expect do
            ReactOnRails.configure do |config|
              config.server_bundle_output_path = nil
              config.enforce_private_server_bundles = true
            end
          end.to raise_error(ReactOnRails::Error, /server_bundle_output_path is nil/)
        end

        it "raises error when server_bundle_output_path is inside public directory" do
          expect do
            ReactOnRails.configure do |config|
              config.server_bundle_output_path = "public/server-bundles"
              config.enforce_private_server_bundles = true
            end
          end.to raise_error(ReactOnRails::Error, /is inside the public directory/)
        end

        it "allows server_bundle_output_path outside public directory" do
          expect do
            ReactOnRails.configure do |config|
              config.server_bundle_output_path = "ssr-generated"
              config.enforce_private_server_bundles = true
            end
          end.not_to raise_error
        end
      end

      context "when enforce_private_server_bundles is false" do
        it "allows server_bundle_output_path to be nil" do
          expect do
            ReactOnRails.configure do |config|
              config.server_bundle_output_path = nil
              config.enforce_private_server_bundles = false
            end
          end.not_to raise_error
        end

        it "allows server_bundle_output_path inside public directory" do
          expect do
            ReactOnRails.configure do |config|
              config.server_bundle_output_path = "public/server-bundles"
              config.enforce_private_server_bundles = false
            end
          end.not_to raise_error
        end
      end
    end

    describe "#ensure_webpack_generated_files_exists" do
      let(:config) { described_class.new }

      before do
        # Reset to test defaults
        config.server_bundle_js_file = "server-bundle.js"
        config.rsc_bundle_js_file = nil
        config.react_client_manifest_file = "react-client-manifest.json"
        config.react_server_client_manifest_file = "react-server-client-manifest.json"
      end

      context "when webpack_generated_files has default manifest.json only" do
        it "automatically includes server bundle when configured" do
          config.webpack_generated_files = %w[manifest.json]

          config.send(:ensure_webpack_generated_files_exists)

          expect(config.webpack_generated_files).to eq(%w[
                                                         manifest.json
                                                         server-bundle.js
                                                         react-client-manifest.json
                                                         react-server-client-manifest.json
                                                       ])
        end

        it "does not duplicate manifest.json" do
          config.webpack_generated_files = %w[manifest.json]

          config.send(:ensure_webpack_generated_files_exists)

          expect(config.webpack_generated_files.count("manifest.json")).to eq(1)
        end
      end

      context "when webpack_generated_files is empty" do
        it "populates with all required files" do
          config.webpack_generated_files = []

          config.send(:ensure_webpack_generated_files_exists)

          expect(config.webpack_generated_files).to eq(%w[
                                                         manifest.json
                                                         server-bundle.js
                                                         react-client-manifest.json
                                                         react-server-client-manifest.json
                                                       ])
        end
      end

      context "when server bundle already included" do
        it "does not duplicate entries" do
          config.webpack_generated_files = %w[manifest.json server-bundle.js]

          config.send(:ensure_webpack_generated_files_exists)

          expect(config.webpack_generated_files).to eq(%w[
                                                         manifest.json
                                                         server-bundle.js
                                                         react-client-manifest.json
                                                         react-server-client-manifest.json
                                                       ])
          expect(config.webpack_generated_files.count("server-bundle.js")).to eq(1)
        end
      end

      context "when custom files are configured" do
        it "preserves custom files and adds missing critical files" do
          config.webpack_generated_files = %w[manifest.json custom-bundle.js]

          config.send(:ensure_webpack_generated_files_exists)

          expect(config.webpack_generated_files).to include("manifest.json")
          expect(config.webpack_generated_files).to include("custom-bundle.js")
          expect(config.webpack_generated_files).to include("server-bundle.js")
          expect(config.webpack_generated_files).to include("react-client-manifest.json")
        end
      end

      context "when server bundle is not configured" do
        it "does not add nil server bundle" do
          config.server_bundle_js_file = nil
          config.webpack_generated_files = %w[manifest.json]

          config.send(:ensure_webpack_generated_files_exists)

          expect(config.webpack_generated_files).not_to include(nil)
          expect(config.webpack_generated_files).not_to include("server-bundle.js")
          expect(config.webpack_generated_files).to include("manifest.json")
        end
      end

      context "when RSC bundle is configured" do
        it "includes RSC bundle in monitoring" do
          config.rsc_bundle_js_file = "rsc-bundle.js"
          config.webpack_generated_files = %w[manifest.json]

          config.send(:ensure_webpack_generated_files_exists)

          expect(config.webpack_generated_files).to include("rsc-bundle.js")
          expect(config.webpack_generated_files).to include("server-bundle.js")
          expect(config.webpack_generated_files).to include("manifest.json")
        end
      end

      context "when React manifests are not configured" do
        it "does not add nil React manifests" do
          config.react_client_manifest_file = nil
          config.react_server_client_manifest_file = nil
          config.webpack_generated_files = %w[manifest.json]

          config.send(:ensure_webpack_generated_files_exists)

          expect(config.webpack_generated_files).not_to include(nil)
          expect(config.webpack_generated_files).to eq(%w[manifest.json server-bundle.js])
        end
      end

      context "when ensuring server bundle monitoring for RSpec optimization" do
        it "ensures server bundle in private directory is monitored with default config" do
          # Simulate default generator configuration
          config.webpack_generated_files = %w[manifest.json]
          config.server_bundle_js_file = "server-bundle.js"
          config.server_bundle_output_path = "ssr-generated"

          config.send(:ensure_webpack_generated_files_exists)

          # Critical: server bundle must be included for RSpec helper optimization to work
          expect(config.webpack_generated_files).to include("server-bundle.js")
        end

        it "handles all files being in different directories" do
          # Simulate cross-directory scenario from PR #1798
          config.webpack_generated_files = %w[manifest.json]
          config.server_bundle_js_file = "server-bundle.js"
          config.server_bundle_output_path = "ssr-generated"
          config.generated_assets_dir = "public/packs"

          config.send(:ensure_webpack_generated_files_exists)

          # All critical files should be monitored regardless of directory
          expect(config.webpack_generated_files).to include("manifest.json")
          expect(config.webpack_generated_files).to include("server-bundle.js")
        end
      end
    end
  end
end

# rubocop:enable Metrics/ModuleLength

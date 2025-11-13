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

    describe ".immediate_hydration (deprecated)" do
      before do
        # Reset the warning flag before each test
        described_class.immediate_hydration_warned = false
        allow(Rails.logger).to receive(:warn)
      end

      after do
        # Reset the warning flag after each test
        described_class.immediate_hydration_warned = false
      end

      describe "setter" do
        it "logs a deprecation warning when setting to true" do
          ReactOnRails.configure do |config|
            config.immediate_hydration = true
          end

          expect(Rails.logger).to have_received(:warn)
            .with(/immediate_hydration' configuration option is deprecated/)
        end

        it "logs a deprecation warning when setting to false" do
          ReactOnRails.configure do |config|
            config.immediate_hydration = false
          end

          expect(Rails.logger).to have_received(:warn)
            .with(/immediate_hydration' configuration option is deprecated/)
        end

        it "mentions the value in the warning message" do
          ReactOnRails.configure do |config|
            config.immediate_hydration = true
          end

          expect(Rails.logger).to have_received(:warn) do |message|
            expect(message).to include("config.immediate_hydration = true")
          end
        end

        it "only logs the warning once even if called multiple times" do
          ReactOnRails.configure do |config|
            config.immediate_hydration = true
            config.immediate_hydration = false
            config.immediate_hydration = true
          end

          expect(Rails.logger).to have_received(:warn).once
        end
      end

      describe "getter" do
        it "logs a deprecation warning when accessed" do
          ReactOnRails.configure {} # rubocop:disable Lint/EmptyBlock

          ReactOnRails.configuration.immediate_hydration

          expect(Rails.logger).to have_received(:warn)
            .with(/immediate_hydration' configuration option is deprecated/)
        end

        it "returns nil" do
          ReactOnRails.configure {} # rubocop:disable Lint/EmptyBlock

          result = ReactOnRails.configuration.immediate_hydration

          expect(result).to be_nil
        end

        it "only logs the warning once even if called multiple times" do
          ReactOnRails.configure {} # rubocop:disable Lint/EmptyBlock

          ReactOnRails.configuration.immediate_hydration
          ReactOnRails.configuration.immediate_hydration
          ReactOnRails.configuration.immediate_hydration

          expect(Rails.logger).to have_received(:warn).once
        end
      end

      describe "setter and getter interactions" do
        it "does not warn again on getter if setter already warned" do
          ReactOnRails.configure do |config|
            config.immediate_hydration = true
          end

          expect(Rails.logger).to have_received(:warn).once

          ReactOnRails.configuration.immediate_hydration

          # Still only one warning total
          expect(Rails.logger).to have_received(:warn).once
        end

        it "does not warn again on setter if getter already warned" do
          ReactOnRails.configure {} # rubocop:disable Lint/EmptyBlock

          ReactOnRails.configuration.immediate_hydration

          expect(Rails.logger).to have_received(:warn).once

          ReactOnRails.configure do |config|
            config.immediate_hydration = true
          end

          # Still only one warning total
          expect(Rails.logger).to have_received(:warn).once
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
  end
end

# rubocop:enable Metrics/ModuleLength

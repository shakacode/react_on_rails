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
          # Simulate Pro being available for these feature tests
          stub_const("ReactOnRailsPro", Module.new)
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
          # Simulate Pro being available for these feature tests
          stub_const("ReactOnRailsPro", Module.new)
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

      context "when ReactOnRailsPro is not available" do
        before do
          # Ensure ReactOnRailsPro is not defined
          hide_const("ReactOnRailsPro") if defined?(ReactOnRailsPro)
          allow(ReactOnRails::PackerUtils).to receive(:shakapacker_version_requirement_met?)
            .with("8.2.0").and_return(true)
        end

        it "defaults to :defer for non-Pro users" do
          ReactOnRails.configure {} # rubocop:disable Lint/EmptyBlock
          expect(ReactOnRails.configuration.generated_component_packs_loading_strategy).to eq(:defer)
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

        it "raises error for :async value (Pro-only)" do
          allow(Rails.env).to receive(:production?).and_return(false)
          expect do
            ReactOnRails.configure do |config|
              config.generated_component_packs_loading_strategy = :async
            end
          end.to raise_error(ReactOnRails::Error, /Pro-only features without React on Rails Pro/)
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

    describe "Pro-only feature validation" do
      context "when ReactOnRailsPro is not defined" do
        before do
          # Ensure ReactOnRailsPro is not defined
          hide_const("ReactOnRailsPro") if defined?(ReactOnRailsPro)
          # Mock PackerUtils for generated_component_packs_loading_strategy
          allow(ReactOnRails::PackerUtils).to receive(:supports_async_loading?).and_return(true)
        end

        context "when immediate_hydration is set to true" do
          it "raises error in non-production environments" do
            allow(Rails.env).to receive(:production?).and_return(false)
            expect do
              ReactOnRails.configure do |config|
                config.immediate_hydration = true
              end
            end.to raise_error(ReactOnRails::Error, /Pro-only features without React on Rails Pro/)
          end

          it "logs error in production but does not raise" do
            allow(Rails.env).to receive(:production?).and_return(true)
            allow(Rails.logger).to receive(:error)
            expect do
              ReactOnRails.configure do |config|
                config.immediate_hydration = true
              end
            end.not_to raise_error
            expect(Rails.logger).to have_received(:error).with(/Pro-only features/)
          end
        end

        context "when generated_component_packs_loading_strategy is set to :async" do
          it "raises error in non-production environments" do
            allow(Rails.env).to receive(:production?).and_return(false)
            expect do
              ReactOnRails.configure do |config|
                config.generated_component_packs_loading_strategy = :async
              end
            end.to raise_error(ReactOnRails::Error, /Pro-only features without React on Rails Pro/)
          end

          it "logs error in production but does not raise" do
            allow(Rails.env).to receive(:production?).and_return(true)
            allow(Rails.logger).to receive(:error)
            expect do
              ReactOnRails.configure do |config|
                config.generated_component_packs_loading_strategy = :async
              end
            end.not_to raise_error
            expect(Rails.logger).to have_received(:error).with(/Pro-only features/)
          end
        end

        context "when generated_component_packs_loading_strategy is set to :defer or :sync" do
          it "does not raise error for :defer" do
            expect do
              ReactOnRails.configure do |config|
                config.generated_component_packs_loading_strategy = :defer
              end
            end.not_to raise_error
          end

          it "does not raise error for :sync" do
            expect do
              ReactOnRails.configure do |config|
                config.generated_component_packs_loading_strategy = :sync
              end
            end.not_to raise_error
          end
        end

        context "when both Pro-only features are set" do
          it "lists both features in error message" do
            allow(Rails.env).to receive(:production?).and_return(false)
            expect do
              ReactOnRails.configure do |config|
                config.immediate_hydration = true
                config.generated_component_packs_loading_strategy = :async
              end
            end.to raise_error(ReactOnRails::Error, /immediate_hydration.*generated_component_packs_loading_strategy/m)
          end
        end

        context "when immediate_hydration is set to false" do
          it "does not raise error" do
            expect do
              ReactOnRails.configure do |config|
                config.immediate_hydration = false
              end
            end.not_to raise_error
          end
        end

        context "when no Pro-only features are set" do
          it "does not raise error" do
            expect do
              ReactOnRails.configure {} # rubocop:disable Lint/EmptyBlock
            end.not_to raise_error
          end
        end
      end

      context "when ReactOnRailsPro is defined" do
        before do
          # Simulate ReactOnRailsPro being defined
          stub_const("ReactOnRailsPro", Module.new)
          allow(ReactOnRails::PackerUtils).to receive(:supports_async_loading?).and_return(true)
        end

        it "allows immediate_hydration = true" do
          expect do
            ReactOnRails.configure do |config|
              config.immediate_hydration = true
            end
          end.not_to raise_error
        end

        it "allows generated_component_packs_loading_strategy to be set" do
          expect do
            ReactOnRails.configure do |config|
              config.generated_component_packs_loading_strategy = :async
            end
          end.not_to raise_error
        end
      end
    end
  end
end

# rubocop:enable Metrics/ModuleLength

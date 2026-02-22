# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRailsPro # rubocop:disable Metrics/ModuleLength
  RSpec.describe Configuration do
    after do
      ReactOnRailsPro.instance_variable_set(:@configuration, nil)
    end

    describe ".assets_to_copy" do
      it "stays an array if array provided" do
        value = %w[a b]
        ReactOnRailsPro.configure do |config|
          config.assets_to_copy = value
        end
        expect(ReactOnRailsPro.configuration.assets_to_copy).to eq(value)
      end

      it "converts a single value to an array" do
        ReactOnRailsPro.configure do |config|
          config.assets_to_copy = "a"
        end
        expect(ReactOnRailsPro.configuration.assets_to_copy).to eq(["a"])
      end

      it "keep nil if not provided" do
        ReactOnRailsPro.configure do |config|
          config.assets_to_copy = ""
        end
        expect(ReactOnRailsPro.configuration.assets_to_copy).to be_nil
      end
    end

    describe ".remote_bundle_cache_adapter" do
      it "throws if any value besides a module is assigned" do
        expect do
          ReactOnRailsPro.configure do |config|
            config.remote_bundle_cache_adapter = "invalid value"
          end
        end.to raise_error(ReactOnRailsPro::Error,
                           /config.remote_bundle_cache_adapter can only have a module or class assigned/)
      end

      context "when assigned a module" do
        it "throws if the assigned module does not have a class method named 'build'" do
          expect do
            ReactOnRailsPro.configure do |config|
              config.remote_bundle_cache_adapter = Class.new
            end
          end.to raise_error(ReactOnRailsPro::Error,
                             /config.remote_bundle_cache_adapter must have a class method named 'build'/)
        end

        it "throws if the assigned module does not have a class method named 'fetch'" do
          expect do
            ReactOnRailsPro.configure do |config|
              config.remote_bundle_cache_adapter = Class.new do
                def self.build(*)
                  true
                end
              end
            end
          end.to raise_error(ReactOnRailsPro::Error,
                             /config.remote_bundle_cache_adapter must have a class method named 'fetch'/)
        end

        it "throws if the assigned module does not have a class method named 'upload'" do
          expect do
            ReactOnRailsPro.configure do |config|
              config.remote_bundle_cache_adapter = Class.new do
                def self.build(*)
                  true
                end

                def self.fetch(*)
                  true
                end
              end
            end
          end.to raise_error(ReactOnRailsPro::Error,
                             /config.remote_bundle_cache_adapter must have a class method named 'upload'/)
        end
      end
    end

    describe ".renderer_url" do
      it "is the renderer_url if provided" do
        url = "http://something.com:1234"

        ReactOnRailsPro.configure do |config|
          config.renderer_url = url
        end

        expect(ReactOnRailsPro.configuration.renderer_url).to eq(url)
      end

      it "is the default of http://localhost:3800 if render_url is ''" do
        ReactOnRailsPro.configure do |config|
          config.renderer_url = ""
        end

        expect(ReactOnRailsPro.configuration.renderer_url)
          .to eq(ReactOnRailsPro::Configuration::DEFAULT_RENDERER_URL)
      end

      it "is the default of http://localhost:3800 if render_url is nil" do
        ReactOnRailsPro.configure do |config|
          config.renderer_url = nil
        end

        expect(ReactOnRailsPro.configuration.renderer_url)
          .to eq(ReactOnRailsPro::Configuration::DEFAULT_RENDERER_URL)
      end

      it "throws if render_url is not parseable by URI" do
        invalid_url = "https://:an#@!invalidpassword@server.com:123"
        expect do
          ReactOnRailsPro.configure do |config|
            config.renderer_url = invalid_url
          end
        end.to raise_error(ReactOnRailsPro::Error,
                           /Unparseable ReactOnRailsPro.config.renderer_url #{invalid_url} /)
      end
    end

    describe ".renderer_password" do
      it "is the renderer_password if provided" do
        password = "abcdef"

        ReactOnRailsPro.configure do |config|
          config.renderer_password = password
        end

        expect(ReactOnRailsPro.configuration.renderer_password).to eq(password)
      end

      it "is the URI password if provided in the URL" do
        password = "abcdef"

        url = "https://:#{password}@localhost:3800"
        ReactOnRailsPro.configure do |config|
          config.renderer_url = url
        end

        expect(ReactOnRailsPro.configuration.renderer_password).to eq(password)
      end

      it "is blank if not provided in the URL" do
        ReactOnRailsPro.configure do |config|
          config.renderer_url = "https://localhost:3800"
        end

        expect(ReactOnRailsPro.configuration.renderer_password).to be_nil
      end
    end

    describe ".profile_server_rendering_js_code" do
      before do
        # mock the ExecJS runtime to be Node
        allow(ExecJS).to receive(:runtime).and_return(ExecJS::Runtimes::Node)
      end

      it "is the profile_server_rendering_js_code if provided" do
        ReactOnRailsPro.configure do |config|
          config.profile_server_rendering_js_code = true
        end

        expect(ReactOnRailsPro.configuration.profile_server_rendering_js_code).to be(true)
      end

      it "is false if not provided" do
        ReactOnRailsPro.configure do |_config|
          # Do nothing
        end

        expect(ReactOnRailsPro.configuration.profile_server_rendering_js_code).to be(false)
      end

      it "configures the ExecJS runtime if profile_server_rendering_js_code is true and server_renderer is ExecJS" do
        ReactOnRailsPro.configure do |config|
          config.profile_server_rendering_js_code = true
          config.server_renderer = "ExecJS"
        end

        expect(ExecJS.runtime).to be_a(ExecJS::ExternalRuntime)
      end

      it "raises an error if profile_server_rendering_js_code is true and used ExecJS runtime is not Node or V8" do
        allow(ExecJS).to receive(:runtime).and_return(ExecJS::Runtimes::Bun)

        expect do
          ReactOnRailsPro.configure do |config|
            config.profile_server_rendering_js_code = true
            config.server_renderer = "ExecJS"
          end
        end.to raise_error(ReactOnRailsPro::Error,
                           /ExecJS profiler only supports Node.js \(V8\) or V8 runtimes./)
      end
    end

    describe "RSC configuration options" do
      it "has default values for RSC bundle and manifest files" do
        ReactOnRailsPro.configure {} # rubocop:disable Lint/EmptyBlock

        expect(ReactOnRailsPro.configuration.rsc_bundle_js_file).to eq("rsc-bundle.js")
        expect(ReactOnRailsPro.configuration.react_client_manifest_file).to eq("react-client-manifest.json")
        expect(ReactOnRailsPro.configuration.react_server_client_manifest_file)
          .to eq("react-server-client-manifest.json")
      end

      it "allows setting rsc_bundle_js_file" do
        ReactOnRailsPro.configure do |config|
          config.rsc_bundle_js_file = "custom-rsc-bundle.js"
        end

        expect(ReactOnRailsPro.configuration.rsc_bundle_js_file).to eq("custom-rsc-bundle.js")
      end

      it "allows setting react_client_manifest_file" do
        ReactOnRailsPro.configure do |config|
          config.react_client_manifest_file = "custom-client-manifest.json"
        end

        expect(ReactOnRailsPro.configuration.react_client_manifest_file).to eq("custom-client-manifest.json")
      end

      it "allows setting react_server_client_manifest_file" do
        ReactOnRailsPro.configure do |config|
          config.react_server_client_manifest_file = "custom-server-client-manifest.json"
        end

        expect(ReactOnRailsPro.configuration.react_server_client_manifest_file)
          .to eq("custom-server-client-manifest.json")
      end

      it "allows nil values for RSC configuration options" do
        ReactOnRailsPro.configure do |config|
          config.rsc_bundle_js_file = nil
          config.react_client_manifest_file = nil
          config.react_server_client_manifest_file = nil
        end

        expect(ReactOnRailsPro.configuration.rsc_bundle_js_file).to be_nil
        expect(ReactOnRailsPro.configuration.react_client_manifest_file).to be_nil
        expect(ReactOnRailsPro.configuration.react_server_client_manifest_file).to be_nil
      end

      it "configures all RSC options together for a typical RSC setup" do
        ReactOnRailsPro.configure do |config|
          config.enable_rsc_support = true
          config.rsc_bundle_js_file = "rsc-bundle.js"
          config.react_client_manifest_file = "client-manifest.json"
          config.react_server_client_manifest_file = "server-client-manifest.json"
        end

        expect(ReactOnRailsPro.configuration.enable_rsc_support).to be(true)
        expect(ReactOnRailsPro.configuration.rsc_bundle_js_file).to eq("rsc-bundle.js")
        expect(ReactOnRailsPro.configuration.react_client_manifest_file).to eq("client-manifest.json")
        expect(ReactOnRailsPro.configuration.react_server_client_manifest_file).to eq("server-client-manifest.json")
      end
    end

    describe ".props_transformer" do
      it "is nil by default" do
        ReactOnRailsPro.configure {} # rubocop:disable Lint/EmptyBlock

        expect(ReactOnRailsPro.configuration.props_transformer).to be_nil
      end

      it "accepts a transformer that responds to transform_props" do
        transformer = Module.new do
          def self.transform_props(component_name, key_props)
            key_props.merge(expanded: true)
          end
        end

        ReactOnRailsPro.configure do |config|
          config.props_transformer = transformer
        end

        expect(ReactOnRailsPro.configuration.props_transformer).to eq(transformer)
      end

      it "raises error if transformer does not respond to transform_props" do
        expect do
          ReactOnRailsPro.configure do |config|
            config.props_transformer = Object.new
          end
        end.to raise_error(ReactOnRailsPro::Error,
                           /must respond to `transform_props/)
      end
    end

    describe ".concurrent_component_streaming_buffer_size" do
      it "accepts positive integers" do
        ReactOnRailsPro.configure do |config|
          config.concurrent_component_streaming_buffer_size = 128
        end

        expect(ReactOnRailsPro.configuration.concurrent_component_streaming_buffer_size).to eq(128)
      end

      it "raises error for non-positive integers" do
        expect do
          ReactOnRailsPro.configure do |config|
            config.concurrent_component_streaming_buffer_size = 0
          end
        end.to raise_error(ReactOnRailsPro::Error,
                           /must be a positive integer/)
      end

      it "raises error for negative integers" do
        expect do
          ReactOnRailsPro.configure do |config|
            config.concurrent_component_streaming_buffer_size = -1
          end
        end.to raise_error(ReactOnRailsPro::Error,
                           /must be a positive integer/)
      end

      it "raises error for non-integers" do
        expect do
          ReactOnRailsPro.configure do |config|
            config.concurrent_component_streaming_buffer_size = "64"
          end
        end.to raise_error(ReactOnRailsPro::Error,
                           /must be a positive integer/)
      end
    end
  end
end

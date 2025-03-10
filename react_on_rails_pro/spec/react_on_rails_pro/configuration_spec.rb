# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRailsPro
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
  end
end

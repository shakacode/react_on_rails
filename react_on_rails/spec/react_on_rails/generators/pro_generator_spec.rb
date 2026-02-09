# frozen_string_literal: true

require_relative "../support/generator_spec_helper"

# Base install output of serverWebpackConfig.js (use_pro? = false, use_rsc? = false)
# Contains all structural elements that Pro gsub transforms target.
BASE_SERVER_WEBPACK_CONFIG = <<~JS
  const { merge, config } = require('shakapacker');
  const commonWebpackConfig = require('./commonWebpackConfig');

  const bundler = config.assets_bundler === 'rspack'
    ? require('@rspack/core')
    : require('webpack');

  const configureServer = () => {
    const serverWebpackConfig = commonWebpackConfig();

    serverWebpackConfig.output = {
      filename: 'server-bundle.js',
      globalObject: 'this',
      // If using the React on Rails Pro node server renderer, uncomment the next line
      // libraryTarget: 'commonjs2',
      path: serverBundleOutputPath,
    };

    serverWebpackConfig.plugins.unshift(new bundler.optimize.LimitChunkCountPlugin({ maxChunks: 1 }));

    const rules = serverWebpackConfig.module.rules;
    rules.forEach((rule) => {
      if (Array.isArray(rule.use)) {
        const cssLoader = rule.use.find((item) => {
          return item.includes('css-loader');
        });
        if (cssLoader && cssLoader.options) {
          cssLoader.options.modules = { exportOnlyLocals: true };
        }
      }
    });

    serverWebpackConfig.devtool = 'eval';

    // If using the default 'web', then libraries like Emotion and loadable-components
    // break with SSR. The fix is to use a node renderer and change the target.
    // If using the React on Rails Pro node server renderer, uncomment the next line
    // serverWebpackConfig.target = 'node'

    return serverWebpackConfig;
  };

  module.exports = configureServer;
JS

# Base install output of ServerClientOrBoth.js (use_pro? = false)
BASE_SERVER_CLIENT_OR_BOTH = <<~JS
  const clientWebpackConfig = require('./clientWebpackConfig');
  const serverWebpackConfig = require('./serverWebpackConfig');

  const serverClientOrBoth = (envSpecific) => {
    const clientConfig = clientWebpackConfig();
    const serverConfig = serverWebpackConfig();

    if (envSpecific) {
      envSpecific(clientConfig, serverConfig);
    }

    let result;
    if (process.env.WEBPACK_SERVE || process.env.CLIENT_BUNDLE_ONLY) {
      // eslint-disable-next-line no-console
      console.log('[React on Rails] Creating only the client bundles.');
      result = clientConfig;
    } else if (process.env.SERVER_BUNDLE_ONLY) {
      // eslint-disable-next-line no-console
      console.log('[React on Rails] Creating only the server bundle.');
      result = serverConfig;
    } else {
      // default is the standard client and server build
      // eslint-disable-next-line no-console
      console.log('[React on Rails] Creating both client and server bundles.');
      result = [clientConfig, serverConfig];
    }

    return result;
  };

  module.exports = serverClientOrBoth;
JS

describe ProGenerator, type: :generator do
  include GeneratorSpec::TestCase

  destination File.expand_path("../dummy-for-generators", __dir__)

  # Unit tests for prerequisite validation

  context "when base React on Rails is not installed" do
    let(:generator) { described_class.new }

    before do
      allow(generator).to receive(:destination_root).and_return("/fake/path")
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?)
        .with("/fake/path/config/initializers/react_on_rails.rb")
        .and_return(false)
    end

    specify "missing_base_installation? returns true with helpful error" do
      expect(generator.send(:missing_base_installation?)).to be true
      error_text = GeneratorMessages.messages.join("\n")
      expect(error_text).to include("React on Rails is not installed")
      expect(error_text).to include("rails g react_on_rails:install")
    end
  end

  context "when Pro gem is not installed" do
    let(:generator) { described_class.new }

    before do
      allow(Gem).to receive(:loaded_specs).and_return({})
      allow(generator).to receive(:gem_in_lockfile?).with("react_on_rails_pro").and_return(false)
    end

    specify "missing_pro_gem? returns true with standalone error message" do
      expect(generator.send(:missing_pro_gem?, force: true)).to be true
      error_text = GeneratorMessages.messages.join("\n")
      # Standalone message should NOT mention --pro flag
      expect(error_text).to include("This generator requires the react_on_rails_pro gem")
      expect(error_text).not_to include("You specified")
      expect(error_text).to include("react_on_rails_pro")
    end
  end

  # Integration test for standalone happy path
  # Uses before (not before(:all)) to allow mocking the Pro gem check

  context "when prerequisites are met" do
    before do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      # Simulate base React on Rails installed
      simulate_existing_file("config/initializers/react_on_rails.rb", "ReactOnRails.configure {}")
      # Simulate Procfile.dev exists for appending
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      # Simulate base webpack configs (what base install generates without --pro)
      simulate_existing_file("config/webpack/serverWebpackConfig.js", BASE_SERVER_WEBPACK_CONFIG)
      simulate_existing_file("config/webpack/ServerClientOrBoth.js", BASE_SERVER_CLIENT_OR_BOTH)
      # Mock Pro gem as installed
      allow(Gem).to receive(:loaded_specs).and_return({ "react_on_rails_pro" => double })

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "creates Pro initializer" do
      assert_file "config/initializers/react_on_rails_pro.rb" do |content|
        expect(content).to include("ReactOnRailsPro.configure")
        expect(content).to include("config.server_renderer")
      end
    end

    it "Pro initializer does not include RSC config (RSC generator adds it)" do
      assert_file "config/initializers/react_on_rails_pro.rb" do |content|
        expect(content).not_to include("enable_rsc_support")
        expect(content).not_to include("rsc_bundle_js_file")
      end
    end

    it "creates node-renderer.js" do
      assert_file "client/node-renderer.js" do |content|
        expect(content).to include("reactOnRailsProNodeRenderer")
      end
    end

    it "adds node-renderer to Procfile.dev" do
      assert_file "Procfile.dev" do |content|
        expect(content).to include("node-renderer:")
        expect(content).to include("RENDERER_PORT=3800")
      end
    end

    describe "webpack config transforms" do
      it "adds extractLoader function" do
        assert_file "config/webpack/serverWebpackConfig.js" do |content|
          expect(content).to include("function extractLoader(rule, loaderName)")
        end
      end

      it "enables libraryTarget commonjs2" do
        assert_file "config/webpack/serverWebpackConfig.js" do |content|
          expect(content).to include("libraryTarget: 'commonjs2',")
          expect(content).not_to include("// libraryTarget: 'commonjs2',")
        end
      end

      it "sets target to node with clean comments" do
        assert_file "config/webpack/serverWebpackConfig.js" do |content|
          expect(content).to include("serverWebpackConfig.target = 'node';")
          expect(content).not_to include("// serverWebpackConfig.target = 'node'")
        end
      end

      it "disables node polyfills" do
        assert_file "config/webpack/serverWebpackConfig.js" do |content|
          expect(content).to include("serverWebpackConfig.node = false;")
        end
      end

      it "adds Babel SSR caller setup" do
        assert_file "config/webpack/serverWebpackConfig.js" do |content|
          expect(content).to include("babelLoader.options.caller = { ssr: true };")
        end
      end

      it "changes module.exports to object style" do
        assert_file "config/webpack/serverWebpackConfig.js" do |content|
          expect(content).to include("module.exports = {")
          expect(content).to include("default: configureServer,")
          expect(content).to include("extractLoader,")
        end
      end

      it "updates ServerClientOrBoth.js to destructured import" do
        assert_file "config/webpack/ServerClientOrBoth.js" do |content|
          expect(content).to include("{ default: serverWebpackConfig }")
          expect(content).not_to match(/^const serverWebpackConfig = require/)
        end
      end
    end
  end
end

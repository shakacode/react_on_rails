# frozen_string_literal: true

require_relative "../support/generator_spec_helper"

# Pro-transformed serverWebpackConfig.js (after Pro generator, before RSC)
# Contains extractLoader, object exports, LimitChunkCountPlugin — all RSC patterns target these.
PRO_SERVER_WEBPACK_CONFIG = <<~JS
  const { merge, config } = require('shakapacker');
  const commonWebpackConfig = require('./commonWebpackConfig');

  const bundler = config.assets_bundler === 'rspack'
    ? require('@rspack/core')
    : require('webpack');

  function extractLoader(rule, loaderName) {
    if (!Array.isArray(rule.use)) return null;
    return rule.use.find((item) => {
      const testValue = typeof item === 'string' ? item : item.loader;
      return testValue && testValue.includes(loaderName);
    });
  }

  const configureServer = () => {
    const serverWebpackConfig = commonWebpackConfig();

    serverWebpackConfig.plugins.unshift(new bundler.optimize.LimitChunkCountPlugin({ maxChunks: 1 }));

    serverWebpackConfig.target = 'node';
    serverWebpackConfig.node = false;

    return serverWebpackConfig;
  };

  module.exports = {
    default: configureServer,
    extractLoader,
  };
JS

# Pro-transformed ServerClientOrBoth.js (destructured import, no RSC yet)
PRO_SERVER_CLIENT_OR_BOTH = <<~JS
  const clientWebpackConfig = require('./clientWebpackConfig');
  const { default: serverWebpackConfig } = require('./serverWebpackConfig');

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

# Base clientWebpackConfig.js (no RSC yet)
BASE_CLIENT_WEBPACK_CONFIG = <<~JS
  const commonWebpackConfig = require('./commonWebpackConfig');

  const configureClient = () => {
    const clientConfig = commonWebpackConfig();
    delete clientConfig.entry['server-bundle'];

    return clientConfig;
  };

  module.exports = configureClient;
JS

describe RscGenerator, type: :generator do
  include GeneratorSpec::TestCase

  destination File.expand_path("../dummy-for-generators", __dir__)

  # Unit tests for prerequisite validation

  context "when Pro is not installed" do
    let(:generator) { described_class.new }

    before do
      allow(generator).to receive(:destination_root).and_return("/fake/path")
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?)
        .with("/fake/path/config/initializers/react_on_rails_pro.rb")
        .and_return(false)
    end

    specify "missing_pro_installation? returns true with helpful error" do
      expect(generator.send(:missing_pro_installation?)).to be true
      error_text = GeneratorMessages.messages.join("\n")
      expect(error_text).to include("React on Rails Pro is not installed")
      expect(error_text).to include("rails g react_on_rails:pro")
    end
  end

  # Integration test for standalone happy path

  context "when Pro is installed" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      # Simulate Pro initializer (must have multi-line block for gsub_file to work)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      # Simulate Procfile.dev exists for appending
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      # Simulate Pro-transformed webpack configs (what Pro generator produces)
      simulate_existing_file("config/webpack/serverWebpackConfig.js", PRO_SERVER_WEBPACK_CONFIG)
      simulate_existing_file("config/webpack/ServerClientOrBoth.js", PRO_SERVER_CLIENT_OR_BOTH)
      simulate_existing_file("config/webpack/clientWebpackConfig.js", BASE_CLIENT_WEBPACK_CONFIG)

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "adds RSC config to Pro initializer" do
      assert_file "config/initializers/react_on_rails_pro.rb" do |content|
        expect(content).to include("enable_rsc_support = true")
        expect(content).to include('rsc_bundle_js_file = "rsc-bundle.js"')
        expect(content).to include('rsc_payload_generation_url_path = "rsc_payload/"')
      end
    end

    it "creates RSC webpack config" do
      assert_file "config/webpack/rscWebpackConfig.js" do |content|
        expect(content).to include("rscConfig")
      end
    end

    it "creates HelloServer component" do
      assert_file "app/javascript/src/HelloServer/ror_components/HelloServer.jsx"
      assert_file "app/javascript/src/HelloServer/components/HelloServer.jsx"
    end

    it "creates HelloServerController" do
      assert_file "app/controllers/hello_server_controller.rb" do |content|
        expect(content).to include("HelloServerController")
      end
    end

    it "creates HelloServer view" do
      assert_file "app/views/hello_server/index.html.erb" do |content|
        expect(content).to include("HelloServer")
      end
    end

    it "adds RSC routes" do
      assert_file "config/routes.rb" do |content|
        expect(content).to include("rsc_payload_route")
        expect(content).to include("hello_server")
      end
    end

    it "adds rsc-bundle to Procfile.dev" do
      assert_file "Procfile.dev" do |content|
        expect(content).to include("rsc-bundle:")
        expect(content).to include("RSC_BUNDLE_ONLY")
      end
    end

    describe "webpack config transforms" do
      it "adds RSCWebpackPlugin to serverWebpackConfig" do
        assert_file "config/webpack/serverWebpackConfig.js" do |content|
          expect(content).to include("RSCWebpackPlugin")
          expect(content).to include("react-on-rails-rsc/WebpackPlugin")
        end
      end

      it "adds rscBundle parameter to configureServer" do
        assert_file "config/webpack/serverWebpackConfig.js" do |content|
          expect(content).to match(/configureServer\s*=\s*\(rscBundle\s*=\s*false\)/)
        end
      end

      it "adds RSCWebpackPlugin to clientWebpackConfig" do
        assert_file "config/webpack/clientWebpackConfig.js" do |content|
          expect(content).to include("RSCWebpackPlugin")
          expect(content).to include("react-on-rails-rsc/WebpackPlugin")
          expect(content).to include("new RSCWebpackPlugin({ isServer: false })")
        end
      end

      it "adds RSC handling to ServerClientOrBoth" do
        assert_file "config/webpack/ServerClientOrBoth.js" do |content|
          expect(content).to include("rscWebpackConfig")
          expect(content).to include("RSC_BUNDLE_ONLY")
          expect(content).to include("rscConfig")
        end
      end
    end
  end

  # TypeScript variant

  context "when Pro is installed with --typescript" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")

      Dir.chdir(destination_root) do
        run_generator(["--typescript", "--force"])
      end
    end

    it "creates HelloServer component with tsx extension" do
      assert_file "app/javascript/src/HelloServer/ror_components/HelloServer.tsx"
      assert_file "app/javascript/src/HelloServer/components/HelloServer.tsx"
      assert_no_file "app/javascript/src/HelloServer/ror_components/HelloServer.jsx"
    end
  end
end

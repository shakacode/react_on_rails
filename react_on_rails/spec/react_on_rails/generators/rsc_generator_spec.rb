# frozen_string_literal: true

require_relative "../support/generator_spec_helper"
require "open3"
require "tempfile"

describe RscGenerator, type: :generator do
  include GeneratorSpec::TestCase

  destination File.expand_path("../dummy-for-generators", __dir__)

  describe "#add_rsc_to_procfile" do
    let(:generator) { described_class.new([], {}, destination_root:) }

    before do
      prepare_destination
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
    end

    it "uses the standard Shakapacker command when the optional watch binstub is absent" do
      Dir.chdir(destination_root) { generator.send(:add_rsc_to_procfile) }

      assert_file "Procfile.dev" do |content|
        expect(content).to include("rsc-bundle: RSC_BUNDLE_ONLY=true bin/shakapacker --watch")
      end
    end

    it "uses Shakapacker's watch binstub when it is present" do
      simulate_existing_file("bin/shakapacker-watch", "#!/usr/bin/env sh\n")

      Dir.chdir(destination_root) { generator.send(:add_rsc_to_procfile) }

      assert_file "Procfile.dev" do |content|
        expect(content).to include("rsc-bundle: RSC_BUNDLE_ONLY=true bin/shakapacker-watch --watch")
      end
    end
  end

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

  context "when standalone Tailwind flag is passed" do
    before do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files

      Dir.chdir(destination_root) do
        run_generator(["--tailwind", "--force"])
      end
    end

    it "rejects standalone Tailwind setup instead of creating a broken layout" do
      error_text = GeneratorMessages.messages.join("\n")

      expect(error_text).to include("standalone react_on_rails:rsc generator does not support --tailwind")
      expect(error_text).to include("rails generate react_on_rails:install --rsc --tailwind")
      assert_no_file "app/views/layouts/react_on_rails_rsc.html.erb"
      assert_no_file "app/views/layouts/react_on_rails_default.html.erb"
      assert_no_file "app/javascript/packs/react_on_rails_tailwind.js"
      assert_no_file "app/javascript/stylesheets/application.css"
    end
  end

  describe "#install_agent_guardrails" do
    subject(:install_agent_guardrails) { generator.send(:install_agent_guardrails) }

    let(:generator) { described_class.new }

    before do
      allow(generator).to receive(:options).and_return(generator_options)
      allow(ReactOnRails::AgentGuardrails).to receive(:install).and_return([])
    end

    context "when the generator is in pretend mode" do
      let(:generator_options) { { pretend: true, skip: false } }

      it "does not write guardrail files" do
        install_agent_guardrails

        expect(ReactOnRails::AgentGuardrails).not_to have_received(:install)
      end
    end

    context "when the generator is in skip mode" do
      let(:generator_options) { { pretend: false, skip: true } }

      it "creates missing guardrails while preserving existing files" do
        install_agent_guardrails

        expect(ReactOnRails::AgentGuardrails).to have_received(:install)
          .with(generator.destination_root, skip_existing: true)
      end
    end

    context "when guardrail files cannot be written" do
      let(:generator_options) { { pretend: false, skip: false } }

      before do
        allow(generator).to receive(:say)
        allow(ReactOnRails::AgentGuardrails).to receive(:install).and_raise(Errno::EACCES, ".claude/settings.json")
      end

      it "warns and allows RSC generation to continue" do
        expect { install_agent_guardrails }.not_to raise_error
        expect(generator).to have_received(:say)
          .with(a_string_including("RSC agent guardrail installation incomplete", ".claude/settings.json"), :yellow)
      end
    end
  end

  # Integration test for standalone happy path

  context "when Pro is installed" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      # Simulate Pro initializer (must have multi-line block for gsub_file to work)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      # Simulate Procfile.dev exists for appending
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      # Simulate Pro-transformed webpack configs (what Pro generator produces)
      simulate_pro_webpack_files

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

    it "installs the RSC agent guardrails into .claude" do
      assert_file ".claude/skills/rsc-app-safety/SKILL.md"
      assert_file ".claude/hooks/rsc-app-safety-check.rb"
      assert_file ".claude/settings.json" do |content|
        expect(content).to include('"command": "ruby"')
        expect(content).to include("rsc-app-safety-check.rb")
      end
    end

    it "creates RSC webpack config" do
      assert_file "config/webpack/rscWebpackConfig.js" do |content|
        expect(content).to include("rscConfig")
        expect(content).not_to include(
          "const { RSCReferenceDiscoveryPlugin } = require('react-on-rails-rsc/RSCReferenceDiscoveryPlugin');"
        )
        expect(content).to include("const serverWebpackModule = require('./serverWebpackConfig');")
        expect(content).to include("require('react-on-rails-rsc/RSCReferenceDiscoveryPlugin')")
        expect(content).to include("Run bin/shakapacker-precompile-hook before bin/shakapacker.")
        expect(content).to include("process.env.REACT_ON_RAILS_RSC_REGISTRATION_ENTRY_PATH")
        expect(content).to include("defaultServerComponentRegistrationEntry")
        expect(content).to include("validServerComponentRegistrationEntry")
        expect(content).to include("basename(entryPath) !== expectedServerComponentRegistrationEntry")
        expect(content).to include("statSync(entryPath).isFile()")
        expect(content).to include("excludedRegistrationEntryPathComponents")
        expect(content).to include("const reactPackageRoot = dirname(require.resolve('react/package.json'))")
        expect(content).to include("const resolveReactServerEntry = (entryFilename) =>")
        expect(content).to include("existsSync(entryPath)")
        expect(content).to include("delete rscAliases.react")
        expect(content).to include("delete rscAliases['react$']")
        expect(content).to include("delete rscAliases['react/jsx-runtime']")
        expect(content).to include("delete rscAliases['react/jsx-runtime$']")
        expect(content).to include("delete rscAliases['react/jsx-dev-runtime']")
        expect(content).to include("delete rscAliases['react/jsx-dev-runtime$']")
        expect(content).to include("delete rscAliases['react-dom/server']")
        expect(content).to include("delete rscAliases['react-dom/server$']")
        expect(content).to include("react$: resolveReactServerEntry('react.react-server.js')")
        expect(content).to include("'react/jsx-runtime$': resolveReactServerEntry('jsx-runtime.react-server.js')")
        expect(content).to include(
          "'react/jsx-dev-runtime$': resolveReactServerEntry('jsx-dev-runtime.react-server.js')"
        )
      end
    end

    it "creates HelloServer component and LikeButton client component" do
      assert_file "app/javascript/src/HelloServer/ror_components/HelloServer.jsx"
      assert_file "app/javascript/src/HelloServer/components/HelloServer.jsx"
      assert_file "app/javascript/src/HelloServer/components/LikeButton.jsx"
    end

    it "creates react_on_rails_default layout when no compatible existing layout is found" do
      assert_file "app/views/layouts/react_on_rails_default.html.erb" do |content|
        expect(content).to include("<%= stylesheet_pack_tag %>")
        expect(content).to include("<%= javascript_pack_tag %>")
      end
    end

    include_examples "rsc_hello_server_files"

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
        expect(content).to include("bin/shakapacker --watch")
      end
    end

    describe "webpack config transforms" do
      it "adds RSCWebpackPlugin to serverWebpackConfig" do
        assert_file "config/webpack/serverWebpackConfig.js" do |content|
          expect(content).to include("RSCWebpackPlugin")
          expect(content).to include("react-on-rails-rsc/WebpackPlugin")
          expect(content).to include("clientReferences: rscClientReferences")
          expect(content).to include("const rscClientReferences = (() => {")
          expect(content).to include("const defaultRefsJson = resolve('ssr-generated/rsc-client-references.json');")
          expect(content).to include("return readManifestReferences(defaultRefsJson);")
          expect(content).to include("directory: resolve(config.source_path)")
          expect(content).to include('include: /\.(js|mjs|cjs|ts|mts|cts|jsx|tsx)$/')
          expect(content).to include("isServer: true")
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
          expect(content).to include("clientReferences: rscClientReferences")
          expect(content).to include("const rscClientReferences = (() => {")
          expect(content).to include("const defaultRefsJson = resolve('ssr-generated/rsc-client-references.json');")
          expect(content).to include("return readManifestReferences(defaultRefsJson);")
          expect(content).to include("directory: resolve(config.source_path)")
          expect(content).to include('include: /\.(js|mjs|cjs|ts|mts|cts|jsx|tsx)$/')
          expect(content).to include("isServer: false")
        end
      end

      it "adds RSC handling to ServerClientOrBoth" do
        assert_file "config/webpack/ServerClientOrBoth.js" do |content|
          expect(content).to include("require('./rscWebpackConfig')")
          expect(content).to include("envSpecific(clientConfig, serverConfig, rscConfig);")
          expect(content).to include("RSC_BUNDLE_ONLY")
          expect(content).to include("rscConfig")
        end
      end
    end
  end

  context "when the client webpack config already imports Shakapacker config" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        "const { config } = require('shakapacker');\n#{base_client_webpack_content}"
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "does not inject a duplicate config import" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content.scan("const { config } = require('shakapacker');").length).to eq(1)
        expect(content).to include("clientReferences: rscClientReferences")
        expect(content).to include("directory: resolve(config.source_path)")
        expect(content).to include("isServer: false")
      end
    end
  end

  context "when the client webpack config already imports Shakapacker config across multiple lines" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        <<~JS
          const {
            config,
          } = require('shakapacker');
          #{base_client_webpack_content}
        JS
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "does not inject a duplicate config import" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content.scan("require('shakapacker')").length).to eq(1)
        expect(content).to include("clientReferences: rscClientReferences")
        expect(content).to include("directory: resolve(config.source_path)")
        expect(content).to include("isServer: false")
      end
    end
  end

  context "when the client webpack config uses a double-quoted common config import" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        base_client_webpack_content.sub("require('./commonWebpackConfig')", 'require("./commonWebpackConfig")')
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "adds RSCWebpackPlugin to clientWebpackConfig" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content).to include("RSCWebpackPlugin")
        expect(content).to include("clientReferences: rscClientReferences")
        expect(content).to include("directory: resolve(config.source_path)")
        expect(content).to include("isServer: false")
      end
    end
  end

  context "when the client webpack config cannot inject the scoped helper before adding the plugin" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const resolve = require('custom-resolver');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            delete clientConfig.entry['server-bundle'];

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "adds the plugin without scoped client references and warns that the helper was not added" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content).to include("RSCWebpackPlugin")
        expect(content).to include("new RSCWebpackPlugin({ isServer: false })")
        expect(content).not_to include("rscClientReferences")
      end

      expect(GeneratorMessages.messages.join("\n"))
        .to include("RSCWebpackPlugin will be added without scoped clientReferences")
    end
  end

  context "when a fresh client webpack config uses an unsupported import anchor" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        <<~JS
          const commonWebpackConfig = require(`./commonWebpackConfig`);

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            delete clientConfig.entry['server-bundle'];

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "leaves the plugin out and explicitly tells users the plugin was not added" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content).not_to include("RSCWebpackPlugin")
        expect(content).not_to include("rscClientReferences")
      end

      messages = GeneratorMessages.messages.join("\n")
      expect(messages).to include("backtick template-literal require paths")
      expect(messages).to include("RSCWebpackPlugin was not added to config/webpack/clientWebpackConfig.js")
    end
  end

  context "when a fresh client webpack config misses the plugin insertion point" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            delete clientConfig.entry['server-bundle'];

            finalizeClientConfig(clientConfig);
          };

          module.exports = configureClient;
        JS
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "rolls back the prepared imports and scoped helper" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content).not_to include("RSCWebpackPlugin")
        expect(content).not_to include("rscClientReferences")
        expect(content).to include("finalizeClientConfig(clientConfig);")
      end

      expect(GeneratorMessages.messages.join("\n"))
        .to include("Reverted partial RSC setup; please add RSCWebpackPlugin and clientReferences manually")
    end
  end

  context "when the client webpack config already imports RSCWebpackPlugin but has no active plugin call" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            delete clientConfig.entry['server-bundle'];

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "reuses the existing import rather than re-declaring it" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content.scan(%r{require\(['"]react-on-rails-rsc/WebpackPlugin['"]\)}).length).to eq(1)
        expect(content.scan(/new\s+RSCWebpackPlugin\s*\(/).length).to eq(1)
      end
    end
  end

  context "when an existing client webpack config invokes RSCWebpackPlugin with extra spacing" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            delete clientConfig.entry['server-bundle'];

            clientConfig.plugins.push(
              new RSCWebpackPlugin ({ isServer: false })
            );

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "detects the existing plugin and routes to the update path rather than duplicating the import" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content.scan(%r{require\(['"]react-on-rails-rsc/WebpackPlugin['"]\)}).length).to eq(1)
        expect(content.scan(/new\s+RSCWebpackPlugin\s*\(/).length).to eq(1)
      end
    end

    it "injects scoped clientReferences into the spaced plugin call" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content).to include("clientReferences: rscClientReferences")
        expect(content).to include("const rscClientReferences")
        expect(content).to include("directory: resolve(config.source_path)")
      end

      expect(GeneratorMessages.messages.join("\n"))
        .not_to include("no plugin options with isServer: false could be rewritten")
    end
  end

  context "when a fresh client webpack config has a commented-out RSCWebpackPlugin and no insertion point" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');

          // Old setup: clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));
          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            delete clientConfig.entry['server-bundle'];

            finalizeClientConfig(clientConfig);
          };

          module.exports = configureClient;
        JS
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "still rolls back the prepared imports rather than trusting the commented-out reference" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content).to include("// Old setup: clientConfig.plugins.push(new RSCWebpackPlugin")
        expect(content).not_to include("rscClientReferences")
        expect(content).not_to include("require('react-on-rails-rsc/WebpackPlugin')")
        expect(content).to include("finalizeClientConfig(clientConfig);")
      end

      expect(GeneratorMessages.messages.join("\n"))
        .to include("Reverted partial RSC setup; please add RSCWebpackPlugin and clientReferences manually")
    end
  end

  context "when the server webpack config uses double-quoted bundler imports" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/serverWebpackConfig.js",
        pro_server_webpack_content
          .sub("require('@rspack/core')", 'require("@rspack/core")')
          .sub("require('webpack')", 'require("webpack")')
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "adds RSCWebpackPlugin to serverWebpackConfig" do
      assert_file "config/webpack/serverWebpackConfig.js" do |content|
        expect(content).to include("RSCWebpackPlugin")
        expect(content).to include("clientReferences: rscClientReferences")
        expect(content).to include("directory: resolve(config.source_path)")
        expect(content).to include("isServer: true")
      end
    end
  end

  context "when a fresh server webpack config misses the plugin insertion point" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/serverWebpackConfig.js",
        pro_server_webpack_content.sub(
          "  serverWebpackConfig.plugins.unshift(new bundler.optimize.LimitChunkCountPlugin({ maxChunks: 1 }));\n\n",
          ""
        )
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "rolls back the prepared imports, scoped helper, and rscBundle parameter" do
      assert_file "config/webpack/serverWebpackConfig.js" do |content|
        expect(content).not_to include("RSCWebpackPlugin")
        expect(content).not_to include("rscClientReferences")
        expect(content).not_to include("rscBundle")
        expect(content).to include("const configureServer = () => {")
      end

      expect(GeneratorMessages.messages.join("\n"))
        .to include("Reverted partial RSC setup; please add RSCWebpackPlugin and clientReferences manually")
    end
  end

  context "when the server webpack config already imports path resolve" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/serverWebpackConfig.js",
        "const { resolve } = require('path');\n#{pro_server_webpack_content}"
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "does not inject a duplicate resolve import" do
      assert_file "config/webpack/serverWebpackConfig.js" do |content|
        expect(content.scan("const { resolve } = require('path');").length).to eq(1)
        expect(content).to include("clientReferences: rscClientReferences")
        expect(content).to include("directory: resolve(config.source_path)")
        expect(content).to include("isServer: true")
      end
    end
  end

  context "when existing RSC webpack configs lack scoped client references" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      limit_chunk_plugin = "serverWebpackConfig.plugins.unshift(" \
                           "new bundler.optimize.LimitChunkCountPlugin({ maxChunks: 1 }));"
      old_rsc_plugin = <<~JS.chomp
        if (!rscBundle) {
          serverWebpackConfig.plugins.push(new RSCWebpackPlugin({ chunkName: 'server', isServer: true }));
        }

        #{limit_chunk_plugin}
      JS
      simulate_existing_file(
        "config/webpack/serverWebpackConfig.js",
        <<~JS
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          #{pro_server_webpack_content
            .sub('const configureServer = () => {', 'const configureServer = (rscBundle = false) => {')
            .sub(limit_chunk_plugin, old_rsc_plugin)}
        JS
      )
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        <<~JS
          const config = require('shakapacker').config;
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          #{base_client_webpack_content.sub(
            'return clientConfig;',
            [
              "clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false, chunkName: 'client' }));",
              '',
              '  return clientConfig;'
            ].join("\n")
          )}
        JS
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "updates the existing server plugin to use scoped client references" do
      assert_file "config/webpack/serverWebpackConfig.js" do |content|
        rsc_plugin_import = "const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');"
        expect(content.scan(rsc_plugin_import).length).to eq(1)
        expect(content).to include("const { resolve } = require('path');")
        plugin_config = content[/new RSCWebpackPlugin\(\{([^}]*)\}\)/m, 1]
        expect(plugin_config).not_to be_nil
        expect(plugin_config).to include("clientReferences: rscClientReferences")
        expect(content).to include("directory: resolve(config.source_path)")
        expect(plugin_config).to include("chunkName: 'server'")
        expect(plugin_config).to include("isServer: true")
      end
    end

    it "updates the existing client plugin to use scoped client references" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        rsc_plugin_import = "const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');"
        expect(content.scan(rsc_plugin_import).length).to eq(1)
        expect(content).to include("const config = require('shakapacker').config;")
        expect(content).not_to include("const { config } = require('shakapacker');")
        expect(content).to include("const { resolve } = require('path');")
        plugin_config = content[/new RSCWebpackPlugin\(\{([^}]*)\}\)/m, 1]
        expect(plugin_config).not_to be_nil
        expect(plugin_config).to include("clientReferences: rscClientReferences")
        expect(content).to include("directory: resolve(config.source_path)")
        expect(plugin_config).to include("chunkName: 'client'")
        expect(plugin_config).to include("isServer: false")
      end
    end
  end

  context "when a server config has multiple RSC plugin targets" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      limit_chunk_plugin = "serverWebpackConfig.plugins.unshift(" \
                           "new bundler.optimize.LimitChunkCountPlugin({ maxChunks: 1 }));"
      old_rsc_plugins = <<~JS.chomp
        if (!rscBundle) {
          serverWebpackConfig.plugins.push(
            new RSCWebpackPlugin({
              isServer: false,
              clientReferences: customClientReferences,
            }),
          );
          serverWebpackConfig.plugins.push(
            new RSCWebpackPlugin({
              chunkName: getChunkName(),
              metadata: { owner: 'server' },
              isServer: true,
            }),
          );
        }

        #{limit_chunk_plugin}
      JS
      simulate_existing_file(
        "config/webpack/serverWebpackConfig.js",
        <<~JS
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          const customClientReferences = { directory: './custom' };
          const getChunkName = () => 'server';
          #{pro_server_webpack_content
            .sub('const configureServer = () => {', 'const configureServer = (rscBundle = false) => {')
            .sub(limit_chunk_plugin, old_rsc_plugins)}
        JS
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "only rewrites the matching server plugin and preserves the other target" do
      assert_file "config/webpack/serverWebpackConfig.js" do |content|
        expect(content.scan("clientReferences: customClientReferences").length).to eq(1)
        expect(content.scan("clientReferences: rscClientReferences").length).to eq(1)
        expect(content).to include("metadata: { owner: 'server' }")
        expect(content).to include("directory: resolve(config.source_path)")
        expect(content).to match(/isServer: true,\s*\n\s*clientReferences: rscClientReferences,/)
      end
    end
  end

  context "when an existing client RSC webpack config uses a double-quoted import anchor" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        <<~JS
          const commonWebpackConfig = require("./commonWebpackConfig");
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "updates the existing plugin to use scoped client references" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content).to include("clientReferences: rscClientReferences")
        expect(content).to include("const rscClientReferences")
        expect(content).to include("directory: resolve(config.source_path)")
        expect(content).to include("isServer: false")
      end
    end
  end

  context "when an existing RSC webpack config has no matching plugin target" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(new RSCWebpackPlugin({ mode: 'client' }));

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "leaves the plugin untouched and warns that no target was rewritten" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content).to include("new RSCWebpackPlugin({ mode: 'client' })")
        expect(content).not_to include("clientReferences: rscClientReferences")
        expect(content).not_to include("const rscClientReferences")
      end

      messages = GeneratorMessages.messages.join("\n")
      expect(messages).to include("no plugin options with isServer: false")
      expect(messages).to include("Dynamic or computed plugin options cannot be verified automatically")
    end
  end

  context "when an existing RSC webpack config has unsupported import anchors" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        <<~JS
          const buildClientWebpackConfig = require("./commonWebpackConfig");
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = buildClientWebpackConfig();
            clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "does not rewrite the plugin when the helper setup cannot be inserted" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content).not_to include("clientReferences: rscClientReferences")
        expect(content).not_to include("const rscClientReferences")
        expect(content).to include("new RSCWebpackPlugin({ isServer: false })")
      end

      expect(GeneratorMessages.messages.join("\n"))
        .to include("generated manifest-backed clientReferences resolver in clientWebpackConfig.js")
    end
  end

  context "when an existing RSC webpack config already defines custom client references" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          const customClientReferences = { directory: './custom' };
          const getChunkName = () => 'client';

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(
              new RSCWebpackPlugin({
                chunkName: getChunkName(),
                clientReferences: customClientReferences,
                isServer: false,
              }),
            );

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "leaves the custom client references untouched without adding a duplicate property" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content.scan("clientReferences:").length).to eq(1)
        expect(content).to include("clientReferences: customClientReferences")
        expect(content).not_to include("clientReferences: rscClientReferences")
        expect(content).not_to include("const rscClientReferences")
      end

      messages = GeneratorMessages.messages.join("\n")
      expect(messages).to include("already define clientReferences")
      expect(messages).to include("some may already be correctly scoped")
      expect(messages).to include("generated manifest-backed clientReferences resolver in clientWebpackConfig.js")
    end
  end

  context "when an existing RSC webpack config mentions scoped client references in a comment" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(
              new RSCWebpackPlugin({
                // clientReferences: rscClientReferences
                isServer: false,
              }),
            );

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "does not treat the comment as a configured clientReferences option" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content).to include("const rscClientReferences")
        expect(content).to match(/^\s*isServer: false,\n\s*clientReferences: rscClientReferences,/)
      end
    end
  end

  context "when an existing RSC webpack config uses shorthand clientReferences" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          const clientReferences = { directory: './custom' };

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(
              new RSCWebpackPlugin({
                isServer: false,
                clientReferences,
              }),
            );

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "treats shorthand clientReferences as configured without overriding the local variable" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content.scan(/\bclientReferences\b/).length).to eq(2)
        expect(content).to include("const clientReferences = { directory: './custom' };")
        expect(content).not_to include("clientReferences: rscClientReferences")
        expect(content).not_to include("const rscClientReferences")
      end

      messages = GeneratorMessages.messages.join("\n")
      expect(messages).to include("already define clientReferences")
      expect(messages).to include("generated manifest-backed clientReferences resolver in clientWebpackConfig.js")
    end
  end

  context "when an existing RSC webpack config uses quoted clientReferences" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          const customClientReferences = { directory: './custom' };

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(
              new RSCWebpackPlugin({
                isServer: false,
                "clientReferences": customClientReferences,
              }),
            );

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "treats quoted clientReferences as configured without appending a duplicate key" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content.scan("clientReferences").length).to eq(1)
        expect(content).to include('"clientReferences": customClientReferences')
        expect(content).not_to include("clientReferences: rscClientReferences")
      end

      messages = GeneratorMessages.messages.join("\n")
      expect(messages).to include("already define clientReferences")
      expect(messages).to include("generated manifest-backed clientReferences resolver in clientWebpackConfig.js")
    end
  end

  describe "existing RSC webpack config migration helpers" do
    let(:generator) { described_class.new([], {}, { destination_root: }) }

    before do
      prepare_destination
    end

    it "rewrites an unscoped plugin when another same-target plugin has custom references" do
      config_path = "config/webpack/serverWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const { config } = require('shakapacker');
          const bundler = config.assets_bundler === 'rspack'
            ? require('@rspack/core')
            : require('webpack');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          const customClientReferences = { directory: './custom' };

          serverWebpackConfig.plugins.push(
            new RSCWebpackPlugin({
              isServer: true,
              clientReferences: customClientReferences,
            }),
          );
          serverWebpackConfig.plugins.push(
            new RSCWebpackPlugin({
              chunkName: 'server',
              isServer: true,
            }),
          );
        JS
      )

      content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: true)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content.scan("clientReferences: customClientReferences").length).to eq(1)
      expect(migrated_content.scan("clientReferences: rscClientReferences").length).to eq(1)
      expect(migrated_content).to include("chunkName: 'server'")
      expect(migrated_content).to include("directory: resolve(config.source_path)")
      expect(migrated_content).to match(/isServer: true,\s*\n\s*clientReferences: rscClientReferences,/)
      expect(generator.send(:check_rsc_server_config)).to include(
        "generated manifest-backed clientReferences resolver in serverWebpackConfig.js"
      )
    end

    it "upgrades an existing broad rscClientReferences helper on the fresh-install path" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const { config } = require('shakapacker');
          const { resolve } = require('path');
          const commonWebpackConfig = require('./commonWebpackConfig');

          const rscClientReferences = {
            directory: resolve(config.source_path),
            recursive: true,
            include: /\\.(js|mjs|cjs|ts|mts|cts|jsx|tsx)$/,
          };

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      generator.send(:update_client_webpack_config_for_rsc)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content.scan("const rscClientReferences").length).to eq(1)
      expect(migrated_content).to include("const fallbackRscClientReferences = {")
      expect(migrated_content).to include("const rscClientReferences = (() => {")
      expect(migrated_content).to include(
        "const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');"
      )
      expect(migrated_content).to include(
        "new RSCWebpackPlugin({ isServer: false, clientReferences: rscClientReferences })"
      )
    end

    it "upgrades an existing broad helper when the plugin already references rscClientReferences" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const { config } = require('shakapacker');
          const { resolve } = require('path');
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const rscClientReferences = {
            directory: resolve(config.source_path),
            recursive: true,
            include: /\\.(js|mjs|cjs|ts|mts|cts|jsx|tsx)$/,
          };

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(
              new RSCWebpackPlugin({
                isServer: false,
                clientReferences: rscClientReferences,
              }),
            );

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content.scan("const rscClientReferences").length).to eq(1)
      expect(migrated_content).to include("const fallbackRscClientReferences = {")
      expect(migrated_content).to include("const rscClientReferences = (() => {")
      expect(migrated_content).to include("clientReferences: rscClientReferences")
    end

    it "warns and skips wiring an existing unscoped rscClientReferences helper on the fresh-install path" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');

          const rscClientReferences = { directory: './custom' };

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      generator.send(:update_client_webpack_config_for_rsc)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content.scan("const rscClientReferences").length).to eq(1)
      expect(migrated_content).to include(
        "const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');"
      )
      expect(migrated_content).to include("new RSCWebpackPlugin({ isServer: false })")
      expect(migrated_content).not_to include("clientReferences: rscClientReferences")
      expect(GeneratorMessages.messages.join("\n"))
        .to include("rscClientReferences already exists but does not point to resolve(config.source_path)")
    end

    it "does not inject server client references when the shakapacker config binding is unavailable" do
      config_path = "config/webpack/serverWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const bundler = config.assets_bundler === 'rspack'
            ? require('@rspack/core')
            : require('webpack');
          const commonWebpackConfig = require('./commonWebpackConfig');

          const configureServer = () => {
            const serverWebpackConfig = commonWebpackConfig();
            serverWebpackConfig.plugins.unshift(new bundler.optimize.LimitChunkCountPlugin({ maxChunks: 1 }));

            return serverWebpackConfig;
          };

          module.exports = configureServer;
        JS
      )

      generator.send(:update_server_webpack_config_for_rsc)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).not_to include("const rscClientReferences")
      expect(migrated_content).not_to include("clientReferences: rscClientReferences")
      expect(GeneratorMessages.messages.join("\n"))
        .to include("shakapacker's `config` is not imported in this file")
    end

    it "ignores plugin markers in comments when finding rewrite targets" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          // Previously used: new RSCWebpackPlugin({ isServer: false })
          const migrationNote = "new RSCWebpackPlugin({ isServer: false })";
          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).to include("// Previously used: new RSCWebpackPlugin({ isServer: false })")
      expect(migrated_content).to include('const migrationNote = "new RSCWebpackPlugin({ isServer: false })";')
      expect(migrated_content).to include(
        "new RSCWebpackPlugin({ isServer: false, clientReferences: rscClientReferences })"
      )
    end

    it "appends clientReferences at the end of a single-line options object that has options after isServer" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false, chunkName: 'client' }));

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).to include(
        "new RSCWebpackPlugin({ isServer: false, chunkName: 'client', clientReferences: rscClientReferences })"
      )
      expect(migrated_content).not_to match(/isServer: false, clientReferences: rscClientReferences, chunkName/)
    end

    it "rewrites plugin options that include a template-literal value with simple ${} interpolation" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          const env = process.env.RAILS_ENV;

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(
              new RSCWebpackPlugin({
                isServer: false,
                chunkName: `${env}-bundle`,
              }),
            );

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).to include("chunkName: `${env}-bundle`,")
      expect(migrated_content).to match(
        /chunkName: `\$\{env\}-bundle`,\n\s+clientReferences: rscClientReferences,/
      )
      expect(migrated_content.scan("clientReferences: rscClientReferences").length).to eq(1)
    end

    it "adds clientReferences to the real isServer option when comments mention isServer first" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(
              new RSCWebpackPlugin({
                // isServer: false is documented here, but this is not the option.
                isServer: false,
              }),
            );

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).to include("// isServer: false is documented here, but this is not the option.")
      expect(migrated_content).not_to include("// isServer: false, clientReferences: rscClientReferences")
      expect(migrated_content).to match(/^\s*isServer: false,\n\s*clientReferences: rscClientReferences,/)
    end

    it "inserts the splice comma before a trailing line comment on the last option" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(
              new RSCWebpackPlugin({
                isServer: false // intentional: no trailing comma
              }),
            );

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).to include("isServer: false, // intentional: no trailing comma")
      expect(migrated_content).not_to include("// intentional: no trailing comma,")
      expect(migrated_content).to match(
        %r{isServer: false, // intentional: no trailing comma\n\s+clientReferences: rscClientReferences,}
      )
    end

    it "does not treat function-scoped path module bindings as top-level setup blockers" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const resolve = require('path');
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).to include("const { resolve } = require('path');")
      expect(migrated_content).to include("const resolve = require('path');")
      expect(migrated_content).to include("directory: resolve(config.source_path)")
      expect(migrated_content).to include(
        "new RSCWebpackPlugin({ isServer: false, clientReferences: rscClientReferences })"
      )
    end

    it "blocks setup when an indented top-level resolve binding would conflict with the injected import" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

            const resolve = (...parts) => path.resolve(__dirname, ...parts);
          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).to include("  const resolve = (...parts) => path.resolve(__dirname, ...parts);")
      expect(migrated_content).not_to include("const { resolve } = require('path');")
      expect(migrated_content).not_to include("clientReferences: rscClientReferences")
      expect(migrated_content).not_to include("const rscClientReferences")
      expect(GeneratorMessages.messages.join("\n"))
        .to include("a top-level `resolve` binding already exists that would conflict")
    end

    it "does not inject client references setup into a commented client import anchor" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          /*
           * const commonWebpackConfig = require('./commonWebpackConfig');
           */
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = { plugins: [] };
            clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).not_to include("const rscClientReferences")
      expect(migrated_content).not_to include("clientReferences: rscClientReferences")
      expect(GeneratorMessages.messages.join("\n"))
        .to include("expected webpack import anchor was not found")
    end

    it "explains that backtick require anchors must be migrated manually" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const commonWebpackConfig = require(`./commonWebpackConfig`);
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).not_to include("const rscClientReferences")
      expect(migrated_content).not_to include("clientReferences: rscClientReferences")
      expect(GeneratorMessages.messages.join("\n"))
        .to include("backtick template-literal require paths")
    end

    it "explains that rspack-only server anchors must be migrated manually" do
      config_path = "config/webpack/serverWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const { config } = require('shakapacker');
          const bundler = require('@rspack/core');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureServer = () => {
            const serverWebpackConfig = { plugins: [] };
            serverWebpackConfig.plugins.push(new RSCWebpackPlugin({ isServer: true }));

            return serverWebpackConfig;
          };

          module.exports = configureServer;
        JS
      )

      content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: true)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).not_to include("const rscClientReferences")
      expect(migrated_content).not_to include("clientReferences: rscClientReferences")
      expect(GeneratorMessages.messages.join("\n"))
        .to include("Rspack-only server configs without the webpack fallback ternary")
    end

    it "does not treat a stale generated client references helper as scoped" do
      content = <<~JS
        const rscClientReferences = { directory: '.' };
        clientConfig.plugins.push(
          new RSCWebpackPlugin({
            isServer: false,
            clientReferences: rscClientReferences,
          }),
        );
      JS

      expect(generator.send(:rsc_plugin_uses_scoped_client_references?, content, is_server: false)).to be(false)
    end

    it "does not treat a legacy broad helper as already manifest-backed" do
      content = <<~JS
        const { config } = require('shakapacker');
        const { resolve } = require('path');
        const rscClientReferences = {
          directory: resolve(config.source_path),
          recursive: true,
          include: /\\.(js|ts|jsx|tsx)$/,
        };
        serverWebpackConfig.plugins.push(
          new RSCWebpackPlugin({
            isServer: true,
            clientReferences: rscClientReferences,
          }),
        );
      JS

      expect(generator.send(:rsc_plugin_uses_scoped_client_references?, content, is_server: true)).to be(false)
      expect(generator.send(:scoped_rsc_client_references_defined?, content)).to be(true)
    end

    it "does not treat a fallback-only IIFE as manifest-backed" do
      content = <<~JS
        const { config } = require('shakapacker');
        const { resolve } = require('path');
        const fallbackRscClientReferences = {
          directory: resolve(config.source_path),
          recursive: true,
          include: /\\.(js|ts|jsx|tsx)$/,
        };
        const rscClientReferences = (() => {
          const migrationNote = `
            const defaultRefsJson = resolve('ssr-generated/rsc-client-references.json');
            const readManifestReferences = (refsJson) => refsJson;
            return readManifestReferences(defaultRefsJson);
          `;
          return [fallbackRscClientReferences];
        })();
        serverWebpackConfig.plugins.push(
          new RSCWebpackPlugin({
            isServer: true,
            clientReferences: rscClientReferences,
          }),
        );
      JS

      expect(generator.send(:rsc_plugin_uses_scoped_client_references?, content, is_server: true)).to be(false)
    end

    it "does not treat a direct fallback array as manifest-backed" do
      content = <<~JS
        const { config } = require('shakapacker');
        const { resolve } = require('path');
        const fallbackRscClientReferences = {
          directory: resolve(config.source_path),
          recursive: true,
          include: /\\.(js|ts|jsx|tsx)$/,
        };
        const rscClientReferences = [fallbackRscClientReferences];
        clientConfig.plugins.push(
          new RSCWebpackPlugin({
            isServer: false,
            clientReferences: rscClientReferences,
          }),
        );
      JS

      expect(generator.send(:generated_rsc_client_references_defined?, content)).to be(false)
      expect(generator.send(:rsc_plugin_uses_scoped_client_references?, content, is_server: false)).to be(false)
    end

    it "recognizes the exact generated resolver as manifest-backed" do
      resolver = generator.send(:rsc_client_references_js)

      expect(generator.send(:generated_rsc_client_references_defined?, resolver)).to be(true)
    end

    it "recognizes the generated resolver after a formatter adds a trailing argument comma" do
      resolver = generator.send(:rsc_client_references_js).sub(
        "resolve('ssr-generated/rsc-client-references.json')",
        "resolve(\n    'ssr-generated/rsc-client-references.json',\n  )"
      )

      expect(generator.send(:generated_rsc_client_references_defined?, resolver)).to be(true)
    end

    it "runs the exact generated resolver in ESM with the documented compatibility shim" do
      resolver = generator.send(:rsc_client_references_js)
      esm_config = <<~JS
        import { createRequire } from 'node:module';
        import { dirname, resolve } from 'node:path';
        import { fileURLToPath } from 'node:url';

        const require = createRequire(import.meta.url);
        const __dirname = dirname(fileURLToPath(import.meta.url));
        const config = { source_path: '.', source_entry_path: '.' };

        #{resolver}

        if (!Array.isArray(rscClientReferences)) throw new Error('Expected an array of client references');
      JS

      Tempfile.create(["rsc-client-references", ".mjs"]) do |file|
        file.write(esm_config)
        file.flush
        _stdout, stderr, status = Open3.capture3("node", file.path)

        expect(status.success?).to be(true), stderr
      end
    end

    it "detects scoped client references when resolve has inner whitespace" do
      content = <<~JS
        const rscClientReferences = {
          directory: resolve( config.source_path ),
        };
      JS

      expect(generator.send(:scoped_rsc_client_references_defined?, content)).to be(true)
    end

    it "detects scoped client references when the directory key follows regex values with braces" do
      content = <<~JS
        const rscClientReferences = {
          include: /component\\.(js|jsx){1,2}$/,
          directory: resolve(config.source_path),
        };
      JS

      expect(generator.send(:scoped_rsc_client_references_defined?, content)).to be(true)
    end

    it "ignores a function-scoped rscClientReferences declaration" do
      content = <<~JS
        function buildServerConfig() {
          const rscClientReferences = {
            directory: resolve(config.source_path),
            recursive: true,
            include: /\\.(js|ts|jsx|tsx)$/,
          };
          return rscClientReferences;
        }
      JS

      expect(generator.send(:rsc_client_references_defined?, content)).to be(false)
      expect(generator.send(:scoped_rsc_client_references_defined?, content)).to be(false)
    end

    it "does not treat a manifest-named fallback-only helper as generated" do
      content = <<~JS
        const fallbackRscClientReferences = {
          directory: resolve(config.source_path),
          recursive: true,
          include: /.(js|ts|jsx|tsx)$/,
        };

        const rscClientReferences = (() => {
          const configuredRefsJson = process.env.RSC_MANIFEST_CLIENT_REFERENCES_JSON;
          const refsJson = configuredRefsJson || resolve('ssr-generated/rsc-client-references.json');
          return fallbackRscClientReferences;
        })();
      JS

      expect(generator.send(:rsc_client_references_defined?, content)).to be(true)
      expect(generator.send(:scoped_rsc_client_references_defined?, content)).to be(false)
    end

    it "does not treat renamed manifest markers without manifest reading as generated" do
      content = <<~JS
        const fallbackRscClientReferences = {
          directory: resolve(config.source_path),
          recursive: true,
          include: /.(js|ts|jsx|tsx)$/,
        };

        const rscClientReferences = (() => {
          const configuredRefsJson = process.env.SOME_RENAMED_ENV_VAR;
          const refsJson = configuredRefsJson || resolve('ssr-generated/renamed-refs.json');
          return fallbackRscClientReferences;
        })();
      JS

      expect(generator.send(:scoped_rsc_client_references_defined?, content)).to be(false)
    end

    it "does not detect a fully commented-out generated manifest block" do
      content = <<~JS
        // const fallbackRscClientReferences = {
        //   directory: resolve(config.source_path),
        // };
        //
        // const rscClientReferences = (() => {
        //   return fallbackRscClientReferences;
        // })();
      JS

      expect(generator.send(:rsc_client_references_defined?, content)).to be(false)
      expect(generator.send(:scoped_rsc_client_references_defined?, content)).to be(false)
    end

    it "detects a module-scope let rscClientReferences declaration" do
      content = <<~JS
        let rscClientReferences = {
          directory: resolve(config.source_path),
          recursive: true,
          include: /\\.(js|ts|jsx|tsx)$/,
        };
      JS

      expect(generator.send(:rsc_client_references_defined?, content)).to be(true)
      expect(generator.send(:scoped_rsc_client_references_defined?, content)).to be(true)
    end

    it "detects a module-scope var rscClientReferences declaration" do
      content = <<~JS
        var rscClientReferences = {
          directory: resolve(config.source_path),
        };
      JS

      expect(generator.send(:rsc_client_references_defined?, content)).to be(true)
    end

    it "does not skip migration when only a commented-out directory key matches the scoped pattern" do
      content = <<~JS
        const rscClientReferences = {
          // directory: resolve(config.source_path),
          directory: './app/javascript',
        };
      JS

      expect(generator.send(:rsc_client_references_defined?, content)).to be(true)
      expect(generator.send(:scoped_rsc_client_references_defined?, content)).to be(false)
    end

    it "treats a plugin invocation without parseable isServer options as out-of-scope" do
      content = <<~JS
        const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
        clientConfig.plugins.push(new RSCWebpackPlugin(buildOptions()));
      JS

      expect(generator.send(:rsc_plugin_client_references_configured?, content, is_server: false)).to be(true)
    end

    it "requires the generated resolver for a parseable plugin with custom client references" do
      content = <<~JS
        const customClientReferences = { directory: './custom' };
        clientConfig.plugins.push(
          new RSCWebpackPlugin({
            isServer: false,
            clientReferences: customClientReferences,
          }),
        );
      JS

      expect(generator.send(:rsc_plugin_client_references_configured?, content, is_server: false)).to be(false)
    end

    it "requires every parseable plugin to use the generated resolver" do
      content = <<~JS
        const fallbackRscClientReferences = {
          directory: resolve(config.source_path),
        };
        const rscClientReferences = (() => [fallbackRscClientReferences])();
        clientConfig.plugins.push(
          new RSCWebpackPlugin({ isServer: false, clientReferences: rscClientReferences }),
        );
        clientConfig.plugins.push(
          new RSCWebpackPlugin({ isServer: false, clientReferences: customClientReferences }),
        );
      JS

      expect(generator.send(:rsc_plugin_client_references_configured?, content, is_server: false)).to be(false)
    end

    it "counts active non-object-literal plugin options without counting comments or object options" do
      content = <<~JS
        const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
        // clientConfig.plugins.push(new RSCWebpackPlugin(buildCommentedOptions()));
        clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));
        clientConfig.plugins.push(new RSCWebpackPlugin());
        clientConfig.plugins.push(new RSCWebpackPlugin(buildOptions()));
        clientConfig.plugins.push(new RSCWebpackPlugin("literalOptions"));
        clientConfig.plugins.push(new RSCWebpackPlugin(`templateOptions`));
      JS

      expect(generator.send(:non_object_literal_rsc_plugin_invocation_count, content)).to eq(3)
    end

    it "warns during verification when client plugin options are not object literals" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          clientConfig.plugins.push(new RSCWebpackPlugin(buildOptions()));
        JS
      )

      expect(generator.send(:check_rsc_client_config)).to eq([])

      messages = GeneratorMessages.messages.join("\n")
      expect(messages).to include("use non-object-literal options")
      expect(messages).to include("cannot verify whether the generated manifest-backed resolver is configured")
      expect(messages).not_to include("generated manifest-backed clientReferences resolver in clientWebpackConfig.js")
    end

    it "warns only once without naming only the first config when both webpack configs use non-object options" do
      simulate_existing_file(
        "config/webpack/serverWebpackConfig.js",
        <<~JS
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          const rscBundle = false;
          serverWebpackConfig.plugins.push(new RSCWebpackPlugin(serverPluginOptions()));
        JS
      )
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        <<~JS
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          clientConfig.plugins.push(new RSCWebpackPlugin(clientPluginOptions()));
        JS
      )

      generator.send(:check_rsc_server_config)
      generator.send(:check_rsc_client_config)

      non_object_warnings = GeneratorMessages.messages.grep(/use non-object-literal options/)
      expect(non_object_warnings.length).to eq(1)
      expect(non_object_warnings.first).to include("one or more bundler configs")
      expect(non_object_warnings.first).not_to include("serverWebpackConfig.js")
      expect(non_object_warnings.first).not_to include("clientWebpackConfig.js")
    end

    it "does not warn during verification for object options or commented-out non-object plugin calls" do
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        <<~JS
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          // clientConfig.plugins.push(new RSCWebpackPlugin(buildOptions()));
          clientConfig.plugins.push(new RSCWebpackPlugin({
            isServer: false,
            clientReferences,
          }));
        JS
      )

      generator.send(:check_rsc_client_config)

      expect(GeneratorMessages.messages.join("\n")).not_to include("use non-object-literal options")
    end

    it "treats shorthand clientReferences as a top-level configured option" do
      body = <<~JS
        isServer: false,
        clientReferences,
      JS

      expect(generator.send(:rsc_plugin_body_has_top_level_key?, body, "clientReferences")).to be(true)
    end

    it "treats quoted clientReferences as a top-level configured option" do
      body = <<~JS
        isServer: false,
        "clientReferences": customClientReferences,
      JS

      expect(generator.send(:rsc_plugin_body_has_top_level_key?, body, "clientReferences")).to be(true)
    end

    it "does not treat a top-level value reference as a configured clientReferences option" do
      body = <<~JS
        isServer: false,
        metadata: clientReferences,
      JS

      expect(generator.send(:rsc_plugin_body_has_top_level_key?, body, "clientReferences")).to be(false)
    end

    it "detects quoted scoped clientReferences as already configured" do
      body = <<~JS
        isServer: false,
        "clientReferences": rscClientReferences,
      JS

      expect(generator.send(:rsc_plugin_body_has_top_level_scoped_client_references?, body)).to be(true)
    end

    it "detects scoped clientReferences when comments separate the key from its value" do
      bodies = [
        <<~JS,
          isServer: false,
          clientReferences: /* preserve the graph-derived resolver */ rscClientReferences,
        JS
        <<~JS
          isServer: false,
          "clientReferences": // preserve the graph-derived resolver
            rscClientReferences,
        JS
      ]

      expect(bodies).to all(satisfy do |body|
        generator.send(:rsc_plugin_body_has_top_level_scoped_client_references?, body)
      end)
    end

    it "does not treat commented-out or nested scoped clientReferences as top-level configuration" do
      bodies = [
        <<~JS,
          isServer: false,
          // clientReferences: rscClientReferences,
        JS
        <<~JS
          isServer: false,
          metadata: {
            clientReferences: /* nested */ rscClientReferences,
          },
        JS
      ]

      expect(bodies).to all(satisfy do |body|
        !generator.send(:rsc_plugin_body_has_top_level_scoped_client_references?, body)
      end)
    end

    it "matches the server setup anchor with CRLF line endings" do
      content = [
        "const bundler = config.assets_bundler === 'rspack'",
        "  ? require('@rspack/core')",
        "  : require('webpack');"
      ].join("\r\n")

      expect(generator.send(:rsc_client_references_setup_anchor?, content, is_server: true)).to be(true)
    end

    it "matches the server setup anchor with comments around the bundler ternary" do
      content = <<~JS
        const bundler = config.assets_bundler /* generated by Shakapacker */ === 'rspack'
          // Rspack is selected by app config.
          ? require('@rspack/core')
          /* Keep webpack as the fallback for non-Rspack apps. */
          : require('webpack');
      JS

      expect(generator.send(:rsc_client_references_setup_anchor?, content, is_server: true)).to be(true)
    end

    it "matches the client setup anchor with CRLF line endings" do
      content = [
        "const commonWebpackConfig = require('./commonWebpackConfig');",
        "const next = 1;"
      ].join("\r\n")

      expect(generator.send(:rsc_client_references_setup_anchor?, content, is_server: false)).to be(true)
    end

    it "preserves CRLF line endings when injecting and rewriting scoped client references" do
      config_path = "config/webpack/clientWebpackConfig.js"
      crlf_content = [
        "const commonWebpackConfig = require('./commonWebpackConfig');",
        "const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');",
        "",
        "const configureClient = () => {",
        "  const clientConfig = commonWebpackConfig();",
        "  clientConfig.plugins.push(",
        "    new RSCWebpackPlugin({",
        "      isServer: false,",
        "    }),",
        "  );",
        "",
        "  return clientConfig;",
        "};",
        "",
        "module.exports = configureClient;"
      ].join("\r\n")

      simulate_existing_file(
        config_path,
        "#{crlf_content}\r\n"
      )

      content = File.binread(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: false)

      migrated_content = File.binread(File.join(destination_root, config_path))
      expect(migrated_content).to include("const fallbackRscClientReferences = {\r\n")
      expect(migrated_content).to include("const rscClientReferences = (() => {\r\n")
      expect(migrated_content).to include("      isServer: false,\r\n      clientReferences: rscClientReferences,")
      expect(migrated_content).not_to match(/(?<!\r)\n/)
    end

    it "detects named imports with trailing commas" do
      content = "const { config, } = require('shakapacker');"

      expect(generator.send(:commonjs_named_imported?, content, "shakapacker", "config")).to be(true)
    end

    it "detects named imports with leading indentation" do
      shakapacker_content = "  const { config, } = require('shakapacker');"
      path_content = "\tlet { resolve } = require('path');"

      expect(generator.send(:commonjs_named_imported?, shakapacker_content, "shakapacker", "config"))
        .to be(true)
      expect(generator.send(:commonjs_named_imported?, path_content, "path", "resolve"))
        .to be(true)
    end

    it "detects named imports when destructuring comments contain braces" do
      content = <<~JS
        const {
          /* kept for docs: } */
          config,
        } = require('shakapacker');
      JS

      expect(generator.send(:commonjs_named_imported?, content, "shakapacker", "config"))
        .to be(true)
    end

    it "detects named imports with defaults and self aliases" do
      default_without_space = "const { config=fallbackConfig } = require('shakapacker');"
      self_aliased_config = "const { config: config } = require('shakapacker');"
      self_aliased_resolve = "const { resolve: resolve } = require('path');"

      expect(generator.send(:commonjs_named_imported?, default_without_space, "shakapacker", "config"))
        .to be(true)
      expect(generator.send(:commonjs_named_imported?, self_aliased_config, "shakapacker", "config"))
        .to be(true)
      expect(generator.send(:commonjs_named_imported?, self_aliased_resolve, "path", "resolve"))
        .to be(true)
    end

    it "does not treat renamed aliases as the exact binding used by rscClientReferences" do
      aliased_config = "const { config: shakapackerConfig } = require('shakapacker');"
      aliased_resolve = "const { resolve: pathResolve } = require('path');"

      expect(generator.send(:commonjs_named_imported?, aliased_config, "shakapacker", "config"))
        .to be(false)
      expect(generator.send(:commonjs_named_imported?, aliased_resolve, "path", "resolve"))
        .to be(false)
    end

    it "detects legacy let or var dot-access shakapacker config imports" do
      expect(generator.send(:shakapacker_config_imported?, "let config = require('shakapacker').config;"))
        .to be(true)
      expect(generator.send(:shakapacker_config_imported?, "var config = require('shakapacker').config;"))
        .to be(true)
      expect(generator.send(:shakapacker_config_imported?, "  const config = require('shakapacker').config;"))
        .to be(true)
    end

    it "detects legacy let or var dot-access path resolve imports" do
      expect(generator.send(:path_resolve_imported?, "let resolve = require('path').resolve;"))
        .to be(true)
      expect(generator.send(:path_resolve_imported?, "var resolve = require('path').resolve;"))
        .to be(true)
      expect(generator.send(:path_resolve_imported?, "  const resolve = require('path').resolve;"))
        .to be(true)
    end

    it "treats function-scoped shakapacker config imports as not module-scope" do
      function_scoped = <<~JS
        function getShakapackerConfig() {
          const { config } = require('shakapacker');
          return config;
        }
      JS
      dot_access_scoped = <<~JS
        function getShakapackerConfig() {
          const config = require('shakapacker').config;
          return config;
        }
      JS

      expect(generator.send(:shakapacker_config_imported?, function_scoped)).to be(false)
      expect(generator.send(:shakapacker_config_imported?, dot_access_scoped)).to be(false)
    end

    it "treats function-scoped path resolve imports as not module-scope" do
      function_scoped = <<~JS
        function helper() {
          const { resolve } = require('path');
          return resolve('a', 'b');
        }
      JS
      dot_access_scoped = <<~JS
        function helper() {
          const resolve = require('path').resolve;
          return resolve('a', 'b');
        }
      JS

      expect(generator.send(:path_resolve_imported?, function_scoped)).to be(false)
      expect(generator.send(:path_resolve_imported?, dot_access_scoped)).to be(false)
    end

    it "detects top-level imports after regex literals with braces" do
      content = <<~JS
        const literalOpenBrace = /\\{/;
        const { resolve } = require('path');
        const { config } = require('shakapacker');
      JS

      expect(generator.send(:path_resolve_imported?, content)).to be(true)
      expect(generator.send(:shakapacker_config_imported?, content)).to be(true)
    end

    it "detects top-level imports after regex literals preceded by block comments" do
      content = <<~JS
        const literalOpenBrace = /* comment */ /\\{/;
        const { resolve } = require('path');
        const { config } = require('shakapacker');
      JS

      expect(generator.send(:path_resolve_imported?, content)).to be(true)
      expect(generator.send(:shakapacker_config_imported?, content)).to be(true)
    end

    it "does not detect imports after an unterminated regex literal" do
      content = <<~JS
        const invalidRegex = /abc
        const { resolve } = require('path');
      JS

      expect(generator.send(:path_resolve_imported?, content)).to be(false)
    end

    it "detects top-level destructuring that creates config or resolve bindings" do
      config_content = "const { config } = require('custom-package');"
      resolve_content = "const { resolve: resolve } = require('custom-paths');"

      expect(generator.send(:top_level_config_binding?, config_content)).to be(true)
      expect(generator.send(:top_level_resolve_binding?, resolve_content)).to be(true)
    end

    it "detects top-level class declarations that create config or resolve bindings" do
      expect(generator.send(:top_level_config_binding?, "class config {}")).to be(true)
      expect(generator.send(:top_level_resolve_binding?, "  class resolve extends BaseResolve {}")).to be(true)
    end

    it "ignores top-level destructuring that renames config or resolve bindings" do
      config_content = "const { config: customConfig } = require('custom-package');"
      resolve_content = "const { resolve: customResolve } = require('custom-paths');"

      expect(generator.send(:top_level_config_binding?, config_content)).to be(false)
      expect(generator.send(:top_level_resolve_binding?, resolve_content)).to be(false)
    end

    it "preserves URL-like substrings inside string options when stripping comments" do
      options = "isServer: false, namespace: 'https://example.com/rsc', label: \"http://b//c\""

      stripped = generator.send(:rsc_plugin_options_without_comments, options)

      expect(stripped).to include("'https://example.com/rsc'")
      expect(stripped).to include("\"http://b//c\"")
    end

    it "still strips line and block comments outside string literals" do
      options = "isServer: true, // a comment\n  /* block */ chunkName: 'main'"

      stripped = generator.send(:rsc_plugin_options_without_comments, options)

      expect(stripped).not_to include("a comment")
      expect(stripped).not_to include("block")
      expect(stripped).to include("isServer: true,")
      expect(stripped).to include("chunkName: 'main'")
    end

    it "treats normal RSCWebpackPlugin invocations as parseable" do
      content = <<~JS
        new RSCWebpackPlugin({
          isServer: true,
          include: /\\.(js|jsx){1,3}$/,
        });
      JS

      partition = generator.send(:rsc_plugin_option_sections_partition, content, is_server: true)
      expect(partition.fetch(:safe).length).to eq(1)
      expect(partition.fetch(:unparseable)).to eq(0)
    end

    it "flags plugin invocations whose options block was scanned past the wrong closing brace" do
      # The unmatched `}` inside the regex literal causes the depth scanner to return early,
      # so the `}` it picks is not followed by `)` — `rsc_plugin_options_followed_by_close_paren?`
      # detects the mismatch and the section is counted as unparseable rather than rewritten.
      content = <<~JS
        new RSCWebpackPlugin({
          isServer: true,
          include: /\\}/,
        });
      JS

      partition = generator.send(:rsc_plugin_option_sections_partition, content, is_server: true)
      expect(partition.fetch(:safe).length).to eq(0)
      expect(partition.fetch(:unparseable)).to eq(1)
    end

    it "treats a block comment between the options object and `)` as parseable" do
      # `advance_js_block_comment_state` exits with state=nil and index pointing at the
      # closing `/` of `*/`. Without skipping that consumed character, the scanner would
      # falsely flag this invocation as unparseable.
      content = "new RSCWebpackPlugin({ isServer: true } /* keep me */ );\n"

      partition = generator.send(:rsc_plugin_option_sections_partition, content, is_server: true)
      expect(partition.fetch(:safe).length).to eq(1)
      expect(partition.fetch(:unparseable)).to eq(0)
    end

    it "treats a trailing comma between the options object and `)` as parseable" do
      # Prettier's `trailingComma: "all"` emits `new RSCWebpackPlugin({...},)`. Without
      # tolerating the single trailing comma the scanner would mark these as unparseable
      # and the user's migration would silently bail.
      content = "new RSCWebpackPlugin({ isServer: true },);\n"

      partition = generator.send(:rsc_plugin_option_sections_partition, content, is_server: true)
      expect(partition.fetch(:safe).length).to eq(1)
      expect(partition.fetch(:unparseable)).to eq(0)
    end

    it "skips leading string literals when looking for the first significant token" do
      content = %(  "client-bundle", { isServer: false })

      index = generator.send(:first_significant_js_index, content, 0)
      expect(content[index]).to eq(",")
    end

    it "clears state but leaves index on the closing `/` when advance_js_scan_state exits a block comment" do
      # `block_comment_exit_guard` invariant: when `*/` is consumed, state must be nil and
      # index must point at the closing `/` so the caller's trailing `index += 1` lands on
      # the first character after the comment. Several callers (`matching_js_closing_brace`,
      # `js_code_position?`, `js_top_level_position?`) rely on this without an explicit
      # `prev_state == :block_comment` guard, so a regression here would silently misroute
      # downstream `char == '{' / '}' / ')'` checks.
      content = "/* x */next"
      state = :block_comment
      escaped = false
      # Advance to the `*` of `*/` so `char == '*'` and `next_char == '/'`.
      slash_index = content.index("*/") + 1
      next_state, _next_escaped, returned_index =
        generator.send(:advance_js_scan_state, state, escaped, "*", "/", slash_index - 1)

      expect(next_state).to be_nil
      expect(returned_index).to eq(slash_index)
      expect(content[returned_index]).to eq("/")
      expect(content[returned_index + 1]).to eq("n")
    end

    it "warns and skips the rewrite when an RSCWebpackPlugin options block is unparseable" do
      config_path = "config/webpack/serverWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const { config } = require('shakapacker');
          const bundler = config.assets_bundler === 'rspack'
            ? require('@rspack/core')
            : require('webpack');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          serverWebpackConfig.plugins.push(
            new RSCWebpackPlugin({
              isServer: true,
              include: /\\}/,
            }),
          );
        JS
      )
      content = File.read(File.join(destination_root, config_path))

      expect(generator.send(:rsc_plugin_sections_safe_to_rewrite?, config_path, content, is_server: true))
        .to be(false)

      messages = GeneratorMessages.messages.join("\n")
      expect(messages).to include(config_path)
      expect(messages).to include("cannot parse safely")
      expect(messages).to include("regex literal with an unmatched")
      expect(messages).not_to include("isServer: true")
    end

    it "normalizes a legacy rspack plugin before skipping an unparseable clientReferences rewrite" do
      allow(generator).to receive(:using_rspack?).and_return(true)
      config_path = "config/rspack/serverWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const { config } = require('shakapacker');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          serverWebpackConfig.plugins.push(
            new RSCWebpackPlugin({
              isServer: true,
              include: /\\}/,
            }),
          );
        JS
      )
      content = File.read(File.join(destination_root, config_path))

      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: true)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).to include(
        "const { RSCRspackPlugin } = require('react-on-rails-rsc/RspackPlugin');"
      )
      expect(migrated_content).to include("new RSCRspackPlugin({")
      expect(migrated_content).not_to include("RSCWebpackPlugin")
      expect(migrated_content).not_to include("clientReferences: rscClientReferences")

      messages = GeneratorMessages.messages.join("\n")
      expect(messages).to include(config_path)
      expect(messages).to include("cannot parse safely")
    end

    it "flags plugin invocations whose options block cannot find a closing brace" do
      content = <<~JS
        new RSCWebpackPlugin({
          isServer: true,
          include: /\\{/,
        });
      JS

      partition = generator.send(:rsc_plugin_option_sections_partition, content, is_server: true)
      expect(partition.fetch(:safe).length).to eq(0)
      expect(partition.fetch(:unparseable)).to eq(1)
    end

    it "does not bucket a section by a nested isServer value into the wrong partition" do
      # `metadata: { isServer: true }` must not route this section into the `is_server: true`
      # bucket; only the top-level `isServer: false` should match the `is_server: false` bucket.
      # Without depth-aware matching, the `is_server: true` partition would falsely include this
      # section, the rewrite would correctly bail (the splice helper IS depth-aware), and the
      # user would see a misleading "no plugin options with isServer: true could be rewritten"
      # warning for a config that is actually fine.
      content = <<~JS
        new RSCWebpackPlugin({
          metadata: { isServer: true },
          isServer: false,
        });
      JS

      true_partition = generator.send(:rsc_plugin_option_sections_partition, content, is_server: true)
      false_partition = generator.send(:rsc_plugin_option_sections_partition, content, is_server: false)

      expect(true_partition.fetch(:safe).length).to eq(0)
      expect(false_partition.fetch(:safe).length).to eq(1)
    end

    it "keeps the client references rewrite predicate free of file writes" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(
              new RSCWebpackPlugin({
                isServer: false,
                clientReferences: rscClientReferences,
              }),
            );

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      full_path = File.join(destination_root, config_path)
      content = File.read(full_path)

      expect(generator.send(:rsc_plugin_needs_client_references_rewrite?, content, is_server: false))
        .to be(false)
      expect(File.read(full_path)).to eq(content)
    end

    it "returns true from the client references rewrite predicate without file writes" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));
        JS
      )

      full_path = File.join(destination_root, config_path)
      content = File.read(full_path)

      expect(generator.send(:rsc_plugin_needs_client_references_rewrite?, content, is_server: false))
        .to be(true)
      expect(File.read(full_path)).to eq(content)
    end

    it "does not inject duplicate imports for legacy let or var CommonJS destructuring" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          var { config } = require('shakapacker');
          let { resolve } = require('path');
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).to include("var { config } = require('shakapacker');")
      expect(migrated_content).to include("let { resolve } = require('path');")
      expect(migrated_content).not_to include("const { config } = require('shakapacker');")
      expect(migrated_content).not_to include("const { resolve } = require('path');")
      expect(migrated_content).to include("directory: resolve(config.source_path)")
      expect(migrated_content).to include(
        "new RSCWebpackPlugin({ isServer: false, clientReferences: rscClientReferences })"
      )
    end

    it "normalizes a legacy webpack plugin import and invocation when updating an rspack client config" do
      allow(generator).to receive(:using_rspack?).and_return(true)
      config_path = "config/rspack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).to include(
        "const { RSCRspackPlugin } = require('react-on-rails-rsc/RspackPlugin');"
      )
      expect(migrated_content).to include(
        "new RSCRspackPlugin({ isServer: false, clientReferences: rscClientReferences })"
      )
      expect(migrated_content).not_to include("RSCWebpackPlugin")
      expect(migrated_content).not_to include("react-on-rails-rsc/WebpackPlugin")
    end

    it "removes a stale legacy import when an rspack config already has the native import" do
      allow(generator).to receive(:using_rspack?).and_return(true)
      config_path = "config/rspack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCRspackPlugin } = require('react-on-rails-rsc/RspackPlugin');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content.scan("react-on-rails-rsc/RspackPlugin").length).to eq(1)
      expect(migrated_content).to include(
        "new RSCRspackPlugin({ isServer: false, clientReferences: rscClientReferences })"
      )
      expect(migrated_content).not_to include("RSCWebpackPlugin")
      expect(migrated_content).not_to include("react-on-rails-rsc/WebpackPlugin")
    end

    it "preserves declaration order when the native rspack import appears after the legacy import" do
      allow(generator).to receive(:using_rspack?).and_return(true)
      config_path = "config/rspack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));

            return clientConfig;
          };

          const { RSCRspackPlugin } = require('react-on-rails-rsc/RspackPlugin');

          module.exports = configureClient;
        JS
      )

      content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      native_import = "const { RSCRspackPlugin } = require('react-on-rails-rsc/RspackPlugin');"
      expect(migrated_content.scan("react-on-rails-rsc/RspackPlugin").length).to eq(1)
      expect(migrated_content.index(native_import)).to be < migrated_content.index("const configureClient = ()")
      expect(migrated_content).to include(
        "new RSCRspackPlugin({ isServer: false, clientReferences: rscClientReferences })"
      )
      expect(migrated_content).not_to include("RSCWebpackPlugin")
      expect(migrated_content).not_to include("react-on-rails-rsc/WebpackPlugin")
    end

    it "does not rename a legacy plugin invocation when the import form cannot be normalized" do
      allow(generator).to receive(:using_rspack?).and_return(true)
      config_path = "config/rspack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          import { RSCWebpackPlugin } from 'react-on-rails-rsc/WebpackPlugin';
          const commonWebpackConfig = require('./commonWebpackConfig');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).to include("import { RSCWebpackPlugin } from 'react-on-rails-rsc/WebpackPlugin';")
      expect(migrated_content).to include(
        "new RSCWebpackPlugin({ isServer: false, clientReferences: rscClientReferences })"
      )
      expect(migrated_content).not_to include("RSCRspackPlugin")
      expect(migrated_content).not_to include("react-on-rails-rsc/RspackPlugin")

      messages = GeneratorMessages.messages.join("\n")
      expect(messages).to include("ESM syntax")
      expect(messages).to include("const { RSCRspackPlugin } = require('react-on-rails-rsc/RspackPlugin');")
    end

    it "ignores commented legacy plugin imports when deciding whether an rspack binding exists" do
      allow(generator).to receive(:using_rspack?).and_return(true)
      config_path = "config/rspack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          import { RSCWebpackPlugin } from 'react-on-rails-rsc/WebpackPlugin';
          const commonWebpackConfig = require('./commonWebpackConfig');

          /*
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          */

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).to include("import { RSCWebpackPlugin } from 'react-on-rails-rsc/WebpackPlugin';")
      expect(migrated_content).to include(
        "new RSCWebpackPlugin({ isServer: false, clientReferences: rscClientReferences })"
      )
      expect(migrated_content).not_to include("RSCRspackPlugin")
      expect(migrated_content).not_to include("react-on-rails-rsc/RspackPlugin")
    end

    it "normalizes a legacy webpack plugin import and invocation when updating an rspack server config" do
      allow(generator).to receive(:using_rspack?).and_return(true)
      config_path = "config/rspack/serverWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const { config } = require('shakapacker');
          const bundler = config.assets_bundler === 'rspack'
            ? require('@rspack/core')
            : require('webpack');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureServer = (rscBundle = false) => {
            if (!rscBundle) {
              serverWebpackConfig.plugins.push(new RSCWebpackPlugin({ isServer: true }));
            }

            return serverWebpackConfig;
          };

          module.exports = configureServer;
        JS
      )

      content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: true)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).to include(
        "const { RSCRspackPlugin } = require('react-on-rails-rsc/RspackPlugin');"
      )
      expect(migrated_content).to include(
        "new RSCRspackPlugin({ isServer: true, clientReferences: rscClientReferences })"
      )
      expect(migrated_content).not_to include("RSCWebpackPlugin")
      expect(migrated_content).not_to include("react-on-rails-rsc/WebpackPlugin")
    end

    it "reports the wrong bundler plugin during rspack server-config verification instead of a bare missing warning" do
      allow(generator).to receive(:using_rspack?).and_return(true)
      simulate_existing_file(
        "config/rspack/serverWebpackConfig.js",
        <<~JS
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          const rscBundle = false;
          serverWebpackConfig.plugins.push(new RSCWebpackPlugin({ isServer: true }));
        JS
      )

      expect(generator.send(:check_rsc_server_config)).to include(
        "RSCRspackPlugin in serverWebpackConfig.js " \
        "(found RSCWebpackPlugin — wrong bundler plugin; replace it manually)"
      )
    end

    it "reports the wrong bundler plugin during rspack client-config verification instead of a bare missing warning" do
      allow(generator).to receive(:using_rspack?).and_return(true)
      simulate_existing_file(
        "config/rspack/clientWebpackConfig.js",
        <<~JS
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));
        JS
      )

      expect(generator.send(:check_rsc_client_config)).to include(
        "RSCRspackPlugin in clientWebpackConfig.js " \
        "(found RSCWebpackPlugin — wrong bundler plugin; replace it manually)"
      )
    end

    it "reports a stale inactive import when an rspack client config also has the active plugin" do
      allow(generator).to receive(:using_rspack?).and_return(true)
      simulate_existing_file(
        "config/rspack/clientWebpackConfig.js",
        <<~JS
          const { config } = require('shakapacker');
          const { resolve } = require('path');
          const { RSCRspackPlugin } = require('react-on-rails-rsc/RspackPlugin');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          const rscClientReferences = { directory: resolve(config.source_path) };
          clientConfig.plugins.push(
            new RSCRspackPlugin({ isServer: false, clientReferences: rscClientReferences }),
          );
        JS
      )

      expect(generator.send(:check_rsc_client_config)).to include(
        "stale RSCWebpackPlugin in clientWebpackConfig.js " \
        "(found alongside RSCRspackPlugin — remove the inactive bundler plugin manually)"
      )
    end

    it "reports a stale inactive invocation when an rspack server config also has the active plugin" do
      allow(generator).to receive(:using_rspack?).and_return(true)
      simulate_existing_file(
        "config/rspack/serverWebpackConfig.js",
        <<~JS
          const { config } = require('shakapacker');
          const { resolve } = require('path');
          const { RSCRspackPlugin } = require('react-on-rails-rsc/RspackPlugin');
          const rscClientReferences = { directory: resolve(config.source_path) };
          const rscBundle = false;
          serverWebpackConfig.plugins.push(
            new RSCRspackPlugin({ isServer: true, clientReferences: rscClientReferences }),
          );
          serverWebpackConfig.plugins.push(new RSCWebpackPlugin({ isServer: true }));
        JS
      )

      expect(generator.send(:check_rsc_server_config)).to include(
        "stale RSCWebpackPlugin in serverWebpackConfig.js " \
        "(found alongside RSCRspackPlugin — remove the inactive bundler plugin manually)"
      )
    end

    it "ignores inactive plugin names in comments and strings during mixed-plugin verification" do
      allow(generator).to receive(:using_rspack?).and_return(true)
      simulate_existing_file(
        "config/rspack/clientWebpackConfig.js",
        <<~JS
          const { config } = require('shakapacker');
          const { resolve } = require('path');
          const { RSCRspackPlugin } = require('react-on-rails-rsc/RspackPlugin');
          const rscClientReferences = { directory: resolve(config.source_path) };
          // Previous import: const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          const migrationNote = "new RSCWebpackPlugin({ isServer: false })";
          clientConfig.plugins.push(
            new RSCRspackPlugin({ isServer: false, clientReferences: rscClientReferences }),
          );
        JS
      )

      expect(generator.send(:check_rsc_client_config)).to include(
        "generated manifest-backed clientReferences resolver in clientWebpackConfig.js"
      )
    end

    it "does not inject duplicate imports when existing bindings are indented" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
            const { config } = require('shakapacker');
          \tconst { resolve } = require('path');
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content.scan("const { config } = require('shakapacker');").length).to eq(1)
      expect(migrated_content.scan("const { resolve } = require('path');").length).to eq(1)
      expect(migrated_content).to include("directory: resolve(config.source_path)")
      expect(migrated_content).to include(
        "new RSCWebpackPlugin({ isServer: false, clientReferences: rscClientReferences })"
      )
    end

    it "blocks setup when a custom top-level resolve binding would conflict with the injected import" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const resolve = (...parts) => path.resolve(__dirname, ...parts);
          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).to include("const resolve = (...parts) => path.resolve(__dirname, ...parts);")
      expect(migrated_content).not_to include("const { resolve } = require('path');")
      expect(migrated_content).not_to include("clientReferences: rscClientReferences")
      expect(migrated_content).not_to include("const rscClientReferences")
      expect(GeneratorMessages.messages.join("\n"))
        .to include("a top-level `resolve` binding already exists that would conflict")
    end

    it "blocks setup when a custom top-level config binding would conflict with the injected import" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const config = { source_path: 'app/javascript' };
          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).to include("const config = { source_path: 'app/javascript' };")
      expect(migrated_content).not_to include("const { config } = require('shakapacker');")
      expect(migrated_content).not_to include("clientReferences: rscClientReferences")
      expect(migrated_content).not_to include("const rscClientReferences")
      expect(GeneratorMessages.messages.join("\n"))
        .to include("a top-level `config` binding already exists that would conflict")
    end

    it "blocks setup when a destructured top-level config binding would conflict with the injected import" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const { config } = require('custom-webpack-config');
          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, content, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).to include("const { config } = require('custom-webpack-config');")
      expect(migrated_content).not_to include("const { config } = require('shakapacker');")
      expect(migrated_content).not_to include("clientReferences: rscClientReferences")
      expect(migrated_content).not_to include("const rscClientReferences")
      expect(GeneratorMessages.messages.join("\n"))
        .to include("a top-level `config` binding already exists that would conflict")
    end

    it "logs the direct file rewrite as a generator action" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));
        JS
      )

      expect(generator).to receive(:say_status).with(:rewrite, config_path, :green)
      expect(generator.send(:rewrite_rsc_plugin_client_references, config_path, is_server: false)).to be(true)
    end

    it "places clientReferences on its own line for multi-line plugin rewrites" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          clientConfig.plugins.push(
            new RSCWebpackPlugin({
              chunkName: 'client',
              isServer: false,
            }),
          );
        JS
      )

      generator.send(:rewrite_rsc_plugin_client_references, config_path, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).to match(
        /chunkName: 'client',\n\s*isServer: false,\n\s*clientReferences: rscClientReferences,/
      )
      expect(GeneratorMessages.messages.join("\n")).not_to include("npx prettier")
    end

    it "matches indentation from the last code line when a template-literal value contains a newline" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          clientConfig.plugins.push(
            new RSCWebpackPlugin({
              isServer: false,
              message: `hello
          world`,
            }),
          );
        JS
      )

      generator.send(:rewrite_rsc_plugin_client_references, config_path, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).to include(
        "    message: `hello\nworld`,\n    clientReferences: rscClientReferences,"
      )
      expect(migrated_content).not_to include("world`,\n  clientReferences")
    end

    it "does not write plugin rewrites in pretend mode" do
      config_path = "config/webpack/clientWebpackConfig.js"
      pretend_generator = described_class.new([], { pretend: true }, { destination_root: })
      simulate_existing_file(
        config_path,
        <<~JS
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));
        JS
      )

      original_content = File.read(File.join(destination_root, config_path))
      expect(pretend_generator).to receive(:say_status)
        .with(:pretend, "Would rewrite #{config_path}", :yellow)
      expect(pretend_generator.send(:rewrite_rsc_plugin_client_references, config_path, is_server: false)).to be(true)
      expect(File.read(File.join(destination_root, config_path))).to eq(original_content)
    end

    it "does not write plugin rewrites in skip mode" do
      config_path = "config/webpack/clientWebpackConfig.js"
      skip_generator = described_class.new([], { skip: true }, { destination_root: })
      simulate_existing_file(
        config_path,
        <<~JS
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));
        JS
      )

      original_content = File.read(File.join(destination_root, config_path))
      expect(skip_generator).to receive(:say_status).with(:skip, config_path, :yellow)
      expect(skip_generator.send(:rewrite_rsc_plugin_client_references, config_path, is_server: false)).to be(true)
      expect(File.read(File.join(destination_root, config_path))).to eq(original_content)
    end

    it "continues planning later setup steps after scoped helper setup in pretend mode" do
      config_path = "config/webpack/clientWebpackConfig.js"
      pretend_generator = described_class.new([], { pretend: true }, { destination_root: })
      simulate_existing_file(
        config_path,
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      original_content = File.read(File.join(destination_root, config_path))
      expect(pretend_generator).to receive(:say_status)
        .with(:pretend, "Would inject rscClientReferences into #{config_path}", :yellow)
      expect(pretend_generator).to receive(:say_status)
        .with(:pretend, "Would rewrite #{config_path}", :yellow)
      pretend_generator.send(:update_existing_rsc_webpack_config, config_path, original_content, is_server: false)

      expect(File.read(File.join(destination_root, config_path))).to eq(original_content)
      expect(GeneratorMessages.messages.join("\n")).not_to include("generated scoped helper setup was not written")
    end

    it "rolls back helper setup when the follow-up plugin rewrite cannot be applied" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      original_content = File.read(File.join(destination_root, config_path))
      allow(generator).to receive(:rewrite_rsc_plugin_client_references)
        .with(config_path, is_server: false)
        .and_return(false)
      allow(generator).to receive(:say_status).and_call_original

      generator.send(:update_existing_rsc_webpack_config, config_path, original_content, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(generator).to have_received(:rewrite_rsc_plugin_client_references)
        .with(config_path, is_server: false)
      expect(generator).to have_received(:say_status).with(:revert, config_path, :yellow)
      expect(migrated_content).to eq(original_content)
      expect(migrated_content).not_to include("const rscClientReferences")
      expect(GeneratorMessages.messages.join("\n"))
        .to include("no plugin options with isServer: false could be rewritten")
    end

    it "does not inject scoped helper setup in skip mode" do
      config_path = "config/webpack/clientWebpackConfig.js"
      skip_generator = described_class.new([], { skip: true }, { destination_root: })
      simulate_existing_file(
        config_path,
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      original_content = File.read(File.join(destination_root, config_path))
      expect(skip_generator).to receive(:say_status).with(:skip, config_path, :yellow).twice
      skip_generator.send(:update_existing_rsc_webpack_config, config_path, original_content, is_server: false)

      expect(File.read(File.join(destination_root, config_path))).to eq(original_content)
      expect(GeneratorMessages.messages.join("\n")).not_to include("generated scoped helper setup was not written")
    end

    it "treats skipped from-scratch scoped helper setup as ready" do
      config_path = "config/webpack/clientWebpackConfig.js"
      skip_generator = described_class.new([], { skip: true }, { destination_root: })
      simulate_existing_file(config_path, base_client_webpack_content)

      expect(skip_generator.send(:rsc_client_references_setup_ready?, config_path)).to be(true)
      expect(GeneratorMessages.messages.join("\n")).not_to include("generated scoped helper setup was not written")
    end

    it "splices clientReferences at the top level when isServer also appears in a nested object" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          clientConfig.plugins.push(
            new RSCWebpackPlugin({
              metadata: {
                isServer: false,
              },
              chunkName: 'client',
              isServer: false,
            }),
          );
        JS
      )

      generator.send(:rewrite_rsc_plugin_client_references, config_path, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content.scan("clientReferences: rscClientReferences").length).to eq(1)
      # The new key must land in the top-level options object, not inside `metadata`.
      expect(migrated_content).to match(
        /chunkName: 'client',\n\s*isServer: false,\n\s*clientReferences: rscClientReferences,\n\s*\}\),/
      )
      expect(migrated_content).not_to match(/metadata: \{\n\s*isServer: false,\n\s*clientReferences:/)
    end

    it "rewrites the options object even when a JS comment sits between '(' and '{'" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          clientConfig.plugins.push(
            new RSCWebpackPlugin( /* client-side opts */ {
              isServer: false,
            }),
          );
        JS
      )

      expect(generator.send(:rewrite_rsc_plugin_client_references, config_path, is_server: false)).to be(true)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).to match(
        /isServer: false,\n\s*clientReferences: rscClientReferences,\n\s*\}\),/
      )
      expect(GeneratorMessages.messages.join("\n")).not_to include("no plugin options")
    end

    it "still rewrites when clientReferences appears only inside a nested sibling object" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          clientConfig.plugins.push(
            new RSCWebpackPlugin({
              metadata: {
                clientReferences: 'unused',
              },
              isServer: false,
            }),
          );
        JS
      )

      generator.send(:rewrite_rsc_plugin_client_references, config_path, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content).to include("clientReferences: rscClientReferences")
      # Nested mention is preserved verbatim, and a real top-level option is added.
      expect(migrated_content).to include("clientReferences: 'unused'")
      expect(migrated_content).to match(
        /isServer: false,\n\s*clientReferences: rscClientReferences,\n\s*\}\),/
      )
    end

    it "does not treat a nested clientReferences: rscClientReferences as already migrated" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(
              new RSCWebpackPlugin({
                metadata: {
                  clientReferences: rscClientReferences,
                },
                isServer: false,
              }),
            );

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      original_content = File.read(File.join(destination_root, config_path))
      generator.send(:update_existing_rsc_webpack_config, config_path, original_content, is_server: false)

      migrated_content = File.read(File.join(destination_root, config_path))
      expect(migrated_content.scan("clientReferences: rscClientReferences").length).to eq(2)
      expect(migrated_content).to match(
        /isServer: false,\n\s*clientReferences: rscClientReferences,\n\s*\}\),/
      )
    end

    it "reports a missing manifest-backed resolver when only a nested clientReferences exists" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          clientConfig.plugins.push(
            new RSCWebpackPlugin({
              metadata: {
                clientReferences: 'unused',
              },
              isServer: false,
            }),
          );
        JS
      )

      missing = generator.send(:check_rsc_client_config)
      expect(missing).to include(
        "generated manifest-backed clientReferences resolver in clientWebpackConfig.js"
      )
    end

    it "reports a missing manifest-backed resolver for a fallback-only helper" do
      config_path = "config/webpack/clientWebpackConfig.js"
      simulate_existing_file(
        config_path,
        <<~JS
          const { config } = require('shakapacker');
          const { resolve } = require('path');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');
          const fallbackRscClientReferences = {
            directory: resolve(config.source_path),
            recursive: true,
          };
          const rscClientReferences = [fallbackRscClientReferences];
          clientConfig.plugins.push(
            new RSCWebpackPlugin({
              isServer: false,
              clientReferences: rscClientReferences,
            }),
          );
        JS
      )

      missing = generator.send(:check_rsc_client_config)
      expect(missing).to include(
        "generated manifest-backed clientReferences resolver in clientWebpackConfig.js"
      )
    end
  end

  context "when required imports appear after the client RSC setup anchor" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));

            return clientConfig;
          };

          const { config } = require('shakapacker');

          module.exports = configureClient;
        JS
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "warns why the scoped client references migration was skipped" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content).not_to include("clientReferences: rscClientReferences")
        expect(content).not_to include("const rscClientReferences")
      end

      expect(GeneratorMessages.messages.join("\n"))
        .to include("shakapacker's `config` is imported after the `commonWebpackConfig` anchor")
    end
  end

  context "when an existing client RSC webpack config already references the scoped helper" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        <<~JS
          const { config } = require('shakapacker');
          const { resolve } = require('path');
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(
              new RSCWebpackPlugin({
                isServer: false,
                clientReferences: rscClientReferences,
              }),
            );

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "injects the missing scoped helper instead of warning that all plugins already define clientReferences" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content).to include("const fallbackRscClientReferences = {")
        expect(content).to include("const rscClientReferences = (() => {")
        expect(content).to include("directory: resolve(config.source_path)")
        expect(content).to include("clientReferences: rscClientReferences")
      end

      expect(GeneratorMessages.messages.join("\n"))
        .not_to include("all matching RSCWebpackPlugin instances already define clientReferences")
    end

    it "emits the manifest resolution contract that the Pro dummy mirrors" do
      # Keep these tokens in lockstep with the Pro dummy's hand-written mirror at
      # react_on_rails_pro/spec/dummy/config/webpack/rscManifestClientReferences.js (pinned by
      # react_on_rails_pro/spec/dummy/tests/rsc-manifest-client-references.test.js). Drift on either
      # side fails CI.
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content).to include("process.env.RSC_MANIFEST_CLIENT_REFERENCES_JSON")
        expect(content).to include("process.env.REACT_ON_RAILS_RSC_REGISTRATION_ENTRY_PATH")
        expect(content).to include("ssr-generated/rsc-client-references.json")
        expect(content).to include("RSC_REFERENCE_DISCOVERY_BUILD")
        expect(content).to include("RSC_BUNDLE_ONLY")
        expect(content).to include("Run bin/shakapacker-precompile-hook before bin/shakapacker.")
        expect(content).to include("rscConfigSupportsDiscovery")
        expect(content).to include("resolve(__dirname, 'rscWebpackConfig.js')")
        expect(content).to include("bin/shakapacker-precompile-hook")
        expect(content).to include("const content = readFileSync(filePath, 'utf8');")
        expect(content).to include("falling back to broad client")
        expect(content).to include("reference scan. Re-run rails g react_on_rails:rsc")
        expect(content).to include("Array.isArray(payload.refs)")
        expect(content).to include("to contain a refs array")
        # The configured override is path-resolved on both sides (mirror parity).
        expect(content).to include("resolve(configuredRefsJson)")
        # A configured override that does not exist throws a clear error (mirror parity).
        expect(content).to include("RSC_MANIFEST_CLIENT_REFERENCES_JSON is set but the file does not exist")
        # Malformed manifest JSON is re-thrown with the file path (mirror parity).
        expect(content).to include("Failed to parse RSC client references manifest")
        # Configured overrides also get the best-effort staleness warning (mirror parity).
        expect(content).to include("warnIfManifestStale(resolvedRefsJson)")
        # A configured registration entry path overrides the default staleness target.
        expect(content).to include("const configuredRegistrationEntry")
        expect(content).to include("defaultServerComponentRegistrationEntry")
        expect(content).to include("validServerComponentRegistrationEntry")
        expect(content).to include("basename(entryPath) !== expectedServerComponentRegistrationEntry")
        expect(content).to include("statSync(entryPath).isFile()")
        expect(content).to include("excludedRegistrationEntryPathComponents")
        configured_refs_index = content.index("if (configuredRefsJson)")
        discovery_build_index = content.index("if (process.env.RSC_REFERENCE_DISCOVERY_BUILD")
        default_refs_index = content.index("if (existsSync(defaultRefsJson))")
        expect(configured_refs_index).not_to be_nil
        expect(discovery_build_index).not_to be_nil
        expect(default_refs_index).not_to be_nil
        expect(configured_refs_index).to be < discovery_build_index
        expect(discovery_build_index).to be < default_refs_index
        # Best-effort staleness warning: manifest older than the registration entry -> console.warn.
        expect(content).to include("statSync")
        expect(content).to include("catch {")
        expect(content).to include("may be stale")
        # The fallback resolves to an array, exactly like the manifest path (payload.refs) and the
        # Pro dummy mirror's DEFAULT_CLIENT_REFERENCES, so clientReferences always receives an array
        # regardless of which branch the cascade returns from (mirror parity).
        expect(content.scan("return [fallbackRscClientReferences];").length).to eq(3)
        # Pin the include extension set byte-for-byte in lockstep with the Pro dummy mirror.
        expect(content).to include("/\\.(js|mjs|cjs|ts|mts|cts|jsx|tsx)$/")
      end
    end
  end

  context "when an existing client RSC webpack config mixes custom and scoped client references" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        <<~JS
          const { config } = require('shakapacker');
          const { resolve } = require('path');
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const customClientReferences = { directory: './custom' };

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(
              new RSCWebpackPlugin({
                isServer: false,
                clientReferences: customClientReferences,
              }),
              new RSCWebpackPlugin({
                isServer: false,
                clientReferences: rscClientReferences,
              }),
            );

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "injects the missing scoped helper without touching the custom clientReferences" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content).to include("const fallbackRscClientReferences = {")
        expect(content).to include("const rscClientReferences = (() => {")
        expect(content).to include("directory: resolve(config.source_path)")
        expect(content.scan("clientReferences: customClientReferences").length).to eq(1)
        expect(content.scan("clientReferences: rscClientReferences").length).to eq(1)
      end

      expect(GeneratorMessages.messages.join("\n"))
        .not_to include("all matching RSCWebpackPlugin instances already define clientReferences")
    end
  end

  context "when path is imported into an unusable resolve binding" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const resolve = require('path');
          const { RSCWebpackPlugin } = require('react-on-rails-rsc/WebpackPlugin');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false }));

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "does not add a duplicate resolve binding or half-apply scoped client references" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content.scan("const resolve = require('path');").length).to eq(1)
        expect(content).not_to include("const { resolve } = require('path');")
        expect(content).not_to include("clientReferences: rscClientReferences")
        expect(content).not_to include("const rscClientReferences")
      end

      expect(GeneratorMessages.messages.join("\n"))
        .to include("a top-level `resolve` binding already exists that would conflict")
    end
  end

  context "when the client webpack config uses aliased imports" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        <<~JS
          const { config: shakapackerConfig } = require('shakapacker');
          const { resolve } = require('path');
          #{base_client_webpack_content}
        JS
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "injects a usable config import without redeclaring resolve" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        # An aliased destructuring import does not create the plain `config` binding that
        # rscClientReferences uses, so the duplicate require is intentional and harmless.
        expect(content.scan("const { config } = require('shakapacker');").length).to eq(1)
        expect(content.scan("const { resolve } = require('path');").length).to eq(1)
        expect(content).to include("const { config: shakapackerConfig } = require('shakapacker');")
        expect(content).to include("directory: resolve(config.source_path)")
        expect(content).to include("isServer: false")
      end
    end
  end

  context "when the client webpack config uses self-aliased imports" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "config/webpack/clientWebpackConfig.js",
        <<~JS
          const { config: config } = require('shakapacker');
          const { resolve: resolve } = require('path');
          #{base_client_webpack_content}
        JS
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "reuses the self-aliased imports without adding duplicate bindings" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content).to include("const { config: config } = require('shakapacker');")
        expect(content).to include("const { resolve: resolve } = require('path');")
        expect(content).not_to include("const { config } = require('shakapacker');")
        expect(content).not_to include("const { resolve } = require('path');")
        expect(content).to include("directory: resolve(config.source_path)")
        expect(content).to include("isServer: false")
      end
    end
  end

  context "when Pro is installed with a canonical legacy hello_world layout" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_hello_world_controller("hello_world")
      simulate_canonical_pack_tag_layout("hello_world")

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    include_examples "rsc_hello_server_files", "hello_world"

    it "reuses the existing hello_world layout without creating react_on_rails_default" do
      assert_file "app/views/layouts/hello_world.html.erb"
      assert_no_file "app/views/layouts/react_on_rails_default.html.erb"
    end
  end

  context "when Pro is installed with a canonical custom HelloWorld layout" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_hello_world_controller("marketing")
      simulate_canonical_pack_tag_layout("marketing")

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    include_examples "rsc_hello_server_files", "marketing"

    it "reuses the HelloWorldController layout when it is compatible" do
      assert_file "app/views/layouts/marketing.html.erb"
      assert_no_file "app/views/layouts/react_on_rails_default.html.erb"
    end
  end

  context "when Pro is installed with a parenthesized HelloWorldController layout declaration" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file("app/controllers/hello_world_controller.rb", <<~RUBY)
        class HelloWorldController < ApplicationController
          layout("marketing")

          def index
          end
        end
      RUBY
      simulate_canonical_pack_tag_layout("marketing")

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    include_examples "rsc_hello_server_files", "marketing"

    it "reuses the parenthesized-layout declaration target" do
      assert_file "app/views/layouts/marketing.html.erb"
      assert_no_file "app/views/layouts/react_on_rails_default.html.erb"
    end
  end

  context "when Pro is installed with a HelloWorldController layout declaration followed by a comment" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file("app/controllers/hello_world_controller.rb", <<~RUBY)
        class HelloWorldController < ApplicationController
          layout "marketing" # keep the legacy layout for the existing page

          def index
          end
        end
      RUBY
      simulate_canonical_pack_tag_layout("marketing")

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    include_examples "rsc_hello_server_files", "marketing"

    it "reuses the commented layout declaration target" do
      assert_file "app/views/layouts/marketing.html.erb"
      assert_no_file "app/views/layouts/react_on_rails_default.html.erb"
    end
  end

  context "when Pro is installed with a symbol HelloWorldController layout declaration" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file("app/controllers/hello_world_controller.rb", <<~RUBY)
        class HelloWorldController < ApplicationController
          layout :marketing_layout

          def index
          end
        end
      RUBY
      simulate_canonical_pack_tag_layout("marketing_layout")

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    include_examples "rsc_hello_server_files", "react_on_rails_default"

    it "does not treat a symbol layout selector as a literal layout file name" do
      assert_file "app/views/layouts/marketing_layout.html.erb"
      assert_file "app/views/layouts/react_on_rails_default.html.erb"
    end
  end

  context "when Pro is installed with a named-pack hello_world layout" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_hello_world_controller("hello_world")
      simulate_named_pack_tag_layout("hello_world")

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    include_examples "rsc_hello_server_files", "hello_world"

    it "reuses hello_world when it already has both pack tags" do
      assert_file "app/views/layouts/hello_world.html.erb" do |content|
        expect(content).to include('<%= stylesheet_pack_tag "application" %>')
        expect(content).to include('<%= javascript_pack_tag "application" %>')
      end

      assert_no_file "app/views/layouts/react_on_rails_default.html.erb"
    end
  end

  context "when Pro is installed with a mixed-pack react_on_rails_default layout and a canonical hello_world layout" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_mixed_pack_tag_layout("react_on_rails_default")
      simulate_canonical_pack_tag_layout("hello_world")

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    include_examples "rsc_hello_server_files", "hello_world"

    it "prefers the fully canonical hello_world layout over the mixed default layout" do
      assert_file "app/views/layouts/react_on_rails_default.html.erb" do |content|
        expect(content).to include('<%= stylesheet_pack_tag "application" %>')
        expect(content).to include('<%= javascript_pack_tag "application" %>')
      end

      assert_file "app/views/layouts/hello_world.html.erb" do |content|
        expect(content).to include("<%= stylesheet_pack_tag %>")
        expect(content).to include("<%= javascript_pack_tag %>")
      end
    end
  end

  context "when Pro is installed with canonical pack tags containing percent signs in keyword arguments" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_hello_world_controller("hello_world")
      simulate_existing_layout("hello_world", <<~ERB)
        <!DOCTYPE html>
        <html>
          <head>
            <%= stylesheet_pack_tag(data: { progress: "50%" }) %>
            <%= javascript_pack_tag(data: { progress: "50%" }) %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    include_examples "rsc_hello_server_files", "hello_world"

    it "reuses the existing layout instead of misclassifying the pack tags as missing" do
      assert_file "app/views/layouts/hello_world.html.erb" do |content|
        expect(content).to include('progress: "50%"')
      end

      assert_no_file "app/views/layouts/react_on_rails_default.html.erb"
    end
  end

  context "when Pro is installed with a user-owned react_on_rails_rsc-prefixed layout" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_layout("react_on_rails_rsc_auth", <<~ERB)
        <!DOCTYPE html>
        <html>
          <head>
            <%= stylesheet_pack_tag %>
            <%= javascript_pack_tag %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    include_examples "rsc_hello_server_files", "react_on_rails_default"

    it "does not treat user-owned react_on_rails_rsc-prefixed layouts as generator fallbacks" do
      assert_file "app/views/layouts/react_on_rails_rsc_auth.html.erb"
      assert_file "app/views/layouts/react_on_rails_default.html.erb"
    end
  end

  context "when Pro is installed with similarly named pack tag helpers" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_hello_world_controller("hello_world")
      simulate_existing_layout("hello_world", <<~ERB)
        <!DOCTYPE html>
        <html>
          <head>
            <%= stylesheet_pack_tag_with_integrity "application" %>
            <%= javascript_pack_tag_with_integrity "application" %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    include_examples "rsc_hello_server_files", "react_on_rails_default"

    it "does not treat similarly named helpers as the required pack tag helpers" do
      assert_file "app/views/layouts/hello_world.html.erb" do |content|
        expect(content).to include("javascript_pack_tag_with_integrity")
        expect(content).to include("stylesheet_pack_tag_with_integrity")
      end

      assert_file "app/views/layouts/react_on_rails_default.html.erb"
    end
  end

  context "when Pro is installed with a named-pack react_on_rails_default layout" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_hello_world_controller("react_on_rails_default")
      simulate_named_pack_tag_layout("react_on_rails_default")

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    include_examples "rsc_hello_server_files", "react_on_rails_default"

    it "reuses react_on_rails_default when it already has both pack tags" do
      assert_file "app/views/layouts/react_on_rails_default.html.erb" do |content|
        expect(content).to include('<%= stylesheet_pack_tag "application" %>')
        expect(content).to include('<%= javascript_pack_tag "application" %>')
      end

      assert_no_file "app/views/layouts/react_on_rails_rsc.html.erb"
    end
  end

  context "when Pro is installed with a Tailwind-aware react_on_rails_default layout" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_hello_world_controller("react_on_rails_default")
      simulate_existing_layout("react_on_rails_default", <<~ERB)
        <!DOCTYPE html>
        <html>
          <head>
            <% prepend_javascript_pack_tag "react_on_rails_tailwind" %>
            <%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>
            <%= javascript_pack_tag %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    include_examples "rsc_hello_server_files", "react_on_rails_default"

    it "preserves Tailwind pack tags after regenerating the layout with --force" do
      assert_file "app/views/layouts/react_on_rails_default.html.erb" do |content|
        expect(content).to include('prepend_javascript_pack_tag "react_on_rails_tailwind"')
        expect(content).to include('stylesheet_pack_tag "react_on_rails_tailwind", media: "all"')
        expect(content).to include("<%= javascript_pack_tag %>")
      end

      assert_no_file "app/views/layouts/react_on_rails_rsc.html.erb"
    end
  end

  context "when Pro is installed with an existing HelloServer controller on a non-Tailwind layout" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "app/javascript/src/HelloServer/ror_components/HelloServer.jsx",
        "export default function HelloServer() { return null; }\n"
      )
      simulate_existing_file("app/controllers/hello_server_controller.rb", <<~RUBY)
        class HelloServerController < ApplicationController
          layout "hello_world"

          def index
          end
        end
      RUBY
      simulate_canonical_pack_tag_layout("hello_world")

      Dir.chdir(destination_root) do
        run_generator(["--force", "--tailwind", "--invoked-by-install"])
      end
    end

    it "warns that the existing HelloServer controller may need a Tailwind-aware layout" do
      messages = GeneratorMessages.messages.join("\n")

      expect(messages).to include("HelloServerController already exists")
      expect(messages).to include("may not use the Tailwind-aware React on Rails layout")
      expect(messages).to include('prepend_javascript_pack_tag "react_on_rails_tailwind"')
      expect(messages).to include('stylesheet_pack_tag "react_on_rails_tailwind", media: "all"')
    end
  end

  context "when Pro is installed with an existing HelloServer controller on a commented Tailwind layout" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "app/javascript/src/HelloServer/ror_components/HelloServer.jsx",
        "export default function HelloServer() { return null; }\n"
      )
      simulate_existing_file("app/controllers/hello_server_controller.rb", <<~RUBY)
        class HelloServerController < ApplicationController
          layout "hello_world"

          def index
          end
        end
      RUBY
      simulate_existing_layout("hello_world", <<~ERB)
        <!DOCTYPE html>
        <html>
          <head>
            <!--
            <% prepend_javascript_pack_tag "react_on_rails_tailwind" %>
            <%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>
            <%= javascript_pack_tag %>
            -->
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB

      Dir.chdir(destination_root) do
        run_generator(["--force", "--tailwind", "--invoked-by-install"])
      end
    end

    it "warns that the existing HelloServer controller still needs an active Tailwind-aware layout" do
      messages = GeneratorMessages.messages.join("\n")

      expect(messages).to include("HelloServerController already exists")
      expect(messages).to include("may not use the Tailwind-aware React on Rails layout")
    end
  end

  context "when Pro is installed with an existing HelloServer controller on a Tailwind-aware layout" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "app/javascript/src/HelloServer/ror_components/HelloServer.jsx",
        "export default function HelloServer() { return null; }\n"
      )
      simulate_existing_file("app/controllers/hello_server_controller.rb", <<~RUBY)
        class HelloServerController < ApplicationController
          layout "hello_world"

          def index
          end
        end
      RUBY
      simulate_existing_layout("hello_world", <<~ERB)
        <!DOCTYPE html>
        <html>
          <head>
            <% prepend_javascript_pack_tag "react_on_rails_tailwind" %>
            <%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>
            <%= javascript_pack_tag %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB

      Dir.chdir(destination_root) do
        run_generator(["--force", "--tailwind", "--invoked-by-install"])
      end
    end

    it "does not warn when the existing controller layout has the active Tailwind pack block" do
      messages = GeneratorMessages.messages.join("\n")

      expect(messages).not_to include("may not use the Tailwind-aware React on Rails layout")
    end
  end

  context "when Pro is installed with an existing HelloServer controller " \
          "inheriting a Tailwind-aware ApplicationController layout" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("app/controllers/application_controller.rb", <<~RUBY)
        class ApplicationController < ActionController::Base
          layout "react_on_rails_default"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "app/javascript/src/HelloServer/ror_components/HelloServer.jsx",
        "export default function HelloServer() { return null; }\n"
      )
      simulate_existing_file("app/controllers/hello_server_controller.rb", <<~RUBY)
        class HelloServerController < ApplicationController
          def index
          end
        end
      RUBY
      simulate_existing_layout("react_on_rails_default", <<~ERB)
        <!DOCTYPE html>
        <html>
          <head>
            <% prepend_javascript_pack_tag "react_on_rails_tailwind" %>
            <%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>
            <%= javascript_pack_tag %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB

      Dir.chdir(destination_root) do
        run_generator(["--force", "--tailwind", "--invoked-by-install"])
      end
    end

    it "does not warn when the inherited default layout has the active Tailwind pack block" do
      messages = GeneratorMessages.messages.join("\n")

      expect(messages).not_to include("may not use the Tailwind-aware React on Rails layout")
    end
  end

  context "when Pro is installed with an existing HelloServer controller " \
          "implicitly using the application layout" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_existing_file(
        "app/javascript/src/HelloServer/ror_components/HelloServer.jsx",
        "export default function HelloServer() { return null; }\n"
      )
      simulate_existing_file("app/controllers/hello_server_controller.rb", <<~RUBY)
        class HelloServerController < ApplicationController
          def index
          end
        end
      RUBY
      simulate_named_pack_tag_layout("application")
      simulate_existing_layout("react_on_rails_default", <<~ERB)
        <!DOCTYPE html>
        <html>
          <head>
            <% prepend_javascript_pack_tag "react_on_rails_tailwind" %>
            <%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>
            <%= javascript_pack_tag %>
          </head>
          <body>
            <%= yield %>
          </body>
        </html>
      ERB

      Dir.chdir(destination_root) do
        run_generator(["--force", "--tailwind", "--invoked-by-install"])
      end
    end

    it "warns because Rails falls back to application, not react_on_rails_default" do
      messages = GeneratorMessages.messages.join("\n")

      expect(messages).to include("HelloServerController already exists")
      expect(messages).to include("may not use the Tailwind-aware React on Rails layout")
    end
  end

  context "when Pro is installed with a hello_world layout missing a required pack tag" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_hello_world_controller("hello_world")
      simulate_layout_missing_stylesheet_pack_tag("hello_world")

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    include_examples "rsc_hello_server_files", "react_on_rails_default"

    it "creates react_on_rails_default instead of reusing the incomplete hello_world layout" do
      assert_file "app/views/layouts/react_on_rails_default.html.erb" do |content|
        expect(content).to include("<%= stylesheet_pack_tag %>")
        expect(content).to include("<%= javascript_pack_tag %>")
      end

      assert_file "app/views/layouts/hello_world.html.erb" do |content|
        expect(content).to include('<%= javascript_pack_tag "application" %>')
        expect(content).not_to include("stylesheet_pack_tag")
      end
    end
  end

  context "when Tailwind RSC sees a canonical legacy hello_world layout without Tailwind wiring" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_hello_world_controller("hello_world")
      simulate_canonical_pack_tag_layout("hello_world")

      Dir.chdir(destination_root) do
        run_generator(["--force", "--tailwind", "--invoked-by-install"])
      end
    end

    include_examples "rsc_hello_server_files", "react_on_rails_default"

    it "creates a Tailwind-aware fallback layout instead of reusing the legacy layout" do
      assert_file "app/views/layouts/hello_world.html.erb" do |content|
        expect(content).to include("<%= stylesheet_pack_tag %>")
        expect(content).to include("<%= javascript_pack_tag %>")
        expect(content).not_to include("react_on_rails_tailwind")
      end

      assert_file "app/views/layouts/react_on_rails_default.html.erb" do |content|
        expect(content).to include('<% prepend_javascript_pack_tag "react_on_rails_tailwind" %>')
        expect(content).to include('<%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>')
        expect(content).to include("<%= javascript_pack_tag %>")
      end
    end
  end

  context "when Tailwind RSC fallback creates a new layout after earlier layouts are unusable" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_hello_world_controller("hello_world")
      simulate_layout_missing_stylesheet_pack_tag("hello_world")

      Dir.chdir(destination_root) do
        run_generator(["--force", "--tailwind", "--invoked-by-install"])
      end
    end

    include_examples "rsc_hello_server_files", "react_on_rails_default"

    it "creates a Tailwind-aware fallback layout" do
      assert_file "app/views/layouts/react_on_rails_default.html.erb" do |content|
        expect(content).to include('<% prepend_javascript_pack_tag "react_on_rails_tailwind" %>')
        expect(content).to include('<%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>')
        expect(content).to include("<%= javascript_pack_tag %>")
      end
    end
  end

  context "when earlier layouts are unusable and a compatible react_on_rails_rsc layout already exists" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_hello_world_controller("hello_world")
      simulate_layout_missing_stylesheet_pack_tag("hello_world")
      simulate_canonical_pack_tag_layout("react_on_rails_rsc")

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    include_examples "rsc_hello_server_files", "react_on_rails_rsc"

    it "reuses the existing react_on_rails_rsc layout instead of minting react_on_rails_rsc_2" do
      assert_file "app/views/layouts/react_on_rails_rsc.html.erb"
      assert_no_file "app/views/layouts/react_on_rails_rsc_2.html.erb"
    end
  end

  context "when earlier layouts are unusable and a compatible react_on_rails_rsc_10 layout already exists" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_pro_webpack_files
      simulate_hello_world_controller("hello_world")
      simulate_layout_missing_stylesheet_pack_tag("hello_world")
      simulate_canonical_pack_tag_layout("react_on_rails_rsc_10")

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    include_examples "rsc_hello_server_files", "react_on_rails_rsc_10"

    it "reuses the existing react_on_rails_rsc_10 layout instead of minting a new fallback" do
      assert_file "app/views/layouts/react_on_rails_rsc_10.html.erb"
      assert_no_file "app/views/layouts/react_on_rails_rsc_11.html.erb"
    end
  end

  # Rspack variant — verifies that standalone RSC generator writes to config/rspack/
  # when it detects an existing rspack project via config/shakapacker.yml.
  # RscGenerator has no --rspack option; detection is via rspack_configured_in_project?.

  context "when Pro is installed on an existing rspack project" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      # simulate_rspack_pro_webpack_files also creates the rspack shakapacker.yml
      # so rspack_configured_in_project? returns true (no --rspack flag available)
      simulate_rspack_pro_webpack_files

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "creates RSC webpack config in config/rspack/ (not config/webpack/)" do
      assert_file "config/rspack/rscWebpackConfig.js" do |content|
        expect(content).to include("rscConfig")
      end
      assert_no_file "config/webpack/rscWebpackConfig.js"
    end

    describe "RSC webpack config transforms in config/rspack/" do
      it "adds the native RSCRspackPlugin to serverWebpackConfig" do
        assert_file "config/rspack/serverWebpackConfig.js" do |content|
          expect(content).to include("RSCRspackPlugin")
          expect(content).to include("react-on-rails-rsc/RspackPlugin")
          expect(content).to include("clientReferences: rscClientReferences")
          expect(content).to include("const rscClientReferences = (() => {")
          expect(content).to include("const defaultRefsJson = resolve('ssr-generated/rsc-client-references.json');")
          expect(content).to include("return readManifestReferences(defaultRefsJson);")
          expect(content).to include("directory: resolve(config.source_path)")
          expect(content).to include("isServer: true")
          # Rspack projects get the native plugin, not the webpack one.
          expect(content).not_to include("RSCWebpackPlugin")
          expect(content).not_to include("react-on-rails-rsc/WebpackPlugin")
        end
      end

      it "adds rscBundle parameter to configureServer" do
        assert_file "config/rspack/serverWebpackConfig.js" do |content|
          expect(content).to match(/configureServer\s*=\s*\(rscBundle\s*=\s*false\)/)
        end
      end

      it "adds the native RSCRspackPlugin to clientWebpackConfig" do
        assert_file "config/rspack/clientWebpackConfig.js" do |content|
          expect(content).to include("RSCRspackPlugin")
          expect(content).to include("react-on-rails-rsc/RspackPlugin")
          expect(content).to include("clientReferences: rscClientReferences")
          expect(content).to include("const rscClientReferences = (() => {")
          expect(content).to include("const defaultRefsJson = resolve('ssr-generated/rsc-client-references.json');")
          expect(content).to include("const rscWebpackConfig = resolve(__dirname, 'rscWebpackConfig.js')")
          expect(content).not_to include("config/webpack/rscWebpackConfig.js")
          expect(content).to include("return readManifestReferences(defaultRefsJson);")
          expect(content).to include("directory: resolve(config.source_path)")
          expect(content).to include("isServer: false")
          expect(content).not_to include("RSCWebpackPlugin")
          expect(content).not_to include("react-on-rails-rsc/WebpackPlugin")
        end
      end

      it "adds RSC handling to ServerClientOrBoth" do
        assert_file "config/rspack/ServerClientOrBoth.js" do |content|
          expect(content).to include("require('./rscWebpackConfig')")
          expect(content).to include("envSpecific(clientConfig, serverConfig, rscConfig);")
          expect(content).to include("RSC_BUNDLE_ONLY")
          expect(content).to include("rscConfig")
        end
      end
    end

    # Rspack RSC compatibility — verifies that the generated RSC config uses
    # bundler-agnostic patterns that work with both webpack and Rspack runtimes.
    # Some assertions below overlap with the "RSC webpack config transforms" block
    # above but use more specific matchers (e.g. verifying the `false` value, not
    # just the key name). The duplication is intentional.
    # See: https://github.com/shakacode/react_on_rails/issues/1828

    describe "Rspack RSC runtime compatibility" do
      it "rscWebpackConfig.js uses react-server conditionNames for module resolution" do
        assert_file "config/rspack/rscWebpackConfig.js" do |content|
          expect(content).to include("conditionNames")
          expect(content).to include("react-server")
        end
      end

      it "rscWebpackConfig.js canonicalizes React server aliases and excludes react-dom/server for RSC bundle" do
        assert_file "config/rspack/rscWebpackConfig.js" do |content|
          expect(content).to include("delete rscAliases.react")
          expect(content).to include("delete rscAliases['react$']")
          expect(content).to include("delete rscAliases['react/jsx-runtime']")
          expect(content).to include("delete rscAliases['react/jsx-runtime$']")
          expect(content).to include("delete rscAliases['react/jsx-dev-runtime']")
          expect(content).to include("delete rscAliases['react/jsx-dev-runtime$']")
          expect(content).to include("delete rscAliases['react-dom/server']")
          expect(content).to include("delete rscAliases['react-dom/server$']")
          expect(content).to include("react$: resolveReactServerEntry('react.react-server.js')")
          expect(content).to include("'react/jsx-runtime$': resolveReactServerEntry('jsx-runtime.react-server.js')")
          expect(content).to include(
            "'react/jsx-dev-runtime$': resolveReactServerEntry('jsx-dev-runtime.react-server.js')"
          )
          expect(content).to include("'react-dom/server': false")
        end
      end

      it "rscWebpackConfig.js adds RSC WebpackLoader to the loader chain" do
        assert_file "config/rspack/rscWebpackConfig.js" do |content|
          expect(content).to include("react-on-rails-rsc/WebpackLoader")
        end
      end

      it "rscWebpackConfig.js passes true to skip the RSC plugin in RSC bundle" do
        assert_file "config/rspack/rscWebpackConfig.js" do |content|
          expect(content).to include("serverWebpackConfig(true)")
          # The RSC bundle must not include either bundler's manifest plugin.
          expect(content).not_to match(/new\s+RSC(?:Webpack|Rspack)Plugin/)
        end
      end

      it "rscWebpackConfig.js renames entry to rsc-bundle" do
        assert_file "config/rspack/rscWebpackConfig.js" do |content|
          expect(content).to include("'rsc-bundle'")
          expect(content).to include("rsc-bundle.js")
        end
      end

      it "rscWebpackConfig.js contains conditional loader-chain handling for function-based and array-based rule.use" do
        assert_file "config/rspack/rscWebpackConfig.js" do |content|
          # Must handle both loader styles since Rspack projects often use SWC
          expect(content).to include("typeof rule.use === 'function'")
          expect(content).to include("Array.isArray(rule.use)")
        end
      end

      it "serverWebpackConfig.js (from Pro generator) uses bundler-agnostic LimitChunkCountPlugin" do
        assert_file "config/rspack/serverWebpackConfig.js" do |content|
          # This content comes from the Pro generator, not the RSC generator.
          # Verified here to ensure the full Rspack server config is bundler-agnostic.
          expect(content).to include("bundler.optimize.LimitChunkCountPlugin")
        end
      end

      it "serverWebpackConfig.js conditionally skips the RSC plugin when rscBundle is true" do
        assert_file "config/rspack/serverWebpackConfig.js" do |content|
          expect(content).to include("if (!rscBundle)")
          expect(content).to include("clientReferences: rscClientReferences")
          expect(content).to include("directory: resolve(config.source_path)")
          expect(content).to include("isServer: true")
        end
      end

      it "ServerClientOrBoth.js includes RSC_BUNDLE_ONLY env var handling for isolated RSC builds" do
        assert_file "config/rspack/ServerClientOrBoth.js" do |content|
          expect(content).to include("process.env.RSC_BUNDLE_ONLY")
          expect(content).to include("rscConfig")
          # Verify three-bundle default (client + server + RSC)
          expect(content).to include("[clientConfig, serverConfig, rscConfig]")
        end
      end
    end
  end

  # Rspack analogue of the webpack "already imports/invokes RSCWebpackPlugin" dedup contexts above.
  # Exercises the Rspack branch of RSC_PLUGIN_INVOCATION_REGEX (/new\s+RSC(?:Webpack|Rspack)Plugin\s*\(/):
  # if that regex regressed to webpack-only, the generator would not detect the existing
  # `new RSCRspackPlugin(` call, would route to the add-plugin path, and inject a duplicate import —
  # producing `Identifier 'RSCRspackPlugin' has already been declared` at build time.
  context "when an existing rspack client config already imports and invokes RSCRspackPlugin" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      # Sets up the rspack shakapacker.yml so rspack_configured_in_project? is true,
      # then overrides the client config with one that already has the native plugin.
      simulate_rspack_pro_webpack_files
      simulate_existing_file(
        "config/rspack/clientWebpackConfig.js",
        <<~JS
          const commonWebpackConfig = require('./commonWebpackConfig');
          const { RSCRspackPlugin } = require('react-on-rails-rsc/RspackPlugin');

          const configureClient = () => {
            const clientConfig = commonWebpackConfig();
            delete clientConfig.entry['server-bundle'];

            clientConfig.plugins.push(
              new RSCRspackPlugin ({ isServer: false })
            );

            return clientConfig;
          };

          module.exports = configureClient;
        JS
      )

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "detects the existing native plugin and routes to the update path rather than duplicating the import" do
      assert_file "config/rspack/clientWebpackConfig.js" do |content|
        expect(content.scan(%r{require\(['"]react-on-rails-rsc/RspackPlugin['"]\)}).length).to eq(1)
        expect(content.scan(/new\s+RSCRspackPlugin\s*\(/).length).to eq(1)
        # The webpack plugin must never leak into an rspack config.
        expect(content).not_to include("RSCWebpackPlugin")
        expect(content).not_to include("react-on-rails-rsc/WebpackPlugin")
      end
    end

    it "injects scoped clientReferences into the existing native plugin call" do
      assert_file "config/rspack/clientWebpackConfig.js" do |content|
        expect(content).to include("clientReferences: rscClientReferences")
        expect(content).to include("const rscClientReferences")
        expect(content).to include("directory: resolve(config.source_path)")
      end
    end
  end

  # Rspack + legacy Pro variant — same as the legacy webpack exports context below,
  # but with Pro configs in config/rspack/ and rspack shakapacker.yml.
  # Verifies that the backward-compatible rscWebpackConfig.js is created in the
  # correct rspack path when the project uses legacy-style Pro exports.

  context "when Pro is installed with legacy webpack exports on an existing rspack project" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_rspack_legacy_pro_webpack_files

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "creates backward-compatible rscWebpackConfig.js in config/rspack/" do
      assert_file "config/rspack/rscWebpackConfig.js" do |content|
        expect(content).to include("const serverWebpackModule = require('./serverWebpackConfig')")
        expect(content).to include("serverWebpackModule.default || serverWebpackModule")
        expect(content).to include("serverWebpackModule.extractLoader ||")
      end
      assert_no_file "config/webpack/rscWebpackConfig.js"
    end

    it "adds RSC import to ServerClientOrBoth in config/rspack/ for legacy server import syntax" do
      assert_file "config/rspack/ServerClientOrBoth.js" do |content|
        expect(content).to include("const serverWebpackConfig = require('./serverWebpackConfig');")
        expect(content).to include("const rscWebpackConfig = require('./rscWebpackConfig');")
      end
    end
  end

  context "when Pro is installed with legacy webpack exports" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
        ReactOnRailsPro.configure do |config|
          config.server_renderer = "NodeRenderer"
        end
      RUBY
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_legacy_pro_webpack_files

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "creates backward-compatible rscWebpackConfig.js" do
      assert_file "config/webpack/rscWebpackConfig.js" do |content|
        expect(content).to include("const serverWebpackModule = require('./serverWebpackConfig')")
        expect(content).to include("serverWebpackModule.default || serverWebpackModule")
        expect(content).to include("serverWebpackModule.extractLoader ||")
      end
    end

    it "adds RSC import to ServerClientOrBoth for legacy server import syntax" do
      assert_file "config/webpack/ServerClientOrBoth.js" do |content|
        expect(content).to include("const serverWebpackConfig = require('./serverWebpackConfig');")
        expect(content).to include("const rscWebpackConfig = require('./rscWebpackConfig');")
      end
    end
  end

  # Regression tests for #4630 — fragile envSpecific gsub and masking verifier.
  # The standalone RSC generator gsub-rewrites ServerClientOrBoth.js; when a linter
  # reformats the file (e.g. removes trailing semicolons), the rewrite must still
  # succeed, the verifier must catch partial transforms, and re-running the generator
  # must repair them.

  describe "ServerClientOrBoth envSpecific rewrite robustness (#4630)" do
    let(:generator) { described_class.new([], {}, { destination_root: }) }

    before do
      prepare_destination
    end

    it "rewrites envSpecific call even when the trailing semicolon is missing" do
      config_path = "config/webpack/ServerClientOrBoth.js"
      base_content = server_client_or_both_content(destructured_import: true)
      content_without_semicolons = base_content
                                   .gsub("envSpecific(clientConfig, serverConfig);",
                                         "envSpecific(clientConfig, serverConfig)")
      simulate_existing_file(config_path, content_without_semicolons)

      generator.send(:update_server_client_or_both_for_rsc)

      result = File.read(File.join(destination_root, config_path))
      expect(result).to include("envSpecific(clientConfig, serverConfig, rscConfig);")
    end

    it "rewrites envSpecific call with extra whitespace around arguments" do
      config_path = "config/webpack/ServerClientOrBoth.js"
      base_content = server_client_or_both_content(destructured_import: true)
      content_with_spaces = base_content
                            .gsub("envSpecific(clientConfig, serverConfig);",
                                  "envSpecific( clientConfig ,  serverConfig )")
      simulate_existing_file(config_path, content_with_spaces)

      generator.send(:update_server_client_or_both_for_rsc)

      result = File.read(File.join(destination_root, config_path))
      expect(result).to include("envSpecific(clientConfig, serverConfig, rscConfig);")
    end

    it "repairs a partially transformed file on re-run" do
      config_path = "config/webpack/ServerClientOrBoth.js"
      # Simulate partial state: import landed but envSpecific was NOT rewritten
      partial_content = server_client_or_both_content(destructured_import: true)
                        .sub(
                          "const { default: serverWebpackConfig } = require('./serverWebpackConfig');",
                          "const { default: serverWebpackConfig } = require('./serverWebpackConfig');\n" \
                          "const rscWebpackConfig = require('./rscWebpackConfig');"
                        )
      simulate_existing_file(config_path, partial_content)

      generator.send(:update_server_client_or_both_for_rsc)

      result = File.read(File.join(destination_root, config_path))
      expect(result).to include("envSpecific(clientConfig, serverConfig, rscConfig);")
      expect(result).to include("RSC_BUNDLE_ONLY")
      expect(result.scan("require('./rscWebpackConfig')").length).to eq(1)
    end

    it "verifier detects a partially transformed ServerClientOrBoth" do
      config_path = "config/webpack/ServerClientOrBoth.js"
      # Import present but invocation and envSpecific NOT rewritten
      partial_content = server_client_or_both_content(destructured_import: true)
                        .sub(
                          "const { default: serverWebpackConfig } = require('./serverWebpackConfig');",
                          "const { default: serverWebpackConfig } = require('./serverWebpackConfig');\n" \
                          "const rscWebpackConfig = require('./rscWebpackConfig');"
                        )
      simulate_existing_file(config_path, partial_content)

      missing = generator.send(:check_rsc_scob_config)
      expect(missing).to include(
        "rscConfig declaration (const rscConfig = rscWebpackConfig()) in ServerClientOrBoth.js"
      )
      expect(missing).to include(
        "envSpecific(clientConfig, serverConfig, rscConfig) call in ServerClientOrBoth.js"
      )
      # The verifier now also covers the two default-branch transforms so a
      # silent RSC_BUNDLE_ONLY / result-array no-op is surfaced, not masked.
      expect(missing).to include("RSC_BUNDLE_ONLY branch in ServerClientOrBoth.js")
      expect(missing).to include("RSC-aware default result array in ServerClientOrBoth.js")
      expect(missing).not_to include("rscWebpackConfig import in ServerClientOrBoth.js")
    end

    it "verifier flags a missing RSC_BUNDLE_ONLY branch even when import/invocation/envSpecific are present" do
      config_path = "config/webpack/ServerClientOrBoth.js"
      # Fully transform, then simulate a downstream tool stripping just the
      # RSC_BUNDLE_ONLY branch and reverting the default result array.
      simulate_existing_file(config_path,
                             server_client_or_both_content(destructured_import: true))
      generator.send(:update_server_client_or_both_for_rsc)
      full = File.read(File.join(destination_root, config_path))
      degraded = full
                 .sub(/  \} else if \(process\.env\.RSC_BUNDLE_ONLY\) \{.*?result = rscConfig;\n/m, "")
                 .sub("result = [clientConfig, serverConfig, rscConfig];",
                      "result = [clientConfig, serverConfig];")
      File.write(File.join(destination_root, config_path), degraded)

      missing = generator.send(:check_rsc_scob_config)
      expect(missing).to include("RSC_BUNDLE_ONLY branch in ServerClientOrBoth.js")
      expect(missing).to include("RSC-aware default result array in ServerClientOrBoth.js")
      # The three upstream markers are still present, so they must NOT be flagged.
      expect(missing).not_to include("rscWebpackConfig import in ServerClientOrBoth.js")
      expect(missing).not_to include(
        "rscConfig declaration (const rscConfig = rscWebpackConfig()) in ServerClientOrBoth.js"
      )
      expect(missing).not_to include(
        "envSpecific(clientConfig, serverConfig, rscConfig) call in ServerClientOrBoth.js"
      )
    end

    it "verifier returns empty for a fully transformed ServerClientOrBoth" do
      config_path = "config/webpack/ServerClientOrBoth.js"
      simulate_existing_file(config_path,
                             server_client_or_both_content(destructured_import: true))

      generator.send(:update_server_client_or_both_for_rsc)

      missing = generator.send(:check_rsc_scob_config)
      expect(missing).to eq([])
    end

    it "inserts the rscConfig declaration even when rscWebpackConfig() appears only in a comment" do
      config_path = "config/webpack/ServerClientOrBoth.js"
      # A stray comment mentioning the invocation must NOT trip the skip-guard —
      # otherwise the `const rscConfig = rscWebpackConfig();` declaration is skipped
      # while envSpecific/RSC_BUNDLE_ONLY still reference rscConfig, producing
      # `ReferenceError: rscConfig is not defined` at runtime.
      with_comment = server_client_or_both_content(destructured_import: true)
                     .sub("const serverClientOrBoth = (envSpecific) => {",
                          "// NOTE: rscWebpackConfig() is invoked below\n" \
                          "const serverClientOrBoth = (envSpecific) => {")
      simulate_existing_file(config_path, with_comment)

      generator.send(:update_server_client_or_both_for_rsc)

      result = File.read(File.join(destination_root, config_path))
      # Declaration inserted exactly once, and every rscConfig reference is backed.
      expect(result).to include("const rscConfig = rscWebpackConfig();")
      expect(result.scan("const rscConfig = rscWebpackConfig();").length).to eq(1)
      expect(result).to include("envSpecific(clientConfig, serverConfig, rscConfig);")
      expect(generator.send(:check_rsc_scob_config)).to eq([])
    end

    it "inserts the RSC_BUNDLE_ONLY branch even when RSC_BUNDLE_ONLY appears only in a comment" do
      config_path = "config/webpack/ServerClientOrBoth.js"
      # A stray comment mentioning RSC_BUNDLE_ONLY must not make the branch
      # insertion silently no-op via a loose substring guard.
      with_comment = server_client_or_both_content(destructured_import: true)
                     .sub("  let result;",
                          "  // RSC_BUNDLE_ONLY handling is added below\n  let result;")
      simulate_existing_file(config_path, with_comment)

      generator.send(:update_server_client_or_both_for_rsc)

      result = File.read(File.join(destination_root, config_path))
      expect(result).to include("} else if (process.env.RSC_BUNDLE_ONLY) {")
      expect(result.scan("result = rscConfig;").length).to eq(1)
      expect(generator.send(:check_rsc_scob_config)).to eq([])
    end

    it "verifier flags a stray RSC_BUNDLE_ONLY comment mention as a missing branch" do
      config_path = "config/webpack/ServerClientOrBoth.js"
      # Fully transform, then replace the real branch with a bare comment mention.
      simulate_existing_file(config_path,
                             server_client_or_both_content(destructured_import: true))
      generator.send(:update_server_client_or_both_for_rsc)
      full = File.read(File.join(destination_root, config_path))
      stray = full.sub(/  \} else if \(process\.env\.RSC_BUNDLE_ONLY\) \{.*?result = rscConfig;\n/m,
                       "  // RSC_BUNDLE_ONLY branch removed by a downstream tool\n")
      File.write(File.join(destination_root, config_path), stray)

      # The loose substring `RSC_BUNDLE_ONLY` is still present, but the structural
      # matcher (condition + `result = rscConfig`) is not, so it is flagged.
      missing = generator.send(:check_rsc_scob_config)
      expect(missing).to include("RSC_BUNDLE_ONLY branch in ServerClientOrBoth.js")
    end

    it "recognizes an inner-bracket-spaced result array as already RSC-aware (no double transform)" do
      config_path = "config/webpack/ServerClientOrBoth.js"
      simulate_existing_file(config_path,
                             server_client_or_both_content(destructured_import: true))
      generator.send(:update_server_client_or_both_for_rsc)
      full = File.read(File.join(destination_root, config_path))
      # Simulate a linter reflowing the array with inner-bracket spaces.
      reflowed = full.sub("result = [clientConfig, serverConfig, rscConfig];",
                          "result = [ clientConfig, serverConfig, rscConfig ];")
      File.write(File.join(destination_root, config_path), reflowed)

      generator2 = described_class.new([], {}, { destination_root: })
      generator2.send(:update_server_client_or_both_for_rsc)

      result = File.read(File.join(destination_root, config_path))
      expect(result).to include("result = [ clientConfig, serverConfig, rscConfig ];")
      # Not double-rewritten into a broken/duplicated array.
      expect(result.scan(/result\s*=\s*\[[^\]]*rscConfig[^\]]*\]/).length).to eq(1)
      expect(generator2.send(:check_rsc_scob_config)).to eq([])
    end

    it "is idempotent across consecutive runs" do
      config_path = "config/webpack/ServerClientOrBoth.js"
      # Start with the base (unconfigured) fixture
      simulate_existing_file(config_path,
                             server_client_or_both_content(destructured_import: true))

      generator.send(:update_server_client_or_both_for_rsc)
      result = File.read(File.join(destination_root, config_path))

      # Re-running on the transformed output must be a true no-op
      generator2 = described_class.new([], {}, { destination_root: })
      generator2.send(:update_server_client_or_both_for_rsc)

      result2 = File.read(File.join(destination_root, config_path))
      expect(result2).to eq(result)
    end

    it "repairs partially transformed default-bundle output on re-run" do
      config_path = "config/webpack/ServerClientOrBoth.js"
      # Simulate: log message updated but result array NOT updated
      partial_content = server_client_or_both_content(destructured_import: true)
                        .sub(
                          "console.log('[React on Rails] Creating both client and server bundles.');",
                          "console.log('[React on Rails] Creating client, server, and RSC bundles.');"
                        )
      simulate_existing_file(config_path, partial_content)

      generator.send(:update_server_client_or_both_for_rsc)

      result = File.read(File.join(destination_root, config_path))
      expect(result).to include("[clientConfig, serverConfig, rscConfig]")
      expect(result).to include("client, server, and RSC bundles")
    end

    it "inserts the RSC_BUNDLE_ONLY branch even when the default-build comment is removed" do
      config_path = "config/webpack/ServerClientOrBoth.js"
      # A linter/user may drop or reword the `// default is the standard client
      # and server build` comment; the insertion must not depend on it.
      content_without_comment = server_client_or_both_content(destructured_import: true)
                                .gsub("    // default is the standard client and server build\n", "")
      simulate_existing_file(config_path, content_without_comment)

      generator.send(:update_server_client_or_both_for_rsc)

      result = File.read(File.join(destination_root, config_path))
      expect(result).to include("process.env.RSC_BUNDLE_ONLY")
      expect(result).to include("result = rscConfig;")
      # Exactly one RSC_BUNDLE_ONLY branch — the bare `} else {` anchor must not
      # match the `} else if (...) {` branches.
      expect(result.scan("process.env.RSC_BUNDLE_ONLY").length).to eq(1)
    end

    it "inserts the RSC_BUNDLE_ONLY branch when the default-build comment is reworded and reflowed" do
      config_path = "config/webpack/ServerClientOrBoth.js"
      reflowed = server_client_or_both_content(destructured_import: true)
                 .gsub("    // default is the standard client and server build",
                       "    // fall through to the combined client + server build")
                 .gsub("  } else {", "  }else{")
      # Guard: the fixture must actually contain the compact `}else{` form, so this
      # test can't silently no-op (the indentation the helper emits is 2 spaces).
      expect(reflowed).to include("}else{")
      expect(reflowed).not_to include("} else {")
      simulate_existing_file(config_path, reflowed)

      generator.send(:update_server_client_or_both_for_rsc)

      result = File.read(File.join(destination_root, config_path))
      # Passes because DEFAULT_BUILD_BRANCH_ANCHOR is whitespace-tolerant
      # (`\}\s*else\s*\{`), genuinely matching the compact `}else{` form.
      expect(result).to include("process.env.RSC_BUNDLE_ONLY")
      expect(result.scan("process.env.RSC_BUNDLE_ONLY").length).to eq(1)
    end

    it "inserts RSC_BUNDLE_ONLY into the default branch only, not an earlier bare `} else {`" do
      config_path = "config/webpack/ServerClientOrBoth.js"
      # Customized SCOB with an EARLIER bare `} else {` on the envSpecific guard,
      # before `let result;` is declared. The insertion must anchor on the
      # default-build branch, not this earlier else — otherwise `result = rscConfig`
      # is spliced in before `result` exists, corrupting the config.
      customized = server_client_or_both_content(destructured_import: true)
                   .sub(
                     "  if (envSpecific) {\n    envSpecific(clientConfig, serverConfig);\n  }",
                     "  if (envSpecific) {\n    envSpecific(clientConfig, serverConfig);\n  " \
                     "} else {\n    throw new Error('envSpecific is required');\n  }"
                   )
      simulate_existing_file(config_path, customized)

      generator.send(:update_server_client_or_both_for_rsc)

      result = File.read(File.join(destination_root, config_path))
      # Exactly one RSC branch, and the earlier custom else is untouched.
      expect(result.scan("process.env.RSC_BUNDLE_ONLY").length).to eq(1)
      expect(result).to include("} else {\n    throw new Error('envSpecific is required');\n  }")
      # The RSC branch sits inside the bundle-selection block, immediately before
      # the default `} else {` (the one whose body builds the default result).
      expect(result).to match(
        /result = rscConfig;\n\s*\} else \{[^}]*?result = \[clientConfig, serverConfig, rscConfig\]/m
      )
      # Corruption signature: no `result = rscConfig;` before `let result;`.
      before_decl = result[0...result.index("let result;")]
      expect(before_decl).not_to include("result = rscConfig;")
    end

    # #4630 core invariant: the third envSpecific arg (rscConfig) is what lets
    # development.js flip `clientWebpackConfig.lazyCompilation = false` for RSC.
    # If this rewrite silently no-ops, lazy compilation is left ON. Guard the
    # exact 3-arg shape development.js's `developmentEnvOnly(client, _server,
    # rscWebpackConfig)` relies on.
    it "rewrites envSpecific to the 3-arg form that enables lazyCompilation=false" do
      config_path = "config/webpack/ServerClientOrBoth.js"
      simulate_existing_file(config_path,
                             server_client_or_both_content(destructured_import: true))

      generator.send(:update_server_client_or_both_for_rsc)

      result = File.read(File.join(destination_root, config_path))
      # The rscConfig third arg must be present and truthy at runtime.
      expect(result).to include("const rscConfig = rscWebpackConfig();")
      expect(result).to match(/envSpecific\(\s*clientConfig\s*,\s*serverConfig\s*,\s*rscConfig\s*\)/)
      # The pre-RSC 2-arg call must be gone (that shape leaves lazyCompilation on).
      expect(result).not_to match(/envSpecific\(\s*clientConfig\s*,\s*serverConfig\s*\)\s*;/)
    end

    it "inserts the RSC import after a `.default` server import (valid JS, not before the property access)" do
      config_path = "config/webpack/ServerClientOrBoth.js"
      # Customized server import using a trailing `.default`. The RSC import must
      # land AFTER the full statement, never before `.default;` (which would
      # produce `require('./serverWebpackConfig')\nconst rscWebpackConfig...;.default;`).
      with_default = server_client_or_both_content(destructured_import: false)
                     .sub("const serverWebpackConfig = require('./serverWebpackConfig');",
                          "const serverWebpackConfig = require('./serverWebpackConfig').default;")
      simulate_existing_file(config_path, with_default)

      generator.send(:update_server_client_or_both_for_rsc)

      result = File.read(File.join(destination_root, config_path))
      expect(result).to include(
        "const serverWebpackConfig = require('./serverWebpackConfig').default;\n" \
        "const rscWebpackConfig = require('./rscWebpackConfig');"
      )
      # No corrupted `);.default;` sequence, and exactly one RSC import.
      expect(result).not_to include(");.default")
      expect(result.scan("const rscWebpackConfig = require('./rscWebpackConfig');").length).to eq(1)
    end

    it "recognizes a whitespace-spaced server require and inserts the RSC import" do
      config_path = "config/webpack/ServerClientOrBoth.js"
      spaced = server_client_or_both_content(destructured_import: false)
               .sub("const serverWebpackConfig = require('./serverWebpackConfig');",
                    "const serverWebpackConfig = require( './serverWebpackConfig' );")
      simulate_existing_file(config_path, spaced)

      generator.send(:update_server_client_or_both_for_rsc)

      result = File.read(File.join(destination_root, config_path))
      expect(result).to include("const rscWebpackConfig = require('./rscWebpackConfig');")
      # Inserted immediately after the (spaced) server import, not elsewhere.
      expect(result).to match(
        %r{require\(\s*'\./serverWebpackConfig'\s*\);\nconst rscWebpackConfig = require\('\./rscWebpackConfig'\);}
      )
    end

    it "bails (no corruption) when the default-bundle result array has an incidental second match" do
      config_path = "config/webpack/ServerClientOrBoth.js"
      # A customized file with an extra `result = [clientConfig, serverConfig]`
      # elsewhere. gsub_file would rewrite BOTH; replace_single_match must bail so
      # nothing is corrupted, and the verifier surfaces the un-applied transform.
      doubled = server_client_or_both_content(destructured_import: true)
                .sub("  let result;",
                     "  let result;\n  result = [clientConfig, serverConfig]; // incidental")
      simulate_existing_file(config_path, doubled)

      generator.send(:update_server_client_or_both_for_rsc)

      result = File.read(File.join(destination_root, config_path))
      # Neither 2-element array was rewritten to the 3-element RSC-aware form.
      expect(result.scan("result = [clientConfig, serverConfig, rscConfig]").length).to eq(0)
      expect(result.scan(/result\s*=\s*\[clientConfig, serverConfig\]/).length).to eq(2)
      # The un-applied transform is surfaced, not silently masked.
      missing = generator.send(:check_rsc_scob_config)
      expect(missing).to include("RSC-aware default result array in ServerClientOrBoth.js")
    end
  end

  # TypeScript variant — only tests file extension behavior (.tsx vs .jsx).
  # Webpack transforms are TypeScript-agnostic and covered by the main context above.

  # Unit tests for using_rspack? on RscGenerator specifically.
  # RscGenerator does not declare --rspack, so options[:rspack] is always nil and
  # rspack_configured_in_project? (YAML detection) is the only real code path.
  # Integration tests above exercise this end-to-end; these unit tests make the
  # detection logic explicit on the class that actually uses it.

  describe "#using_rspack?" do
    context "when shakapacker.yml has assets_bundler: rspack" do
      let(:generator) { described_class.new }

      before do
        prepare_destination
        simulate_rspack_shakapacker_yml
        allow(generator).to receive(:destination_root).and_return(destination_root)
      end

      it "returns true via YAML fallback (no --rspack option available on RscGenerator)" do
        expect(generator.send(:using_rspack?)).to be true
      end
    end

    context "when no shakapacker.yml exists" do
      let(:generator) { described_class.new }

      before do
        prepare_destination
        allow(generator).to receive(:destination_root).and_return(destination_root)
      end

      it "returns false" do
        expect(generator.send(:using_rspack?)).to be false
      end
    end
  end

  context "when Pro is installed with --typescript" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
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
      assert_file "app/javascript/src/HelloServer/components/LikeButton.tsx"
      assert_no_file "app/javascript/src/HelloServer/ror_components/HelloServer.jsx"
    end
  end
end

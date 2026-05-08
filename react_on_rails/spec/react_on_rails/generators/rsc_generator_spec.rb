# frozen_string_literal: true

require_relative "../support/generator_spec_helper"

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

    it "creates RSC webpack config" do
      assert_file "config/webpack/rscWebpackConfig.js" do |content|
        expect(content).to include("rscConfig")
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
        expect(content).to include("bin/shakapacker-watch --watch")
      end
    end

    describe "webpack config transforms" do
      it "adds RSCWebpackPlugin to serverWebpackConfig" do
        assert_file "config/webpack/serverWebpackConfig.js" do |content|
          expect(content).to include("RSCWebpackPlugin")
          expect(content).to include("react-on-rails-rsc/WebpackPlugin")
          expect(content).to include("clientReferences: rscClientReferences")
          expect(content).to include("directory: resolve(config.source_path)")
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
          expect(content).to include("directory: resolve(config.source_path)")
          expect(content).to include("isServer: false")
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
            "clientConfig.plugins.push(new RSCWebpackPlugin({ isServer: false, chunkName: 'client' }));\n\n  return clientConfig;"
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

  context "when an existing RSC webpack config has custom import anchors" do
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

    it "does not rewrite the plugin when the helper setup cannot be inserted" do
      assert_file "config/webpack/clientWebpackConfig.js" do |content|
        expect(content).not_to include("clientReferences: rscClientReferences")
        expect(content).not_to include("const rscClientReferences")
        expect(content).to include("new RSCWebpackPlugin({ isServer: false })")
      end

      expect(GeneratorMessages.messages.join("\n")).to include("scoped clientReferences in clientWebpackConfig.js")
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

      expect(GeneratorMessages.messages.join("\n")).to include("already defines clientReferences")
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
        expect(content).to match(/^\s*isServer: false, clientReferences: rscClientReferences/)
      end
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

      expect(GeneratorMessages.messages.join("\n")).to include("required imports ('path'/'shakapacker')")
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

      expect(GeneratorMessages.messages.join("\n")).to include("required imports ('path'/'shakapacker')")
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
      it "adds RSCWebpackPlugin to serverWebpackConfig" do
        assert_file "config/rspack/serverWebpackConfig.js" do |content|
          expect(content).to include("RSCWebpackPlugin")
          expect(content).to include("react-on-rails-rsc/WebpackPlugin")
          expect(content).to include("clientReferences: rscClientReferences")
          expect(content).to include("directory: resolve(config.source_path)")
          expect(content).to include("isServer: true")
        end
      end

      it "adds rscBundle parameter to configureServer" do
        assert_file "config/rspack/serverWebpackConfig.js" do |content|
          expect(content).to match(/configureServer\s*=\s*\(rscBundle\s*=\s*false\)/)
        end
      end

      it "adds RSCWebpackPlugin to clientWebpackConfig" do
        assert_file "config/rspack/clientWebpackConfig.js" do |content|
          expect(content).to include("RSCWebpackPlugin")
          expect(content).to include("clientReferences: rscClientReferences")
          expect(content).to include("directory: resolve(config.source_path)")
          expect(content).to include("isServer: false")
        end
      end

      it "adds RSC handling to ServerClientOrBoth" do
        assert_file "config/rspack/ServerClientOrBoth.js" do |content|
          expect(content).to include("rscWebpackConfig")
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

      it "rscWebpackConfig.js aliases react-dom/server to false for RSC bundle" do
        assert_file "config/rspack/rscWebpackConfig.js" do |content|
          expect(content).to include("'react-dom/server': false")
        end
      end

      it "rscWebpackConfig.js adds RSC WebpackLoader to the loader chain" do
        assert_file "config/rspack/rscWebpackConfig.js" do |content|
          expect(content).to include("react-on-rails-rsc/WebpackLoader")
        end
      end

      it "rscWebpackConfig.js passes true to skip RSCWebpackPlugin in RSC bundle" do
        assert_file "config/rspack/rscWebpackConfig.js" do |content|
          expect(content).to include("serverWebpackConfig(true)")
          expect(content).not_to match(/new\s+RSCWebpackPlugin/)
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

      it "serverWebpackConfig.js conditionally skips RSCWebpackPlugin when rscBundle is true" do
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

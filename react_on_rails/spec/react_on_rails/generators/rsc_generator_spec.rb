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

  context "when Pro is installed with a compatible legacy hello_world layout" do
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
      simulate_compatible_auto_registration_layout("hello_world")

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

  context "when Pro is installed with a compatible custom HelloWorld layout" do
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
      simulate_compatible_auto_registration_layout("marketing")

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
      simulate_compatible_auto_registration_layout("marketing")

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

  context "when Pro is installed with an incompatible hello_world layout" do
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
      simulate_incompatible_pack_named_layout("hello_world")

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    include_examples "rsc_hello_server_files"

    it "creates a compatible react_on_rails_default layout instead of reusing hello_world by name alone" do
      assert_file "app/views/layouts/react_on_rails_default.html.erb" do |content|
        expect(content).to include("<%= stylesheet_pack_tag %>")
        expect(content).to include("<%= javascript_pack_tag %>")
      end

      assert_file "app/views/layouts/hello_world.html.erb" do |content|
        expect(content).to include('<%= stylesheet_pack_tag "application" %>')
        expect(content).to include('<%= javascript_pack_tag "application" %>')
      end
    end
  end

  context "when Pro is installed with an incompatible react_on_rails_default layout" do
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
      simulate_incompatible_pack_named_layout("react_on_rails_default")

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    include_examples "rsc_hello_server_files", "react_on_rails_rsc"

    it "creates a dedicated compatible layout without overwriting the incompatible react_on_rails_default file" do
      assert_file "app/views/layouts/react_on_rails_rsc.html.erb" do |content|
        expect(content).to include("<%= stylesheet_pack_tag %>")
        expect(content).to include("<%= javascript_pack_tag %>")
      end

      assert_file "app/views/layouts/react_on_rails_default.html.erb" do |content|
        expect(content).to include('<%= stylesheet_pack_tag "application" %>')
        expect(content).to include('<%= javascript_pack_tag "application" %>')
      end
    end
  end

  context "when Pro is installed and a compatible react_on_rails_rsc layout already exists" do
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
      simulate_incompatible_pack_named_layout("hello_world")
      simulate_compatible_auto_registration_layout("react_on_rails_rsc")

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
          expect(content).to include("new RSCWebpackPlugin({ isServer: false })")
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

# frozen_string_literal: true

require_relative "../support/generator_spec_helper"

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
      allow(Bundler).to receive(:with_unbundled_env).and_yield
      allow(Open3).to receive(:capture2e).with("bundle add react_on_rails_pro --strict")
                                         .and_return(["", instance_double(Process::Status, success?: false)])
    end

    specify "missing_pro_gem? returns true with standalone error message" do
      expect(generator.send(:missing_pro_gem?, force: true)).to be true
      expect(Bundler).to have_received(:with_unbundled_env)
      expect(Open3).to have_received(:capture2e).with("bundle add react_on_rails_pro --strict")
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
      simulate_npm_files(package_json: true)
      # Simulate base React on Rails installed
      simulate_existing_file("config/initializers/react_on_rails.rb", "ReactOnRails.configure {}")
      # Simulate Procfile.dev exists for appending
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      # Simulate base webpack configs (what base install generates without --pro)
      simulate_base_webpack_files
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

  context "when server webpack has only libraryTarget uncommented" do
    before do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails.rb", "ReactOnRails.configure {}")
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      simulate_base_webpack_files
      allow(Gem).to receive(:loaded_specs).and_return({ "react_on_rails_pro" => double })

      server_webpack_path = File.join(destination_root, "config/webpack/serverWebpackConfig.js")
      partially_updated_content = File.read(server_webpack_path)
                                      .sub("// libraryTarget: 'commonjs2',", "libraryTarget: 'commonjs2',")
      File.write(server_webpack_path, partially_updated_content)

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    it "applies remaining Pro transforms instead of skipping as fully configured" do
      assert_file "config/webpack/serverWebpackConfig.js" do |content|
        expect(content).to include("function extractLoader")
        expect(content).to include("babelLoader.options.caller = { ssr: true };")
        expect(content).to include("serverWebpackConfig.target = 'node';")
        expect(content).to include("serverWebpackConfig.node = false;")
        expect(content).to include("module.exports = {")
      end

      assert_file "config/webpack/ServerClientOrBoth.js" do |content|
        expect(content).to include("{ default: serverWebpackConfig }")
      end
    end
  end

  # Rspack variant — verifies that standalone Pro generator writes to config/rspack/
  # when it detects an existing rspack project via config/shakapacker.yml.
  # ProGenerator has no --rspack option; detection is via rspack_configured_in_project?.
  # Uses before (not before(:all)) to allow mocking the Pro gem check.

  # Unit tests for using_rspack? on ProGenerator specifically.
  # ProGenerator does not declare --rspack, so options[:rspack] is always nil and
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
        allow(Gem).to receive(:loaded_specs).and_return({ "react_on_rails_pro" => double })
      end

      it "returns true via YAML fallback (no --rspack option available on ProGenerator)" do
        expect(generator.send(:using_rspack?)).to be true
      end
    end

    context "when no shakapacker.yml exists" do
      let(:generator) { described_class.new }

      before do
        prepare_destination
        allow(generator).to receive(:destination_root).and_return(destination_root)
        allow(Gem).to receive(:loaded_specs).and_return({ "react_on_rails_pro" => double })
      end

      it "returns false" do
        expect(generator.send(:using_rspack?)).to be false
      end
    end
  end

  context "when prerequisites are met on an existing rspack project" do
    before do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/initializers/react_on_rails.rb", "ReactOnRails.configure {}")
      simulate_existing_file("Procfile.dev", "rails: bin/rails s\n")
      # simulate_rspack_base_webpack_files also creates the rspack shakapacker.yml
      # so rspack_configured_in_project? returns true (no --rspack flag available)
      simulate_rspack_base_webpack_files
      allow(Gem).to receive(:loaded_specs).and_return({ "react_on_rails_pro" => double })

      Dir.chdir(destination_root) do
        run_generator(["--force"])
      end
    end

    describe "Pro webpack config transforms in config/rspack/" do
      it "applies Pro transforms to serverWebpackConfig in config/rspack/" do
        assert_file "config/rspack/serverWebpackConfig.js" do |content|
          expect(content).to include("libraryTarget: 'commonjs2',")
          expect(content).to include("function extractLoader")
          expect(content).to include("serverWebpackConfig.target = 'node';")
          expect(content).to include("module.exports = {")
        end
      end

      it "updates ServerClientOrBoth.js to destructured import in config/rspack/" do
        assert_file "config/rspack/ServerClientOrBoth.js" do |content|
          expect(content).to include("{ default: serverWebpackConfig }")
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative "../support/generator_spec_helper"
require_relative "../support/version_test_helpers"
describe InstallGenerator, type: :generator do
  include GeneratorSpec::TestCase

  destination File.expand_path("../dummy-for-generators", __dir__)

  context "without args" do
    before(:all) { run_generator_test_with_args(%w[], package_json: true) }

    include_examples "base_generator", application_js: true
    include_examples "no_redux_generator"
  end

  context "with --redux" do
    before(:all) { run_generator_test_with_args(%w[--redux], package_json: true) }

    include_examples "base_generator_common", application_js: true
    include_examples "react_with_redux_generator"
  end

  context "with -R" do
    before(:all) { run_generator_test_with_args(%w[-R], package_json: true) }

    include_examples "base_generator_common", application_js: true
    include_examples "react_with_redux_generator"
  end

  context "with --typescript" do
    before(:all) { run_generator_test_with_args(%w[--typescript], package_json: true) }

    include_examples "base_generator_common", application_js: true
    include_examples "no_redux_generator"

    it "creates TypeScript component files with .tsx extension" do
      assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx"
      assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.server.tsx"
    end

    it "creates tsconfig.json file" do
      assert_file "tsconfig.json" do |content|
        config = JSON.parse(content)
        expect(config["compilerOptions"]["jsx"]).to eq("react-jsx")
        expect(config["compilerOptions"]["strict"]).to be true
        expect(config["include"]).to include("app/javascript/**/*")
      end
    end

    it "TypeScript component includes proper typing" do
      assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx" do |content|
        expect(content).to match(/interface HelloWorldProps/)
        expect(content).to match(/React\.FC<HelloWorldProps>/)
        expect(content).to match(/onChange=\{.*e.*=>.*setName\(e\.target\.value\).*\}/)
      end
    end
  end

  context "with -T" do
    before(:all) { run_generator_test_with_args(%w[-T], package_json: true) }

    include_examples "base_generator_common", application_js: true
    include_examples "no_redux_generator"

    it "creates TypeScript component files with .tsx extension" do
      assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx"
      assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.server.tsx"
    end
  end

  context "with --redux --typescript" do
    before(:all) { run_generator_test_with_args(%w[--redux --typescript], package_json: true) }

    include_examples "base_generator_common", application_js: true

    it "creates redux directories" do
      assert_directory "app/javascript/src/HelloWorldApp/ror_components"
      %w[actions constants containers reducers store].each do |dir|
        assert_directory("app/javascript/src/HelloWorldApp/#{dir}")
      end
    end

    it "creates appropriate templates" do
      assert_file("app/views/hello_world/index.html.erb") do |contents|
        expect(contents).to match(/"HelloWorldApp"/)
      end
    end

    it "copies base redux TypeScript files" do
      %w[app/javascript/src/HelloWorldApp/actions/helloWorldActionCreators.ts
         app/javascript/src/HelloWorldApp/containers/HelloWorldContainer.ts
         app/javascript/src/HelloWorldApp/constants/helloWorldConstants.ts
         app/javascript/src/HelloWorldApp/reducers/helloWorldReducer.ts
         app/javascript/src/HelloWorldApp/store/helloWorldStore.ts
         app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.client.tsx
         app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.server.tsx].each { |file| assert_file(file) }
    end

    it "creates TypeScript Redux component files" do
      assert_file "app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.client.tsx"
      assert_file "app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.server.tsx"
      assert_file "app/javascript/src/HelloWorldApp/components/HelloWorld.tsx"
    end

    it "TypeScript Redux component includes proper typing" do
      assert_file "app/javascript/src/HelloWorldApp/components/HelloWorld.tsx" do |content|
        expect(content).to match(/type HelloWorldProps = PropsFromRedux/)
        expect(content).to match(/React\.FC<HelloWorldProps>/)
      end
    end

    it "TypeScript Redux App includes proper typing" do
      assert_file "app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.client.tsx" do |content|
        expect(content).to match(/interface HelloWorldAppProps/)
        expect(content).to match(/FC<HelloWorldAppProps>/)
      end
    end
  end

  context "without existing application.js or application.js.coffee file" do
    before(:all) { run_generator_test_with_args([], application_js: false, package_json: true) }

    include_examples "base_generator", application_js: false
  end

  context "with existing application.js or application.js.coffee file" do
    before(:all) { run_generator_test_with_args([], application_js: true, package_json: true) }

    include_examples "base_generator", application_js: true
  end

  context "with rails_helper" do
    before(:all) { run_generator_test_with_args([], spec: true, package_json: true) }

    it "adds ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)" do
      expected = ReactOnRails::Generators::BaseGenerator::CONFIGURE_RSPEC_TO_COMPILE_ASSETS
      assert_file("spec/rails_helper.rb") { |contents| expect(contents).to match(expected) }
    end
  end

  context "with --rspack" do
    before(:all) { run_generator_test_with_args(%w[--rspack], package_json: true) }

    include_examples "base_generator", application_js: true
    include_examples "no_redux_generator"

    it "creates bin/switch-bundler script" do
      assert_file "bin/switch-bundler" do |content|
        expect(content).to include("class BundlerSwitcher")
        expect(content).to include("RSPACK_DEPS")
        expect(content).to include("WEBPACK_DEPS")
      end
    end

    it "installs rspack dependencies in package.json" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        expect(package_json["dependencies"]).to include("@rspack/core")
        expect(package_json["dependencies"]).to include("rspack-manifest-plugin")
        expect(package_json["devDependencies"]).to include("@rspack/cli")
        expect(package_json["devDependencies"]).to include("@rspack/plugin-react-refresh")
      end
    end

    it "does not install webpack-specific dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        expect(package_json["dependencies"]).not_to include("webpack")
        expect(package_json["devDependencies"]).not_to include("webpack-cli")
        expect(package_json["devDependencies"]).not_to include("@pmmmwh/react-refresh-webpack-plugin")
      end
    end

    it "generates unified webpack config with bundler detection" do
      assert_file "config/webpack/development.js" do |content|
        expect(content).to include("const { devServer, inliningCss, config } = require('shakapacker')")
        expect(content).to include("if (config.assets_bundler === 'rspack')")
        expect(content).to include("@rspack/plugin-react-refresh")
        expect(content).to include("@pmmmwh/react-refresh-webpack-plugin")
      end
    end

    it "generates server webpack config with bundler variable" do
      assert_file "config/webpack/serverWebpackConfig.js" do |content|
        expect(content).to include("const bundler = config.assets_bundler === 'rspack'")
        expect(content).to include("? require('@rspack/core')")
        expect(content).to include(": require('webpack')")
        expect(content).to include("new bundler.optimize.LimitChunkCountPlugin")
      end
    end
  end

  context "with --rspack --typescript" do
    before(:all) { run_generator_test_with_args(%w[--rspack --typescript], package_json: true) }

    include_examples "base_generator_common", application_js: true
    include_examples "no_redux_generator"

    it "creates TypeScript component files with .tsx extension" do
      assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx"
      assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.server.tsx"
    end

    it "creates tsconfig.json file" do
      assert_file "tsconfig.json" do |content|
        config = JSON.parse(content)
        expect(config["compilerOptions"]["jsx"]).to eq("react-jsx")
        expect(config["compilerOptions"]["strict"]).to be true
        expect(config["include"]).to include("app/javascript/**/*")
      end
    end

    it "installs both rspack and typescript dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        # Rspack dependencies
        expect(package_json["dependencies"]).to include("@rspack/core")
        expect(package_json["devDependencies"]).to include("@rspack/cli")
        # TypeScript dependencies
        expect(package_json["devDependencies"]).to include("typescript")
        expect(package_json["devDependencies"]).to include("@types/react")
        expect(package_json["devDependencies"]).to include("@types/react-dom")
      end
    end

    it "TypeScript component includes proper typing" do
      assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx" do |content|
        expect(content).to match(/interface HelloWorldProps/)
        expect(content).to match(/React\.FC<HelloWorldProps>/)
      end
    end
  end

  context "with helpful message" do
    let(:expected) do
      GeneratorMessages.format_info(GeneratorMessages.helpful_message_after_installation)
    end

    before do
      # Clear any previous messages to ensure clean test state
      GeneratorMessages.clear
      # Mock Shakapacker installation to succeed so we get the success message
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("bin/shakapacker").and_return(true)
      allow(File).to receive(:exist?).with("bin/shakapacker-dev-server").and_return(true)
    end

    specify "base generator contains a helpful message" do
      run_generator_test_with_args(%w[], package_json: true)
      # Check that the success message is present (flexible matching)
      output_text = GeneratorMessages.output.join("\n")
      expect(output_text).to include("🎉 React on Rails Successfully Installed!")
      expect(output_text).to include("📋 QUICK START:")
      expect(output_text).to include("✨ KEY FEATURES:")
      expect(output_text).to match(/bundle && (npm|yarn|pnpm) install/)
      expect(output_text).to include("💡 TIP: Run 'bin/dev help'")
    end

    specify "react with redux generator contains a helpful message" do
      run_generator_test_with_args(%w[--redux], package_json: true)
      # Check that the success message is present (flexible matching)
      output_text = GeneratorMessages.output.join("\n")
      expect(output_text).to include("🎉 React on Rails Successfully Installed!")
      expect(output_text).to include("📋 QUICK START:")
      expect(output_text).to include("✨ KEY FEATURES:")
      expect(output_text).to match(/bundle && (npm|yarn|pnpm) install/)
      expect(output_text).to include("💡 TIP: Run 'bin/dev help'")
    end
  end

  context "when detecting existing bin-files on *nix" do
    let(:install_generator) { described_class.new }

    specify "when node is exist" do
      stub_const("RUBY_PLATFORM", "linux")
      allow(install_generator).to receive(:`).with("which node").and_return("/path/to/bin")
      allow(install_generator).to receive(:`).with("node --version 2>/dev/null").and_return("v20.0.0")
      expect(install_generator.send(:missing_node?)).to be false
    end
  end

  context "when detecting missing bin-files on *nix" do
    let(:install_generator) { described_class.new }

    specify "when node is missing" do
      stub_const("RUBY_PLATFORM", "linux")
      allow(install_generator).to receive(:`).with("which node").and_return("")
      expect(install_generator.send(:missing_node?)).to be true
    end
  end

  context "when detecting existing bin-files on windows" do
    let(:install_generator) { described_class.new }

    specify "when node is exist" do
      stub_const("RUBY_PLATFORM", "mswin")
      allow(install_generator).to receive(:`).with("where node").and_return("/path/to/bin")
      allow(install_generator).to receive(:`).with("node --version 2>/dev/null").and_return("v20.0.0")
      expect(install_generator.send(:missing_node?)).to be false
    end
  end

  context "when detecting missing bin-files on windows" do
    let(:install_generator) { described_class.new }

    specify "when node is missing" do
      stub_const("RUBY_PLATFORM", "mswin")
      allow(install_generator).to receive(:`).with("where node").and_return("")
      expect(install_generator.send(:missing_node?)).to be true
    end
  end
end

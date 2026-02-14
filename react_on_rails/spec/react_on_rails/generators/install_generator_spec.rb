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

    it "installs appropriate transpiler dependencies based on Shakapacker version" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        # This test verifies the generator adapts to the Shakapacker version in the current environment.
        # CI runs with both minimum (Shakapacker 8.x) and latest (Shakapacker 9.x) configurations,
        # so this test validates correct behavior for whichever version is installed.
        # SWC is the default transpiler for Shakapacker 9.3.0+; Babel is the default for older versions.
        swc_is_default = ReactOnRails::PackerUtils.shakapacker_version_requirement_met?("9.3.0")

        if swc_is_default
          expect(package_json["devDependencies"]).to include("@swc/core")
          expect(package_json["devDependencies"]).to include("swc-loader")
        else
          # For older Shakapacker versions, SWC is NOT installed by default
          # (Babel is the default, but we don't install Babel deps since Shakapacker handles it)
          expect(package_json["devDependencies"]).not_to include("@swc/core")
        end
      end
    end
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

  context "when Shakapacker was pre-installed" do
    # Tests behavior when Shakapacker was already installed before running react_on_rails:install.
    # Uses --skip so template() preserves the pre-existing shakapacker.yml,
    # while gsub_file patchers (configure_precompile_hook) still run on it.
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)

      # Simulate Shakapacker being already installed (config files pre-exist)
      # with a shakapacker.yml with the default Shakapacker format (precompile_hook commented out)
      simulate_existing_file("config/shakapacker.yml", <<~YAML)
        # Note: You must restart bin/shakapacker-dev-server for changes to take effect
        default: &default
          source_path: app/javascript
          source_entry_path: packs
          public_root_path: public
          public_output_path: packs
          cache_path: tmp/shakapacker
          webpack_compile_output: true
          shakapacker_precompile: true
          additional_paths: []
          cache_manifest: false
          assets_bundler: "webpack"
          # Example: precompile_hook: 'bin/shakapacker-precompile-hook'
          # precompile_hook: ~

        development:
          <<: *default

        test:
          <<: *default
          compile: true

        production:
          <<: *default
      YAML
      simulate_existing_file("bin/shakapacker", "")
      simulate_existing_file("bin/shakapacker-dev-server", "")
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS

      Dir.chdir(destination_root) do
        run_generator(["--ignore-warnings", "--skip"])
      end
    end

    it "configures precompile_hook in shakapacker.yml" do
      assert_file "config/shakapacker.yml" do |content|
        # The commented placeholder should be replaced with the actual value
        expect(content).to include("precompile_hook: 'bin/shakapacker-precompile-hook'")
        # The example comment should be preserved
        expect(content).to include("# Example: precompile_hook:")
        # The old commented-out line should be gone
        expect(content).not_to match(/^\s*#\s*precompile_hook:\s*~/)
      end
    end

    it "preserves other shakapacker.yml settings and comments" do
      assert_file "config/shakapacker.yml" do |content|
        # Comments should be preserved
        expect(content).to include("# Note: You must restart bin/shakapacker-dev-server")
        # YAML anchors should be preserved
        expect(content).to include("default: &default")
        expect(content).to include("<<: *default")
        # Other settings should be preserved
        expect(content).to include("source_path: app/javascript")
        expect(content).to include("assets_bundler: \"webpack\"")
      end
    end
  end

  # Regression test for https://github.com/shakacode/react_on_rails/issues/2289
  # When Shakapacker is freshly installed by the generator, the RoR template must be applied
  # (with force: true) so that version-conditional settings like private_output_path are configured.
  context "when Shakapacker was just installed (regression #2289)" do
    before(:all) do
      run_generator_test_with_args(%w[--shakapacker-just-installed], package_json: true) do
        # Simulate Shakapacker's installer having created its default config
        # with private_output_path commented out (the bug scenario)
        simulate_existing_file("config/shakapacker.yml", <<~YAML)
          default: &default
            source_path: app/javascript
            source_entry_path: packs
            # private_output_path: ssr-generated
            # precompile_hook: ~

          development:
            <<: *default

          test:
            <<: *default
            compile: true

          production:
            <<: *default
        YAML
        simulate_existing_file("bin/shakapacker", "")
        simulate_existing_file("bin/shakapacker-dev-server", "")
        simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
          const { generateWebpackConfig } = require('shakapacker')
          const webpackConfig = generateWebpackConfig()
          module.exports = webpackConfig
        JS
      end
    end

    it "uncomments private_output_path for Shakapacker 9+" do
      unless ReactOnRails::PackerUtils.shakapacker_version_requirement_met?("9.0.0")
        skip "Only applies to Shakapacker 9+"
      end

      assert_file "config/shakapacker.yml" do |content|
        expect(content).to match(/^\s+private_output_path: ssr-generated/)
        expect(content).not_to match(/^\s+#\s*private_output_path/)
      end
    end

    it "applies the full RoR template (not Shakapacker's default)" do
      assert_file "config/shakapacker.yml" do |content|
        # RoR's template includes precompile_hook configured (not commented)
        expect(content).to include("precompile_hook: 'bin/shakapacker-precompile-hook'")
        # RoR's template includes nested_entries
        expect(content).to include("nested_entries: true")
      end
    end
  end

  describe "copy_packer_config force behavior" do
    let(:destination) { File.expand_path("../dummy-for-generators", __dir__) }

    before do
      # Ensure destination exists and has a shakapacker.yml to trigger conflict
      FileUtils.mkdir_p(File.join(destination, "config"))
      File.write(File.join(destination, "config/shakapacker.yml"), "existing: config\n")
    end

    it "passes force: true when shakapacker_just_installed is true" do
      gen = BaseGenerator.new([], { shakapacker_just_installed: true, force: false },
                              { destination_root: destination })
      allow(gen).to receive(:template)
      allow(gen).to receive(:configure_rspack_in_shakapacker)
      allow(gen).to receive(:configure_precompile_hook_in_shakapacker)

      gen.copy_packer_config

      expect(gen).to have_received(:template)
        .with("base/base/config/shakapacker.yml.tt", "config/shakapacker.yml", force: true)
    end

    it "calls template without force when shakapacker_just_installed is false" do
      gen = BaseGenerator.new([], { shakapacker_just_installed: false, force: false },
                              { destination_root: destination })
      allow(gen).to receive(:template)
      allow(gen).to receive(:configure_rspack_in_shakapacker)
      allow(gen).to receive(:configure_precompile_hook_in_shakapacker)

      gen.copy_packer_config

      expect(gen).to have_received(:template)
        .with("base/base/config/shakapacker.yml.tt", "config/shakapacker.yml")
    end
  end

  context "with --rspack" do
    # Uses --skip so template() preserves the pre-existing shakapacker.yml,
    # while gsub_file patchers (configure_rspack_in_shakapacker) still run on it.
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)

      # Simulate Shakapacker being already installed (config files pre-exist)
      # This allows testing that configure_rspack_in_shakapacker properly updates the config
      simulate_existing_file("config/shakapacker.yml", <<~YAML)
        # Note: You must restart bin/shakapacker-dev-server for changes to take effect
        default: &default
          source_path: app/javascript
          source_entry_path: packs
          public_root_path: public
          public_output_path: packs
          cache_path: tmp/shakapacker
          webpack_compile_output: true
          shakapacker_precompile: true
          additional_paths: []
          cache_manifest: false
          javascript_transpiler: "babel"
          assets_bundler: "webpack"
          # precompile_hook: ~

        development:
          <<: *default

        test:
          <<: *default
          compile: true

        production:
          <<: *default
      YAML
      simulate_existing_file("bin/shakapacker", "")
      simulate_existing_file("bin/shakapacker-dev-server", "")
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

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

    it "configures rspack in shakapacker.yml" do
      assert_file "config/shakapacker.yml" do |content|
        # Should have rspack as the bundler (inherited by all environments via YAML anchor)
        expect(content).to include("assets_bundler: rspack")
        # Should not have webpack as the bundler
        expect(content).not_to match(/assets_bundler:\s*["']?webpack["']?/)
        # Should use swc loader (rspack works best with SWC)
        expect(content).to include("javascript_transpiler: swc")
        expect(content).not_to match(/javascript_transpiler:\s*["']?babel["']?/)
      end
    end

    it "preserves YAML structure in shakapacker.yml" do
      assert_file "config/shakapacker.yml" do |content|
        # YAML anchors should be preserved
        expect(content).to include("default: &default")
        expect(content).to include("<<: *default")
        # Comments should be preserved
        expect(content).to include("# Note: You must restart")
      end
    end
  end

  context "with --rspack --typescript" do
    # Uses --skip so template() preserves the pre-existing shakapacker.yml,
    # while gsub_file patchers (configure_rspack_in_shakapacker) still run on it.
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)

      # Simulate Shakapacker being already installed (config files pre-exist)
      simulate_existing_file("config/shakapacker.yml", <<~YAML)
        # Note: You must restart bin/shakapacker-dev-server for changes to take effect
        default: &default
          source_path: app/javascript
          source_entry_path: packs
          javascript_transpiler: "babel"
          assets_bundler: "webpack"
          # precompile_hook: ~

        development:
          <<: *default

        test:
          <<: *default
          compile: true

        production:
          <<: *default
      YAML
      simulate_existing_file("bin/shakapacker", "")
      simulate_existing_file("bin/shakapacker-dev-server", "")
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--typescript", "--ignore-warnings", "--skip"])
      end
    end

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

  # Regression test for https://github.com/shakacode/react_on_rails/issues/2287
  # Bundler subprocess commands must run in unbundled environment to prevent
  # BUNDLE_GEMFILE inheritance from parent process
  describe "bundler environment isolation" do
    let(:install_generator) { described_class.new }

    it "clears BUNDLE_GEMFILE when running bundle add" do
      allow(install_generator).to receive(:shakapacker_in_gemfile?).and_return(false)
      allow(install_generator).to receive(:system).with("bundle add shakapacker --strict").and_return(true)

      expect(Bundler).to receive(:with_unbundled_env).and_yield

      install_generator.send(:ensure_shakapacker_in_gemfile)
    end

    it "clears BUNDLE_GEMFILE when running bundle install and shakapacker:install" do
      # Verify both system calls run inside with_unbundled_env
      allow(Bundler).to receive(:with_unbundled_env).and_yield
      allow(install_generator).to receive(:system).with("bundle install").and_return(true)
      allow(install_generator).to receive(:system).with("bundle exec rails shakapacker:install").and_return(true)

      install_generator.send(:install_shakapacker)

      expect(install_generator).to have_received(:system).with("bundle install")
      expect(install_generator).to have_received(:system).with("bundle exec rails shakapacker:install")
      expect(Bundler).to have_received(:with_unbundled_env).at_least(:twice)
    end

    context "with fake BUNDLE_GEMFILE set" do
      around do |example|
        original_gemfile = ENV.fetch("BUNDLE_GEMFILE", nil)
        example.run
      ensure
        if original_gemfile
          ENV["BUNDLE_GEMFILE"] = original_gemfile
        else
          ENV.delete("BUNDLE_GEMFILE")
        end
      end

      it "Bundler.with_unbundled_env clears BUNDLE_GEMFILE in block" do
        ENV["BUNDLE_GEMFILE"] = "/fake/parent/Gemfile"

        bundler_env_in_block = nil
        Bundler.with_unbundled_env do
          bundler_env_in_block = ENV.fetch("BUNDLE_GEMFILE", nil)
        end

        expect(bundler_env_in_block).to be_nil
      end

      it "checks local Gemfile regardless of BUNDLE_GEMFILE env var" do
        ENV["BUNDLE_GEMFILE"] = "/some/other/project/Gemfile"

        # The method should check "Gemfile" not ENV["BUNDLE_GEMFILE"]
        # We verify this by checking it does NOT try to access the env var path
        allow(File).to receive(:file?).with("Gemfile").and_return(false)
        allow(File).to receive(:file?).with("/some/other/project/Gemfile").and_return(true)

        result = install_generator.send(:shakapacker_in_gemfile_text?, "shakapacker")

        # If it checked ENV["BUNDLE_GEMFILE"], it would find the file and continue
        # Since we return false for "Gemfile", the result should be false
        expect(result).to be false
      end

      it "checks local Gemfile.lock regardless of BUNDLE_GEMFILE env var" do
        ENV["BUNDLE_GEMFILE"] = "/some/other/project/Gemfile"

        # The method should check "Gemfile.lock" not derived from ENV["BUNDLE_GEMFILE"]
        allow(File).to receive(:file?).with("Gemfile.lock").and_return(false)
        allow(File).to receive(:file?).with("/some/other/project/Gemfile.lock").and_return(true)

        result = install_generator.send(:shakapacker_in_lockfile?, "shakapacker")

        # If it derived path from ENV["BUNDLE_GEMFILE"], it would find the file
        # Since we return false for "Gemfile.lock", the result should be false
        expect(result).to be false
      end
    end
  end
end

# frozen_string_literal: true

require_relative "../support/generator_spec_helper"
require_relative "../support/version_test_helpers"
describe InstallGenerator, type: :generator do
  include GeneratorSpec::TestCase

  destination File.expand_path("../dummy-for-generators", __dir__)

  def base_generator_fixture(options = {})
    ReactOnRails::Generators::BaseGenerator.new([], options, destination_root: destination_root)
  end

  def render_stock_webpack_template(template_path, options = {})
    base_generator_fixture(options).send(:rendered_template_for_cleanup, template_path)
  end

  def simulate_managed_stock_webpack_files(options = {})
    # MANAGED_WEBPACK_FILE_TEMPLATES is private_constant; this fixture helper
    # intentionally introspects it so tests track managed-file coverage.
    managed_template_map = ReactOnRails::Generators::BaseGenerator.const_get(:MANAGED_WEBPACK_FILE_TEMPLATES)
    managed_template_map.each do |filename, template_path|
      simulate_existing_file("config/webpack/#{filename}", render_stock_webpack_template(template_path, options))
    end
  end

  context "without args" do
    before(:all) { run_generator_test_with_args(%w[], package_json: true) }

    include_examples "base_generator", application_js: true
    include_examples "no_redux_generator"

    it "sets DEFAULT_ROUTE to hello_world in bin/dev" do
      assert_file "bin/dev" do |content|
        expect(content).to include('DEFAULT_ROUTE = "hello_world"')
      end
    end

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
          # (Babel is the default, and babel.config.js requires @babel/preset-react)
          expect(package_json["devDependencies"]).not_to include("@swc/core")
          expect(package_json["devDependencies"]).to include("@babel/preset-react")
        end
      end
    end

    it "enables build_test_command by default" do
      assert_file "config/initializers/react_on_rails.rb" do |content|
        expect(content).to include('config.build_test_command = "RAILS_ENV=test bin/shakapacker"')
      end
    end

    it "sets shakapacker test compile to false by default" do
      assert_file "config/shakapacker.yml" do |content|
        expect(content).to match(/^test:.*?^\s+compile:\s*false/m)
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

  context "with minitest test_helper and no rspec files" do
    before(:all) do
      run_generator_test_with_args([], spec: false, package_json: true) do
        simulate_existing_file("test/test_helper.rb", <<~RUBY)
          ENV["RAILS_ENV"] ||= "test"
          require_relative "../config/environment"
          require "rails/test_help"

          class ActiveSupport::TestCase
          end
        RUBY
      end
    end

    it "adds ReactOnRails::TestHelper.ensure_assets_compiled for minitest" do
      expected = ReactOnRails::Generators::BaseGenerator::CONFIGURE_MINITEST_TO_COMPILE_ASSETS
      assert_file("test/test_helper.rb") { |contents| expect(contents).to match(expected) }
    end
  end

  context "with both rspec and minitest helpers present" do
    before(:all) do
      run_generator_test_with_args([], spec: true, package_json: true) do
        simulate_existing_file("test/test_helper.rb", <<~RUBY)
          ENV["RAILS_ENV"] ||= "test"
          require_relative "../config/environment"
          require "rails/test_help"

          class ActiveSupport::TestCase
          end
        RUBY
      end
    end

    it "adds ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config) for rspec" do
      expected = ReactOnRails::Generators::BaseGenerator::CONFIGURE_RSPEC_TO_COMPILE_ASSETS
      assert_file("spec/rails_helper.rb") { |contents| expect(contents).to match(expected) }
    end

    it "adds ReactOnRails::TestHelper.ensure_assets_compiled for minitest" do
      expected = ReactOnRails::Generators::BaseGenerator::CONFIGURE_MINITEST_TO_COMPILE_ASSETS
      assert_file("test/test_helper.rb") { |contents| expect(contents).to match(expected) }
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
          # private_output_path: ssr-generated
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

    it "configures private_output_path for SSR bundles on Shakapacker 9+" do
      assert_file "config/shakapacker.yml" do |content|
        if ReactOnRails::PackerUtils.shakapacker_version_requirement_met?("9.0.0")
          expect(content).to include("private_output_path: ssr-generated")
          expect(content).not_to match(/^\s*#\s*private_output_path:/)
        else
          expect(content).to match(/^\s*#\s*private_output_path:/)
        end
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

  context "when shakapacker.yml already has private_output_path key without a value" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)

      simulate_existing_file("config/shakapacker.yml", <<~YAML)
        default: &default
          source_path: app/javascript
          source_entry_path: packs
          public_output_path: packs
          private_output_path:
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
        run_generator(["--ignore-warnings", "--skip"])
      end
    end

    it "does not insert duplicate private_output_path entries" do
      skip "private_output_path requires Shakapacker >= 9.0.0" unless
        ReactOnRails::PackerUtils.shakapacker_version_requirement_met?("9.0.0")

      assert_file "config/shakapacker.yml" do |content|
        expect(content.scan(/^\s*private_output_path:/).size).to eq(1)
      end
    end
  end

  # Regression test for https://github.com/shakacode/react_on_rails/issues/2289
  # When Shakapacker is freshly installed by the generator, the RoR template must be applied
  # (with force: true) so that version-conditional settings like private_output_path are configured.
  context "when Shakapacker was just installed (regression #2289)" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)

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

      Dir.chdir(destination_root) do
        # Run without --force: the fix must work via --shakapacker-just-installed alone,
        # not rely on the global --force flag overwriting all conflicting files.
        run_generator(["--shakapacker-just-installed", "--ignore-warnings"])
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

    it "generates unified rspack config with bundler detection" do
      assert_file "config/rspack/development.js" do |content|
        expect(content).to include("const { devServer, inliningCss, config } = require('shakapacker')")
        expect(content).to include("if (config.assets_bundler === 'rspack')")
        expect(content).to include("@rspack/plugin-react-refresh")
        expect(content).to include("@pmmmwh/react-refresh-webpack-plugin")
      end
    end

    it "generates server rspack config with bundler variable" do
      assert_file "config/rspack/serverWebpackConfig.js" do |content|
        expect(content).to include("const bundler = config.assets_bundler === 'rspack'")
        expect(content).to include("? require('@rspack/core')")
        expect(content).to include(": require('webpack')")
        expect(content).to include("new bundler.optimize.LimitChunkCountPlugin")
      end
    end

    it "writes the main rspack config to config/rspack/rspack.config.js" do
      assert_file "config/rspack/rspack.config.js" do |content|
        expect(content).to include("const envSpecificConfig = () =>")
        expect(content).to include("const path = resolve(__dirname, `${env.nodeEnv}.js`)")
      end
    end

    it "removes stale stock config/webpack files after switching to rspack" do
      expect(File).not_to exist(File.join(destination_root, "config/webpack"))
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

    it "adds private_output_path on Shakapacker 9+ when missing" do
      assert_file "config/shakapacker.yml" do |content|
        if ReactOnRails::PackerUtils.shakapacker_version_requirement_met?("9.0.0")
          expect(content).to include("private_output_path: ssr-generated")
        end
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

  shared_context "with webpack to rspack migration base" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)
      simulate_existing_file("config/shakapacker.yml", <<~YAML)
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
    end
  end

  context "with --rspack and custom webpack files" do
    include_context "with webpack to rspack migration base"

    before(:all) do
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS
      simulate_existing_file("config/webpack/custom-banner.js", "module.exports = { custom: true };\n")

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

    it "keeps config/webpack when custom files are detected" do
      assert_file "config/webpack/custom-banner.js"
      assert_file "config/rspack/rspack.config.js"
    end
  end

  context "with --rspack and dotfiles in config/webpack" do
    include_context "with webpack to rspack migration base"

    before(:all) do
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS
      simulate_existing_file("config/webpack/.gitkeep", "")

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

    it "removes stale managed files but keeps config/webpack when dotfiles are present" do
      assert_file "config/webpack/.gitkeep"
      assert_no_file "config/webpack/webpack.config.js"
      assert_file "config/rspack/rspack.config.js"
    end
  end

  context "with --rspack and empty config/webpack directory" do
    include_context "with webpack to rspack migration base"

    before(:all) do
      FileUtils.mkdir_p(File.join(destination_root, "config/webpack"))

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

    it "keeps config/webpack when directory is empty" do
      assert_directory "config/webpack"
      assert_file "config/rspack/rspack.config.js"
    end
  end

  context "with --rspack and full managed stock webpack files" do
    include_context "with webpack to rspack migration base"

    before(:all) do
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS
      simulate_managed_stock_webpack_files

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

    it "removes config/webpack when only managed stock files are present" do
      expect(File).not_to exist(File.join(destination_root, "config/webpack"))
      assert_file "config/rspack/rspack.config.js"
    end
  end

  context "with --rspack and symlinked webpack entries" do
    include_context "with webpack to rspack migration base"

    before(:all) do
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS

      symlink_target = File.join(destination_root, "tmp/clientWebpackConfig.js")
      FileUtils.mkdir_p(File.dirname(symlink_target))
      File.write(
        symlink_target,
        render_stock_webpack_template("base/base/config/webpack/clientWebpackConfig.js.tt")
      )
      File.symlink(symlink_target, File.join(destination_root, "config/webpack/clientWebpackConfig.js"))

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

    it "keeps config/webpack when symlink entries are present" do
      assert_directory "config/webpack"
      expect(File.symlink?(File.join(destination_root, "config/webpack/clientWebpackConfig.js"))).to be(true)
      assert_file "config/rspack/rspack.config.js"
    end
  end

  context "with --rspack and nested config/webpack directory" do
    include_context "with webpack to rspack migration base"

    before(:all) do
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS
      simulate_existing_file("config/webpack/custom/.keep", "")

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

    it "keeps config/webpack when nested directories are present" do
      assert_file "config/webpack/custom/.keep"
      assert_file "config/rspack/rspack.config.js"
    end
  end

  context "with --rspack and customized webpack.config.js only" do
    include_context "with webpack to rspack migration base"

    before(:all) do
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { env } = require('shakapacker')
        const { existsSync } = require('fs')
        const { resolve } = require('path')

        const envSpecificConfig = () => {
          const path = resolve(__dirname, `${env.nodeEnv}.js`)
          if (existsSync(path)) return require(path)
          throw new Error(`Could not find file to load ${path}`)
        }

        const config = envSpecificConfig()
        config.resolve = config.resolve || {}
        module.exports = config
      JS

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

    it "keeps config/webpack when webpack.config.js is customized" do
      assert_file "config/webpack/webpack.config.js"
      assert_file "config/rspack/rspack.config.js"
    end
  end

  context "with --rspack and comment-only notes in webpack.config.js" do
    include_context "with webpack to rspack migration base"

    before(:all) do
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        // Team note: keep webpack fallback while validating rspack migration.
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

    it "keeps config/webpack when files include comment-only customizations" do
      assert_file "config/webpack/webpack.config.js"
      assert_file "config/rspack/rspack.config.js"
    end
  end

  context "with --rspack and legacy generateWebpackConfigs.js" do
    include_context "with webpack to rspack migration base"

    before(:all) do
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS
      # Render from the current template so fixture content stays in sync with generator output.
      simulate_existing_file(
        "config/webpack/generateWebpackConfigs.js",
        render_stock_webpack_template("base/base/config/webpack/ServerClientOrBoth.js.tt")
      )

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

    it "removes legacy generateWebpackConfigs.js along with stale config/webpack directory" do
      expect(File).not_to exist(File.join(destination_root, "config/webpack"))
      assert_file "config/rspack/rspack.config.js"
    end
  end

  context "with --rspack and legacy generateWebpackConfigs.js generated with --rsc" do
    include_context "with webpack to rspack migration base"

    before(:all) do
      simulate_existing_file("config/webpack/webpack.config.js", <<~JS)
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS
      simulate_existing_file("config/webpack/generateWebpackConfigs.js", <<~JS)
        const clientWebpackConfig = require('./clientWebpackConfig');
        const serverWebpackConfig = require('./serverWebpackConfig');
        const rscWebpackConfig = require('./rscWebpackConfig');

        const serverClientOrBoth = (envSpecific) => {
          const clientConfig = clientWebpackConfig();
          const serverConfig = serverWebpackConfig();
          const rscConfig = rscWebpackConfig();
          if (envSpecific) envSpecific(clientConfig, serverConfig, rscConfig);
          return [clientConfig, serverConfig, rscConfig];
        };

        module.exports = serverClientOrBoth;
      JS

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

    it "keeps config/webpack when legacy content no longer matches current options" do
      assert_file "config/webpack/generateWebpackConfigs.js"
      assert_file "config/rspack/rspack.config.js"
    end
  end

  context "with --rsc app switching from webpack to rspack" do
    include_context "with webpack to rspack migration base"

    before(:all) do
      simulate_existing_file(
        "config/webpack/webpack.config.js",
        render_stock_webpack_template("base/base/config/webpack/webpack.config.js.tt", rsc: true)
      )
      simulate_existing_file(
        "config/webpack/rscWebpackConfig.js",
        render_stock_webpack_template("rsc/base/config/webpack/rscWebpackConfig.js.tt", rsc: true)
      )

      Dir.chdir(destination_root) do
        run_generator(["--rsc", "--rspack", "--ignore-warnings", "--skip"])
      end
    end

    it "removes stale stock config/webpack files including rscWebpackConfig.js" do
      assert_no_file "config/webpack"
      assert_file "config/rspack/rspack.config.js"
      assert_file "config/rspack/rscWebpackConfig.js"
    end
  end

  # Tests a fresh rspack install where Shakapacker was installed directly with rspack
  # (no prior webpack config). This exercises different code paths than "with --rspack":
  # - shakapacker_config_file_exists? falls through to the rspack branches (lines 333-334)
  # - copy_webpack_main_config finds the existing stock rspack config and auto-replaces it
  # - configure_rspack_in_shakapacker is a no-op (already rspack)
  context "with --rspack and pre-existing rspack config (fresh rspack install)" do
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)

      # Simulate Shakapacker installed directly with SHAKAPACKER_ASSETS_BUNDLER=rspack.
      # No config/webpack/ directory exists — only config/rspack/.
      simulate_existing_file("config/shakapacker.yml", <<~YAML)
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
          javascript_transpiler: "swc"
          assets_bundler: "rspack"
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
      # Stock rspack config — exact content from Shakapacker 9.4.0
      simulate_existing_file("config/rspack/rspack.config.js", <<~JS)
        // See the shakacode/shakapacker README and docs directory for advice on customizing your rspackConfig.
        const { generateRspackConfig } = require('shakapacker/rspack')

        const rspackConfig = generateRspackConfig()

        module.exports = rspackConfig
      JS

      Dir.chdir(destination_root) do
        run_generator(["--rspack", "--ignore-warnings", "--skip"])
      end
    end

    include_examples "base_generator", application_js: true
    include_examples "no_redux_generator"

    it "auto-replaces stock rspack config with React on Rails environment loader" do
      assert_file "config/rspack/rspack.config.js" do |content|
        expect(content).to include("const envSpecificConfig = () =>")
        expect(content).not_to include("generateRspackConfig")
      end
    end

    it "generates all bundler configs in config/rspack/" do
      %w[serverWebpackConfig.js clientWebpackConfig.js commonWebpackConfig.js
         ServerClientOrBoth.js development.js production.js test.js].each do |file|
        assert_file "config/rspack/#{file}"
      end
    end

    it "does not create any config/webpack/ files" do
      assert_no_file "config/webpack/webpack.config.js"
      assert_no_file "config/webpack/serverWebpackConfig.js"
      assert_no_file "config/webpack/clientWebpackConfig.js"
    end

    it "preserves rspack bundler setting in shakapacker.yml" do
      assert_file "config/shakapacker.yml" do |content|
        expect(content).to include("assets_bundler: \"rspack\"")
        expect(content).not_to match(/assets_bundler:\s*["']?webpack["']?/)
      end
    end

    it "installs rspack dependencies in package.json" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        expect(package_json["dependencies"]).to include("@rspack/core")
        expect(package_json["dependencies"]).to include("rspack-manifest-plugin")
        expect(package_json["devDependencies"]).to include("@rspack/cli")
      end
    end

    it "does not install webpack-specific dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        expect(package_json["dependencies"]).not_to include("webpack")
        expect(package_json["devDependencies"]).not_to include("webpack-cli")
      end
    end
  end

  context "with --rspack --redux" do
    # Uses --skip so template() preserves the pre-existing shakapacker.yml,
    # while gsub_file patchers (configure_rspack_in_shakapacker) still run on it.
    before(:all) do
      prepare_destination
      simulate_existing_rails_files(package_json: true)
      simulate_npm_files(package_json: true)

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
        run_generator(["--rspack", "--redux", "--ignore-warnings", "--skip"])
      end
    end

    include_examples "base_generator_common", application_js: true
    include_examples "react_with_redux_generator"

    it "installs both Rspack and Redux dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        deps = package_json["dependencies"] || {}
        expect(deps).to include("@rspack/core")
        expect(deps).to include("redux")
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

  context "with --pro" do
    before(:all) { run_generator_test_with_args(%w[--pro], package_json: true) }

    include_examples "base_generator", application_js: true
    include_examples "no_redux_generator"

    it "creates Pro initializer with NodeRenderer configuration" do
      assert_file "config/initializers/react_on_rails_pro.rb" do |content|
        expect(content).to include("ReactOnRailsPro.configure")
        expect(content).to include('config.server_renderer = "NodeRenderer"')
        expect(content).to include("config.renderer_url")
        expect(content).to include("config.renderer_password")
        expect(content).to include("config.ssr_timeout")
      end
    end

    it "creates node-renderer.js bootstrap file" do
      assert_file "client/node-renderer.js" do |content|
        expect(content).to include("reactOnRailsProNodeRenderer")
        expect(content).to include("require('react-on-rails-pro-node-renderer')")
        expect(content).to include("serverBundleCachePath")
        expect(content).to include("port:")
        expect(content).to include("password:")
        expect(content).to include("workersCount:")
      end
    end

    it "adds node-renderer process to Procfile.dev" do
      assert_file "Procfile.dev" do |content|
        expect(content).to include("node-renderer:")
        expect(content).to include("RENDERER_PORT=3800")
        expect(content).to include("node client/node-renderer.js")
      end
    end

    it "installs Pro npm dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        deps = package_json["dependencies"] || {}
        expect(deps).to include("react-on-rails-pro")
        expect(deps).to include("react-on-rails-pro-node-renderer")
      end
    end

    it "serverWebpackConfig includes Pro features" do
      assert_file "config/webpack/serverWebpackConfig.js" do |content|
        expect(content).to include("libraryTarget: 'commonjs2',")
        expect(content).to include("function extractLoader")
        expect(content).to include("serverWebpackConfig.target = 'node'")
      end
    end

    it "Pro initializer does not include RSC configuration" do
      assert_file "config/initializers/react_on_rails_pro.rb" do |content|
        expect(content).not_to include("enable_rsc_support")
        expect(content).not_to include("rsc_bundle_js_file")
      end
    end
  end

  context "with --pro --redux" do
    before(:all) { run_generator_test_with_args(%w[--pro --redux], package_json: true) }

    include_examples "base_generator_common", application_js: true
    include_examples "react_with_redux_generator"
    include_examples "pro_common_files"

    it "installs both Pro and Redux dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        deps = package_json["dependencies"] || {}
        expect(deps).to include("react-on-rails-pro")
        expect(deps).to include("redux")
      end
    end
  end

  context "with --pro --typescript" do
    before(:all) { run_generator_test_with_args(%w[--pro --typescript], package_json: true) }

    include_examples "base_generator_common", application_js: true
    include_examples "no_redux_generator"
    include_examples "pro_common_files"

    it "creates TypeScript component files with .tsx extension" do
      assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.tsx"
      assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.server.tsx"
    end

    it "creates tsconfig.json file" do
      assert_file "tsconfig.json" do |content|
        config = JSON.parse(content)
        expect(config["compilerOptions"]["jsx"]).to eq("react-jsx")
      end
    end

    it "installs both Pro and TypeScript dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        deps = package_json["dependencies"] || {}
        dev_deps = package_json["devDependencies"] || {}
        expect(deps).to include("react-on-rails-pro")
        expect(dev_deps).to include("typescript")
        expect(dev_deps).to include("@types/react")
      end
    end
  end

  context "with --pro --rspack" do
    before(:all) do
      run_generator_test_with_args(%w[--pro --rspack], package_json: true) do
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
      end
    end

    include_examples "base_generator", application_js: true
    include_examples "no_redux_generator"
    include_examples "pro_common_files"

    it "installs both Pro and Rspack dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        deps = package_json["dependencies"] || {}
        expect(deps).to include("react-on-rails-pro")
        expect(deps).to include("@rspack/core")
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

      it "updates ServerClientOrBoth to destructured import in config/rspack/" do
        assert_file "config/rspack/ServerClientOrBoth.js" do |content|
          expect(content).to include("{ default: serverWebpackConfig }")
        end
      end
    end
  end

  context "when Pro initializer already exists" do
    before(:all) do
      run_generator_test_with_args(%w[--pro], package_json: true) do
        simulate_existing_file("config/initializers/react_on_rails_pro.rb", "# existing Pro config\n")
      end
    end

    it "does not overwrite existing Pro initializer" do
      assert_file "config/initializers/react_on_rails_pro.rb" do |content|
        expect(content).to include("# existing Pro config")
        expect(content).not_to include("ReactOnRailsPro.configure")
      end
    end
  end

  context "when node-renderer.js already exists" do
    before(:all) do
      run_generator_test_with_args(%w[--pro], package_json: true) do
        simulate_existing_dir("client")
        simulate_existing_file("client/node-renderer.js", "// existing node-renderer\n")
      end
    end

    it "does not overwrite existing node-renderer.js" do
      assert_file "client/node-renderer.js" do |content|
        expect(content).to include("// existing node-renderer")
        expect(content).not_to include("reactOnRailsProNodeRenderer")
      end
    end
  end

  context "when Procfile.dev already contains node-renderer" do
    let(:install_generator) { described_class.new([], { pro: true }) }

    before do
      allow(install_generator).to receive(:destination_root).and_return("/fake/path")
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("/fake/path/Procfile.dev").and_return(true)
      allow(File).to receive(:read).with("/fake/path/Procfile.dev")
                                   .and_return("rails: bundle exec rails s\nnode-renderer: existing config\n")
    end

    specify "add_pro_to_procfile does not append duplicate entry" do
      expect(install_generator).not_to receive(:append_to_file)
      install_generator.send(:add_pro_to_procfile)
    end
  end

  context "when Procfile.dev exists without node-renderer" do
    let(:install_generator) { described_class.new([], { pro: true }) }

    before do
      allow(install_generator).to receive(:destination_root).and_return("/fake/path")
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("/fake/path/Procfile.dev").and_return(true)
      allow(File).to receive(:read).with("/fake/path/Procfile.dev")
                                   .and_return("rails: bundle exec rails s\ndev-server: bin/shakapacker\n")
    end

    specify "add_pro_to_procfile appends node-renderer entry" do
      expect(install_generator).to receive(:append_to_file).with("Procfile.dev", include("node-renderer:"))
      install_generator.send(:add_pro_to_procfile)
    end
  end

  context "with --rsc" do
    before(:all) { run_generator_test_with_args(%w[--rsc], package_json: true) }

    include_examples "rsc_common_files"

    it "creates node-renderer.js" do
      assert_file "client/node-renderer.js" do |content|
        expect(content).to include("reactOnRailsProNodeRenderer")
        expect(content).to include("require('react-on-rails-pro-node-renderer')")
      end
    end

    it "adds RSC bundle watcher to Procfile.dev" do
      assert_file "Procfile.dev" do |content|
        expect(content).to include("RSC_BUNDLE_ONLY=yes")
        expect(content).to include("rsc-bundle:")
      end
    end

    it "installs RSC npm dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        deps = package_json["dependencies"] || {}
        expect(deps).to include("react-on-rails-pro")
        expect(deps).to include("react-on-rails-pro-node-renderer")
        expect(deps).to include("react-on-rails-rsc")
      end
    end

    it "creates rscWebpackConfig.js" do
      assert_file "config/webpack/rscWebpackConfig.js" do |content|
        expect(content).to include("const serverWebpackModule = require('./serverWebpackConfig')")
        expect(content).to include("const serverWebpackConfig = serverWebpackModule.default || serverWebpackModule")
        expect(content).to include("serverWebpackConfig(true)")
        expect(content).to include("rsc-bundle")
        expect(content).to include("react-server")
      end
    end

    it "serverWebpackConfig includes RSCWebpackPlugin import" do
      assert_file "config/webpack/serverWebpackConfig.js" do |content|
        expect(content).to include("RSCWebpackPlugin")
        expect(content).to include("react-on-rails-rsc/WebpackPlugin")
      end
    end

    it "serverWebpackConfig has rscBundle parameter" do
      assert_file "config/webpack/serverWebpackConfig.js" do |content|
        expect(content).to match(/configureServer\s*=\s*\(rscBundle\s*=\s*false\)/)
        expect(content).to include("if (!rscBundle)")
      end
    end

    it "creates HelloServer instead of HelloWorld (controller, route, and components)" do
      # HelloWorld should NOT exist - HelloServer replaces it entirely
      assert_no_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.jsx"
      assert_no_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.server.jsx"
      assert_no_file "app/controllers/hello_world_controller.rb"
      assert_file "config/routes.rb" do |content|
        expect(content).not_to include("hello_world")
      end

      # HelloServer should exist
      assert_file "app/javascript/src/HelloServer/ror_components/HelloServer.jsx"
      assert_file "app/javascript/src/HelloServer/components/HelloServer.jsx"
      assert_file "app/javascript/src/HelloServer/components/LikeButton.jsx"
    end

    include_examples "rsc_hello_server_files"

    it "adds HelloServer route" do
      assert_file "config/routes.rb" do |content|
        expect(content).to include("hello_server")
        expect(content).to include("rsc_payload")
      end
    end

    it "sets DEFAULT_ROUTE to hello_server in bin/dev" do
      assert_file "bin/dev" do |content|
        expect(content).to include('DEFAULT_ROUTE = "hello_server"')
      end
    end
  end

  context "with --rsc --redux" do
    before(:all) { run_generator_test_with_args(%w[--rsc --redux], package_json: true) }

    include_examples "react_with_redux_generator"
    include_examples "rsc_common_files"

    it "creates both HelloWorldApp and HelloServer" do
      assert_file "app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.client.jsx"
      assert_file "app/javascript/src/HelloWorldApp/ror_components/HelloWorldApp.server.jsx"
      assert_file "app/javascript/src/HelloServer/ror_components/HelloServer.jsx"
      assert_file "app/javascript/src/HelloServer/components/HelloServer.jsx"
      assert_file "app/javascript/src/HelloServer/components/LikeButton.jsx"
    end

    it "creates hello_world route and controller for Redux" do
      assert_file "config/routes.rb" do |content|
        expect(content).to include("hello_world")
      end
      assert_file "app/controllers/hello_world_controller.rb"
    end

    it "installs both RSC and Redux dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        deps = package_json["dependencies"] || {}
        expect(deps).to include("react-on-rails-rsc")
        expect(deps).to include("redux")
      end
    end

    include_examples "rsc_hello_server_files"
  end

  context "with --rsc --typescript" do
    before(:all) { run_generator_test_with_args(%w[--rsc --typescript], package_json: true) }

    include_examples "rsc_common_files"

    it "creates TypeScript HelloServer component" do
      assert_no_file "app/javascript/src/HelloServer/ror_components/HelloServer.jsx"
      assert_no_file "app/javascript/src/HelloServer/components/HelloServer.jsx"
      assert_file "app/javascript/src/HelloServer/ror_components/HelloServer.tsx"
      assert_file "app/javascript/src/HelloServer/components/HelloServer.tsx"
      assert_file "app/javascript/src/HelloServer/components/LikeButton.tsx"
    end

    it "creates tsconfig.json file" do
      assert_file "tsconfig.json" do |content|
        config = JSON.parse(content)
        expect(config["compilerOptions"]["jsx"]).to eq("react-jsx")
      end
    end

    it "installs both RSC and TypeScript dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        deps = package_json["dependencies"] || {}
        dev_deps = package_json["devDependencies"] || {}
        expect(deps).to include("react-on-rails-rsc")
        expect(dev_deps).to include("typescript")
        expect(dev_deps).to include("@types/react")
      end
    end

    include_examples "rsc_hello_server_files"
  end

  context "with --rsc --rspack" do
    before(:all) { run_generator_test_with_args(%w[--rsc --rspack], package_json: true) }

    include_examples "rsc_common_files"

    it "creates rscWebpackConfig.js in config/rspack/ (not config/webpack/)" do
      assert_file "config/rspack/rscWebpackConfig.js" do |content|
        expect(content).to include("serverWebpackConfig(true)")
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

      it "adds RSCWebpackPlugin to clientWebpackConfig" do
        assert_file "config/rspack/clientWebpackConfig.js" do |content|
          expect(content).to include("RSCWebpackPlugin")
          expect(content).to include("react-on-rails-rsc/WebpackPlugin")
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

    it "installs both RSC and Rspack dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        deps = package_json["dependencies"] || {}
        expect(deps).to include("react-on-rails-rsc")
        expect(deps).to include("@rspack/core")
      end
    end

    include_examples "rsc_hello_server_files"
  end

  context "when rscWebpackConfig.js already exists" do
    before(:all) do
      run_generator_test_with_args(%w[--rsc], package_json: true) do
        simulate_existing_dir("config/webpack")
        simulate_existing_file("config/webpack/rscWebpackConfig.js", "// existing RSC config\n")
      end
    end

    it "does not overwrite existing rscWebpackConfig.js" do
      assert_file "config/webpack/rscWebpackConfig.js" do |content|
        expect(content).to include("// existing RSC config")
        expect(content).not_to include("serverWebpackConfig(true)")
      end
    end
  end

  context "when Procfile.dev already contains RSC watcher" do
    let(:install_generator) { described_class.new([], { rsc: true }) }

    before do
      allow(install_generator).to receive(:destination_root).and_return("/fake/path")
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("/fake/path/Procfile.dev").and_return(true)
      procfile_content = "rails: bundle exec rails s\nrsc-bundle: RSC_BUNDLE_ONLY=yes bin/shakapacker\n"
      allow(File).to receive(:read).with("/fake/path/Procfile.dev").and_return(procfile_content)
    end

    specify "add_rsc_to_procfile does not append duplicate entry" do
      expect(install_generator).not_to receive(:append_to_file)
      install_generator.send(:add_rsc_to_procfile)
    end
  end

  context "with helpful message" do
    before do
      # Clear any previous messages to ensure clean test state
      GeneratorMessages.clear
    end

    specify "base generator contains a helpful message" do
      run_generator_test_with_args(%w[], package_json: true) do
        simulate_existing_file("bin/shakapacker", "")
        simulate_existing_file("bin/shakapacker-dev-server", "")
        simulate_existing_file("config/shakapacker.yml", "default: {}\n")
        simulate_existing_file("config/webpack/webpack.config.js", "// mock webpack config\n")
      end
      # Check that the success message is present (flexible matching)
      output_text = GeneratorMessages.output.join("\n")
      expect(output_text).to include("🎉 React on Rails Successfully Installed!")
      expect(output_text).to include("📋 QUICK START:")
      expect(output_text).to include("✨ KEY FEATURES:")
      expect(output_text).to match(/bundle && (npm|yarn|pnpm) install/)
      expect(output_text).to include("💡 TIP: Run 'bin/dev help'")
    end

    specify "react with redux generator contains a helpful message" do
      run_generator_test_with_args(%w[--redux], package_json: true) do
        simulate_existing_file("bin/shakapacker", "")
        simulate_existing_file("bin/shakapacker-dev-server", "")
        simulate_existing_file("config/shakapacker.yml", "default: {}\n")
        simulate_existing_file("config/webpack/webpack.config.js", "// mock webpack config\n")
      end
      # Check that the success message is present (flexible matching)
      output_text = GeneratorMessages.output.join("\n")
      expect(output_text).to include("🎉 React on Rails Successfully Installed!")
      expect(output_text).to include("📋 QUICK START:")
      expect(output_text).to include("✨ KEY FEATURES:")
      expect(output_text).to match(/bundle && (npm|yarn|pnpm) install/)
      expect(output_text).to include("💡 TIP: Run 'bin/dev help'")
    end

    specify "run_generators adds post-install messaging for redux installs" do
      install_generator = described_class.new([], { redux: true })
      allow(install_generator).to receive(:installation_prerequisites_met?).and_return(true)
      allow(install_generator).to receive(:invoke_generators)
      allow(install_generator).to receive(:add_bin_scripts)
      allow(install_generator).to receive(:print_generator_messages)

      expect(install_generator).to receive(:add_post_install_message)
      install_generator.run_generators
    end

    specify "shows incomplete-installation guidance when shakapacker setup fails" do
      install_generator = described_class.new
      install_generator.instance_variable_set(:@shakapacker_setup_incomplete, true)

      install_generator.send(:add_post_install_message)
      output_text = GeneratorMessages.output.join("\n")

      expect(output_text).to include("React on Rails installation is incomplete")
      expect(output_text).to include("Avoid running ./bin/dev")
      expect(output_text).to include("Some generator files may have been partially created during this run")
      expect(output_text).to include("clean up your working tree before rerunning")
      expect(output_text).to include("commit, stash, or discard the partial changes")
      expect(output_text).to include("--ignore-warnings")
      expect(output_text).not_to include("🎉 React on Rails Successfully Installed!")
      expect(output_text).not_to include("📋 QUICK START:")
    end

    specify "incomplete-installation guidance uses detected package manager install command" do
      install_generator = described_class.new
      install_generator.instance_variable_set(:@shakapacker_setup_incomplete, true)
      allow(GeneratorMessages).to receive(:detect_package_manager).and_return("pnpm")

      install_generator.send(:add_post_install_message)
      output_text = GeneratorMessages.output.join("\n")

      expect(output_text).to include("pnpm install")
    end

    specify "incomplete-installation guidance preserves original install flags" do
      install_generator = described_class.new([], { redux: true, typescript: true, rspack: true, rsc: true })
      install_generator.instance_variable_set(:@shakapacker_setup_incomplete, true)

      install_generator.send(:add_post_install_message)
      output_text = GeneratorMessages.output.join("\n")

      expect(output_text).to include("rails generate react_on_rails:install --redux --typescript --rspack --rsc")
      expect(output_text).not_to include(
        "rails generate react_on_rails:install --redux --typescript --rspack --rsc --ignore-warnings"
      )
    end

    specify "recovery_install_command keeps meaningful flags only" do
      install_generator = described_class.new(
        [],
        { redux: true, typescript: true, rspack: true, rsc: true, pro: true, ignore_warnings: true,
          force: true, skip: true, pretend: true }
      )

      command = install_generator.send(:recovery_install_command)

      expect(command).to eq("rails generate react_on_rails:install --redux --typescript --rspack --rsc")
      expect(command).not_to include("--ignore-warnings")
      expect(command).not_to include("--force")
      expect(command).not_to include("--skip")
      expect(command).not_to include("--pretend")
      expect(command).not_to include("--pro")
    end

    specify "recovery_install_command includes --pro when requested without --rsc" do
      install_generator = described_class.new([], { pro: true })

      command = install_generator.send(:recovery_install_command)

      expect(command).to eq("rails generate react_on_rails:install --pro")
    end

    specify "shakapacker install error preserves original install flags" do
      install_generator = described_class.new([], { redux: true, typescript: true, ignore_warnings: true })

      install_generator.send(:handle_shakapacker_install_error)
      output_text = GeneratorMessages.output.join("\n")

      expect(output_text).to include("clean up your working tree before rerunning")
      expect(output_text).to include("Re-run: rails generate react_on_rails:install --redux --typescript")
    end

    specify "shakapacker gemfile error preserves original install flags" do
      # ignore_warnings: true is required so handle_shakapacker_gemfile_error logs
      # the error instead of raising Thor::Error, which lets this example inspect output.
      install_generator = described_class.new([], { rspack: true, pro: true, ignore_warnings: true })

      install_generator.send(:handle_shakapacker_gemfile_error)
      output_text = GeneratorMessages.output.join("\n")

      expect(output_text).to include("clean up your working tree before rerunning")
      expect(output_text).to include("Then re-run: rails generate react_on_rails:install --rspack --pro")
    end
  end

  describe "--pretend mode behavior" do
    let(:install_generator) { described_class.new([], { pretend: true }) }
    let(:typescript_install_generator) { described_class.new([], { pretend: true, typescript: true }) }

    it "skips automatic shakapacker installation commands" do
      allow(install_generator).to receive(:shakapacker_configured?).and_return(false)

      expect(install_generator).to receive(:say_status)
        .with(:pretend, "Skipping automatic Shakapacker installation in --pretend mode", :yellow)
      expect(install_generator).not_to receive(:print_shakapacker_setup_banner)
      expect(install_generator).not_to receive(:ensure_shakapacker_in_gemfile)
      expect(install_generator).not_to receive(:install_shakapacker)
      expect(install_generator).not_to receive(:finalize_shakapacker_setup)

      install_generator.send(:ensure_shakapacker_installed)
    end

    it "does not chmod copied bin scripts in pretend mode" do
      allow(install_generator).to receive(:directory)
      allow(install_generator).to receive(:use_rsc?).and_return(false)

      expect(install_generator).to receive(:say_status)
        .with(:pretend, "Skipping chmod on bin scripts in --pretend mode", :yellow)
      expect(Dir).not_to receive(:chdir)
      expect(File).not_to receive(:chmod)

      install_generator.send(:add_bin_scripts)
    end

    it "does not install typescript dependencies in pretend mode" do
      expect(typescript_install_generator).to receive(:say_status)
        .with(:pretend, "Skipping TypeScript dependency installation in --pretend mode", :yellow)
      expect(typescript_install_generator).not_to receive(:add_typescript_dependencies)

      typescript_install_generator.send(:install_typescript_dependencies)
    end

    it "does not set up react dependencies in pretend mode" do
      expect(install_generator).to receive(:say_status)
        .with(:pretend, "Skipping React dependency setup in --pretend mode", :yellow)
      expect(install_generator).not_to receive(:setup_js_dependencies)

      install_generator.send(:setup_react_dependencies)
    end

    it "does not create css module type files in pretend mode" do
      expect(install_generator).to receive(:say_status)
        .with(:pretend, "Skipping CSS module type definitions in --pretend mode", :yellow)
      expect(FileUtils).not_to receive(:mkdir_p)
      expect(File).not_to receive(:write)

      install_generator.send(:create_css_module_types)
    end

    it "does not write tsconfig.json in pretend mode" do
      expect(install_generator).to receive(:say_status)
        .with(:pretend, "Skipping tsconfig.json creation in --pretend mode", :yellow)
      expect(File).not_to receive(:write)

      install_generator.send(:create_typescript_config)
    end

    it "forwards pretend mode to base and react_no_redux generators" do
      allow(install_generator).to receive(:ensure_shakapacker_installed)
      allow(install_generator).to receive(:setup_react_dependencies)
      allow(install_generator).to receive_messages(use_pro?: false, use_rsc?: false)

      expect(install_generator).to receive(:invoke)
        .with("react_on_rails:base", [], hash_including(pretend: true))
      expect(install_generator).to receive(:invoke)
        .with("react_on_rails:react_no_redux", [], hash_including(pretend: true))

      install_generator.send(:invoke_generators)
    end

    it "forwards pretend mode to redux, pro, and rsc generators" do
      redux_pro_rsc_install_generator = described_class.new([], { pretend: true, redux: true, pro: true, rsc: true })

      allow(redux_pro_rsc_install_generator).to receive(:ensure_shakapacker_installed)
      allow(redux_pro_rsc_install_generator).to receive(:setup_react_dependencies)
      allow(redux_pro_rsc_install_generator).to receive_messages(use_pro?: true, use_rsc?: true)

      expect(redux_pro_rsc_install_generator).to receive(:invoke)
        .with("react_on_rails:base", [], hash_including(pretend: true))
      expect(redux_pro_rsc_install_generator).to receive(:invoke)
        .with("react_on_rails:react_with_redux", [], hash_including(pretend: true))
      expect(redux_pro_rsc_install_generator).to receive(:invoke)
        .with("react_on_rails:pro", [], hash_including(pretend: true))
      expect(redux_pro_rsc_install_generator).to receive(:invoke)
        .with("react_on_rails:rsc", [], hash_including(pretend: true))

      redux_pro_rsc_install_generator.send(:invoke_generators)
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

  # Tests for ensure_shakapacker_installed detection path:
  # the config_changed detection and @shakapacker_just_installed assignment in
  # finalize_shakapacker_setup — the runtime path that fires during a real
  # `rails g react_on_rails:install` when Shakapacker wasn't pre-configured.
  describe "ensure_shakapacker_installed detection path" do
    let(:install_generator) { described_class.new }

    before do
      allow(install_generator).to receive(:print_shakapacker_setup_banner)
      allow(install_generator).to receive(:ensure_shakapacker_in_gemfile)
      allow(install_generator).to receive_messages(shakapacker_configured?: false, install_shakapacker: true)
      allow(install_generator).to receive(:puts)
    end

    it "sets @shakapacker_just_installed=true when yml did not exist before install" do
      Dir.mktmpdir do |dir|
        yml_path = File.join(dir, "config/shakapacker.yml")

        allow(install_generator).to receive(:install_shakapacker) do
          # Simulate shakapacker creating the yml from scratch
          FileUtils.mkdir_p(File.dirname(yml_path))
          File.write(yml_path, "new: shakapacker defaults\n")
          true
        end

        Dir.chdir(dir) { install_generator.send(:ensure_shakapacker_installed) }
        expect(install_generator.instance_variable_get(:@shakapacker_just_installed)).to be true
      end
    end

    it "sets @shakapacker_just_installed=true when yml existed but was overwritten (user said y)" do
      Dir.mktmpdir do |dir|
        yml_path = File.join(dir, "config/shakapacker.yml")
        FileUtils.mkdir_p(File.dirname(yml_path))
        File.write(yml_path, "old: content\n")

        allow(install_generator).to receive(:install_shakapacker) do
          File.write(yml_path, "new: shakapacker defaults\n")
          true
        end

        Dir.chdir(dir) { install_generator.send(:ensure_shakapacker_installed) }
        expect(install_generator.instance_variable_get(:@shakapacker_just_installed)).to be true
      end
    end

    it "sets @shakapacker_just_installed=false when yml existed and was preserved (user said n)" do
      Dir.mktmpdir do |dir|
        yml_path = File.join(dir, "config/shakapacker.yml")
        FileUtils.mkdir_p(File.dirname(yml_path))
        File.write(yml_path, "custom: config\n")

        allow(install_generator).to receive(:install_shakapacker).and_return(true)
        Dir.chdir(dir) { install_generator.send(:ensure_shakapacker_installed) }
        expect(install_generator.instance_variable_get(:@shakapacker_just_installed)).to be false
      end
    end

    it "sets @shakapacker_just_installed=false when yml did not exist before or after install (nil→nil)" do
      Dir.mktmpdir do |dir|
        # install_shakapacker returns true but does not write the yml
        allow(install_generator).to receive(:install_shakapacker).and_return(true)
        Dir.chdir(dir) { install_generator.send(:ensure_shakapacker_installed) }
        expect(install_generator.instance_variable_get(:@shakapacker_just_installed)).to be false
      end
    end

    it "does not call finalize_shakapacker_setup when install_shakapacker fails" do
      Dir.mktmpdir do |dir|
        allow(install_generator).to receive(:install_shakapacker).and_return(false)

        Dir.chdir(dir) { install_generator.send(:ensure_shakapacker_installed) }
        expect(install_generator.instance_variable_get(:@shakapacker_just_installed)).to be_nil
        expect(install_generator.instance_variable_get(:@shakapacker_setup_incomplete)).to be true
      end
    end

    it "keeps setup incomplete when adding shakapacker to Gemfile fails, even if install succeeds" do
      Dir.mktmpdir do |dir|
        allow(install_generator).to receive_messages(ensure_shakapacker_in_gemfile: false, install_shakapacker: true)
        allow(install_generator).to receive(:finalize_shakapacker_setup)

        Dir.chdir(dir) { install_generator.send(:ensure_shakapacker_installed) }

        expect(install_generator.instance_variable_get(:@shakapacker_setup_incomplete)).to be true
        expect(install_generator).to have_received(:install_shakapacker)
        expect(install_generator).to have_received(:finalize_shakapacker_setup)
      end
    end
  end

  describe "#shakapacker_configured?" do
    let(:install_generator) { described_class.new }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(install_generator).to receive(:shakapacker_binaries_exist?).and_return(true)
      allow(File).to receive(:exist?).with("config/shakapacker.yml").and_return(true)
    end

    it "returns true when rspack config exists in config/rspack" do
      allow(File).to receive(:exist?).with("config/webpack/webpack.config.js").and_return(false)
      allow(File).to receive(:exist?).with("config/webpack/webpack.config.ts").and_return(false)
      allow(File).to receive(:exist?).with("config/rspack/rspack.config.js").and_return(true)
      allow(File).to receive(:exist?).with("config/rspack/rspack.config.ts").and_return(false)

      expect(install_generator.send(:shakapacker_configured?)).to be true
    end

    it "returns true when webpack TypeScript config exists" do
      allow(File).to receive(:exist?).with("config/webpack/webpack.config.js").and_return(false)
      allow(File).to receive(:exist?).with("config/webpack/webpack.config.ts").and_return(true)

      expect(install_generator.send(:shakapacker_configured?)).to be true
    end

    it "returns true when rspack TypeScript config exists" do
      allow(File).to receive(:exist?).with("config/webpack/webpack.config.js").and_return(false)
      allow(File).to receive(:exist?).with("config/webpack/webpack.config.ts").and_return(false)
      allow(File).to receive(:exist?).with("config/rspack/rspack.config.js").and_return(false)
      allow(File).to receive(:exist?).with("config/rspack/rspack.config.ts").and_return(true)

      expect(install_generator.send(:shakapacker_configured?)).to be true
    end

    it "returns false when no supported bundler config file exists" do
      allow(File).to receive(:exist?).with("config/webpack/webpack.config.js").and_return(false)
      allow(File).to receive(:exist?).with("config/webpack/webpack.config.ts").and_return(false)
      allow(File).to receive(:exist?).with("config/rspack/rspack.config.js").and_return(false)
      allow(File).to receive(:exist?).with("config/rspack/rspack.config.ts").and_return(false)

      expect(install_generator.send(:shakapacker_configured?)).to be false
    end
  end

  describe "#standard_shakapacker_config?" do
    let(:destination) { File.expand_path("../dummy-for-generators", __dir__) }
    let(:generator) { BaseGenerator.new([], {}, { destination_root: destination }) }

    it "recognizes stock webpack config with comments (Shakapacker 9.x)" do
      # Exact content from shakapacker 9.4.0 lib/install/config/webpack/webpack.config.js
      content = <<~JS
        // See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.
        const { generateWebpackConfig } = require('shakapacker')

        const webpackConfig = generateWebpackConfig()

        module.exports = webpackConfig
      JS
      expect(generator.send(:standard_shakapacker_config?, content)).to be true
    end

    it "recognizes stock webpack config without comments" do
      content = <<~JS
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS
      expect(generator.send(:standard_shakapacker_config?, content)).to be true
    end

    it "recognizes stock webpack config with extra comments when comment-insensitive matching is enabled" do
      content = <<~JS
        // team-specific note
        const { generateWebpackConfig } = require('shakapacker')
        const webpackConfig = generateWebpackConfig()
        module.exports = webpackConfig
      JS
      expect(generator.send(:standard_shakapacker_config?, content)).to be false
      expect(generator.send(:standard_shakapacker_config?, content, strip_comments: true)).to be true
    end

    it "recognizes stock rspack config with comments (Shakapacker 9.x)" do
      # Exact content from shakapacker 9.4.0 lib/install/config/rspack/rspack.config.js
      content = <<~JS
        // See the shakacode/shakapacker README and docs directory for advice on customizing your rspackConfig.
        const { generateRspackConfig } = require('shakapacker/rspack')

        const rspackConfig = generateRspackConfig()

        module.exports = rspackConfig
      JS
      expect(generator.send(:standard_shakapacker_config?, content)).to be true
    end

    it "recognizes stock rspack config without comments" do
      content = <<~JS
        const { generateRspackConfig } = require('shakapacker/rspack')
        const rspackConfig = generateRspackConfig()
        module.exports = rspackConfig
      JS
      expect(generator.send(:standard_shakapacker_config?, content)).to be true
    end

    it "rejects custom config with user modifications" do
      content = <<~JS
        const { generateRspackConfig } = require('shakapacker/rspack')
        const rspackConfig = generateRspackConfig()
        rspackConfig.module.rules.push({ test: /\\.svg$/, type: 'asset' })
        module.exports = rspackConfig
      JS
      expect(generator.send(:standard_shakapacker_config?, content)).to be false
    end

    it "rejects React on Rails environment-loader config" do
      content = <<~JS
        const { env } = require('shakapacker')
        const { existsSync } = require('fs')
        const { resolve } = require('path')
        const envSpecificConfig = () => {
          const path = resolve(__dirname, `${env.nodeEnv}.js`)
          if (existsSync(path)) { return require(path) }
          else { throw new Error(`Could not find file to load ${path}`) }
        }
        module.exports = envSpecificConfig()
      JS
      expect(generator.send(:standard_shakapacker_config?, content)).to be false
    end

    it "recognizes stock TypeScript webpack config with type import (Shakapacker 9.4+)" do
      content = <<~TS
        import { generateWebpackConfig } from 'shakapacker'
        import type { Configuration } from 'webpack'
        const webpackConfig: Configuration = generateWebpackConfig()
        export default webpackConfig
      TS
      expect(generator.send(:standard_shakapacker_config?, content)).to be true
    end

    it "recognizes stock TypeScript webpack config without type import" do
      content = <<~TS
        import { generateWebpackConfig } from 'shakapacker'
        const webpackConfig = generateWebpackConfig()
        export default webpackConfig
      TS
      expect(generator.send(:standard_shakapacker_config?, content)).to be true
    end

    it "recognizes stock TypeScript configs with double quotes" do
      content = <<~TS
        import { generateWebpackConfig } from "shakapacker"
        const webpackConfig = generateWebpackConfig()
        export default webpackConfig
      TS
      expect(generator.send(:standard_shakapacker_config?, content)).to be true
    end

    it "recognizes stock TypeScript rspack config with type import (Shakapacker 9.4+)" do
      content = <<~TS
        import { generateRspackConfig } from 'shakapacker/rspack'
        import type { RspackOptions } from '@rspack/core'
        const rspackConfig: RspackOptions = generateRspackConfig()
        export default rspackConfig
      TS
      expect(generator.send(:standard_shakapacker_config?, content)).to be true
    end

    it "recognizes stock TypeScript rspack config without type import" do
      content = <<~TS
        import { generateRspackConfig } from 'shakapacker/rspack'
        const rspackConfig = generateRspackConfig()
        export default rspackConfig
      TS
      expect(generator.send(:standard_shakapacker_config?, content)).to be true
    end

    it "rejects customized TypeScript config with user modifications" do
      content = <<~TS
        import { generateWebpackConfig } from 'shakapacker'
        import type { Configuration } from 'webpack'
        const webpackConfig: Configuration = generateWebpackConfig()
        webpackConfig.resolve!.extensions!.push('.graphql')
        export default webpackConfig
      TS
      expect(generator.send(:standard_shakapacker_config?, content)).to be false
    end
  end

  describe "#bundler_main_config_path" do
    let(:destination) { File.expand_path("../dummy-for-generators", __dir__) }

    context "when using webpack" do
      let(:generator) { BaseGenerator.new([], {}, { destination_root: destination }) }

      it "returns .ts path when TypeScript config exists" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with("config/webpack/webpack.config.ts").and_return(true)
        expect(generator.send(:bundler_main_config_path)).to eq("config/webpack/webpack.config.ts")
      end

      it "returns .js path when no TypeScript config exists" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with("config/webpack/webpack.config.ts").and_return(false)
        expect(generator.send(:bundler_main_config_path)).to eq("config/webpack/webpack.config.js")
      end
    end

    context "when using rspack" do
      let(:generator) { BaseGenerator.new([], { rspack: true }, { destination_root: destination }) }

      it "returns .ts path when TypeScript config exists" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with("config/rspack/rspack.config.ts").and_return(true)
        expect(generator.send(:bundler_main_config_path)).to eq("config/rspack/rspack.config.ts")
      end

      it "returns .js path when no TypeScript config exists" do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with("config/rspack/rspack.config.ts").and_return(false)
        expect(generator.send(:bundler_main_config_path)).to eq("config/rspack/rspack.config.js")
      end
    end
  end

  describe "#copy_webpack_main_config" do
    let(:destination) { File.expand_path("../dummy-for-generators", __dir__) }
    let(:generator) { BaseGenerator.new([], {}, { destination_root: destination }) }

    it "uses TypeScript template when target config path ends with .ts" do
      allow(generator).to receive(:bundler_main_config_path).and_return("config/webpack/webpack.config.ts")
      allow(File).to receive(:exist?).with("config/webpack/webpack.config.ts").and_return(false)
      allow(generator).to receive(:template)

      generator.send(:copy_webpack_main_config, "base/base", {})

      expect(generator).to have_received(:template).with(
        "base/base/config/webpack/webpack.config.ts.tt",
        "config/webpack/webpack.config.ts",
        {}
      )
    end

    it "uses rspack template when target config path is rspack config" do
      allow(generator).to receive(:bundler_main_config_path).and_return("config/rspack/rspack.config.ts")
      allow(File).to receive(:exist?).with("config/rspack/rspack.config.ts").and_return(false)
      allow(generator).to receive(:template)

      generator.send(:copy_webpack_main_config, "base/base", {})

      expect(generator).to have_received(:template).with(
        "base/base/config/webpack/rspack.config.ts.tt",
        "config/rspack/rspack.config.ts",
        {}
      )
    end

    it "replaces existing stock TypeScript webpack config in place" do
      ts_path = "config/webpack/webpack.config.ts"
      ts_template = "base/base/config/webpack/webpack.config.ts.tt"
      stock_ts_config = <<~TS
        import { generateWebpackConfig } from 'shakapacker'
        const webpackConfig = generateWebpackConfig()
        export default webpackConfig
      TS

      allow(generator).to receive(:bundler_main_config_path).and_return(ts_path)
      allow(generator).to receive(:bundler_main_config_template_path).with("base/base", ts_path).and_return(ts_template)
      allow(File).to receive(:exist?).with(ts_path).and_return(true)
      allow(File).to receive(:read).with(ts_path).and_return(stock_ts_config)
      allow(generator).to receive(:standard_shakapacker_config?).with(stock_ts_config,
                                                                      strip_comments: true).and_return(true)
      allow(generator).to receive(:remove_file)
      allow(generator).to receive(:template)

      generator.send(:copy_webpack_main_config, "base/base", {})

      expect(generator).to have_received(:remove_file).with(ts_path, verbose: false)
      expect(generator).to have_received(:template).with(ts_template, ts_path, {})
    end

    it "routes existing custom TypeScript webpack config through custom replacement flow" do
      ts_path = "config/webpack/webpack.config.ts"
      ts_template = "base/base/config/webpack/webpack.config.ts.tt"
      custom_ts_config = <<~TS
        import { generateWebpackConfig } from 'shakapacker'
        const webpackConfig = generateWebpackConfig()
        webpackConfig.resolve?.extensions?.push('.graphql')
        export default webpackConfig
      TS

      allow(generator).to receive(:bundler_main_config_path).and_return(ts_path)
      allow(generator).to receive(:bundler_main_config_template_path).with("base/base", ts_path).and_return(ts_template)
      allow(File).to receive(:exist?).with(ts_path).and_return(true)
      allow(File).to receive(:read).with(ts_path).and_return(custom_ts_config)
      allow(generator).to receive(:standard_shakapacker_config?).with(custom_ts_config,
                                                                      strip_comments: true).and_return(false)
      allow(generator).to receive(:react_on_rails_config?).with(custom_ts_config).and_return(false)
      allow(generator).to receive(:handle_custom_webpack_config)

      generator.send(:copy_webpack_main_config, "base/base", {})

      expect(generator).to have_received(:handle_custom_webpack_config).with("base/base", {}, ts_path)
    end
  end

  describe "TypeScript bundler main config templates" do
    let(:webpack_ts_template_path) do
      File.expand_path(
        "../../../lib/generators/react_on_rails/templates/base/base/config/webpack/webpack.config.ts.tt",
        __dir__
      )
    end
    let(:rspack_ts_template_path) do
      File.expand_path(
        "../../../lib/generators/react_on_rails/templates/base/base/config/webpack/rspack.config.ts.tt",
        __dir__
      )
    end

    it "keeps the webpack TypeScript template compatible with Shakapacker's require-based loader" do
      content = File.read(webpack_ts_template_path)

      expect(content).to include("resolve(__dirname, `${env.nodeEnv}.js`)")
      expect(content).to include("return require(path)")
      expect(content).not_to include("import.meta.url")
      expect(content).not_to include("createRequire")
    end

    it "keeps the rspack TypeScript template compatible with Shakapacker's require-based loader" do
      content = File.read(rspack_ts_template_path)

      expect(content).to include("resolve(__dirname, `${env.nodeEnv}.js`)")
      expect(content).to include("return require(path)")
      expect(content).not_to include("import.meta.url")
      expect(content).not_to include("createRequire")
    end
  end

  describe "#using_rspack?" do
    context "when --rspack option is provided" do
      let(:install_generator) { described_class.new([], { rspack: true }) }

      it "returns true" do
        expect(install_generator.send(:using_rspack?)).to be true
      end
    end

    context "when --rspack is false (default)" do
      let(:install_generator) { described_class.new }

      # InstallGenerator declares --rspack with default: false, so options[:rspack]
      # is false (not nil). using_rspack? returns false via the first branch without
      # reaching the YAML fallback (rspack_configured_in_project?).
      it "returns false" do
        expect(install_generator.send(:using_rspack?)).to be false
      end
    end
  end

  describe "#destination_config_path" do
    context "with --rspack" do
      let(:install_generator) { described_class.new([], { rspack: true }) }

      it "remaps config/webpack/ to config/rspack/" do
        expect(install_generator.send(:destination_config_path, "config/webpack/serverWebpackConfig.js"))
          .to eq("config/rspack/serverWebpackConfig.js")
      end

      it "leaves paths without config/webpack/ unchanged" do
        expect(install_generator.send(:destination_config_path, "app/javascript/packs/server-bundle.js"))
          .to eq("app/javascript/packs/server-bundle.js")
      end
    end

    context "without --rspack" do
      let(:install_generator) { described_class.new }

      it "returns path unchanged" do
        expect(install_generator.send(:destination_config_path, "config/webpack/serverWebpackConfig.js"))
          .to eq("config/webpack/serverWebpackConfig.js")
      end
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
      allow(install_generator).to receive(:system).with({}, "bundle exec rails shakapacker:install").and_return(true)

      install_generator.send(:install_shakapacker)

      expect(install_generator).to have_received(:system).with("bundle install")
      expect(install_generator).to have_received(:system).with({}, "bundle exec rails shakapacker:install")
      expect(Bundler).to have_received(:with_unbundled_env).at_least(:twice)
    end

    it "passes SHAKAPACKER_ASSETS_BUNDLER=rspack to shakapacker:install when --rspack is set" do
      rspack_generator = described_class.new([], { rspack: true })
      allow(Bundler).to receive(:with_unbundled_env).and_yield
      allow(rspack_generator).to receive(:system).with("bundle install").and_return(true)
      allow(rspack_generator).to receive(:system)
        .with({ "SHAKAPACKER_ASSETS_BUNDLER" => "rspack" }, "bundle exec rails shakapacker:install")
        .and_return(true)

      rspack_generator.send(:install_shakapacker)

      expect(rspack_generator).to have_received(:system)
        .with({ "SHAKAPACKER_ASSETS_BUNDLER" => "rspack" }, "bundle exec rails shakapacker:install")
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

  # Pro/RSC prerequisite validation tests

  context "when using --pro flag without Pro gem installed" do
    let(:install_generator) { described_class.new([], { pro: true }) }
    let(:expected_pro_version) { Gem::Version.new(ReactOnRails::VERSION).release.to_s }
    let(:fake_pid) { 12_345 }

    before do
      allow(Gem).to receive(:loaded_specs).and_return({})
      allow(install_generator).to receive(:gem_in_lockfile?).with("react_on_rails_pro").and_return(false)
      allow(Bundler).to receive(:with_unbundled_env).and_yield
      allow(Process).to receive(:spawn).and_return(fake_pid)
      allow(install_generator).to receive(:wait_for_bundle_process)
        .with(fake_pid).and_return(instance_double(Process::Status, success?: false))
    end

    specify "missing_pro_gem? returns true and error mentions --pro flag" do
      expect(install_generator.send(:missing_pro_gem?)).to be true
      expect(Bundler).to have_received(:with_unbundled_env)
      expect(Process).to have_received(:spawn)
      error_text = GeneratorMessages.messages.join("\n")
      expect(error_text).to include("--pro")
      expect(error_text).to include("react_on_rails_pro")
      expect(error_text).to include("~> #{expected_pro_version}")
      expect(error_text).to include("justin@shakacode.com")
    end
  end

  context "when using --rsc flag without Pro gem installed" do
    let(:install_generator) { described_class.new([], { rsc: true }) }
    let(:fake_pid) { 12_345 }

    before do
      allow(Gem).to receive(:loaded_specs).and_return({})
      allow(install_generator).to receive(:gem_in_lockfile?).with("react_on_rails_pro").and_return(false)
      allow(Bundler).to receive(:with_unbundled_env).and_yield
      allow(Process).to receive(:spawn).and_return(fake_pid)
      allow(install_generator).to receive(:wait_for_bundle_process)
        .with(fake_pid).and_return(instance_double(Process::Status, success?: false))
    end

    specify "missing_pro_gem? returns true and error mentions --rsc flag" do
      expect(install_generator.send(:missing_pro_gem?)).to be true
      expect(Bundler).to have_received(:with_unbundled_env)
      expect(Process).to have_received(:spawn)
      error_text = GeneratorMessages.messages.join("\n")
      expect(error_text).to include("--rsc")
    end
  end

  context "when auto-installing Pro gem succeeds" do
    let(:install_generator) { described_class.new([], { pro: true }) }
    let(:fake_pid) { 12_345 }

    before do
      allow(Gem).to receive(:loaded_specs).and_return({})
      allow(install_generator).to receive(:gem_in_lockfile?).with("react_on_rails_pro").and_return(false)
      allow(Bundler).to receive(:with_unbundled_env).and_yield
      allow(Process).to receive(:spawn).and_return(fake_pid)
      allow(install_generator).to receive(:wait_for_bundle_process)
        .with(fake_pid).and_return(instance_double(Process::Status, success?: true))

      # Simulate stale memoized value from an earlier check.
      install_generator.instance_variable_set(:@pro_gem_installed, false)
    end

    specify "missing_pro_gem? marks memoized pro_gem_installed? state as installed" do
      expect(install_generator.send(:missing_pro_gem?)).to be false
      expect(Bundler).to have_received(:with_unbundled_env)
      expect(Process).to have_received(:spawn)
      expect(install_generator.instance_variable_get(:@pro_gem_installed)).to be true
    end
  end

  context "when auto-install times out" do
    let(:install_generator) { described_class.new([], { pro: true }) }
    let(:fake_pid) { 12_345 }

    before do
      allow(Gem).to receive(:loaded_specs).and_return({})
      allow(install_generator).to receive(:gem_in_lockfile?).with("react_on_rails_pro").and_return(false)
      allow(Bundler).to receive(:with_unbundled_env).and_yield
      allow(Process).to receive(:spawn).and_return(fake_pid)
      allow(install_generator).to receive(:wait_for_bundle_process)
        .with(fake_pid).and_return(nil)
    end

    specify "missing_pro_gem? returns true with timeout message" do
      expect(install_generator.send(:missing_pro_gem?)).to be true
    end
  end

  context "when auto-install raises an error" do
    let(:install_generator) { described_class.new([], { pro: true }) }

    before do
      allow(Gem).to receive(:loaded_specs).and_return({})
      allow(install_generator).to receive(:gem_in_lockfile?).with("react_on_rails_pro").and_return(false)
      allow(Bundler).to receive(:with_unbundled_env).and_raise(Errno::ENOENT, "bundle not found")
    end

    specify "missing_pro_gem? returns true and handles error gracefully" do
      expect(install_generator.send(:missing_pro_gem?)).to be true
    end
  end

  context "when using --pro flag with Pro gem in Gem.loaded_specs" do
    let(:install_generator) { described_class.new([], { pro: true }) }

    specify "missing_pro_gem? returns false" do
      allow(Gem).to receive(:loaded_specs).and_return({ "react_on_rails_pro" => double })

      expect(install_generator.send(:missing_pro_gem?)).to be false
    end
  end

  context "when using --pro flag with Pro gem in Gemfile.lock" do
    let(:install_generator) { described_class.new([], { pro: true }) }

    specify "missing_pro_gem? returns false" do
      allow(Gem).to receive(:loaded_specs).and_return({})
      allow(install_generator).to receive(:gem_in_lockfile?).with("react_on_rails_pro").and_return(true)

      expect(install_generator.send(:missing_pro_gem?)).to be false
    end
  end

  context "when not using --pro or --rsc flags" do
    let(:install_generator) { described_class.new }

    specify "missing_pro_gem? returns false without checking gem" do
      expect(install_generator.send(:missing_pro_gem?)).to be false
    end
  end

  # React version detection tests

  context "when package.json has standard React version" do
    let(:install_generator) { described_class.new }

    specify "detect_react_version extracts version" do
      allow(install_generator).to receive(:package_json).and_return({ "dependencies" => { "react" => "19.0.3" } })

      expect(install_generator.send(:detect_react_version)).to eq("19.0.3")
    end
  end

  context "when package.json has React version with caret prefix" do
    let(:install_generator) { described_class.new }

    specify "detect_react_version extracts version without prefix" do
      allow(install_generator).to receive(:package_json).and_return({ "dependencies" => { "react" => "^19.0.3" } })

      expect(install_generator.send(:detect_react_version)).to eq("19.0.3")
    end
  end

  context "when package.json has React as workspace protocol" do
    let(:install_generator) { described_class.new }

    specify "detect_react_version returns nil" do
      allow(install_generator).to receive(:package_json).and_return({ "dependencies" => { "react" => "workspace:*" } })

      expect(install_generator.send(:detect_react_version)).to be_nil
    end
  end

  context "when package.json is not available" do
    let(:install_generator) { described_class.new }

    specify "detect_react_version returns nil" do
      allow(install_generator).to receive(:package_json).and_return(nil)

      expect(install_generator.send(:detect_react_version)).to be_nil
    end
  end

  # RSC React version warning tests

  context "when using --rsc with React 19.0.4" do
    let(:install_generator) { described_class.new([], { rsc: true }) }

    specify "warn_about_react_version_for_rsc does not add warning" do
      allow(install_generator).to receive(:detect_react_version).and_return("19.0.4")

      install_generator.send(:warn_about_react_version_for_rsc)
      expect(GeneratorMessages.messages.join("\n")).not_to include("⚠️")
    end
  end

  context "when using --rsc with React 19.1.0" do
    let(:install_generator) { described_class.new([], { rsc: true }) }

    specify "warn_about_react_version_for_rsc adds version incompatibility warning" do
      allow(install_generator).to receive(:detect_react_version).and_return("19.1.0")

      install_generator.send(:warn_about_react_version_for_rsc)
      warning_text = GeneratorMessages.messages.join("\n")
      expect(warning_text).to include("RSC requires React 19.0.x")
      expect(warning_text).to include("detected: 19.1.0")
    end
  end

  context "when using --rsc with React 18.2.0" do
    let(:install_generator) { described_class.new([], { rsc: true }) }

    specify "warn_about_react_version_for_rsc adds version incompatibility warning" do
      allow(install_generator).to receive(:detect_react_version).and_return("18.2.0")

      install_generator.send(:warn_about_react_version_for_rsc)
      warning_text = GeneratorMessages.messages.join("\n")
      expect(warning_text).to include("RSC requires React 19.0.x")
    end
  end

  context "when using --rsc with React 19.0.0" do
    let(:install_generator) { described_class.new([], { rsc: true }) }

    specify "warn_about_react_version_for_rsc adds minimum version warning" do
      allow(install_generator).to receive(:detect_react_version).and_return("19.0.0")

      install_generator.send(:warn_about_react_version_for_rsc)
      warning_text = GeneratorMessages.messages.join("\n")
      expect(warning_text).to include("below the recommended minimum")
      expect(warning_text).to include("CVE")
    end
  end

  context "when not using --rsc flag" do
    let(:install_generator) { described_class.new }

    specify "warn_about_react_version_for_rsc does not run" do
      allow(install_generator).to receive(:detect_react_version).and_return("18.2.0")

      install_generator.send(:warn_about_react_version_for_rsc)
      expect(GeneratorMessages.messages.join("\n")).not_to include("RSC")
    end
  end
end

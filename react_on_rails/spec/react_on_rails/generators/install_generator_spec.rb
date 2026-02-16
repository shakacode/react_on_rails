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

  context "when Shakapacker was just installed by the generator" do
    # This tests the fix for https://github.com/shakacode/react_on_rails/issues/2278
    # When Shakapacker is installed by the RoR generator, the marker file exists
    # and the generator skips copying shakapacker.yml. We must still configure precompile_hook.
    before(:all) do
      run_generator_test_with_args(%w[], package_json: true) do
        # Simulate Shakapacker being just installed by creating the marker file
        # and a shakapacker.yml with the default Shakapacker format (precompile_hook commented out)
        simulate_existing_file(".shakapacker_just_installed", "")
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

    it "removes the marker file" do
      expect(File.exist?(File.join(destination_root, ".shakapacker_just_installed"))).to be false
    end
  end

  context "with --rspack" do
    before(:all) do
      run_generator_test_with_args(%w[--rspack], package_json: true) do
        # Simulate Shakapacker being just installed (marker + config files)
        # This allows testing that configure_rspack_in_shakapacker properly updates the config
        simulate_existing_file(".shakapacker_just_installed", "")
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
    before(:all) do
      run_generator_test_with_args(%w[--rspack --typescript], package_json: true) do
        # Simulate Shakapacker being just installed (marker + config files)
        simulate_existing_file(".shakapacker_just_installed", "")
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

    # TODO: When --rsc tests are added, evaluate if this negative test is redundant.
    #       If the positive RSC tests adequately cover the template conditional, remove this.
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

    it "creates Pro initializer" do
      assert_file "config/initializers/react_on_rails_pro.rb" do |content|
        expect(content).to include("ReactOnRailsPro.configure")
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
      end
    end

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

    it "creates Pro initializer" do
      assert_file "config/initializers/react_on_rails_pro.rb" do |content|
        expect(content).to include("ReactOnRailsPro.configure")
      end
    end

    it "creates node-renderer.js" do
      assert_file "client/node-renderer.js"
    end

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
    before(:all) { run_generator_test_with_args(%w[--pro --rspack], package_json: true) }

    include_examples "base_generator", application_js: true
    include_examples "no_redux_generator"

    it "creates Pro initializer" do
      assert_file "config/initializers/react_on_rails_pro.rb" do |content|
        expect(content).to include("ReactOnRailsPro.configure")
      end
    end

    it "creates node-renderer.js" do
      assert_file "client/node-renderer.js"
    end

    it "installs both Pro and Rspack dependencies" do
      assert_file "package.json" do |content|
        package_json = JSON.parse(content)
        deps = package_json["dependencies"] || {}
        expect(deps).to include("react-on-rails-pro")
        expect(deps).to include("@rspack/core")
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

    it "copies common files" do
      %w[config/initializers/react_on_rails.rb
         Procfile.dev
         Procfile.dev-static-assets
         Procfile.dev-prod-assets].each { |file| assert_file(file) }
    end

    it "creates Pro initializer with RSC configuration" do
      assert_file "config/initializers/react_on_rails_pro.rb" do |content|
        expect(content).to include("ReactOnRailsPro.configure")
        expect(content).to include("enable_rsc_support = true")
        expect(content).to include('rsc_bundle_js_file = "rsc-bundle.js"')
        expect(content).to include('rsc_payload_generation_url_path = "rsc_payload/"')
      end
    end

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
        expect(content).to include("const { default: serverWebpackConfig")
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

    it "creates HelloServer controller and view" do
      assert_file "app/controllers/hello_server_controller.rb" do |content|
        expect(content).to include("class HelloServerController")
        expect(content).to include("ReactOnRailsPro::Stream")
      end

      assert_file "app/views/hello_server/index.html.erb" do |content|
        expect(content).to include("HelloServer")
        expect(content).to include("stream_react_component")
      end
    end

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

    it "copies common files" do
      %w[config/initializers/react_on_rails.rb
         Procfile.dev
         Procfile.dev-static-assets
         Procfile.dev-prod-assets].each { |file| assert_file(file) }
    end

    it "creates Pro initializer with RSC configuration" do
      assert_file "config/initializers/react_on_rails_pro.rb" do |content|
        expect(content).to include("enable_rsc_support = true")
      end
    end

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
  end

  context "with --rsc --typescript" do
    before(:all) { run_generator_test_with_args(%w[--rsc --typescript], package_json: true) }

    it "copies common files" do
      %w[config/initializers/react_on_rails.rb
         Procfile.dev
         Procfile.dev-static-assets
         Procfile.dev-prod-assets].each { |file| assert_file(file) }
    end

    it "creates Pro initializer with RSC configuration" do
      assert_file "config/initializers/react_on_rails_pro.rb" do |content|
        expect(content).to include("enable_rsc_support = true")
      end
    end

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
  end

  context "with --rsc --rspack" do
    before(:all) { run_generator_test_with_args(%w[--rsc --rspack], package_json: true) }

    it "copies common files" do
      %w[config/initializers/react_on_rails.rb
         Procfile.dev
         Procfile.dev-static-assets
         Procfile.dev-prod-assets].each { |file| assert_file(file) }
    end

    it "creates Pro initializer with RSC configuration" do
      assert_file "config/initializers/react_on_rails_pro.rb" do |content|
        expect(content).to include("enable_rsc_support = true")
      end
    end

    it "creates rscWebpackConfig.js (works with Rspack)" do
      assert_file "config/webpack/rscWebpackConfig.js" do |content|
        expect(content).to include("serverWebpackConfig(true)")
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

  # Pro/RSC prerequisite validation tests

  context "when using --pro flag without Pro gem installed" do
    let(:install_generator) { described_class.new([], { pro: true }) }

    specify "missing_pro_gem? returns true and error mentions --pro flag" do
      allow(Gem).to receive(:loaded_specs).and_return({})
      allow(install_generator).to receive(:gem_in_lockfile?).with("react_on_rails_pro").and_return(false)

      expect(install_generator.send(:missing_pro_gem?)).to be true
      error_text = GeneratorMessages.messages.join("\n")
      expect(error_text).to include("--pro")
      expect(error_text).to include("react_on_rails_pro")
      expect(error_text).to include("Try Pro free!")
    end
  end

  context "when using --rsc flag without Pro gem installed" do
    let(:install_generator) { described_class.new([], { rsc: true }) }

    specify "missing_pro_gem? returns true and error mentions --rsc flag" do
      allow(Gem).to receive(:loaded_specs).and_return({})
      allow(install_generator).to receive(:gem_in_lockfile?).with("react_on_rails_pro").and_return(false)

      expect(install_generator.send(:missing_pro_gem?)).to be true
      error_text = GeneratorMessages.messages.join("\n")
      expect(error_text).to include("--rsc")
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

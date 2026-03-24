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
    let(:fake_pid) { 12_345 }

    before do
      allow(Gem).to receive(:loaded_specs).and_return({})
      allow(generator).to receive(:gem_in_lockfile?).with("react_on_rails_pro").and_return(false)
      allow(Bundler).to receive(:with_unbundled_env).and_yield
      allow(Process).to receive(:spawn).and_return(fake_pid)
      allow(generator).to receive(:wait_for_bundle_process)
        .with(fake_pid).and_return(instance_double(Process::Status, success?: false))
    end

    specify "missing_pro_gem? returns true with standalone error message" do
      expect(generator.send(:missing_pro_gem?, force: true)).to be true
      expect(Bundler).to have_received(:with_unbundled_env)
      expect(Process).to have_received(:spawn)
        .with(a_string_matching(/\Abundle add react_on_rails_pro --version='~> [\d.]+' --strict\z/),
              out: anything, err: anything)
      error_text = GeneratorMessages.messages.join("\n")
      # Standalone message should NOT mention --pro flag
      expect(error_text).to include("This generator requires the react_on_rails_pro gem")
      expect(error_text).not_to include("You specified")
      expect(error_text).to include("react_on_rails_pro")
    end
  end

  describe "#swap_base_gem_for_pro_in_gemfile" do
    let(:generator) { described_class.new }
    let(:gemfile_path) { File.join(destination_root, "Gemfile") }

    before do
      prepare_destination
      allow(generator).to receive(:destination_root).and_return(destination_root)
    end

    it "replaces react_on_rails with react_on_rails_pro and runs bundle install" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails", "~> 16.0"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expected_version = Gem::Version.new(ReactOnRails::VERSION).release.to_s
      expect(gemfile_content).to include("gem \"react_on_rails_pro\", \"~> #{expected_version}\"")
      expect(gemfile_content).not_to match(/gem\s+["']react_on_rails["']/)
      expect(generator).to have_received(:bundle_install_after_gem_swap)
    end

    it "preserves indentation when replacing a grouped Gemfile entry" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"

        group :default do
          gem "react_on_rails", "~> 16.0"
        end
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expected_version = Gem::Version.new(ReactOnRails::VERSION).release.to_s
      expect(gemfile_content).to include("  gem \"react_on_rails_pro\", \"~> #{expected_version}\"")
      expect(generator).to have_received(:bundle_install_after_gem_swap)
    end

    it "replaces multiline react_on_rails declaration without leaving orphan lines" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails",
          "~> 16.0"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expected_version = Gem::Version.new(ReactOnRails::VERSION).release.to_s
      expect(gemfile_content).to include("gem \"react_on_rails_pro\", \"~> #{expected_version}\"")
      expect(gemfile_content).not_to include("gem \"react_on_rails\",")
      expect(gemfile_content).not_to include("  \"~> 16.0\"")
      expect(generator).to have_received(:bundle_install_after_gem_swap)
    end

    it "replaces multiline declarations that have an inline comment after the trailing comma" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails", # pinned for compatibility
          "~> 16.0"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expected_version = Gem::Version.new(ReactOnRails::VERSION).release.to_s
      expect(gemfile_content).to include("gem \"react_on_rails_pro\", \"~> #{expected_version}\"")
      expect(gemfile_content).not_to include("gem \"react_on_rails\", # pinned for compatibility")
      expect(gemfile_content).not_to include("  \"~> 16.0\"")
    end

    it "does not consume the next gem line when base declaration ends with a trailing comma" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails",
        gem "rails"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expected_version = Gem::Version.new(ReactOnRails::VERSION).release.to_s
      expect(gemfile_content).to include("gem \"react_on_rails_pro\", \"~> #{expected_version}\"")
      expect(gemfile_content).to include("gem \"rails\"")
    end

    it "preserves single quote style when replacing single-quoted Gemfile entries" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem 'react_on_rails', '~> 16.0'
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expected_version = Gem::Version.new(ReactOnRails::VERSION).release.to_s
      expect(gemfile_content).to include("gem 'react_on_rails_pro', '~> #{expected_version}'")
      expect(generator).to have_received(:bundle_install_after_gem_swap)
    end

    it "replaces parenthesized Gemfile declarations" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem("react_on_rails", "~> 16.0")
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expected_version = Gem::Version.new(ReactOnRails::VERSION).release.to_s
      expect(gemfile_content).to include("gem \"react_on_rails_pro\", \"~> #{expected_version}\"")
      expect(gemfile_content).not_to include('gem("react_on_rails"')
      expect(generator).to have_received(:bundle_install_after_gem_swap)
    end

    it "removes base gem without adding duplicate react_on_rails_pro entries" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails", "~> 16.0"
        gem "react_on_rails_pro", "~> 16.0"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expect(gemfile_content).not_to match(/gem\s+["']react_on_rails["']/)
      expect(gemfile_content.scan(/gem\s+["']react_on_rails_pro["']/).size).to eq(1)
      expect(generator).to have_received(:bundle_install_after_gem_swap)
    end

    it "does nothing when Gemfile has no react_on_rails entry" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "rails"
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      original_content = File.read(gemfile_path)
      generator.send(:swap_base_gem_for_pro_in_gemfile)

      expect(File.read(gemfile_path)).to eq(original_content)
      expect(generator).not_to have_received(:bundle_install_after_gem_swap)
    end

    it "warns when Gemfile is missing" do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(gemfile_path).and_return(false)
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      warning_text = GeneratorMessages.messages.join("\n")
      expect(warning_text).to include("Could not find Gemfile")
      expect(warning_text).to include("non-standard Gemfile path")
      expect(generator).not_to have_received(:bundle_install_after_gem_swap)
    end

    it "warns and skips bundle install when Gemfile cannot be written" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails", "~> 16.0"
      RUBY
      allow(File).to receive(:write).and_call_original
      allow(File).to receive(:write).with(gemfile_path, anything).and_raise(Errno::EACCES)
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      warning_text = GeneratorMessages.messages.join("\n")
      expect(warning_text).to include("Could not update Gemfile")
      expect(warning_text).to include("Please update your Gemfile manually")
      expect(generator).not_to have_received(:bundle_install_after_gem_swap)
    end

    it "replaces base gem entries that include inline comments" do
      simulate_existing_file("Gemfile", <<~RUBY)
        source "https://rubygems.org"
        gem "react_on_rails" # pinned for compatibility
      RUBY
      allow(generator).to receive(:bundle_install_after_gem_swap)

      generator.send(:swap_base_gem_for_pro_in_gemfile)

      gemfile_content = File.read(gemfile_path)
      expected_version = Gem::Version.new(ReactOnRails::VERSION).release.to_s
      expect(gemfile_content).to include("gem \"react_on_rails_pro\", \"~> #{expected_version}\"")
      expect(gemfile_content).not_to include("gem \"react_on_rails\" # pinned for compatibility")
      expect(generator).to have_received(:bundle_install_after_gem_swap)
    end
  end

  describe "#bundle_install_after_gem_swap" do
    let(:generator) { described_class.new }
    let(:fake_pid) { 23_456 }

    before do
      prepare_destination
      allow(generator).to receive(:destination_root).and_return(destination_root)
      GeneratorMessages.clear
      allow(Bundler).to receive(:with_unbundled_env).and_yield
      allow(Process).to receive(:spawn).and_return(fake_pid)
    end

    it "returns without warnings when bundle install succeeds" do
      allow(generator).to receive(:wait_for_bundle_process)
        .with(fake_pid).and_return(instance_double(Process::Status, success?: true))

      generator.send(:bundle_install_after_gem_swap)

      expect(GeneratorMessages.messages).to eq([])
    end

    it "uses bounded process waiting and warns on timeout" do
      allow(generator).to receive(:wait_for_bundle_process).with(fake_pid).and_return(nil)

      generator.send(:bundle_install_after_gem_swap)

      expect(Process).to have_received(:spawn).with(
        { "BUNDLE_GEMFILE" => File.join(destination_root, "Gemfile") },
        "bundle",
        "install",
        out: $stdout,
        err: $stderr,
        chdir: destination_root
      )
      expect(generator).to have_received(:wait_for_bundle_process).with(fake_pid)
      warning_text = GeneratorMessages.messages.join("\n")
      expect(warning_text).to include("timed out")
      expect(warning_text).to include("bundle install")
    end
  end

  describe "#update_imports_to_pro_package" do
    let(:generator) { described_class.new }
    let(:application_js_path) { File.join(destination_root, "app/javascript/packs/application.js") }
    let(:server_js_path) { File.join(destination_root, "client/server.js") }
    let(:frontend_js_path) { File.join(destination_root, "app/frontend/entrypoints/client.ts") }
    let(:vue_component_path) { File.join(destination_root, "app/frontend/components/RorWidget.vue") }
    let(:svelte_component_path) { File.join(destination_root, "frontend/components/RorWidget.svelte") }

    before do
      prepare_destination
      allow(generator).to receive(:destination_root).and_return(destination_root)
      simulate_existing_file("app/javascript/packs/application.js", <<~JS)
        import ReactOnRails from "react-on-rails";
        const ror = require("react-on-rails");
        const lazyRor = import(/* webpackChunkName: "ror" */ "react-on-rails");
        const commentLikeString = "/* not a JS comment";
        import ReactOnRailsServer from "react-on-rails/server";
        import ReactOnRailsClient from "react-on-rails/client";
        import "react-on-rails";
        import CustomPackage from "react-on-rails-utils";
        const scoped = "@scope/react-on-rails";
        const url = "https://cdn.example.com/react-on-rails/client.js";
        // import "react-on-rails";
        /*
         * import ReactOnRails from "react-on-rails";
         */
      JS
      simulate_existing_file("client/server.js", "import ReactOnRails from \"react-on-rails-pro\";\n")
      simulate_existing_file("app/frontend/entrypoints/client.ts", "import ReactOnRails from \"react-on-rails\";\n")
      simulate_existing_file("app/frontend/components/RorWidget.vue", <<~VUE)
        <script>
        import ReactOnRails from "react-on-rails";
        const ror = require("react-on-rails");
        </script>
      VUE
      simulate_existing_file("frontend/components/RorWidget.svelte", <<~SVELTE)
        <script>
          import ReactOnRails from "react-on-rails";
        </script>
      SVELTE
    end

    it "updates react-on-rails imports and requires to react-on-rails-pro" do
      generator.send(:update_imports_to_pro_package)

      expect(File.read(application_js_path)).to include('import ReactOnRails from "react-on-rails-pro";')
      expect(File.read(application_js_path)).to include('require("react-on-rails-pro")')
      expect(File.read(application_js_path)).to include('import(/* webpackChunkName: "ror" */ "react-on-rails-pro")')
      expect(File.read(application_js_path)).to include('import ReactOnRailsServer from "react-on-rails-pro/server";')
      expect(File.read(application_js_path)).to include('import ReactOnRailsClient from "react-on-rails-pro/client";')
      expect(File.read(application_js_path)).to include('import "react-on-rails-pro";')
      expect(File.read(application_js_path)).to include('import CustomPackage from "react-on-rails-utils";')
      expect(File.read(application_js_path)).to include('const scoped = "@scope/react-on-rails";')
      expect(File.read(application_js_path)).to include('const url = "https://cdn.example.com/react-on-rails/client.js";')
      expect(File.read(application_js_path)).to include('// import "react-on-rails";')
      expect(File.read(application_js_path)).to include('* import ReactOnRails from "react-on-rails";')
      expect(File.read(server_js_path)).to include('import ReactOnRails from "react-on-rails-pro";')
      expect(File.read(frontend_js_path)).to include('import ReactOnRails from "react-on-rails-pro";')
      expect(File.read(vue_component_path)).to include('import ReactOnRails from "react-on-rails-pro";')
      expect(File.read(vue_component_path)).to include('require("react-on-rails-pro")')
      expect(File.read(svelte_component_path)).to include('import ReactOnRails from "react-on-rails-pro";')
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

    include_examples "pro_common_files"

    it "Pro initializer does not include RSC config (RSC generator adds it)" do
      assert_file "config/initializers/react_on_rails_pro.rb" do |content|
        expect(content).not_to include("enable_rsc_support")
        expect(content).not_to include("rsc_bundle_js_file")
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

# frozen_string_literal: true

require_relative "../../react_on_rails/spec_helper"
require_relative "../../../lib/react_on_rails/doctor"

RSpec.describe ReactOnRails::Doctor do
  let(:doctor) { described_class.new(verbose: false, fix: false) }

  describe "#initialize" do
    it "initializes with default options" do
      expect(doctor).to be_instance_of(described_class)
    end

    it "accepts verbose and fix options" do
      verbose_doctor = described_class.new(verbose: true, fix: true)
      expect(verbose_doctor).to be_instance_of(described_class)
    end
  end

  describe "#run_diagnosis" do
    before do
      # Mock all output methods to avoid actual printing
      allow(doctor).to receive(:puts)
      allow(doctor).to receive(:exit)

      # Mock file system interactions
      allow(File).to receive_messages(exist?: false, directory?: false)

      # Mock the new server bundle path methods
      allow(doctor).to receive_messages(
        "`": "",
        determine_server_bundle_path: "app/javascript/packs/server-bundle.js",
        server_bundle_filename: "server-bundle.js",
        npm_test_script?: false,
        yarn_test_script?: false
      )

      # Mock the checker to avoid actual system calls
      checker = instance_double(ReactOnRails::SystemChecker)
      allow(ReactOnRails::SystemChecker).to receive(:new).and_return(checker)
      allow(checker).to receive_messages(
        check_node_installation: true,
        check_package_manager: true,
        check_react_on_rails_packages: true,
        check_shakapacker_configuration: true,
        check_react_dependencies: true,
        check_react_on_rails_initializer: true,
        check_webpack_configuration: true,
        report_dependency_versions: true,
        report_shakapacker_version: true,
        report_webpack_version: true,
        add_success: true,
        add_warning: true,
        add_info: true,
        errors?: false,
        warnings?: false,
        messages: []
      )
    end

    it "runs diagnosis without errors" do
      expect { doctor.run_diagnosis }.not_to raise_error
    end

    it "prints header" do
      expect(doctor).to receive(:puts).with(/REACT ON RAILS DOCTOR/)
      doctor.run_diagnosis
    end

    it "runs all check sections" do
      checker = doctor.instance_variable_get(:@checker)

      expect(checker).to receive(:check_node_installation)
      expect(checker).to receive(:check_package_manager)
      expect(checker).to receive(:check_react_on_rails_packages)
      expect(checker).to receive(:check_shakapacker_configuration)
      expect(checker).to receive(:check_react_dependencies)
      expect(checker).to receive(:check_react_on_rails_initializer)
      expect(checker).to receive(:check_webpack_configuration)

      doctor.run_diagnosis
    end
  end

  describe "server bundle path detection" do
    let(:doctor) { described_class.new }

    describe "#determine_server_bundle_path" do
      context "when Shakapacker gem is available with relative paths" do
        let(:shakapacker_config) do
          instance_double(Shakapacker::Configuration, source_path: "client/app", source_entry_path: "packs")
        end

        before do
          shakapacker_module = instance_double(Shakapacker, config: shakapacker_config)
          stub_const("Shakapacker", shakapacker_module)
          allow(doctor).to receive(:require).with("shakapacker").and_return(true)
          allow(doctor).to receive(:server_bundle_filename).and_return("server-bundle.js")
        end

        it "uses Shakapacker API configuration with relative paths" do
          path = doctor.send(:determine_server_bundle_path)
          expect(path).to eq("client/app/packs/server-bundle.js")
        end
      end

      context "when Shakapacker gem is available with absolute paths" do
        let(:rails_root) { "/Users/test/myapp" }
        let(:shakapacker_config) do
          instance_double(Shakapacker::Configuration, source_path: "#{rails_root}/client/app",
                                                      source_entry_path: "packs")
        end

        before do
          shakapacker_module = instance_double(Shakapacker, config: shakapacker_config)
          stub_const("Shakapacker", shakapacker_module)
          allow(doctor).to receive(:require).with("shakapacker").and_return(true)
          allow(doctor).to receive(:server_bundle_filename).and_return("server-bundle.js")
          allow(Dir).to receive(:pwd).and_return(rails_root)
        end

        it "converts absolute paths to relative paths" do
          path = doctor.send(:determine_server_bundle_path)
          expect(path).to eq("client/app/packs/server-bundle.js")
        end
      end

      context "when Shakapacker gem returns nested absolute paths" do
        let(:rails_root) { "/Users/test/myapp" }
        let(:shakapacker_config) do
          instance_double(Shakapacker::Configuration, source_path: "#{rails_root}/client/app",
                                                      source_entry_path: "#{rails_root}/client/app/packs")
        end

        before do
          shakapacker_module = instance_double(Shakapacker, config: shakapacker_config)
          stub_const("Shakapacker", shakapacker_module)
          allow(doctor).to receive(:require).with("shakapacker").and_return(true)
          allow(doctor).to receive(:server_bundle_filename).and_return("server-bundle.js")
          allow(Dir).to receive(:pwd).and_return(rails_root)
        end

        it "handles nested absolute paths correctly" do
          path = doctor.send(:determine_server_bundle_path)
          expect(path).to eq("client/app/packs/server-bundle.js")
        end
      end

      context "when Shakapacker gem is not available" do
        before do
          allow(doctor).to receive(:require).with("shakapacker").and_raise(LoadError)
          allow(doctor).to receive(:server_bundle_filename).and_return("server-bundle.js")
        end

        it "uses default path" do
          path = doctor.send(:determine_server_bundle_path)
          expect(path).to eq("app/javascript/packs/server-bundle.js")
        end
      end
    end

    describe "#server_bundle_filename" do
      context "when react_on_rails.rb has custom filename" do
        let(:initializer_content) do
          'config.server_bundle_js_file = "custom-server-bundle.js"'
        end

        before do
          allow(File).to receive(:exist?).with("config/initializers/react_on_rails.rb").and_return(true)
          allow(File).to receive(:read).with("config/initializers/react_on_rails.rb").and_return(initializer_content)
        end

        it "extracts filename from initializer" do
          filename = doctor.send(:server_bundle_filename)
          expect(filename).to eq("custom-server-bundle.js")
        end
      end

      context "when no custom filename is configured" do
        before do
          allow(File).to receive(:exist?).with("config/initializers/react_on_rails.rb").and_return(false)
        end

        it "returns default filename" do
          filename = doctor.send(:server_bundle_filename)
          expect(filename).to eq("server-bundle.js")
        end
      end
    end
  end

  describe "#check_async_usage" do
    let(:checker) { instance_double(ReactOnRails::SystemChecker) }

    before do
      allow(doctor).to receive(:checker).and_return(checker)
      allow(checker).to receive_messages(add_error: true, add_warning: true, add_info: true)
      allow(File).to receive(:exist?).and_call_original
      allow(Dir).to receive(:glob).and_return([])
    end

    context "when Pro gem is installed" do
      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
      end

      it "skips the check" do
        doctor.send(:check_async_usage)
        expect(checker).not_to have_received(:add_error)
        expect(checker).not_to have_received(:add_warning)
      end
    end

    context "when Pro gem is not installed" do
      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
      end

      context "when async is used in view files" do
        before do
          allow(Dir).to receive(:glob).with("app/views/**/*.erb").and_return(["app/views/layouts/application.html.erb"])
          allow(Dir).to receive(:glob).with("app/views/**/*.haml").and_return([])
          allow(Dir).to receive(:glob).with("app/views/**/*.slim").and_return([])
          allow(File).to receive(:exist?).with("app/views/layouts/application.html.erb").and_return(true)
          allow(File).to receive(:read).with("app/views/layouts/application.html.erb")
                                       .and_return('<%= javascript_pack_tag "application", :async %>')
          allow(File).to receive(:exist?).with("config/initializers/react_on_rails.rb").and_return(false)
          allow(doctor).to receive(:relativize_path).with("app/views/layouts/application.html.erb")
                                                    .and_return("app/views/layouts/application.html.erb")
        end

        it "reports an error" do
          doctor.send(:check_async_usage)
          expect(checker).to have_received(:add_error).with("🚫 :async usage detected without React on Rails Pro")
          expect(checker).to have_received(:add_error)
            .with("  javascript_pack_tag with :async found in view files:")
        end
      end

      context "when generated_component_packs_loading_strategy is :async" do
        before do
          allow(File).to receive(:exist?).with("config/initializers/react_on_rails.rb").and_return(true)
          allow(File).to receive(:read).with("config/initializers/react_on_rails.rb")
                                       .and_return("config.generated_component_packs_loading_strategy = :async")
        end

        it "reports an error" do
          doctor.send(:check_async_usage)
          expect(checker).to have_received(:add_error).with("🚫 :async usage detected without React on Rails Pro")
          expect(checker).to have_received(:add_error)
            .with("  config.generated_component_packs_loading_strategy = :async in initializer")
        end
      end

      context "when no async usage is detected" do
        before do
          allow(File).to receive(:exist?).with("config/initializers/react_on_rails.rb").and_return(true)
          allow(File).to receive(:read).with("config/initializers/react_on_rails.rb")
                                       .and_return("config.generated_component_packs_loading_strategy = :defer")
        end

        it "does not report any issues" do
          doctor.send(:check_async_usage)
          expect(checker).not_to have_received(:add_error)
          expect(checker).not_to have_received(:add_warning)
        end
      end
    end
  end

  describe "#scan_view_files_for_async_pack_tag" do
    before do
      allow(Dir).to receive(:glob).and_call_original
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:read).and_call_original
    end

    context "when view files contain javascript_pack_tag with :async" do
      before do
        allow(Dir).to receive(:glob).with("app/views/**/*.erb")
                                    .and_return(["app/views/layouts/application.html.erb"])
        allow(Dir).to receive(:glob).with("app/views/**/*.haml").and_return([])
        allow(Dir).to receive(:glob).with("app/views/**/*.slim").and_return([])
        allow(File).to receive(:exist?).with("app/views/layouts/application.html.erb").and_return(true)
        allow(File).to receive(:read).with("app/views/layouts/application.html.erb")
                                     .and_return('<%= javascript_pack_tag "app", :async %>')
        allow(doctor).to receive(:relativize_path).with("app/views/layouts/application.html.erb")
                                                  .and_return("app/views/layouts/application.html.erb")
      end

      it "returns files with async" do
        files = doctor.send(:scan_view_files_for_async_pack_tag)
        expect(files).to include("app/views/layouts/application.html.erb")
      end
    end

    context "when view files contain javascript_pack_tag with async: true" do
      before do
        allow(Dir).to receive(:glob).with("app/views/**/*.erb")
                                    .and_return(["app/views/layouts/application.html.erb"])
        allow(Dir).to receive(:glob).with("app/views/**/*.haml").and_return([])
        allow(Dir).to receive(:glob).with("app/views/**/*.slim").and_return([])
        allow(File).to receive(:exist?).with("app/views/layouts/application.html.erb").and_return(true)
        allow(File).to receive(:read).with("app/views/layouts/application.html.erb")
                                     .and_return('<%= javascript_pack_tag "app", async: true %>')
        allow(doctor).to receive(:relativize_path).with("app/views/layouts/application.html.erb")
                                                  .and_return("app/views/layouts/application.html.erb")
      end

      it "returns files with async" do
        files = doctor.send(:scan_view_files_for_async_pack_tag)
        expect(files).to include("app/views/layouts/application.html.erb")
      end
    end

    context "when view files contain defer: \"async\" (false positive check)" do
      before do
        allow(Dir).to receive(:glob).with("app/views/**/*.erb")
                                    .and_return(["app/views/layouts/application.html.erb"])
        allow(Dir).to receive(:glob).with("app/views/**/*.haml").and_return([])
        allow(Dir).to receive(:glob).with("app/views/**/*.slim").and_return([])
        allow(File).to receive(:exist?).with("app/views/layouts/application.html.erb").and_return(true)
        allow(File).to receive(:read).with("app/views/layouts/application.html.erb")
                                     .and_return('<%= javascript_pack_tag "app", defer: "async" %>')
      end

      it "does not return files (async is a string value, not the option)" do
        files = doctor.send(:scan_view_files_for_async_pack_tag)
        expect(files).to be_empty
      end
    end

    context "when view files do not contain async" do
      before do
        allow(Dir).to receive(:glob).with("app/views/**/*.erb")
                                    .and_return(["app/views/layouts/application.html.erb"])
        allow(Dir).to receive(:glob).with("app/views/**/*.haml").and_return([])
        allow(Dir).to receive(:glob).with("app/views/**/*.slim").and_return([])
        allow(File).to receive(:exist?).with("app/views/layouts/application.html.erb").and_return(true)
        allow(File).to receive(:read).with("app/views/layouts/application.html.erb")
                                     .and_return('<%= javascript_pack_tag "app" %>')
      end

      it "returns empty array" do
        files = doctor.send(:scan_view_files_for_async_pack_tag)
        expect(files).to be_empty
      end
    end

    context "when file has uncommented pack tag without :async and commented one with :async" do
      before do
        allow(Dir).to receive(:glob).with("app/views/**/*.erb")
                                    .and_return(["app/views/layouts/application.html.erb"])
        allow(Dir).to receive(:glob).with("app/views/**/*.haml").and_return([])
        allow(Dir).to receive(:glob).with("app/views/**/*.slim").and_return([])
        allow(File).to receive(:exist?).with("app/views/layouts/application.html.erb").and_return(true)
        allow(File).to receive(:read).with("app/views/layouts/application.html.erb")
                                     .and_return('<%= javascript_pack_tag "app", defer: true %>
<%# javascript_pack_tag "other", :async %>')
      end

      it "does not return files (only commented line has :async)" do
        files = doctor.send(:scan_view_files_for_async_pack_tag)
        expect(files).to be_empty
      end
    end

    context "when async is only in ERB comments" do
      before do
        allow(Dir).to receive(:glob).with("app/views/**/*.erb")
                                    .and_return(["app/views/layouts/application.html.erb"])
        allow(Dir).to receive(:glob).with("app/views/**/*.haml").and_return([])
        allow(Dir).to receive(:glob).with("app/views/**/*.slim").and_return([])
        allow(File).to receive(:exist?).with("app/views/layouts/application.html.erb").and_return(true)
        allow(File).to receive(:read).with("app/views/layouts/application.html.erb")
                                     .and_return('<%# javascript_pack_tag "app", :async %>')
      end

      it "returns empty array" do
        files = doctor.send(:scan_view_files_for_async_pack_tag)
        expect(files).to be_empty
      end
    end

    context "when async is only in HAML comments" do
      before do
        allow(Dir).to receive(:glob).with("app/views/**/*.erb").and_return([])
        allow(Dir).to receive(:glob).with("app/views/**/*.haml")
                                    .and_return(["app/views/layouts/application.html.haml"])
        allow(Dir).to receive(:glob).with("app/views/**/*.slim").and_return([])
        allow(File).to receive(:exist?).with("app/views/layouts/application.html.haml").and_return(true)
        allow(File).to receive(:read).with("app/views/layouts/application.html.haml")
                                     .and_return('-# javascript_pack_tag "app", :async')
      end

      it "returns empty array" do
        files = doctor.send(:scan_view_files_for_async_pack_tag)
        expect(files).to be_empty
      end
    end

    context "when async is only in HTML comments" do
      before do
        allow(Dir).to receive(:glob).with("app/views/**/*.erb")
                                    .and_return(["app/views/layouts/application.html.erb"])
        allow(Dir).to receive(:glob).with("app/views/**/*.haml").and_return([])
        allow(Dir).to receive(:glob).with("app/views/**/*.slim").and_return([])
        allow(Dir).to receive(:glob).with("app/views/**/*.slim").and_return([])
        allow(File).to receive(:exist?).with("app/views/layouts/application.html.erb").and_return(true)
        allow(File).to receive(:read).with("app/views/layouts/application.html.erb")
                                     .and_return('<!-- <%= javascript_pack_tag "app", :async %> -->')
      end

      it "returns empty array" do
        files = doctor.send(:scan_view_files_for_async_pack_tag)
        expect(files).to be_empty
      end
    end

    context "when async is only in Slim comments" do
      before do
        allow(Dir).to receive(:glob).with("app/views/**/*.erb").and_return([])
        allow(Dir).to receive(:glob).with("app/views/**/*.haml").and_return([])
        allow(Dir).to receive(:glob).with("app/views/**/*.slim").and_return([])
        allow(Dir).to receive(:glob).with("app/views/**/*.slim")
                                    .and_return(["app/views/layouts/application.html.slim"])
        allow(File).to receive(:exist?).with("app/views/layouts/application.html.slim").and_return(true)
        allow(File).to receive(:read).with("app/views/layouts/application.html.slim")
                                     .and_return('/ = javascript_pack_tag "app", :async')
      end

      it "returns empty array" do
        files = doctor.send(:scan_view_files_for_async_pack_tag)
        expect(files).to be_empty
      end
    end

    context "when view files contain Slim javascript_pack_tag with :async" do
      before do
        allow(Dir).to receive(:glob).with("app/views/**/*.erb").and_return([])
        allow(Dir).to receive(:glob).with("app/views/**/*.haml").and_return([])
        allow(Dir).to receive(:glob).with("app/views/**/*.slim").and_return([])
        allow(Dir).to receive(:glob).with("app/views/**/*.slim")
                                    .and_return(["app/views/layouts/application.html.slim"])
        allow(File).to receive(:exist?).with("app/views/layouts/application.html.slim").and_return(true)
        allow(File).to receive(:read).with("app/views/layouts/application.html.slim")
                                     .and_return('= javascript_pack_tag "app", :async')
        allow(doctor).to receive(:relativize_path).with("app/views/layouts/application.html.slim")
                                                  .and_return("app/views/layouts/application.html.slim")
      end

      it "returns files with async" do
        files = doctor.send(:scan_view_files_for_async_pack_tag)
        expect(files).to include("app/views/layouts/application.html.slim")
      end
    end

    context "when javascript_pack_tag spans multiple lines" do
      before do
        allow(Dir).to receive(:glob).with("app/views/**/*.erb")
                                    .and_return(["app/views/layouts/application.html.erb"])
        allow(Dir).to receive(:glob).with("app/views/**/*.haml").and_return([])
        allow(Dir).to receive(:glob).with("app/views/**/*.slim").and_return([])
        allow(File).to receive(:exist?).with("app/views/layouts/application.html.erb").and_return(true)
        allow(File).to receive(:read).with("app/views/layouts/application.html.erb")
                                     .and_return("<%= javascript_pack_tag \"app\",\n  :async %>")
        allow(doctor).to receive(:relativize_path).with("app/views/layouts/application.html.erb")
                                                  .and_return("app/views/layouts/application.html.erb")
      end

      it "returns files with async" do
        files = doctor.send(:scan_view_files_for_async_pack_tag)
        expect(files).to include("app/views/layouts/application.html.erb")
      end
    end
  end

  describe "#config_has_async_loading_strategy?" do
    context "when config file has :async strategy" do
      before do
        allow(File).to receive(:exist?).with("config/initializers/react_on_rails.rb").and_return(true)
        allow(File).to receive(:read).with("config/initializers/react_on_rails.rb")
                                     .and_return("config.generated_component_packs_loading_strategy = :async")
      end

      it "returns true" do
        expect(doctor.send(:config_has_async_loading_strategy?)).to be true
      end
    end

    context "when config file has different strategy" do
      before do
        allow(File).to receive(:exist?).with("config/initializers/react_on_rails.rb").and_return(true)
        allow(File).to receive(:read).with("config/initializers/react_on_rails.rb")
                                     .and_return("config.generated_component_packs_loading_strategy = :defer")
      end

      it "returns false" do
        expect(doctor.send(:config_has_async_loading_strategy?)).to be false
      end
    end

    context "when config file does not exist" do
      before do
        allow(File).to receive(:exist?).with("config/initializers/react_on_rails.rb").and_return(false)
      end

      it "returns false" do
        expect(doctor.send(:config_has_async_loading_strategy?)).to be false
      end
    end

    context "when :async strategy is commented out" do
      before do
        allow(File).to receive(:exist?).with("config/initializers/react_on_rails.rb").and_return(true)
        allow(File).to receive(:read).with("config/initializers/react_on_rails.rb")
                                     .and_return("# config.generated_component_packs_loading_strategy = :async")
      end

      it "returns false" do
        expect(doctor.send(:config_has_async_loading_strategy?)).to be false
      end
    end
  end

  describe "server bundle path validation" do
    let(:doctor) { described_class.new }
    let(:checker) { doctor.instance_variable_get(:@checker) }

    before do
      allow(checker).to receive(:add_info)
      allow(checker).to receive(:add_success)
      allow(checker).to receive(:add_warning)
    end

    describe "#validate_server_bundle_path_sync" do
      context "when webpack config file doesn't exist" do
        before do
          allow(File).to receive(:exist?).with("config/webpack/serverWebpackConfig.js").and_return(false)
        end

        it "adds info message and skips validation" do
          expected_msg = "\n  ℹ️  Webpack server config not found - skipping path validation"
          expect(checker).to receive(:add_info).with(expected_msg)
          doctor.send(:validate_server_bundle_path_sync, "ssr-generated")
        end
      end

      context "when webpack config uses hardcoded path" do
        let(:webpack_content) do
          <<~JS
            serverWebpackConfig.output = {
              filename: 'server-bundle.js',
              path: require('path').resolve(__dirname, '../../ssr-generated'),
            };
          JS
        end

        before do
          allow(File).to receive(:exist?).with("config/webpack/serverWebpackConfig.js").and_return(true)
          allow(File).to receive(:read).with("config/webpack/serverWebpackConfig.js").and_return(webpack_content)
        end

        it "reports success when paths match" do
          expected_msg = "\n  ✅ Webpack and Rails configs are in sync (both use 'ssr-generated')"
          expect(checker).to receive(:add_success).with(expected_msg)
          doctor.send(:validate_server_bundle_path_sync, "ssr-generated")
        end

        it "reports warning when paths don't match" do
          expect(checker).to receive(:add_warning).with(/Configuration mismatch detected/)
          doctor.send(:validate_server_bundle_path_sync, "server-bundles")
        end

        it "includes both paths in warning when mismatched" do
          expect(checker).to receive(:add_warning) do |msg|
            expect(msg).to include('server_bundle_output_path = "server-bundles"')
            expect(msg).to include('output.path = "ssr-generated"')
          end
          doctor.send(:validate_server_bundle_path_sync, "server-bundles")
        end
      end

      context "when webpack config uses config.outputPath" do
        let(:webpack_content) do
          <<~JS
            serverWebpackConfig.output = {
              filename: 'server-bundle.js',
              path: config.outputPath,
            };
          JS
        end

        before do
          allow(File).to receive(:exist?).with("config/webpack/serverWebpackConfig.js").and_return(true)
          allow(File).to receive(:read).with("config/webpack/serverWebpackConfig.js").and_return(webpack_content)
        end

        it "reports that it cannot validate" do
          expect(checker).to receive(:add_info).with(/Webpack config uses config\.outputPath/)
          doctor.send(:validate_server_bundle_path_sync, "ssr-generated")
        end

        it "does not report success or warning" do
          expect(checker).not_to receive(:add_success)
          expect(checker).not_to receive(:add_warning)
          doctor.send(:validate_server_bundle_path_sync, "ssr-generated")
        end
      end

      context "when webpack config uses a variable" do
        let(:webpack_content) do
          <<~JS
            const outputPath = calculatePath();
            serverWebpackConfig.output = {
              path: outputPath,
            };
          JS
        end

        before do
          allow(File).to receive(:exist?).with("config/webpack/serverWebpackConfig.js").and_return(true)
          allow(File).to receive(:read).with("config/webpack/serverWebpackConfig.js").and_return(webpack_content)
        end

        it "reports that it cannot validate" do
          expect(checker).to receive(:add_info).with(/Webpack config uses a variable/)
          doctor.send(:validate_server_bundle_path_sync, "ssr-generated")
        end
      end

      context "when webpack config reading fails" do
        before do
          allow(File).to receive(:exist?).with("config/webpack/serverWebpackConfig.js").and_return(true)
          allow(File).to receive(:read).and_raise(StandardError, "Permission denied")
        end

        it "handles error gracefully" do
          expect(checker).to receive(:add_info).with(/Could not validate webpack config: Permission denied/)
          doctor.send(:validate_server_bundle_path_sync, "ssr-generated")
        end
      end
    end

    describe "#extract_webpack_output_path" do
      context "with hardcoded path pattern" do
        let(:webpack_content) do
          "path: require('path').resolve(__dirname, '../../my-bundle-dir')"
        end

        it "extracts the path" do
          result = doctor.send(:extract_webpack_output_path, webpack_content, "config/webpack/test.js")
          expect(result).to eq("my-bundle-dir")
        end
      end

      context "with config.outputPath" do
        let(:webpack_content) { "path: config.outputPath" }

        it "returns nil and adds info message" do
          expect(checker).to receive(:add_info).with(/config\.outputPath/)
          result = doctor.send(:extract_webpack_output_path, webpack_content, "config/webpack/test.js")
          expect(result).to be_nil
        end
      end

      context "with variable" do
        let(:webpack_content) { "path: myPath" }

        it "returns nil and adds info message" do
          expect(checker).to receive(:add_info).with(/variable/)
          result = doctor.send(:extract_webpack_output_path, webpack_content, "config/webpack/test.js")
          expect(result).to be_nil
        end
      end

      context "with unrecognized pattern" do
        let(:webpack_content) { "output: {}" }

        it "returns nil and adds info message" do
          expect(checker).to receive(:add_info).with(/Could not parse/)
          result = doctor.send(:extract_webpack_output_path, webpack_content, "config/webpack/test.js")
          expect(result).to be_nil
        end
      end
    end

    describe "#normalize_path" do
      it "removes leading ./" do
        expect(doctor.send(:normalize_path, "./ssr-generated")).to eq("ssr-generated")
      end

      it "removes leading /" do
        expect(doctor.send(:normalize_path, "/ssr-generated")).to eq("ssr-generated")
      end

      it "removes trailing /" do
        expect(doctor.send(:normalize_path, "ssr-generated/")).to eq("ssr-generated")
      end

      it "handles paths with both leading and trailing slashes" do
        expect(doctor.send(:normalize_path, "./ssr-generated/")).to eq("ssr-generated")
      end

      it "strips whitespace" do
        expect(doctor.send(:normalize_path, "  ssr-generated  ")).to eq("ssr-generated")
      end

      it "returns unchanged path if already normalized" do
        expect(doctor.send(:normalize_path, "ssr-generated")).to eq("ssr-generated")
      end

      it "handles nil gracefully" do
        expect(doctor.send(:normalize_path, nil)).to be_nil
      end

      it "handles non-string values gracefully" do
        expect(doctor.send(:normalize_path, 123)).to eq(123)
      end
    end
  end
end

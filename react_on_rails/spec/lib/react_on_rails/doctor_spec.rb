# frozen_string_literal: true

require_relative "../../react_on_rails/spec_helper"
require_relative "../../../lib/react_on_rails/doctor"
require "fileutils"
require "tmpdir"

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

  describe "test asset compilation consistency" do
    let(:doctor) { described_class.new(verbose: false, fix: fix_mode) }
    let(:fix_mode) { false }
    let(:checker) { doctor.instance_variable_get(:@checker) }

    around do |example|
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { example.run }
      end
    end

    def write_project_file(path, content)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
    end

    it "warns when build_test_command is set but minitest helper is missing in mixed setup" do
      write_project_file("config/initializers/react_on_rails.rb", <<~RUBY)
        ReactOnRails.configure do |config|
          config.build_test_command = "RAILS_ENV=test bin/shakapacker"
        end
      RUBY
      write_project_file("config/shakapacker.yml", <<~YAML)
        test:
          compile: false
      YAML
      write_project_file("spec/rails_helper.rb", <<~RUBY)
        require "react_on_rails/test_helper"
        RSpec.configure do |config|
          ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
        end
      RUBY
      write_project_file("test/test_helper.rb", <<~RUBY)
        require "rails/test_help"
      RUBY

      doctor.send(:check_build_test_configuration)

      warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
      expect(warning_messages).to include(a_string_including("missing for Minitest"))
    end

    it "reports separate development/test output paths as recommended" do
      write_project_file("config/initializers/react_on_rails.rb", <<~RUBY)
        ReactOnRails.configure do |config|
          config.build_test_command = "RAILS_ENV=test bin/shakapacker"
        end
      RUBY
      write_project_file("config/shakapacker.yml", <<~YAML)
        development:
          public_output_path: packs

        test:
          public_output_path: packs-test
          compile: false
      YAML
      write_project_file("spec/rails_helper.rb", <<~RUBY)
        require "react_on_rails/test_helper"
        RSpec.configure do |config|
          ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
        end
      RUBY

      doctor.send(:check_build_test_configuration)

      success_messages = checker.messages.select { |msg| msg[:type] == :success }.map { |msg| msg[:content] }
      expect(success_messages).to include(a_string_including("separate public_output_path values"))
    end

    it "uses inherited default output paths when analyzing test/dev workflow" do
      write_project_file("config/initializers/react_on_rails.rb", <<~RUBY)
        ReactOnRails.configure do |config|
          config.build_test_command = "RAILS_ENV=test bin/shakapacker"
        end
      RUBY
      write_project_file("config/shakapacker.yml", <<~YAML)
        default: &default
          public_output_path: packs

        development:
          <<: *default

        test:
          <<: *default
          public_output_path: packs-test
          compile: false
      YAML
      write_project_file("spec/rails_helper.rb", <<~RUBY)
        require "react_on_rails/test_helper"
        RSpec.configure do |config|
          ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
        end
      RUBY

      doctor.send(:check_build_test_configuration)

      success_messages = checker.messages.select { |msg| msg[:type] == :success }.map { |msg| msg[:content] }
      expect(success_messages).to include(a_string_including("separate public_output_path values"))
    end

    it "warns when development and test share public_output_path" do
      write_project_file("config/initializers/react_on_rails.rb", <<~RUBY)
        ReactOnRails.configure do |config|
          config.build_test_command = "RAILS_ENV=test bin/shakapacker"
        end
      RUBY
      write_project_file("config/shakapacker.yml", <<~YAML)
        default:
          private_output_path: ssr-generated

        development:
          public_output_path: packs

        test:
          public_output_path: packs
          compile: false
      YAML
      write_project_file("spec/rails_helper.rb", <<~RUBY)
        require "react_on_rails/test_helper"
        RSpec.configure do |config|
          ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
        end
      RUBY

      doctor.send(:check_build_test_configuration)

      warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
      info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
      expect(warning_messages).to include(a_string_including("share public_output_path 'packs'"))
      expect(info_messages).to include(a_string_including("advanced workflow meant for bin/dev static"))
    end

    it "raises an error for shared output path when HMR Procfile exists without static Procfile" do
      write_project_file("config/initializers/react_on_rails.rb", <<~RUBY)
        ReactOnRails.configure do |config|
          config.build_test_command = "RAILS_ENV=test bin/shakapacker"
        end
      RUBY
      write_project_file("config/shakapacker.yml", <<~YAML)
        development:
          public_output_path: packs

        test:
          public_output_path: packs
          compile: false
      YAML
      write_project_file("spec/rails_helper.rb", <<~RUBY)
        require "react_on_rails/test_helper"
        RSpec.configure do |config|
          ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
        end
      RUBY
      write_project_file("Procfile.dev", <<~PROCFILE)
        rails: bundle exec rails s -p ${PORT:-3000}
        dev-server: bin/shakapacker-dev-server
      PROCFILE

      doctor.send(:check_build_test_configuration)

      error_messages = checker.messages.select { |msg| msg[:type] == :error }.map { |msg| msg[:content] }
      expect(error_messages).to include(a_string_including("Procfile.dev-static-assets is missing"))
    end

    context "with fix enabled" do
      let(:fix_mode) { true }

      it "adds missing minitest helper wiring in mixed setup" do
        write_project_file("config/initializers/react_on_rails.rb", <<~RUBY)
          ReactOnRails.configure do |config|
            config.build_test_command = "RAILS_ENV=test bin/shakapacker"
          end
        RUBY
        write_project_file("config/shakapacker.yml", <<~YAML)
          test:
            compile: false
        YAML
        write_project_file("spec/rails_helper.rb", <<~RUBY)
          require "react_on_rails/test_helper"
          RSpec.configure do |config|
            ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
          end
        RUBY
        write_project_file("test/test_helper.rb", <<~RUBY)
          require "rails/test_help"
        RUBY

        doctor.send(:check_build_test_configuration)

        helper_content = File.read("test/test_helper.rb")
        expect(helper_content).to include('require "react_on_rails/test_helper"')
        expect(helper_content).to include("ReactOnRails::TestHelper.ensure_assets_compiled")
      end

      it "sets test compile to false when both approaches are configured" do
        write_project_file("config/initializers/react_on_rails.rb", <<~RUBY)
          ReactOnRails.configure do |config|
            config.build_test_command = "RAILS_ENV=test bin/shakapacker"
          end
        RUBY
        write_project_file("config/shakapacker.yml", <<~YAML)
          default: &default
            source_path: app/javascript

          test:
            <<: *default
            compile: true
        YAML
        write_project_file("spec/rails_helper.rb", <<~RUBY)
          require "react_on_rails/test_helper"
          RSpec.configure do |config|
            ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
          end
        RUBY

        doctor.send(:check_build_test_configuration)

        expect(File.read("config/shakapacker.yml")).to include("compile: false")
      end

      it "adds build_test_command when helper is configured without it" do
        write_project_file("config/initializers/react_on_rails.rb", <<~RUBY)
          ReactOnRails.configure do |config|
            config.auto_load_bundle = true
          end
        RUBY
        write_project_file("config/shakapacker.yml", <<~YAML)
          test:
            compile: false
        YAML
        write_project_file("spec/rails_helper.rb", <<~RUBY)
          require "react_on_rails/test_helper"
          RSpec.configure do |config|
            ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
          end
        RUBY

        doctor.send(:check_build_test_configuration)

        expect(File.read("config/initializers/react_on_rails.rb")).to include(
          'config.build_test_command = "RAILS_ENV=test bin/shakapacker"'
        )
      end
    end

    it "reports helper status per framework" do
      write_project_file("spec/rails_helper.rb", <<~RUBY)
        require "react_on_rails/test_helper"
        RSpec.configure do |config|
          ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
        end
      RUBY
      write_project_file("test/test_helper.rb", <<~RUBY)
        require "rails/test_help"
      RUBY

      doctor.send(:check_test_helper_setup)

      success_messages = checker.messages.select { |msg| msg[:type] == :success }.map { |msg| msg[:content] }
      info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }

      expect(success_messages).to include(
        a_string_including("configured for RSpec in spec/rails_helper.rb")
      )
      expect(info_messages).to include(
        a_string_including("missing for Minitest in test/test_helper.rb")
      )
    end

    it "detects RSpec helper setup from spec/spec_helper.rb when rails_helper.rb exists" do
      write_project_file("config/initializers/react_on_rails.rb", <<~RUBY)
        ReactOnRails.configure do |config|
          config.build_test_command = "RAILS_ENV=test bin/shakapacker"
        end
      RUBY
      write_project_file("config/shakapacker.yml", <<~YAML)
        test:
          compile: false
      YAML
      write_project_file("spec/rails_helper.rb", <<~RUBY)
        require "spec_helper"
        RSpec.configure do |config|
          config.example_status_persistence_file_path = "spec/examples.txt"
        end
      RUBY
      write_project_file("spec/spec_helper.rb", <<~RUBY)
        RSpec.configure do |config|
          ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
        end
      RUBY

      doctor.send(:check_build_test_configuration)

      warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
      expect(warning_messages).not_to include(a_string_including("missing for RSpec"))
    end

    it "does not emit helper-missing warning when both compile:true and build_test_command are set" do
      write_project_file("config/initializers/react_on_rails.rb", <<~RUBY)
        ReactOnRails.configure do |config|
          config.build_test_command = "RAILS_ENV=test bin/shakapacker"
        end
      RUBY
      write_project_file("config/shakapacker.yml", <<~YAML)
        test:
          compile: true
      YAML

      doctor.send(:check_build_test_configuration)

      warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
      expect(warning_messages).to include(a_string_including("Both build_test_command and shakapacker compile: true"))
      expect(warning_messages).not_to include(a_string_including("no test helper files were found"))
    end

    describe "#check_shared_output_paths_with_hmr" do
      let(:shared_hmr_shakapacker) do
        <<~YAML
          default: &default
            source_path: client/app

          development:
            <<: *default
            public_output_path: packs
            dev_server:
              hmr: true

          test:
            <<: *default
            public_output_path: packs
            compile: false
        YAML
      end

      let(:default_initializer) do
        <<~RUBY
          ReactOnRails.configure do |config|
            config.build_test_command = "RAILS_ENV=test bin/shakapacker"
          end
        RUBY
      end

      def setup_shared_hmr_config
        write_project_file("config/shakapacker.yml", shared_hmr_shakapacker)
        write_project_file("config/initializers/react_on_rails.rb", default_initializer)
      end

      it "warns when shared output paths AND hmr: true AND Capybara uses own server" do
        setup_shared_hmr_config
        write_project_file("spec/rails_helper.rb", <<~RUBY)
          require "capybara/rails"
          require "react_on_rails/test_helper"
          Capybara.register_driver :selenium_chrome_headless do |app|
            Capybara::Selenium::Driver.new(app, browser: :chrome)
          end
          RSpec.configure do |config|
            ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
          end
        RUBY

        doctor.send(:check_build_test_configuration)
        doctor.send(:check_shared_output_paths_with_hmr)

        warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
        expect(warning_messages).to include(a_string_including("Shared output paths with dev_server.hmr: true"))
      end

      it "does not warn when separate output paths AND hmr: true" do
        write_project_file("config/shakapacker.yml", <<~YAML)
          development:
            public_output_path: packs
            dev_server:
              hmr: true

          test:
            public_output_path: packs-test
            compile: false
        YAML
        write_project_file("config/initializers/react_on_rails.rb", default_initializer)
        write_project_file("spec/rails_helper.rb", <<~RUBY)
          require "capybara/rails"
          require "react_on_rails/test_helper"
          RSpec.configure do |config|
            ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
          end
        RUBY

        doctor.send(:check_build_test_configuration)
        doctor.send(:check_shared_output_paths_with_hmr)

        warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
        expect(warning_messages).not_to include(a_string_including("Shared output paths with dev_server.hmr"))
      end

      it "does not warn when Capybara uses run_server = false (external server mode)" do
        setup_shared_hmr_config
        write_project_file("spec/rails_helper.rb", <<~RUBY)
          require "capybara/rails"
          require "react_on_rails/test_helper"
          Capybara.app_host = "http://localhost:3000"
          Capybara.run_server = false
          RSpec.configure do |config|
            ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
          end
        RUBY

        doctor.send(:check_build_test_configuration)
        doctor.send(:check_shared_output_paths_with_hmr)

        warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
        expect(warning_messages).not_to include(a_string_including("Shared output paths with dev_server.hmr"))
      end

      it "does not warn when no Capybara is configured (Playwright/Cypress only)" do
        setup_shared_hmr_config
        write_project_file("spec/rails_helper.rb", <<~RUBY)
          require "react_on_rails/test_helper"
          RSpec.configure do |config|
            ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)
          end
        RUBY

        doctor.send(:check_build_test_configuration)
        doctor.send(:check_shared_output_paths_with_hmr)

        warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
        expect(warning_messages).not_to include(a_string_including("Shared output paths with dev_server.hmr"))
      end

      it "does not warn when no test helper files exist (Playwright/Cypress only)" do
        setup_shared_hmr_config

        doctor.send(:check_build_test_configuration)
        doctor.send(:check_shared_output_paths_with_hmr)

        warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
        expect(warning_messages).not_to include(a_string_including("Shared output paths with dev_server.hmr"))
      end
    end

    describe "#check_minitest_system_test_wiring" do
      it "warns when application_system_test_case.rb exists but ensure_assets_compiled is missing" do
        write_project_file("test/application_system_test_case.rb", <<~RUBY)
          class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
            driven_by :selenium, using: :chrome
          end
        RUBY
        write_project_file("test/test_helper.rb", <<~RUBY)
          require "rails/test_help"
        RUBY

        doctor.send(:check_minitest_system_test_wiring)

        warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
        expect(warning_messages).to include(
          a_string_including("ensure_assets_compiled")
        )
      end

      it "reports success when system test case and ensure_assets_compiled are both present" do
        write_project_file("test/application_system_test_case.rb", <<~RUBY)
          class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
            driven_by :selenium, using: :chrome
          end
        RUBY
        write_project_file("test/test_helper.rb", <<~RUBY)
          require "react_on_rails/test_helper"
          ActiveSupport::TestCase.setup do
            ReactOnRails::TestHelper.ensure_assets_compiled
          end
        RUBY

        doctor.send(:check_minitest_system_test_wiring)

        success_messages = checker.messages.select { |msg| msg[:type] == :success }.map { |msg| msg[:content] }
        expect(success_messages).to include(
          a_string_including("Minitest system tests detected with ensure_assets_compiled")
        )
      end

      it "does nothing when no application_system_test_case.rb exists" do
        initial_count = checker.messages.length
        doctor.send(:check_minitest_system_test_wiring)
        expect(checker.messages.length).to eq(initial_count)
      end

      context "with fix enabled" do
        let(:fix_mode) { true }

        it "adds ensure_assets_compiled to test_helper.rb" do
          write_project_file("test/application_system_test_case.rb", <<~RUBY)
            class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
              driven_by :selenium, using: :chrome
            end
          RUBY
          write_project_file("test/test_helper.rb", <<~RUBY)
            require "rails/test_help"
          RUBY

          doctor.send(:check_minitest_system_test_wiring)

          helper_content = File.read("test/test_helper.rb")
          expect(helper_content).to include("ensure_assets_compiled")
        end
      end
    end

    describe "#check_capybara_external_server_mode" do
      it "detects Capybara.run_server = false in rails_helper.rb" do
        write_project_file("spec/rails_helper.rb", <<~RUBY)
          require "capybara/rails"
          Capybara.app_host = "http://localhost:3000"
          Capybara.run_server = false
        RUBY

        doctor.send(:check_capybara_external_server_mode)

        info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
        expect(info_messages).to include(
          a_string_including("Capybara.run_server = false")
        )
        expect(info_messages).to include(
          a_string_including("bin/dev")
        )
      end

      it "reports custom driver registrations" do
        write_project_file("spec/rails_helper.rb", <<~RUBY)
          require "capybara/rails"
          Capybara.register_driver :selenium_chrome_headless do |app|
            Capybara::Selenium::Driver.new(app, browser: :chrome)
          end
        RUBY

        doctor.send(:check_capybara_external_server_mode)

        info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
        expect(info_messages).to include(
          a_string_including(":selenium_chrome_headless")
        )
      end

      it "notes HMR limitation for standard Capybara mode" do
        write_project_file("spec/rails_helper.rb", <<~RUBY)
          require "capybara/rails"
          Capybara.default_driver = :selenium_chrome_headless
        RUBY

        doctor.send(:check_capybara_external_server_mode)

        info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
        expect(info_messages).to include(
          a_string_including("HMR assets won't work")
        )
      end

      it "does nothing when no helper files mention capybara" do
        initial_count = checker.messages.length
        doctor.send(:check_capybara_external_server_mode)
        expect(checker.messages.length).to eq(initial_count)
      end
    end
  end

  describe "server bundle path Shakapacker integration" do
    let(:doctor) { described_class.new }
    let(:checker) { doctor.instance_variable_get(:@checker) }

    before do
      allow(checker).to receive(:add_info)
      allow(checker).to receive(:add_success)
      allow(checker).to receive(:add_warning)
    end

    describe "#check_shakapacker_private_output_path" do
      context "when Shakapacker is not defined" do
        before do
          hide_const("::Shakapacker")
        end

        it "reports manual configuration" do
          expect(checker).to receive(:add_info).with("\n  ℹ️  Shakapacker not detected - using manual configuration")
          doctor.send(:check_shakapacker_private_output_path, "ssr-generated")
        end
      end

      context "when Shakapacker does not support private_output_path (pre-9.0)" do
        let(:shakapacker_module) { Module.new }
        let(:shakapacker_config) { instance_double(Shakapacker::Configuration) }

        before do
          config = shakapacker_config
          stub_const("::Shakapacker", shakapacker_module)
          shakapacker_module.define_singleton_method(:config) { config }
          allow(shakapacker_config).to receive(:respond_to?).with(:private_output_path).and_return(false)
        end

        it "recommends upgrading to Shakapacker 9.0+" do
          expect(checker).to receive(:add_info).with(/Recommendation: Upgrade to Shakapacker 9\.0\+/)
          doctor.send(:check_shakapacker_private_output_path, "ssr-generated")
        end
      end

      context "when Shakapacker 9.0+ is available" do
        let(:shakapacker_module) { Module.new }
        let(:shakapacker_config) { instance_double(Shakapacker::Configuration) }
        let(:rails_module) { Module.new }
        let(:rails_root) { instance_double(Pathname, to_s: "/app") }

        before do
          config = shakapacker_config
          root = rails_root
          stub_const("::Shakapacker", shakapacker_module)
          stub_const("Rails", rails_module)
          shakapacker_module.define_singleton_method(:config) { config }
          rails_module.define_singleton_method(:root) { root }
          allow(shakapacker_config).to receive(:respond_to?).with(:private_output_path).and_return(true)
        end

        it "reports success when private_output_path matches" do
          private_path = instance_double(Pathname, to_s: "/app/ssr-generated")
          allow(shakapacker_config).to receive(:private_output_path).and_return(private_path)

          success_msg = "\n  ✅ Using Shakapacker 9.0+ private_output_path: 'ssr-generated'"
          info_msg = "     Auto-detected from shakapacker.yml - no manual config needed"
          expect(checker).to receive(:add_success).with(success_msg)
          expect(checker).to receive(:add_info).with(info_msg)
          doctor.send(:check_shakapacker_private_output_path, "ssr-generated")
        end

        it "warns when private_output_path doesn't match" do
          private_path = instance_double(Pathname, to_s: "/app/server-bundles")
          allow(shakapacker_config).to receive(:private_output_path).and_return(private_path)

          expect(checker).to receive(:add_warning).with(/Configuration mismatch detected/)
          doctor.send(:check_shakapacker_private_output_path, "ssr-generated")
        end

        it "includes both paths in mismatch warning" do
          private_path = instance_double(Pathname, to_s: "/app/server-bundles")
          allow(shakapacker_config).to receive(:private_output_path).and_return(private_path)

          expect(checker).to receive(:add_warning) do |msg|
            expect(msg).to include("Shakapacker private_output_path: 'server-bundles'")
            expect(msg).to include("React on Rails server_bundle_output_path: 'ssr-generated'")
          end
          doctor.send(:check_shakapacker_private_output_path, "ssr-generated")
        end

        it "recommends configuring when private_output_path not set" do
          allow(shakapacker_config).to receive(:private_output_path).and_return(nil)

          recommendation_msg = /Recommendation: Configure private_output_path in shakapacker\.yml/
          expect(checker).to receive(:add_info).with(recommendation_msg)
          doctor.send(:check_shakapacker_private_output_path, "ssr-generated")
        end

        it "provides configuration example when not set" do
          allow(shakapacker_config).to receive(:private_output_path).and_return(nil)

          expect(checker).to receive(:add_info) do |msg|
            expect(msg).to include("private_output_path: ssr-generated")
          end
          doctor.send(:check_shakapacker_private_output_path, "ssr-generated")
        end

        it "handles errors gracefully" do
          allow(shakapacker_config).to receive(:private_output_path).and_raise(StandardError, "Config error")

          expect(checker).to receive(:add_info).with("\n  ℹ️  Could not check Shakapacker config: Config error")
          doctor.send(:check_shakapacker_private_output_path, "ssr-generated")
        end
      end
    end
  end

  describe "Pro package consistency checks" do
    let(:doctor) { described_class.new }
    let(:checker) { doctor.instance_variable_get(:@checker) }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("package.json").and_return(true)
    end

    context "when both react-on-rails and react-on-rails-pro npm packages are installed" do
      before do
        allow(File).to receive(:read).with("package.json").and_return(
          JSON.generate({ "dependencies" => { "react-on-rails" => "16.4.0", "react-on-rails-pro" => "16.4.0" } })
        )
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
        allow(ReactOnRails::Utils).to receive(:package_manager_remove_command)
          .with("react-on-rails").and_return("npm remove react-on-rails")
      end

      it "reports an error about duplicate packages" do
        expect(checker).to receive(:add_error).with(/Both 'react-on-rails' and 'react-on-rails-pro'/)
        doctor.send(:check_pro_package_consistency)
      end
    end

    context "when Pro gem is installed but using base npm package" do
      before do
        allow(File).to receive(:read).with("package.json").and_return(
          JSON.generate({ "dependencies" => { "react-on-rails" => "16.4.0" } })
        )
        allow(ReactOnRails::Utils).to receive_messages(
          react_on_rails_pro?: true,
          react_on_rails_pro_version: "16.4.0",
          package_manager_install_exact_command: "npm install react-on-rails-pro@16.4.0"
        )
      end

      it "reports an error about gem/package mismatch" do
        expect(checker).to receive(:add_error).with(/Pro gem is installed but using the base/)
        doctor.send(:check_pro_package_consistency)
      end
    end

    context "when Pro npm package is installed without Pro gem" do
      before do
        allow(File).to receive(:read).with("package.json").and_return(
          JSON.generate({ "dependencies" => { "react-on-rails-pro" => "16.4.0" } })
        )
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
      end

      it "reports an error about missing Pro gem" do
        expect(checker).to receive(:add_error).with(/npm package is installed but the Pro gem is not/)
        doctor.send(:check_pro_package_consistency)
      end
    end

    context "when packages and gems are consistent" do
      before do
        allow(File).to receive(:read).with("package.json").and_return(
          JSON.generate({ "dependencies" => { "react-on-rails" => "16.4.0" } })
        )
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
      end

      it "reports no errors" do
        expect(checker).not_to receive(:add_error)
        doctor.send(:check_pro_package_consistency)
      end
    end

    context "when package.json is located in a configured JS workspace" do
      before do
        rails_root = Pathname.new("/tmp/myapp")
        package_json_path = rails_root.join("client", "package.json").to_s
        allow(Rails).to receive(:root).and_return(rails_root)
        allow(ReactOnRails).to receive(:configuration).and_return(
          instance_double(ReactOnRails::Configuration, node_modules_location: "client")
        )
        allow(File).to receive(:exist?).with(package_json_path).and_return(true)
        allow(File).to receive(:read).with(package_json_path).and_return(
          JSON.generate({ "dependencies" => { "react-on-rails-pro" => "16.4.0" } })
        )
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
      end

      it "uses the configured workspace package.json path" do
        expect(checker).to receive(:add_error).with(/npm package is installed but the Pro gem is not/)
        doctor.send(:check_pro_package_consistency)
      end
    end
  end

  describe "private path resolution helpers" do
    describe "#resolved_webpack_config_path" do
      it "prefers shakapacker-derived webpack config candidates over the default path" do
        allow(File).to receive(:exist?).and_return(false)
        allow(File).to receive(:exist?).with("config/custom/webpack.config.ts").and_return(true)
        allow(doctor).to receive(:shakapacker_webpack_config_directory).and_return("config/custom")

        expect(doctor.send(:resolved_webpack_config_path)).to eq("config/custom/webpack.config.ts")
      end

      it "resolves rspack config candidates from the shakapacker-derived directory" do
        allow(File).to receive(:exist?).and_return(false)
        allow(File).to receive(:exist?).with("config/rspack/rspack.config.ts").and_return(true)
        allow(doctor).to receive(:shakapacker_webpack_config_directory).and_return("config/rspack")

        expect(doctor.send(:resolved_webpack_config_path)).to eq("config/rspack/rspack.config.ts")
      end

      it "falls back to default rspack config paths when shakapacker directory is unavailable" do
        allow(File).to receive(:exist?).and_return(false)
        allow(File).to receive(:exist?).with("config/rspack/rspack.config.js").and_return(true)
        allow(doctor).to receive(:shakapacker_webpack_config_directory).and_return(nil)

        expect(doctor.send(:resolved_webpack_config_path)).to eq("config/rspack/rspack.config.js")
      end
    end

    describe "#shakapacker_webpack_config_directory" do
      it "extracts a directory from shakapacker's config file path" do
        allow(doctor).to receive(:require).with("shakapacker").and_return(true)
        shakapacker_config = Struct.new(:assets_bundler_config_path).new(
          "#{Rails.root}/config/custom/webpack.config.ts"
        )
        shakapacker_class = Class.new do
          class << self
            attr_accessor :config
          end
        end
        stub_const("Shakapacker", shakapacker_class)
        Shakapacker.config = shakapacker_config

        expect(doctor.send(:shakapacker_webpack_config_directory)).to eq("config/custom")
      end
    end
  end
end

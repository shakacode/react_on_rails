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
        report_bundler_version: true,
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

    it "uses a neutral bundler configuration section header" do
      checker = doctor.instance_variable_get(:@checker)
      messages = []
      allow(checker).to receive(:messages).and_return(messages)
      allow(checker).to receive(:check_webpack_configuration) do
        messages << { type: :success, content: "Bundler config checked" }
      end

      expect(doctor).to receive(:puts).with(/Bundler Configuration:/)
      expect(doctor).not_to receive(:puts).with(/Webpack Configuration:/)

      doctor.run_diagnosis
    end
  end

  describe "JSON output format" do
    let(:json_doctor) { described_class.new(format: :json) }

    # All check section methods are stubbed so no real system inspection runs;
    # messages_by_id injects SystemChecker-style messages for specific sections.
    def stub_check_sections(doctor, messages_by_id = {})
      checker = doctor.instance_variable_get(:@checker)
      described_class::CHECK_SECTIONS.each do |section|
        allow(doctor).to receive(section[:method]) do
          (messages_by_id[section[:id]] || []).each { |message| checker.messages << message }
        end
      end
    end

    def run_and_parse_json(doctor)
      output = []
      allow(doctor).to receive(:exit)
      allow(doctor).to receive(:puts) { |arg| output << arg.to_s }
      doctor.run_diagnosis
      JSON.parse(output.join("\n"))
    end

    it "rejects unknown formats" do
      expect { described_class.new(format: :xml) }.to raise_error(ArgumentError, /Invalid doctor format/)
    end

    it "rejects nil and other non-symbolizable formats with ArgumentError" do
      expect { described_class.new(format: nil) }.to raise_error(ArgumentError, /Invalid doctor format/)
      expect { described_class.new(format: 42) }.to raise_error(ArgumentError, /Invalid doctor format/)
    end

    it "accepts the format as a string" do
      expect(described_class.new(format: "json").send(:format)).to eq(:json)
    end

    it "emits valid JSON with schema_version and ror_version" do
      stub_check_sections(json_doctor)
      report = run_and_parse_json(json_doctor)

      expect(report["schema_version"]).to eq(1)
      expect(report["ror_version"]).to eq(ReactOnRails::VERSION)
    end

    it "emits one entry per check section with stable snake_case ids" do
      stub_check_sections(json_doctor)
      report = run_and_parse_json(json_doctor)

      expect(report["checks"].map { |check| check["id"] }).to eq(
        %w[
          environment_prerequisites
          react_on_rails_versions
          react_on_rails_packages
          javascript_package_dependencies
          key_configuration_files
          configuration_analysis
          bin_dev_launcher_setup
          rails_integration
          bundler_configuration
          testing_setup
          development_environment
          react_on_rails_pro_setup
          react_server_components
        ]
      )
    end

    it "maps message severities to pass/warn/fail statuses with summary counts" do
      stub_check_sections(
        json_doctor,
        "environment_prerequisites" => [
          { type: :success, content: "Node OK" },
          { type: :error, content: "Missing package manager" }
        ],
        "react_on_rails_versions" => [{ type: :warning, content: "Version drift" }],
        "rails_integration" => [{ type: :success, content: "Rails detected" }]
      )
      report = run_and_parse_json(json_doctor)
      checks_by_id = report["checks"].to_h { |check| [check["id"], check] }

      expect(checks_by_id["environment_prerequisites"]["status"]).to eq("fail")
      expect(checks_by_id["react_on_rails_versions"]["status"]).to eq("warn")
      expect(checks_by_id["rails_integration"]["status"]).to eq("pass")
      expect(report["status"]).to eq("fail")
      expect(report["summary"]).to eq("pass" => 11, "warn" => 1, "fail" => 1)
      expect(report["checks"].map { |check| check["status"] }.uniq).to all(match(/\A(pass|warn|fail)\z/))
    end

    it "surfaces the most severe message and full details per check" do
      stub_check_sections(
        json_doctor,
        "environment_prerequisites" => [
          { type: :info, content: "Checking environment" },
          { type: :warning, content: "Old Node version" },
          { type: :error, content: "Missing package manager" }
        ]
      )
      report = run_and_parse_json(json_doctor)
      check = report["checks"].first

      expect(check["message"]).to eq("Missing package manager")
      expect(check["details"]).to eq(
        [
          { "level" => "info", "content" => "Checking environment" },
          { "level" => "warning", "content" => "Old Node version" },
          { "level" => "error", "content" => "Missing package manager" }
        ]
      )
    end

    it "reports a null message for passing checks even when info/success details exist" do
      stub_check_sections(
        json_doctor,
        "rails_integration" => [
          { type: :info, content: "Checking Rails" },
          { type: :success, content: "Rails detected" }
        ]
      )
      report = run_and_parse_json(json_doctor)
      check = report["checks"].find { |entry| entry["id"] == "rails_integration" }

      expect(check["status"]).to eq("pass")
      expect(check["message"]).to be_nil
      expect(check["details"].length).to eq(2)
    end

    it "reports warn overall status and exit code 0 when only warnings exist" do
      stub_check_sections(json_doctor, "testing_setup" => [{ type: :warning, content: "No test helper" }])
      allow(json_doctor).to receive(:puts)

      expect(json_doctor).to receive(:exit).with(0)
      json_doctor.run_diagnosis
    end

    it "exits with status 1 when any check fails" do
      stub_check_sections(json_doctor, "rails_integration" => [{ type: :error, content: "No Rails app" }])
      allow(json_doctor).to receive(:puts)

      expect(json_doctor).to receive(:exit).with(1)
      json_doctor.run_diagnosis
    end

    it "redirects stray check output to stderr so stdout stays valid JSON" do
      stub_check_sections(json_doctor)
      checker = json_doctor.instance_variable_get(:@checker)
      allow(json_doctor).to receive(:check_environment) do
        puts "stray check output"
        checker.messages << { type: :success, content: "Node OK" }
      end
      allow(json_doctor).to receive(:exit)

      output = []
      allow(json_doctor).to receive(:puts) { |arg| output << arg.to_s }

      expect { json_doctor.run_diagnosis }.to output(/stray check output/).to_stderr
      expect { JSON.parse(output.join("\n")) }.not_to raise_error
      expect(output.join).not_to include("stray check output")
    end

    it "captures fd-level stdout writes (STDOUT/subprocesses), not just $stdout" do
      stub_check_sections(json_doctor)
      allow(json_doctor).to receive(:check_environment) do
        STDOUT.puts "fd-level stray output" # rubocop:disable Style/GlobalStdStream
        system("echo subprocess stray output")
      end
      allow(json_doctor).to receive(:exit)

      output = []
      allow(json_doctor).to receive(:puts) { |arg| output << arg.to_s }

      expect { json_doctor.run_diagnosis }
        .to output(/fd-level stray output.*subprocess stray output/m).to_stderr
      expect { JSON.parse(output.join("\n")) }.not_to raise_error
      expect(output.join).not_to include("stray output")
    end

    it "keeps the human-readable text format as the default" do
      default_doctor = described_class.new
      expect(default_doctor.send(:format)).to eq(:text)
    end
  end

  describe "#dev_server_label" do
    it "uses the canonical webpack-dev-server spelling for webpack apps" do
      allow(doctor).to receive(:configured_assets_bundler).and_return("webpack")

      expect(doctor.send(:dev_server_label)).to eq("webpack-dev-server")
    end
  end

  describe "#parsed_shakapacker_config" do
    it "reads and parses config/shakapacker.yml at most once per Doctor instance" do
      # Exercises Doctor's memoizing super override: several checks consult the
      # config through different private helpers, but one diagnosis must read and
      # parse config/shakapacker.yml only once. Stubbing File keeps both the
      # memoization and the shared helper implementation in the path under test.
      config_path = "/tmp/myapp/config/shakapacker.yml"
      allow(doctor).to receive(:shakapacker_config_path).and_return(config_path)
      allow(File).to receive(:exist?).with(config_path).and_return(true)
      allow(File).to receive(:read).with(config_path).and_return("default:\n  assets_bundler: rspack\n")

      first = doctor.send(:parsed_shakapacker_config)
      doctor.send(:active_assets_bundler)
      doctor.send(:development_hmr_enabled?)
      second = doctor.send(:parsed_shakapacker_config)

      aggregate_failures do
        expect(first).to be(second)
        expect(File).to have_received(:read).with(config_path).once
      end
    end

    it "memoizes nil when config/shakapacker.yml is missing" do
      config_path = "/tmp/myapp/config/shakapacker.yml"
      allow(doctor).to receive(:shakapacker_config_path).and_return(config_path)
      allow(File).to receive(:exist?).with(config_path).and_return(false)

      first = doctor.send(:parsed_shakapacker_config)
      doctor.send(:active_assets_bundler)
      second = doctor.send(:parsed_shakapacker_config)

      aggregate_failures do
        expect(first).to be_nil
        expect(second).to be_nil
        expect(File).to have_received(:exist?).with(config_path).once
      end
    end

    it "memoizes nil when config/shakapacker.yml cannot be read" do
      config_path = "/tmp/myapp/config/shakapacker.yml"
      allow(doctor).to receive(:shakapacker_config_path).and_return(config_path)
      allow(File).to receive(:exist?).with(config_path).and_return(true)
      allow(File).to receive(:read).with(config_path).and_raise(Errno::EACCES)

      first = doctor.send(:parsed_shakapacker_config)
      doctor.send(:active_assets_bundler)
      second = doctor.send(:parsed_shakapacker_config)

      aggregate_failures do
        expect(first).to be_nil
        expect(second).to be_nil
        expect(File).to have_received(:read).with(config_path).once
      end
    end
  end

  describe "#development_dev_server_config" do
    it "defaults to HMR when development dev_server override omits mode keys" do
      allow(doctor).to receive(:parsed_shakapacker_config).and_return(
        "default" => { "dev_server" => { "hmr" => true, "host" => "0.0.0.0" } },
        "development" => { "dev_server" => { "port" => 3035 } }
      )

      aggregate_failures do
        expect(doctor.send(:development_dev_server_config)).to eq("port" => 3035)
        expect(doctor.send(:development_hmr_enabled?)).to be(true)
      end
    end

    it "normalizes selected dev_server keys to strings" do
      allow(doctor).to receive(:parsed_shakapacker_config).and_return(
        "default" => { dev_server: { hmr: true } },
        "development" => { "dev_server" => { "hmr" => false } }
      )

      aggregate_failures do
        expect(doctor.send(:development_dev_server_config)).to include("hmr" => false)
        expect(doctor.send(:development_dev_server_config)).not_to have_key(:hmr)
        expect(doctor.send(:development_hmr_enabled?)).to be(false)
      end
    end

    it "treats hmr only mode as HMR" do
      allow(doctor).to receive(:parsed_shakapacker_config).and_return(
        "development" => { "dev_server" => { "hmr" => "only" } }
      )

      expect(doctor.send(:development_hmr_enabled?)).to be(true)
    end
  end

  describe "#print_next_steps" do
    around do |example|
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { example.run }
      end
    end

    it "uses the configured reload mode for bin/dev next steps" do
      FileUtils.mkdir_p("bin")
      FileUtils.touch("bin/dev")
      File.write("Procfile.dev", "web: bin/rails server\njs: bin/shakapacker-dev-server\n")
      doctor.instance_variable_set(
        :@checker,
        instance_double(ReactOnRails::SystemChecker, errors?: false, warnings?: false, messages: [])
      )
      allow(doctor).to receive_messages(
        default_dev_server_mode: :live_reload,
        npm_test_script?: false,
        yarn_test_script?: false
      )
      allow(doctor).to receive(:puts)

      expect(doctor).to receive(:puts).with(a_string_including("Start development with live reload:"))

      doctor.send(:print_next_steps)
    end
  end

  describe "#check_procfiles" do
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

    it "preserves webpack-specific Procfile descriptions for webpack apps" do
      write_project_file("config/shakapacker.yml", "default:\n  assets_bundler: webpack\n")
      write_project_file("Procfile.dev", "web: bin/rails server\njs: bin/shakapacker-dev-server\n")
      write_project_file("Procfile.dev-static-assets", "web: bin/rails server\njs: bin/shakapacker --watch\n")

      doctor.send(:check_procfiles)

      success_messages = checker.messages.select { |msg| msg[:type] == :success }.map { |msg| msg[:content] }
      expect(success_messages).to include(a_string_including("Live reload development with webpack-dev-server"))
      expect(success_messages).to include(a_string_including("Static development with webpack --watch"))
    end

    it "uses neutral/rspack Procfile descriptions for rspack live-reload apps" do
      write_project_file("config/shakapacker.yml", <<~YAML)
        default:
          assets_bundler: rspack
        development:
          dev_server:
            hmr: false
            live_reload: true
      YAML
      write_project_file("Procfile.dev", "web: bin/rails server\njs: bin/shakapacker-dev-server\n")
      write_project_file("Procfile.dev-static-assets", "web: bin/rails server\njs: bin/shakapacker --watch\n")

      doctor.send(:check_procfiles)

      success_messages = checker.messages.select { |msg| msg[:type] == :success }.map { |msg| msg[:content] }
      expect(success_messages).to include(a_string_including("Live reload development with Rspack dev server"))
      expect(success_messages).to include(a_string_including("Static development with rspack watch"))
      expect(success_messages).not_to include(a_string_including("webpack-dev-server"))
      expect(success_messages).not_to include(a_string_including("webpack --watch"))
    end

    it "detects rspack Procfile descriptions from a custom SHAKAPACKER_CONFIG path" do
      old_config_path = ENV.fetch("SHAKAPACKER_CONFIG", nil)
      ENV["SHAKAPACKER_CONFIG"] = "config/custom_shakapacker.yml"

      write_project_file("config/shakapacker.yml", "default:\n  assets_bundler: webpack\n")
      write_project_file("config/custom_shakapacker.yml", <<~YAML)
        default:
          assets_bundler: rspack
        development:
          dev_server:
            hmr: false
      YAML
      write_project_file("Procfile.dev", "web: bin/rails server\njs: bin/shakapacker-dev-server\n")
      write_project_file("Procfile.dev-static-assets", "web: bin/rails server\njs: bin/shakapacker --watch\n")

      doctor.send(:check_procfiles)

      success_messages = checker.messages.select { |msg| msg[:type] == :success }.map { |msg| msg[:content] }
      expect(success_messages).to include(a_string_including("Live reload development with Rspack dev server"))
    ensure
      old_config_path.nil? ? ENV.delete("SHAKAPACKER_CONFIG") : ENV["SHAKAPACKER_CONFIG"] = old_config_path
    end

    it "treats live_reload true without hmr as live reload" do
      write_project_file("config/shakapacker.yml", <<~YAML)
        default:
          assets_bundler: rspack
        development:
          dev_server:
            live_reload: true
      YAML
      write_project_file("Procfile.dev", "web: bin/rails server\njs: bin/shakapacker-dev-server\n")
      write_project_file("Procfile.dev-static-assets", "web: bin/rails server\njs: bin/shakapacker --watch\n")

      doctor.send(:check_procfiles)

      success_messages = checker.messages.select { |msg| msg[:type] == :success }.map { |msg| msg[:content] }
      expect(success_messages).to include(a_string_including("Live reload development with Rspack dev server"))
      expect(success_messages).not_to include(a_string_including("HMR development with Rspack dev server"))
    end

    it "falls back to webpack labels when shakapacker config cannot be parsed" do
      write_project_file("config/shakapacker.yml", "default:\n  assets_bundler: [rspack\n")
      write_project_file("Procfile.dev", "web: bin/rails server\njs: bin/shakapacker-dev-server\n")
      write_project_file("Procfile.dev-static-assets", "web: bin/rails server\njs: bin/shakapacker --watch\n")

      expect { doctor.send(:check_procfiles) }.not_to raise_error

      success_messages = checker.messages.select { |msg| msg[:type] == :success }.map { |msg| msg[:content] }
      expect(success_messages).to include(a_string_including("HMR development with webpack-dev-server"))
      expect(success_messages).to include(a_string_including("Static development with webpack --watch"))
    end
  end

  describe "#check_react_on_rails_initializer" do
    let(:doctor) { described_class.new(verbose: false, fix: false) }
    let(:checker) { doctor.instance_variable_get(:@checker) }
    let(:runtime_config) do
      instance_double(
        ReactOnRails::Configuration,
        server_bundle_js_file: "runtime-server-bundle.js",
        server_bundle_output_path: "runtime-ssr-output",
        enforce_private_server_bundles: true,
        prerender: true,
        server_renderer_pool_size: 3,
        server_renderer_timeout: 45,
        raise_on_prerender_error: true,
        generated_component_packs_loading_strategy: :async,
        auto_load_bundle: true,
        component_registry_timeout: 7000,
        development_mode: false,
        trace: false,
        logging_on_server: false,
        replay_console: false,
        build_test_command: "RAILS_ENV=test bin/shakapacker",
        build_production_command: "RAILS_ENV=production bin/shakapacker",
        i18n_dir: nil,
        i18n_yml_dir: nil,
        i18n_output_format: nil,
        components_subdirectory: nil,
        same_bundle_for_client_and_server: false,
        random_dom_id: nil,
        rendering_extension: nil,
        rendering_props_extension: nil,
        server_render_method: nil
      )
    end

    around do |example|
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { example.run }
      end
    end

    def write_project_file(path, content)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
    end

    it "prefers runtime values over initializer regex parsing" do
      write_project_file("config/initializers/react_on_rails.rb", <<~RUBY)
        ReactOnRails.configure do |config|
          config.server_bundle_js_file = "initializer-server-bundle.js"
          config.prerender = false
          config.auto_load_bundle = false
        end
      RUBY

      allow(doctor).to receive(:react_on_rails_runtime_configuration).and_return(runtime_config)

      doctor.send(:check_react_on_rails_initializer)

      info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }

      expect(info_messages).to include(a_string_including("Using loaded runtime configuration values"))
      expect(info_messages).to include(a_string_including("server_bundle_js_file: runtime-server-bundle.js"))
      expect(info_messages).to include(a_string_including("prerender: true"))
      expect(info_messages).to include(a_string_including("auto_load_bundle: true"))
      expect(info_messages).not_to include(a_string_including("random_dom_id:"))
      expect(info_messages).not_to include(a_string_including("initializer-server-bundle.js"))
    end

    it "uses runtime values when initializer file is missing" do
      allow(doctor).to receive(:react_on_rails_runtime_configuration).and_return(runtime_config)

      doctor.send(:check_react_on_rails_initializer)

      warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
      info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }

      expect(warning_messages).not_to include(
        a_string_including("React on Rails configuration file not found: config/initializers/react_on_rails.rb")
      )
      expect(info_messages).to include(
        a_string_including("No config/initializers/react_on_rails.rb found (using runtime configuration)")
      )
      expect(info_messages).to include(a_string_including("Using loaded runtime configuration values"))
      expect(info_messages).to include(a_string_including("server_bundle_js_file: runtime-server-bundle.js"))
    end

    it "shows initializer/default bundle value when runtime server_bundle_js_file is nil" do
      allow(runtime_config).to receive(:server_bundle_js_file).and_return(nil)
      allow(doctor).to receive(:react_on_rails_runtime_configuration).and_return(runtime_config)

      doctor.send(:check_react_on_rails_initializer)

      info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
      expect(info_messages).to include(
        a_string_including("server_bundle_js_file: server-bundle.js (initializer/default)")
      )
    end

    it "treats whitespace-only runtime server_bundle_js_file as disabled" do
      allow(runtime_config).to receive(:server_bundle_js_file).and_return("   ")
      allow(doctor).to receive(:react_on_rails_runtime_configuration).and_return(runtime_config)

      doctor.send(:check_react_on_rails_initializer)

      info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
      expect(info_messages).to include(
        a_string_including('server_bundle_js_file: "" (disabled)')
      )
    end

    it "shows SSR-disabled default when runtime config is unavailable and initializer does not set server bundle" do
      write_project_file("config/initializers/react_on_rails.rb", <<~RUBY)
        ReactOnRails.configure do |config|
          config.prerender = false
        end
      RUBY
      allow(doctor).to receive(:react_on_rails_runtime_configuration).and_return(nil)

      doctor.send(:check_react_on_rails_initializer)

      info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
      expect(info_messages).to include(
        a_string_including('server_bundle_js_file: "" (default, SSR disabled)')
      )
    end

    it "omits component_registry_timeout when runtime value is the default" do
      allow(runtime_config).to receive(:component_registry_timeout).and_return(5000)
      allow(doctor).to receive(:react_on_rails_runtime_configuration).and_return(runtime_config)

      doctor.send(:check_react_on_rails_initializer)

      info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
      expect(info_messages).not_to include(a_string_including("component_registry_timeout"))
    end

    it "omits auto_load_bundle when runtime value is the default" do
      allow(runtime_config).to receive(:auto_load_bundle).and_return(false)
      allow(doctor).to receive(:react_on_rails_runtime_configuration).and_return(runtime_config)

      doctor.send(:check_react_on_rails_initializer)

      info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
      expect(info_messages).not_to include(a_string_including("auto_load_bundle"))
    end

    it "omits development/debugging runtime values when they match defaults" do
      allow(runtime_config).to receive_messages(
        development_mode: Rails.env.development?,
        trace: Rails.env.development?,
        logging_on_server: true,
        replay_console: true
      )
      allow(doctor).to receive(:react_on_rails_runtime_configuration).and_return(runtime_config)

      doctor.send(:check_react_on_rails_initializer)

      info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
      expect(info_messages).not_to include(a_string_including("development_mode"))
      expect(info_messages).not_to include(a_string_including("trace"))
      expect(info_messages).not_to include(a_string_including("logging_on_server"))
      expect(info_messages).not_to include(a_string_including("replay_console"))
    end

    it "reports nil logging/replay values explicitly when runtime config is unexpected" do
      allow(runtime_config).to receive_messages(logging_on_server: nil, replay_console: nil)
      allow(doctor).to receive(:react_on_rails_runtime_configuration).and_return(runtime_config)

      doctor.send(:check_react_on_rails_initializer)

      info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
      expect(info_messages).to include(a_string_including("logging_on_server: nil"))
      expect(info_messages).to include(a_string_including("replay_console: nil"))
    end

    it "omits enforce_private_server_bundles when runtime value is the default" do
      allow(runtime_config).to receive(:enforce_private_server_bundles).and_return(false)
      allow(doctor).to receive(:react_on_rails_runtime_configuration).and_return(runtime_config)

      doctor.send(:check_react_on_rails_initializer)

      info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
      expect(info_messages).not_to include(a_string_including("enforce_private_server_bundles"))
    end

    it "omits raise_on_prerender_error when runtime value matches environment default" do
      allow(runtime_config).to receive(:raise_on_prerender_error).and_return(Rails.env.development?)
      allow(doctor).to receive(:react_on_rails_runtime_configuration).and_return(runtime_config)

      doctor.send(:check_react_on_rails_initializer)

      info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
      expect(info_messages).not_to include(a_string_including("raise_on_prerender_error"))
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
          allow(File).to receive(:exist?).and_call_original
          %w[.js .jsx .ts .tsx .mjs .cjs].each do |extension|
            allow(File).to receive(:exist?).with("client/app/packs/server-bundle#{extension}").and_return(false)
          end
        end

        it "uses Shakapacker API configuration with relative paths" do
          path = doctor.send(:determine_server_bundle_path)
          expect(path).to eq("client/app/packs/server-bundle.js")
        end

        it "accepts a TypeScript server bundle source file when the configured filename is .js" do
          allow(File).to receive(:exist?).with("client/app/packs/server-bundle.ts").and_return(true)

          path = doctor.send(:determine_server_bundle_path)

          expect(path).to eq("client/app/packs/server-bundle.ts")
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
          allow(File).to receive(:exist?).and_call_original
          %w[.js .jsx .ts .tsx .mjs .cjs].each do |ext|
            allow(File).to receive(:exist?).with("client/app/packs/server-bundle#{ext}").and_return(false)
          end
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
          allow(File).to receive(:exist?).and_call_original
          %w[.js .jsx .ts .tsx .mjs .cjs].each do |ext|
            allow(File).to receive(:exist?).with("client/app/packs/server-bundle#{ext}").and_return(false)
          end
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
          allow(File).to receive(:exist?).and_call_original
          %w[.js .jsx .ts .tsx .mjs .cjs].each do |ext|
            allow(File).to receive(:exist?).with("app/javascript/packs/server-bundle#{ext}").and_return(false)
          end
        end

        it "uses default path" do
          path = doctor.send(:determine_server_bundle_path)
          expect(path).to eq("app/javascript/packs/server-bundle.js")
        end

        it "accepts a TypeScript server bundle source file" do
          allow(File).to receive(:exist?).with("app/javascript/packs/server-bundle.ts").and_return(true)

          path = doctor.send(:determine_server_bundle_path)

          expect(path).to eq("app/javascript/packs/server-bundle.ts")
        end
      end
    end

    describe "#server_bundle_filename" do
      context "when runtime config sets server_bundle_js_file to an empty string" do
        let(:runtime_config) do
          instance_double(ReactOnRails::Configuration, server_bundle_js_file: "")
        end

        before do
          allow(doctor).to receive(:react_on_rails_runtime_configuration).and_return(runtime_config)
        end

        it "returns an empty string" do
          filename = doctor.send(:server_bundle_filename)
          expect(filename).to eq("")
        end
      end

      context "when runtime config has nil server_bundle_js_file" do
        let(:runtime_config) do
          instance_double(ReactOnRails::Configuration, server_bundle_js_file: nil)
        end

        before do
          allow(doctor).to receive(:react_on_rails_runtime_configuration).and_return(runtime_config)
          allow(File).to receive(:exist?).with("config/initializers/react_on_rails.rb").and_return(false)
        end

        it "falls back to the default filename" do
          filename = doctor.send(:server_bundle_filename)
          expect(filename).to eq("server-bundle.js")
        end
      end

      context "when react_on_rails.rb has custom filename" do
        let(:initializer_content) do
          'config.server_bundle_js_file = "custom-server-bundle.js"'
        end

        before do
          allow(doctor).to receive(:react_on_rails_runtime_configuration).and_return(nil)
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
          allow(doctor).to receive(:react_on_rails_runtime_configuration).and_return(nil)
          allow(File).to receive(:exist?).with("config/initializers/react_on_rails.rb").and_return(false)
        end

        it "returns default filename" do
          filename = doctor.send(:server_bundle_filename)
          expect(filename).to eq("server-bundle.js")
        end
      end
    end
  end

  describe "#check_javascript_bundles" do
    let(:doctor) { described_class.new(verbose: false, fix: false) }
    let(:checker) { doctor.instance_variable_get(:@checker) }

    it "treats whitespace server_bundle_js_file as disabled SSR" do
      allow(doctor).to receive(:server_bundle_filename).and_return("   ")

      doctor.send(:check_javascript_bundles)

      info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
      warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }

      expect(info_messages).to include(a_string_including("skipping SSR bundle existence check"))
      expect(warning_messages).to be_empty
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
          dev_server:
            hmr: true

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
      expect(error_messages).to include(a_string_including("Shared output path + HMR Procfile.dev detected"))
    end

    it "uses the detected Procfile.dev mode when shared output path can use static mode" do
      write_project_file("config/initializers/react_on_rails.rb", <<~RUBY)
        ReactOnRails.configure do |config|
          config.build_test_command = "RAILS_ENV=test bin/shakapacker"
        end
      RUBY
      write_project_file("config/shakapacker.yml", <<~YAML)
        development:
          public_output_path: packs
          dev_server:
            hmr: false
            live_reload: true

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
      write_project_file("Procfile.dev-static-assets", <<~PROCFILE)
        assets: bin/shakapacker --watch
      PROCFILE

      doctor.send(:check_build_test_configuration)

      warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
      expect(warning_messages).to include(
        a_string_including("Live reload Procfile.dev is present. Shared output path is high-risk")
      )
      expect(warning_messages).not_to include(a_string_including("Development server Procfile.dev"))
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

      it "does not warn when development overrides the default dev_server without hmr" do
        write_project_file("config/shakapacker.yml", <<~YAML)
          default: &default
            source_path: client/app
            dev_server:
              hmr: true

          development:
            <<: *default
            public_output_path: packs
            dev_server:
              port: 3035

          test:
            <<: *default
            public_output_path: packs
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

      it "notes dev-server asset limitation for standard Capybara mode" do
        write_project_file("spec/rails_helper.rb", <<~RUBY)
          require "capybara/rails"
          Capybara.default_driver = :selenium_chrome_headless
        RUBY

        doctor.send(:check_capybara_external_server_mode)

        info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
        expect(info_messages).to include(
          a_string_including("dev-server assets won't work")
        )
      end

      it "does nothing when no helper files mention capybara" do
        initial_count = checker.messages.length
        doctor.send(:check_capybara_external_server_mode)
        expect(checker.messages.length).to eq(initial_count)
      end
    end
  end

  describe "#check_server_bundle_prerender_consistency" do
    let(:doctor) { described_class.new(verbose: false, fix: false) }
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

    context "when runtime config conflicts with initializer text" do
      let(:runtime_config) do
        instance_double(
          ReactOnRails::Configuration,
          server_bundle_js_file: "",
          prerender: true
        )
      end

      it "uses runtime values and reports missing server bundle" do
        write_project_file("config/initializers/react_on_rails.rb", <<~RUBY)
          ReactOnRails.configure do |config|
            config.server_bundle_js_file = "server-bundle.js"
            config.prerender = false
          end
        RUBY

        allow(doctor).to receive(:react_on_rails_runtime_configuration).and_return(runtime_config)

        doctor.send(:check_server_bundle_prerender_consistency)

        warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
        expect(warning_messages).to include(
          a_string_including("Server rendering is enabled but server_bundle_js_file is not configured")
        )
      end
    end

    context "when initializer is missing but runtime config is available" do
      let(:runtime_config) do
        instance_double(
          ReactOnRails::Configuration,
          server_bundle_js_file: "",
          prerender: true
        )
      end

      it "still performs the consistency check" do
        allow(doctor).to receive(:react_on_rails_runtime_configuration).and_return(runtime_config)

        doctor.send(:check_server_bundle_prerender_consistency)

        warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
        expect(warning_messages).to include(
          a_string_including("Server rendering is enabled but server_bundle_js_file is not configured")
        )
      end
    end

    context "when runtime server_bundle_js_file is nil and prerender is enabled" do
      let(:runtime_config) do
        instance_double(
          ReactOnRails::Configuration,
          server_bundle_js_file: nil,
          prerender: true
        )
      end

      it "treats nil as initializer/default fallback instead of disabled" do
        allow(doctor).to receive(:react_on_rails_runtime_configuration).and_return(runtime_config)

        doctor.send(:check_server_bundle_prerender_consistency)

        warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
        success_messages = checker.messages.select { |msg| msg[:type] == :success }.map { |msg| msg[:content] }

        expect(warning_messages).not_to include(
          a_string_including("Server rendering is enabled but server_bundle_js_file is not configured")
        )
        expect(success_messages).to include(a_string_including("Server rendering configuration is consistent"))
      end
    end

    context "when views use stream_react_component (RSC/streaming apps)" do
      it "reports consistent configuration" do
        write_project_file("config/initializers/react_on_rails.rb", <<~RUBY)
          ReactOnRails.configure do |config|
            config.server_bundle_js_file = "server-bundle.js"
          end
        RUBY
        write_project_file("app/views/hello_server/index.html.erb", <<~ERB)
          <h1>Hello Server</h1>
          <%= stream_react_component('HelloServer', props: @hello_server_props) %>
        ERB

        doctor.send(:check_server_bundle_prerender_consistency)

        success_messages = checker.messages.select { |msg| msg[:type] == :success }.map { |msg| msg[:content] }
        info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }

        expect(success_messages).to include(a_string_including("Server rendering configuration is consistent"))
        expect(info_messages).not_to include(a_string_including("remove server_bundle_js_file"))
      end
    end

    context "when views use cached_stream_react_component" do
      it "reports consistent configuration" do
        write_project_file("config/initializers/react_on_rails.rb", <<~RUBY)
          ReactOnRails.configure do |config|
            config.server_bundle_js_file = "server-bundle.js"
          end
        RUBY
        write_project_file("app/views/posts/show.html.erb", <<~ERB)
          <%= cached_stream_react_component('PostDetail', props: @post_props) %>
        ERB

        doctor.send(:check_server_bundle_prerender_consistency)

        success_messages = checker.messages.select { |msg| msg[:type] == :success }.map { |msg| msg[:content] }
        expect(success_messages).to include(a_string_including("Server rendering configuration is consistent"))
      end
    end

    context "when views use rsc_payload_react_component" do
      it "reports consistent configuration" do
        write_project_file("config/initializers/react_on_rails.rb", <<~RUBY)
          ReactOnRails.configure do |config|
            config.server_bundle_js_file = "server-bundle.js"
          end
        RUBY
        write_project_file("app/views/posts/show.html.erb", <<~ERB)
          <%= rsc_payload_react_component('PostDetail', props: @post_props) %>
        ERB

        doctor.send(:check_server_bundle_prerender_consistency)

        success_messages = checker.messages.select { |msg| msg[:type] == :success }.map { |msg| msg[:content] }
        expect(success_messages).to include(a_string_including("Server rendering configuration is consistent"))
      end
    end

    context "when views have no prerender or streaming helpers" do
      it "suggests removing server_bundle_js_file" do
        write_project_file("config/initializers/react_on_rails.rb", <<~RUBY)
          ReactOnRails.configure do |config|
            config.server_bundle_js_file = "server-bundle.js"
          end
        RUBY
        write_project_file("app/views/hello_world/index.html.erb", <<~ERB)
          <h1>Hello World</h1>
          <%= react_component("HelloWorld", props: @hello_world_props) %>
        ERB

        doctor.send(:check_server_bundle_prerender_consistency)

        info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
        expect(info_messages).to include(a_string_including("remove server_bundle_js_file"))
      end
    end
  end

  describe "#check_server_rendering_engine" do
    let(:doctor) { described_class.new(verbose: false, fix: false) }
    let(:checker) { doctor.instance_variable_get(:@checker) }
    let(:execjs_runtime) { Struct.new(:name).new("Node.js (V8)") }
    let(:execjs_module) { Struct.new(:runtime).new(execjs_runtime) }

    around do |example|
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { example.run }
      end
    end

    def write_project_file(path, content)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
    end

    context "when Pro runtime config reports NodeRenderer without initializer text" do
      before do
        allow(doctor).to receive(:resolved_pro_server_renderer).and_return("NodeRenderer")
      end

      it "treats ExecJS as fallback without rechecking Pro availability" do
        stub_const("ExecJS", execjs_module)
        expect(ReactOnRails::Utils).not_to receive(:react_on_rails_pro?)

        doctor.send(:check_server_rendering_engine)

        info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
        expect(info_messages).to include(a_string_including("Pro uses NodeRenderer"))
        expect(info_messages).to include(a_string_including("ExecJS available as fallback"))
        expect(info_messages).not_to include(a_string_matching(/^\s+ExecJS Runtime:/))
      end
    end

    context "when Pro initializer has NodeRenderer" do
      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
        write_project_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
          ReactOnRailsPro.configure do |config|
            config.server_renderer = "NodeRenderer"
          end
        RUBY
      end

      it "labels ExecJS as fallback" do
        stub_const("ExecJS", execjs_module)

        doctor.send(:check_server_rendering_engine)

        info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
        expect(info_messages).to include(a_string_including("Pro uses NodeRenderer"))
        expect(info_messages).to include(a_string_including("ExecJS available as fallback"))
        expect(info_messages).not_to include(a_string_matching(/^\s+ExecJS Runtime:/))
      end
    end

    context "when Pro initializer has NodeRenderer and ExecJS is absent" do
      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
        write_project_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
          ReactOnRailsPro.configure do |config|
            config.server_renderer = "NodeRenderer"
          end
        RUBY
        hide_const("ExecJS")
      end

      it "warns about missing ExecJS fallback" do
        doctor.send(:check_server_rendering_engine)

        info_messages = checker.messages.select { |m| m[:type] == :info }.map { |m| m[:content] }
        warning_messages = checker.messages.select { |m| m[:type] == :warning }.map { |m| m[:content] }
        expect(info_messages).to include(a_string_including("Pro uses NodeRenderer"))
        expect(warning_messages).to include(
          a_string_including("ExecJS fallback is enabled but ExecJS is not available")
        )
      end
    end

    context "when Pro initializer has NodeRenderer, ExecJS is absent, and fallback is disabled" do
      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
        write_project_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
          ReactOnRailsPro.configure do |config|
            config.server_renderer = "NodeRenderer"
            config.renderer_use_fallback_exec_js = false
          end
        RUBY
        hide_const("ExecJS")
      end

      it "does not warn about missing ExecJS fallback" do
        doctor.send(:check_server_rendering_engine)

        info_messages = checker.messages.select { |m| m[:type] == :info }.map { |m| m[:content] }
        warning_messages = checker.messages.select { |m| m[:type] == :warning }.map { |m| m[:content] }
        expect(info_messages).to include(a_string_including("Pro uses NodeRenderer"))
        expect(info_messages).to include(
          a_string_including("ExecJS fallback is disabled (renderer_use_fallback_exec_js = false)")
        )
        expect(warning_messages).not_to include(
          a_string_including("ExecJS fallback is enabled but ExecJS is not available")
        )
      end
    end

    context "when Pro initializer does not have NodeRenderer" do
      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
        write_project_file("config/initializers/react_on_rails_pro.rb", <<~RUBY)
          ReactOnRailsPro.configure do |config|
            config.prerender_caching = true
          end
        RUBY
      end

      it "reports ExecJS as primary engine" do
        stub_const("ExecJS", execjs_module)

        doctor.send(:check_server_rendering_engine)

        info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
        expect(info_messages).to include(a_string_including("ExecJS Runtime:"))
        expect(info_messages).not_to include(a_string_including("Pro uses NodeRenderer"))
      end
    end

    context "when no Pro initializer exists" do
      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
      end

      it "reports ExecJS as primary engine" do
        stub_const("ExecJS", execjs_module)

        doctor.send(:check_server_rendering_engine)

        info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
        expect(info_messages).to include(a_string_including("ExecJS Runtime:"))
      end
    end

    context "when Pro gem is not installed" do
      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
      end

      it "reports ExecJS as primary engine" do
        stub_const("ExecJS", execjs_module)

        doctor.send(:check_server_rendering_engine)

        info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
        expect(info_messages).to include(a_string_including("ExecJS Runtime:"))
      end
    end
  end

  describe "#check_bin_dev_launcher_setup" do
    let(:doctor) { described_class.new(verbose: false, fix: false) }
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

    it "warns instead of erroring when the generated launcher is missing" do
      doctor.send(:check_bin_dev_launcher_setup)

      error_messages = checker.messages.select { |msg| msg[:type] == :error }
      warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
      info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }

      expect(error_messages).to be_empty
      expect(warning_messages).to include(a_string_including("Official React on Rails bin/dev launcher not found"))
      expect(info_messages).to include(a_string_including("rails generate react_on_rails:install"))
    end

    it "acknowledges custom launchers when bin/dev is missing" do
      write_project_file("dev", <<~SH)
        #!/usr/bin/env bash
        bundle exec overmind start -f Procfile.dev
      SH

      doctor.send(:check_bin_dev_launcher_setup)

      error_messages = checker.messages.select { |msg| msg[:type] == :error }
      info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }

      expect(error_messages).to be_empty
      expect(info_messages).to include(a_string_including("Custom launcher detected"))
      expect(info_messages).to include(a_string_including("./dev"))
      expect(info_messages).to include(a_string_including("To use the official launcher instead"))
    end

    it "does not detect a dev/ directory as a custom launcher" do
      FileUtils.mkdir_p("dev")

      doctor.send(:check_bin_dev_launcher_setup)

      info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }

      expect(info_messages).not_to include(a_string_including("Custom launcher detected"))
    end

    it "skips Procfile checks for custom projects via check_bin_dev_launcher" do
      write_project_file("dev", <<~SH)
        #!/usr/bin/env bash
        bundle exec overmind start -f Procfile.dev
      SH

      doctor.send(:check_bin_dev_launcher)

      all_messages = checker.messages.map { |msg| msg[:content] }
      warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }

      expect(warning_messages).not_to include(a_string_including("Missing Procfile.dev"))
      expect(warning_messages).not_to include(a_string_including("Missing Procfile.dev-static-assets"))
      expect(warning_messages).not_to include(a_string_including("Missing Procfile.dev-prod-assets"))
      expect(all_messages).not_to include(a_string_including("Launcher Procfiles"))
    end

    it "warns when NodeRenderer static and prod Procfiles do not start the renderer on RENDERER_PORT" do
      allow(doctor).to receive(:resolved_pro_server_renderer).and_return("NodeRenderer")
      write_project_file("bin/dev", "ReactOnRails::Dev::ServerManager\n")
      write_project_file("Procfile.dev", <<~PROCFILE)
        rails: bundle exec rails s -p ${PORT:-3000}
        node-renderer: RENDERER_LOG_LEVEL=debug RENDERER_PORT=${RENDERER_PORT:-3800} node renderer/node-renderer.js
      PROCFILE
      write_project_file("Procfile.dev-static-assets", <<~PROCFILE)
        web: bin/rails server -p ${PORT:-3000}
        js: bin/shakapacker-watch --watch
      PROCFILE
      write_project_file("Procfile.dev-prod-assets", <<~PROCFILE)
        rails: bundle exec rails s -p ${PORT:-3001}
      PROCFILE

      doctor.send(:check_bin_dev_launcher)

      warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
      expect(warning_messages).to include(a_string_including("Procfile.dev-static-assets"))
      expect(warning_messages).to include(a_string_including("Procfile.dev-prod-assets"))
      expect(warning_messages).to include(a_string_including("Node Renderer on RENDERER_PORT"))
    end

    it "warns when a common Rack server command starts without the Node Renderer" do
      allow(doctor).to receive(:resolved_pro_server_renderer).and_return("NodeRenderer")
      write_project_file("bin/dev", "ReactOnRails::Dev::ServerManager\n")
      write_project_file("Procfile.dev", <<~PROCFILE)
        web: bundle exec puma -C config/puma.rb
      PROCFILE

      doctor.send(:check_bin_dev_launcher)

      warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
      expect(warning_messages).to include(a_string_including("Procfile.dev"))
      expect(warning_messages).to include(a_string_including("Node Renderer on RENDERER_PORT"))
    end

    it "accepts complete NodeRenderer Procfiles for all bin/dev modes" do
      allow(doctor).to receive(:resolved_pro_server_renderer).and_return("NodeRenderer")
      write_project_file("bin/dev", "ReactOnRails::Dev::ServerManager\n")
      write_project_file("Procfile.dev", <<~PROCFILE)
        rails: bundle exec rails s -p ${PORT:-3000}
        node-renderer: RENDERER_PORT=${RENDERER_PORT:-3800} node renderer/node-renderer.js
      PROCFILE
      write_project_file("Procfile.dev-static-assets", <<~PROCFILE)
        web: bin/rails server -p ${PORT:-3000}
        custom-renderer: RENDERER_PORT=${RENDERER_PORT:-3800} node renderer/node-renderer.js
      PROCFILE
      write_project_file("Procfile.dev-prod-assets", <<~PROCFILE)
        rails: bundle exec rails s -p ${PORT:-3001}
        node-renderer: RENDERER_PORT=${RENDERER_PORT:-3800} pnpm run node-renderer
      PROCFILE

      doctor.send(:check_bin_dev_launcher)

      warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
      expect(warning_messages).not_to include(a_string_including("Node Renderer on RENDERER_PORT"))
    end

    it "accepts npm and yarn NodeRenderer package scripts" do
      allow(doctor).to receive(:resolved_pro_server_renderer).and_return("NodeRenderer")
      write_project_file("bin/dev", "ReactOnRails::Dev::ServerManager\n")
      write_project_file("Procfile.dev", <<~PROCFILE)
        rails: bundle exec rails s -p ${PORT:-3000}
        node-renderer: RENDERER_PORT=${RENDERER_PORT:-3800} npm run node-renderer
      PROCFILE
      write_project_file("Procfile.dev-static-assets", <<~PROCFILE)
        web: bin/rails server -p ${PORT:-3000}
        node-renderer: RENDERER_PORT=${RENDERER_PORT:-3800} yarn node-renderer
      PROCFILE
      write_project_file("Procfile.dev-prod-assets", <<~PROCFILE)
        rails: bundle exec rails s -p ${PORT:-3001}
        node-renderer: RENDERER_PORT=${RENDERER_PORT:-3800} yarn run node-renderer
      PROCFILE

      doctor.send(:check_bin_dev_launcher)

      warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
      expect(warning_messages).not_to include(a_string_including("Node Renderer on RENDERER_PORT"))
    end

    it "warns when a renderer process uses RENDERER_PORT but does not start the Node Renderer" do
      allow(doctor).to receive(:resolved_pro_server_renderer).and_return("NodeRenderer")
      write_project_file("bin/dev", "ReactOnRails::Dev::ServerManager\n")
      write_project_file("Procfile.dev", <<~PROCFILE)
        rails: bundle exec rails s -p ${PORT:-3000}
        renderer: RENDERER_PORT=${RENDERER_PORT:-3800} vite
      PROCFILE
      write_project_file("Procfile.dev-static-assets", <<~PROCFILE)
        web: bin/rails server -p ${PORT:-3000}
        node-renderer: RENDERER_PORT=${RENDERER_PORT:-3800} node renderer/node-renderer.js
      PROCFILE
      write_project_file("Procfile.dev-prod-assets", <<~PROCFILE)
        rails: bundle exec rails s -p ${PORT:-3001}
        node-renderer: RENDERER_PORT=${RENDERER_PORT:-3800} pnpm run node-renderer
      PROCFILE

      doctor.send(:check_bin_dev_launcher)

      warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
      expect(warning_messages).to include(a_string_including("Procfile.dev"))
      expect(warning_messages).to include(a_string_including("Node Renderer on RENDERER_PORT"))
    end

    it "warns when a node-renderer entry omits RENDERER_PORT (matches generator's update-it-manually decision)" do
      # Mirrors the install_generator_spec case: NEW_RENDERER_COMMAND_REGEX now requires
      # RENDERER_PORT, so the generator surfaces "Update it manually" for this Procfile.
      # The doctor must agree by warning, otherwise the user gets contradictory feedback.
      allow(doctor).to receive(:resolved_pro_server_renderer).and_return("NodeRenderer")
      write_project_file("bin/dev", "ReactOnRails::Dev::ServerManager\n")
      write_project_file("Procfile.dev", <<~PROCFILE)
        rails: bundle exec rails s -p ${PORT:-3000}
        node-renderer: node renderer/node-renderer.js
      PROCFILE

      doctor.send(:check_bin_dev_launcher)

      warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
      expect(warning_messages).to include(a_string_including("Procfile.dev"))
      expect(warning_messages).to include(a_string_including("Node Renderer on RENDERER_PORT"))
    end

    it "suggests the legacy client/node-renderer.js path when that is the only renderer file present" do
      # Pro setup skips Procfile rewrites when it detects a legacy client/node-renderer.js,
      # so the doctor's suggested fix must reference the file that actually exists rather
      # than pointing the user at the renderer/ path that the generator didn't create.
      allow(doctor).to receive(:resolved_pro_server_renderer).and_return("NodeRenderer")
      write_project_file("bin/dev", "ReactOnRails::Dev::ServerManager\n")
      write_project_file("client/node-renderer.js", "// legacy renderer\n")
      write_project_file("Procfile.dev", "rails: bundle exec rails s -p ${PORT:-3000}\n")

      doctor.send(:check_bin_dev_launcher)

      warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
      expect(warning_messages).to include(a_string_including("client/node-renderer.js"))
      expect(warning_messages).not_to include(a_string_including("node renderer/node-renderer.js"))
    end

    it "labels launcher Procfile.dev as live reload when Shakapacker disables HMR" do
      write_project_file("bin/dev", "ReactOnRails::Dev::ServerManager.run_from_command_line\n")
      write_project_file("Procfile.dev", "web: bin/rails server\njs: bin/shakapacker-dev-server\n")
      write_project_file("config/shakapacker.yml", <<~YAML)
        development:
          dev_server:
            hmr: false
            live_reload: true
      YAML

      doctor.send(:check_bin_dev_launcher)

      success_messages = checker.messages.select { |msg| msg[:type] == :success }.map { |msg| msg[:content] }
      expect(success_messages).to include(
        a_string_including("Procfile.dev - Live reload development (bin/dev default)")
      )
      expect(success_messages).not_to include(a_string_including("Procfile.dev - HMR development"))
    end

    it "labels Procfile.dev diagnostics as live reload when Shakapacker disables HMR" do
      write_project_file("Procfile.dev", "web: bin/rails server\njs: bin/shakapacker-dev-server\n")
      write_project_file("config/shakapacker.yml", <<~YAML)
        development:
          dev_server:
            hmr: false
            live_reload: true
      YAML

      doctor.send(:check_procfiles)

      success_messages = checker.messages.select { |msg| msg[:type] == :success }.map { |msg| msg[:content] }
      expect(success_messages).to include(
        a_string_including("Procfile.dev exists (Live reload development with webpack-dev-server)")
      )
      expect(success_messages).not_to include(a_string_including("HMR development with webpack-dev-server"))
    end

    it "reuses the computed Procfile.dev description when reporting missing shakapacker-dev-server" do
      write_project_file("Procfile.dev", "web: bin/rails server\n")
      config = {
        description: "Live reload development with webpack-dev-server",
        required_for: "bin/dev (default mode)"
      }

      doctor.send(:check_individual_procfile, "Procfile.dev", config)

      warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
      expect(warning_messages).to include(
        a_string_including(
          "Live reload development with webpack-dev-server (Procfile.dev) requires shakapacker-dev-server"
        )
      )
    end

    it "memoizes the default dev server mode for a doctor run" do
      expect(ReactOnRails::Dev::ServerMode).to receive(:detect).once.and_return(:hmr)

      2.times { doctor.send(:default_dev_server_mode) }
    end
  end

  describe "#shakapacker_config_path" do
    let(:doctor) { described_class.new(verbose: false, fix: false) }
    let(:rails_root) { Pathname.new(Dir.mktmpdir("doctor-rails-root")) }

    around do |example|
      original_config_path = ENV.fetch("SHAKAPACKER_CONFIG", nil)
      original_cwd = Dir.pwd
      ENV.delete("SHAKAPACKER_CONFIG")
      example.run
    ensure
      ENV["SHAKAPACKER_CONFIG"] = original_config_path
      Dir.chdir(original_cwd)
      FileUtils.remove_entry(rails_root) if rails_root.exist?
    end

    before do
      allow(Rails).to receive(:root).and_return(rails_root)
    end

    it "defaults to config/shakapacker.yml under Rails.root" do
      expect(doctor.send(:shakapacker_config_path)).to eq(
        rails_root.join("config", "shakapacker.yml").to_s
      )
    end

    # Regression guard: doctor must resolve SHAKAPACKER_CONFIG the same way Engine/ServerManager do,
    # so a relative path does not silently fall back to HMR labels when doctor runs from another dir.
    it "resolves a relative SHAKAPACKER_CONFIG path against Rails.root" do
      ENV["SHAKAPACKER_CONFIG"] = "config/custom-shakapacker.yml"

      Dir.mktmpdir("doctor-cwd") do |unrelated_cwd|
        Dir.chdir(unrelated_cwd) do
          expect(doctor.send(:shakapacker_config_path)).to eq(
            rails_root.join("config", "custom-shakapacker.yml").to_s
          )
        end
      end
    end

    it "preserves an absolute SHAKAPACKER_CONFIG path" do
      config_path = "/tmp/custom-shakapacker.yml"
      ENV["SHAKAPACKER_CONFIG"] = config_path

      expect(doctor.send(:shakapacker_config_path)).to eq(config_path)
    end

    it "uses the current working directory for relative config when Rails is not booted" do
      allow(Rails).to receive(:root).and_return(nil)
      ENV["SHAKAPACKER_CONFIG"] = "config/custom-shakapacker.yml"

      Dir.mktmpdir("doctor-cwd") do |cwd|
        Dir.chdir(cwd) do
          expect(doctor.send(:shakapacker_config_path)).to eq(
            File.expand_path("config/custom-shakapacker.yml", Dir.pwd)
          )
        end
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
    let(:package_json_path) { "/tmp/myapp/package.json" }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(doctor).to receive(:resolved_package_json_path).and_return(package_json_path)
      allow(File).to receive(:exist?).with(package_json_path).and_return(true)
    end

    context "when both react-on-rails and react-on-rails-pro npm packages are installed" do
      before do
        allow(File).to receive(:read).with(package_json_path).and_return(
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
        allow(File).to receive(:read).with(package_json_path).and_return(
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
        allow(File).to receive(:read).with(package_json_path).and_return(
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
        allow(File).to receive(:read).with(package_json_path).and_return(
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
        allow(doctor).to receive(:resolved_package_json_path).and_return(package_json_path)
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

    context "when node_modules_location points to a missing JS workspace" do
      let(:rails_root) { Pathname.new("/tmp/myapp") }
      let(:package_root) { rails_root.join("client") }
      let(:workspace_package_json_path) { package_root.join("package.json").to_s }

      before do
        allow(Rails).to receive(:root).and_return(rails_root)
        allow(ReactOnRails).to receive(:configuration).and_return(
          instance_double(ReactOnRails::Configuration, node_modules_location: "client")
        )
        allow(doctor).to receive(:resolved_package_json_path).and_call_original
        allow(File).to receive(:exist?).with(workspace_package_json_path).and_return(false)
        allow(Dir).to receive(:exist?).with(package_root.to_s).and_return(false)
      end

      it "warns instead of silently skipping the Pro package check" do
        doctor.send(:check_pro_package_consistency)

        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("node_modules_location points to #{package_root}") })
          .to be true
        expect(warning_msgs.any? { |m| m[:content].include?("all diagnostics that read from it are skipped") })
          .to be true
      end

      it "warns once when checker and doctor see the same missing package root" do
        allow(checker).to receive(:cli_exists?).with("npm").and_return(true)
        allow(checker).to receive(:cli_exists?).with("pnpm").and_return(false)
        allow(checker).to receive(:cli_exists?).with("yarn").and_return(false)
        allow(checker).to receive(:cli_exists?).with("bun").and_return(false)

        checker.check_package_manager
        doctor.send(:check_pro_package_consistency)

        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        root_warnings = warning_msgs.select do |message|
          message[:content].include?("node_modules_location points to #{package_root}")
        end
        expect(root_warnings.length).to eq(1)
      end
    end

    context "when the configured JS workspace exists without package.json" do
      let(:rails_root) { Pathname.new("/tmp/myapp") }
      let(:package_root) { rails_root.join("client") }
      let(:workspace_package_json_path) { package_root.join("package.json").to_s }

      before do
        allow(Rails).to receive(:root).and_return(rails_root)
        allow(ReactOnRails).to receive(:configuration).and_return(
          instance_double(ReactOnRails::Configuration, node_modules_location: "client")
        )
        allow(doctor).to receive(:resolved_package_json_path).and_call_original
        allow(File).to receive(:exist?).with(workspace_package_json_path).and_return(false)
        allow(Dir).to receive(:exist?).with(package_root.to_s).and_return(true)
      end

      it "warns instead of silently skipping the Pro package check" do
        doctor.send(:check_pro_package_consistency)

        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("#{workspace_package_json_path} not found") })
          .to be true
        expect(warning_msgs.any? { |m| m[:content].include?("Pro package consistency") }).to be true
      end
    end
  end

  describe "#check_gem_wildcard_for" do
    let(:doctor) { described_class.new }
    let(:checker) { doctor.instance_variable_get(:@checker) }

    before do
      stub_const("ReactOnRails::VERSION", "16.5.0")
    end

    it "accepts multiline Gemfile declarations with comment-only continuation lines" do
      gemfile_content = <<~RUBY
        gem 'react_on_rails',
            # pinned for compatibility
            '16.5.0'
      RUBY

      doctor.send(:check_gem_wildcard_for, gemfile_content, "react_on_rails")

      expect(checker.messages.any? do |msg|
        msg[:type] == :success && msg[:content].include?("Gemfile uses exact version for react_on_rails")
      end).to be true
      expect(checker.messages.any? do |msg|
        msg[:type] == :error && msg[:content].include?("Gemfile specifies no version for react_on_rails")
      end).to be false
    end

    it "accepts keyword-style Gemfile version declarations" do
      gemfile_content = "gem 'react_on_rails', version: '16.5.0'\n"

      doctor.send(:check_gem_wildcard_for, gemfile_content, "react_on_rails")

      expect(checker.messages.any? do |msg|
        msg[:type] == :success && msg[:content].include?("Gemfile uses exact version for react_on_rails")
      end).to be true
    end
  end

  describe "#check_npm_alias_version" do
    let(:doctor) { described_class.new }
    let(:checker) { doctor.instance_variable_get(:@checker) }

    before do
      stub_const("ReactOnRails::VERSION", "16.5.0")
      allow(ReactOnRails::Utils).to receive_messages(
        react_on_rails_pro_version: "16.5.0",
        package_manager_install_exact_command: "pnpm add react-on-rails-pro@16.5.0"
      )
      allow(ReactOnRails::Utils).to receive(:package_manager_install_exact_command) do |package_name, version|
        "pnpm add #{package_name}@#{version}"
      end
    end

    it "reports an error for non-exact npm alias specs" do
      expect(checker).to receive(:add_error).with(
        include(
          "non-exact version in npm alias for react-on-rails-pro: npm:@scope/react-on-rails-pro@^16.5.0",
          "will cause a runtime error on app startup",
          "Fix: pnpm add react-on-rails-pro@16.5.0",
          "bundle exec rake react_on_rails:sync_versions WRITE=true"
        )
      )

      doctor.send(:check_npm_alias_version, "npm:@scope/react-on-rails-pro@^16.5.0", "react-on-rails-pro")
    end

    it "reports success for exact npm alias specs" do
      expect(checker).to receive(:add_success).with("✅ package.json uses exact version for react-on-rails")

      doctor.send(:check_npm_alias_version, "npm:@scope/react-on-rails@16.5.0", "react-on-rails")
    end

    it "reports an error for exact npm alias versions that do not match expected version" do
      expect(checker).to receive(:add_error).with(
        include(
          "npm alias version mismatch for react-on-rails: npm:@scope/react-on-rails@16.4.0",
          "Expected exact version: 16.5.0",
          "Fix: pnpm add react-on-rails@16.5.0"
        )
      )

      doctor.send(:check_npm_alias_version, "npm:@scope/react-on-rails@16.4.0", "react-on-rails")
    end

    it "reports an error for npm aliases without a parseable trailing version" do
      expect(checker).to receive(:add_error).with(
        include(
          "npm alias without a parseable version for react-on-rails: npm:@scope/react-on-rails",
          "Fix: pnpm add react-on-rails@16.5.0"
        )
      )

      doctor.send(:check_npm_alias_version, "npm:@scope/react-on-rails", "react-on-rails")
    end
  end

  describe "#auto_fix_versions" do
    let(:doctor) { described_class.new(verbose: false, fix: true) }
    let(:checker) { doctor.instance_variable_get(:@checker) }

    def stub_synchronizer(result)
      synchronizer = instance_double(ReactOnRails::VersionSynchronizer, sync: result)

      allow(doctor).to receive(:package_json_path_for)
        .with("package version auto-sync")
        .and_return("package.json")
      allow(ReactOnRails::VersionSynchronizer).to receive(:new).and_return(synchronizer)
    end

    it "adds explicit guidance that Gemfile constraints are not auto-fixed when changes are applied" do
      result = ReactOnRails::VersionSynchronizer::Result.new(
        changes: [{ section: "dependencies", package: "react-on-rails", from: "^16.4.0", to: "16.5.0" }],
        changed_files: ["package.json"],
        unsupported_specs: [],
        missing_source_specs: []
      )
      stub_synchronizer(result)

      doctor.send(:auto_fix_versions)

      info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
      expect(info_messages).to include(
        a_string_including("FIX=true only updates package.json; update Gemfile constraints manually if needed.")
      )
    end

    # Regression: previously emitted unconditionally, producing misleading noise
    # alongside `report_sync_changes`'s "No package.json version changes needed".
    it "skips the Gemfile-constraints info message when there are no changes" do
      result = ReactOnRails::VersionSynchronizer::Result.new(
        changes: [],
        changed_files: [],
        unsupported_specs: [],
        missing_source_specs: []
      )
      stub_synchronizer(result)

      doctor.send(:auto_fix_versions)

      info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
      expect(info_messages).not_to include(
        a_string_including("FIX=true only updates package.json; update Gemfile constraints manually if needed.")
      )
    end
  end

  describe "private path resolution helpers" do
    describe "#resolved_package_root" do
      let(:rails_root) { Pathname.new("/tmp/myapp") }

      before do
        allow(Rails).to receive(:root).and_return(rails_root)
      end

      def stub_node_modules_location(path)
        allow(ReactOnRails).to receive(:configuration).and_return(
          instance_double(ReactOnRails::Configuration, node_modules_location: path)
        )
      end

      it "resolves root package paths to Rails.root" do
        [nil, "", ".", rails_root.to_s, "#{rails_root}/"].each do |node_modules_location|
          doctor = described_class.new(verbose: false, fix: false)
          stub_node_modules_location(node_modules_location)

          expect(doctor.send(:resolved_package_root)).to eq(rails_root.to_s)
          expect(doctor.send(:resolved_package_json_path)).to eq(rails_root.join("package.json").to_s)
          expect(doctor.send(:resolved_package_path, "package.json")).to eq(rails_root.join("package.json").to_s)
        end
      end

      it "resolves nested package paths under Rails.root" do
        stub_node_modules_location("client")

        expect(doctor.send(:resolved_package_root)).to eq(rails_root.join("client").to_s)
        expect(doctor.send(:resolved_package_json_path)).to eq(rails_root.join("client", "package.json").to_s)
        expect(doctor.send(:resolved_package_path, "yarn.lock")).to eq(rails_root.join("client", "yarn.lock").to_s)
      end

      it "passes through absolute package paths" do
        stub_node_modules_location("/opt/app/client/")

        expect(doctor.send(:resolved_package_root)).to eq("/opt/app/client")
        expect(doctor.send(:resolved_package_json_path)).to eq("/opt/app/client/package.json")
        expect(doctor.send(:resolved_package_path, "yarn.lock")).to eq("/opt/app/client/yarn.lock")
      end
    end

    describe "#resolved_webpack_config_path" do
      it "prioritizes shakapacker's exact assets_bundler_config_path" do
        allow(File).to receive(:file?).and_return(false)
        allow(File).to receive(:file?).with("config/custom/custom-bundler.config.js").and_return(true)
        allow(File).to receive(:file?).with("config/custom/webpack.config.js").and_return(true)
        allow(doctor).to receive(:shakapacker_assets_bundler_config_path)
          .and_return("config/custom/custom-bundler.config.js")
        allow(doctor).to receive(:bundler_config_directory)
          .with("config/custom/custom-bundler.config.js")
          .and_return("config/custom")

        expect(doctor.send(:resolved_webpack_config_path)).to eq("config/custom/custom-bundler.config.js")
      end

      it "falls back to shakapacker-derived webpack config candidates when exact shakapacker path is not a file" do
        allow(File).to receive(:file?).and_return(false)
        allow(File).to receive(:file?).with("config/custom/webpack.config.ts").and_return(true)
        allow(doctor).to receive(:bundler_config_directory)
          .with("config/custom/custom-bundler.config.js")
          .and_return("config/custom")
        allow(doctor).to receive(:shakapacker_assets_bundler_config_path)
          .and_return("config/custom/custom-bundler.config.js")

        expect(doctor.send(:resolved_webpack_config_path)).to eq("config/custom/webpack.config.ts")
      end

      it "keeps sibling bundler candidates when shakapacker path uses a standard filename" do
        allow(File).to receive(:file?).and_return(false)
        allow(File).to receive(:file?).with("config/webpack/rspack.config.js").and_return(true)
        allow(doctor).to receive(:bundler_config_directory)
          .with("config/webpack/webpack.config.js")
          .and_return("config/webpack")
        allow(doctor).to receive(:shakapacker_assets_bundler_config_path)
          .and_return("config/webpack/webpack.config.js")

        expect(doctor.send(:resolved_webpack_config_path)).to eq("config/webpack/rspack.config.js")
      end

      it "resolves rspack config candidates from the shakapacker-derived directory" do
        allow(File).to receive(:file?).and_return(false)
        allow(File).to receive(:file?).with("config/rspack/rspack.config.ts").and_return(true)
        allow(doctor).to receive(:bundler_config_directory)
          .with("config/rspack/custom-bundler.config.js")
          .and_return("config/rspack")
        allow(doctor).to receive(:shakapacker_assets_bundler_config_path)
          .and_return("config/rspack/custom-bundler.config.js")

        expect(doctor.send(:resolved_webpack_config_path)).to eq("config/rspack/rspack.config.ts")
      end

      it "falls back to default rspack config paths when shakapacker directory is unavailable" do
        allow(File).to receive(:file?).and_return(false)
        allow(File).to receive(:file?).with("config/rspack/rspack.config.js").and_return(true)
        allow(doctor).to receive(:bundler_config_directory).with(nil).and_return(nil)
        allow(doctor).to receive(:shakapacker_assets_bundler_config_path).and_return(nil)

        expect(doctor.send(:resolved_webpack_config_path)).to eq("config/rspack/rspack.config.js")
      end
    end

    describe "#shakapacker_assets_bundler_config_path" do
      it "normalizes shakapacker assets_bundler_config_path to a rails-relative path" do
        rails_root = Pathname.new("/tmp/myapp")
        allow(Rails).to receive(:root).and_return(rails_root)
        allow(doctor).to receive(:require).with("shakapacker").and_return(true)
        shakapacker_config = Struct.new(:assets_bundler_config_path).new(
          "#{rails_root}/config/custom/custom-bundler.config.ts"
        )
        shakapacker_class = Class.new do
          class << self
            attr_accessor :config
          end
        end
        stub_const("Shakapacker", shakapacker_class)
        Shakapacker.config = shakapacker_config

        expect(doctor.send(:shakapacker_assets_bundler_config_path)).to eq("config/custom/custom-bundler.config.ts")
      end

      it "keeps absolute assets_bundler_config_path outside Rails.root unchanged" do
        rails_root = Pathname.new("/tmp/myapp")
        allow(Rails).to receive(:root).and_return(rails_root)
        allow(doctor).to receive(:require).with("shakapacker").and_return(true)
        shakapacker_config = Struct.new(:assets_bundler_config_path).new("/opt/custom/bundler.config.js")
        shakapacker_class = Class.new do
          class << self
            attr_accessor :config
          end
        end
        stub_const("Shakapacker", shakapacker_class)
        Shakapacker.config = shakapacker_config

        expect(doctor.send(:shakapacker_assets_bundler_config_path)).to eq("/opt/custom/bundler.config.js")
      end

      it "does not strip absolute paths when Rails.root is filesystem root" do
        allow(Rails).to receive(:root).and_return(Pathname.new("/"))
        allow(doctor).to receive(:require).with("shakapacker").and_return(true)
        shakapacker_config = Struct.new(:assets_bundler_config_path).new("/opt/custom/bundler.config.js")
        shakapacker_class = Class.new do
          class << self
            attr_accessor :config
          end
        end
        stub_const("Shakapacker", shakapacker_class)
        Shakapacker.config = shakapacker_config

        expect(doctor.send(:shakapacker_assets_bundler_config_path)).to eq("/opt/custom/bundler.config.js")
      end

      it "returns nil when normalization strips to an empty relative path" do
        rails_root = Pathname.new("/tmp/myapp")
        allow(Rails).to receive(:root).and_return(rails_root)
        allow(doctor).to receive(:require).with("shakapacker").and_return(true)
        shakapacker_config = Struct.new(:assets_bundler_config_path).new("#{rails_root}/")
        shakapacker_class = Class.new do
          class << self
            attr_accessor :config
          end
        end
        stub_const("Shakapacker", shakapacker_class)
        Shakapacker.config = shakapacker_config

        expect(doctor.send(:shakapacker_assets_bundler_config_path)).to be_nil
      end
    end

    describe "#bundler_config_directory" do
      it "extracts a directory from shakapacker's config file path" do
        expect(doctor.send(:bundler_config_directory, "config/custom/webpack.config.ts"))
          .to eq("config/custom")
      end

      it "returns nil for bare filenames without a directory component" do
        expect(doctor.send(:bundler_config_directory, "webpack.config.js")).to be_nil
      end
    end
  end

  # ── Pro Setup Checks ──────────────────────────────────────────────
  # ReactOnRailsPro class may not be loaded in the test environment (Pro is optional),
  # so we must use unverified doubles for stub_const.
  # rubocop:disable RSpec/VerifiedDoubles

  describe "Pro setup checks" do
    let(:doctor) { described_class.new(verbose: false, fix: false) }
    let(:checker) { doctor.instance_variable_get(:@checker) }

    before do
      allow(doctor).to receive(:puts)
      allow(doctor).to receive(:exit)
    end

    context "when Pro gem is not installed" do
      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
      end

      it "does not add any Pro setup messages" do
        initial_count = checker.messages.length
        doctor.send(:check_pro_setup)
        expect(checker.messages.length).to eq(initial_count)
      end
    end

    context "when Pro gem is installed with NodeRenderer" do
      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
        pro_config = double("ProConfig", server_renderer: "NodeRenderer", rolling_deploy_adapter: nil)
        stub_const("ReactOnRailsPro", double("ReactOnRailsPro", configuration: pro_config))
      end

      it "reports success for NodeRenderer" do
        doctor.send(:check_pro_setup)
        success_messages = checker.messages.select { |m| m[:type] == :success }
        expect(success_messages.any? { |m| m[:content].include?("NodeRenderer") }).to be true
      end
    end

    context "when Pro gem is installed with ExecJS" do
      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
        pro_config = double("ProConfig", server_renderer: "ExecJS", rolling_deploy_adapter: nil)
        stub_const("ReactOnRailsPro", double("ReactOnRailsPro", configuration: pro_config))
      end

      it "reports ExecJS mode as info" do
        doctor.send(:check_pro_setup)
        info_messages = checker.messages.select { |m| m[:type] == :info }
        expect(info_messages.any? { |m| m[:content].include?("ExecJS") }).to be true
      end
    end

    context "when Pro configuration raises an error" do
      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
        stub_const("ReactOnRailsPro", double("ReactOnRailsPro"))
        allow(ReactOnRailsPro).to receive(:configuration).and_raise(StandardError, "config load failed")
      end

      it "catches the error and adds a warning" do
        doctor.send(:check_pro_setup)
        warning_messages = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_messages.any? { |m| m[:content].include?("config load failed") }).to be true
      end
    end
  end

  describe "ensure_rails_environment_loaded" do
    let(:doctor) { described_class.new(verbose: false, fix: false) }
    let(:checker) { doctor.instance_variable_get(:@checker) }

    context "when config/environment.rb exists and loads successfully" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("config")
            File.write("config/environment.rb", "# noop")
            example.run
          end
        end
      end

      it "returns true" do
        expect(doctor.send(:ensure_rails_environment_loaded)).to be true
      end

      it "only loads once" do
        doctor.send(:ensure_rails_environment_loaded)
        # Second call should return true without re-requiring
        expect(doctor.send(:ensure_rails_environment_loaded)).to be true
      end
    end

    context "when config/environment.rb does not exist" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) { example.run }
        end
      end

      it "returns false" do
        expect(doctor.send(:ensure_rails_environment_loaded)).to be false
      end
    end

    context "when loading raises an error" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("config")
            File.write("config/environment.rb", "raise 'boot failed'")
            example.run
          end
        end
      end

      it "returns false and adds a warning" do
        expect(doctor.send(:ensure_rails_environment_loaded)).to be false
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("Could not load Rails environment") }).to be true
      end
    end
  end

  describe "react_on_rails_runtime_configuration" do
    let(:doctor) { described_class.new(verbose: false, fix: false) }
    let(:checker) { doctor.instance_variable_get(:@checker) }

    it "memoizes nil when rails environment cannot be loaded" do
      expect(doctor).to receive(:ensure_rails_environment_loaded).once.and_return(false)

      expect(doctor.send(:react_on_rails_runtime_configuration)).to be_nil
      expect(doctor.send(:react_on_rails_runtime_configuration)).to be_nil
    end

    it "rescues and memoizes nil when ReactOnRails.configuration raises" do
      allow(doctor).to receive(:ensure_rails_environment_loaded).and_return(true)
      allow(ReactOnRails).to receive(:configuration).and_raise(StandardError, "bad config")

      expect(doctor.send(:react_on_rails_runtime_configuration)).to be_nil
      expect(doctor.send(:react_on_rails_runtime_configuration)).to be_nil

      warning_messages = checker.messages.select { |m| m[:type] == :warning }.map { |m| m[:content] }
      warning_count =
        warning_messages.count { |msg| msg.include?("Could not query React on Rails runtime configuration") }
      expect(warning_count).to eq(1)
    end
  end

  describe "resolved_pro_server_renderer" do
    let(:doctor) { described_class.new(verbose: false, fix: false) }
    let(:checker) { doctor.instance_variable_get(:@checker) }

    it "memoizes nil when Pro is not active" do
      expect(ReactOnRails::Utils).to receive(:react_on_rails_pro?).once.and_return(false)

      expect(doctor.send(:resolved_pro_server_renderer)).to be_nil
      expect(doctor.send(:resolved_pro_server_renderer)).to be_nil
    end

    it "warns once when Pro is active but runtime and initializer renderer sources are unavailable" do
      allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
      allow(doctor).to receive_messages(
        ensure_rails_environment_loaded: true,
        pro_initializer_has_node_renderer?: false
      )
      hide_const("ReactOnRailsPro") if defined?(ReactOnRailsPro)

      expect(doctor.send(:resolved_pro_server_renderer)).to be_nil
      expect(doctor.send(:resolved_pro_server_renderer)).to be_nil

      warning_messages = checker.messages.select { |m| m[:type] == :warning }.map { |m| m[:content] }
      expect(warning_messages.count { |msg| msg.include?("Could not determine Pro server renderer") }).to eq(1)
    end

    it "adds an info message when Rails env is unavailable and initializer fallback is absent" do
      allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
      allow(doctor).to receive_messages(
        ensure_rails_environment_loaded: false,
        pro_initializer_has_node_renderer?: false
      )

      expect(doctor.send(:resolved_pro_server_renderer)).to be_nil

      info_messages = checker.messages.select { |m| m[:type] == :info }.map { |m| m[:content] }
      expect(info_messages.any? { |msg| msg.include?("Rails environment unavailable and no initializer match found") })
        .to be true
    end

    it "rescues LoadError when Pro runtime renderer cannot be queried" do
      allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_raise(LoadError, "missing pro gem")

      expect(doctor.send(:resolved_pro_server_renderer)).to be_nil

      warning_messages = checker.messages.select { |m| m[:type] == :warning }.map { |m| m[:content] }
      expect(warning_messages.any? { |msg| msg.include?("Could not read Pro runtime renderer configuration") })
        .to be true
    end
  end

  describe "check_pro_initializer_existence" do
    let(:doctor) { described_class.new(verbose: false, fix: false) }
    let(:checker) { doctor.instance_variable_get(:@checker) }

    context "when Pro initializer exists" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("config/initializers")
            File.write("config/initializers/react_on_rails_pro.rb", "ReactOnRailsPro.configure {}")
            example.run
          end
        end
      end

      it "reports success" do
        doctor.send(:check_pro_initializer_existence)
        success_msgs = checker.messages.select { |m| m[:type] == :success }
        expect(success_msgs.any? { |m| m[:content].include?("Pro initializer exists") }).to be true
      end
    end

    context "when Pro initializer is missing" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) { example.run }
        end
      end

      it "reports warning" do
        doctor.send(:check_pro_initializer_existence)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("Pro initializer not found") }).to be true
      end
    end
  end

  describe "check_rolling_deploy_adapter" do
    let(:doctor) { described_class.new(verbose: false, fix: false) }
    let(:checker) { doctor.instance_variable_get(:@checker) }
    let(:config) { double("ProConfig", rolling_deploy_adapter: adapter) } # rubocop:disable RSpec/VerifiedDoubles

    before do
      # Capture let values into locals so closures inside define_singleton_method
      # can see them — define_singleton_method evaluates blocks in the module's
      # own scope where `config` is not a known identifier.
      config_value = config
      pro_module = Module.new
      pro_module.define_singleton_method(:configuration) { config_value }
      utils_module = Module.new
      utils_module.define_singleton_method(:resolve_renderer_cache_dir) { "/tmp/nonexistent-cache-dir" }
      pro_module.const_set(:Utils, utils_module)
      stub_const("ReactOnRailsPro", pro_module)
      ENV.delete("PREVIOUS_BUNDLE_HASHES")
    end

    after { ENV.delete("PREVIOUS_BUNDLE_HASHES") }

    context "when rolling_deploy_adapter is nil and env override is unset" do
      let(:adapter) { nil }

      it "adds an info line" do
        doctor.send(:check_rolling_deploy_adapter)
        info = checker.messages.select { |m| m[:type] == :info }
        expect(info.any? { |m| m[:content].include?("No rolling_deploy_adapter configured") }).to be(true)
      end
    end

    context "when env override is set but adapter is nil" do
      let(:adapter) { nil }

      before { ENV["PREVIOUS_BUNDLE_HASHES"] = "abc,def" }

      it "warns that both are required" do
        doctor.send(:check_rolling_deploy_adapter)
        warnings = checker.messages.select { |m| m[:type] == :warning }
        expect(warnings.any? do |m|
                 m[:content].include?("PREVIOUS_BUNDLE_HASHES") && m[:content].include?("abc,def")
               end).to be(true)
      end
    end

    # Regression: an accidentally-large PREVIOUS_BUNDLE_HASHES value (e.g. a
    # full bundle dumped into the env by mistake) should not flood operator
    # output. Echo a capped prefix and the total length instead.
    context "when env override is large enough to flood operator output" do
      let(:adapter) { nil }
      let(:long_value) { "a" * 500 }

      before { ENV["PREVIOUS_BUNDLE_HASHES"] = long_value }

      it "truncates the echoed env value and reports the total length" do
        doctor.send(:check_rolling_deploy_adapter)
        warning = checker.messages.find { |m| m[:type] == :warning && m[:content].include?("PREVIOUS_BUNDLE_HASHES") }
        expect(warning).not_to be_nil
        expect(warning[:content]).to include("… (500 chars total)")
        expect(warning[:content]).not_to include("a" * 200)
      end
    end

    context "when adapter implements all required methods and returns hashes" do
      let(:adapter) do
        Module.new do
          def self.previous_bundle_hashes = %w[abc def]
          def self.fetch(_hash); end
          def self.upload(_hash, **_opts); end
        end
      end

      it "reports protocol success and probe success" do
        doctor.send(:check_rolling_deploy_adapter)
        successes = checker.messages.select { |m| m[:type] == :success }
        expect(successes.any? { |m| m[:content].include?("responds to all required methods") }).to be(true)
        expect(successes.any? { |m| m[:content].include?("2 hash(es)") }).to be(true)
      end
    end

    context "when adapter is configured and PREVIOUS_BUNDLE_HASHES is also set" do
      let(:adapter) do
        Module.new do
          def self.previous_bundle_hashes
            raise "should not be probed when env var overrides discovery"
          end

          def self.fetch(_hash); end
          def self.upload(_hash, **_opts); end
        end
      end

      before { ENV["PREVIOUS_BUNDLE_HASHES"] = "abc,def" }

      it "skips the previous_bundle_hashes probe and reports the env-var override" do
        doctor.send(:check_rolling_deploy_adapter)
        info = checker.messages.select { |m| m[:type] == :info }
        warnings = checker.messages.select { |m| m[:type] == :warning }
        expect(info.any? do |m|
                 m[:content].include?("PREVIOUS_BUNDLE_HASHES") && m[:content].include?("skipping")
               end).to be(true)
        expect(warnings.none? { |m| m[:content].include?("should not be probed") }).to be(true)
      end
    end

    context "when renderer cache contains rolling-deploy temporary directories" do
      let(:cache_dir) { Dir.mktmpdir }
      let(:adapter) do
        Module.new do
          def self.previous_bundle_hashes = %w[abc]
          def self.fetch(_hash); end
          def self.upload(_hash, **_opts); end
        end
      end

      before do
        FileUtils.mkdir_p(File.join(cache_dir, "abc"))
        FileUtils.mkdir_p(File.join(cache_dir, "abc.staging-1234-deadbeef12"))
        FileUtils.mkdir_p(File.join(cache_dir, "abc.previous-1234-feedface12"))
        cache_dir_value = cache_dir
        ReactOnRailsPro::Utils.define_singleton_method(:resolve_renderer_cache_dir) { cache_dir_value }
      end

      after { FileUtils.rm_rf(cache_dir) }

      it "excludes temporary directories from the bundle-hash count" do
        doctor.send(:check_rolling_deploy_adapter)
        info = checker.messages.select { |m| m[:type] == :info }
        expect(info.map { |m| m[:content] }).to include(a_string_matching(/\(1 bundle-hash subdir\(s\)\)/))
      end
    end

    context "when adapter is missing required methods" do
      let(:adapter) do
        Module.new do
          def self.previous_bundle_hashes = []
        end
      end

      it "warns with the missing methods listed" do
        doctor.send(:check_rolling_deploy_adapter)
        warnings = checker.messages.select { |m| m[:type] == :warning }
        expect(warnings.any? do |m|
                 m[:content].include?("missing required methods") && m[:content].include?("fetch")
               end).to be(true)
        expect(warnings.none? { |m| m[:content].include?("previous_bundle_hashes returned []") }).to be(true)
      end
    end

    context "when previous_bundle_hashes returns []" do
      let(:adapter) do
        Module.new do
          def self.previous_bundle_hashes = []
          def self.fetch(_hash); end
          def self.upload(_hash, **_opts); end
        end
      end

      it "warns that the upload side likely has not run" do
        doctor.send(:check_rolling_deploy_adapter)
        warnings = checker.messages.select { |m| m[:type] == :warning }
        expect(warnings.any? { |m| m[:content].include?("returned []") }).to be(true)
      end
    end

    context "when previous_bundle_hashes times out" do
      let(:adapter) do
        Module.new do
          def self.previous_bundle_hashes
            sleep 1
          end

          def self.fetch(_hash); end
          def self.upload(_hash, **_opts); end
        end
      end

      before do
        stager_module = Module.new
        stager_module.const_set(:DISCOVERY_TIMEOUT_SECONDS, 0.01)
        ReactOnRailsPro.const_set(:RollingDeployCacheStager, stager_module)
      end

      it "uses the stager timeout constant when it is loaded" do
        doctor.send(:check_rolling_deploy_adapter)
        warnings = checker.messages.select { |m| m[:type] == :warning }
        expect(warnings.any? { |m| m[:content].include?("timed out after 0.01s") }).to be(true)
      end
    end
  end

  describe "report_resolved_cache_dir" do
    let(:doctor) { described_class.new(verbose: false, fix: false) }
    let(:checker) { doctor.instance_variable_get(:@checker) }
    let(:cache_dir) { Dir.mktmpdir("doctor-cache") }

    before do
      cache_dir_value = cache_dir
      pro_module = Module.new
      utils_module = Module.new
      utils_module.define_singleton_method(:resolve_renderer_cache_dir) { cache_dir_value }
      pro_module.const_set(:Utils, utils_module)
      stub_const("ReactOnRailsPro", pro_module)
    end

    after { FileUtils.rm_rf(cache_dir) }

    it "excludes leftover staging/backup temp dirs from the bundle-hash count" do
      FileUtils.mkdir_p(File.join(cache_dir, "abc123"))
      FileUtils.mkdir_p(File.join(cache_dir, "def456"))
      FileUtils.mkdir_p(File.join(cache_dir, "abc123.staging-1234-deadbeef"))
      FileUtils.mkdir_p(File.join(cache_dir, "abc123.previous-1234-feedface"))

      doctor.send(:report_resolved_cache_dir)

      info = checker.messages.find { |m| m[:type] == :info && m[:content].include?(cache_dir) }
      expect(info[:content]).to include("(2 bundle-hash subdir(s))")
    end

    it "uses the Pro stager constant when the Pro gem is loaded" do
      stager_module = Module.new
      stager_module.const_set(:TEMPORARY_DIRECTORY_PATTERN, /\.tempmarker\z/)
      ReactOnRailsPro.const_set(:RollingDeployCacheStager, stager_module)
      FileUtils.mkdir_p(File.join(cache_dir, "abc123"))
      FileUtils.mkdir_p(File.join(cache_dir, "abc123.tempmarker"))

      doctor.send(:report_resolved_cache_dir)

      info = checker.messages.find { |m| m[:type] == :info && m[:content].include?(cache_dir) }
      expect(info[:content]).to include("(1 bundle-hash subdir(s))")
    end
  end

  describe "check_deprecated_renderer_cache_task" do
    let(:doctor) { described_class.new(verbose: false, fix: false) }
    let(:checker) { doctor.instance_variable_get(:@checker) }

    context "when a Procfile references the deprecated task" do
      let(:tmpdir) { Dir.mktmpdir }

      before do
        File.write(
          File.join(tmpdir, "Procfile"),
          "web: bundle exec rake react_on_rails_pro:pre_stage_bundle_for_node_renderer && bundle exec puma\n"
        )
        allow(Rails).to receive(:root).and_return(Pathname.new(tmpdir))
      end

      after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

      it "warns with migration guidance" do
        doctor.send(:check_deprecated_renderer_cache_task)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("pre_stage_bundle_for_node_renderer") }).to be(true)
        expect(warning_msgs.any? { |m| m[:content].include?("MODE=symlink") }).to be(true)
      end
    end

    context "when a Dockerfile variant references the deprecated task" do
      let(:tmpdir) { Dir.mktmpdir }

      before do
        File.write(
          File.join(tmpdir, "Dockerfile.production"),
          "RUN bundle exec rake react_on_rails_pro:pre_stage_bundle_for_node_renderer\n"
        )
        allow(Rails).to receive(:root).and_return(Pathname.new(tmpdir))
      end

      after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

      it "suggests the copy-mode task without MODE=symlink" do
        doctor.send(:check_deprecated_renderer_cache_task)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs).not_to be_empty
        warning_content = warning_msgs.map { |m| m[:content] }.join("\n")
        # Match from the bullet header through any indented continuation lines.
        bullet_section = warning_content[/  • Dockerfile\.production →(?:\n {6,}.*)*/]
        expect(bullet_section).not_to be_nil
        expect(bullet_section).to include("ENV RENDERER_SERVER_BUNDLE_CACHE_PATH=/app/.node-renderer-bundles")
        expect(bullet_section).to include("RUN bundle exec rake react_on_rails_pro:pre_seed_renderer_cache")
        expect(bullet_section).not_to include(tmpdir)
        expect(bullet_section).not_to include("MODE=symlink")
      end
    end

    context "when a compose file references the deprecated task" do
      let(:tmpdir) { Dir.mktmpdir }

      before do
        File.write(
          File.join(tmpdir, "docker-compose.yml"),
          "services:\n  web:\n    command: bundle exec rake react_on_rails_pro:pre_stage_bundle_for_node_renderer\n"
        )
        allow(Rails).to receive(:root).and_return(Pathname.new(tmpdir))
      end

      after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

      it "warns with migration guidance and a copy-mode hint for image builds" do
        doctor.send(:check_deprecated_renderer_cache_task)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        suggestion_line = warning_msgs
                          .flat_map { |m| m[:content].split("\n") }
                          .find { |line| line.include?("docker-compose.yml →") }
        expect(suggestion_line).not_to be_nil
        expect(suggestion_line).to include("pre_seed_renderer_cache")
        expect(suggestion_line).to include("MODE=symlink")
        expect(suggestion_line).to include("MODE=copy")
      end
    end

    context "when a Compose V2 compose.yaml references the deprecated task" do
      let(:tmpdir) { Dir.mktmpdir }

      before do
        File.write(
          File.join(tmpdir, "compose.yaml"),
          "services:\n  web:\n    command: bundle exec rake react_on_rails_pro:pre_stage_bundle_for_node_renderer\n"
        )
        allow(Rails).to receive(:root).and_return(Pathname.new(tmpdir))
      end

      after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

      it "detects .yaml variants of Compose files" do
        doctor.send(:check_deprecated_renderer_cache_task)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        suggestion_line = warning_msgs
                          .flat_map { |m| m[:content].split("\n") }
                          .find { |line| line.include?("compose.yaml →") }
        expect(suggestion_line).not_to be_nil
        expect(suggestion_line).to include("pre_seed_renderer_cache")
      end
    end

    context "when a Kamal deploy config references the deprecated task" do
      let(:tmpdir) { Dir.mktmpdir }

      before do
        FileUtils.mkdir_p(File.join(tmpdir, ".kamal"))
        File.write(
          File.join(tmpdir, ".kamal", "deploy.yml"),
          "hooks:\n  post-deploy: bundle exec rake react_on_rails_pro:pre_stage_bundle_for_node_renderer\n"
        )
        allow(Rails).to receive(:root).and_return(Pathname.new(tmpdir))
      end

      after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

      it "shows MODE=symlink and MODE=copy on separate lines for deploy vs image-build hooks" do
        doctor.send(:check_deprecated_renderer_cache_task)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs).not_to be_empty
        warning_content = warning_msgs.map { |m| m[:content] }.join("\n")
        # Match from the bullet header through any indented continuation lines.
        bullet_section = warning_content[%r{  • \.kamal/deploy\.yml →(?:\n {6,}.*)*}]
        expect(bullet_section).not_to be_nil
        expect(bullet_section).to include("rake react_on_rails_pro:pre_seed_renderer_cache MODE=symlink")
        expect(bullet_section).to include("Kamal deploy hooks")
        expect(bullet_section).to include("Kamal image-build hooks")
        expect(bullet_section).to include("MODE=copy")
        # The previous trailing-comment form ("# use copy mode for image builds") was contradictory
        # for users editing build hooks, so it must not reappear on the same line as the command.
        expect(bullet_section).not_to match(/MODE=symlink # use copy mode for image builds/)
      end
    end

    context "when a Capistrano staging deploy config references the deprecated task" do
      let(:tmpdir) { Dir.mktmpdir }

      before do
        FileUtils.mkdir_p(File.join(tmpdir, "config/deploy"))
        File.write(
          File.join(tmpdir, "config/deploy/staging.rb"),
          "before 'deploy:assets:precompile', 'react_on_rails_pro:pre_stage_bundle_for_node_renderer'\n"
        )
        allow(Rails).to receive(:root).and_return(Pathname.new(tmpdir))
      end

      after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

      it "flags multi-stage Capistrano deploy files for migration" do
        doctor.send(:check_deprecated_renderer_cache_task)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        suggestion_line = warning_msgs
                          .flat_map { |m| m[:content].split("\n") }
                          .find { |line| line.include?("config/deploy/staging.rb →") }
        expect(suggestion_line).not_to be_nil
        expect(suggestion_line).to include("pre_seed_renderer_cache")
        expect(suggestion_line).to include("MODE=symlink")
      end
    end

    context "when no deploy scripts reference the deprecated task" do
      let(:tmpdir) { Dir.mktmpdir }

      before { allow(Rails).to receive(:root).and_return(Pathname.new(tmpdir)) }
      after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

      it "adds no warnings" do
        doctor.send(:check_deprecated_renderer_cache_task)
        expect(checker.messages.select { |m| m[:type] == :warning }).to be_empty
      end
    end

    context "when a configured deploy-script path is a directory" do
      let(:tmpdir) { Dir.mktmpdir }

      before do
        FileUtils.mkdir_p(File.join(tmpdir, "bin/deploy"))
        File.write(
          File.join(tmpdir, "Procfile"),
          "web: bundle exec rake react_on_rails_pro:pre_stage_bundle_for_node_renderer\n"
        )
        allow(Rails).to receive(:root).and_return(Pathname.new(tmpdir))
      end

      after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

      it "skips the directory and continues scanning real files" do
        doctor.send(:check_deprecated_renderer_cache_task)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }

        expect(warning_msgs.any? { |m| m[:content].include?("Procfile") }).to be(true)
        expect(warning_msgs.none? do |m|
                 m[:content].include?("Could not scan bin/deploy for deprecated renderer-cache task")
               end).to be(true)
      end
    end

    context "when a deploy-script file exceeds the size gate" do
      let(:tmpdir) { Dir.mktmpdir }

      before do
        # Stub the cap so we do not have to write a real 1 MB file — the gate
        # logic is what we are exercising, not the specific threshold.
        stub_const("ReactOnRails::Doctor::RENDERER_CACHE_DEPLOY_SCRIPT_MAX_BYTES", 64)
        padding = "x" * 128
        File.write(
          File.join(tmpdir, "Procfile"),
          "web: bundle exec rake react_on_rails_pro:pre_stage_bundle_for_node_renderer\n#{padding}"
        )
        allow(Rails).to receive(:root).and_return(Pathname.new(tmpdir))
      end

      after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

      it "silently skips the file and emits no warning" do
        doctor.send(:check_deprecated_renderer_cache_task)
        expect(checker.messages.select { |m| m[:type] == :warning }).to be_empty
      end
    end

    context "when a deploy-script file is exactly the size gate" do
      let(:tmpdir) { Dir.mktmpdir }
      let(:script_content) do
        "web: bundle exec rake react_on_rails_pro:pre_stage_bundle_for_node_renderer\n"
      end

      before do
        stub_const("ReactOnRails::Doctor::RENDERER_CACHE_DEPLOY_SCRIPT_MAX_BYTES", script_content.bytesize)
        File.write(File.join(tmpdir, "Procfile"), script_content)
        allow(Rails).to receive(:root).and_return(Pathname.new(tmpdir))
      end

      after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

      it "still scans the file" do
        doctor.send(:check_deprecated_renderer_cache_task)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("pre_stage_bundle_for_node_renderer") }).to be(true)
      end
    end

    context "when reading a deploy-script file raises an unexpected error" do
      let(:tmpdir) { Dir.mktmpdir }
      let(:procfile_path) { File.join(tmpdir, "Procfile") }

      before do
        File.write(
          procfile_path,
          "web: bundle exec rake react_on_rails_pro:pre_stage_bundle_for_node_renderer\n"
        )
        root_path = Pathname.new(tmpdir)
        allow(Rails).to receive(:root).and_return(root_path)

        # Simulate a filesystem error (e.g. transient EIO or a permissions race)
        # on the actual Pathname receiver used by the doctor scan.
        failing_procfile = instance_double(Pathname)
        allow(failing_procfile).to receive_messages(file?: true, size: File.size(procfile_path))
        allow(failing_procfile).to receive(:binread).and_raise(Errno::EIO, "simulated read failure")
        allow(root_path).to receive(:join).and_call_original
        allow(root_path).to receive(:join).with("Procfile").and_return(failing_procfile)
      end

      after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

      it "captures the error as a warning that names the offending file" do
        expect { doctor.send(:check_deprecated_renderer_cache_task) }.not_to raise_error
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? do |m|
                 m[:content].include?("Could not scan Procfile for deprecated renderer-cache task")
               end).to be(true)
      end
    end

    context "when probing a deploy-script file size raises an unexpected error" do
      let(:tmpdir) { Dir.mktmpdir }
      let(:deploy_path) { File.join(tmpdir, "bin", "deploy") }

      before do
        FileUtils.mkdir_p(File.dirname(deploy_path))
        File.write(
          deploy_path,
          "bundle exec rake react_on_rails_pro:pre_stage_bundle_for_node_renderer\n"
        )

        root_path = Pathname.new(tmpdir)
        allow(Rails).to receive(:root).and_return(root_path)

        failing_procfile = instance_double(Pathname)
        allow(failing_procfile).to receive(:file?).and_return(true)
        allow(failing_procfile).to receive(:size).and_raise(Errno::EACCES, "simulated size failure")
        allow(root_path).to receive(:join).and_call_original
        allow(root_path).to receive(:join).with("Procfile").and_return(failing_procfile)
      end

      after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

      it "captures the error for that file and continues scanning the rest" do
        expect { doctor.send(:check_deprecated_renderer_cache_task) }.not_to raise_error
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? do |m|
                 m[:content].include?("Could not scan Procfile for deprecated renderer-cache task")
               end).to be(true)
        expect(warning_msgs.any? { |m| m[:content].include?("bin/deploy") }).to be(true)
        expect(warning_msgs.none? do |m|
                 m[:content].include?("Could not complete scan for deprecated renderer-cache task")
               end).to be(true)
      end
    end

    context "when the deprecated task name appears only inside a comment" do
      let(:tmpdir) { Dir.mktmpdir }

      before do
        File.write(
          File.join(tmpdir, "Procfile"),
          "# was: bundle exec rake react_on_rails_pro:pre_stage_bundle_for_node_renderer\n" \
          "web: bundle exec puma\n"
        )
        File.write(
          File.join(tmpdir, "Dockerfile"),
          "# previously: rake react_on_rails_pro:pre_stage_bundle_for_node_renderer\n" \
          "RUN bundle exec rake react_on_rails_pro:pre_seed_renderer_cache\n"
        )
        allow(Rails).to receive(:root).and_return(Pathname.new(tmpdir))
      end

      after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

      it "does not warn for files where every match is in a leading-comment line" do
        doctor.send(:check_deprecated_renderer_cache_task)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs).to be_empty
      end
    end

    context "when the deprecated task name appears only in a trailing inline comment" do
      let(:tmpdir) { Dir.mktmpdir }

      before do
        File.write(
          File.join(tmpdir, "Procfile"),
          "web: bundle exec puma  # was: bundle exec rake react_on_rails_pro:pre_stage_bundle_for_node_renderer\n"
        )
        allow(Rails).to receive(:root).and_return(Pathname.new(tmpdir))
      end

      after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

      it "does not warn when the task only appears after a trailing `#` annotation" do
        doctor.send(:check_deprecated_renderer_cache_task)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs).to be_empty
      end
    end

    context "when a deploy-script file contains non-UTF-8 bytes" do
      let(:tmpdir) { Dir.mktmpdir }

      before do
        # Latin-1 byte (\xE9) outside ASCII; Pathname#read would raise
        # Encoding::InvalidByteSequenceError if the default external encoding
        # is UTF-8. The doctor scan should still match the ASCII task name.
        File.binwrite(
          File.join(tmpdir, "Procfile"),
          "# d\xE9ploiement legacy\n" \
          "web: bundle exec rake react_on_rails_pro:pre_stage_bundle_for_node_renderer\n"
        )
        allow(Rails).to receive(:root).and_return(Pathname.new(tmpdir))
      end

      after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

      it "still detects the deprecated task and does not surface a generic scan error" do
        doctor.send(:check_deprecated_renderer_cache_task)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("pre_stage_bundle_for_node_renderer") }).to be(true)
        expect(warning_msgs.none? do |m|
                 m[:content].include?("Could not scan Procfile for deprecated renderer-cache task")
               end).to be(true)
      end
    end

    context "when a CircleCI config references the deprecated task" do
      let(:tmpdir) { Dir.mktmpdir }

      before do
        FileUtils.mkdir_p(File.join(tmpdir, ".circleci"))
        File.write(
          File.join(tmpdir, ".circleci/config.yml"),
          "jobs:\n  deploy:\n    steps:\n      " \
          "- run: bundle exec rake react_on_rails_pro:pre_stage_bundle_for_node_renderer\n"
        )
        allow(Rails).to receive(:root).and_return(Pathname.new(tmpdir))
      end

      after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

      it "flags CI manifests in the fixed allowlist" do
        doctor.send(:check_deprecated_renderer_cache_task)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        suggestion_line = warning_msgs
                          .flat_map { |m| m[:content].split("\n") }
                          .find { |line| line.include?(".circleci/config.yml →") }
        expect(suggestion_line).not_to be_nil
        expect(suggestion_line).to include("pre_seed_renderer_cache")
      end
    end

    context "when a Jenkinsfile references the deprecated task" do
      let(:tmpdir) { Dir.mktmpdir }

      before do
        File.write(
          File.join(tmpdir, "Jenkinsfile"),
          "pipeline {\n  stages {\n    stage('deploy') {\n      " \
          "steps { sh 'bundle exec rake react_on_rails_pro:pre_stage_bundle_for_node_renderer' }\n    " \
          "}\n  }\n}\n"
        )
        allow(Rails).to receive(:root).and_return(Pathname.new(tmpdir))
      end

      after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

      it "flags Jenkinsfile entries in the fixed allowlist" do
        doctor.send(:check_deprecated_renderer_cache_task)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        suggestion_line = warning_msgs
                          .flat_map { |m| m[:content].split("\n") }
                          .find { |line| line.include?("Jenkinsfile →") }
        expect(suggestion_line).not_to be_nil
        expect(suggestion_line).to include("pre_seed_renderer_cache")
      end
    end

    context "when a Jenkinsfile only comments out the deprecated task" do
      let(:tmpdir) { Dir.mktmpdir }

      before do
        File.write(
          File.join(tmpdir, "Jenkinsfile"),
          "pipeline {\n  stages {\n    stage('deploy') {\n      " \
          "// sh 'bundle exec rake react_on_rails_pro:pre_stage_bundle_for_node_renderer'\n    " \
          "}\n  }\n}\n"
        )
        allow(Rails).to receive(:root).and_return(Pathname.new(tmpdir))
      end

      after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

      it "ignores Groovy-style line comments" do
        doctor.send(:check_deprecated_renderer_cache_task)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.none? { |m| m[:content].include?("pre_stage_bundle_for_node_renderer") }).to be(true)
      end
    end

    context "when a GitHub Actions workflow discovered via glob references the deprecated task" do
      let(:tmpdir) { Dir.mktmpdir }

      before do
        FileUtils.mkdir_p(File.join(tmpdir, ".github/workflows"))
        File.write(
          File.join(tmpdir, ".github/workflows/deploy.yml"),
          "jobs:\n  release:\n    steps:\n      " \
          "- run: bundle exec rake react_on_rails_pro:pre_stage_bundle_for_node_renderer\n"
        )
        # A second workflow with no reference confirms the glob only flags hits.
        File.write(
          File.join(tmpdir, ".github/workflows/test.yml"),
          "jobs:\n  test:\n    steps:\n      - run: bundle exec rspec\n"
        )
        allow(Rails).to receive(:root).and_return(Pathname.new(tmpdir))
      end

      after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

      it "flags workflows expanded from the bounded glob" do
        doctor.send(:check_deprecated_renderer_cache_task)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        warning_content = warning_msgs.map { |m| m[:content] }.join("\n")
        expect(warning_content).to include(".github/workflows/deploy.yml →")
        expect(warning_content).not_to include(".github/workflows/test.yml")
        expect(warning_content).to include("pre_seed_renderer_cache")
      end
    end

    context "when a Capistrano stage file outside the fixed allowlist references the deprecated task" do
      let(:tmpdir) { Dir.mktmpdir }

      before do
        FileUtils.mkdir_p(File.join(tmpdir, "config/deploy"))
        # canary.rb is not in RENDERER_CACHE_DEPLOY_SCRIPT_PATHS, so it can only be
        # found via the config/deploy/*.rb glob expansion.
        File.write(
          File.join(tmpdir, "config/deploy/canary.rb"),
          "before 'deploy:assets:precompile', 'react_on_rails_pro:pre_stage_bundle_for_node_renderer'\n"
        )
        allow(Rails).to receive(:root).and_return(Pathname.new(tmpdir))
      end

      after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

      it "flags arbitrary Capistrano stage files via the glob" do
        doctor.send(:check_deprecated_renderer_cache_task)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        suggestion_line = warning_msgs
                          .flat_map { |m| m[:content].split("\n") }
                          .find { |line| line.include?("config/deploy/canary.rb →") }
        expect(suggestion_line).not_to be_nil
        expect(suggestion_line).to include("pre_seed_renderer_cache")
        expect(suggestion_line).to include("MODE=symlink")
      end
    end

    context "when a glob-discovered file raises during read" do
      let(:tmpdir) { Dir.mktmpdir }
      let(:workflow_relpath) { ".github/workflows/deploy.yml" }
      let(:workflow_path) { File.join(tmpdir, workflow_relpath) }

      before do
        FileUtils.mkdir_p(File.dirname(workflow_path))
        File.write(
          workflow_path,
          "jobs:\n  release:\n    steps:\n      " \
          "- run: bundle exec rake react_on_rails_pro:pre_stage_bundle_for_node_renderer\n"
        )
        # Also drop a Procfile hit so we can confirm the scan keeps going after
        # the per-file failure on the glob-discovered workflow.
        File.write(
          File.join(tmpdir, "Procfile"),
          "web: bundle exec rake react_on_rails_pro:pre_stage_bundle_for_node_renderer\n"
        )

        root_path = Pathname.new(tmpdir)
        allow(Rails).to receive(:root).and_return(root_path)

        failing_workflow = instance_double(Pathname)
        allow(failing_workflow).to receive_messages(file?: true, size: File.size(workflow_path))
        allow(failing_workflow).to receive(:binread).and_raise(Errno::EIO, "simulated read failure")
        allow(root_path).to receive(:join).and_call_original
        allow(root_path).to receive(:join).with(workflow_relpath).and_return(failing_workflow)
      end

      after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

      it "captures the per-file failure and keeps scanning the remaining paths" do
        expect { doctor.send(:check_deprecated_renderer_cache_task) }.not_to raise_error
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? do |m|
                 m[:content].include?("Could not scan #{workflow_relpath} for deprecated renderer-cache task")
               end).to be(true)
        expect(warning_msgs.any? { |m| m[:content].include?("Procfile") }).to be(true)
        expect(warning_msgs.none? do |m|
                 m[:content].include?("Could not complete scan for deprecated renderer-cache task")
               end).to be(true)
      end
    end

    context "when expanding a deploy-script glob raises an unexpected error" do
      let(:tmpdir) { Dir.mktmpdir }

      before do
        File.write(
          File.join(tmpdir, "Procfile"),
          "web: bundle exec rake react_on_rails_pro:pre_stage_bundle_for_node_renderer\n"
        )
        allow(Rails).to receive(:root).and_return(Pathname.new(tmpdir))

        # Fail only the workflows glob; the others must still expand normally.
        allow(Dir).to receive(:glob).and_call_original
        allow(Dir).to receive(:glob)
          .with(".github/workflows/*.yml", File::FNM_PATHNAME, base: tmpdir)
          .and_raise(Errno::EACCES, "simulated glob failure")
      end

      after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

      it "captures the glob failure and continues scanning fixed paths" do
        expect { doctor.send(:check_deprecated_renderer_cache_task) }.not_to raise_error
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? do |m|
                 m[:content].include?("Could not expand renderer-cache deploy-script glob .github/workflows/*.yml")
               end).to be(true)
        expect(warning_msgs.any? { |m| m[:content].include?("pre_stage_bundle_for_node_renderer") }).to be(true)
        expect(warning_msgs.none? do |m|
                 m[:content].include?("Could not complete scan for deprecated renderer-cache task")
               end).to be(true)
      end
    end

    context "when a Capistrano stage file is reachable via both the fixed list and the glob" do
      let(:tmpdir) { Dir.mktmpdir }

      before do
        FileUtils.mkdir_p(File.join(tmpdir, "config/deploy"))
        File.write(
          File.join(tmpdir, "config/deploy/staging.rb"),
          "before 'deploy:assets:precompile', 'react_on_rails_pro:pre_stage_bundle_for_node_renderer'\n"
        )
        allow(Rails).to receive(:root).and_return(Pathname.new(tmpdir))
      end

      after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

      it "reports the same file only once" do
        doctor.send(:check_deprecated_renderer_cache_task)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        bullet_lines = warning_msgs
                       .flat_map { |m| m[:content].split("\n") }
                       .grep(%r{config/deploy/staging\.rb →})
        expect(bullet_lines.length).to eq(1)
      end
    end
  end

  describe "check_base_package_references" do
    let(:doctor) { described_class.new(verbose: false, fix: false) }
    let(:checker) { doctor.instance_variable_get(:@checker) }

    context "when JS files import from 'react-on-rails' (base package)" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            File.write("app/javascript/packs/custom-bundle.js",
                       "import ReactOnRails from 'react-on-rails';\nReactOnRails.register({});\n")
            example.run
          end
        end
      end

      it "reports warning with file paths" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("react-on-rails") }).to be true
        expect(warning_msgs.any? { |m| m[:content].include?("custom-bundle.js") }).to be true
        expect(warning_msgs.any? { |m| m[:content].include?("dynamic imports") }).to be true
      end
    end

    context "when JS files import from 'react-on-rails/client' (base subpath)" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            File.write("app/javascript/packs/app.js",
                       "import ReactOnRails from 'react-on-rails/client';\n")
            example.run
          end
        end
      end

      it "reports warning" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("react-on-rails") }).to be true
      end
    end

    context "when JS files use require('react-on-rails')" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            File.write("app/javascript/packs/legacy.js",
                       "const ReactOnRails = require('react-on-rails');\n")
            example.run
          end
        end
      end

      it "reports warning" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("react-on-rails") }).to be true
      end
    end

    context "when JS files dynamically import the base package after a Pro migration" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            File.write("app/javascript/packs/lazy.js",
                       "const ReactOnRails = await import('react-on-rails/client');\n")
            example.run
          end
        end
      end

      it "reports warning" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("lazy.js") }).to be true
      end
    end

    context "when JS files use a side-effect import of the base package after a Pro migration" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            File.write("app/javascript/packs/side-effect.js",
                       "import 'react-on-rails';\nimport 'react-on-rails/client';\n")
            example.run
          end
        end
      end

      it "reports warning" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("side-effect.js") }).to be true
      end
    end

    context "when JS files use a side-effect import of the Pro package" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            File.write("app/javascript/packs/side-effect.js",
                       "import 'react-on-rails-pro';\n")
            example.run
          end
        end
      end

      it "does not warn" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("side-effect.js") }).to be false
      end
    end

    context "when Vue or Svelte components reference the base package after a Pro migration" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            File.write("app/javascript/packs/Widget.vue",
                       "<template>\n  <div />\n</template>\n\n" \
                       "<script setup>\nimport ReactOnRails from 'react-on-rails';\n</script>\n")
            File.write("app/javascript/packs/Widget.svelte",
                       "<script lang=\"ts\">\n  import 'react-on-rails/client';\n</script>\n\n<div />\n")
            example.run
          end
        end
      end

      it "reports warning for both .vue and .svelte files" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("Widget.vue") }).to be true
        expect(warning_msgs.any? { |m| m[:content].include?("Widget.svelte") }).to be true
      end
    end

    context "when JS tests mock the base package after a Pro migration" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            File.write("app/javascript/packs/app.test.ts",
                       "jest.mock('react-on-rails', () => ({ authenticityHeaders: jest.fn() }));\n")
            example.run
          end
        end
      end

      it "reports warning" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("app.test.ts") }).to be true
        expect(warning_msgs.any? { |m| m[:content].include?("Found references to 'react-on-rails'") }).to be true
      end
    end

    context "when JS tests mock a base package subpath after a Pro migration" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            File.write("app/javascript/packs/app.test.ts",
                       "jest.mock('react-on-rails/client', () => ({ authenticityHeaders: jest.fn() }));\n")
            example.run
          end
        end
      end

      it "reports warning" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("app.test.ts") }).to be true
      end
    end

    context "when JS tests use a typed Jest mock for the base package after a Pro migration" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            File.write("app/javascript/packs/app.test.ts",
                       "jest.mock<typeof import('react-on-rails')>('react-on-rails', () => ({}));\n")
            example.run
          end
        end
      end

      it "reports warning" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("app.test.ts") }).to be true
      end
    end

    context "when JS tests mock the Pro package after a Pro migration" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            File.write("app/javascript/packs/app.test.ts",
                       "jest.mock('react-on-rails-pro', () => ({ authenticityHeaders: jest.fn() }));\n")
            example.run
          end
        end
      end

      it "does not warn" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("app.test.ts") }).to be false
      end
    end

    context "when Vitest tests import the actual base package after a Pro migration" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            File.write("app/javascript/packs/app.test.ts",
                       "const mod = await vi.importActual('react-on-rails/client');\n")
            example.run
          end
        end
      end

      it "reports warning" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("app.test.ts") }).to be true
      end
    end

    context "when Vitest tests import the base package mock without a receiver" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            File.write("app/javascript/packs/app.test.ts",
                       "const mod = await importMock('react-on-rails');\n")
            example.run
          end
        end
      end

      it "reports warning" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("app.test.ts") }).to be true
      end
    end

    context "when non-test code has a bare mock helper that references the base package string" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            File.write("app/javascript/packs/factory.ts",
                       "mock('react-on-rails', factory);\n")
            example.run
          end
        end
      end

      it "does not warn" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("factory.ts") }).to be false
      end
    end

    context "when non-test code has a mock-like receiver that references the base package string" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            File.write("app/javascript/packs/factory.ts",
                       "server.mock('react-on-rails', factory);\n")
            example.run
          end
        end
      end

      it "does not warn" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("factory.ts") }).to be false
      end
    end

    context "when JS tests use additional mock helpers after a Pro migration" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            {
              "create-mock.test.ts" => "jest.createMockFromModule('react-on-rails');\n",
              "unmock.test.ts" => "jest.unmock('react-on-rails');\n",
              "deep-unmock.test.ts" => "jest.deepUnmock('react-on-rails');\n",
              "do-mock.test.ts" => "jest.doMock('react-on-rails/client', () => ({}));\n",
              "do-unmock.test.ts" => "vi.doUnmock('react-on-rails');\n",
              "dont-mock.test.ts" => "jest.dontMock('react-on-rails');\n",
              "set-mock.test.ts" => "jest.setMock('react-on-rails', {});\n",
              "unstable-mock-module.test.ts" => "jest.unstable_mockModule('react-on-rails', () => ({}));\n",
              "unstable-unmock-module.test.ts" => "jest.unstable_unmockModule('react-on-rails');\n",
              "require-actual.test.ts" => "const mod = jest.requireActual('react-on-rails');\n",
              "require-mock.test.ts" => "const mod = jest.requireMock('react-on-rails/client');\n",
              "vitest-mock.test.ts" => "vi.mock('react-on-rails', () => ({ authenticityHeaders: vi.fn() }));\n"
            }.each do |filename, content|
              File.write("app/javascript/packs/#{filename}", content)
            end
            example.run
          end
        end
      end

      it "reports warning for each stale helper reference" do
        doctor.send(:check_base_package_references)
        warning_content = checker.messages.select { |m| m[:type] == :warning }.map { |m| m[:content] }.join("\n")
        expect(warning_content).to include("create-mock.test.ts")
        expect(warning_content).to include("unmock.test.ts")
        expect(warning_content).to include("deep-unmock.test.ts")
        expect(warning_content).to include("do-mock.test.ts")
        expect(warning_content).to include("do-unmock.test.ts")
        expect(warning_content).to include("dont-mock.test.ts")
        expect(warning_content).to include("set-mock.test.ts")
        expect(warning_content).to include("unstable-mock-module.test.ts")
        expect(warning_content).to include("unstable-unmock-module.test.ts")
        expect(warning_content).to include("require-actual.test.ts")
        expect(warning_content).to include("require-mock.test.ts")
        expect(warning_content).to include("vitest-mock.test.ts")
      end
    end

    context "when JS tests use a nonstandard vitest namespace object" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            File.write("app/javascript/packs/vitest-namespace.test.ts",
                       "vitest.mock('react-on-rails', () => ({}));\n")
            example.run
          end
        end
      end

      it "does not report a warning for the nonstandard helper form" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("vitest-namespace.test.ts") }).to be false
      end
    end

    context "when TypeScript declaration files augment the base package after a Pro migration" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/types")
            File.write("app/javascript/types/react-on-rails.d.ts",
                       "declare module 'react-on-rails' {\n  export function register(): void;\n}\n")
            example.run
          end
        end
      end

      it "reports warning" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("react-on-rails.d.ts") }).to be true
      end
    end

    context "when TypeScript declaration files augment a base package subpath after a Pro migration" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/types")
            File.write("app/javascript/types/react-on-rails-client.d.ts",
                       "declare module 'react-on-rails/client' {\n  export function register(): void;\n}\n")
            example.run
          end
        end
      end

      it "reports warning" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("react-on-rails-client.d.ts") }).to be true
      end
    end

    context "when TypeScript declarations export augmentations for the base package after a Pro migration" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/types")
            File.write("app/javascript/types/react-on-rails-export.d.ts",
                       "export declare module 'react-on-rails' {\n  export function register(): void;\n}\n")
            example.run
          end
        end
      end

      it "reports warning" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("react-on-rails-export.d.ts") }).to be true
      end
    end

    context "when module files use ESM or CommonJS extensions after a Pro migration" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            File.write("app/javascript/packs/esm-entry.mjs",
                       "import ReactOnRails from 'react-on-rails';\n")
            File.write("app/javascript/packs/cjs-entry.cjs",
                       "const ReactOnRails = require('react-on-rails/client');\n")
            example.run
          end
        end
      end

      it "reports warning for each module file" do
        doctor.send(:check_base_package_references)
        warning_content = checker.messages.select { |m| m[:type] == :warning }.map { |m| m[:content] }.join("\n")
        expect(warning_content).to include("esm-entry.mjs")
        expect(warning_content).to include("cjs-entry.cjs")
      end
    end

    context "when TypeScript module files use .mts or .cts extensions after a Pro migration" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            FileUtils.mkdir_p("app/javascript/types")
            File.write("app/javascript/packs/esm-entry.mts",
                       "import ReactOnRails from 'react-on-rails';\n")
            File.write("app/javascript/packs/cjs-entry.cts",
                       "const ReactOnRails = require('react-on-rails/client');\n")
            File.write("app/javascript/types/react-on-rails.d.mts",
                       "declare module 'react-on-rails' {\n  export function register(): void;\n}\n")
            File.write("app/javascript/types/react-on-rails.d.cts",
                       "declare module 'react-on-rails/client' {\n  export function register(): void;\n}\n")
            example.run
          end
        end
      end

      it "reports warning for each TypeScript module and declaration file" do
        doctor.send(:check_base_package_references)
        warning_content = checker.messages.select { |m| m[:type] == :warning }.map { |m| m[:content] }.join("\n")
        expect(warning_content).to include("esm-entry.mts")
        expect(warning_content).to include("cjs-entry.cts")
        expect(warning_content).to include("react-on-rails.d.mts")
        expect(warning_content).to include("react-on-rails.d.cts")
      end
    end

    context "when .mts or .cts files correctly reference 'react-on-rails-pro'" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            FileUtils.mkdir_p("app/javascript/types")
            File.write("app/javascript/packs/esm-entry.mts",
                       "import ReactOnRails from 'react-on-rails-pro';\n")
            File.write("app/javascript/packs/cjs-entry.cts",
                       "const ReactOnRails = require('react-on-rails-pro/client');\n")
            File.write("app/javascript/types/react-on-rails-pro.d.mts",
                       "declare module 'react-on-rails-pro' {\n  export function register(): void;\n}\n")
            File.write("app/javascript/types/react-on-rails-pro.d.cts",
                       "declare module 'react-on-rails-pro/client' {\n  export function register(): void;\n}\n")
            example.run
          end
        end
      end

      it "reports success without flagging Pro references" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        success_msgs = checker.messages.select { |m| m[:type] == :success }
        expect(warning_msgs).to be_empty
        expect(success_msgs.any? { |m| m[:content].include?("Pro package used correctly") }).to be true
      end
    end

    context "when one scanned file has invalid UTF-8 content" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            File.write("app/javascript/packs/app.js",
                       "import ReactOnRails from 'react-on-rails';\n")
            File.binwrite("app/javascript/packs/binary.js", "\xFF")
            example.run
          end
        end
      end

      it "skips the unreadable file and keeps scanning the rest" do
        doctor.send(:check_base_package_references)
        warning_content = checker.messages.select { |m| m[:type] == :warning }.map { |m| m[:content] }.join("\n")
        expect(warning_content).to include("app.js")
        expect(warning_content).not_to include("Could not scan")
      end
    end

    context "when JS files correctly import from 'react-on-rails-pro'" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            File.write("app/javascript/packs/app.js",
                       "import ReactOnRails from 'react-on-rails-pro';\nReactOnRails.register({});\n")
            example.run
          end
        end
      end

      it "reports success" do
        doctor.send(:check_base_package_references)
        success_msgs = checker.messages.select { |m| m[:type] == :success }
        expect(success_msgs.any? { |m| m[:content].include?("Pro package used correctly") }).to be true
      end
    end

    context "when JS files correctly dynamically import from 'react-on-rails-pro'" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            File.write("app/javascript/packs/lazy.js",
                       "const ReactOnRails = await import('react-on-rails-pro/client');\n")
            example.run
          end
        end
      end

      it "reports success" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        success_msgs = checker.messages.select { |m| m[:type] == :success }
        expect(warning_msgs).to be_empty
        expect(success_msgs.any? { |m| m[:content].include?("Pro package used correctly") }).to be true
      end
    end

    context "when JS tests correctly mock 'react-on-rails-pro'" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            File.write("app/javascript/packs/app.test.ts",
                       "jest.mock('react-on-rails-pro', () => ({ authenticityHeaders: jest.fn() }));\n")
            example.run
          end
        end
      end

      it "reports success" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        success_msgs = checker.messages.select { |m| m[:type] == :success }
        expect(warning_msgs).to be_empty
        expect(success_msgs.any? { |m| m[:content].include?("Pro package used correctly") }).to be true
      end
    end

    context "when Vitest tests correctly import actual 'react-on-rails-pro'" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            File.write("app/javascript/packs/app.test.ts",
                       "const mod = await vi.importActual('react-on-rails-pro');\n")
            example.run
          end
        end
      end

      it "reports success" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        success_msgs = checker.messages.select { |m| m[:type] == :success }
        expect(warning_msgs).to be_empty
        expect(success_msgs.any? { |m| m[:content].include?("Pro package used correctly") }).to be true
      end
    end

    context "when TypeScript declarations correctly augment 'react-on-rails-pro'" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/types")
            File.write("app/javascript/types/react-on-rails-pro.d.ts",
                       "declare module 'react-on-rails-pro' {\n  export function register(): void;\n}\n")
            example.run
          end
        end
      end

      it "reports success" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        success_msgs = checker.messages.select { |m| m[:type] == :success }
        expect(warning_msgs).to be_empty
        expect(success_msgs.any? { |m| m[:content].include?("Pro package used correctly") }).to be true
      end
    end

    context "when TypeScript declarations correctly augment a Pro package subpath" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/types")
            File.write("app/javascript/types/react-on-rails-pro-client.d.ts",
                       "declare module 'react-on-rails-pro/client' {\n  export function register(): void;\n}\n")
            example.run
          end
        end
      end

      it "reports success" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        success_msgs = checker.messages.select { |m| m[:type] == :success }
        expect(warning_msgs).to be_empty
        expect(success_msgs.any? { |m| m[:content].include?("Pro package used correctly") }).to be true
      end
    end

    context "when no JS files exist" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) { example.run }
        end
      end

      it "reports success (no files to scan)" do
        doctor.send(:check_base_package_references)
        success_msgs = checker.messages.select { |m| m[:type] == :success }
        expect(success_msgs.any? { |m| m[:content].include?("Pro package used correctly") }).to be true
      end
    end

    context "when a generator-scanned client root contains stale base package references" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("client/app/packs")
            File.write("client/app/packs/app.test.ts",
                       "jest.mock('react-on-rails', () => ({}));\n")
            example.run
          end
        end
      end

      it "reports warning for the same root the Pro generator rewrites" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("client/app/packs/app.test.ts") }).to be true
      end
    end

    context "when Shakapacker source_path is custom (e.g. client/app)" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("config")
            File.write("config/shakapacker.yml", "default:\n  source_path: client/app\n")
            FileUtils.mkdir_p("client/app/packs")
            File.write("client/app/packs/app.js",
                       "import ReactOnRails from 'react-on-rails';\n")
            example.run
          end
        end
      end

      before do
        allow(doctor).to receive(:require).with("shakapacker").and_raise(LoadError)
      end

      it "scans the custom source_path and reports warning" do
        doctor.send(:check_base_package_references)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("react-on-rails") }).to be true
        expect(warning_msgs.any? { |m| m[:content].include?("client/app/packs/app.js") }).to be true
      end
    end

    context "when a file disappears during the base package scan" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("app/javascript/packs")
            example.run
          end
        end
      end

      it "skips the unreadable file and keeps scanning the rest" do
        missing_file = "app/javascript/packs/deleted.js"
        stale_file = "app/javascript/packs/stale.js"
        File.write(stale_file, "import ReactOnRails from 'react-on-rails';\n")

        allow(Dir).to receive(:glob).and_call_original
        allow(Dir).to receive(:glob).with("app/javascript/**/*.js").and_return([missing_file, stale_file])

        doctor.send(:check_base_package_references)
        warning_content = checker.messages.select { |m| m[:type] == :warning }.map { |m| m[:content] }.join("\n")
        expect(warning_content).to include(stale_file)
        expect(warning_content).not_to include("Could not scan for base package references")
      end
    end
  end

  # ── RSC Setup Checks ─────────────────────────────────────────────

  describe "RSC setup checks" do
    let(:doctor) { described_class.new(verbose: false, fix: false) }
    let(:checker) { doctor.instance_variable_get(:@checker) }

    before do
      allow(doctor).to receive(:puts)
      allow(doctor).to receive(:exit)
    end

    context "when Pro gem is not installed" do
      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
      end

      it "does not add any RSC messages" do
        initial_count = checker.messages.length
        doctor.send(:check_rsc_setup)
        expect(checker.messages.length).to eq(initial_count)
      end
    end

    context "when Pro is installed but RSC is disabled" do
      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
        pro_config = double("ProConfig", enable_rsc_support: false)
        stub_const("ReactOnRailsPro", double("ReactOnRailsPro", configuration: pro_config))
      end

      it "does not add any RSC messages" do
        initial_count = checker.messages.length
        doctor.send(:check_rsc_setup)
        expect(checker.messages.length).to eq(initial_count)
      end
    end

    context "when RSC is enabled with valid setup" do
      let(:pro_config) do
        double("ProConfig",
               enable_rsc_support: true,
               server_renderer: "NodeRenderer",
               rsc_bundle_js_file: "rsc-bundle.js",
               rsc_payload_generation_url_path: "rsc_payload/")
      end

      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("config/webpack")
            File.write("config/routes.rb", "Rails.application.routes.draw do\n  rsc_payload_route\nend")
            File.write("config/webpack/rscWebpackConfig.js", "module.exports = {}")
            File.write("package.json", '{"dependencies":{"react":"~19.0.4","react-on-rails-rsc":"1.0.0"}}')
            File.write("Procfile.dev", "rsc-bundle: RSC_BUNDLE_ONLY=true bin/shakapacker --watch")
            example.run
          end
        end
      end

      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
        stub_const("ReactOnRailsPro", double("ReactOnRailsPro", configuration: pro_config))
      end

      it "reports RSC detected with config values" do
        doctor.send(:check_rsc_setup)
        info_messages = checker.messages.select { |m| m[:type] == :info }
        expect(info_messages.any? { |m| m[:content].include?("React Server Components: enabled") }).to be true
        expect(info_messages.any? { |m| m[:content].include?("rsc-bundle.js") }).to be true
      end

      it "reports no errors for a complete setup" do
        doctor.send(:check_rsc_setup)
        error_messages = checker.messages.select { |m| m[:type] == :error }
        expect(error_messages).to be_empty
      end
    end

    context "when RSC is enabled but renderer is ExecJS" do
      let(:pro_config) do
        double("ProConfig",
               enable_rsc_support: true,
               server_renderer: "ExecJS",
               rsc_bundle_js_file: "rsc-bundle.js",
               rsc_payload_generation_url_path: "rsc_payload/")
      end

      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("config/webpack")
            File.write("config/routes.rb", "rsc_payload_route")
            File.write("config/webpack/rscWebpackConfig.js", "{}")
            File.write("package.json", '{"dependencies":{"react":"~19.0.4","react-on-rails-rsc":"1.0.0"}}')
            File.write("Procfile.dev", "rsc-bundle: RSC_BUNDLE_ONLY=true bin/shakapacker --watch")
            example.run
          end
        end
      end

      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
        stub_const("ReactOnRailsPro", double("ReactOnRailsPro", configuration: pro_config))
      end

      it "reports error about renderer mode" do
        doctor.send(:check_rsc_setup)
        error_messages = checker.messages.select { |m| m[:type] == :error }
        expect(error_messages.any? { |m| m[:content].include?("NodeRenderer") }).to be true
      end
    end

    context "when check_rsc_setup raises an unexpected error" do
      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
        stub_const("ReactOnRailsPro", double("ReactOnRailsPro"))
        allow(ReactOnRailsPro).to receive(:configuration).and_raise(StandardError, "unexpected failure")
      end

      it "catches the error and adds a warning" do
        doctor.send(:check_rsc_setup)
        warning_messages = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_messages.any? { |m| m[:content].include?("unexpected failure") }).to be true
      end
    end
  end

  # ── RSC Individual Check Methods ─────────────────────────────────

  describe "check_rsc_payload_route" do
    let(:doctor) { described_class.new(verbose: false, fix: false) }
    let(:checker) { doctor.instance_variable_get(:@checker) }

    context "when routes.rb contains rsc_payload_route" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("config")
            File.write("config/routes.rb",
                       "Rails.application.routes.draw do\n  rsc_payload_route\nend")
            example.run
          end
        end
      end

      it "reports success" do
        doctor.send(:check_rsc_payload_route)
        success_msgs = checker.messages.select { |m| m[:type] == :success }
        expect(success_msgs.any? { |m| m[:content].include?("RSC payload route") }).to be true
      end
    end

    context "when rsc_payload_route is commented out" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("config")
            File.write("config/routes.rb",
                       "Rails.application.routes.draw do\n  # rsc_payload_route\nend")
            example.run
          end
        end
      end

      it "reports error (does not count commented-out route)" do
        doctor.send(:check_rsc_payload_route)
        error_msgs = checker.messages.select { |m| m[:type] == :error }
        expect(error_msgs.any? { |m| m[:content].include?("rsc_payload_route") }).to be true
      end
    end

    context "when routes.rb exists but lacks rsc_payload_route" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("config")
            File.write("config/routes.rb", "Rails.application.routes.draw do\nend")
            example.run
          end
        end
      end

      it "reports error with fix instructions" do
        doctor.send(:check_rsc_payload_route)
        error_msgs = checker.messages.select { |m| m[:type] == :error }
        expect(error_msgs.any? { |m| m[:content].include?("rsc_payload_route") }).to be true
      end
    end

    context "when routes.rb does not exist" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) { example.run }
        end
      end

      it "reports warning" do
        doctor.send(:check_rsc_payload_route)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("routes.rb not found") }).to be true
      end
    end
  end

  describe "check_rsc_bundler_config" do
    let(:doctor) { described_class.new(verbose: false, fix: false) }
    let(:checker) { doctor.instance_variable_get(:@checker) }

    context "when config/webpack/rscWebpackConfig.js exists" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("config/webpack")
            File.write("config/webpack/rscWebpackConfig.js", "{}")
            example.run
          end
        end
      end

      it "reports success" do
        doctor.send(:check_rsc_bundler_config)
        success_msgs = checker.messages.select { |m| m[:type] == :success }
        expect(success_msgs.any? { |m| m[:content].include?("RSC bundler config") }).to be true
      end
    end

    context "when config/rspack/rscWebpackConfig.js exists" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            FileUtils.mkdir_p("config/rspack")
            File.write("config/rspack/rscWebpackConfig.js", "{}")
            example.run
          end
        end
      end

      it "reports success for rspack variant" do
        doctor.send(:check_rsc_bundler_config)
        success_msgs = checker.messages.select { |m| m[:type] == :success }
        expect(success_msgs.any? { |m| m[:content].include?("RSC bundler config") }).to be true
      end
    end

    context "when neither config exists" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) { example.run }
        end
      end

      it "reports error with fix instructions" do
        doctor.send(:check_rsc_bundler_config)
        error_msgs = checker.messages.select { |m| m[:type] == :error }
        expect(error_msgs.any? { |m| m[:content].include?("RSC bundler config not found") }).to be true
      end
    end
  end

  describe "check_rsc_react_version" do
    let(:doctor) { described_class.new(verbose: false, fix: false) }
    let(:checker) { doctor.instance_variable_get(:@checker) }

    def install_react(version)
      FileUtils.mkdir_p("node_modules/react")
      File.write("node_modules/react/package.json", "{\"version\":\"#{version}\"}")
    end

    def install_package(name, package_json)
      FileUtils.mkdir_p("node_modules/#{name}")
      File.write("node_modules/#{name}/package.json", JSON.generate(package_json))
    end

    def stub_package_root(path)
      allow(doctor).to receive(:resolved_package_root).and_return(path)
    end

    before do
      # RSpec runs before hooks inside the chdir around hooks below, so Dir.pwd is the per-example tmpdir.
      stub_package_root(Dir.pwd)
    end

    context "when React 19.0.4+" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            install_react("19.0.4")
            example.run
          end
        end
      end

      it "reports success" do
        doctor.send(:check_rsc_react_version)
        success_msgs = checker.messages.select { |m| m[:type] == :success }
        expect(success_msgs.any? { |m| m[:content].include?("compatible with RSC") }).to be true
      end
    end

    context "when React 19.0.0-19.0.3" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            install_react("19.0.2")
            example.run
          end
        end
      end

      it "reports warning about security vulnerabilities" do
        doctor.send(:check_rsc_react_version)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("security vulnerabilities") }).to be true
      end
    end

    context "when React 18.x" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            install_react("18.2.0")
            example.run
          end
        end
      end

      it "reports error" do
        doctor.send(:check_rsc_react_version)
        error_msgs = checker.messages.select { |m| m[:type] == :error }
        expect(error_msgs.any? { |m| m[:content].include?("not compatible with RSC") }).to be true
      end
    end

    context "when React 19.1.x" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            install_react("19.1.0")
            example.run
          end
        end
      end

      it "reports warning about unverified version" do
        doctor.send(:check_rsc_react_version)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("not been verified") }).to be true
      end
    end

    context "when React 20.x (future major)" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            install_react("20.0.0")
            example.run
          end
        end
      end

      it "reports warning, not error" do
        doctor.send(:check_rsc_react_version)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        error_msgs = checker.messages.select { |m| m[:type] == :error }
        expect(warning_msgs.any? { |m| m[:content].include?("not been verified") }).to be true
        expect(error_msgs).to be_empty
      end
    end

    context "when installed version differs from declared range" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            File.write("package.json", '{"dependencies":{"react":"^19.0.0"}}')
            install_react("19.0.4")
            example.run
          end
        end
      end

      it "uses the installed version, not the declared range" do
        doctor.send(:check_rsc_react_version)
        success_msgs = checker.messages.select { |m| m[:type] == :success }
        expect(success_msgs.any? { |m| m[:content].include?("19.0.4") }).to be true
      end
    end

    context "when react-on-rails-rsc declares a React peer range" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            File.write(
              "package.json",
              JSON.generate(
                "dependencies" => {
                  "react" => "19.0.7",
                  "react-dom" => "19.0.7",
                  "react-on-rails-rsc" => "19.2.0-rc.4"
                }
              )
            )
            install_react("19.0.7")
            install_package("react-dom", "version" => "19.0.7")
            install_package(
              "react-on-rails-rsc",
              "version" => "19.2.0-rc.4",
              "peerDependencies" => { "react" => "^19.2.7", "react-dom" => "^19.2.7" }
            )
            example.run
          end
        end
      end

      it "errors when installed React does not satisfy the RSC peer range" do
        doctor.send(:check_rsc_react_version)

        error_msgs = checker.messages.select { |m| m[:type] == :error }.map { |m| m[:content] }
        expect(error_msgs).to include(
          a_string_including(
            "react-on-rails-rsc 19.2.0-rc.4 requires react ^19.2.7",
            "installed react is 19.0.7"
          )
        )
      end

      it "reports an error when the declared RSC package cannot be resolved from node_modules" do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            File.write(
              "package.json",
              JSON.generate(
                "dependencies" => {
                  "react" => "19.0.7",
                  "react-on-rails-rsc" => "19.2.0-rc.4"
                }
              )
            )
            install_react("19.0.7")
            stub_package_root(Dir.pwd)

            doctor.send(:check_rsc_react_version)

            error_msgs = checker.messages.select { |m| m[:type] == :error }.map { |m| m[:content] }
            expect(error_msgs).to include(
              a_string_including(
                "react-on-rails-rsc is declared in package.json but could not be resolved from node_modules",
                "npm install"
              )
            )
            expect(error_msgs.none? { |msg| msg.include?("requires react") }).to be true
          end
        end
      end

      it "keeps the React 19.0.4 security floor warning when broad RSC peer ranges allow older React" do
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            File.write(
              "package.json",
              JSON.generate(
                "dependencies" => {
                  "react" => "19.0.2",
                  "react-dom" => "19.0.2",
                  "react-on-rails-rsc" => "19.0.5"
                }
              )
            )
            install_react("19.0.2")
            install_package("react-dom", "version" => "19.0.2")
            install_package(
              "react-on-rails-rsc",
              "version" => "19.0.5",
              "peerDependencies" => { "react" => "^19.0.0", "react-dom" => "^19.0.0" }
            )
            stub_package_root(Dir.pwd)
            allow(doctor).to receive(:rsc_dist_tags).and_return({})

            doctor.send(:check_rsc_react_version)

            warning_msgs = checker.messages.select { |m| m[:type] == :warning }.map { |m| m[:content] }
            expect(warning_msgs).to include(a_string_including("security vulnerabilities fixed in 19.0.4+"))
          end
        end
      end
    end

    context "when react-on-rails-rsc is behind the prerelease dist-tag" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            File.write(
              "package.json",
              JSON.generate(
                "dependencies" => {
                  "react" => "19.0.7",
                  "react-dom" => "19.0.7",
                  "react-on-rails-rsc" => "19.0.5"
                }
              )
            )
            install_react("19.0.7")
            install_package("react-dom", "version" => "19.0.7")
            install_package(
              "react-on-rails-rsc",
              "version" => "19.0.5",
              "peerDependencies" => { "react" => "^19.0.4", "react-dom" => "^19.0.4" }
            )
            example.run
          end
        end
      end

      it "warns that the installed package is behind the next dist-tag" do
        allow(doctor).to receive(:capture_rsc_dist_tags)
          .with(Dir.pwd)
          .and_return(
            [
              JSON.generate("latest" => "19.0.5", "next" => "19.2.0-rc.4"),
              instance_double(Process::Status, success?: true)
            ]
          )

        doctor.send(:check_rsc_react_version)

        warning_msgs = checker.messages.select { |m| m[:type] == :warning }.map { |m| m[:content] }
        expect(warning_msgs).to include(
          a_string_including(
            "react-on-rails-rsc 19.0.5 is behind the npm next dist-tag 19.2.0-rc.4",
            "React Server Components track React minor versions"
          )
        )
      end

      it "reports an info message once when the dist-tag lookup is unavailable" do
        allow(doctor).to receive(:capture_rsc_dist_tags)
          .with(Dir.pwd)
          .and_return(["", instance_double(Process::Status, success?: false)])

        doctor.send(:check_rsc_react_version)
        doctor.send(:check_rsc_react_version)

        info_msgs = checker.messages.select { |m| m[:type] == :info }.map { |m| m[:content] }
        expect(
          info_msgs.count { |msg| msg.include?("Could not fetch react-on-rails-rsc dist-tags") }
        ).to eq(1)
        expect(doctor).to have_received(:capture_rsc_dist_tags).with(Dir.pwd).once
      end

      it "kills a stalled dist-tag subprocess and reports an info message" do
        stub_const("ReactOnRails::Doctor::NPM_VIEW_FETCH_TIMEOUT_SECONDS", 0.1)
        stub_const("ReactOnRails::Doctor::NPM_VIEW_TERMINATION_GRACE_SECONDS", 0.1)
        allow(doctor).to receive(:rsc_dist_tag_command).and_return([Gem.ruby, "-e", "sleep 20"])

        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        doctor.send(:check_rsc_react_version)
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at

        info_msgs = checker.messages.select { |m| m[:type] == :info }.map { |m| m[:content] }
        expect(info_msgs).to include(a_string_including("Could not fetch react-on-rails-rsc dist-tags"))
        expect(elapsed).to be < 2
      end

      it "reports an info message when npm returns JSON that is not an object" do
        allow(doctor).to receive(:capture_rsc_dist_tags)
          .with(Dir.pwd)
          .and_return(["null", instance_double(Process::Status, success?: true)])

        doctor.send(:check_rsc_react_version)

        info_msgs = checker.messages.select { |m| m[:type] == :info }.map { |m| m[:content] }
        expect(info_msgs).to include(a_string_including("Could not fetch react-on-rails-rsc dist-tags"))
      end
    end

    describe "RSC npm range parsing" do
      it "supports npm hyphen ranges" do
        expect(doctor.send(:npm_range_satisfied?, "19.1.0", "19.0.0 - 19.2.0"))
          .to be true
        expect(doctor.send(:npm_range_satisfied?, "19.3.0", "19.0.0 - 19.2.0"))
          .to be false
      end

      it "uses npm tilde upper bounds for single-component versions" do
        expect(doctor.send(:npm_range_satisfied?, "1.9.0", "~1")).to be true
        expect(doctor.send(:npm_range_satisfied?, "2.0.0", "~1")).to be false
      end

      it "supports npm partial x-range upper bounds" do
        expect(doctor.send(:npm_range_satisfied?, "19.2.7", "19.x")).to be true
        expect(doctor.send(:npm_range_satisfied?, "20.0.0", "19.x")).to be false
        expect(doctor.send(:npm_range_satisfied?, "19.2.7", "19.2")).to be true
        expect(doctor.send(:npm_range_satisfied?, "19.3.0", "19.2")).to be false
        expect(doctor.send(:npm_range_satisfied?, "19.2.7", "19.2.x")).to be true
        expect(doctor.send(:npm_range_satisfied?, "19.3.0", "19.2.x")).to be false
        expect(doctor.send(:npm_range_satisfied?, "19.3.0", "^19.2")).to be true
        expect(doctor.send(:npm_range_satisfied?, "20.0.0", "^19.2")).to be false
        expect(doctor.send(:npm_range_satisfied?, "0.0.5", "^0.0.x")).to be true
        expect(doctor.send(:npm_range_satisfied?, "0.1.0", "^0.0.x")).to be false
      end
    end

    describe "installed package resolution" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) { example.run }
        end
      end

      it "does not pass invalid package names to node resolution" do
        allow(Open3).to receive(:capture3)

        result = doctor.send(
          :installed_package_json,
          Dir.pwd,
          "react'); require('child_process').execSync('echo unsafe'); require('react"
        )

        expect(result).to be_nil
        expect(Open3).not_to have_received(:capture3)
      end

      it "rejects uppercase package names before node resolution" do
        allow(Open3).to receive(:capture3)

        result = doctor.send(:installed_package_json, Dir.pwd, "React")

        expect(result).to be_nil
        expect(Open3).not_to have_received(:capture3)
      end
    end

    context "when React is installed in a configured nested JS workspace" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) { example.run }
        end
      end

      it "uses the configured package root for node module resolution" do
        package_root = File.join(Dir.pwd, "client")
        FileUtils.mkdir_p("client")
        File.write("client/package.json", '{"dependencies":{"react":"^19.0.0"}}')
        FileUtils.mkdir_p("client/node_modules/react")
        File.write("client/node_modules/react/package.json", '{"version":"19.0.4"}')
        stub_package_root(package_root)
        allow(Open3).to receive(:capture3)
          .with(
            "node",
            "-e",
            "console.log(require.resolve(process.argv[1] + '/package.json'))",
            "react",
            chdir: package_root
          )
          .and_return(
            [
              "#{File.join(package_root, 'node_modules/react/package.json')}\n",
              "",
              instance_double(Process::Status, success?: true)
            ]
          )

        doctor.send(:check_rsc_react_version)
        success_msgs = checker.messages.select { |m| m[:type] == :success }
        expect(success_msgs.any? { |m| m[:content].include?("19.0.4") }).to be true
      end

      it "falls back to the declared React version in the nested package.json when node is unavailable" do
        FileUtils.mkdir_p("client")
        File.write("client/package.json", '{"dependencies":{"react":"19.0.4"}}')
        stub_package_root(File.join(Dir.pwd, "client"))
        allow(Open3).to receive(:capture3).and_return(
          ["", "", instance_double(Process::Status, success?: false)]
        )

        doctor.send(:check_rsc_react_version)
        success_msgs = checker.messages.select { |m| m[:type] == :success }
        expect(success_msgs.any? { |m| m[:content].include?("19.0.4") }).to be true
      end

      it "warns when the configured package root does not exist" do
        stub_package_root(File.join(Dir.pwd, "client"))

        doctor.send(:check_rsc_react_version)

        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("node_modules_location") }).to be true
        expect(warning_msgs.any? { |m| m[:content].include?("does not exist") }).to be true
        expect(warning_msgs.any? { |m| m[:content].include?("config/initializers/react_on_rails.rb") }).to be true
        expect(warning_msgs.count { |m| m[:content].include?("node_modules_location") }).to eq(1)
        expect(warning_msgs.any? { |m| m[:content].include?("all diagnostics that read from it are skipped") })
          .to be true
      end

      it "warns when the configured package root exists without package.json" do
        package_root = File.join(Dir.pwd, "client")
        package_json_path = File.join(package_root, "package.json")
        FileUtils.mkdir_p(package_root)
        stub_package_root(package_root)
        allow(Open3).to receive(:capture3).and_return(
          ["", "", instance_double(Process::Status, success?: false)]
        )

        doctor.send(:check_rsc_react_version)

        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("#{package_json_path} not found") }).to be true
        expect(warning_msgs.any? { |m| m[:content].include?("declared React version") }).to be true
        expect(warning_msgs.any? { |m| m[:content].include?("config/initializers/react_on_rails.rb") }).to be true
      end
    end

    context "when React is not installed" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            File.write("package.json", '{"dependencies":{}}')
            example.run
          end
        end
      end

      it "reports info and skips" do
        doctor.send(:check_rsc_react_version)
        info_msgs = checker.messages.select { |m| m[:type] == :info }
        expect(info_msgs.any? { |m| m[:content].include?("Could not detect React version") }).to be true
      end
    end
  end

  describe "JSON output for RSC compatibility" do
    let(:json_doctor) { described_class.new(format: :json) }
    let(:checker) { json_doctor.instance_variable_get(:@checker) }
    let(:pro_config) do
      double(
        "ProConfig",
        enable_rsc_support: true,
        server_renderer: "NodeRenderer",
        rsc_bundle_js_file: "rsc-bundle.js",
        rsc_payload_generation_url_path: "rsc_payload/"
      )
    end

    def install_package(name, package_json)
      FileUtils.mkdir_p("node_modules/#{name}")
      File.write("node_modules/#{name}/package.json", JSON.generate(package_json))
    end

    around do |example|
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          FileUtils.mkdir_p("config/webpack")
          File.write("config/routes.rb", "Rails.application.routes.draw do\n  rsc_payload_route\nend")
          File.write("config/webpack/rscWebpackConfig.js", "{}")
          File.write("Procfile.dev", "rsc-bundle: RSC_BUNDLE_ONLY=true bin/shakapacker --watch")
          File.write(
            "package.json",
            JSON.generate(
              "dependencies" => {
                "react" => "19.0.7",
                "react-dom" => "19.0.7",
                "react-on-rails-rsc" => "19.2.0-rc.4"
              }
            )
          )
          install_package("react", "version" => "19.0.7")
          install_package("react-dom", "version" => "19.0.7")
          install_package(
            "react-on-rails-rsc",
            "version" => "19.2.0-rc.4",
            "peerDependencies" => { "react" => "^19.2.7", "react-dom" => "^19.2.7" }
          )
          example.run
        end
      end
    end

    before do
      described_class::CHECK_SECTIONS.each do |section|
        allow(json_doctor).to receive(section[:method])
      end
      allow(json_doctor).to receive(:check_rsc_setup).and_call_original
      allow(json_doctor).to receive(:ensure_rails_environment_loaded)
      allow(json_doctor).to receive(:resolved_package_root).and_return(Dir.pwd)
      allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
      stub_const("ReactOnRailsPro", double("ReactOnRailsPro", configuration: pro_config))
    end

    it "includes RSC peer compatibility failures in the react_server_components check" do
      output = []
      allow(json_doctor).to receive(:exit)
      allow(json_doctor).to receive(:puts) { |arg| output << arg.to_s }

      json_doctor.run_diagnosis

      report = JSON.parse(output.join("\n"))
      rsc_check = report["checks"].find { |check| check["id"] == "react_server_components" }
      expect(rsc_check["status"]).to eq("fail")
      expect(rsc_check["message"]).to include("react-on-rails-rsc 19.2.0-rc.4 requires react ^19.2.7")
      expect(report["status"]).to eq("fail")
    end
  end

  describe "check_rsc_procfile_watcher" do
    let(:doctor) { described_class.new(verbose: false, fix: false) }
    let(:checker) { doctor.instance_variable_get(:@checker) }

    context "when Procfile.dev contains RSC_BUNDLE_ONLY" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            File.write("Procfile.dev", "rsc-bundle: RSC_BUNDLE_ONLY=true bin/shakapacker --watch")
            example.run
          end
        end
      end

      it "reports success" do
        doctor.send(:check_rsc_procfile_watcher)
        success_msgs = checker.messages.select { |m| m[:type] == :success }
        expect(success_msgs.any? { |m| m[:content].include?("RSC bundle watcher") }).to be true
      end
    end

    context "when RSC_BUNDLE_ONLY is commented out in Procfile.dev" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            File.write("Procfile.dev",
                       "web: bin/rails server\n# rsc-bundle: RSC_BUNDLE_ONLY=true bin/shakapacker --watch")
            example.run
          end
        end
      end

      it "reports warning (does not count commented-out entry)" do
        doctor.send(:check_rsc_procfile_watcher)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("RSC bundle watcher not found") }).to be true
      end
    end

    context "when Procfile.dev exists but lacks RSC entry" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) do
            File.write("Procfile.dev", "web: bin/rails server\nwebpack: bin/shakapacker-dev-server")
            example.run
          end
        end
      end

      it "reports warning" do
        doctor.send(:check_rsc_procfile_watcher)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("RSC bundle watcher not found") }).to be true
      end
    end

    context "when Procfile.dev does not exist" do
      around do |example|
        Dir.mktmpdir do |tmpdir|
          Dir.chdir(tmpdir) { example.run }
        end
      end

      it "reports warning" do
        doctor.send(:check_rsc_procfile_watcher)
        warning_msgs = checker.messages.select { |m| m[:type] == :warning }
        expect(warning_msgs.any? { |m| m[:content].include?("Procfile.dev not found") }).to be true
      end
    end
  end

  describe "check_rsc_client_manifest" do
    let(:doctor) { described_class.new(verbose: false, fix: false) }
    let(:checker) { doctor.instance_variable_get(:@checker) }

    around do |example|
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) { example.run }
      end
    end

    before do
      stub_const("ReactOnRailsPro", Module.new)
      ReactOnRailsPro.const_set(:Utils, Module.new)
      ReactOnRailsPro::Utils.define_singleton_method(:react_client_manifest_file_path) { nil }
      allow(ReactOnRailsPro::Utils).to receive(:react_client_manifest_file_path)
        .and_return(File.expand_path("public/packs/react-client-manifest.json"))
    end

    it "warns when the RSC client manifest resolves to a dev-server URL" do
      allow(ReactOnRailsPro::Utils).to receive(:react_client_manifest_file_path)
        .and_return("http://localhost:3035/packs/react-client-manifest.json")

      doctor.send(:check_rsc_client_manifest)

      warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
      info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
      expect(warning_messages).to include(a_string_including("dev-server URL"))
      expect(info_messages).to include(a_string_including("bin/dev static"))
    end

    it "warns when the RSC client manifest file is missing" do
      doctor.send(:check_rsc_client_manifest)

      warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
      info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
      expect(warning_messages).to include(a_string_including("RSC client manifest not found"))
      expect(info_messages).to include(a_string_including("bin/dev static"))
    end

    it "warns with rebuild guidance when the RSC client manifest is invalid JSON" do
      FileUtils.mkdir_p("public/packs")
      File.write("public/packs/react-client-manifest.json", "{not-json")

      doctor.send(:check_rsc_client_manifest)

      warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
      info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
      expect(warning_messages).to include(a_string_including("RSC client manifest is not valid JSON"))
      expect(info_messages).to include(a_string_including("bin/dev static"))
      expect(info_messages).to include(a_string_including("public/packs"))
    end

    it "warns when the RSC client manifest is missing client reference metadata" do
      FileUtils.mkdir_p("public/packs")
      File.write(
        "public/packs/react-client-manifest.json",
        JSON.generate("moduleLoading" => { "prefix" => "", "crossOrigin" => nil })
      )

      doctor.send(:check_rsc_client_manifest)

      warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
      expect(warning_messages).to include(
        a_string_including("RSC client manifest is missing filePathToModuleMetadata")
      )
    end

    it "warns when the RSC client manifest has no client reference metadata" do
      FileUtils.mkdir_p("public/packs")
      File.write(
        "public/packs/react-client-manifest.json",
        JSON.generate("moduleLoading" => { "prefix" => "", "crossOrigin" => nil }, "filePathToModuleMetadata" => {})
      )

      doctor.send(:check_rsc_client_manifest)

      warning_messages = checker.messages.select { |msg| msg[:type] == :warning }.map { |msg| msg[:content] }
      info_messages = checker.messages.select { |msg| msg[:type] == :info }.map { |msg| msg[:content] }
      expect(warning_messages).to include(
        a_string_including("RSC client manifest has no client reference metadata")
      )
      expect(info_messages).to include(a_string_including("bin/dev static"))
      expect(info_messages).to include(a_string_including("public/packs"))
      expect(info_messages).to include(a_string_including("ssr-generated"))
      expect(info_messages).to include(a_string_including(".node-renderer-bundles"))
    end
  end
  # rubocop:enable RSpec/VerifiedDoubles
end

# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "rbconfig"
require_relative "spec_helper"
require "tmpdir"

module ReactOnRails
  RSpec.describe Engine do
    describe ".skip_version_validation?" do
      let(:package_json_path) { "/fake/path/package.json" }

      before do
        allow(VersionChecker::NodePackageVersion).to receive(:package_json_path)
          .and_return(package_json_path)
        allow(Rails.logger).to receive(:debug)
      end

      context "when REACT_ON_RAILS_SKIP_VALIDATION is set" do
        before do
          ENV["REACT_ON_RAILS_SKIP_VALIDATION"] = "true"
        end

        after do
          ENV.delete("REACT_ON_RAILS_SKIP_VALIDATION")
        end

        it "returns true" do
          expect(described_class.skip_version_validation?).to be true
        end

        it "logs debug message about environment variable" do
          described_class.skip_version_validation?
          expect(Rails.logger).to have_received(:debug)
            .with("[React on Rails] Skipping validation - disabled via environment variable")
        end

        context "with other skip conditions also present" do
          context "when package.json exists and running a generator" do
            before do
              allow(File).to receive(:exist?).with(package_json_path).and_return(true)
              allow(described_class).to receive(:running_generator?).and_return(true)
            end

            it "prioritizes ENV over generator check" do
              expect(described_class.skip_version_validation?).to be true
            end

            it "short-circuits before checking generator context" do
              described_class.skip_version_validation?
              expect(Rails.logger).to have_received(:debug)
                .with("[React on Rails] Skipping validation - disabled via environment variable")
              expect(Rails.logger).not_to have_received(:debug)
                .with("[React on Rails] Skipping validation during generator runtime")
            end

            it "short-circuits before checking File.exist?" do
              described_class.skip_version_validation?
              expect(File).not_to have_received(:exist?)
            end
          end

          context "when package.json is missing" do
            before do
              allow(File).to receive(:exist?).with(package_json_path).and_return(false)
            end

            it "prioritizes ENV over package.json check" do
              expect(described_class.skip_version_validation?).to be true
            end

            it "short-circuits before checking package.json" do
              described_class.skip_version_validation?
              expect(Rails.logger).to have_received(:debug)
                .with("[React on Rails] Skipping validation - disabled via environment variable")
              expect(Rails.logger).not_to have_received(:debug)
                .with("[React on Rails] Skipping validation - package.json not found")
            end
          end
        end
      end

      context "when package.json doesn't exist" do
        before do
          allow(File).to receive(:exist?).with(package_json_path).and_return(false)
        end

        it "returns true" do
          expect(described_class.skip_version_validation?).to be true
        end

        it "logs debug message about missing package.json" do
          described_class.skip_version_validation?
          expect(Rails.logger).to have_received(:debug)
            .with("[React on Rails] Skipping validation - package.json not found")
        end
      end

      context "when package.json exists" do
        before do
          allow(File).to receive(:exist?).with(package_json_path).and_return(true)
        end

        context "when running a generator" do
          before do
            allow(described_class).to receive(:running_generator?).and_return(true)
          end

          it "returns true" do
            expect(described_class.skip_version_validation?).to be true
          end

          it "logs debug message about generator runtime" do
            described_class.skip_version_validation?
            expect(Rails.logger).to have_received(:debug)
              .with("[React on Rails] Skipping validation during generator runtime")
          end
        end

        context "when not running a generator" do
          before do
            allow(described_class).to receive(:running_generator?).and_return(false)
          end

          it "returns false" do
            expect(described_class.skip_version_validation?).to be false
          end
        end
      end
    end

    describe ".running_generator?" do
      # Uses defined?(Rails::Generators) - same pattern as Rails::Server/Rails::Console detection.
      # Rails only loads the Generators module during `rails generate` commands.

      it "uses defined?(Rails::Generators) for detection" do
        result = described_class.running_generator?
        expected = defined?(Rails::Generators)
        expect(result).to eq(expected)
      end
    end

    describe ".package_json_missing?" do
      let(:package_json_path) { "/fake/path/package.json" }

      before do
        allow(VersionChecker::NodePackageVersion).to receive(:package_json_path)
          .and_return(package_json_path)
      end

      context "when package.json exists" do
        before do
          allow(File).to receive(:exist?).with(package_json_path).and_return(true)
        end

        it "returns false" do
          expect(described_class.package_json_missing?).to be false
        end
      end

      context "when package.json doesn't exist" do
        before do
          allow(File).to receive(:exist?).with(package_json_path).and_return(false)
        end

        it "returns true" do
          expect(described_class.package_json_missing?).to be true
        end
      end
    end

    describe ".shakapacker_configured_as_bundler?" do
      let(:app_root) { Pathname.new(Dir.mktmpdir("react-on-rails-root")) }

      before do
        allow(Rails).to receive(:root).and_return(app_root)
      end

      after do
        FileUtils.remove_entry(app_root)
      end

      context "when config/shakapacker.yml exists" do
        it "returns true" do
          FileUtils.mkdir_p(app_root.join("config"))
          File.write(app_root.join("config", "shakapacker.yml"), "default: {}\n")

          expect(described_class.shakapacker_configured_as_bundler?).to be true
        end
      end

      context "when config/shakapacker.yml does not exist" do
        it "returns false" do
          expect(described_class.shakapacker_configured_as_bundler?).to be false
        end
      end

      it "does not call Shakapacker.config while checking for the config file" do
        expect(::Shakapacker).not_to receive(:config)
        expect(described_class.shakapacker_configured_as_bundler?).to be false
      end

      context "when Shakapacker is not defined" do
        before { hide_const("Shakapacker") }

        it "returns false when config/shakapacker.yml is absent" do
          expect(described_class.shakapacker_configured_as_bundler?).to be false
        end
      end
    end

    describe ".suppress_shakapacker_package_manager_check_if_not_bundler!" do
      # Skip these examples if ::Shakapacker::Utils::Manager isn't currently defined.
      # Other specs in the suite stub_const("Shakapacker", ...) with a bare module that
      # lacks the Utils namespace; in normal flow RSpec restores the constant after each
      # example, so this branch is only hit when something has leaked.
      before do
        skip "Shakapacker::Utils::Manager is unavailable in this scope" unless defined?(::Shakapacker::Utils::Manager)
        allow(Rails.logger).to receive(:info)
      end

      # Snapshot and restore the singleton method so the patch never leaks between examples,
      # regardless of suite ordering or whether earlier tests already replaced it.
      around do |example|
        singleton = nil
        snapshot = nil
        if defined?(::Shakapacker::Utils::Manager)
          singleton = ::Shakapacker::Utils::Manager.singleton_class
          had_override = singleton_defines_package_manager_check?(singleton)
          snapshot = ::Shakapacker::Utils::Manager.method(:error_unless_package_manager_is_obvious!) if had_override
        end
        example.run
      ensure
        if singleton
          if singleton_defines_package_manager_check?(singleton)
            singleton.send(:remove_method, :error_unless_package_manager_is_obvious!)
          end
          if snapshot
            ::Shakapacker::Utils::Manager.define_singleton_method(:error_unless_package_manager_is_obvious!,
                                                                  snapshot)
          end
        end
      end

      def singleton_defines_package_manager_check?(singleton)
        singleton.instance_methods(false).include?(:error_unless_package_manager_is_obvious!) ||
          singleton.private_instance_methods(false).include?(:error_unless_package_manager_is_obvious!)
      end

      context "when Shakapacker is the configured bundler" do
        before do
          allow(described_class).to receive(:shakapacker_configured_as_bundler?).and_return(true)
        end

        it "does not change Shakapacker::Utils::Manager.error_unless_package_manager_is_obvious!" do
          method_name = :error_unless_package_manager_is_obvious!
          before_location = ::Shakapacker::Utils::Manager.method(method_name).source_location
          described_class.suppress_shakapacker_package_manager_check_if_not_bundler!
          after_location = ::Shakapacker::Utils::Manager.method(method_name).source_location
          expect(after_location).to eq before_location
        end
      end

      context "when Shakapacker is not the configured bundler" do
        before do
          allow(described_class).to receive(:shakapacker_configured_as_bundler?).and_return(false)
        end

        it "skips the original guard while Shakapacker remains unconfigured" do
          ::Shakapacker::Utils::Manager.define_singleton_method(:error_unless_package_manager_is_obvious!) do
            raise "original guard"
          end

          described_class.suppress_shakapacker_package_manager_check_if_not_bundler!

          expect { ::Shakapacker::Utils::Manager.error_unless_package_manager_is_obvious! }.not_to raise_error
        end

        it "replaces the method with one defined in engine.rb" do
          described_class.suppress_shakapacker_package_manager_check_if_not_bundler!
          source_path, = ::Shakapacker::Utils::Manager.method(:error_unless_package_manager_is_obvious!).source_location
          expect(source_path).to end_with("/lib/react_on_rails/engine.rb")
        end

        it "logs an informational message" do
          described_class.suppress_shakapacker_package_manager_check_if_not_bundler!
          expect(Rails.logger).to have_received(:info)
            .with(a_string_including("skipping Shakapacker packageManager check"))
        end

        it "does not require a Rails logger" do
          allow(Rails).to receive(:logger).and_return(nil)

          expect { described_class.suppress_shakapacker_package_manager_check_if_not_bundler! }.not_to raise_error
        end
      end

      context "when Shakapacker becomes configured after the patch is installed" do
        before do
          allow(described_class).to receive(:shakapacker_configured_as_bundler?).and_return(false, true)
        end

        it "delegates back to Shakapacker's original package-manager guard" do
          ::Shakapacker::Utils::Manager.define_singleton_method(:error_unless_package_manager_is_obvious!) do
            raise "original guard"
          end

          described_class.suppress_shakapacker_package_manager_check_if_not_bundler!

          expect { ::Shakapacker::Utils::Manager.error_unless_package_manager_is_obvious! }
            .to raise_error(RuntimeError, "original guard")
        end
      end
    end

    describe ".suppress_shakapacker_package_manager_check_if_not_bundler! with missing Shakapacker internals" do
      before do
        stub_const("Shakapacker", Module.new)
        allow(described_class).to receive(:shakapacker_configured_as_bundler?).and_return(false)
        allow(Rails.logger).to receive(:warn)
      end

      it "logs a diagnostic warning" do
        described_class.suppress_shakapacker_package_manager_check_if_not_bundler!

        expect(Rails.logger).to have_received(:warn)
          .with(a_string_including("Shakapacker::Utils::Manager is not defined"))
      end
    end

    describe "Shakapacker package-manager suppression initializer" do
      subject(:initializer) do
        described_class.initializers.find { |i| i.name == "react_on_rails.suppress_shakapacker_package_manager_check" }
      end

      it "is registered" do
        expect(initializer).not_to be_nil
      end

      it "runs before shakapacker.manager_checker" do
        expect(initializer.before).to eq "shakapacker.manager_checker"
      end

      it "delegates to suppress_shakapacker_package_manager_check_if_not_bundler!" do
        expect(described_class).to receive(:suppress_shakapacker_package_manager_check_if_not_bundler!)
        initializer.run
      end
    end

    describe "booting Rails without config/shakapacker.yml" do
      let(:lib_path) { File.expand_path("../../lib", __dir__) }
      let(:npm_version) { ReactOnRails::VersionSyntaxConverter.new.rubygem_to_npm(ReactOnRails::VERSION) }
      let(:boot_script) do
        <<~RUBY
          require "logger"
          require "pathname"

          lib_path = ARGV.fetch(0)
          app_root = Pathname.new(ARGV.fetch(1))
          $LOAD_PATH.unshift(lib_path)

          require "rails"
          require "action_controller/railtie"
          require "react_on_rails"

          module ViteOnlyBootApp
          end

          ViteOnlyBootApp.const_set(
            :Application,
            Class.new(Rails::Application) do
              config.root = app_root
              config.eager_load = false
              config.secret_key_base = "test-secret"
              config.logger = Logger.new($stdout)
              config.load_defaults Rails::VERSION::STRING.to_f
            end
          )

          ViteOnlyBootApp::Application.initialize!
          puts "booted"
        RUBY
      end

      def write_vite_only_package_files(app_root, npm_version)
        FileUtils.mkdir_p(File.join(app_root, "config"))
        File.write(
          File.join(app_root, "package.json"),
          JSON.pretty_generate(
            "private" => true,
            "dependencies" => {
              "react-on-rails" => npm_version
            }
          )
        )
        File.write(
          File.join(app_root, "pnpm-lock.yaml"),
          <<~YAML
            lockfileVersion: '9.0'
            packages: {}
          YAML
        )
      end

      it "boots a Vite/client-only style app without Shakapacker package-manager guard failure" do
        Dir.mktmpdir("react-on-rails-vite-only") do |app_root|
          write_vite_only_package_files(app_root, npm_version)

          stdout, stderr, status = Open3.capture3(
            {
              "APP_ROOT" => app_root,
              "RAILS_ENV" => "test",
              "REACT_ON_RAILS_SKIP_VALIDATION" => nil
            },
            RbConfig.ruby,
            "-e",
            boot_script,
            lib_path,
            app_root
          )

          expect(status).to be_success, <<~MSG
            Expected a Rails app with no config/shakapacker.yml, no packageManager field,
            and a pnpm lockfile to boot after requiring react_on_rails.

            stdout:
            #{stdout}

            stderr:
            #{stderr}
          MSG
          expect(stdout).to include("booted")
        end
      end
    end

    describe "ScoutApm instrumentation initializer" do
      subject(:initializer) { described_class.initializers.find { |i| i.name.include?("scout_apm") } }

      it "defines a named Rails initializer to run after scout_apm.start" do
        expect(initializer.name).to eq "react_on_rails.scout_apm_instrumentation"
        expect(initializer.after).to eq "scout_apm.start"
      end

      describe "react_on_rails.scout_apm_instrumentation" do
        let(:mock_scout_tracer) do
          #
          # Simplified mock of ScoutApm::Tracer that mirrors its real implementation.
          # https://github.com/scoutapp/scout_apm_ruby/blob/v6.1.0/lib/scout_apm/tracer.rb#L47-L70
          #
          Module.new do
            def self.included(base)
              base.define_singleton_method(:instrument_method) do |method_name, **|
                raise "method does not exist: #{method_name}" unless method_defined?(method_name)

                instrumented_name = :"#{method_name}_with_test_instrument"
                uninstrumented_name = :"#{method_name}_without_test_instrument"

                define_method(instrumented_name) do |*args, **kwargs, &block|
                  send(uninstrumented_name, *args, **kwargs, &block)
                end

                alias_method uninstrumented_name, method_name
                alias_method method_name, instrumented_name
              end
            end
          end
        end

        let(:mock_helper) { Module.new.include(ReactOnRails::Helper) }
        let(:mock_rb_embedded_js) { Class.new(ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript) }

        before do
          stub_const("ReactOnRails::Helper", mock_helper)
          stub_const("ReactOnRails::ServerRenderingPool::RubyEmbeddedJavaScript", mock_rb_embedded_js)
        end

        context "when ScoutApm is not defined" do
          before { hide_const("ScoutApm") }

          it "does not instrument Helper#react_component" do
            initializer.run
            expect(mock_helper.instance_methods(false)).not_to include(:react_component_with_test_instrument)
            expect(mock_helper.instance_methods(false)).not_to include(:react_component_without_test_instrument)
          end

          it "does not instrument Helper#react_component_hash" do
            initializer.run
            expect(mock_helper.instance_methods(false)).not_to include(:react_component_hash_with_test_instrument)
            expect(mock_helper.instance_methods(false)).not_to include(:react_component_hash_without_test_instrument)
          end

          it "does not instrument RubyEmbeddedJavaScript.exec_server_render_js" do
            initializer.run
            expect(mock_rb_embedded_js.methods(false)).not_to include(:exec_server_render_js_with_test_instrument)
            expect(mock_rb_embedded_js.methods(false)).not_to include(:exec_server_render_js_without_test_instrument)
          end
        end

        context "when ScoutApm is defined" do
          before { stub_const("ScoutApm::Tracer", mock_scout_tracer) }

          it "instruments Helper#react_component" do
            initializer.run
            expect(mock_helper.instance_methods(false)).to include(:react_component_with_test_instrument)
            expect(mock_helper.instance_methods(false)).to include(:react_component_without_test_instrument)
          end

          it "instruments Helper#react_component_hash" do
            initializer.run
            expect(mock_helper.instance_methods(false)).to include(:react_component_hash_with_test_instrument)
            expect(mock_helper.instance_methods(false)).to include(:react_component_hash_without_test_instrument)
          end

          it "instruments RubyEmbeddedJavaScript.exec_server_render_js" do
            initializer.run
            expect(mock_rb_embedded_js.methods(false)).to include(:exec_server_render_js_with_test_instrument)
            expect(mock_rb_embedded_js.methods(false)).to include(:exec_server_render_js_without_test_instrument)
          end
        end
      end
    end

    describe "automatic rake task loading" do
      # Rails::Engine automatically loads all .rake files from lib/tasks/
      # This test verifies that our rake tasks are loaded without needing
      # an explicit rake_tasks block in engine.rb (which would cause duplicate loading)
      #
      # Historical context: PR #1770 added explicit loading via rake_tasks block,
      # causing tasks to run twice. Fixed in PR #2052 by relying on automatic loading.

      it "verifies engine.rb does not have a rake_tasks block" do
        # Read the engine.rb file
        engine_file = File.read(File.expand_path("../../lib/react_on_rails/engine.rb", __dir__))

        # Check that there's no rake_tasks block
        expect(engine_file).not_to match(/rake_tasks\s+do/),
                                   "Found rake_tasks block in engine.rb. This is unnecessary because " \
                                   "Rails::Engine automatically loads all .rake files from lib/tasks/. Having an " \
                                   "explicit rake_tasks block causes duplicate task execution (tasks run twice " \
                                   "during operations like rake assets:precompile). Remove the rake_tasks block " \
                                   "and rely on automatic loading."
      end

      it "verifies all task files exist in lib/tasks/" do
        # Verify that task files exist in the standard location
        expected_task_files = %w[
          assets.rake
          generate_packs.rake
          locale.rake
          doctor.rake
        ]

        lib_tasks_dir = File.expand_path("../../lib/tasks", __dir__)

        expected_task_files.each do |task_file|
          full_path = File.join(lib_tasks_dir, task_file)
          expect(File.exist?(full_path)).to be(true),
                                            "Expected rake task file '#{task_file}' to exist in lib/tasks/, " \
                                            "but it was not found at #{full_path}. Rails::Engine automatically loads " \
                                            "all .rake files from lib/tasks/ without needing explicit loading."
        end
      end
    end
  end
end

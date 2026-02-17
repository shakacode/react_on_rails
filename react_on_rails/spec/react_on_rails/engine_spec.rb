# frozen_string_literal: true

require_relative "spec_helper"

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
      # See analysis/rake-task-duplicate-analysis.md for full details.

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

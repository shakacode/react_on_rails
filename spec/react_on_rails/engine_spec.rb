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
          context "when package.json exists and ARGV indicates generator" do
            before do
              allow(File).to receive(:exist?).with(package_json_path).and_return(true)
              stub_const("ARGV", ["generate", "react_on_rails:install"])
            end

            it "prioritizes ENV over ARGV check" do
              expect(described_class.skip_version_validation?).to be true
            end

            it "short-circuits before checking ARGV" do
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
            stub_const("ARGV", ["generate", "react_on_rails:install"])
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

        context "when running a generator with short form" do
          before do
            stub_const("ARGV", ["g", "react_on_rails:install"])
          end

          it "returns true" do
            expect(described_class.skip_version_validation?).to be true
          end
        end

        context "when ARGV is empty" do
          before do
            stub_const("ARGV", [])
          end

          it "returns false" do
            expect(described_class.skip_version_validation?).to be false
          end
        end

        context "when running other commands" do
          %w[server console runner].each do |command|
            context "when running '#{command}'" do
              before do
                stub_const("ARGV", [command])
              end

              it "returns false" do
                expect(described_class.skip_version_validation?).to be false
              end
            end
          end
        end
      end
    end

    describe ".running_generator?" do
      context "when ARGV is empty" do
        before do
          stub_const("ARGV", [])
        end

        it "returns false" do
          expect(described_class.running_generator?).to be false
        end
      end

      context "when ARGV.first is 'generate'" do
        before do
          stub_const("ARGV", %w[generate model User])
        end

        it "returns true" do
          expect(described_class.running_generator?).to be true
        end
      end

      context "when ARGV.first is 'g'" do
        before do
          stub_const("ARGV", %w[g controller Users])
        end

        it "returns true" do
          expect(described_class.running_generator?).to be true
        end
      end

      context "when ARGV.first is another command" do
        before do
          stub_const("ARGV", ["server"])
        end

        it "returns false" do
          expect(described_class.running_generator?).to be false
        end
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

    describe "automatic rake task loading" do
      # Rails::Engine automatically loads all .rake files from lib/tasks/
      # This test verifies that our rake tasks are loaded without needing
      # an explicit rake_tasks block in engine.rb (which would cause duplicate loading)
      #
      # Historical context: PR #1770 added explicit loading via rake_tasks block,
      # causing tasks to run twice. Fixed in PR #2052 by relying on automatic loading.
      # See RAKE_TASK_DUPLICATE_ANALYSIS.md for full details.

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

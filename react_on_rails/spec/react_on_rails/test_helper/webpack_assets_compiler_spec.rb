# frozen_string_literal: true

require_relative "../spec_helper"

describe ReactOnRails::TestHelper::WebpackAssetsCompiler do
  describe "#compile_assets" do
    let(:invalid_command) { "false" }
    let(:valid_command) { "true" }

    context "when assets compiler command succeeds" do
      before do
        allow(ReactOnRails.configuration)
          .to receive(:build_test_command)
          .and_return(valid_command)
        allow(ReactOnRails::Utils).to receive(:invoke_and_exit_if_failed)
      end

      it "prints bundler-neutral build messages" do
        expect do
          described_class.new.compile_assets
        end.to output("\nBuilding assets...\nCompleted building assets.\n").to_stdout

        # Assert the compile step actually ran, so the example fails if it is skipped.
        expect(ReactOnRails::Utils).to have_received(:invoke_and_exit_if_failed)
      end
    end

    context "when assets compiler command is invalid" do
      before do
        allow(ReactOnRails.configuration)
          .to receive(:build_test_command)
          .and_return(invalid_command)

        # Mock this out or else it quits the test suite!
        allow(ReactOnRails::Utils).to receive(:exit!).and_raise(SystemExit)
      end

      it "exits immediately" do
        puts "\n\nBEGIN IGNORE PRINTS IN THIS TEST"
        expect do
          described_class.new.compile_assets
        end.to raise_error(SystemExit)
        puts "END IGNORE PRINTS IN THIS TEST\n\n"
      end

      it "prints the correct message" do
        escaped_root = Regexp.escape(Rails.root.to_s)
        escaped_cmd = Regexp.escape(invalid_command)
        expected_pattern = Regexp.new(
          "React on Rails FATAL ERROR!.*" \
          "React on Rails: Error building test assets!.*" \
          "cmd: cd \"#{escaped_root}\" && #{escaped_cmd}.*" \
          "exitstatus: 1",
          Regexp::MULTILINE
        )

        expect do
          described_class.new.compile_assets
        rescue SystemExit
          # No op
        end.to output(expected_pattern).to_stderr
      end

      it "suggests rerunning the configured build command" do
        expect do
          described_class.new.compile_assets
        rescue SystemExit
          # No op
        end.to output(include("Run '#{invalid_command}' manually to compile once")).to_stderr
      end

      it "does not name a specific bundler in the rerun suggestion" do
        expect do
          described_class.new.compile_assets
        rescue SystemExit
          # No op
        end.not_to output(include("bin/shakapacker")).to_stderr
      end
    end
  end
end

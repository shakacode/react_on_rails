# frozen_string_literal: true

require_relative "../spec_helper"

describe ReactOnRails::TestHelper::WebpackAssetsCompiler do
  describe "#ensureAssetsCompiled" do
    let(:invalid_command) { "sh -c 'exit 1'" }

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
          "React on Rails: Error building webpack assets!.*" \
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
    end
  end
end

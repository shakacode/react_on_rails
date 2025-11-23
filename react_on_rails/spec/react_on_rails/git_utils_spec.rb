# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRails
  RSpec.describe GitUtils do
    describe ".uncommitted_changes?" do
      context "with uncommitted git changes" do
        let(:message_handler) { instance_double("MessageHandler") } # rubocop:disable RSpec/VerifiedDoubleReference

        it "returns true" do
          allow(described_class).to receive(:`).with("git status --porcelain").and_return("M file/path")
          expect(message_handler).to receive(:add_error)
            .with(<<~MSG.strip)
              You have uncommitted changes. Please commit or stash them before continuing.

              The React on Rails generator creates many new files and it's important to keep
              your existing changes separate from the generated code for easier review.
            MSG

          expect(described_class.uncommitted_changes?(message_handler, git_installed: true)).to be(true)
        end
      end

      context "with clean git status" do
        let(:message_handler) { instance_double("MessageHandler") } # rubocop:disable RSpec/VerifiedDoubleReference

        it "returns false" do
          allow(described_class).to receive(:`).with("git status --porcelain").and_return("")
          expect(message_handler).not_to receive(:add_error)

          expect(described_class.uncommitted_changes?(message_handler, git_installed: true)).to be(false)
        end
      end

      context "with git not installed" do
        let(:message_handler) { instance_double("MessageHandler") } # rubocop:disable RSpec/VerifiedDoubleReference

        it "returns true" do
          allow(described_class).to receive(:`).with("git status --porcelain").and_return(nil)
          expect(message_handler).to receive(:add_error)
            .with(<<~MSG.strip)
              Git is not installed. Please install Git and commit your changes before continuing.

              The React on Rails generator creates many new files and version control helps
              track what was generated versus your existing code.
            MSG

          expect(described_class.uncommitted_changes?(message_handler, git_installed: false)).to be(true)
        end
      end
    end
  end
end

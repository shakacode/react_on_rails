# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRails
  RSpec.describe GitUtils do
    describe ".uncommitted_changes?" do
      context "with uncommited git changes" do
        let(:message_handler) { instance_double("MessageHandler") }

        it "returns true" do
          allow(described_class).to receive(:`).with("git status --porcelain").and_return("M file/path")
          allow_any_instance_of(Process::Status).to receive(:success?).and_return(true)
          expect(message_handler).to receive(:add_error)
            .with("You have uncommitted code. Please commit or stash your changes before continuing")

          expect(described_class.uncommitted_changes?(message_handler)).to eq(true)
        end
      end

      context "with clean git status" do
        let(:message_handler) { instance_double("MessageHandler") }

        it "returns false" do
          allow(described_class).to receive(:`).with("git status --porcelain").and_return("")
          allow_any_instance_of(Process::Status).to receive(:success?).and_return(true)
          expect(message_handler).not_to receive(:add_error)

          expect(described_class.uncommitted_changes?(message_handler)).to eq(false)
        end
      end

      context "with git not installed" do
        let(:message_handler) { instance_double("MessageHandler") }

        it "returns true" do
          allow(described_class).to receive(:`).with("git status --porcelain").and_return(nil)
          allow_any_instance_of(Process::Status).to receive(:success?).and_return(false)
          expect(message_handler).to receive(:add_error)
            .with("You do not have Git installed. Please install Git, and commit your changes before continuing")

          expect(described_class.uncommitted_changes?(message_handler)).to eq(true)
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRails
  RSpec.describe GitUtils do
    describe ".uncommitted_changes?" do
      context "With uncommited git changes" do
        subject { "M file/path" }
        let(:message_handler) { instance_double("MessageHandler") }

        before do
          allow(described_class).to receive(:`).with("git status --porcelain").and_return(subject)
          allow_any_instance_of(Process::Status).to receive(:success?).and_return(true)
          expect(message_handler).to receive(:add_error)
            .with("You have uncommitted code. Please commit or stash your changes before continuing")
        end

        it "returns true" do
          expect(described_class.uncommitted_changes?(message_handler)).to eq(true)
        end
      end

      context "With clean git status" do
        subject { "" }
        let(:message_handler) { instance_double("MessageHandler") }

        before do
          allow(described_class).to receive(:`).with("git status --porcelain").and_return(subject)
          allow_any_instance_of(Process::Status).to receive(:success?).and_return(true)
          expect(message_handler).not_to receive(:add_error)
        end

        it "returns false" do
          expect(described_class.uncommitted_changes?(message_handler)).to eq(false)
        end
      end

      context "With git not installed" do
        subject { nil }
        let(:message_handler) { instance_double("MessageHandler") }

        before do
          allow(described_class).to receive(:`).with("git status --porcelain").and_return(subject)
          allow_any_instance_of(Process::Status).to receive(:success?).and_return(false)
          expect(message_handler).to receive(:add_error)
            .with("You do not have Git installed. Please install Git, and commit your changes before continuing")
        end

        it "returns true" do
          expect(described_class.uncommitted_changes?(message_handler)).to eq(true)
        end
      end
    end
  end
end

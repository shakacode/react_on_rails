# frozen_string_literal: true

require_relative "spec_helper"
require "open3"

module ReactOnRails
  RSpec.describe GitUtils do
    describe ".uncommitted_changes?" do
      context "with uncommitted git changes" do
        let(:message_handler) { instance_double("MessageHandler") } # rubocop:disable RSpec/VerifiedDoubleReference

        around do |example|
          original_ci = ENV.fetch("CI", nil)
          ENV.delete("CI")
          example.run
          ENV["CI"] = original_ci if original_ci
        end

        it "returns true" do
          allow(Open3).to receive(:capture2e)
            .with("git", "status", "--porcelain")
            .and_return([
                          "M file/path",
                          instance_double(Process::Status, success?: true, exitstatus: 0)
                        ])
          expect(message_handler).to receive(:add_error)
            .with(<<~MSG.strip)
              You have uncommitted changes. Please commit or stash them before continuing.

              The React on Rails generator creates many new files and it's important to keep
              your existing changes separate from the generated code for easier review.
            MSG

          expect(described_class.uncommitted_changes?(message_handler, git_installed: true)).to be(true)
        end
      end

      context "when CI environment variable is set" do
        let(:message_handler) { instance_double("MessageHandler") } # rubocop:disable RSpec/VerifiedDoubleReference

        around do |example|
          original_ci = ENV.fetch("CI", nil)
          ENV["CI"] = "1"
          example.run
          ENV["CI"] = original_ci
          ENV.delete("CI") unless original_ci
        end

        it "returns false without checking git status" do
          expect(Open3).not_to receive(:capture2e)
          expect(message_handler).not_to receive(:add_error)

          expect(described_class.uncommitted_changes?(message_handler, git_installed: true)).to be(false)
        end
      end

      context "with clean git status" do
        let(:message_handler) { instance_double("MessageHandler") } # rubocop:disable RSpec/VerifiedDoubleReference

        around do |example|
          original_ci = ENV.fetch("CI", nil)
          ENV.delete("CI")
          example.run
          ENV["CI"] = original_ci if original_ci
        end

        it "returns false" do
          allow(Open3).to receive(:capture2e)
            .with("git", "status", "--porcelain")
            .and_return([
                          "",
                          instance_double(Process::Status, success?: true, exitstatus: 0)
                        ])
          expect(message_handler).not_to receive(:add_error)

          expect(described_class.uncommitted_changes?(message_handler, git_installed: true)).to be(false)
        end
      end

      context "with git not installed" do
        let(:message_handler) { instance_double("MessageHandler") } # rubocop:disable RSpec/VerifiedDoubleReference

        around do |example|
          original_ci = ENV.fetch("CI", nil)
          ENV.delete("CI")
          example.run
          ENV["CI"] = original_ci if original_ci
        end

        it "returns true without calling git" do
          expect(Open3).not_to receive(:capture2e)
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

    describe ".warn_if_uncommitted_changes" do
      context "with uncommitted git changes" do
        let(:message_handler) { instance_double("MessageHandler") } # rubocop:disable RSpec/VerifiedDoubleReference

        around do |example|
          original_ci = ENV.fetch("CI", nil)
          ENV.delete("CI")
          example.run
          ENV["CI"] = original_ci if original_ci
        end

        it "adds a warning and returns true" do
          allow(Open3).to receive(:capture2e)
            .with("git", "status", "--porcelain")
            .and_return([
                          "M file/path",
                          instance_double(Process::Status, success?: true, exitstatus: 0)
                        ])
          expect(message_handler).to receive(:add_warning).with(described_class::DIRTY_WORKTREE_WARNING)

          expect(described_class.warn_if_uncommitted_changes(message_handler, git_installed: true)).to be(true)
        end
      end

      context "when CI environment variable is set" do
        let(:message_handler) { instance_double("MessageHandler") } # rubocop:disable RSpec/VerifiedDoubleReference

        around do |example|
          original_ci = ENV.fetch("CI", nil)
          ENV["CI"] = "yes"
          example.run
          ENV["CI"] = original_ci
          ENV.delete("CI") unless original_ci
        end

        it "returns false without checking git status" do
          expect(Open3).not_to receive(:capture2e)
          expect(message_handler).not_to receive(:add_warning)

          expect(described_class.warn_if_uncommitted_changes(message_handler, git_installed: true)).to be(false)
        end
      end

      context "with clean git status" do
        let(:message_handler) { instance_double("MessageHandler") } # rubocop:disable RSpec/VerifiedDoubleReference

        around do |example|
          original_ci = ENV.fetch("CI", nil)
          ENV.delete("CI")
          example.run
          ENV["CI"] = original_ci if original_ci
        end

        it "returns false" do
          allow(Open3).to receive(:capture2e)
            .with("git", "status", "--porcelain")
            .and_return([
                          "",
                          instance_double(Process::Status, success?: true, exitstatus: 0)
                        ])
          expect(message_handler).not_to receive(:add_warning)

          expect(described_class.warn_if_uncommitted_changes(message_handler, git_installed: true)).to be(false)
        end
      end

      context "with git not installed" do
        let(:message_handler) { instance_double("MessageHandler") } # rubocop:disable RSpec/VerifiedDoubleReference

        around do |example|
          original_ci = ENV.fetch("CI", nil)
          ENV.delete("CI")
          example.run
          ENV["CI"] = original_ci if original_ci
        end

        it "adds a warning and returns true without calling git" do
          expect(Open3).not_to receive(:capture2e)
          expect(message_handler).to receive(:add_warning).with(described_class::MISSING_GIT_WARNING)

          expect(described_class.warn_if_uncommitted_changes(message_handler, git_installed: false)).to be(true)
        end
      end

      context "when git status reports a non-git directory" do
        let(:message_handler) { instance_double("MessageHandler") } # rubocop:disable RSpec/VerifiedDoubleReference

        around do |example|
          original_ci = ENV.fetch("CI", nil)
          ENV.delete("CI")
          example.run
          ENV["CI"] = original_ci if original_ci
        end

        it "uses a not-a-repository warning" do
          allow(Open3).to receive(:capture2e)
            .with("git", "status", "--porcelain")
            .and_return([
                          "fatal: not a git repository",
                          instance_double(Process::Status, success?: false, exitstatus: 128)
                        ])
          expect(message_handler).to receive(:add_warning).with(described_class::NOT_A_GIT_REPOSITORY_WARNING)

          expect(described_class.warn_if_uncommitted_changes(message_handler, git_installed: true)).to be(true)
        end
      end
    end
  end
end

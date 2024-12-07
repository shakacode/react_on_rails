# frozen_string_literal: true

require_relative "spec_helper"
require_relative "support/version_test_helpers"

class FakeLogger
  attr_accessor :message

  def error(message)
    self.message = message
  end
end

module ReactOnRails # rubocop:disable Metrics/ModuleLength
  describe VersionChecker do
    describe "#warn_if_gem_and_node_package_versions_differ" do
      let(:logger) { FakeLogger.new }

      context "when gem and node package major and minor versions are equal" do
        let(:node_package_version) do
          double_package_version(raw: "2.2.5-beta.2", major_minor_patch: %w[2 2 5])
        end

        before { stub_gem_version("2.2.5.beta.2") }

        it "does not log" do
          allow(Rails.logger).to receive(:warn)
          check_version_and_log(node_package_version)
          expect(Rails.logger).not_to have_received(:warn)
        end
      end

      context "when major and minor versions are equal BUT node uses semver wildcard" do
        let(:node_package_version) do
          double_package_version(raw: "^2.2.5", semver_wildcard: true, major_minor_patch: %w[2 2 5])
        end

        before { stub_gem_version("2.2.5") }

        it "logs" do
          allow(Rails.logger).to receive(:warn)
          message = /ReactOnRails: Your node package version for react-on-rails contains a \^ or ~/
          check_version_and_log(node_package_version)
          expect(Rails.logger).to have_received(:warn).with(message)
        end
      end

      context "when gem and node package major versions differ" do
        let(:node_package_version) do
          double_package_version(raw: "13.0.0.beta-2", major_minor_patch: %w[13 0 0])
        end

        before { stub_gem_version("12.0.0.beta.1") }

        it "logs" do
          allow(Rails.logger).to receive(:warn)
          message = /ReactOnRails: ReactOnRails gem and node package versions do not match/
          check_version_and_log(node_package_version)
          expect(Rails.logger).to have_received(:warn).with(message)
        end
      end

      context "when gem and node package major versions match and minor differs" do
        let(:node_package_version) do
          double_package_version(raw: "13.0.0.beta-2", major_minor_patch: %w[13 0 0])
        end

        before { stub_gem_version("13.1.0") }

        it "logs" do
          allow(Rails.logger).to receive(:warn)
          message = /ReactOnRails: ReactOnRails gem and node package versions do not match/
          check_version_and_log(node_package_version)
          expect(Rails.logger).to have_received(:warn).with(message)
        end
      end

      context "when gem and node package major, minor versions match and patch differs" do
        let(:node_package_version) do
          double_package_version(raw: "13.0.1", major_minor_patch: %w[13 0 1])
        end

        before { stub_gem_version("13.0.0") }

        it "logs" do
          allow(Rails.logger).to receive(:warn)
          message = /ReactOnRails: ReactOnRails gem and node package versions do not match/
          check_version_and_log(node_package_version)
          expect(Rails.logger).to have_received(:warn).with(message)
        end
      end

      context "when package json uses a relative path with dots" do
        let(:node_package_version) do
          double_package_version(raw: "../../..", major_minor_patch: "", relative_path: true)
        end

        before { stub_gem_version("2.0.0.beta.1") }

        it "does not log" do
          allow(Rails.logger).to receive(:warn)
          check_version_and_log(node_package_version)
          expect(Rails.logger).not_to have_received(:warn)
        end
      end

      context "when package json doesn't exist" do
        let(:node_package_version) do
          double_package_version(raw: nil)
        end

        it "log method returns nil" do
          expect(check_version_and_log(node_package_version)).to be_nil
        end
      end
    end

    def double_package_version(raw: nil, semver_wildcard: false,
                               major_minor_patch: nil, relative_path: false)
      instance_double(VersionChecker::NodePackageVersion,
                      raw: raw,
                      semver_wildcard?: semver_wildcard,
                      major_minor_patch: major_minor_patch,
                      relative_path?: relative_path)
    end

    def check_version_and_raise(node_package_version)
      version_checker = VersionChecker.new(node_package_version)
      version_checker.raise_if_gem_and_node_package_versions_differ
    end

    def check_version_and_log(node_package_version)
      version_checker = VersionChecker.new(node_package_version)
      version_checker.log_if_gem_and_node_package_versions_differ
    end

    describe VersionChecker::NodePackageVersion do
      subject(:node_package_version) { described_class.new(package_json) }

      describe "#build" do
        it "initializes NodePackageVersion with ReactOnRails.configuration.node_modules_location" do
          allow(ReactOnRails).to receive_message_chain(:configuration, :node_modules_location).and_return("spec/dummy")
          root_package_json_path = File.expand_path("../../package.json", __dir__)
          allow(Rails).to receive_message_chain(:root, :join).and_return(root_package_json_path)
          message = "No 'react-on-rails' entry in the dependencies of #{root_package_json_path}, which is " \
                    "the expected location according to ReactOnRails.configuration.node_modules_location"
          allow(Rails.logger).to receive(:warn)
          described_class.build.raw
          expect(Rails.logger).to have_received(:warn).with(message)
        end
      end

      describe "#semver_wildcard?" do
        context "when package json lists an exact version of '0.0.2'" do
          let(:package_json) { File.expand_path("fixtures/normal_package.json", __dir__) }

          specify { expect(node_package_version.semver_wildcard?).to be false }
        end

        context "when package json lists a semver caret version of '^1.2.3'" do
          let(:package_json) { File.expand_path("fixtures/semver_caret_package.json", __dir__) }

          specify { expect(node_package_version.semver_wildcard?).to be true }
        end

        context "when package json lists a semver tilde version of '~1.2.3'" do
          let(:package_json) { File.expand_path("fixtures/semver_tilde_package.json", __dir__) }

          specify { expect(node_package_version.semver_wildcard?).to be true }
        end
      end

      context "when package json lists a version of '0.0.2'" do
        let(:package_json) { File.expand_path("fixtures/normal_package.json", __dir__) }

        describe "#raw" do
          specify { expect(node_package_version.raw).to eq("0.0.2") }
        end

        describe "#relative_path?" do
          specify { expect(node_package_version.relative_path?).to be false }
        end

        describe "#major" do
          specify { expect(node_package_version.major_minor_patch).to eq(%w[0 0 2]) }
        end
      end

      context "when package json lists a version of '^14.0.0.beta-2'" do
        let(:package_json) { File.expand_path("fixtures/beta_package.json", __dir__) }

        describe "#raw" do
          specify { expect(node_package_version.raw).to eq("^14.0.0.beta-2") }
        end

        describe "#relative_path?" do
          specify { expect(node_package_version.relative_path?).to be false }
        end

        describe "#major_minor_patch" do
          specify { expect(node_package_version.major_minor_patch).to eq(%w[14 0 0]) }
        end
      end

      context "with node version of '../../..'" do
        let(:package_json) { File.expand_path("fixtures/relative_path_package.json", __dir__) }

        describe "#raw" do
          specify { expect(node_package_version.raw).to eq("../../..") }
        end

        describe "#relative_path?" do
          specify { expect(node_package_version.relative_path?).to be true }
        end

        describe "#major" do
          specify { expect(node_package_version.major_minor_patch).to be_nil }
        end
      end

      context "with node version of 'file:///Users/justin/shakacode/react_on_rails'" do
        let(:package_json) { File.expand_path("fixtures/absolute_path_package.json", __dir__) }

        describe "#raw" do
          specify { expect(node_package_version.raw).to eq("file:///Users/justin/shakacode/react_on_rails") }
        end

        describe "#relative_path?" do
          specify { expect(node_package_version.relative_path?).to be true }
        end

        describe "#major" do
          specify { expect(node_package_version.major_minor_patch).to be_nil }
        end
      end

      context "with node version of 'file:.yalc/react-on-rails'" do
        let(:package_json) { File.expand_path("fixtures/yalc_package.json", __dir__) }

        describe "#raw" do
          specify { expect(node_package_version.raw).to eq("file:.yalc/react-on-rails") }
        end

        describe "#relative_path?" do
          specify { expect(node_package_version.relative_path?).to be true }
        end

        describe "#major" do
          specify { expect(node_package_version.major_minor_patch).to be_nil }
        end
      end

      context "with package.json without react-on-rails dependency" do
        let(:package_json) { File.expand_path("../../package.json", __dir__) }

        describe "#raw" do
          it "returns nil" do
            root_package_json_path = File.expand_path("fixtures/nonexistent_package.json", __dir__)
            allow(Rails).to receive_message_chain(:root, :join).and_return(root_package_json_path)
            expect(node_package_version.raw).to be_nil
          end
        end
      end

      context "with non-existing package.json" do
        let(:package_json) { File.expand_path("fixtures/nonexistent_package.json", __dir__) }

        describe "#raw" do
          it "returns nil" do
            root_package_json_path = File.expand_path("fixtures/nonexistent_package.json", __dir__)
            allow(Rails).to receive_message_chain(:root, :join).and_return(root_package_json_path)
            expect(node_package_version.raw).to be_nil
          end
        end
      end
    end
  end
end

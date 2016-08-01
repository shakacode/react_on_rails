require_relative "spec_helper"
require_relative "support/version_test_helpers"

class FakeLogger
  attr_accessor :message

  def warn(message)
    self.message = message
  end
end

module ReactOnRails
  describe VersionChecker do
    describe "#warn_if_gem_and_node_package_versions_differ" do
      let(:logger) { FakeLogger.new }

      context "when gem and node package major versions are equal" do
        let(:node_package_version) { double_package_version(raw: "^2.2.5", major: "2") }
        before { stub_gem_version("2.0.0.beta.2") }

        it "does not log a warning" do
          check_version(node_package_version, logger)
          expect(logger.message).to be_nil
        end
      end

      context "when gem and node package major versions differ" do
        let(:node_package_version) do
          double_package_version(raw: "13.0.0.beta-2", major: "13")
        end
        before { stub_gem_version("12.0.0.beta.1") }

        it "logs a warning" do
          check_version(node_package_version, logger)
          expect(logger.message).to be_present
        end
      end

      context "when package json uses a relative path with dots" do
        let(:node_package_version) do
          double_package_version(raw: "../../..", major: "", relative_path: true)
        end
        before { stub_gem_version("2.0.0.beta.1") }

        it "does not log a warning" do
          check_version(node_package_version, logger)
          expect(logger.message).to be_nil
        end
      end

      context "when package json uses a one-digit version string" do
        let(:node_package_version) do
          double_package_version(raw: "^6", major: "6")
        end

        it "does not log a warning" do
          stub_gem_version("6")
          check_version(node_package_version, logger)
          expect(logger.message).to be_nil
        end

        it "logs a warning" do
          stub_gem_version("5")
          check_version(node_package_version, logger)
          expect(logger.message).to be_present
        end
      end
    end

    def double_package_version(raw: nil, major: nil, relative_path: false)
      instance_double(VersionChecker::NodePackageVersion,
                      raw: raw,
                      major: major,
                      relative_path?: relative_path)
    end

    def check_version(node_package_version, logger)
      version_checker = VersionChecker.new(node_package_version, logger)
      version_checker.warn_if_gem_and_node_package_versions_differ
    end

    describe VersionChecker::NodePackageVersion do
      subject(:node_package_version) { VersionChecker::NodePackageVersion.new(package_json) }

      context "when package json lists a version of '0.0.2'" do
        let(:package_json) { File.expand_path("../fixtures/normal_package.json", __FILE__) }

        describe "#raw" do
          specify { expect(node_package_version.raw).to eq("0.0.2") }
        end

        describe "#relative_path?" do
          specify { expect(node_package_version.relative_path?).to be false }
        end

        describe "#major" do
          specify { expect(node_package_version.major).to eq("0") }
        end
      end

      context "when package json lists a version of '^14.0.0.beta-2'" do
        let(:package_json) { File.expand_path("../fixtures/beta_package.json", __FILE__) }

        describe "#raw" do
          specify { expect(node_package_version.raw).to eq("^14.0.0.beta-2") }
        end

        describe "#relative_path?" do
          specify { expect(node_package_version.relative_path?).to be false }
        end

        describe "#major" do
          specify { expect(node_package_version.major).to eq("14") }
        end
      end

      context "with node version of '../../..'" do
        let(:package_json) { File.expand_path("../fixtures/relative_path_package.json", __FILE__) }

        describe "#raw" do
          specify { expect(node_package_version.raw).to eq("../../..") }
        end

        describe "#relative_path?" do
          specify { expect(node_package_version.relative_path?).to be true }
        end

        describe "#major" do
          specify { expect(node_package_version.major).to be_nil }
        end
      end

      context "with node version of 'file:///Users/justin/shakacode/react_on_rails'" do
        let(:package_json) { File.expand_path("../fixtures/absolute_path_package.json", __FILE__) }

        describe "#raw" do
          specify { expect(node_package_version.raw).to eq("file:///Users/justin/shakacode/react_on_rails") }
        end

        describe "#relative_path?" do
          specify { expect(node_package_version.relative_path?).to be true }
        end

        describe "#major" do
          specify { expect(node_package_version.major).to be_nil }
        end
      end
    end
  end
end

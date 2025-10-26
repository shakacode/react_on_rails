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
    describe "#validate_version_and_package_compatibility!" do
      let(:logger) { FakeLogger.new }

      before do
        # Stub ReactOnRails::Utils.react_on_rails_pro? to return false by default
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
      end

      context "when both react-on-rails and react-on-rails-pro packages are installed" do
        let(:node_package_version) do
          instance_double(VersionChecker::NodePackageVersion,
                          react_on_rails_package?: true,
                          react_on_rails_pro_package?: true,
                          raw: "16.1.1",
                          local_path_or_url?: false,
                          package_json: "/fake/path/package.json")
        end

        it "raises an error" do
          expect { check_version_and_raise(node_package_version) }
            .to raise_error(ReactOnRails::Error,
                            /Both 'react-on-rails' and 'react-on-rails-pro' packages are installed/)
        end
      end

      context "when Pro gem is installed but using base package" do
        let(:node_package_version) do
          instance_double(VersionChecker::NodePackageVersion,
                          react_on_rails_package?: true,
                          react_on_rails_pro_package?: false,
                          raw: "16.1.1",
                          local_path_or_url?: false,
                          semver_wildcard?: false,
                          parts: %w[16 1 1],
                          package_json: "/fake/path/package.json")
        end

        before do
          allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
          stub_gem_version("16.1.1")
        end

        it "raises an error" do
          expect { check_version_and_raise(node_package_version) }
            .to raise_error(ReactOnRails::Error,
                            /You have the Pro gem installed but are using the base 'react-on-rails' package/)
        end
      end

      context "when Pro package is installed but Pro gem is not" do
        let(:node_package_version) do
          instance_double(VersionChecker::NodePackageVersion,
                          react_on_rails_package?: false,
                          react_on_rails_pro_package?: true,
                          raw: "16.1.1",
                          local_path_or_url?: false,
                          semver_wildcard?: false,
                          parts: %w[16 1 1],
                          package_name: "react-on-rails-pro",
                          package_json: "/fake/path/package.json")
        end

        before do
          allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
          stub_gem_version("16.1.1")
        end

        it "raises an error" do
          expect { check_version_and_raise(node_package_version) }
            .to raise_error(ReactOnRails::Error,
                            /You have the 'react-on-rails-pro' package installed but the Pro gem is not installed/)
        end
      end

      context "when package version is not exact (has semver wildcard)" do
        let(:node_package_version) do
          instance_double(VersionChecker::NodePackageVersion,
                          react_on_rails_package?: true,
                          react_on_rails_pro_package?: false,
                          raw: "^16.1.1",
                          local_path_or_url?: false,
                          semver_wildcard?: true,
                          package_name: "react-on-rails",
                          package_json: "/fake/path/package.json")
        end

        before { stub_gem_version("16.1.1") }

        it "raises an error" do
          expect { check_version_and_raise(node_package_version) }
            .to raise_error(ReactOnRails::Error, /The 'react-on-rails' package version is not an exact version/)
        end
      end

      context "when package version does not match gem version" do
        let(:node_package_version) do
          instance_double(VersionChecker::NodePackageVersion,
                          react_on_rails_package?: true,
                          react_on_rails_pro_package?: false,
                          raw: "16.1.2",
                          local_path_or_url?: false,
                          semver_wildcard?: false,
                          parts: %w[16 1 2],
                          package_name: "react-on-rails",
                          package_json: "/fake/path/package.json")
        end

        before { stub_gem_version("16.1.1") }

        it "raises an error" do
          expect { check_version_and_raise(node_package_version) }
            .to raise_error(ReactOnRails::Error, /The 'react-on-rails' package version does not match the gem version/)
        end
      end

      context "when versions match exactly" do
        let(:node_package_version) do
          instance_double(VersionChecker::NodePackageVersion,
                          react_on_rails_package?: true,
                          react_on_rails_pro_package?: false,
                          raw: "16.1.1",
                          local_path_or_url?: false,
                          semver_wildcard?: false,
                          parts: %w[16 1 1],
                          package_json: "/fake/path/package.json")
        end

        before { stub_gem_version("16.1.1") }

        it "does not raise an error" do
          expect { check_version_and_raise(node_package_version) }.not_to raise_error
        end
      end

      context "when using local path" do
        let(:node_package_version) do
          instance_double(VersionChecker::NodePackageVersion,
                          react_on_rails_package?: true,
                          react_on_rails_pro_package?: false,
                          raw: "file:../react-on-rails",
                          local_path_or_url?: true,
                          semver_wildcard?: false,
                          package_json: "/fake/path/package.json")
        end

        before { stub_gem_version("16.1.1") }

        it "does not raise an error" do
          expect { check_version_and_raise(node_package_version) }.not_to raise_error
        end
      end

      context "when Pro gem and Pro package are both installed with matching versions" do
        let(:node_package_version) do
          instance_double(VersionChecker::NodePackageVersion,
                          react_on_rails_package?: false,
                          react_on_rails_pro_package?: true,
                          raw: "16.1.1",
                          local_path_or_url?: false,
                          semver_wildcard?: false,
                          parts: %w[16 1 1],
                          package_json: "/fake/path/package.json")
        end

        before do
          allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
          stub_gem_version("16.1.1")
        end

        it "does not raise an error" do
          expect { check_version_and_raise(node_package_version) }.not_to raise_error
        end
      end

      context "when package.json file does not exist" do
        let(:node_package_version) do
          instance_double(VersionChecker::NodePackageVersion,
                          package_json: "/path/to/nonexistent/package.json")
        end

        it "raises an error" do
          # Override File.exist? to return false for this test
          allow(File).to receive(:exist?).with(node_package_version.package_json).and_return(false)
          # Still need to stub Rails for package_json_location
          allow(Rails).to receive_message_chain(:root, :join).and_return(node_package_version.package_json)
          allow(ReactOnRails).to receive_message_chain(:configuration, :node_modules_location).and_return("")

          version_checker = described_class.new(node_package_version)
          expect { version_checker.validate_version_and_package_compatibility! }
            .to raise_error(ReactOnRails::Error, /package\.json file not found/)
        end
      end
    end

    def double_package_version(raw: nil, semver_wildcard: false,
                               parts: nil, local_path_or_url: false)
      instance_double(VersionChecker::NodePackageVersion,
                      raw: raw,
                      semver_wildcard?: semver_wildcard,
                      parts: parts,
                      local_path_or_url?: local_path_or_url,
                      package_json: "/fake/path/package.json")
    end

    def check_version_and_raise(node_package_version)
      # Stub File.exist? for the package.json check
      allow(File).to receive(:exist?).with(node_package_version.package_json).and_return(true)
      # Stub Rails.root.join for package_json_location helper
      allow(Rails).to receive_message_chain(:root, :join).and_return(node_package_version.package_json)
      # Stub ReactOnRails.configuration.node_modules_location
      allow(ReactOnRails).to receive_message_chain(:configuration, :node_modules_location).and_return("")
      version_checker = VersionChecker.new(node_package_version)
      version_checker.validate_version_and_package_compatibility!
    end

    describe VersionChecker::NodePackageVersion do
      subject(:node_package_version) { described_class.new(package_json) }

      describe "#build" do
        it "initializes NodePackageVersion with ReactOnRails.configuration.node_modules_location" do
          allow(ReactOnRails).to receive_message_chain(:configuration, :node_modules_location).and_return("spec/dummy")
          # Use a fixture that has dependencies but not react-on-rails packages
          test_package_json = File.expand_path("fixtures/beta_package.json", __dir__)
          allow(Rails).to receive_message_chain(:root, :join).and_return(test_package_json)

          # beta_package.json has react-on-rails, so it should not warn
          allow(Rails.logger).to receive(:warn)
          result = described_class.build.raw
          expect(result).to eq("^14.0.0.beta-2")
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

        context "when package json lists a version range of '>=1.2.3 <2.0.0'" do
          let(:package_json) { File.expand_path("fixtures/semver_range_package.json", __dir__) }

          specify { expect(node_package_version.semver_wildcard?).to be true }
        end
      end

      context "when package json lists a version of '0.0.2'" do
        let(:package_json) { File.expand_path("fixtures/normal_package.json", __dir__) }

        describe "#raw" do
          specify { expect(node_package_version.raw).to eq("0.0.2") }
        end

        describe "#local_path_or_url?" do
          specify { expect(node_package_version.local_path_or_url?).to be false }
        end

        describe "#parts" do
          specify { expect(node_package_version.parts).to eq(%w[0 0 2]) }
        end
      end

      context "when package json lists a version of '^14.0.0.beta-2'" do
        let(:package_json) { File.expand_path("fixtures/beta_package.json", __dir__) }

        describe "#raw" do
          specify { expect(node_package_version.raw).to eq("^14.0.0.beta-2") }
        end

        describe "#local_path_or_url?" do
          specify { expect(node_package_version.local_path_or_url?).to be false }
        end

        describe "#parts" do
          specify { expect(node_package_version.parts).to eq(%w[14 0 0 beta-2]) }
        end
      end

      context "with node version of '../../..'" do
        let(:package_json) { File.expand_path("fixtures/relative_path_package.json", __dir__) }

        describe "#raw" do
          specify { expect(node_package_version.raw).to eq("../../..") }
        end

        describe "#local_path_or_url?" do
          specify { expect(node_package_version.local_path_or_url?).to be true }
        end

        describe "#parts" do
          specify { expect(node_package_version.parts).to be_nil }
        end
      end

      context "with node version of 'file:///Users/justin/shakacode/react_on_rails'" do
        let(:package_json) { File.expand_path("fixtures/absolute_path_package.json", __dir__) }

        describe "#raw" do
          specify { expect(node_package_version.raw).to eq("file:///Users/justin/shakacode/react_on_rails") }
        end

        describe "#local_path_or_url?" do
          specify { expect(node_package_version.local_path_or_url?).to be true }
        end

        describe "#parts" do
          specify { expect(node_package_version.parts).to be_nil }
        end
      end

      context "with node version of 'file:.yalc/react-on-rails'" do
        let(:package_json) { File.expand_path("fixtures/yalc_package.json", __dir__) }

        describe "#raw" do
          specify { expect(node_package_version.raw).to eq("file:.yalc/react-on-rails") }
        end

        describe "#local_path_or_url?" do
          specify { expect(node_package_version.local_path_or_url?).to be true }
        end

        describe "#parts" do
          specify { expect(node_package_version.parts).to be_nil }
        end
      end

      context "with node version of `git:` URL" do
        let(:package_json) { File.expand_path("fixtures/git_package.json", __dir__) }

        describe "#raw" do
          specify { expect(node_package_version.raw).to eq("git://github.com/shakacode/react-on-rails.git") }
        end

        describe "#local_path_or_url?" do
          specify { expect(node_package_version.local_path_or_url?).to be true }
        end

        describe "#parts" do
          specify { expect(node_package_version.parts).to be_nil }
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

      describe "Pro package detection" do
        context "with react-on-rails package" do
          let(:package_json) { File.expand_path("fixtures/normal_package.json", __dir__) }

          describe "#react_on_rails_package?" do
            specify { expect(node_package_version.react_on_rails_package?).to be true }
          end

          describe "#react_on_rails_pro_package?" do
            specify { expect(node_package_version.react_on_rails_pro_package?).to be false }
          end

          describe "#package_name" do
            specify { expect(node_package_version.package_name).to eq("react-on-rails") }
          end

          describe "#raw" do
            specify { expect(node_package_version.raw).to eq("0.0.2") }
          end
        end

        context "with react-on-rails-pro package" do
          let(:package_json) { File.expand_path("fixtures/pro_package.json", __dir__) }

          describe "#react_on_rails_package?" do
            specify { expect(node_package_version.react_on_rails_package?).to be false }
          end

          describe "#react_on_rails_pro_package?" do
            specify { expect(node_package_version.react_on_rails_pro_package?).to be true }
          end

          describe "#package_name" do
            specify { expect(node_package_version.package_name).to eq("react-on-rails-pro") }
          end

          describe "#raw" do
            specify { expect(node_package_version.raw).to eq("16.1.1") }
          end
        end

        context "with both packages" do
          let(:package_json) { File.expand_path("fixtures/both_packages.json", __dir__) }

          describe "#react_on_rails_package?" do
            specify { expect(node_package_version.react_on_rails_package?).to be true }
          end

          describe "#react_on_rails_pro_package?" do
            specify { expect(node_package_version.react_on_rails_pro_package?).to be true }
          end

          describe "#package_name" do
            it "prefers Pro package name" do
              expect(node_package_version.package_name).to eq("react-on-rails-pro")
            end
          end

          describe "#raw" do
            it "returns Pro package version (takes precedence)" do
              expect(node_package_version.raw).to eq("16.1.1")
            end
          end
        end

        context "with Pro package using semver caret" do
          let(:package_json) { File.expand_path("fixtures/pro_semver_caret_package.json", __dir__) }

          describe "#react_on_rails_pro_package?" do
            specify { expect(node_package_version.react_on_rails_pro_package?).to be true }
          end

          describe "#package_name" do
            specify { expect(node_package_version.package_name).to eq("react-on-rails-pro") }
          end

          describe "#raw" do
            specify { expect(node_package_version.raw).to eq("^16.1.1") }
          end

          describe "#semver_wildcard?" do
            specify { expect(node_package_version.semver_wildcard?).to be true }
          end
        end

        context "with package.json without any react-on-rails packages" do
          let(:package_json) { File.expand_path("../../package.json", __dir__) }

          describe "#react_on_rails_package?" do
            specify { expect(node_package_version.react_on_rails_package?).to be false }
          end

          describe "#react_on_rails_pro_package?" do
            specify { expect(node_package_version.react_on_rails_pro_package?).to be false }
          end

          describe "#package_name" do
            it "defaults to react-on-rails" do
              expect(node_package_version.package_name).to eq("react-on-rails")
            end
          end
        end
      end
    end
  end
end

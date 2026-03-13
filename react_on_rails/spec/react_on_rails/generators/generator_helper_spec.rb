# frozen_string_literal: true

require_relative "../support/generator_spec_helper"

RSpec.describe GeneratorHelper, type: :generator do
  include described_class

  let(:destination_root) { File.expand_path("../dummy-for-generators", __dir__) }

  describe "#add_npm_dependencies" do
    context "when package_json gem is available" do
      let(:mock_package_json) { instance_double(PackageJson) }
      let(:mock_manager) { instance_double("PackageJson::Manager") } # rubocop:disable RSpec/VerifiedDoubleReference

      before do
        # Stub PackageJson constant so instance_double can reference it
        stub_const("PackageJson", Class.new) unless defined?(PackageJson)

        allow(self).to receive(:package_json).and_return(mock_package_json)
        allow(mock_package_json).to receive(:manager).and_return(mock_manager)
      end

      context "when adding regular dependencies" do
        it "calls manager.add with exact: true" do
          packages = %w[react react-dom]
          allow(mock_manager).to receive(:add).with(packages, exact: true).and_return(true)

          result = add_npm_dependencies(packages)
          expect(mock_manager).to have_received(:add).with(packages, exact: true)
          expect(result).to be true
        end
      end

      context "when adding dev dependencies" do
        it "calls manager.add with type: :dev and exact: true" do
          packages = ["@types/react", "@types/react-dom"]
          allow(mock_manager).to receive(:add).with(packages, type: :dev, exact: true).and_return(true)

          result = add_npm_dependencies(packages, dev: true)
          expect(mock_manager).to have_received(:add).with(packages, type: :dev, exact: true)
          expect(result).to be true
        end
      end

      context "when package manager add returns false" do
        it "returns false so callers can fall back" do
          packages = ["react-on-rails-rsc@99.99.99"]

          allow(mock_manager).to receive(:add).with(packages, exact: true).and_return(false)

          result = add_npm_dependencies(packages)
          expect(mock_manager).to have_received(:add).with(packages, exact: true)
          expect(result).to be false
        end
      end

      context "when package manager add returns nil" do
        it "treats nil as success for side-effect-only package managers" do
          packages = %w[react react-dom]

          allow(mock_manager).to receive(:add).with(packages, exact: true).and_return(nil)

          result = add_npm_dependencies(packages)
          expect(mock_manager).to have_received(:add).with(packages, exact: true)
          expect(result).to be true
        end
      end

      context "when package_json gem raises an error" do
        it "returns false and prints a warning" do
          packages = ["react"]

          allow(mock_manager).to receive(:add).and_raise(StandardError, "Installation failed")
          expect { add_npm_dependencies(packages) }.to output(/Warning: Could not add packages/).to_stdout

          result = add_npm_dependencies(packages)
          expect(result).to be false
        end
      end
    end

    context "when package_json gem is not available" do
      before do
        allow(self).to receive(:package_json).and_return(nil)
      end

      it "returns false" do
        packages = ["react"]

        result = add_npm_dependencies(packages)
        expect(result).to be false
      end
    end
  end

  describe "#package_json" do
    context "when PackageJson is available" do
      before do
        stub_const("PackageJson", Class.new do
          def self.read
            new
          end
        end)
      end

      it "returns a PackageJson instance" do
        result = package_json
        expect(result).to be_a(PackageJson)
      end

      it "memoizes the result" do
        first_call = package_json
        second_call = package_json
        expect(first_call).to equal(second_call)
      end
    end

    # NOTE: Testing the LoadError path is difficult because PackageJson is already loaded
    # in the test environment. The StandardError path below covers the error handling logic.

    context "when package.json file cannot be read" do
      before do
        stub_const("PackageJson", Class.new do
          def self.read
            raise StandardError, "File not found"
          end
        end)
      end

      it "returns nil and prints a warning" do
        expect { package_json }.to output(/Warning: Could not read package\.json/).to_stdout
        expect(package_json).to be_nil
      end
    end
  end

  describe "RSC Pro mode helpers" do
    it "enables rsc-pro mode for explicit --rsc-pro flag" do
      allow(self).to receive(:options).and_return({ rsc_pro: true, rsc: false, pro: false })

      expect(use_rsc_pro_mode?).to be(true)
      expect(use_rsc?).to be(true)
      expect(use_pro?).to be(true)
    end

    it "enables rsc-pro mode when --rsc and --pro are both set" do
      allow(self).to receive(:options).and_return({ rsc_pro: false, rsc: true, pro: true })

      expect(use_rsc_pro_mode?).to be(true)
      expect(use_rsc?).to be(true)
      expect(use_pro?).to be(true)
    end

    it "does not enable rsc-pro mode for standalone --pro" do
      allow(self).to receive(:options).and_return({ rsc_pro: false, rsc: false, pro: true })

      expect(use_rsc_pro_mode?).to be(false)
      expect(use_rsc?).to be(false)
      expect(use_pro?).to be(true)
    end
  end

  describe "#using_swc?" do
    let(:shakapacker_yml_path) { File.join(destination_root, "config/shakapacker.yml") }

    before do
      # Clear memoized value before each test
      remove_instance_variable(:@using_swc) if instance_variable_defined?(:@using_swc)
      FileUtils.mkdir_p(File.join(destination_root, "config"))
    end

    after do
      FileUtils.rm_rf(File.join(destination_root, "config"))
    end

    context "when shakapacker.yml exists with javascript_transpiler: swc" do
      before do
        File.write(shakapacker_yml_path, <<~YAML)
          default: &default
            javascript_transpiler: swc
        YAML
      end

      it "returns true" do
        expect(using_swc?).to be true
      end
    end

    context "when shakapacker.yml exists with javascript_transpiler: babel" do
      before do
        File.write(shakapacker_yml_path, <<~YAML)
          default: &default
            javascript_transpiler: babel
        YAML
      end

      it "returns false" do
        expect(using_swc?).to be false
      end
    end

    context "when shakapacker.yml exists without javascript_transpiler setting" do
      before do
        File.write(shakapacker_yml_path, <<~YAML)
          default: &default
            source_path: app/javascript
        YAML
        # Stub to simulate Shakapacker 9.3.0+ where SWC is default
        stub_const("ReactOnRails::PackerUtils", Class.new do
          def self.shakapacker_version_requirement_met?(version)
            version == "9.3.0"
          end
        end)
      end

      it "returns true for Shakapacker 9.3.0+ (SWC is default)" do
        expect(using_swc?).to be true
      end
    end

    context "when shakapacker.yml does not exist" do
      before do
        FileUtils.rm_f(shakapacker_yml_path)
        # Stub to simulate Shakapacker 9.3.0+ where SWC is default
        stub_const("ReactOnRails::PackerUtils", Class.new do
          def self.shakapacker_version_requirement_met?(version)
            version == "9.3.0"
          end
        end)
      end

      it "returns true for fresh installations with Shakapacker 9.3.0+" do
        expect(using_swc?).to be true
      end
    end

    context "when shakapacker.yml has parse errors" do
      before do
        File.write(shakapacker_yml_path, "invalid: yaml: [}")
        # Stub to simulate Shakapacker 9.3.0+ where SWC is default
        stub_const("ReactOnRails::PackerUtils", Class.new do
          def self.shakapacker_version_requirement_met?(version)
            version == "9.3.0"
          end
        end)
      end

      it "returns true (assumes latest Shakapacker with SWC default)" do
        expect(using_swc?).to be true
      end
    end

    context "with version boundary scenarios" do
      before do
        File.write(shakapacker_yml_path, <<~YAML)
          default: &default
            source_path: app/javascript
        YAML
      end

      context "when Shakapacker version is 9.3.0+ (SWC default)" do
        before do
          stub_const("ReactOnRails::PackerUtils", Class.new do
            def self.shakapacker_version_requirement_met?(version)
              version == "9.3.0"
            end
          end)
        end

        it "returns true when no transpiler is specified" do
          expect(using_swc?).to be true
        end
      end

      context "when Shakapacker version is below 9.3.0 (Babel default)" do
        before do
          stub_const("ReactOnRails::PackerUtils", Class.new do
            def self.shakapacker_version_requirement_met?(version)
              # Only meets requirements for versions below 9.3.0
              version != "9.3.0"
            end
          end)
        end

        it "returns false when no transpiler is specified" do
          expect(using_swc?).to be false
        end
      end

      context "when PackerUtils raises an error during version check" do
        before do
          stub_const("ReactOnRails::PackerUtils", Class.new do
            def self.shakapacker_version_requirement_met?(_version)
              raise StandardError, "Cannot determine version"
            end
          end)
        end

        it "defaults to true (assumes latest Shakapacker)" do
          expect(using_swc?).to be true
        end
      end
    end
  end
end

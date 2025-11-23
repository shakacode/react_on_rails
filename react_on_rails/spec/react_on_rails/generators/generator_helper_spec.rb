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

          expect(mock_manager).to receive(:add).with(packages, exact: true)

          result = add_npm_dependencies(packages)
          expect(result).to be true
        end
      end

      context "when adding dev dependencies" do
        it "calls manager.add with type: :dev and exact: true" do
          packages = ["@types/react", "@types/react-dom"]

          expect(mock_manager).to receive(:add).with(packages, type: :dev, exact: true)

          result = add_npm_dependencies(packages, dev: true)
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
end

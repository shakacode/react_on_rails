# frozen_string_literal: true

require_relative "../support/generator_spec_helper"

describe ReactOnRails::Generators::JsDependencyManager, type: :generator do
  # Create a test class that includes the module for testing
  let(:test_class) do
    Class.new do
      include ReactOnRails::Generators::JsDependencyManager

      attr_accessor :options

      # Mock methods required by JsDependencyManager
      def add_npm_dependencies(_packages, dev: false)
        @add_npm_dependencies_called = true
        @add_npm_dependencies_dev = dev
        @add_npm_dependencies_result
      end

      attr_reader :package_json

      def destination_root
        "/test/path"
      end

      # Test helpers
      attr_writer :add_npm_dependencies_result

      def add_npm_dependencies_called?
        @add_npm_dependencies_called
      end

      def add_npm_dependencies_dev?
        @add_npm_dependencies_dev
      end

      attr_writer :package_json
    end
  end

  let(:instance) { test_class.new }
  # rubocop:disable RSpec/VerifiedDoubles
  let(:mock_manager) { double("PackageManager", install: true, add: true) }
  let(:mock_package_json) { double("PackageJson", manager: mock_manager) }
  # rubocop:enable RSpec/VerifiedDoubles

  # Helper methods to filter GeneratorMessages output
  def warnings
    GeneratorMessages.output.select { |msg| msg.to_s.include?("WARNING") }
  end

  def errors
    GeneratorMessages.output.select { |msg| msg.to_s.include?("ERROR") }
  end

  before do
    # Clear any previous messages
    GeneratorMessages.clear
    # Set up default mocks
    instance.package_json = mock_package_json
    instance.add_npm_dependencies_result = true
  end

  describe "constants" do
    it "defines REACT_DEPENDENCIES" do
      expect(ReactOnRails::Generators::JsDependencyManager::REACT_DEPENDENCIES).to eq(%w[
                                                                                        react
                                                                                        react-dom
                                                                                        prop-types
                                                                                      ])
    end

    it "defines CSS_DEPENDENCIES" do
      expect(ReactOnRails::Generators::JsDependencyManager::CSS_DEPENDENCIES).to eq(%w[
                                                                                      css-loader
                                                                                      css-minimizer-webpack-plugin
                                                                                      mini-css-extract-plugin
                                                                                      style-loader
                                                                                    ])
    end

    it "defines DEV_DEPENDENCIES" do
      expect(ReactOnRails::Generators::JsDependencyManager::DEV_DEPENDENCIES).to(
        eq(%w[@pmmmwh/react-refresh-webpack-plugin react-refresh])
      )
    end

    it "defines RSPACK_DEPENDENCIES" do
      expect(ReactOnRails::Generators::JsDependencyManager::RSPACK_DEPENDENCIES).to eq(%w[
                                                                                         @rspack/core
                                                                                         rspack-manifest-plugin
                                                                                       ])
    end

    it "defines RSPACK_DEV_DEPENDENCIES" do
      expect(ReactOnRails::Generators::JsDependencyManager::RSPACK_DEV_DEPENDENCIES).to(
        eq(%w[@rspack/cli @rspack/plugin-react-refresh react-refresh])
      )
    end

    it "defines TYPESCRIPT_DEPENDENCIES" do
      expect(ReactOnRails::Generators::JsDependencyManager::TYPESCRIPT_DEPENDENCIES).to eq(%w[
                                                                                             typescript
                                                                                             @types/react
                                                                                             @types/react-dom
                                                                                           ])
    end

    it "does not include Babel presets in REACT_DEPENDENCIES" do
      expect(ReactOnRails::Generators::JsDependencyManager::REACT_DEPENDENCIES).not_to include(
        "@babel/preset-react"
      )
    end

    it "does not include Babel TypeScript preset in TYPESCRIPT_DEPENDENCIES" do
      expect(ReactOnRails::Generators::JsDependencyManager::TYPESCRIPT_DEPENDENCIES).not_to include(
        "@babel/preset-typescript"
      )
    end
  end

  describe "#add_packages" do
    it "delegates to add_npm_dependencies" do
      result = instance.send(:add_packages, %w[package1 package2])
      expect(result).to be(true)
      expect(instance.add_npm_dependencies_called?).to be(true)
    end

    it "passes dev flag to add_npm_dependencies" do
      instance.send(:add_packages, %w[package1], dev: true)
      expect(instance.add_npm_dependencies_dev?).to be(true)
    end

    it "returns false when add_npm_dependencies fails" do
      instance.add_npm_dependencies_result = false
      result = instance.send(:add_packages, %w[package1])
      expect(result).to be(false)
    end
  end

  describe "#add_package" do
    it "adds a single package successfully" do
      result = instance.send(:add_package, "react-on-rails@16.0.0")
      expect(result).to be(true)
      expect(mock_manager).to have_received(:add).with(["react-on-rails@16.0.0"])
    end

    it "adds a dev dependency when dev: true" do
      result = instance.send(:add_package, "typescript", dev: true)
      expect(result).to be(true)
      expect(mock_manager).to have_received(:add).with(["typescript"], type: :dev)
    end

    it "returns false when package_json is nil" do
      instance.package_json = nil
      result = instance.send(:add_package, "some-package")
      expect(result).to be(false)
    end

    it "returns false and logs warning when add raises error" do
      allow(mock_manager).to receive(:add).and_raise(StandardError, "Network error")
      result = instance.send(:add_package, "some-package")
      expect(result).to be(false)
    end
  end

  describe "#install_js_dependencies" do
    it "calls package_json.manager.install" do
      result = instance.send(:install_js_dependencies)
      expect(result).to be(true)
      expect(mock_manager).to have_received(:install)
    end

    it "returns false and adds warning when install fails" do
      allow(mock_manager).to receive(:install).and_raise(StandardError, "Network timeout")

      result = instance.send(:install_js_dependencies)

      expect(result).to be(false)
      expect(warnings.size).to be > 0
      expect(warnings.first.to_s).to include("JavaScript dependencies installation failed")
    end
  end

  describe "#add_react_on_rails_package" do
    before do
      # Stub VERSION constant
      stub_const("ReactOnRails::VERSION", "16.0.0")
    end

    it "adds react-on-rails with version for stable releases" do
      instance.send(:add_react_on_rails_package)
      expect(mock_manager).to have_received(:add).with(["react-on-rails@16.0.0"])
    end

    it "adds react-on-rails without version for pre-releases" do
      stub_const("ReactOnRails::VERSION", "16.0.0-rc.1")
      instance.send(:add_react_on_rails_package)
      expect(mock_manager).to have_received(:add).with(["react-on-rails"])
    end

    it "adds warning when add_package fails" do
      allow(mock_manager).to receive(:add).and_return(false)
      instance.package_json = nil

      instance.send(:add_react_on_rails_package)

      expect(warnings.size).to be > 0
      expect(warnings.first.to_s).to include("Failed to add react-on-rails package")
    end

    it "catches exceptions in add_package and adds warning" do
      allow(mock_manager).to receive(:add).and_raise(StandardError, "Connection refused")

      instance.send(:add_react_on_rails_package)

      expect(warnings.size).to be > 0
      # When add_package catches exception, it returns false, triggering the "Failed to add" warning
      expect(warnings.first.to_s).to include("Failed to add react-on-rails package")
    end
  end

  describe "#add_react_dependencies" do
    it "adds React dependencies successfully" do
      instance.send(:add_react_dependencies)
      expect(instance.add_npm_dependencies_called?).to be(true)
    end

    it "adds warning when add_packages fails" do
      instance.add_npm_dependencies_result = false

      instance.send(:add_react_dependencies)

      expect(warnings.size).to be > 0
      expect(warnings.first.to_s).to include("Failed to add React dependencies")
    end
  end

  describe "#add_css_dependencies" do
    it "adds CSS dependencies successfully" do
      instance.send(:add_css_dependencies)
      expect(instance.add_npm_dependencies_called?).to be(true)
    end

    it "adds warning when add_packages fails" do
      instance.add_npm_dependencies_result = false

      instance.send(:add_css_dependencies)

      expect(warnings.size).to be > 0
      expect(warnings.first.to_s).to include("Failed to add CSS dependencies")
    end
  end

  describe "#add_dev_dependencies" do
    it "adds Webpack dev dependencies by default" do
      instance.send(:add_dev_dependencies)
      expect(instance.add_npm_dependencies_called?).to be(true)
      expect(instance.add_npm_dependencies_dev?).to be(true)
    end

    it "adds Rspack dev dependencies when --rspack flag is set" do
      # rubocop:disable RSpec/VerifiedDoubles
      options = double("Options", rspack?: true)
      # rubocop:enable RSpec/VerifiedDoubles
      instance.options = options

      instance.send(:add_dev_dependencies)

      expect(instance.add_npm_dependencies_called?).to be(true)
      expect(instance.add_npm_dependencies_dev?).to be(true)
    end

    it "adds warning when add_packages fails" do
      instance.add_npm_dependencies_result = false

      instance.send(:add_dev_dependencies)

      expect(warnings.size).to be > 0
      expect(warnings.first.to_s).to include("Failed to add development dependencies")
    end
  end

  describe "#add_rspack_dependencies" do
    it "adds Rspack dependencies successfully" do
      instance.send(:add_rspack_dependencies)
      expect(instance.add_npm_dependencies_called?).to be(true)
    end

    it "adds warning when add_packages fails" do
      instance.add_npm_dependencies_result = false

      instance.send(:add_rspack_dependencies)

      expect(warnings.size).to be > 0
      expect(warnings.first.to_s).to include("Failed to add Rspack dependencies")
    end
  end

  describe "#add_typescript_dependencies" do
    it "adds TypeScript dependencies as dev dependencies" do
      instance.send(:add_typescript_dependencies)
      expect(instance.add_npm_dependencies_called?).to be(true)
      expect(instance.add_npm_dependencies_dev?).to be(true)
    end

    it "adds warning when add_packages fails" do
      instance.add_npm_dependencies_result = false

      instance.send(:add_typescript_dependencies)

      expect(warnings.size).to be > 0
      expect(warnings.first.to_s).to include("Failed to add TypeScript dependencies")
    end
  end

  describe "error handling consistency" do
    it "all add_* methods use warnings instead of errors" do
      instance.add_npm_dependencies_result = false
      instance.package_json = nil

      # Call all add methods
      instance.send(:add_react_on_rails_package)
      instance.send(:add_react_dependencies)
      instance.send(:add_css_dependencies)
      instance.send(:add_rspack_dependencies)
      instance.send(:add_typescript_dependencies)
      instance.send(:add_dev_dependencies)

      # All should add warnings, not errors
      expect(warnings.count).to be >= 6
      expect(errors.size).to eq(0)
    end

    it "all warning messages include manual installation instructions" do
      instance.add_npm_dependencies_result = false

      instance.send(:add_react_dependencies)

      warning = warnings.first
      expect(warning.to_s).to include("npm install")
      expect(warning.to_s).to include("manually")
    end
  end
end

# frozen_string_literal: true

require_relative "../support/generator_spec_helper"

# rubocop:disable Style/NumericPredicate
# Using `be > 0` instead of `be_positive` because `be_positive` is not available
# in the RSpec version used with generator_spec test cases (method_missing conflict)
describe ReactOnRails::Generators::JsDependencyManager, type: :generator do
  # Create a test class that includes the module for testing
  let(:test_class) do
    Class.new do
      include ReactOnRails::Generators::JsDependencyManager

      attr_accessor :options

      # Mock methods required by JsDependencyManager
      def add_npm_dependencies(packages, dev: false)
        @add_npm_dependencies_called = true
        @add_npm_dependencies_dev = dev
        @add_npm_dependencies_calls ||= []
        @add_npm_dependencies_calls << { packages: packages, dev: dev }
        @add_npm_dependencies_result
      end

      attr_reader :package_json

      def destination_root
        "/test/path"
      end

      def say(message = "", color = nil, force_new_line = nil)
        @say_calls ||= []
        @say_calls << { message: message, color: color, force_new_line: force_new_line }
      end

      def say_status(status, message, log_status = nil)
        @say_status_calls ||= []
        @say_status_calls << { status: status, message: message, log_status: log_status }
      end

      def system(*args)
        @system_calls ||= []
        @system_calls << args
        @system_result.nil? ? true : @system_result
      end

      # Mock using_swc? from GeneratorHelper (defaults to true for SWC testing)
      def using_swc?
        @using_swc.nil? ? true : @using_swc
      end

      attr_writer :using_swc

      # Mock using_rspack? from GeneratorHelper (defaults to false)
      def using_rspack?
        @using_rspack.nil? ? false : @using_rspack
      end

      attr_writer :using_rspack

      def use_rsc?
        @use_rsc == true
      end

      attr_writer :use_rsc

      # Test helpers
      attr_writer :add_npm_dependencies_result

      def add_npm_dependencies_called?
        @add_npm_dependencies_called
      end

      def add_npm_dependencies_dev?
        @add_npm_dependencies_dev
      end

      def add_npm_dependencies_calls
        @add_npm_dependencies_calls ||= []
      end

      attr_writer :system_result

      def system_calls
        @system_calls ||= []
      end

      attr_writer :package_json

      attr_reader :say_calls, :say_status_calls
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
    allow(GeneratorMessages).to receive(:detect_package_manager).and_return("npm")
    # Set up default mocks
    instance.package_json = mock_package_json
    instance.add_npm_dependencies_result = true
    instance.system_result = true
  end

  describe "constants" do
    it "defines REACT_DEPENDENCIES" do
      expect(ReactOnRails::Generators::JsDependencyManager::REACT_DEPENDENCIES).to eq(%w[
                                                                                        react@^19.0.0
                                                                                        react-dom@^19.0.0
                                                                                        prop-types@^15.0.0
                                                                                      ])
    end

    it "defines CSS_DEPENDENCIES" do
      expect(ReactOnRails::Generators::JsDependencyManager::CSS_DEPENDENCIES).to(
        eq(%w[css-loader@^7.0.0 css-minimizer-webpack-plugin@^8.0.0 mini-css-extract-plugin@^2.0.0
              style-loader@^4.0.0])
      )
    end

    it "defines DEV_DEPENDENCIES" do
      expect(ReactOnRails::Generators::JsDependencyManager::DEV_DEPENDENCIES).to(
        eq(%w[@pmmmwh/react-refresh-webpack-plugin react-refresh])
      )
    end

    it "defines RSPACK_DEPENDENCIES" do
      expect(ReactOnRails::Generators::JsDependencyManager::RSPACK_DEPENDENCIES).to eq(%w[
                                                                                         @rspack/core@^1.0.0
                                                                                         rspack-manifest-plugin@^5.0.0
                                                                                       ])
    end

    it "defines RSPACK_DEV_DEPENDENCIES" do
      expect(ReactOnRails::Generators::JsDependencyManager::RSPACK_DEV_DEPENDENCIES).to(
        eq(%w[@rspack/cli@^1.0.0 @rspack/plugin-react-refresh@^1.0.0 react-refresh])
      )
    end

    it "defines TYPESCRIPT_DEPENDENCIES" do
      expect(ReactOnRails::Generators::JsDependencyManager::TYPESCRIPT_DEPENDENCIES).to eq(%w[
                                                                                             typescript@^6.0.0
                                                                                             @types/react@^19.0.0
                                                                                             @types/react-dom@^19.0.0
                                                                                           ])
    end

    it "defines SWC_DEPENDENCIES" do
      expect(ReactOnRails::Generators::JsDependencyManager::SWC_DEPENDENCIES).to(
        eq(%w[@swc/core@^1.3.0 swc-loader@^0.2.0])
      )
    end

    it "defines BABEL_REACT_DEPENDENCIES" do
      expect(ReactOnRails::Generators::JsDependencyManager::BABEL_REACT_DEPENDENCIES).to eq(
        %w[@babel/preset-react@^7.0.0]
      )
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

    it "falls back to direct package-manager install when add_npm_dependencies fails" do
      instance.add_npm_dependencies_result = false
      result = instance.send(:add_packages, %w[package1])
      expect(result).to be(true)
      expect(instance.system_calls).to include(%w[npm install --save-exact package1])
    end

    it "returns false when add_npm_dependencies and fallback both fail" do
      instance.add_npm_dependencies_result = false
      instance.system_result = false
      result = instance.send(:add_packages, %w[package1])
      expect(result).to be(false)
    end

    it "skips fallback install for packages already present in package.json" do
      instance.add_npm_dependencies_result = false
      allow(instance).to receive(:existing_package_names).and_return(%w[package1])

      result = instance.send(:add_packages, %w[package1])

      expect(result).to be(true)
      expect(instance.system_calls).to eq([])
    end

    it "does not skip fallback install for versioned package specs" do
      instance.add_npm_dependencies_result = false
      allow(instance).to receive(:existing_package_names).and_return(%w[react])

      result = instance.send(:add_packages, ["react@~19.0.4"])

      expect(result).to be(true)
      expect(instance.system_calls).to include(%w[npm install --save-exact react@~19.0.4])
    end
  end

  describe "#add_package" do
    it "adds a single package successfully" do
      result = instance.send(:add_package, "react-on-rails@16.0.0")
      expect(result).to be(true)
      expect(instance.add_npm_dependencies_calls).to include(
        { packages: ["react-on-rails@16.0.0"], dev: false }
      )
    end

    it "adds a dev dependency when dev: true" do
      result = instance.send(:add_package, "typescript", dev: true)
      expect(result).to be(true)
      expect(instance.add_npm_dependencies_calls).to include(
        { packages: ["typescript"], dev: true }
      )
    end

    it "falls back to direct package-manager install when add_npm_dependencies fails" do
      instance.add_npm_dependencies_result = false
      result = instance.send(:add_package, "some-package")
      expect(result).to be(true)
      expect(instance.system_calls).to include(%w[npm install --save-exact some-package])
    end

    it "returns false when fallback install fails" do
      instance.add_npm_dependencies_result = false
      instance.system_result = false
      instance.package_json = nil
      result = instance.send(:add_package, "some-package")
      expect(result).to be(false)
    end

    it "returns false when fallback raises an exception" do
      instance.add_npm_dependencies_result = false
      allow(instance).to receive(:system).and_raise(StandardError, "Network error")
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

    it "falls back to package manager install when package_json is nil" do
      instance.package_json = nil

      result = instance.send(:install_js_dependencies)

      expect(result).to be(true)
      expect(instance.system_calls).to include(%w[npm install])
    end

    it "returns false and adds warning when fallback install fails" do
      instance.package_json = nil
      instance.system_result = false

      result = instance.send(:install_js_dependencies)

      expect(result).to be(false)
      expect(warnings.size).to be > 0
      expect(warnings.first.to_s).to include("JavaScript dependencies installation failed via npm")
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
      expect(instance.add_npm_dependencies_calls).to include(
        { packages: ["react-on-rails@16.0.0"], dev: false }
      )
    end

    it "adds react-on-rails with version for RC pre-releases (npm format with hyphen)" do
      stub_const("ReactOnRails::VERSION", "16.0.0-rc.1")
      instance.send(:add_react_on_rails_package)
      expect(instance.add_npm_dependencies_calls).to include(
        { packages: ["react-on-rails@16.0.0-rc.1"], dev: false }
      )
    end

    it "converts Ruby gem beta format to npm format" do
      stub_const("ReactOnRails::VERSION", "16.2.0.beta.10")
      instance.send(:add_react_on_rails_package)
      expect(instance.add_npm_dependencies_calls).to include(
        { packages: ["react-on-rails@16.2.0-beta.10"], dev: false }
      )
    end

    it "converts Ruby gem RC format to npm format" do
      stub_const("ReactOnRails::VERSION", "16.0.0.rc.1")
      instance.send(:add_react_on_rails_package)
      expect(instance.add_npm_dependencies_calls).to include(
        { packages: ["react-on-rails@16.0.0-rc.1"], dev: false }
      )
    end

    it "converts Ruby gem alpha format to npm format" do
      stub_const("ReactOnRails::VERSION", "16.0.0.alpha.5")
      instance.send(:add_react_on_rails_package)
      expect(instance.add_npm_dependencies_calls).to include(
        { packages: ["react-on-rails@16.0.0-alpha.5"], dev: false }
      )
    end

    it "accepts npm format beta pre-releases (already with hyphen)" do
      stub_const("ReactOnRails::VERSION", "16.2.0-beta.10")
      instance.send(:add_react_on_rails_package)
      expect(instance.add_npm_dependencies_calls).to include(
        { packages: ["react-on-rails@16.2.0-beta.10"], dev: false }
      )
    end

    it "accepts npm format alpha releases (already with hyphen)" do
      stub_const("ReactOnRails::VERSION", "16.0.0-alpha.5")
      instance.send(:add_react_on_rails_package)
      expect(instance.add_npm_dependencies_calls).to include(
        { packages: ["react-on-rails@16.0.0-alpha.5"], dev: false }
      )
    end

    it "adds react-on-rails without version for invalid version formats" do
      stub_const("ReactOnRails::VERSION", "invalid-version")
      instance.send(:add_react_on_rails_package)
      expect(instance.add_npm_dependencies_calls).to include(
        { packages: ["react-on-rails"], dev: false }
      )
    end

    it "warns about invalid version format when version doesn't match semver" do
      stub_const("ReactOnRails::VERSION", "invalid-version")
      allow(instance).to receive(:say_status).and_call_original

      instance.send(:add_react_on_rails_package)
      expect(instance).to have_received(:say_status).with(
        :warning,
        a_string_including("Unrecognized version format invalid-version"),
        :yellow
      )
    end

    it "adds warning when add_package fails" do
      instance.add_npm_dependencies_result = false
      instance.system_result = false
      instance.package_json = nil

      instance.send(:add_react_on_rails_package)

      expect(warnings.size).to be > 0
      expect(warnings.first.to_s).to include("Failed to add react-on-rails package")
    end

    it "catches exceptions in add_package and adds warning" do
      instance.add_npm_dependencies_result = false
      allow(instance).to receive(:system).and_raise(StandardError, "Connection refused")

      instance.send(:add_react_on_rails_package)

      expect(warnings.size).to be > 0
      warning_text = warnings.map(&:to_s).join("\n")
      expect(warning_text).to include("Fallback package install failed: Connection refused")
      expect(warning_text).to include("Failed to add react-on-rails package")
    end
  end

  describe "#add_react_dependencies" do
    it "adds React dependencies successfully" do
      instance.send(:add_react_dependencies)
      expect(instance.add_npm_dependencies_called?).to be(true)
    end

    it "pins react and react-dom to the RSC-compatible 19.0.x track when RSC is enabled" do
      instance.use_rsc = true

      instance.send(:add_react_dependencies)

      expect(instance.add_npm_dependencies_calls).to include(
        a_hash_including(
          packages: ["react@~19.0.4", "react-dom@~19.0.4", "prop-types"],
          dev: false
        )
      )
    end

    it "adds warning when add_packages fails" do
      instance.add_npm_dependencies_result = false
      instance.system_result = false
      allow(instance).to receive(:existing_package_names).and_return([])

      instance.send(:add_react_dependencies)

      expect(warnings.size).to be > 0
      expect(warnings.first.to_s).to include("Failed to add React dependencies")
    end

    it "warns with the pinned React install command when the RSC add fails" do
      instance.use_rsc = true
      instance.add_npm_dependencies_result = false
      instance.system_result = false

      instance.send(:add_react_dependencies)

      expect(warnings.size).to be > 0
      expect(warnings.first.to_s).to include("npm install react@~19.0.4 react-dom@~19.0.4 prop-types")
    end
  end

  describe "#add_css_dependencies" do
    it "adds CSS dependencies successfully" do
      instance.send(:add_css_dependencies)
      expect(instance.add_npm_dependencies_called?).to be(true)
    end

    it "adds warning when add_packages fails" do
      instance.add_npm_dependencies_result = false
      instance.system_result = false

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
      instance.using_rspack = true

      instance.send(:add_dev_dependencies)

      expect(instance.add_npm_dependencies_called?).to be(true)
      expect(instance.add_npm_dependencies_dev?).to be(true)
    end

    it "adds warning when add_packages fails" do
      instance.add_npm_dependencies_result = false
      instance.system_result = false

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
      instance.system_result = false

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
      instance.system_result = false
      allow(instance).to receive(:existing_package_names).and_return([])

      instance.send(:add_typescript_dependencies)

      expect(warnings.size).to be > 0
      expect(warnings.first.to_s).to include("Failed to add TypeScript dependencies")
    end
  end

  describe "#rsc_packages_with_version" do
    it "defines an explicit RSC package version pin independent from the React semver range prefix" do
      expect(ReactOnRails::Generators::JsDependencyManager::RSC_REACT_VERSION_RANGE).to eq("~19.0.4")
      expect(ReactOnRails::Generators::JsDependencyManager::RSC_PACKAGE_VERSION_PIN).to eq("19.0.4")
    end

    it "pins react-on-rails-rsc to the React 19 compatibility track" do
      expected_pin = ReactOnRails::Generators::JsDependencyManager::RSC_PACKAGE_VERSION_PIN
      expect(instance.send(:rsc_packages_with_version)).to eq([["react-on-rails-rsc@#{expected_pin}"], true])
    end
  end

  describe "#add_rsc_dependencies" do
    it "installs version-pinned rsc dependency" do
      allow(instance).to receive(:rsc_packages_with_version).and_return([["react-on-rails-rsc@19.0.4"], true])

      instance.send(:add_rsc_dependencies)

      expect(instance.add_npm_dependencies_calls).to include(
        a_hash_including(packages: ["react-on-rails-rsc@19.0.4"], dev: false)
      )
    end

    it "falls back to unversioned package when pinned install fails" do
      allow(instance).to receive(:rsc_packages_with_version).and_return([["react-on-rails-rsc@19.0.4"], true])

      allow(instance).to receive(:add_packages).with(["react-on-rails-rsc@19.0.4"]).and_return(false)
      allow(instance).to receive(:add_packages).with(["react-on-rails-rsc"]).and_return(true)

      instance.send(:add_rsc_dependencies)

      expect(instance).to have_received(:add_packages).with(["react-on-rails-rsc@19.0.4"])
      expect(instance).to have_received(:add_packages).with(["react-on-rails-rsc"])
      expect(warnings.join("\n")).to include("installed react-on-rails-rsc version may not match")
    end
  end

  describe "#add_babel_react_dependencies" do
    it "adds Babel React preset as dev dependency" do
      instance.send(:add_babel_react_dependencies)
      expect(instance.add_npm_dependencies_called?).to be(true)
      expect(instance.add_npm_dependencies_dev?).to be(true)
    end

    it "adds warning when add_packages fails" do
      instance.add_npm_dependencies_result = false
      instance.system_result = false
      allow(instance).to receive(:existing_package_names).and_return([])

      instance.send(:add_babel_react_dependencies)

      expect(warnings.size).to be > 0
      expect(warnings.first.to_s).to include("Failed to add Babel React preset dependency")
    end

    it "adds warning when an exception is raised" do
      allow(instance).to receive(:add_packages).and_raise(StandardError, "network error")

      instance.send(:add_babel_react_dependencies)

      expect(warnings.size).to be > 0
      expect(warnings.first.to_s).to include("Error adding Babel React preset dependency")
    end
  end

  describe "error handling consistency" do
    it "all add_* methods use warnings instead of errors" do
      instance.add_npm_dependencies_result = false
      instance.system_result = false
      instance.package_json = nil
      allow(instance).to receive(:existing_package_names).and_return([])

      # Call all add methods
      instance.send(:add_react_on_rails_package)
      instance.send(:add_react_dependencies)
      instance.send(:add_css_dependencies)
      instance.send(:add_rspack_dependencies)
      instance.send(:add_typescript_dependencies)
      instance.send(:add_babel_react_dependencies)
      instance.send(:add_dev_dependencies)

      # All should add warnings, not errors
      expect(warnings.count).to be >= 7
      expect(errors.size).to eq(0)
    end

    it "all warning messages include manual installation instructions" do
      instance.add_npm_dependencies_result = false
      instance.system_result = false
      allow(instance).to receive(:existing_package_names).and_return([])

      instance.send(:add_react_dependencies)

      warning = warnings.first
      expect(warning.to_s).to include("npm install")
      expect(warning.to_s).to include("manually")
    end
  end

  describe "#add_js_dependencies" do
    it "adds Babel React preset when SWC is not used" do
      instance.using_swc = false

      instance.send(:add_js_dependencies)

      babel_calls = instance.add_npm_dependencies_calls.select do |call|
        call[:packages].include?("@babel/preset-react@^7.0.0")
      end
      expect(babel_calls.size).to be > 0
      expect(babel_calls.all? { |call| call[:dev] }).to be(true)
    end

    it "does not add Babel React preset when SWC is used" do
      instance.using_swc = true

      instance.send(:add_js_dependencies)

      babel_calls = instance.add_npm_dependencies_calls.select do |call|
        call[:packages].include?("@babel/preset-react@^7.0.0")
      end
      expect(babel_calls).to eq([])
    end

    it "does not add Babel React preset when rspack is used and SWC is not configured" do
      instance.using_swc = false
      instance.using_rspack = true

      instance.send(:add_js_dependencies)

      babel_calls = instance.add_npm_dependencies_calls.select do |call|
        call[:packages].include?("@babel/preset-react@^7.0.0")
      end
      expect(babel_calls).to eq([])
    end
  end

  describe "graceful degradation" do
    it "setup_js_dependencies completes successfully even when all package operations fail" do
      # Simulate complete package installation failure
      instance.add_npm_dependencies_result = false
      instance.system_result = false
      instance.package_json = nil

      # This should not raise any exceptions
      expect { instance.send(:setup_js_dependencies) }.not_to raise_error

      # Should have generated warnings for failures
      expect(warnings.size).to be > 0
      # But no errors that would crash the generator
      expect(errors.size).to eq(0)
    end

    it "setup_js_dependencies completes when install fails but add succeeds" do
      instance.add_npm_dependencies_result = true
      allow(mock_manager).to receive(:install).and_raise(StandardError, "Network timeout")

      # Should not raise despite install failure
      expect { instance.send(:setup_js_dependencies) }.not_to raise_error

      # Should have warning about install failure
      expect(warnings.any? { |w| w.to_s.include?("installation failed") }).to be(true)
    end
  end
end
# rubocop:enable Style/NumericPredicate

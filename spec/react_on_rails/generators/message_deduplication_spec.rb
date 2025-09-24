# frozen_string_literal: true

require_relative "../support/generator_spec_helper"
require_relative "../support/version_test_helpers"

describe "Message Deduplication", type: :generator do
  include GeneratorSpec::TestCase

  destination File.expand_path("../dummy-for-generators", __dir__)

  describe "Post-install message handling" do
    before do
      # Clear any previous messages to ensure clean test state
      GeneratorMessages.clear
      # Mock Shakapacker installation to succeed
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("bin/shakapacker").and_return(true)
      allow(File).to receive(:exist?).with("bin/shakapacker-dev-server").and_return(true)
      allow(File).to receive(:exist?).with("config/shakapacker.yml").and_return(true)
      allow(File).to receive(:exist?).with("config/webpack/webpack.config.js").and_return(true)
    end

    context "with non-Redux installation" do
      it "shows the success message exactly once" do
        run_generator_test_with_args(%w[], package_json: true)
        output_text = GeneratorMessages.output.join("\n")

        # Count occurrences of the success message
        success_count = output_text.scan("🎉 React on Rails Successfully Installed!").count
        expect(success_count).to eq(1),
          "Expected success message to appear exactly once, but appeared #{success_count} times"

        # Ensure post-install message components are present
        expect(output_text).to include("📋 QUICK START:")
        expect(output_text).to include("✨ KEY FEATURES:")
      end
    end

    context "with Redux installation" do
      it "shows the success message exactly once" do
        run_generator_test_with_args(%w[--redux], package_json: true)
        output_text = GeneratorMessages.output.join("\n")

        # Count occurrences of the success message
        success_count = output_text.scan("🎉 React on Rails Successfully Installed!").count
        expect(success_count).to eq(1),
          "Expected success message to appear exactly once with Redux, but appeared #{success_count} times"

        # Ensure post-install message components are present
        expect(output_text).to include("📋 QUICK START:")
        expect(output_text).to include("✨ KEY FEATURES:")

        # The message should be from the Redux generator, containing Redux-specific info
        expect(output_text).to include("HelloWorldApp")
      end
    end
  end

  describe "NPM install execution" do
    let(:install_generator) { InstallGenerator.new }

    before do
      # Mock the system to track NPM install calls
      allow(install_generator).to receive(:system).and_return(true)
      allow(install_generator).to receive(:add_npm_dependencies).and_return(false)
      allow(File).to receive(:exist?).and_return(false)
      allow(File).to receive(:exist?).with(File.join(anything, "package.json")).and_return(true)
      allow(install_generator).to receive(:destination_root).and_return("/test/path")

      # Initialize instance variables
      install_generator.instance_variable_set(:@added_dependencies_to_package_json, false)
      install_generator.instance_variable_set(:@ran_direct_installs, false)
    end

    context "when using package_json gem" do
      before do
        allow(install_generator).to receive(:add_npm_dependencies).and_return(true)
      end

      it "does not run duplicate install commands" do
        # Setup expectation that system should be called only once for the final install
        expect(install_generator).to receive(:system).with("npm", "install").once.and_return(true)

        # Run the dependency setup
        install_generator.send(:setup_js_dependencies)
      end
    end

    context "when falling back to direct npm commands" do
      before do
        allow(install_generator).to receive(:add_npm_dependencies).and_return(false)
      end

      it "does not run the bulk install after direct installs" do
        # Expect individual package installs but no bulk install
        expect(install_generator).to receive(:system).with("npm", "install", anything).at_least(:once).and_return(true)
        expect(install_generator).not_to receive(:system).with("npm", "install")

        # Run the dependency setup
        install_generator.send(:setup_js_dependencies)
      end
    end
  end

  describe "JS dependency method organization" do
    it "uses the shared JsDependencyManager module in base_generator" do
      expect(ReactOnRails::Generators::BaseGenerator.ancestors).to include(ReactOnRails::Generators::JsDependencyManager)
    end

    it "uses the shared JsDependencyManager module in install_generator" do
      expect(ReactOnRails::Generators::InstallGenerator.ancestors).to include(ReactOnRails::Generators::JsDependencyManager)
    end

    it "does not duplicate JS dependency methods between generators" do
      base_generator = ReactOnRails::Generators::BaseGenerator.new
      install_generator = ReactOnRails::Generators::InstallGenerator.new

      # Both should respond to the shared methods
      shared_methods = [:setup_js_dependencies, :add_js_dependencies, :install_js_dependencies]

      shared_methods.each do |method|
        expect(base_generator).to respond_to(method, true)
        expect(install_generator).to respond_to(method, true)
      end

      # The methods should come from the same module
      shared_methods.each do |method|
        base_method = base_generator.method(method)
        install_method = install_generator.method(method)

        expect(base_method.owner).to eq(ReactOnRails::Generators::JsDependencyManager)
        expect(install_method.owner).to eq(ReactOnRails::Generators::JsDependencyManager)
      end
    end
  end
end
# frozen_string_literal: true

require_relative "../support/generator_spec_helper"
require_relative "../support/version_test_helpers"

describe "Message Deduplication", type: :generator do
  include GeneratorSpec::TestCase

  destination File.expand_path("../dummy-for-generators", __dir__)
  tests ReactOnRails::Generators::InstallGenerator

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
      # Mock file reading for webpack config - use call_original first, then specific mock
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with("config/webpack/webpack.config.js").and_return("// mock webpack config")
    end

    context "with non-Redux installation" do
      it "shows the success message exactly once" do
        run_generator_test_with_args(%w[], package_json: true)
        output_text = GeneratorMessages.output.join("\n")

        # Count occurrences of the success message
        success_count = output_text.scan("🎉 React on Rails Successfully Installed!").count
        expect(success_count).to(
          eq(1),
          "Expected success message to appear exactly once, but appeared #{success_count} times"
        )

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
        expect(success_count).to(
          eq(1),
          "Expected success message to appear exactly once with Redux, but appeared #{success_count} times"
        )

        # Ensure post-install message components are present
        expect(output_text).to include("📋 QUICK START:")
        expect(output_text).to include("✨ KEY FEATURES:")

        # The message should be from the Redux generator, containing Redux-specific info
        expect(output_text).to include("HelloWorldApp")
      end
    end
  end

  describe "NPM install execution" do
    let(:install_generator) { ReactOnRails::Generators::InstallGenerator.new }

    before do
      # Mock the system to track NPM install calls
      allow(install_generator).to receive_messages(
        system: true,
        add_npm_dependencies: false,
        destination_root: "/test/path"
      )
      allow(File).to receive(:exist?).and_return(false)
      allow(File).to receive(:exist?).with(a_string_matching(/package\.json$/)).and_return(true)
    end

    context "when using package_json gem (always available via shakapacker)" do
      # rubocop:disable RSpec/VerifiedDoubles
      let(:mock_manager) { double("PackageManager", install: true, add: true) }
      let(:mock_package_json) { double("PackageJson", manager: mock_manager) }
      # rubocop:enable RSpec/VerifiedDoubles

      before do
        # Mock the actual methods used by JsDependencyManager
        # add_npm_dependencies is from GeneratorHelper and is used by add_packages
        # Mock package_json to prevent actual package manager calls
        allow(install_generator).to receive_messages(
          add_npm_dependencies: true,
          package_json: mock_package_json
        )
      end

      it "does not run duplicate install commands" do
        # When package_json gem methods work, it should NOT call system() commands
        expect(install_generator).not_to receive(:system)

        # Run the dependency setup
        install_generator.send(:setup_js_dependencies)

        # Verify package_json.manager.install was called exactly once
        expect(mock_manager).to have_received(:install).once
      end
    end
  end

  describe "JS dependency method organization" do
    it "uses the shared JsDependencyManager module in base_generator" do
      expect(ReactOnRails::Generators::BaseGenerator.ancestors)
        .to include(ReactOnRails::Generators::JsDependencyManager)
    end

    it "uses the shared JsDependencyManager module in install_generator" do
      expect(ReactOnRails::Generators::InstallGenerator.ancestors)
        .to include(ReactOnRails::Generators::JsDependencyManager)
    end

    it "does not duplicate JS dependency methods between generators" do
      base_generator = ReactOnRails::Generators::BaseGenerator.new
      install_generator = ReactOnRails::Generators::InstallGenerator.new

      # Both should respond to the shared methods
      shared_methods = %i[setup_js_dependencies add_js_dependencies install_js_dependencies]

      shared_methods.each do |method|
        expect(base_generator.respond_to?(method, true)).to be(true)
        expect(install_generator.respond_to?(method, true)).to be(true)
        # Verify the methods are defined by the shared module
        expect(ReactOnRails::Generators::BaseGenerator.instance_method(method).owner)
          .to eq(ReactOnRails::Generators::JsDependencyManager)
        expect(ReactOnRails::Generators::InstallGenerator.instance_method(method).owner)
          .to eq(ReactOnRails::Generators::JsDependencyManager)
      end
    end
  end
end

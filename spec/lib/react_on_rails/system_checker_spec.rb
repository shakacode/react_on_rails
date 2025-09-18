# frozen_string_literal: true

require_relative "../../react_on_rails/spec_helper"
require_relative "../../../lib/react_on_rails/system_checker"
RSpec.describe ReactOnRails::SystemChecker do
  let(:checker) { described_class.new }

  describe "#initialize" do
    it "initializes with empty messages" do
      expect(checker.messages).to eq([])
    end
  end

  describe "message management" do
    it "adds error messages" do
      checker.add_error("Test error")
      expect(checker.messages).to include({ type: :error, content: "Test error" })
      expect(checker.errors?).to be true
    end

    it "adds warning messages" do
      checker.add_warning("Test warning")
      expect(checker.messages).to include({ type: :warning, content: "Test warning" })
      expect(checker.warnings?).to be true
    end

    it "adds success messages" do
      checker.add_success("Test success")
      expect(checker.messages).to include({ type: :success, content: "Test success" })
    end

    it "adds info messages" do
      checker.add_info("Test info")
      expect(checker.messages).to include({ type: :info, content: "Test info" })
    end
  end

  describe "#check_node_installation" do
    context "when Node.js is missing" do
      before do
        allow(checker).to receive(:node_missing?).and_return(true)
      end

      it "adds an error message" do
        result = checker.check_node_installation
        expect(result).to be false
        expect(checker.errors?).to be true
        expect(checker.messages.last[:content]).to include("Node.js is required")
      end
    end

    context "when Node.js is installed" do
      before do
        allow(checker).to receive(:node_missing?).and_return(false)
        allow(checker).to receive(:check_node_version)
      end

      it "returns true and checks version" do
        result = checker.check_node_installation
        expect(result).to be true
        expect(checker).to have_received(:check_node_version)
      end
    end
  end

  describe "#check_node_version" do
    context "when Node.js version is too old" do
      before do
        allow(checker).to receive(:`).with("node --version 2>/dev/null").and_return("v16.14.0\n")
      end

      it "adds a warning message" do
        checker.check_node_version
        expect(checker.warnings?).to be true
        expect(checker.messages.last[:content]).to include("Node.js version v16.14.0 detected")
      end
    end

    context "when Node.js version is compatible" do
      before do
        allow(checker).to receive(:`).with("node --version 2>/dev/null").and_return("v18.17.0\n")
      end

      it "adds a success message" do
        checker.check_node_version
        expect(checker.messages.any? do |msg|
                 msg[:type] == :success && msg[:content].include?("Node.js v18.17.0")
               end).to be true
      end
    end

    context "when Node.js version cannot be determined" do
      before do
        allow(checker).to receive(:`).with("node --version 2>/dev/null").and_return("")
      end

      it "does not add any messages" do
        messages_count_before = checker.messages.count
        checker.check_node_version
        expect(checker.messages.count).to eq(messages_count_before)
      end
    end
  end

  describe "#check_package_manager" do
    context "when no package managers are available" do
      before do
        allow(checker).to receive(:cli_exists?).and_return(false)
      end

      it "adds an error message" do
        result = checker.check_package_manager
        expect(result).to be false
        expect(checker.errors?).to be true
        expect(checker.messages.last[:content]).to include("No JavaScript package manager found")
      end
    end

    context "when package managers are available" do
      before do
        allow(checker).to receive(:cli_exists?).with("npm").and_return(true)
        allow(checker).to receive(:cli_exists?).with("yarn").and_return(true)
        allow(checker).to receive(:cli_exists?).with("pnpm").and_return(false)
        allow(checker).to receive(:cli_exists?).with("bun").and_return(false)
      end

      it "adds a success message" do
        result = checker.check_package_manager
        expect(result).to be true
        expect(checker.messages.any? { |msg| msg[:type] == :success && msg[:content].include?("npm, yarn") }).to be true
      end
    end
  end

  describe "#check_shakapacker_configuration" do
    context "when shakapacker is not configured" do
      before do
        allow(checker).to receive(:shakapacker_configured?).and_return(false)
      end

      it "adds an error message" do
        result = checker.check_shakapacker_configuration
        expect(result).to be false
        expect(checker.errors?).to be true
        expect(checker.messages.last[:content]).to include("Shakapacker is not properly configured")
      end
    end

    context "when shakapacker is configured" do
      before do
        allow(checker).to receive(:shakapacker_configured?).and_return(true)
        allow(checker).to receive(:check_shakapacker_in_gemfile)
      end

      it "adds a success message and checks gemfile" do
        result = checker.check_shakapacker_configuration
        expect(result).to be true
        expect(checker.messages.any? do |msg|
                 msg[:type] == :success && msg[:content].include?("Shakapacker is properly configured")
               end).to be true
        expect(checker).to have_received(:check_shakapacker_in_gemfile)
      end
    end
  end

  describe "#check_react_on_rails_gem" do
    context "when gem is loaded" do
      before do
        # Mock the ReactOnRails constant and VERSION
        stub_const("ReactOnRails", Module.new)
        stub_const("ReactOnRails::VERSION", "16.0.0")
      end

      it "adds a success message" do
        checker.check_react_on_rails_gem
        expect(checker.messages.any? do |msg|
                 msg[:type] == :success && msg[:content].include?("React on Rails gem 16.0.0")
               end).to be true
      end
    end

    context "when gem is not available" do
      before do
        allow(checker).to receive(:require).with("react_on_rails").and_raise(LoadError)
      end

      it "adds an error message" do
        checker.check_react_on_rails_gem
        expect(checker.errors?).to be true
        expect(checker.messages.last[:content]).to include("React on Rails gem is not available")
      end
    end
  end

  describe "#check_react_on_rails_npm_package" do
    context "when package.json exists with react-on-rails" do
      let(:package_json_content) do
        { "dependencies" => { "react-on-rails" => "^16.0.0" } }.to_json
      end

      before do
        allow(File).to receive(:exist?).with("package.json").and_return(true)
        allow(File).to receive(:read).with("package.json").and_return(package_json_content)
      end

      it "adds a success message" do
        checker.check_react_on_rails_npm_package
        expect(checker.messages.any? do |msg|
                 msg[:type] == :success && msg[:content].include?("react-on-rails NPM package")
               end).to be true
      end
    end

    context "when package.json exists without react-on-rails" do
      let(:package_json_content) do
        { "dependencies" => { "react" => "^18.0.0" } }.to_json
      end

      before do
        allow(File).to receive(:exist?).with("package.json").and_return(true)
        allow(File).to receive(:read).with("package.json").and_return(package_json_content)
      end

      it "adds a warning message" do
        checker.check_react_on_rails_npm_package
        expect(checker.warnings?).to be true
        expect(checker.messages.last[:content]).to include("react-on-rails NPM package not found")
      end
    end

    context "when package.json does not exist" do
      before do
        allow(File).to receive(:exist?).with("package.json").and_return(false)
      end

      it "does not add any messages" do
        messages_count_before = checker.messages.count
        checker.check_react_on_rails_npm_package
        expect(checker.messages.count).to eq(messages_count_before)
      end
    end
  end

  describe "private methods" do
    describe "#cli_exists?" do
      it "returns true when command exists" do
        allow(checker).to receive(:system).with("which npm > /dev/null 2>&1").and_return(true)
        expect(checker.send(:cli_exists?, "npm")).to be true
      end

      it "returns false when command does not exist" do
        allow(checker).to receive(:system).with("which nonexistent > /dev/null 2>&1").and_return(false)
        expect(checker.send(:cli_exists?, "nonexistent")).to be false
      end
    end

    describe "#shakapacker_configured?" do
      it "returns true when all required files exist" do
        files = [
          "bin/shakapacker",
          "bin/shakapacker-dev-server",
          "config/shakapacker.yml",
          "config/webpack/webpack.config.js"
        ]

        files.each do |file|
          allow(File).to receive(:exist?).with(file).and_return(true)
        end

        expect(checker.send(:shakapacker_configured?)).to be true
      end

      it "returns false when any required file is missing" do
        allow(File).to receive(:exist?).with("bin/shakapacker").and_return(false)
        allow(File).to receive(:exist?).with("bin/shakapacker-dev-server").and_return(true)
        allow(File).to receive(:exist?).with("config/shakapacker.yml").and_return(true)
        allow(File).to receive(:exist?).with("config/webpack/webpack.config.js").and_return(true)

        expect(checker.send(:shakapacker_configured?)).to be false
      end
    end
  end
end

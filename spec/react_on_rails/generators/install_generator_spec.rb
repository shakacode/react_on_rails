# frozen_string_literal: true

require_relative "../support/generator_spec_helper"
require_relative "../support/version_test_helpers"
describe InstallGenerator, type: :generator do
  include GeneratorSpec::TestCase

  destination File.expand_path("../dummy-for-generators", __dir__)

  context "without args" do
    before(:all) { run_generator_test_with_args(%w[], package_json: true) }

    include_examples "base_generator", application_js: true
    include_examples "no_redux_generator"
  end

  context "with --redux" do
    before(:all) { run_generator_test_with_args(%w[--redux], package_json: true) }

    include_examples "base_generator_common", application_js: true
    include_examples "react_with_redux_generator"
  end

  context "with -R" do
    before(:all) { run_generator_test_with_args(%w[-R], package_json: true) }

    include_examples "base_generator_common", application_js: true
    include_examples "react_with_redux_generator"
  end

  context "without existing application.js or application.js.coffee file" do
    before(:all) { run_generator_test_with_args([], application_js: false, package_json: true) }

    include_examples "base_generator", application_js: false
  end

  context "with existing application.js or application.js.coffee file" do
    before(:all) { run_generator_test_with_args([], application_js: true, package_json: true) }

    include_examples "base_generator", application_js: true
  end

  context "with rails_helper" do
    before(:all) { run_generator_test_with_args([], spec: true, package_json: true) }

    it "adds ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)" do
      expected = ReactOnRails::Generators::BaseGenerator::CONFIGURE_RSPEC_TO_COMPILE_ASSETS
      assert_file("spec/rails_helper.rb") { |contents| expect(contents).to match(expected) }
    end
  end

  context "with helpful message" do
    let(:expected) do
      GeneratorMessages.format_info(GeneratorMessages.helpful_message_after_installation)
    end

    specify "base generator contains a helpful message" do
      run_generator_test_with_args(%w[], package_json: true)
      # GeneratorMessages.output is an array with the git error being the first one
      expect(GeneratorMessages.output).to include(expected)
    end

    specify "react with redux generator contains a helpful message" do
      run_generator_test_with_args(%w[--redux], package_json: true)
      # GeneratorMessages.output is an array with the git error being the first one
      expect(GeneratorMessages.output).to include(expected)
    end
  end

  context "when detecting existing bin-files on *nix" do
    let(:install_generator) { described_class.new }

    specify "when node is exist" do
      stub_const("RUBY_PLATFORM", "linux")
      allow(install_generator).to receive(:`).with("which node").and_return("/path/to/bin")
      expect(install_generator.send(:missing_node?)).to be false
    end
  end

  context "when detecting missing bin-files on *nix" do
    let(:install_generator) { described_class.new }

    specify "when node is missing" do
      stub_const("RUBY_PLATFORM", "linux")
      allow(install_generator).to receive(:`).with("which node").and_return("")
      expect(install_generator.send(:missing_node?)).to be true
    end
  end

  context "when detecting existing bin-files on windows" do
    let(:install_generator) { described_class.new }

    specify "when node is exist" do
      stub_const("RUBY_PLATFORM", "mswin")
      allow(install_generator).to receive(:`).with("where node").and_return("/path/to/bin")
      expect(install_generator.send(:missing_node?)).to be false
    end
  end

  context "when detecting missing bin-files on windows" do
    let(:install_generator) { described_class.new }

    specify "when node is missing" do
      stub_const("RUBY_PLATFORM", "mswin")
      allow(install_generator).to receive(:`).with("where node").and_return("")
      expect(install_generator.send(:missing_node?)).to be true
    end
  end

  context "when detecting Shakapacker installation" do
    let(:install_generator) { described_class.new }

    context "when testing shakapacker_installed?" do
      specify "when Shakapacker gem is installed" do
        mock_version = instance_double(Gem::Version, segments: [7, 0, 0])
        mock_gem = instance_double(Gem::Specification, version: mock_version)
        allow(Gem::Specification).to receive(:find_by_name).with("shakapacker").and_return(mock_gem)
        expect(install_generator.send(:shakapacker_installed?)).to be true
      end

      specify "when Shakapacker gem is not installed" do
        allow(Gem::Specification).to receive(:find_by_name).with("shakapacker").and_raise(Gem::MissingSpecError.new(
                                                                                            "gem", "spec"
                                                                                          ))
        expect(install_generator.send(:shakapacker_installed?)).to be false
      end
    end

    context "when testing ensure_shakapacker_installed" do
      specify "when Shakapacker is already installed" do
        allow(install_generator).to receive(:shakapacker_installed?).and_return(true)
        expect(install_generator).not_to receive(:system)
        result = install_generator.send(:ensure_shakapacker_installed)
        expect(result).to be true
      end

      specify "when Shakapacker is not installed and install succeeds" do
        allow(install_generator).to receive(:shakapacker_installed?).and_return(false)
        allow(install_generator).to receive(:system).with("bundle", "add", "shakapacker").and_return(true)
        allow(install_generator).to receive(:system).with("bundle", "exec", "rails", "shakapacker:install").and_return(true)
        expect(GeneratorMessages).to receive(:add_info).with(<<~MSG.strip)
          Shakapacker gem not found in your Gemfile.
          React on Rails requires Shakapacker for webpack integration.
          Adding 'shakapacker' gem to your Gemfile and running installation...
        MSG
        expect(GeneratorMessages).to receive(:add_info).with("Shakapacker installed successfully!")
        result = install_generator.send(:ensure_shakapacker_installed)
        expect(result).to be true
      end

      specify "when Shakapacker is not installed and bundle add fails" do
        allow(install_generator).to receive(:shakapacker_installed?).and_return(false)
        allow(install_generator).to receive(:system).with("bundle", "add", "shakapacker").and_return(false)
        expect(GeneratorMessages).to receive(:add_info).with(<<~MSG.strip)
          Shakapacker gem not found in your Gemfile.
          React on Rails requires Shakapacker for webpack integration.
          Adding 'shakapacker' gem to your Gemfile and running installation...
        MSG
        expect(GeneratorMessages).to receive(:add_error).with(<<~MSG.strip)
          Failed to add Shakapacker to your Gemfile.
          Please run 'bundle add shakapacker' manually and re-run the generator.
        MSG
        result = install_generator.send(:ensure_shakapacker_installed)
        expect(result).to be false
      end

      specify "when Shakapacker is not installed and shakapacker:install fails" do
        allow(install_generator).to receive(:shakapacker_installed?).and_return(false)
        allow(install_generator).to receive(:system).with("bundle", "add", "shakapacker").and_return(true)
        allow(install_generator).to receive(:system).with("bundle", "exec", "rails", "shakapacker:install").and_return(false)
        expect(GeneratorMessages).to receive(:add_info).with(<<~MSG.strip)
          Shakapacker gem not found in your Gemfile.
          React on Rails requires Shakapacker for webpack integration.
          Adding 'shakapacker' gem to your Gemfile and running installation...
        MSG
        expect(GeneratorMessages).to receive(:add_error).with(<<~MSG.strip)
          Failed to install Shakapacker automatically.
          Please run 'bundle exec rails shakapacker:install' manually.
        MSG
        result = install_generator.send(:ensure_shakapacker_installed)
        expect(result).to be false
      end
    end
  end
end

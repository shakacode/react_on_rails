# frozen_string_literal: true

require_relative "../support/generator_spec_helper"
require_relative "../support/version_test_helpers"
describe InstallGenerator, type: :generator do
  include GeneratorSpec::TestCase

  destination File.expand_path("../../dummy-for-generators/", __FILE__)

  context "no args" do
    before(:all) { run_generator_test_with_args(%w[]) }
    include_examples "base_generator", application_js: true
    include_examples "no_redux_generator"
  end

  context "--redux" do
    before(:all) { run_generator_test_with_args(%w[--redux]) }
    include_examples "base_generator", application_js: true
    include_examples "react_with_redux_generator"
  end

  context "-R" do
    before(:all) { run_generator_test_with_args(%w[-R]) }
    include_examples "base_generator", application_js: true
    include_examples "react_with_redux_generator"
  end

  context "without existing application.js or application.js.coffee file" do
    before(:all) { run_generator_test_with_args([], application_js: false) }
    include_examples "base_generator", application_js: false
  end

  context "with existing application.js or application.js.coffee file" do
    before(:all) { run_generator_test_with_args([], application_js: true) }
    include_examples "base_generator", application_js: true
  end

  context "with rails_helper" do
    before(:all) { run_generator_test_with_args([], spec: true) }
    it "adds ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)" do
      expected = ReactOnRails::Generators::BaseGenerator::CONFIGURE_RSPEC_TO_COMPILE_ASSETS
      assert_file("spec/rails_helper.rb") { |contents| assert_match(expected, contents) }
    end
  end

  context "with helpful message" do
    let(:expected) do
      GeneratorMessages.format_info(ReactOnRails::Generators::BaseGenerator.helpful_message)
    end

    specify "base generator contains a helpful message" do
      run_generator_test_with_args(%w[])
      # GeneratorMessages.output is an array with the git error being the first one
      expect(GeneratorMessages.output).to include(expected)
    end

    specify "react with redux generator contains a helpful message" do
      run_generator_test_with_args(%w[--redux])
      # GeneratorMessages.output is an array with the git error being the first one
      expect(GeneratorMessages.output).to include(expected)
    end
  end

  context "detect existing bin-files on *nix" do
    before(:all) { @install_generator = InstallGenerator.new }

    specify "when node is exist" do
      stub_const("RUBY_PLATFORM", "linux")
      allow(@install_generator).to receive(:`).with("which node").and_return("/path/to/bin")
      expect(@install_generator.send(:missing_node?)).to eq false
    end

    specify "when npm is exist" do
      stub_const("RUBY_PLATFORM", "linux")
      allow(@install_generator).to receive(:`).with("which yarn").and_return("/path/to/bin")
      expect(@install_generator.send(:missing_yarn?)).to eq false
    end
  end

  context "detect missing bin-files on *nix" do
    before(:all) { @install_generator = InstallGenerator.new }

    specify "when node is missing" do
      stub_const("RUBY_PLATFORM", "linux")
      allow(@install_generator).to receive(:`).with("which node").and_return("")
      expect(@install_generator.send(:missing_node?)).to eq true
    end

    specify "when npm is missing" do
      stub_const("RUBY_PLATFORM", "linux")
      allow(@install_generator).to receive(:`).with("which yarn").and_return("")
      expect(@install_generator.send(:missing_yarn?)).to eq true
    end
  end

  context "detect existing bin-files on windows" do
    before(:all) { @install_generator = InstallGenerator.new }

    specify "when node is exist" do
      stub_const("RUBY_PLATFORM", "mswin")
      allow(@install_generator).to receive(:`).with("where node").and_return("/path/to/bin")
      expect(@install_generator.send(:missing_node?)).to eq false
    end

    specify "when npm is exist" do
      stub_const("RUBY_PLATFORM", "mswin")
      allow(@install_generator).to receive(:`).with("where yarn").and_return("/path/to/bin")
      expect(@install_generator.send(:missing_yarn?)).to eq false
    end
  end

  context "detect missing bin-files on windows" do
    before(:all) { @install_generator = InstallGenerator.new }

    specify "when node is missing" do
      stub_const("RUBY_PLATFORM", "mswin")
      allow(@install_generator).to receive(:`).with("where node").and_return("")
      expect(@install_generator.send(:missing_node?)).to eq true
    end

    specify "when yarn is missing" do
      stub_const("RUBY_PLATFORM", "mswin")
      allow(@install_generator).to receive(:`).with("where yarn").and_return("")
      expect(@install_generator.send(:missing_yarn?)).to eq true
    end
  end
end

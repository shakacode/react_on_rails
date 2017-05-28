require_relative "../support/generator_spec_helper"
require_relative "../support/version_test_helpers"

# rubocop:disable Metrics/BlockLength
describe InstallGenerator, type: :generator do
  destination File.expand_path("../../dummy-for-generators/", __FILE__)

  context "no args" do
    before(:all) { run_generator_test_with_args(%w()) }
    include_examples "base_generator", application_js: true
    include_examples "no_redux_generator"
  end

  context "--redux" do
    before(:all) { run_generator_test_with_args(%w(--redux)) }
    include_examples "base_generator", application_js: true
    include_examples "react_with_redux_generator"
  end

  context "-R" do
    before(:all) { run_generator_test_with_args(%w(-R)) }
    include_examples "base_generator", application_js: true
    include_examples "react_with_redux_generator"
  end

  context "--node" do
    before(:all) { run_generator_test_with_args(%w(--node)) }
    include_examples "base_generator", application_js: true
    include_examples "node_generator"
  end

  context "-N" do
    before(:all) { run_generator_test_with_args(%w(-N)) }
    include_examples "base_generator", application_js: true
    include_examples "node_generator"
  end

  context "without existing application.js or application.js.coffee file" do
    before(:all) { run_generator_test_with_args([], application_js: false) }
    include_examples "base_generator", application_js: false
  end

  context "with existing application.js or application.js.coffee file" do
    before(:all) { run_generator_test_with_args([], application_js: true) }
    include_examples "base_generator", application_js: true
  end

  context "without existing assets.rb file" do
    before(:all) { run_generator_test_with_args([], assets_rb: false) }
    include_examples "base_generator", assets_rb: false
  end

  context "with existing assets.rb file" do
    before(:all) { run_generator_test_with_args([], assets_rb: true) }
    include_examples "base_generator", assets_rb: true
  end

  context "with rails_helper" do
    before(:all) { run_generator_test_with_args([], spec: true) }
    it "adds ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)" do
      expected = ReactOnRails::Generators::BaseGenerator::CONFIGURE_RSPEC_TO_COMPILE_ASSETS
      assert_file("spec/rails_helper.rb") { |contents| assert_match(expected, contents) }
    end
  end

  context "with missing files to trigger errors" do
    specify "GeneratorMessages has the missing file error" do
      run_generator_test_with_args([], gitignore: false)
      expected = <<-MSG.strip_heredoc
        .gitignore was not found.
        Please add the following content to your .gitignore file:
        # React on Rails
        npm-debug.log*
        node_modules

        # Generated js bundles
        /public/webpack/*

        MSG
      expect(GeneratorMessages.output)
        .to include(GeneratorMessages.format_error(expected))
    end
  end

  context "with helpful message" do
    let(:expected) do
      <<-MSG.strip_heredoc

        What to do next:

          - Include your webpack assets to your application layout.

            <%= javascript_pack_tag 'main' %>

          - Ensure your bundle and yarn installs of dependencies are up to date.

              bundle && yarn

          - Run the foreman command to start the rails server and run webpack in watch mode.

              foreman start -f Procfile.dev

          - Visit http://localhost:3000/hello_world and see your React On Rails app running!
      MSG
    end

    specify "base generator contains a helpful message" do
      run_generator_test_with_args(%w())
      expect(GeneratorMessages.output)
        .to include(GeneratorMessages.format_info(expected))
    end

    specify "react with redux generator contains a helpful message" do
      run_generator_test_with_args(%w(--redux))
      expected = <<-MSG.strip_heredoc

        What to do next:

          - Include your webpack assets to your application layout.

            <%= javascript_pack_tag 'main' %>

          - Ensure your bundle and yarn installs of dependencies are up to date.

              bundle && yarn

          - Run the foreman command to start the rails server and run webpack in watch mode.

              foreman start -f Procfile.dev

          - Visit http://localhost:3000/hello_world and see your React On Rails app running!
      MSG
      expect(GeneratorMessages.output)
        .to include(GeneratorMessages.format_info(expected))
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

  context "when package.json already exists" do
    before(:all) { @install_generator = InstallGenerator.new }

    specify "it adds the script section if missing" do
      data = <<-DATA
{
  "dependencies": {}
}
DATA

      run_generator_test_with_args(%w()) do
        simulate_existing_file("package.json", data)
      end

      assert_file("package.json") do |contents|
        parsed = JSON.parse(contents)
        assert(parsed["scripts"]["postinstall"])
      end
    end

    specify "it adds the postinstall script to the script section" do
      data = <<-DATA
{
  "scripts": {
    "foo": "bar"
  },
  "dependencies": {
  }
}
      DATA

      run_generator_test_with_args(%w()) do
        simulate_existing_file("package.json", data)
      end

      assert_file("package.json") do |contents|
        parsed = JSON.parse(contents)
        assert(parsed["scripts"]["postinstall"])
      end
    end
  end
end

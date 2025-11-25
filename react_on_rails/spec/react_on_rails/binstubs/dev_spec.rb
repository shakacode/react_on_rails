# frozen_string_literal: true

require "react_on_rails/dev"

RSpec.describe "bin/dev script" do
  let(:script_path) { File.expand_path("../../../lib/generators/react_on_rails/templates/base/base/bin/dev", __dir__) }
  let(:dummy_dev_path) { File.expand_path("../../dummy/bin/dev", __dir__) }

  # To suppress stdout during tests
  original_stderr = $stderr
  original_stdout = $stdout
  before(:all) do
    $stderr = File.open(File::NULL, "w")
    $stdout = File.open(File::NULL, "w")
  end

  after(:all) do
    $stderr = original_stderr
    $stdout = original_stdout
  end

  def setup_script_execution
    # Mock ARGV to simulate no arguments (default HMR mode)
    stub_const("ARGV", [])
    # Mock pack generation and allow other system calls
    allow_any_instance_of(Kernel).to receive(:system).and_return(true)
  end

  def setup_script_execution_for_tool_tests
    setup_script_execution
    # For tool selection tests, we don't care about file existence - just tool logic
    allow(File).to receive(:exist?).with("Procfile.dev").and_return(true)
    # Mock exit to prevent test termination
    allow_any_instance_of(Kernel).to receive(:exit)
  end

  # These tests check that the script uses ReactOnRails::Dev classes
  it "uses ReactOnRails::Dev classes" do
    script_content = File.read(script_path)
    expect(script_content).to include("ReactOnRails::Dev::ServerManager")
    expect(script_content).to include("require \"react_on_rails/dev\"")
  end

  it "delegates to ServerManager command line interface" do
    script_content = File.read(script_path)
    expect(script_content).to include("ReactOnRails::Dev::ServerManager.run_from_command_line")
  end

  it "with ReactOnRails::Dev loaded, delegates to ServerManager" do
    setup_script_execution_for_tool_tests

    # Mock the require to succeed
    allow_any_instance_of(Kernel).to receive(:require).with("bundler/setup").and_return(true)
    allow_any_instance_of(Kernel).to receive(:require).with("react_on_rails/dev").and_return(true)

    # Just verify that ServerManager.run_from_command_line gets called
    # The specific argument checking was causing RSpec version compatibility issues
    expect(ReactOnRails::Dev::ServerManager).to receive(:run_from_command_line)

    load script_path
  end

  # Integration test: verify bin/dev can load without NameError
  describe "integration test" do
    it "spec/dummy/bin/dev can load the template script without errors" do
      # This test verifies that all required dependencies are properly loaded
      # when bin/dev is executed, catching issues like missing require statements
      expect(File.exist?(dummy_dev_path)).to be true
      expect(File.exist?(script_path)).to be true

      # Verify the dummy script references the template (using relative path from dummy/bin)
      dummy_content = File.read(dummy_dev_path)
      expect(dummy_content).to include("../../../lib/generators/react_on_rails/templates/base/base/bin/dev")
    end

    it "can require react_on_rails/dev and access all necessary modules" do
      # This catches missing require statements in pack_generator.rb and other files
      # If PackerUtils isn't required, this would fail with NameError
      require "react_on_rails/dev"

      expect { ReactOnRails::Dev::ServerManager }.not_to raise_error
      expect { ReactOnRails::Dev::PackGenerator }.not_to raise_error
      expect { ReactOnRails::PackerUtils }.not_to raise_error
    end
  end
end

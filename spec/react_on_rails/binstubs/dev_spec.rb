# frozen_string_literal: true

require "react_on_rails/dev"

RSpec.describe "bin/dev script" do
  let(:script_path) { "lib/generators/react_on_rails/bin/dev" }

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

  it "supports static development mode" do
    script_content = File.read(script_path)
    expect(script_content).to include("ReactOnRails::Dev::ServerManager.start(:static")
  end

  it "supports production-like mode" do
    script_content = File.read(script_path)
    expect(script_content).to include("ReactOnRails::Dev::ServerManager.start(:production_like")
  end

  it "supports help command" do
    script_content = File.read(script_path)
    expect(script_content).to include('when "help", "--help", "-h"')
    expect(script_content).to include("ReactOnRails::Dev::ServerManager.show_help")
  end

  it "supports kill command" do
    script_content = File.read(script_path)
    expect(script_content).to include("ReactOnRails::Dev::ServerManager.kill_processes")
  end

  it "with ReactOnRails::Dev loaded, delegates to ServerManager" do
    setup_script_execution_for_tool_tests
    allow(ReactOnRails::Dev::ServerManager).to receive(:start)

    # Mock the require to succeed
    allow_any_instance_of(Kernel).to receive(:require).with("bundler/setup").and_return(true)
    allow_any_instance_of(Kernel).to receive(:require).with("react_on_rails/dev").and_return(true)

    expect(ReactOnRails::Dev::ServerManager).to receive(:start).with(:development, "Procfile.dev", verbose: false)

    load script_path
  end
end

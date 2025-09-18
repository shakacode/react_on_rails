# frozen_string_literal: true

require_relative "../spec_helper"
require "react_on_rails/dev/server_manager"
require "open3"

RSpec.describe ReactOnRails::Dev::ServerManager do
  # Suppress stdout/stderr during tests
  before(:all) do
    @original_stderr = $stderr
    @original_stdout = $stdout
    $stderr = File.open(File::NULL, "w")
    $stdout = File.open(File::NULL, "w")
  end

  after(:all) do
    $stderr = @original_stderr
    $stdout = @original_stdout
  end

  def mock_system_calls
    allow(ReactOnRails::Dev::PackGenerator).to receive(:generate).with(any_args)
    allow_any_instance_of(Kernel).to receive(:system).and_return(true)
    allow_any_instance_of(Kernel).to receive(:exit)
    allow(ReactOnRails::Dev::ProcessManager).to receive(:ensure_procfile)
    allow(ReactOnRails::Dev::ProcessManager).to receive(:run_with_process_manager)
  end

  describe ".start" do
    before { mock_system_calls }

    it "starts development mode by default" do
      expect(ReactOnRails::Dev::PackGenerator).to receive(:generate)
      expect(ReactOnRails::Dev::ProcessManager).to receive(:ensure_procfile).with("Procfile.dev")
      expect(ReactOnRails::Dev::ProcessManager).to receive(:run_with_process_manager).with("Procfile.dev")

      described_class.start(:development)
    end

    it "starts HMR mode same as development" do
      expect(ReactOnRails::Dev::PackGenerator).to receive(:generate)
      expect(ReactOnRails::Dev::ProcessManager).to receive(:ensure_procfile).with("Procfile.dev")
      expect(ReactOnRails::Dev::ProcessManager).to receive(:run_with_process_manager).with("Procfile.dev")

      described_class.start(:hmr)
    end

    it "starts static development mode" do
      expect(ReactOnRails::Dev::PackGenerator).to receive(:generate)
      expect(ReactOnRails::Dev::ProcessManager).to receive(:ensure_procfile).with("Procfile.dev-static-assets")
      expect(ReactOnRails::Dev::ProcessManager).to receive(:run_with_process_manager).with("Procfile.dev-static-assets")

      described_class.start(:static)
    end

    it "starts production-like mode" do
      command = "NODE_ENV=production bundle exec rails assets:precompile"
      status_double = instance_double(Process::Status, success?: true)
      expect(Open3).to receive(:capture3).with(command).and_return(["output", "", status_double])
      expect(ReactOnRails::Dev::ProcessManager).to receive(:ensure_procfile).with("Procfile.dev-prod-assets")
      expect(ReactOnRails::Dev::ProcessManager).to receive(:run_with_process_manager).with("Procfile.dev-prod-assets")

      described_class.start(:production_like)
    end

    it "raises error for unknown mode" do
      expect { described_class.start(:unknown) }.to raise_error(ArgumentError, "Unknown mode: unknown")
    end
  end

  describe ".kill_processes" do
    before do
      allow_any_instance_of(Kernel).to receive(:`).and_return("")
      allow(File).to receive(:exist?).and_return(false)
    end

    it "attempts to kill development processes" do
      # Mock Open3.capture2 calls that find_process_pids uses
      allow(Open3).to receive(:capture2).with("pgrep", "-f", "rails", err: File::NULL).and_return(["1234\n5678", nil])
      allow(Open3).to receive(:capture2)
        .with("pgrep", "-f", "node.*react[-_]on[-_]rails", err: File::NULL)
        .and_return(["2345", nil])
      allow(Open3).to receive(:capture2).with("pgrep", "-f", "overmind", err: File::NULL).and_return(["", nil])
      allow(Open3).to receive(:capture2).with("pgrep", "-f", "foreman", err: File::NULL).and_return(["", nil])
      allow(Open3).to receive(:capture2).with("pgrep", "-f", "ruby.*puma", err: File::NULL).and_return(["", nil])
      allow(Open3).to receive(:capture2)
        .with("pgrep", "-f", "webpack-dev-server", err: File::NULL).and_return(["", nil])
      allow(Open3).to receive(:capture2)
        .with("pgrep", "-f", "bin/shakapacker-dev-server", err: File::NULL).and_return(["", nil])

      allow(Process).to receive(:pid).and_return(9999) # Current process PID
      expect(Process).to receive(:kill).with("TERM", 1234)
      expect(Process).to receive(:kill).with("TERM", 5678)
      expect(Process).to receive(:kill).with("TERM", 2345)

      described_class.kill_processes
    end

    it "cleans up socket files when they exist" do
      # Make sure no processes are found so cleanup_socket_files gets called
      allow(Open3).to receive(:capture2).and_return(["", nil])

      allow(File).to receive(:exist?).with(".overmind.sock").and_return(true)
      allow(File).to receive(:exist?).with("tmp/sockets/overmind.sock").and_return(false)
      allow(File).to receive(:exist?).with("tmp/pids/server.pid").and_return(false)
      expect(File).to receive(:delete).with(".overmind.sock")

      described_class.kill_processes
    end
  end

  describe ".show_help" do
    it "displays help information" do
      expect { described_class.show_help }.to output(%r{Usage: bin/dev \[command\]}).to_stdout_from_any_process
    end
  end
end

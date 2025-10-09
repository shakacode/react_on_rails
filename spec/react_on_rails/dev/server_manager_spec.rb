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
      env = { "NODE_ENV" => "production" }
      argv = ["bundle", "exec", "rails", "assets:precompile"]
      status_double = instance_double(Process::Status, success?: true)
      expect(Open3).to receive(:capture3).with(env, *argv).and_return(["output", "", status_double])
      expect(ReactOnRails::Dev::ProcessManager).to receive(:ensure_procfile).with("Procfile.dev-prod-assets")
      expect(ReactOnRails::Dev::ProcessManager).to receive(:run_with_process_manager).with("Procfile.dev-prod-assets")

      described_class.start(:production_like)
    end

    it "starts production-like mode with custom rails_env" do
      env = { "NODE_ENV" => "production", "RAILS_ENV" => "staging" }
      argv = ["bundle", "exec", "rails", "assets:precompile"]
      status_double = instance_double(Process::Status, success?: true)
      expect(Open3).to receive(:capture3).with(env, *argv).and_return(["output", "", status_double])
      expect(ReactOnRails::Dev::ProcessManager).to receive(:ensure_procfile).with("Procfile.dev-prod-assets")
      expect(ReactOnRails::Dev::ProcessManager).to receive(:run_with_process_manager).with("Procfile.dev-prod-assets")

      described_class.start(:production_like, nil, verbose: false, rails_env: "staging")
    end

    it "rejects invalid rails_env with shell injection characters" do
      expect_any_instance_of(Kernel).to receive(:exit).with(1)
      allow_any_instance_of(Kernel).to receive(:puts) # Allow other puts calls
      error_pattern = /Invalid rails_env.*Must contain only letters, numbers, and underscores/
      expect_any_instance_of(Kernel).to receive(:puts).with(error_pattern)

      described_class.start(:production_like, nil, verbose: false, rails_env: "production; rm -rf /")
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

      # Mock lsof calls for port checking
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3000", err: File::NULL).and_return(["", nil])
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3001", err: File::NULL).and_return(["", nil])

      allow(Process).to receive(:pid).and_return(9999) # Current process PID
      expect(Process).to receive(:kill).with("TERM", 1234)
      expect(Process).to receive(:kill).with("TERM", 5678)
      expect(Process).to receive(:kill).with("TERM", 2345)

      described_class.kill_processes
    end

    it "kills processes on ports 3000 and 3001" do
      # No pattern-based processes
      allow(Open3).to receive(:capture2).with("pgrep", any_args).and_return(["", nil])

      # Mock port processes
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3000", err: File::NULL).and_return(["3456", nil])
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3001", err: File::NULL).and_return(["3457\n3458", nil])

      allow(Process).to receive(:pid).and_return(9999)
      expect(Process).to receive(:kill).with("TERM", 3456)
      expect(Process).to receive(:kill).with("TERM", 3457)
      expect(Process).to receive(:kill).with("TERM", 3458)

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

  describe ".find_port_pids" do
    it "finds PIDs listening on a specific port" do
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3000", err: File::NULL).and_return(["1234\n5678", nil])
      allow(Process).to receive(:pid).and_return(9999)

      pids = described_class.find_port_pids(3000)
      expect(pids).to eq([1234, 5678])
    end

    it "excludes current process PID" do
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3000", err: File::NULL).and_return(["1234\n9999", nil])
      allow(Process).to receive(:pid).and_return(9999)

      pids = described_class.find_port_pids(3000)
      expect(pids).to eq([1234])
    end

    it "returns empty array when lsof is not found" do
      allow(Open3).to receive(:capture2).and_raise(Errno::ENOENT)

      pids = described_class.find_port_pids(3000)
      expect(pids).to eq([])
    end

    it "returns empty array on permission denied" do
      allow(Open3).to receive(:capture2).and_raise(Errno::EACCES)

      pids = described_class.find_port_pids(3000)
      expect(pids).to eq([])
    end
  end

  describe ".kill_port_processes" do
    it "kills processes on specified ports" do
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3000", err: File::NULL).and_return(["1234", nil])
      allow(Open3).to receive(:capture2).with("lsof", "-ti", ":3001", err: File::NULL).and_return(["5678", nil])
      allow(Process).to receive(:pid).and_return(9999)

      expect(Process).to receive(:kill).with("TERM", 1234)
      expect(Process).to receive(:kill).with("TERM", 5678)

      result = described_class.kill_port_processes([3000, 3001])
      expect(result).to be true
    end

    it "returns false when no processes found on ports" do
      allow(Open3).to receive(:capture2).and_return(["", nil])

      result = described_class.kill_port_processes([3000, 3001])
      expect(result).to be false
    end
  end

  describe ".terminate_processes" do
    it "successfully kills processes" do
      pids = [1234, 5678]
      expect(Process).to receive(:kill).with("TERM", 1234)
      expect(Process).to receive(:kill).with("TERM", 5678)

      described_class.terminate_processes(pids)
    end

    it "handles ESRCH (process not found) silently" do
      pids = [1234]
      allow(Process).to receive(:kill).with("TERM", 1234).and_raise(Errno::ESRCH)

      # Should not raise an error and should not output anything
      expect { described_class.terminate_processes(pids) }.not_to raise_error
    end

    it "handles EPERM (permission denied) with warning" do
      pids = [1234]
      allow(Process).to receive(:kill).with("TERM", 1234).and_raise(Errno::EPERM)

      # Should not raise an error but should output a warning
      expect { described_class.terminate_processes(pids) }.to output(/permission denied/).to_stdout_from_any_process
    end

    it "handles mixed success and ESRCH" do
      pids = [1234, 5678]
      expect(Process).to receive(:kill).with("TERM", 1234)
      allow(Process).to receive(:kill).with("TERM", 5678).and_raise(Errno::ESRCH)

      expect { described_class.terminate_processes(pids) }.not_to raise_error
    end

    it "handles mixed success and EPERM" do
      pids = [1234, 5678]
      expect(Process).to receive(:kill).with("TERM", 1234)
      allow(Process).to receive(:kill).with("TERM", 5678).and_raise(Errno::EPERM)

      expect do
        described_class.terminate_processes(pids)
      end.to output(/5678.*permission denied/).to_stdout_from_any_process
    end

    it "handles ArgumentError (invalid signal)" do
      pids = [1234]
      allow(Process).to receive(:kill).with("TERM", 1234).and_raise(ArgumentError)

      # Should not raise an error
      expect { described_class.terminate_processes(pids) }.not_to raise_error
    end

    it "handles RangeError (invalid PID)" do
      pids = [999_999_999_999]
      allow(Process).to receive(:kill).with("TERM", 999_999_999_999).and_raise(RangeError)

      # Should not raise an error
      expect { described_class.terminate_processes(pids) }.not_to raise_error
    end
  end

  describe ".show_help" do
    it "displays help information" do
      expect { described_class.show_help }.to output(%r{Usage: bin/dev \[command\]}).to_stdout_from_any_process
    end
  end
end

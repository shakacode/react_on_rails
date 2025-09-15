# frozen_string_literal: true

require_relative "../spec_helper"

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
    allow(ReactOnRails::Dev::PackGenerator).to receive(:generate)
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
      expect(ReactOnRails::Dev::PackGenerator).to receive(:generate)
      expect_any_instance_of(Kernel).to receive(:system).with("RAILS_ENV=production NODE_ENV=production bundle exec rails assets:precompile")
      allow($CHILD_STATUS).to receive(:success?).and_return(true)
      expect_any_instance_of(Kernel).to receive(:system).with("RAILS_ENV=production bundle exec rails server -p 3001")

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
      # Mock some running processes
      allow_any_instance_of(Kernel).to receive(:`).with("pgrep -f \"rails\" 2>/dev/null").and_return("1234\n5678")
      allow(Process).to receive(:pid).and_return(9999) # Current process PID
      expect(Process).to receive(:kill).with("TERM", 1234)
      expect(Process).to receive(:kill).with("TERM", 5678)

      described_class.kill_processes
    end

    it "cleans up socket files when they exist" do
      allow(File).to receive(:exist?).with(".overmind.sock").and_return(true)
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

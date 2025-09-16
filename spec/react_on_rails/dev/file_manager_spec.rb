# frozen_string_literal: true

require_relative "../spec_helper"
require "react_on_rails/dev/file_manager"

RSpec.describe ReactOnRails::Dev::FileManager do
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

  describe ".cleanup_stale_files" do
    before do
      allow(Kernel).to receive(:`).and_return("")
    end

    context "when overmind is not running" do
      before do
        allow(Kernel).to receive(:`).with("pgrep -f \"overmind\" 2>/dev/null").and_return("")
      end

      it "removes stale overmind socket files" do
        # Setup File.exist? stubs for all expected calls
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(".overmind.sock").and_return(true)
        allow(File).to receive(:exist?).with("tmp/sockets/overmind.sock").and_return(false)
        allow(File).to receive(:exist?).with("tmp/pids/server.pid").and_return(false)

        # Setup File.delete stub to prevent actual file deletion and return success
        allow(File).to receive(:delete).with(".overmind.sock").and_return(1)

        # Stub puts method to prevent output during test
        allow_any_instance_of(Object).to receive(:puts)

        result = described_class.cleanup_stale_files
        expect(result).to be_truthy  # Accept any truthy value
      end

      it "does not remove socket files when they don't exist" do
        allow(File).to receive(:exist?).and_return(false)

        result = described_class.cleanup_stale_files
        expect(result).to be false
      end
    end

    context "when overmind is running" do
      before do
        allow(Kernel).to receive(:`).with("pgrep -f \"overmind\" 2>/dev/null").and_return("1234")
        allow(File).to receive(:exist?).and_return(false)
      end

      it "does not remove socket files when overmind is running" do
        expect(File).not_to receive(:delete)

        result = described_class.cleanup_stale_files
        expect(result).to be false
      end
    end

    context "when Rails server pid file exists" do
      before do
        allow(Kernel).to receive(:`).with("pgrep -f \"overmind\" 2>/dev/null").and_return("")
        allow(File).to receive(:exist?).with(".overmind.sock").and_return(false)
        allow(File).to receive(:exist?).with("tmp/sockets/overmind.sock").and_return(false)
        allow(File).to receive(:exist?).with("tmp/pids/server.pid").and_return(true)
        allow(File).to receive(:read).with("tmp/pids/server.pid").and_return("1234")
      end

      it "removes stale pid file when process is not running" do
        allow(Process).to receive(:kill).with(0, 1234).and_raise(Errno::ESRCH)
        expect(File).to receive(:delete).with("tmp/pids/server.pid")

        result = described_class.cleanup_stale_files
        expect(result).to be true
      end

      it "does not remove pid file when process is running" do
        allow(Process).to receive(:kill).with(0, 1234).and_return(true)
        expect(File).not_to receive(:delete).with("tmp/pids/server.pid")

        result = described_class.cleanup_stale_files
        expect(result).to be false
      end
    end
  end
end

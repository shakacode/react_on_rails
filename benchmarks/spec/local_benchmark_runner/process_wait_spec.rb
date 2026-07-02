# frozen_string_literal: true

require_relative "../../lib/local_benchmark_runner/process_wait"

RSpec.describe LocalBenchmarkRunner::ProcessWait do
  describe ".wait_for_port" do
    it "fails fast when a direct child exits before opening the port" do
      pid = Process.spawn("sh", "-c", "exit 42")
      sleep 0.05

      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      expect do
        described_class.wait_for_port(pid, 65_530, "Rails server", timeout: 2, sleep_interval: 0.01)
      end.to raise_error(RuntimeError, /Rails server \(pid #{pid}\) exited during startup .*exit 42/)
      expect(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).to be < 0.5
    ensure
      begin
        Process.wait(pid, Process::WNOHANG) if pid
      rescue Errno::ECHILD
        nil
      end
    end

    it "accepts an open port when the wrapper process has already exited" do
      server = TCPServer.new("localhost", 0)
      pid = Process.spawn("sh", "-c", "exit 0")
      sleep 0.05

      expect do
        described_class.wait_for_port(pid, server.addr[1], "Rails server", timeout: 2, sleep_interval: 0.01)
      end.not_to raise_error
    ensure
      server&.close
      begin
        Process.wait(pid, Process::WNOHANG) if pid
      rescue Errno::ECHILD
        nil
      end
    end

    it "treats timeout as elapsed seconds when polling faster than once per second" do
      pid = Process.spawn("sh", "-c", "sleep 1")

      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      expect do
        described_class.wait_for_port(pid, 65_531, "Rails server", timeout: 0.05, sleep_interval: 0.01)
      end.to raise_error(RuntimeError, "Rails server failed to start within 0.05s")
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
      expect(elapsed).to be >= 0.05
      expect(elapsed).to be < 0.5
    ensure
      if pid
        begin
          Process.kill("TERM", pid)
        rescue Errno::ESRCH
          nil
        end
        begin
          Process.wait(pid)
        rescue Errno::ECHILD
          nil
        end
      end
    end
  end
end

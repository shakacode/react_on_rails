# frozen_string_literal: true

require "socket"

module LocalBenchmarkRunner
  module ProcessWait
    ALREADY_REAPED = :already_reaped

    module_function

    def wait_for_port(pid, port, label, timeout:, sleep_interval: 1)
      attempt = 0
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
      loop do
        if (status = reap_if_exited(pid))
          raise "#{label} (pid #{pid}) exited during startup#{exit_detail(status)}"
        end
        return if port_open?(port)

        remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
        raise "#{label} failed to start within #{timeout}s" if remaining <= 0

        attempt += 1
        puts "  attempt #{attempt}: #{label} (port #{port}) not ready yet (timeout #{timeout}s)..."
        sleep [sleep_interval, remaining].min
      end
    end

    def port_open?(port)
      TCPSocket.new("localhost", port).close
      true
    rescue StandardError
      false
    end

    def reap_if_exited(pid)
      _, status = Process.waitpid2(pid, Process::WNOHANG)
      status
    rescue Errno::ECHILD
      ALREADY_REAPED
    end

    def exit_detail(status)
      case status
      when Process::Status
        " (#{status})"
      when ALREADY_REAPED
        " (already reaped)"
      else
        ""
      end
    end
  end
end

# frozen_string_literal: true

require "fileutils"

# Guards benchmark payload writes against target process failures that happen
# after the benchmark script starts measuring but before Bencher receives data.
class BenchmarkTargetMonitor
  class MonitorFailure < StandardError; end

  STARTUP_LOG_FILENAME = "target_startup_before_benchmark.log"
  UNEXPECTED_WORKER_RESTART = "died UNEXPECTEDLY"
  BLANK_CHUNK_SIZE = 8 * 1024

  def self.from_env(output_dir:, env: ENV)
    new(
      target_pid: env["TARGET_PID"],
      target_log: env["TARGET_LOG"],
      output_dir: output_dir
    )
  end

  def self.pid_alive?(pid)
    Process.kill(0, pid)
    true
  rescue Errno::EPERM
    true
  rescue Errno::ESRCH
    false
  end

  def initialize(target_pid: nil, target_log: nil, output_dir: nil, pid_alive: nil)
    @target_pid = present_string(target_pid)
    @target_log = present_string(target_log)
    @output_dir = output_dir
    @pid_alive = pid_alive || ->(pid) { self.class.pid_alive?(pid) }
  end

  def start_measurement!
    preserve_and_blank_target_log if target_log?
  end

  def verify_after_measurement!
    verify_target_pid!
    verify_unexpected_worker_log!
    true
  end

  private

  def present_string(value)
    value = value.to_s
    value.empty? ? nil : value
  end

  def target_log?
    @target_log && File.file?(@target_log)
  end

  def preserve_and_blank_target_log
    FileUtils.mkdir_p(@output_dir) if @output_dir
    File.binwrite(File.join(@output_dir, STARTUP_LOG_FILENAME), File.binread(@target_log)) if @output_dir
    blank_existing_log_bytes
  end

  # Truncating a file that a running process already has open can leave sparse NUL
  # gaps when that process writes again at its old file offset. Overwriting the
  # startup bytes with newlines keeps the existing workflow grep text-only while
  # preventing pre-measurement events from matching the post-run scan.
  def blank_existing_log_bytes
    remaining = File.size(@target_log)
    File.open(@target_log, "r+b") do |file|
      until remaining.zero?
        chunk_size = [remaining, BLANK_CHUNK_SIZE].min
        file.write("\n" * chunk_size)
        remaining -= chunk_size
      end
    end
  end

  def verify_target_pid!
    return unless @target_pid

    pid = Integer(@target_pid)
    return if @pid_alive.call(pid)

    raise MonitorFailure, "Benchmark target PID #{pid} exited during the measured benchmark window; " \
                          "discarding benchmark metrics because the target process did not survive."
  rescue ArgumentError
    raise MonitorFailure, "TARGET_PID=#{@target_pid.inspect} is not an integer; discarding benchmark metrics " \
                          "because target liveness could not be verified."
  end

  def verify_unexpected_worker_log!
    return unless target_log?

    matches = unexpected_worker_restart_lines
    return if matches.empty?

    raise MonitorFailure, "Pro node-renderer worker restarted during the measured benchmark window. " \
                          "The node-renderer master logged `#{UNEXPECTED_WORKER_RESTART}`, which means " \
                          "a worker process died and was forked again; discarding benchmark metrics " \
                          "instead of uploading partial data. Matching log line(s):\n#{matches.join("\n")}"
  end

  def unexpected_worker_restart_lines
    File.readlines(@target_log, chomp: true).each_with_index.filter_map do |line, index|
      next unless line.include?(UNEXPECTED_WORKER_RESTART)

      "#{index + 1}:#{line}"
    end
  end
end

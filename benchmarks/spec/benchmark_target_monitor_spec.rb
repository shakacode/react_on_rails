# frozen_string_literal: true

require "tmpdir"
require_relative "spec_helper"
require_relative "../lib/benchmark_config"
require_relative "../lib/benchmark_helpers"
require_relative "../lib/bmf_helpers"

RSpec.describe "benchmark target monitoring" do
  describe BenchmarkTargetMonitor do
    def with_log_file(content)
      Dir.mktmpdir do |dir|
        log_path = File.join(dir, "target.log")
        output_dir = File.join(dir, "bench_results")
        File.write(log_path, content)
        yield log_path, output_dir
      end
    end

    it "builds from TARGET_PID and TARGET_LOG in an injected environment" do
      with_log_file("startup complete\n") do |log_path, output_dir|
        monitor = described_class.from_env(
          output_dir: output_dir,
          env: { "TARGET_PID" => Process.pid.to_s, "TARGET_LOG" => log_path }
        )

        monitor.start_measurement!

        preserved = File.join(output_dir, described_class::STARTUP_LOG_FILENAME)
        expect(File.read(preserved)).to eq("startup complete\n")
        expect { monitor.verify_after_measurement! }.not_to raise_error
      end
    end

    it "is a no-op when neither TARGET_PID nor TARGET_LOG is provided" do
      Dir.mktmpdir do |dir|
        monitor = described_class.from_env(output_dir: dir, env: {})

        expect { monitor.start_measurement! }.not_to raise_error
        expect { monitor.verify_after_measurement! }.not_to raise_error
      end
    end

    it "preserves startup logs and blanks the live log before the measured window" do
      with_log_file("booting\nWorker 1 died UNEXPECTEDLY :(, restarting\nready\n") do |log_path, output_dir|
        monitor = described_class.new(target_log: log_path, output_dir: output_dir)

        monitor.start_measurement!

        preserved = File.join(output_dir, described_class::STARTUP_LOG_FILENAME)
        expect(File.read(preserved)).to include("Worker 1 died UNEXPECTEDLY")
        expect(File.read(log_path)).not_to include("died UNEXPECTEDLY")
        expect { monitor.verify_after_measurement! }.not_to raise_error
      end
    end

    it "does not re-preserve or blank measured log content when measurement starts twice" do
      with_log_file("startup complete\n") do |log_path, output_dir|
        monitor = described_class.new(target_log: log_path, output_dir: output_dir)
        measured_restart = "Worker 2 died UNEXPECTEDLY :(, restarting\n"

        monitor.start_measurement!
        File.open(log_path, "a") { |file| file.write(measured_restart) }
        monitor.start_measurement!

        preserved = File.join(output_dir, described_class::STARTUP_LOG_FILENAME)
        expect(File.read(preserved)).to eq("startup complete\n")
        expect(File.read(log_path)).to include(measured_restart)
        expect { monitor.verify_after_measurement! }
          .to raise_error(BenchmarkTargetMonitor::MonitorFailure, /node-renderer master logged/)
      end
    end

    it "does not monitor or blank the live log when startup logs cannot be preserved" do
      content = "booting\nWorker 1 died UNEXPECTEDLY :(, restarting\nready\n"

      with_log_file(content) do |log_path, _output_dir|
        monitor = described_class.new(target_log: log_path)

        monitor.start_measurement!

        expect(File.read(log_path)).to eq(content)
        expect { monitor.verify_after_measurement! }.not_to raise_error
      end
    end

    it "ignores a target log path that does not exist" do
      Dir.mktmpdir do |dir|
        monitor = described_class.new(target_log: File.join(dir, "missing.log"), output_dir: File.join(dir, "out"))

        expect { monitor.start_measurement! }.not_to raise_error
        expect { monitor.verify_after_measurement! }.not_to raise_error
      end
    end

    it "does not scan a target log that is created after measurement starts" do
      Dir.mktmpdir do |dir|
        log_path = File.join(dir, "target.log")
        output_dir = File.join(dir, "bench_results")
        monitor = described_class.new(target_log: log_path, output_dir: output_dir)

        monitor.start_measurement!
        File.write(log_path, "Worker 1 died UNEXPECTEDLY :(, restarting\n")

        expect { monitor.verify_after_measurement! }.not_to raise_error
      end
    end

    it "blanks bytes appended after log preservation but before opening the log for overwrite" do
      with_log_file("booting\nready\n") do |log_path, output_dir|
        monitor = described_class.new(target_log: log_path, output_dir: output_dir)
        late_log_line = "Worker 2 died UNEXPECTEDLY :(, restarting\n"

        allow(File).to receive(:open).and_wrap_original do |original_open, path, mode, *args, &block|
          original_open.call(path, "ab") { |file| file.write(late_log_line) } if path == log_path && mode == "r+b"
          original_open.call(path, mode, *args, &block)
        end

        monitor.start_measurement!

        preserved = File.join(output_dir, described_class::STARTUP_LOG_FILENAME)
        expect(File.read(preserved)).not_to include("died UNEXPECTEDLY")
        expect(File.read(log_path)).not_to include("died UNEXPECTEDLY")
      end
    end

    it "fails when verification runs before the measured window starts" do
      monitor = described_class.new

      expect { monitor.verify_after_measurement! }
        .to raise_error(BenchmarkTargetMonitor::MonitorFailure, /start_measurement! was never called/)
    end

    it "fails when the node renderer master logs an unexpected worker restart during measurement" do
      with_log_file("startup complete\n") do |log_path, output_dir|
        monitor = described_class.new(target_log: log_path, output_dir: output_dir)
        monitor.start_measurement!
        File.open(log_path, "a") { |file| file.puts("Worker 2 died UNEXPECTEDLY :(, restarting") }

        expect { monitor.verify_after_measurement! }
          .to raise_error(
            BenchmarkTargetMonitor::MonitorFailure,
            /node-renderer master logged `died UNEXPECTEDLY`.*discarding benchmark metrics/m
          )
      end
    end

    it "fails when the benchmark target PID no longer exists before metrics are written" do
      monitor = described_class.new(target_pid: "123", pid_alive: ->(_pid) { false })

      monitor.start_measurement!

      expect { monitor.verify_after_measurement! }
        .to raise_error(BenchmarkTargetMonitor::MonitorFailure, /PID 123.*discarding benchmark metrics/)
    end

    it "fails before liveness checks when the benchmark target PID is non-positive" do
      pid_alive = ->(_pid) { raise "pid liveness check should not run" }
      monitor = described_class.new(target_pid: "0", pid_alive: pid_alive)

      monitor.start_measurement!

      expect { monitor.verify_after_measurement! }
        .to raise_error(BenchmarkTargetMonitor::MonitorFailure, /TARGET_PID="0".*positive integer/)
    end
  end

  describe "write_benchmark_payload" do
    let(:collector) { instance_double(BmfCollector) }
    let(:monitor) { instance_double(BenchmarkTargetMonitor) }

    it "verifies the target monitor before writing Bencher payload files" do
      expect(monitor).to receive(:verify_after_measurement!).ordered
      expect(collector).to receive(:write_bmf_json).with(BENCHMARK_JSON, append: true).ordered
      expect(collector).to receive(:write_display_json).with(DISPLAY_JSON, append: true).ordered

      write_benchmark_payload(collector, target_monitor: monitor, append: true)
    end

    it "does not write payload files when target monitoring fails" do
      expect(monitor).to receive(:verify_after_measurement!)
        .and_raise(BenchmarkTargetMonitor::MonitorFailure, "target failed")
      expect(collector).not_to receive(:write_bmf_json)
      expect(collector).not_to receive(:write_display_json)

      expect { write_benchmark_payload(collector, target_monitor: monitor) }
        .to raise_error(BenchmarkTargetMonitor::MonitorFailure, "target failed")
    end
  end
end

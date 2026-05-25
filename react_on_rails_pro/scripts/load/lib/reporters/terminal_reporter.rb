# frozen_string_literal: true

module RendererHarness
  module Reporters
    module TerminalReporter
      module_function

      def print_summary(io, summary)
        io.puts "=== Renderer Load Harness Results ==="
        scenario_line = "Scenario: #{summary[:scenario]} | " \
                        "Concurrency: #{summary[:concurrency]} | " \
                        "Elapsed: #{format_secs(summary[:elapsed_seconds])}"
        io.puts scenario_line
        io.puts "Transport: #{summary[:transport]}"
        io.puts
        print_requests(io, summary[:requests])
        print_latency(io, summary[:latency_ms])
        print_memory(io, summary[:memory])
        io.puts
        io.puts "Output: #{summary[:output_dir]}" if summary[:output_dir]
      end

      def print_requests(io, req)
        io.puts "Requests: #{req[:count]} (failures: #{req[:failures]})"
        io.puts "RPS: #{format('%.1f', req[:rps])}"
        io.puts
      end

      def print_latency(io, lat)
        line = "Latency (ms):  p50=#{fmt(lat[:p50])}  p95=#{fmt(lat[:p95])}  " \
               "p99=#{fmt(lat[:p99])}  max=#{fmt(lat[:max])}"
        io.puts line
      end

      def print_memory(io, mem)
        return unless mem

        io.puts "Rails RSS slope: #{format('%+.2f', mem[:rails_slope_mb_per_min] || 0)} MB/min"
        return unless mem[:renderer_slope_mb_per_min]

        io.puts "Renderer RSS slope: #{format('%+.2f', mem[:renderer_slope_mb_per_min])} MB/min"
      end

      def fmt(value)
        return "n/a" if value.nil?

        format("%.1f", value)
      end

      def format_secs(secs)
        return "n/a" if secs.nil?

        "#{format('%.1f', secs)}s"
      end

      private_class_method :print_requests, :print_latency, :print_memory, :fmt, :format_secs
    end
  end
end

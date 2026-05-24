# frozen_string_literal: true

require "open3"

module RendererHarness
  class MemorySampler
    GC_KEYS = %i[
      heap_live_slots
      total_allocated_objects
      malloc_increase_bytes
      oldmalloc_increase_bytes
    ].freeze

    attr_reader :pids, :rows

    def initialize(pids:, start_time: Time.now)
      @pids = pids
      @start_time = start_time
      @rows = []
      @thread = nil
      @stop = false
    end

    def start_background(interval_seconds:)
      @thread = Thread.new do
        until @stop
          @rows << sample_once
          sleep(interval_seconds)
        end
      end
    end

    def stop_background
      @stop = true
      @thread&.join
    end

    def sample_once
      row = { t_seconds: Time.now - @start_time }
      pids.each do |label, pid|
        next if pid.nil?

        row[:"#{label}_rss_kb"] = sample_rss_kb(pid)
      end
      gc_snapshot.each { |k, v| row[:"gc_#{k}"] = v }
      row
    end

    def sample_rss_kb(pid)
      out = run_ps(pid)
      return nil if out.nil? || out.strip.empty?

      out.strip.to_i
    rescue Errno::ESRCH, Errno::ENOENT
      nil
    end

    def gc_snapshot
      stat = GC.stat
      GC_KEYS.to_h { |k| [k, stat[k].to_i] }
    end

    private

    def run_ps(pid)
      out, _err, status = Open3.capture3("ps", "-o", "rss=", "-p", pid.to_s)
      status.success? ? out : nil
    end
  end
end

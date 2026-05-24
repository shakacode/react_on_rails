# frozen_string_literal: true

require "open3"

module RendererHarness
  class MemorySampler
    # NOTE: File-descriptor count sampling is deferred to a follow-up.
    # The design spec lists it as "best-effort"; the foundation PR ships RSS + GC.stat only.

    GC_KEYS = %i[
      heap_live_slots
      total_allocated_objects
      malloc_increase_bytes
      oldmalloc_increase_bytes
    ].freeze

    attr_reader :pids

    def initialize(pids:, start_time: Time.now)
      @pids = pids.freeze
      @start_time = start_time
      @rows = []
      @rows_mutex = Mutex.new
      @thread = nil
      @stop = false
    end

    def rows
      @rows_mutex.synchronize { @rows.dup }
    end

    def start_background(interval_seconds:)
      raise "MemorySampler already running" if @thread&.alive?

      @stop = false
      @thread = Thread.new do
        until @stop
          begin
            @rows_mutex.synchronize { @rows << sample_once }
          rescue StandardError => e
            warn "MemorySampler: sample_once raised #{e.class}: #{e.message}"
          end
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

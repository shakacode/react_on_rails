# frozen_string_literal: true

require_relative "spec_helper"
require "memory_sampler"
require "timeout"

RSpec.describe RendererHarness::MemorySampler do
  describe "#sample_rss_kb" do
    it "parses ps output and returns integer kB" do
      sampler = described_class.new(pids: { rails: 1234 })
      allow(sampler).to receive(:run_ps).with(1234).and_return("  102400\n")
      expect(sampler.sample_rss_kb(1234)).to eq(102_400)
    end

    it "returns nil when ps returns nothing" do
      sampler = described_class.new(pids: { rails: 1234 })
      allow(sampler).to receive(:run_ps).with(1234).and_return("")
      expect(sampler.sample_rss_kb(1234)).to be_nil
    end

    it "returns nil when ps raises" do
      sampler = described_class.new(pids: { rails: 1234 })
      allow(sampler).to receive(:run_ps).with(1234).and_raise(Errno::ESRCH)
      expect(sampler.sample_rss_kb(1234)).to be_nil
    end
  end

  describe "#gc_snapshot" do
    it "returns a hash with the four tracked keys" do
      sampler = described_class.new(pids: { rails: Process.pid })
      snap = sampler.gc_snapshot
      expect(snap.keys).to contain_exactly(
        :heap_live_slots, :total_allocated_objects, :malloc_increase_bytes, :oldmalloc_increase_bytes
      )
      expect(snap.values).to all(be_a(Integer))
    end
  end

  describe "#sample_once" do
    it "returns a row including t_seconds, rails_rss_kb, and gc.* fields" do
      sampler = described_class.new(
        pids: { rails: 1234 },
        start_time: Process.clock_gettime(Process::CLOCK_MONOTONIC) - 5
      )
      allow(sampler).to receive(:run_ps).with(1234).and_return("100\n")
      row = sampler.sample_once
      expect(row[:t_seconds]).to be_within(0.5).of(5.0)
      expect(row[:rails_rss_kb]).to eq(100)
      expect(row.keys).to include(:gc_heap_live_slots)
    end

    it "includes renderer_rss_kb when renderer pid is set" do
      sampler = described_class.new(pids: { rails: 1234, renderer: 5678 })
      allow(sampler).to receive(:run_ps).with(1234).and_return("100\n")
      allow(sampler).to receive(:run_ps).with(5678).and_return("4000\n")
      row = sampler.sample_once
      expect(row[:renderer_rss_kb]).to eq(4000)
    end

    it "skips renderer when its pid is nil" do
      sampler = described_class.new(pids: { rails: 1234, renderer: nil })
      allow(sampler).to receive(:run_ps).with(1234).and_return("100\n")
      row = sampler.sample_once
      expect(row).to have_key(:rails_rss_kb)
      expect(row).not_to have_key(:renderer_rss_kb)
    end
  end

  describe "background thread" do
    it "accumulates rows and stops cleanly" do
      sampler = described_class.new(pids: { rails: Process.pid })
      sampler.start_background(interval_seconds: 0.01)
      sleep(0.05)
      sampler.stop_background
      expect(sampler.rows.size).to be >= 1
      expect(sampler.rows.first).to have_key(:t_seconds)
    end

    it "raises if start_background is called twice" do
      sampler = described_class.new(pids: { rails: Process.pid })
      begin
        sampler.start_background(interval_seconds: 0.05)
        expect { sampler.start_background(interval_seconds: 0.05) }.to raise_error(/already running/)
      ensure
        sampler.stop_background
      end
    end

    it "wakes a sleeping sampler thread during stop" do
      sampler = described_class.new(pids: { rails: Process.pid })
      sampler.start_background(interval_seconds: 60)
      Timeout.timeout(1.0) { sleep(0.01) until sampler.rows.any? }
      expect(sampler.rows).not_to be_empty

      sampler.stop_background(timeout_seconds: 0.2)

      expect(sampler.instance_variable_get(:@thread)).to be_nil
    end

    it "kills and resets a sampler thread that does not stop in time" do
      sampler = described_class.new(pids: { rails: Process.pid })
      sampling_started = Queue.new
      release_sample = Queue.new
      allow(sampler).to receive(:sample_once) do
        sampling_started << true
        release_sample.pop
        { t_seconds: 0 }
      end

      sampler.start_background(interval_seconds: 60)
      sampling_started.pop

      expect do
        sampler.stop_background(timeout_seconds: 0.01)
      end.to output(/MemorySampler: background thread did not stop/).to_stderr
      expect(sampler.instance_variable_get(:@thread)).to be_nil

      allow(sampler).to receive(:sample_once).and_return({ t_seconds: 0 })
      expect { sampler.start_background(interval_seconds: 0.01) }.not_to raise_error
    ensure
      release_sample << true
      sampler.stop_background(timeout_seconds: 0.01)
    end

    it "does not hold the rows mutex while sampling" do
      sampler = described_class.new(pids: { rails: Process.pid })
      sampling_started = Queue.new
      release_sample = Queue.new
      rows_thread = nil

      allow(sampler).to receive(:sample_once) do
        sampling_started << true
        release_sample.pop
        { t_seconds: 0 }
      end

      begin
        sampler.start_background(interval_seconds: 60)
        sampling_started.pop
        rows_thread = Thread.new { sampler.rows }

        expect(rows_thread.join(0.2)).to eq(rows_thread)
        expect(rows_thread.value).to eq([])
      ensure
        release_sample << true
        sampler.stop_background(timeout_seconds: 0.2)
        rows_thread&.kill if rows_thread&.alive?
      end
    end
  end
end

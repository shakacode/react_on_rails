# frozen_string_literal: true

require "spec_helper"
require "memory_sampler"

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
      sampler = described_class.new(pids: { rails: 1234 }, start_time: Time.now - 5)
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
  end
end

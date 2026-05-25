# frozen_string_literal: true

require_relative "spec_helper"
require "metrics"
require "request_result"

RSpec.describe RendererHarness::Metrics do
  describe ".percentile" do
    it "returns the only sample when given a single value" do
      expect(described_class.percentile([42.0], 50)).to eq(42.0)
    end

    it "returns nil for an empty sample set" do
      expect(described_class.percentile([], 99)).to be_nil
    end

    it "returns p50 of a sorted series" do
      samples = (1..100).map(&:to_f)
      expect(described_class.percentile(samples, 50)).to be_within(1.0).of(50.0)
    end

    it "returns p99 of a known series" do
      samples = (1..100).map(&:to_f)
      expect(described_class.percentile(samples, 99)).to be >= 99.0
    end

    it "handles identical samples" do
      expect(described_class.percentile([5.0] * 20, 95)).to eq(5.0)
    end
  end

  describe ".rps" do
    it "returns count / elapsed seconds" do
      expect(described_class.rps(count: 100, elapsed_seconds: 4.0)).to eq(25.0)
    end

    it "returns 0.0 when count is 0" do
      expect(described_class.rps(count: 0, elapsed_seconds: 0)).to eq(0.0)
    end

    it "uses a small elapsed floor when elapsed is 0" do
      expect(described_class.rps(count: 100, elapsed_seconds: 0))
        .to eq(100 / described_class::MIN_RPS_ELAPSED_SECONDS)
    end
  end

  describe ".slope_mb_per_min" do
    it "is positive for monotonically rising RSS" do
      # 10 samples 1s apart, RSS rises 1MB per second = 60 MB/min
      series = (0..9).map { |i| [i.to_f, (100 + i) * 1024.0] } # kB units like ps
      slope = described_class.slope_mb_per_min(series)
      expect(slope).to be_within(0.5).of(60.0)
    end

    it "is 0 for a flat series" do
      series = (0..9).map { |i| [i.to_f, 100_000.0] }
      expect(described_class.slope_mb_per_min(series)).to be_within(0.001).of(0.0)
    end

    it "returns 0 for fewer than 2 samples" do
      expect(described_class.slope_mb_per_min([[1.0, 1000.0]])).to eq(0.0)
    end
  end

  describe ".summarize_latencies" do
    it "returns a hash with p50/p90/p95/p99/p99_9/max/mean/count/failures/ok_count" do
      results = (1..100).map { |i| RendererHarness::RequestResult.new(latency_ms: i.to_f, ok: true) }
      summary = described_class.summarize_latencies(results)
      expect(summary).to include(:p50, :p90, :p95, :p99, :p99_9, :max, :mean, :count, :failures, :ok_count)
      expect(summary[:count]).to eq(100)
      expect(summary[:max]).to eq(100.0)
    end

    it "excludes failed requests from latency percentiles" do
      results = [
        RendererHarness::RequestResult.new(latency_ms: 10.0, ok: true),
        RendererHarness::RequestResult.new(latency_ms: 9999.0, ok: false)
      ]
      summary = described_class.summarize_latencies(results)
      expect(summary[:count]).to eq(2)
      expect(summary[:failures]).to eq(1)
      expect(summary[:ok_count]).to eq(1)
      expect(summary[:max]).to eq(10.0)
    end
  end
end

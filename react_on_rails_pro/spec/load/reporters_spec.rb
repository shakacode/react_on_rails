# frozen_string_literal: true

require_relative "spec_helper"
require "tmpdir"
require "json"
require "csv"
require "request_result"
require "reporters/json_reporter"
require "reporters/csv_reporter"
require "reporters/terminal_reporter"

RSpec.describe "Reporters" do
  let(:results) do
    [
      RendererHarness::RequestResult.new(
        latency_ms: 12.0, bytes_in: 1024, bytes_out: 256, ok: true,
        error: nil, http_status: 200, scenario: "standard_render",
        thread_id: 0, t_started_ms: 1.0
      ),
      RendererHarness::RequestResult.new(
        latency_ms: 0.0, bytes_in: 0, bytes_out: 0, ok: false,
        error: "timeout", http_status: nil, scenario: "standard_render",
        thread_id: 0, t_started_ms: 2.0
      )
    ]
  end

  let(:memory_rows) do
    [
      { t_seconds: 0.0, rails_rss_kb: 100_000, gc_heap_live_slots: 1000 },
      { t_seconds: 1.0, rails_rss_kb: 101_000, gc_heap_live_slots: 1100 }
    ]
  end

  let(:summary_payload) do
    {
      scenario: "standard_render",
      transport: "httpx",
      concurrency: 1,
      elapsed_seconds: 5.0,
      requests: { count: 2, failures: 1, rps: 0.4 },
      latency_ms: { p50: 12.0, p95: 12.0, p99: 12.0, max: 12.0, mean: 12.0 },
      memory: { rails_slope_mb_per_min: 0.5 }
    }
  end

  describe RendererHarness::Reporters::JsonReporter do
    it "writes summary.json with the payload" do
      Dir.mktmpdir do |dir|
        described_class.write(File.join(dir, "summary.json"), summary_payload)
        parsed = JSON.parse(File.read(File.join(dir, "summary.json")))
        expect(parsed["scenario"]).to eq("standard_render")
        expect(parsed["transport"]).to eq("httpx")
        expect(parsed["requests"]["count"]).to eq(2)
      end
    end
  end

  describe RendererHarness::Reporters::CsvReporter do
    it "writes latency.csv with one header + one row per result" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "latency.csv")
        described_class.write_latency(path, results)
        rows = CSV.read(path)
        expect(rows.first).to include("latency_ms", "ok", "scenario")
        expect(rows.length).to eq(3) # header + 2 results
      end
    end

    it "writes memory.csv with one header + one row per sample" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "memory.csv")
        described_class.write_memory(path, memory_rows)
        rows = CSV.read(path)
        expect(rows.first).to include("t_seconds", "rails_rss_kb")
        expect(rows.length).to eq(3) # header + 2 samples
      end
    end

    it "write_memory does nothing for empty rows" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "memory.csv")
        described_class.write_memory(path, [])
        expect(File.exist?(path)).to be false
      end
    end

    it "write_memory unions keys across rows" do
      rows = [
        { t_seconds: 0.0, rails_rss_kb: 100 },
        { t_seconds: 1.0, rails_rss_kb: 110, renderer_rss_kb: 200 }
      ]
      Dir.mktmpdir do |dir|
        path = File.join(dir, "memory.csv")
        described_class.write_memory(path, rows)
        header = CSV.read(path).first
        expect(header).to include("renderer_rss_kb")
      end
    end

    it "write_memory keeps known columns in stable order" do
      rows = [
        { t_seconds: 0.0, rails_rss_kb: 100, gc_heap_live_slots: 10 },
        { t_seconds: 1.0, rails_rss_kb: 110, renderer_rss_kb: 200, custom_metric: 1 }
      ]

      Dir.mktmpdir do |dir|
        path = File.join(dir, "memory.csv")
        described_class.write_memory(path, rows)
        header = CSV.read(path).first
        expect(header).to eq(
          %w[t_seconds rails_rss_kb renderer_rss_kb gc_heap_live_slots custom_metric]
        )
      end
    end
  end

  describe RendererHarness::Reporters::TerminalReporter do
    it "prints a summary block including scenario, transport, RPS, p99" do
      out = StringIO.new
      described_class.print(out, summary_payload)
      text = out.string
      expect(text).to include("standard_render")
      expect(text).to include("httpx")
      expect(text).to include("RPS")
      expect(text).to include("p99")
    end

    it "tolerates missing :memory key" do
      out = StringIO.new
      payload = summary_payload.dup.tap { |p| p[:memory] = nil }
      expect { described_class.print(out, payload) }.not_to raise_error
    end
  end
end
